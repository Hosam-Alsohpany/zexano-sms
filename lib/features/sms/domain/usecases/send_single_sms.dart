import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/sms_message.dart';
import '../repositories/sms_repository.dart';

class SendSingleSms {
  final SmsRepository repository;

  SendSingleSms(this.repository);

  Future<AppResult<SmsMessage>> call({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
    String channelType = 'sms',
  }) {
    return repository.sendSingleSms(
      messageBody: messageBody,
      phoneNumber: phoneNumber,
      contactName: contactName,
      contactId: contactId,
      channelType: channelType,
    );
  }
}
