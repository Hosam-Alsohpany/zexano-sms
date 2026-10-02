import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/groups_repository.dart';

class RemoveContactFromGroup {
  final GroupsRepository repository;

  RemoveContactFromGroup(this.repository);

  Future<AppResult<void>> call(String groupId, String contactId) {
    return repository.removeContactFromGroup(
      groupId: groupId,
      contactId: contactId,
    );
  }
}
