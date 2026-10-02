import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class ValidateBackupPassphrase {
  final BackupRepository repository;

  ValidateBackupPassphrase(this.repository);

  Future<AppResult<bool>> call(BackupPassphrase passphrase) {
    return repository.validateBackupPassphrase(passphrase);
  }
}
