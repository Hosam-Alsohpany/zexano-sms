import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

enum ExportFileStatus {
  success,
  cancelled,
  failed,
}

class ExportFileResult {
  final ExportFileStatus status;
  final String? pathOrUri;
  final String? errorMessage;

  const ExportFileResult.success(this.pathOrUri)
      : status = ExportFileStatus.success,
        errorMessage = null;

  const ExportFileResult.cancelled()
      : status = ExportFileStatus.cancelled,
        pathOrUri = null,
        errorMessage = null;

  const ExportFileResult.failed(this.errorMessage)
      : status = ExportFileStatus.failed,
        pathOrUri = null;

  bool get isSuccess => status == ExportFileStatus.success;
  bool get isCancelled => status == ExportFileStatus.cancelled;
  bool get isFailed => status == ExportFileStatus.failed;
}

class CsvVcfContactsHandler {
  final Uuid _uuid;

  CsvVcfContactsHandler({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<List<Contact>?> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'vcf'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    final extension = path.split('.').last.toLowerCase();

    if (extension == 'csv') {
      return parseCsv(content);
    } else {
      return parseVcf(content);
    }
  }

  List<String> _splitCsvRows(String content) {
    var cleanContent = content;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }
    final rows = <String>[];
    final currentRow = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < cleanContent.length; i++) {
      final char = cleanContent[i];
      if (char == '"') {
        if (inQuotes && i + 1 < cleanContent.length && cleanContent[i + 1] == '"') {
          currentRow.write('""');
          i++;
        } else {
          inQuotes = !inQuotes;
          currentRow.write('"');
        }
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < cleanContent.length && cleanContent[i + 1] == '\n') {
          i++;
        }
        if (currentRow.isNotEmpty) {
          final rowStr = currentRow.toString();
          if (rowStr.trim().isNotEmpty) {
            rows.add(rowStr);
          }
          currentRow.clear();
        }
      } else {
        currentRow.write(char);
      }
    }
    if (currentRow.isNotEmpty) {
      final rowStr = currentRow.toString();
      if (rowStr.trim().isNotEmpty) {
        rows.add(rowStr);
      }
    }
    return rows;
  }

  List<Contact> parseCsv(String content) {
    final lines = _splitCsvRows(content);
    if (lines.length < 2) return [];

    final headers = parseCsvLine(lines[0]);
    final firstNameIdx = findColumn(headers, ['first_name', 'given_name', 'firstname', 'first', 'given']);
    final lastNameIdx = findColumn(headers, ['last_name', 'family_name', 'lastname', 'last', 'family', 'surname']);
    final fullNameIdx = findColumn(headers, ['full_name', 'fullname', 'name', 'display_name']);
    final phoneIdx = findColumn(headers, ['phone', 'mobile', 'phone_number', 'phonenumber', 'telephone', 'tel', 'cell', 'number']);
    final notesIdx = findColumn(headers, ['notes', 'note', 'comments', 'comment']);

    if (phoneIdx == -1) return [];

    final contacts = <Contact>[];

    for (var i = 1; i < lines.length; i++) {
      final fields = parseCsvLine(lines[i]);
      if (phoneIdx >= fields.length) continue;

      final phone = fields[phoneIdx].trim();
      if (phone.isEmpty) continue;

      String firstName = '';
      String lastName = '';

      if (firstNameIdx != -1 && firstNameIdx < fields.length) {
        firstName = fields[firstNameIdx].trim();
      }
      if (lastNameIdx != -1 && lastNameIdx < fields.length) {
        lastName = fields[lastNameIdx].trim();
      }

      if (firstName.isEmpty && lastName.isEmpty && fullNameIdx != -1 && fullNameIdx < fields.length) {
        final full = fields[fullNameIdx].trim();
        final spaceIdx = full.lastIndexOf(' ');
        if (spaceIdx > 0) {
          firstName = full.substring(0, spaceIdx).trim();
          lastName = full.substring(spaceIdx + 1).trim();
        } else {
          firstName = full;
        }
      }

      final notes = notesIdx != -1 && notesIdx < fields.length ? fields[notesIdx].trim() : '';

      contacts.add(Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
        notes: notes,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    return contacts;
  }

  String decodeQuotedPrintable(String text) {
    // If the text already contains non-ASCII chars, it was already
    // decoded by readAsString() — return as-is.
    for (var j = 0; j < text.length; j++) {
      if (text.codeUnitAt(j) > 127) return text;
    }
    final bytes = <int>[];
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '=' && i + 2 < text.length) {
        final hi = text.codeUnitAt(i + 1);
        final lo = text.codeUnitAt(i + 2);
        if (_isHexDigit(hi) && _isHexDigit(lo)) {
          bytes.add(int.parse(text.substring(i + 1, i + 3), radix: 16));
          i += 2;
          continue;
        }
      }
      bytes.add(text.codeUnitAt(i));
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // Some vCard files encode QP bytes as Latin-1 (ISO-8859-1)
      // instead of UTF-8. Fall back gracefully.
      try {
        return latin1.decode(bytes);
      } on FormatException {
        // If some byte is > 255 (raw non-ASCII char leaked in),
        // return original text as a last resort.
        return text;
      }
    }
  }

  bool _isHexDigit(int code) {
    return (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x46) ||
        (code >= 0x61 && code <= 0x66);
  }

  /// Parses a vCard property line into its components.
  /// Returns [propName, value, isQuotedPrintable].
  List<Object?> _parseVcfProperty(String line) {
    final colonIdx = line.indexOf(':');
    if (colonIdx == -1) return [null, null, false];

    final prefix = line.substring(0, colonIdx);
    final propName = prefix.split(';').first.toUpperCase();
    var value = line.substring(colonIdx + 1).trim();

    // Check for QUOTED-PRINTABLE encoding in parameters
    final params = prefix.split(';').skip(1);
    var isQuotedPrintable = false;
    for (final param in params) {
      final upper = param.toUpperCase();
      if (upper == 'ENCODING=QUOTED-PRINTABLE' ||
          upper == 'ENCODING=QUOTED-PRINTABLE;' ||
          upper.contains('ENCODING=QUOTED-PRINTABLE')) {
        isQuotedPrintable = true;
      }
    }

    if (isQuotedPrintable) {
      value = decodeQuotedPrintable(value);
    } else {
      value = unescapeVcf(value);
    }

    return [propName, value, isQuotedPrintable];
  }

  List<Contact> parseVcf(String content) {
    final contacts = <Contact>[];
    final records = content.split(RegExp(r'END:VCARD', caseSensitive: false));

    for (final record in records) {
      if (record.trim().isEmpty) continue;

      String? fullName;
      String? phone;
      String? notes;

      final rawLines = record.split(RegExp(r'\r?\n'));
      // Merge continuation lines:
      //   - vCard folding: continuation starts with space/tab
      //   - QP soft break: previous line ends with '='
      final lines = <String>[];
      for (final rawLine in rawLines) {
        if (rawLine.isEmpty) continue;
        if (lines.isNotEmpty &&
            (rawLine.startsWith(' ') || rawLine.startsWith('\t') ||
             lines.last.endsWith('='))) {
          var prev = lines.last;
          if (prev.endsWith('=')) {
            prev = prev.substring(0, prev.length - 1);
          }
          lines.last = prev + rawLine.trimLeft();
        } else {
          lines.add(rawLine);
        }
      }

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = _parseVcfProperty(trimmed);
        final propName = parts[0] as String?;
        final value = parts[1] as String?;
        if (propName == null || value == null) continue;

        if (propName == 'FN') {
          fullName = value;
        } else if (propName == 'TEL') {
          if (phone == null && value.isNotEmpty) {
            phone = value;
          }
        } else if (propName == 'NOTE') {
          notes = value;
        } else if (propName == 'N') {
          if (fullName == null) {
            final nameParts = value.split(';').map((p) => p.trim()).toList();
            final family = nameParts.isNotEmpty ? nameParts[0] : '';
            final given = nameParts.length > 1 ? nameParts[1] : '';
            final middle = nameParts.length > 2 ? nameParts[2] : '';
            final parts = [given, middle, family].where((s) => s.isNotEmpty).toList();
            if (parts.isNotEmpty) {
              fullName = parts.join(' ');
            }
          }
        }
      }

      if (phone == null || phone.isEmpty) continue;

      String firstName = '';
      String lastName = '';
      if (fullName != null && fullName.isNotEmpty) {
        final spaceIdx = fullName.lastIndexOf(' ');
        if (spaceIdx > 0) {
          firstName = fullName.substring(0, spaceIdx).trim();
          lastName = fullName.substring(spaceIdx + 1).trim();
        } else {
          firstName = fullName;
        }
      }

      contacts.add(Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
        notes: notes ?? '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    return contacts;
  }

  List<String> parseCsvLine(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    fields.add(current.toString().trim());

    return fields;
  }

  int findColumn(List<String> headers, List<String> aliases) {
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
      for (final alias in aliases) {
        if (header == alias) return i;
      }
    }
    return -1;
  }

  String escapeVcf(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll('\n', r'\n');
  }

  String unescapeVcf(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (text[i] == r'\' && i + 1 < text.length) {
        final next = text[i + 1];
        if (next == 'n' || next == 'N') {
          buffer.write('\n');
          i++;
        } else if (next == ',' || next == ';' || next == r'\') {
          buffer.write(next);
          i++;
        } else {
          buffer.write(text[i]);
        }
      } else {
        buffer.write(text[i]);
      }
    }
    return buffer.toString();
  }

  String generateVcf(List<Contact> contacts) {
    final buffer = StringBuffer();
    for (final contact in contacts) {
      final name = contact.fullName.trim();
      final escapedName = escapeVcf(name);
      buffer.writeln('BEGIN:VCARD');
      buffer.writeln('VERSION:3.0');
      buffer.writeln('FN:$escapedName');
      buffer.writeln('N:;$escapedName;;;');
      if (contact.phoneNumber.trim().isNotEmpty) {
        buffer.writeln('TEL;TYPE=CELL:${contact.phoneNumber.trim()}');
      }
      if (contact.notes.trim().isNotEmpty) {
        buffer.writeln('NOTE:${escapeVcf(contact.notes.trim())}');
      }
      buffer.writeln('END:VCARD');
    }
    return buffer.toString();
  }

  String escapeCsvField(String field) {
    if (field.contains('"') ||
        field.contains(',') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String generateCsv(List<Contact> contacts) {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('full_name,phone,notes');
    for (final contact in contacts) {
      final name = escapeCsvField(contact.fullName);
      final phone = escapeCsvField(contact.phoneNumber);
      final notes = escapeCsvField(contact.notes);
      buffer.writeln('$name,$phone,$notes');
    }
    return buffer.toString();
  }

  Future<ExportFileResult> exportContactsToFile({
    required List<Contact> contacts,
    required String format,
    String? customFileName,
  }) async {
    final extension = format.toLowerCase().replaceAll('.', '');
    final content = extension == 'csv' ? generateCsv(contacts) : generateVcf(contacts);
    final defaultFileName = customFileName ??
        'contacts_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final mimeType = extension == 'csv' ? 'text/comma-separated-values' : 'text/vcard';

    debugPrint(
      '[EXPORT START] format=$format contactsCount=${contacts.length} '
      'bytesLength=${content.length} suggestedFileName=$defaultFileName',
    );

    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.zexano.sms/sms');
        final result = await channel.invokeMethod<Map<dynamic, dynamic>>('saveFile', {
          'fileName': defaultFileName,
          'mimeType': mimeType,
          'content': content,
        });

        final status = result?['status'] as String?;
        debugPrint('[EXPORT ANDROID SAF RESULT] status=$status result=$result');

        if (status == 'success') {
          final uri = result?['uri'] as String?;
          return ExportFileResult.success(uri ?? defaultFileName);
        } else if (status == 'cancelled') {
          return const ExportFileResult.cancelled();
        } else {
          return ExportFileResult.failed(result?['error']?.toString() ?? 'Unknown error');
        }
      } on PlatformException catch (e, stack) {
        debugPrint('[EXPORT ANDROID SAF EXCEPTION] code=${e.code} msg=${e.message}\n$stack');
        return ExportFileResult.failed(e.message ?? 'Platform error during export');
      } catch (e, stack) {
        debugPrint('[EXPORT ANDROID UNEXPECTED EXCEPTION] $e\n$stack');
        return ExportFileResult.failed(e.toString());
      }
    }

    // Desktop / non-Android platforms (e.g. Windows)
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Contacts',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      debugPrint('[EXPORT DESKTOP RESULT] savePath=$savePath');

      if (savePath == null) {
        return const ExportFileResult.cancelled();
      }

      final file = File(savePath);
      await file.writeAsString(content, encoding: utf8);
      return ExportFileResult.success(savePath);
    } catch (e, stack) {
      debugPrint('[EXPORT DESKTOP EXCEPTION] $e\n$stack');
      return ExportFileResult.failed(e.toString());
    }
  }
}
