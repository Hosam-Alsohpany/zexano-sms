import 'package:zexano_sms/core/errors/failures.dart';
import '../models/recipient_resolution_result.dart';
import '../repositories/sms_repository.dart';

class BuildRecipientList {
  final SmsRepository repository;

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
