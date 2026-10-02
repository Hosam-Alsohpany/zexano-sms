import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/staged_recipient.dart';
import '../repositories/whatsapp_repository.dart';

class StageSingleMessage {
  final WhatsAppRepository repository;

  StageSingleMessage(this.repository);

  Future<AppResult<StagedRecipient>> call({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
  }) {
    return repository.stageSingleMessage(
      messageBody: messageBody,
      phoneNumber: phoneNumber,
      contactName: contactName,
      contactId: contactId,
    );
  }
}
