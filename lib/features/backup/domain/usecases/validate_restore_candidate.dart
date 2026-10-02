import 'package:zexano_sms/core/errors/failures.dart';
import '../models/verification_result.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class ValidateRestoreCandidate {
  final BackupRepository repository;

  ValidateRestoreCandidate(this.repository);

  Future<AppResult<VerificationResult>> call(
    String filePath, {
    BackupPassphrase? passphrase,
  }) {
    return repository.validateRestoreCandidate(
      filePath,
      passphrase: passphrase,
    );
  }
}
