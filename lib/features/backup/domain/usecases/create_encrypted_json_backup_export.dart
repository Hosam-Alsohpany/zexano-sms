import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/backup_metadata.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_config.dart';
import '../value_objects/backup_file_name.dart';
import '../value_objects/backup_passphrase.dart';

class CreateEncryptedJsonBackupExport {
  final BackupRepository repository;

  CreateEncryptedJsonBackupExport(this.repository);

  Future<AppResult<BackupMetadata>> call({
    required BackupFileName fileName,
    required BackupConfig config,
    required BackupPassphrase passphrase,
  }) {
    return repository.createEncryptedJsonBackup(
      fileName: fileName,
      config: config,
      passphrase: passphrase,
    );
  }
}
