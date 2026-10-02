import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/sms_message.dart';
import '../repositories/sms_repository.dart';

class QueueSms {
  final SmsRepository repository;

  QueueSms(this.repository);

  Future<AppResult<SmsMessage>> call({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  }) {
    return repository.queueSms(
      messageBody: messageBody,
      phoneNumbers: phoneNumbers,
      channelType: channelType,
    );
  }
}
