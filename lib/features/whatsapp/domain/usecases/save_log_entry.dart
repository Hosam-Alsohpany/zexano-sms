import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/staged_recipient.dart';
import '../repositories/whatsapp_repository.dart';

class SaveLogEntry {
  final WhatsAppRepository repository;

  SaveLogEntry(this.repository);

  Future<AppResult<void>> call(StagedRecipient entry) {
    return repository.saveLogEntry(entry);
  }
}
