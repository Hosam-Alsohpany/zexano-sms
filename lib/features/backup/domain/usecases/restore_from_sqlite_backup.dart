import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/restore_report.dart';
import '../repositories/backup_repository.dart';

class RestoreFromSqliteBackup {
  final BackupRepository repository;

  RestoreFromSqliteBackup(this.repository);

  Future<AppResult<RestoreReport>> call(String filePath) {
    return repository.restoreFromSqliteBackup(filePath);
  }
}
