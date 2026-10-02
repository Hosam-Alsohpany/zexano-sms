import 'dart:convert';
import '../models/backup_dto.dart';

class BackupMapper {
  static BackupManifestDto buildManifest({
    required Map<String, List<Map<String, dynamic>>> data,
    required int createdAt,
    bool isEncrypted = false,
    String? checksum,
  }) {
    final entryCounts = <String, int>{};
    for (final entry in data.entries) {
      entryCounts[entry.key] = entry.value.length;
    }
    return BackupManifestDto(
      version: 1,
      createdAt: createdAt,
      includedTables: data.keys.toList(),
      entryCounts: entryCounts,
      isEncrypted: isEncrypted,
      checksum: checksum,
    );
  }

  static BackupExportDto buildExportDto({
    required Map<String, List<Map<String, dynamic>>> data,
    required int createdAt,
    bool isEncrypted = false,
    String? checksum,
  }) {
    return BackupExportDto(
      manifest: buildManifest(
        data: data,
        createdAt: createdAt,
        isEncrypted: isEncrypted,
        checksum: checksum,
      ),
      data: data,
    );
  }

  static int countSmsMessages(
      Map<String, List<Map<String, dynamic>>> data) {
    final history = data['message_history'] ?? [];
    return history.where((r) => r['channelType'] == 'sms').length;
  }

  static int countWhatsAppSessions(
      Map<String, List<Map<String, dynamic>>> data) {
    return data['assisted_sessions']?.length ?? 0;
  }

  static int countContacts(
      Map<String, List<Map<String, dynamic>>> data) {
    return data['contacts']?.length ?? 0;
  }

  static int countGroupEntries(
      Map<String, List<Map<String, dynamic>>> data) {
    return data['groups']?.length ?? 0;
  }

  static int countTemplates(
      Map<String, List<Map<String, dynamic>>> data) {
    return data['message_templates']?.length ?? 0;
  }

  static bool validateBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return false;
      if (!decoded.containsKey('manifest')) return false;
      if (!decoded.containsKey('data') && !decoded.containsKey('payload')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
