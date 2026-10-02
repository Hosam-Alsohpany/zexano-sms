import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/restore_report.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class RestoreFromEncryptedJsonBackup {
  final BackupRepository repository;

  RestoreFromEncryptedJsonBackup(this.repository);

  Future<AppResult<RestoreReport>> call({
    required String filePath,
    required BackupPassphrase passphrase,
  }) {
    return repository.restoreFromEncryptedJsonBackup(
      filePath: filePath,
      passphrase: passphrase,
    );
  }
}
