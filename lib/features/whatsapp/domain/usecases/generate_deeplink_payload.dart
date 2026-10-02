import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/whatsapp_repository.dart';
import '../value_objects/whatsapp_deeplink_payload.dart';

class GenerateDeeplinkPayload {
  final WhatsAppRepository repository;

  GenerateDeeplinkPayload(this.repository);

  Future<AppResult<WhatsAppDeeplinkPayload>> call({
    required String phoneNumber,
    required String messageBody,
    String? packageName,
  }) {
    return repository.generateDeeplinkPayload(
      phoneNumber: phoneNumber,
      messageBody: messageBody,
      packageName: packageName,
    );
  }
}
