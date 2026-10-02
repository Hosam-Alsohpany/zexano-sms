import 'package:zexano_sms/core/errors/failures.dart';
import '../models/sms_batch_result.dart';
import '../repositories/sms_repository.dart';

class SendGroupSms {
  final SmsRepository repository;

  SendGroupSms(this.repository);

  Future<AppResult<SmsBatchResult>> call({
    required String groupId,
    required String messageBody,
    String channelType = 'sms',
  }) {
    return repository.sendGroupSms(
      groupId: groupId,
      messageBody: messageBody,
      channelType: channelType,
    );
  }
}
