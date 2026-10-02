import 'package:zexano_sms/core/errors/failures.dart';
import '../models/verification_result.dart';
import '../repositories/backup_repository.dart';

class VerifyBackupFileIntegrity {
  final BackupRepository repository;

  VerifyBackupFileIntegrity(this.repository);

  Future<AppResult<VerificationResult>> call(String filePath) {
    return repository.verifyBackupIntegrity(filePath);
  }
}
