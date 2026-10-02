import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/groups_repository.dart';

class CheckMembership {
  final GroupsRepository repository;

  CheckMembership(this.repository);

  Future<AppResult<bool>> call(String groupId, String contactId) {
    return repository.checkMembership(
      groupId: groupId,
      contactId: contactId,
    );
  }
}
