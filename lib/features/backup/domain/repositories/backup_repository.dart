import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/backup_metadata.dart';
import '../entities/restore_report.dart';
import '../models/restore_preview.dart';
import '../models/verification_result.dart';
import '../value_objects/backup_config.dart';
import '../value_objects/backup_file_name.dart';
import '../value_objects/backup_passphrase.dart';

abstract class BackupRepository {
  Future<AppResult<BackupMetadata>> createSqliteBackup({
    required BackupFileName fileName,
  });

  Future<AppResult<BackupMetadata>> createEncryptedJsonBackup({
    required BackupFileName fileName,
    required BackupConfig config,
    required BackupPassphrase passphrase,
  });

  Future<AppResult<VerificationResult>> verifyBackupIntegrity(
    String filePath,
  );

  Future<AppResult<BackupMetadata>> readBackupMetadata(String filePath);

  Future<AppResult<BackupMetadata>> importBackupFile(String filePath);

  Future<AppResult<VerificationResult>> validateRestoreCandidate(
    String filePath, {
    BackupPassphrase? passphrase,
  });

  Future<AppResult<RestorePreview>> previewRestoreSummary(String filePath, {
    BackupPassphrase? passphrase,
  });

  Future<AppResult<RestoreReport>> restoreFromSqliteBackup(
    String filePath,
  );

  Future<AppResult<RestoreReport>> restoreFromEncryptedJsonBackup({
    required String filePath,
    required BackupPassphrase passphrase,
  });

  Future<AppResult<RestoreReport>> confirmDestructiveRestore({
    required String filePath,
    required bool confirmed,
    BackupPassphrase? passphrase,
  });

  Future<AppResult<BackupFileName>> generateBackupFileName({
    bool isEncrypted = false,
  });

  Future<AppResult<bool>> validateBackupPassphrase(
    BackupPassphrase passphrase,
  );

  Future<AppResult<String>> decryptBackupPayload({
    required String encryptedPayload,
    required BackupPassphrase passphrase,
  });
}
