import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class ListGroupsForContact {
  final GroupsRepository repository;

  ListGroupsForContact(this.repository);

  Future<AppResult<List<Group>>> call(String contactId) {
    return repository.listGroupsForContact(contactId);
  }
}
