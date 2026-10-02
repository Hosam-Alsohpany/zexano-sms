import 'package:zexano_sms/core/errors/failures.dart';
import '../models/restore_preview.dart';
import '../repositories/backup_repository.dart';
import '../value_objects/backup_passphrase.dart';

class PreviewRestoreSummary {
  final BackupRepository repository;

  PreviewRestoreSummary(this.repository);

  Future<AppResult<RestorePreview>> call(
    String filePath, {
    BackupPassphrase? passphrase,
  }) {
    return repository.previewRestoreSummary(
      filePath,
      passphrase: passphrase,
    );
  }
}
