import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class UpdateGroup {
  final GroupsRepository repository;

  UpdateGroup(this.repository);

  Future<AppResult<Group>> call(Group group) {
    return repository.updateGroup(group);
  }
}
