import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import '../repositories/groups_repository.dart';

class ListContactsInGroup {
  final GroupsRepository repository;

  ListContactsInGroup(this.repository);

  Future<AppResult<List<Contact>>> call(String groupId) {
    return repository.listContactsInGroup(groupId);
  }
}
