import 'package:zexano_sms/core/errors/failures.dart';
import '../models/recipient_resolution_result.dart';
import '../repositories/whatsapp_repository.dart';

class BuildRecipientList {
  final WhatsAppRepository repository;

  BuildRecipientList(this.repository);

  Future<AppResult<RecipientResolutionResult>> call({
    List<String> contactIds = const [],
    List<String> groupIds = const [],
    List<String> manualPhones = const [],
  }) {
    return repository.buildRecipientList(
      contactIds: contactIds,
      groupIds: groupIds,
      manualPhones: manualPhones,
    );
  }
}
