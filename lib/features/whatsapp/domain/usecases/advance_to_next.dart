import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/staged_recipient.dart';
import '../repositories/whatsapp_repository.dart';

class AdvanceToNext {
  final WhatsAppRepository repository;

  AdvanceToNext(this.repository);

  Future<AppResult<StagedRecipient?>> call(String sessionId) {
    return repository.advanceToNext(sessionId);
  }
}
