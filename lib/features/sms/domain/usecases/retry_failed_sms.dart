import 'package:zexano_sms/core/errors/failures.dart';
import '../models/sms_retry_result.dart';
import '../repositories/sms_repository.dart';

class RetryFailedSms {
  final SmsRepository repository;

  RetryFailedSms(this.repository);

  Future<AppResult<SmsRetryResult>> call(String messageId) {
    return repository.retryFailedSms(messageId);
  }
}
