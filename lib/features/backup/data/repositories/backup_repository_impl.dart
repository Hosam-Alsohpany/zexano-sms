import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/backup/data/datasources/backup_local_source.dart';
import 'package:zexano_sms/features/backup/data/mappers/backup_mapper.dart';
import 'package:zexano_sms/features/backup/data/models/backup_dto.dart';
import 'package:zexano_sms/features/backup/data/services/encryption_service.dart';
import 'package:zexano_sms/features/backup/data/services/integrity_service.dart';
import 'package:zexano_sms/features/backup/domain/entities/backup_metadata.dart';
import 'package:zexano_sms/features/backup/domain/entities/restore_report.dart';
import 'package:zexano_sms/features/backup/domain/models/restore_preview.dart';
import 'package:zexano_sms/features/backup/domain/models/verification_result.dart';
import 'package:zexano_sms/features/backup/domain/repositories/backup_repository.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_config.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_file_name.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';

class BackupRepositoryImpl implements BackupRepository {
  final BackupLocalSource _localSource;
  final EncryptionService _encryptionService;
  final IntegrityService _integrityService;
  final String _defaultTenantId;

  BackupRepositoryImpl({
    required BackupLocalSource localSource,
    required EncryptionService encryptionService,
    required IntegrityService integrityService,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _encryptionService = encryptionService,
        _integrityService = integrityService,
        _defaultTenantId = defaultTenantId;

  @override
  Future<AppResult<BackupMetadata>> createSqliteBackup({
    required BackupFileName fileName,
  }) async {
    try {
      final dbPath = await _getDatabasePath();
      if (!File(dbPath).existsSync()) {
        return const Left(BackupFailure(message: 'Database file not found'));
      }

      final backupDir = await _getBackupDirectory();
      final destPath = p.join(backupDir.path, fileName.value);

      await File(dbPath).copy(destPath);

      final file = File(destPath);
      final fileBytes = await file.readAsBytes();
      final checksum = _integrityService.computeFileChecksum(fileBytes);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return Right(BackupMetadata(
        id: const Uuid().v4(),
        fileName: fileName.value,
        createdAt: now,
        fileSize: fileBytes.length,
        entryCount: 0,
        checksum: checksum,
        isEncrypted: false,
        channelTypes: ['sms', 'whatsapp'],
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to create SQLite backup: ${e.toString()}',
        code: 'SQLITE_BACKUP_FAILED',
      ));
    }
  }

  @override
  Future<AppResult<BackupMetadata>> createEncryptedJsonBackup({
    required BackupFileName fileName,
    required BackupConfig config,
    required BackupPassphrase passphrase,
  }) async {
    try {
      final data = await _collectExportData(config);
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      var exportDto = BackupMapper.buildExportDto(
        data: data,
        createdAt: createdAt,
        isEncrypted: config.isEncrypted,
      );

      final rawJson = exportDto.serialize();
      final checksum = _integrityService.computeChecksum(rawJson);

      String fileContent;
      if (config.isEncrypted) {
        final encryptedPayload =
            _encryptionService.encrypt(rawJson, passphrase);
        final payloadHeader = BackupFileHeaderDto(
          manifest: BackupMapper.buildManifest(
            data: data,
            createdAt: createdAt,
            isEncrypted: true,
            checksum: checksum,
          ),
          payload: encryptedPayload,
        );
        fileContent = jsonEncode(payloadHeader.toJson());
      } else {
        exportDto = BackupMapper.buildExportDto(
          data: data,
          createdAt: createdAt,
          checksum: checksum,
        );
        fileContent = exportDto.serialize();
      }

      final backupDir = await _getBackupDirectory();
      final filePath = p.join(backupDir.path, fileName.value);
      await File(filePath).writeAsString(fileContent);

      final writtenFile = File(filePath);
      final entryCount = exportDto.manifest.totalEntries;

      return Right(BackupMetadata(
        id: const Uuid().v4(),
        fileName: fileName.value,
        createdAt: createdAt,
        fileSize: writtenFile.lengthSync(),
        entryCount: entryCount,
        checksum: checksum,
        version: 1,
        isEncrypted: config.isEncrypted,
        channelTypes: config.selectedChannels,
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to create JSON backup: ${e.toString()}',
        code: 'JSON_BACKUP_FAILED',
      ));
    }
  }

  @override
  Future<AppResult<VerificationResult>> verifyBackupIntegrity(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Right(VerificationResult.failure('File does not exist'));
      }

      final fileBytes = await file.readAsBytes();
      final isSqlite = _isSqliteFile(fileBytes);
      final isJson = filePath.endsWith('.json');

      if (isSqlite) {
        return Right(VerificationResult.success());
      }

      if (isJson) {
        final content = utf8.decode(fileBytes);
        final result = await _verifyJsonIntegrity(content);
        return Right(result);
      }

      return Right(VerificationResult.failure('Unknown file format'));
    } on Exception catch (e) {
      return Right(VerificationResult.failure(
          'Verification error: ${e.toString()}'));
    }
  }

  @override
  Future<AppResult<BackupMetadata>> readBackupMetadata(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Left(BackupFailure(message: 'Backup file not found: $filePath'));
      }

      final fileBytes = await file.readAsBytes();
      final isSqlite = _isSqliteFile(fileBytes);

      if (isSqlite) {
        final checksum = _integrityService.computeFileChecksum(fileBytes);
        return Right(BackupMetadata(
          id: const Uuid().v4(),
          fileName: p.basename(filePath),
          createdAt: file.lastModifiedSync().millisecondsSinceEpoch ~/ 1000,
          fileSize: fileBytes.length,
          entryCount: 0,
          checksum: checksum,
          isEncrypted: false,
        ));
      }

      final content = utf8.decode(fileBytes);
      final header = BackupFileHeaderDto.fromJson(
          jsonDecode(content) as Map<String, dynamic>);
      final manifest = header.manifest;

      return Right(BackupMetadata(
        id: const Uuid().v4(),
        fileName: p.basename(filePath),
        createdAt: manifest.createdAt,
        fileSize: fileBytes.length,
        entryCount: manifest.totalEntries,
        checksum: manifest.checksum ?? '',
        version: manifest.version,
        isEncrypted: manifest.isEncrypted,
        channelTypes: manifest.includedTables
            .where((t) => t == 'message_history' || t == 'assisted_sessions')
            .map((t) => t == 'assisted_sessions' ? 'whatsapp' : 'sms')
            .toList(),
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to read backup metadata: ${e.toString()}',
      ));
    }
  }

  @override
  Future<AppResult<BackupMetadata>> importBackupFile(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!sourceFile.existsSync()) {
        return Left(
            BackupFailure(message: 'Source file not found: $filePath'));
      }

      final backupDir = await _getBackupDirectory();
      final basename = p.basename(filePath);
      final destPath = p.join(backupDir.path, basename);

      await sourceFile.copy(destPath);
      return readBackupMetadata(destPath);
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to import backup file: ${e.toString()}',
      ));
    }
  }

  @override
  Future<AppResult<VerificationResult>> validateRestoreCandidate(
    String filePath, {
    BackupPassphrase? passphrase,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Right(VerificationResult.failure('File does not exist'));
      }

      final fileBytes = await file.readAsBytes();
      final isSqlite = _isSqliteFile(fileBytes);

      if (isSqlite) {
        if (fileBytes.length < 100) {
          return Right(VerificationResult.failure('File is too small for SQLite database'));
        }
        return Right(VerificationResult.success());
      }

      if (!filePath.endsWith('.json')) {
        return Right(
            VerificationResult.failure('Unsupported backup file format'));
      }

      final content = utf8.decode(fileBytes);

      if (!BackupMapper.validateBackupJson(content)) {
        return Right(
            VerificationResult.failure('Invalid backup JSON structure'));
      }

      final header = BackupFileHeaderDto.fromJson(
          jsonDecode(content) as Map<String, dynamic>);

      if (!_integrityService.isSchemaVersionCompatible(header.manifest.version)) {
        return Right(VerificationResult.failure(
            'Incompatible schema version: ${header.manifest.version}'));
      }

      if (header.manifest.isEncrypted) {
        if (passphrase == null || header.payload == null) {
          return Right(VerificationResult.failure(
              'Encrypted backup requires passphrase'));
        }
        try {
          final decrypted =
              _encryptionService.decrypt(header.payload!, passphrase);
          if (header.manifest.checksum != null &&
              !_integrityService.verifyChecksum(
                  decrypted, header.manifest.checksum!)) {
            return Right(
                VerificationResult.failure('Checksum mismatch after decryption'));
          }
        } catch (_) {
          return Right(
              VerificationResult.failure('Invalid passphrase or corrupted data'));
        }
      } else {
        final dataSection = jsonDecode(content) as Map<String, dynamic>;
        final dataJson = jsonEncode({'data': dataSection['data'] ?? {}});
        if (header.manifest.checksum != null &&
            !_integrityService.verifyChecksum(
                dataJson, header.manifest.checksum!)) {
          return Right(VerificationResult.failure('Checksum mismatch'));
        }
      }

      return Right(VerificationResult(
        isValid: true,
        checksumMatch: true,
        fileSizeValid: fileBytes.isNotEmpty,
      ));
    } on Exception catch (e) {
      return Right(VerificationResult.failure(
          'Validation error: ${e.toString()}'));
    }
  }

  @override
  Future<AppResult<RestorePreview>> previewRestoreSummary(
    String filePath, {
    BackupPassphrase? passphrase,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Left(BackupFailure(message: 'Backup file not found'));
      }

      final fileBytes = await file.readAsBytes();
      final isSqlite = _isSqliteFile(fileBytes);

      if (isSqlite) {
        return Right(const RestorePreview(
          totalEntries: 0,
          version: 1,
        ));
      }

      if (!filePath.endsWith('.json')) {
        return const Left(BackupFailure(message: 'Unsupported backup format'));
      }

      final content = utf8.decode(fileBytes);
      var dataMap = <String, List<Map<String, dynamic>>>{};
      var manifest = BackupManifestDto(createdAt: 0);

      final raw = jsonDecode(content) as Map<String, dynamic>;
      if (raw.containsKey('manifest')) {
        final header = BackupFileHeaderDto.fromJson(raw);
        manifest = header.manifest;

        if (manifest.isEncrypted) {
          if (passphrase == null || header.payload == null) {
            return Left(BackupFailure(
                message: 'Passphrase required for encrypted backup'));
          }
          final decrypted =
              _encryptionService.decrypt(header.payload!, passphrase);
          final dto = BackupExportDto.deserialize(decrypted);
          dataMap = dto.data;
        } else if (raw.containsKey('data')) {
          final dto = BackupExportDto.fromJson(raw);
          dataMap = dto.data;
        }
      }

      return Right(RestorePreview(
        totalEntries: dataMap.values.fold(0, (s, l) => s + l.length),
        contactCount: BackupMapper.countContacts(dataMap),
        smsMessageCount: BackupMapper.countSmsMessages(dataMap),
        whatsAppSessionCount: BackupMapper.countWhatsAppSessions(dataMap),
        templateCount: BackupMapper.countTemplates(dataMap),
        groupCount: BackupMapper.countGroupEntries(dataMap),
        version: manifest.version,
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to preview restore: ${e.toString()}',
      ));
    }
  }

  @override
  Future<AppResult<RestoreReport>> restoreFromSqliteBackup(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Left(BackupFailure(message: 'Backup file not found'));
      }

      final fileBytes = await file.readAsBytes();
      if (!_isSqliteFile(fileBytes)) {
        return const Left(BackupFailure(message: 'Not a valid SQLite backup file'));
      }

      final dbPath = await _getDatabasePath();
      final tempBackupPath = '$dbPath.restore_temp_backup';

      try {
        if (File(dbPath).existsSync()) {
          await File(dbPath).copy(tempBackupPath);
        }
      } catch (_) {
      }

      try {
        await file.copy(dbPath);
      } catch (_) {
        if (File(tempBackupPath).existsSync()) {
          await File(tempBackupPath).copy(dbPath);
        }
        return Left(BackupFailure(
          message: 'Failed to replace database file',
          code: 'RESTORE_COPY_FAILED',
        ));
      }

      if (File(tempBackupPath).existsSync()) {
        await File(tempBackupPath).delete();
      }

      return Right(const RestoreReport(
        restoredContactCount: 0,
        restoredSmsCount: 0,
        restoredWaCount: 0,
        totalProcessed: 1,
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'SQLite restore failed: ${e.toString()}',
        code: 'SQLITE_RESTORE_FAILED',
      ));
    }
  }

  @override
  Future<AppResult<RestoreReport>> restoreFromEncryptedJsonBackup({
    required String filePath,
    required BackupPassphrase passphrase,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Left(BackupFailure(message: 'Backup file not found'));
      }

      final content = await file.readAsString();
      final raw = jsonDecode(content) as Map<String, dynamic>;
      final header = BackupFileHeaderDto.fromJson(raw);

      String rawJson;
      if (header.manifest.isEncrypted) {
        if (header.payload == null) {
          return Left(BackupFailure(
              message: 'Encrypted backup has no payload'));
        }
        rawJson = _encryptionService.decrypt(header.payload!, passphrase);
      } else {
        final dto = BackupExportDto.fromJson(raw);
        rawJson = jsonEncode(dto.toJson());
      }

      final exportDto = BackupExportDto.deserialize(rawJson);
      final data = exportDto.data;

      var restoredContacts = 0;
      var restoredSms = 0;
      var restoredWa = 0;
      var failedItems = 0;
      final warnings = <String>[];

      await _localSource.runInTransaction(() async {
        if (data.containsKey('contacts') && data['contacts']!.isNotEmpty) {
          _ensureTenantId(data['contacts']!);
          await _localSource.importContacts(data['contacts']!);
          restoredContacts = data['contacts']!.length;
        }

        if (data.containsKey('tags') && data['tags']!.isNotEmpty) {
          _ensureTenantId(data['tags']!);
          await _localSource.importTags(data['tags']!);
        }

        if (data.containsKey('contact_tags') &&
            data['contact_tags']!.isNotEmpty) {
          await _localSource.importContactTags(data['contact_tags']!);
        }

        if (data.containsKey('groups') && data['groups']!.isNotEmpty) {
          _ensureTenantId(data['groups']!);
          await _localSource.importGroups(data['groups']!);
        }

        if (data.containsKey('group_members') &&
            data['group_members']!.isNotEmpty) {
          await _localSource.importGroupMembers(data['group_members']!);
        }

        if (data.containsKey('message_templates') &&
            data['message_templates']!.isNotEmpty) {
          _ensureTenantId(data['message_templates']!);
          await _localSource.importMessageTemplates(data['message_templates']!);
        }

        if (data.containsKey('message_history') &&
            data['message_history']!.isNotEmpty) {
          _ensureTenantId(data['message_history']!);
          try {
            await _localSource.importMessageHistory(data['message_history']!);
            restoredSms = data['message_history']!
                .where((r) => r['channelType'] == 'sms')
                .length;
          } on Exception catch (e) {
            failedItems += data['message_history']!.length;
            warnings.add('Message history import issue: ${e.toString()}');
          }
        }

        if (data.containsKey('assisted_sessions') &&
            data['assisted_sessions']!.isNotEmpty) {
          _ensureTenantId(data['assisted_sessions']!);
          try {
            await _localSource.importAssistedSessions(
                data['assisted_sessions']!);
            restoredWa = data['assisted_sessions']!.length;
          } on Exception catch (e) {
            failedItems += data['assisted_sessions']!.length;
            warnings.add('Assisted sessions import issue: ${e.toString()}');
          }
        }

        if (data.containsKey('staged_recipients') &&
            data['staged_recipients']!.isNotEmpty) {
          try {
            await _localSource.importStagedRecipients(
                data['staged_recipients']!);
          } on Exception catch (e) {
            failedItems += data['staged_recipients']!.length;
            warnings.add('Staged recipients import issue: ${e.toString()}');
          }
        }

        if (data.containsKey('whatsapp_preferences') &&
            data['whatsapp_preferences']!.isNotEmpty) {
          _ensureTenantId(data['whatsapp_preferences']!);
          try {
            await _localSource.importWhatsAppPreferences(
                data['whatsapp_preferences']!);
          } on Exception catch (e) {
            warnings.add('WhatsApp preferences import issue: ${e.toString()}');
          }
        }
      });

      final totalProcessed = data.values.fold(0, (s, l) => s + l.length);

      return Right(RestoreReport(
        restoredContactCount: restoredContacts,
        restoredSmsCount: restoredSms,
        restoredWaCount: restoredWa,
        failedItems: failedItems,
        warnings: warnings,
        totalProcessed: totalProcessed,
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to restore from JSON backup: ${e.toString()}',
        code: 'JSON_RESTORE_FAILED',
      ));
    }
  }

  @override
  Future<AppResult<RestoreReport>> confirmDestructiveRestore({
    required String filePath,
    required bool confirmed,
    BackupPassphrase? passphrase,
  }) async {
    if (!confirmed) {
      return Left(BackupFailure(
        message: 'Restore not confirmed. Action cancelled.',
        code: 'RESTORE_NOT_CONFIRMED',
      ));
    }

    try {
      final isSqlite = filePath.endsWith('.backup');
      if (isSqlite) {
        return restoreFromSqliteBackup(filePath);
      }
      if (passphrase == null) {
        return Left(BackupFailure(
          message: 'Passphrase required for encrypted backup restore',
          code: 'PASSPHRASE_REQUIRED',
        ));
      }
      return restoreFromEncryptedJsonBackup(
          filePath: filePath, passphrase: passphrase);
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Destructive restore failed: ${e.toString()}',
        code: 'DESTRUCTIVE_RESTORE_FAILED',
      ));
    }
  }

  @override
  Future<AppResult<BackupFileName>> generateBackupFileName({
    bool isEncrypted = false,
  }) async {
    try {
      return Right(BackupFileName.generate(isEncrypted: isEncrypted));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Failed to generate filename: ${e.toString()}',
      ));
    }
  }

  @override
  Future<AppResult<bool>> validateBackupPassphrase(
      BackupPassphrase passphrase) async {
    try {
      return Right(passphrase.isValid);
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Passphrase validation error: ${e.toString()}',
      ));
    }
  }

  @override
  Future<AppResult<String>> decryptBackupPayload({
    required String encryptedPayload,
    required BackupPassphrase passphrase,
  }) async {
    try {
      final decrypted =
          _encryptionService.decrypt(encryptedPayload, passphrase);
      return Right(decrypted);
    } on ArgumentError catch (e) {
      return Left(BackupFailure(
        message: 'Decryption failed: ${e.toString()}',
        code: 'DECRYPTION_FAILED',
      ));
    } on Exception catch (e) {
      return Left(BackupFailure(
        message: 'Decryption error: ${e.toString()}',
        code: 'DECRYPTION_ERROR',
      ));
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _collectExportData(
      BackupConfig config) async {
    final data = <String, List<Map<String, dynamic>>>{};

    if (config.includeContacts) {
      data['contacts'] = await _localSource.exportContacts();
      data['tags'] = await _localSource.exportTags();
      data['contact_tags'] = await _localSource.exportContactTags();
    }

    data['groups'] = await _localSource.exportGroups();
    data['group_members'] = await _localSource.exportGroupMembers();

    data['message_templates'] = await _localSource.exportMessageTemplates();

    if (config.includeSms) {
      final allHistory = await _localSource.exportMessageHistory();
      data['message_history'] =
          allHistory.where((r) => r['channelType'] == 'sms').toList();
    }

    if (config.includeWhatsApp) {
      data['assisted_sessions'] = await _localSource.exportAssistedSessions();
      data['staged_recipients'] = await _localSource.exportStagedRecipients();
      data['whatsapp_preferences'] =
          await _localSource.exportWhatsAppPreferences();
    }

    return data;
  }

  Future<VerificationResult> _verifyJsonIntegrity(String content) async {
    try {
      if (!BackupMapper.validateBackupJson(content)) {
        return VerificationResult.failure('Invalid backup JSON structure');
      }

      final raw = jsonDecode(content) as Map<String, dynamic>;
      final header = BackupFileHeaderDto.fromJson(raw);

      if (header.manifest.isEncrypted) {
        if (header.payload == null) {
          return VerificationResult.failure('Missing payload in encrypted backup');
        }
        if (header.manifest.checksum != null) {
          final checksumOk = _integrityService.verifyFileChecksum(
              base64.decode(header.payload!), header.manifest.checksum!);
          if (!checksumOk) {
            return VerificationResult.failure(
                'Encrypted payload checksum mismatch');
          }
        }
      } else {
        final dataJson = jsonEncode({'data': raw['data'] ?? {}});
        if (header.manifest.checksum != null &&
            !_integrityService.verifyChecksum(
                dataJson, header.manifest.checksum!)) {
          return VerificationResult.failure('Data checksum mismatch');
        }
      }

      return VerificationResult.success();
    } on FormatException {
      return VerificationResult.failure('Invalid JSON format');
    }
  }

  void _ensureTenantId(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      if (row['tenantId'] == null || (row['tenantId'] as String).isEmpty) {
        row['tenantId'] = _defaultTenantId;
      }
    }
  }

  bool _isSqliteFile(List<int> bytes) {
    if (bytes.length < 16) return false;
    return bytes[0] == 0x53 && bytes[1] == 0x51 && bytes[2] == 0x4C &&
        bytes[3] == 0x69 && bytes[4] == 0x74 && bytes[5] == 0x65 &&
        bytes[6] == 0x20 && bytes[7] == 0x66;
  }

  Future<String> _getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'zexano_sms.db');
  }

  Future<Directory> _getBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    return backupDir;
  }
}
