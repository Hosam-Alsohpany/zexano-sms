import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/assisted_session.dart';
import '../repositories/whatsapp_repository.dart';

class StageBulkMessages {
  final WhatsAppRepository repository;

  StageBulkMessages(this.repository);

  Future<AppResult<AssistedSession>> call({
    required String messageBody,
    required List<String> phoneNumbers,
    String? sessionId,
  }) {
    return repository.stageBulkMessages(
      messageBody: messageBody,
      phoneNumbers: phoneNumbers,
      sessionId: sessionId,
    );
  }
}
