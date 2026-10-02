import 'package:zexano_sms/core/errors/failures.dart';
import '../models/membership_result.dart';
import '../repositories/groups_repository.dart';

class AddMultipleContactsToGroup {
  final GroupsRepository repository;

  AddMultipleContactsToGroup(this.repository);

  Future<AppResult<MembershipResult>> call(
    String groupId,
    List<String> contactIds,
  ) {
    return repository.addMultipleContactsToGroup(
      groupId: groupId,
      contactIds: contactIds,
    );
  }
}
