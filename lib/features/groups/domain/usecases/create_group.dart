import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class CreateGroup {
  final GroupsRepository repository;

  CreateGroup(this.repository);

  Future<AppResult<Group>> call(Group group) {
    return repository.createGroup(group);
  }
}
