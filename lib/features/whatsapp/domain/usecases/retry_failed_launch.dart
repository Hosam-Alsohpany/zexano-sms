import 'package:zexano_sms/core/errors/failures.dart';
import '../models/launch_result.dart';
import '../repositories/whatsapp_repository.dart';

class RetryFailedLaunch {
  final WhatsAppRepository repository;

  RetryFailedLaunch(this.repository);

  Future<AppResult<LaunchResult>> call({
    required String sessionId,
    required String recipientId,
  }) {
    return repository.retryFailedLaunch(
      sessionId: sessionId,
      recipientId: recipientId,
    );
  }
}
