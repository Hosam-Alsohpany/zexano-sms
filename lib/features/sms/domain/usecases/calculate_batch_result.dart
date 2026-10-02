import 'package:zexano_sms/core/errors/failures.dart';
import '../models/sms_batch_result.dart';
import '../repositories/sms_repository.dart';

class CalculateBatchResult {
  final SmsRepository repository;

  CalculateBatchResult(this.repository);

  Future<AppResult<SmsBatchResult>> call(String messageId) {
    return repository.calculateBatchResult(messageId);
  }
}
