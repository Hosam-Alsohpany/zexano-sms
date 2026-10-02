import 'package:zexano_sms/core/errors/failures.dart';
import '../models/launch_result.dart';
import '../repositories/whatsapp_repository.dart';

class LaunchRecipient {
  final WhatsAppRepository repository;

  LaunchRecipient(this.repository);

  Future<AppResult<LaunchResult>> call(String recipientId) {
    return repository.launchRecipient(recipientId);
  }
}
