import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/restore_report.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class ConfirmDestructiveRestore {
  final BackupRepository repository;

  ConfirmDestructiveRestore(this.repository);

  Future<AppResult<RestoreReport>> call({
    required String filePath,
    required bool confirmed,
    BackupPassphrase? passphrase,
  }) {
    return repository.confirmDestructiveRestore(
      filePath: filePath,
      confirmed: confirmed,
      passphrase: passphrase,
    );
  }
}
