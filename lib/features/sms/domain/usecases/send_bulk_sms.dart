import 'package:zexano_sms/core/errors/failures.dart';
import '../models/sms_batch_result.dart';
import '../repositories/sms_repository.dart';
import '../value_objects/sms_payload.dart';

class SendBulkSms {
  final SmsRepository repository;

  SendBulkSms(this.repository);

  Future<AppResult<SmsBatchResult>> call(SmsPayload payload) {
    return repository.sendBulkSms(payload: payload);
  }
}
