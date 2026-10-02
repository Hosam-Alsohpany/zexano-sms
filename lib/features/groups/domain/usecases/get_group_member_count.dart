import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/groups_repository.dart';

class GetGroupMemberCount {
  final GroupsRepository repository;

  GetGroupMemberCount(this.repository);

  Future<AppResult<int>> call(String groupId) {
    return repository.getGroupMemberCount(groupId);
  }
}
