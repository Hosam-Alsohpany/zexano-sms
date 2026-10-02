import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_file_name.dart';

class GenerateBackupFileName {
  final BackupRepository repository;

  GenerateBackupFileName(this.repository);

  Future<AppResult<BackupFileName>> call({bool isEncrypted = false}) {
    return repository.generateBackupFileName(isEncrypted: isEncrypted);
  }
}
