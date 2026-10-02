import 'package:zexano_sms/core/errors/failures.dart';
import '../models/sms_validation_result.dart';
import '../repositories/sms_repository.dart';

class ValidateSmsPayload {
  final SmsRepository repository;

  ValidateSmsPayload(this.repository);

  Future<AppResult<SmsValidationResult>> call({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  }) {
    return repository.validateSmsPayload(
      messageBody: messageBody,
      phoneNumbers: phoneNumbers,
      channelType: channelType,
    );
  }
}
