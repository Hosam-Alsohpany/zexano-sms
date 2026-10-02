import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class GetGroupById {
  final GroupsRepository repository;

  GetGroupById(this.repository);

  Future<AppResult<Group>> call(String id) {
    return repository.getGroupById(id);
  }
}
