import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/backup_metadata.dart';
import '../repositories/backup_repository.dart';

class ImportBackupFile {
  final BackupRepository repository;

  ImportBackupFile(this.repository);

  Future<AppResult<BackupMetadata>> call(String filePath) {
    return repository.importBackupFile(filePath);
  }
}
