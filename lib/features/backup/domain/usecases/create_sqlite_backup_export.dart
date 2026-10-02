import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/backup_metadata.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_file_name.dart';

class CreateSqliteBackupExport {
  final BackupRepository repository;

  CreateSqliteBackupExport(this.repository);

  Future<AppResult<BackupMetadata>> call(BackupFileName fileName) {
    return repository.createSqliteBackup(fileName: fileName);
  }
}
