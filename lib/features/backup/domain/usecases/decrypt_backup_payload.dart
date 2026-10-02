import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class DecryptBackupPayload {
  final BackupRepository repository;

  DecryptBackupPayload(this.repository);

  Future<AppResult<String>> call({
    required String encryptedPayload,
    required BackupPassphrase passphrase,
  }) {
    return repository.decryptBackupPayload(
      encryptedPayload: encryptedPayload,
      passphrase: passphrase,
    );
  }
}
