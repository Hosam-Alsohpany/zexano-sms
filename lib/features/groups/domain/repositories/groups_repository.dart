import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import '../entities/group.dart';
import '../models/membership_result.dart';
import '../value_objects/group_filter.dart';

abstract class GroupsRepository {
  Future<AppResult<Group>> createGroup(Group group);

  Future<AppResult<Group>> updateGroup(Group group);

  Future<AppResult<Group>> renameGroup(String id, String newName);

  Future<AppResult<void>> deleteGroup(String id);

  Future<AppResult<Group>> getGroupById(String id);

  Future<AppResult<List<Group>>> listGroups({GroupFilter? filter});

  Future<AppResult<List<Group>>> searchGroups(String query);

  Future<AppResult<void>> addContactToGroup({
    required String groupId,
    required String contactId,
  });

  Future<AppResult<void>> removeContactFromGroup({
    required String groupId,
    required String contactId,
  });

  Future<AppResult<MembershipResult>> addMultipleContactsToGroup({
    required String groupId,
    required List<String> contactIds,
  });

  Future<AppResult<List<Contact>>> listContactsInGroup(String groupId);

  Future<AppResult<List<Group>>> listGroupsForContact(String contactId);

  Future<AppResult<bool>> checkMembership({
    required String groupId,
    required String contactId,
  });

  Future<AppResult<int>> getGroupMemberCount(String groupId);
}
