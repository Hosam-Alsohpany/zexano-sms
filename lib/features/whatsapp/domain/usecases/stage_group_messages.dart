import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/assisted_session.dart';
import '../repositories/whatsapp_repository.dart';

class StageGroupMessages {
  final WhatsAppRepository repository;

  StageGroupMessages(this.repository);

  Future<AppResult<AssistedSession>> call({
    required String groupId,
    required String messageBody,
  }) {
    return repository.stageGroupMessages(
      groupId: groupId,
      messageBody: messageBody,
    );
  }
}
