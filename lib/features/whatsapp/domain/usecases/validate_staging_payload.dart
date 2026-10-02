import 'package:zexano_sms/core/errors/failures.dart';
import '../models/whatsapp_validation_result.dart';
import '../repositories/whatsapp_repository.dart';

class ValidateStagingPayload {
  final WhatsAppRepository repository;

  ValidateStagingPayload(this.repository);

  Future<AppResult<WhatsAppValidationResult>> call({
    required String messageBody,
    required List<String> phoneNumbers,
  }) {
    return repository.validateStagingPayload(
      messageBody: messageBody,
      phoneNumbers: phoneNumbers,
    );
  }
}
