import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/groups_repository.dart';

class AddContactToGroup {
  final GroupsRepository repository;

  AddContactToGroup(this.repository);

  Future<AppResult<void>> call(String groupId, String contactId) {
    return repository.addContactToGroup(
      groupId: groupId,
      contactId: contactId,
    );
  }
}
