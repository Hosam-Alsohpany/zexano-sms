import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/contacts/data/mappers/contact_mapper.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/groups/data/datasources/groups_local_source.dart';
import 'package:zexano_sms/features/groups/data/mappers/group_mapper.dart';
import 'package:zexano_sms/features/groups/domain/entities/group.dart';
import 'package:zexano_sms/features/groups/domain/models/membership_result.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/groups/domain/value_objects/group_filter.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsLocalSource _localSource;
  final String _defaultTenantId;

  GroupsRepositoryImpl({
    required GroupsLocalSource localSource,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _defaultTenantId = defaultTenantId;

  @override
  Future<AppResult<Group>> createGroup(Group group) async {
    try {
      final normalizedName = group.name.trim();
      if (normalizedName.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Group name cannot be empty',
            code: 'EMPTY_GROUP_NAME',
          ),
        );
      }

      final enriched = group.copyWith(
        tenantId: _defaultTenantId,
        name: normalizedName,
      );

      final existing = await _localSource.getGroupByName(
        normalizedName,
        _defaultTenantId,
      );
      if (existing != null) {
        return const Left(
          ValidationFailure(
            message: 'A group with this name already exists',
            code: 'DUPLICATE_GROUP_NAME',
          ),
        );
      }

      await _localSource.insertGroup(
        GroupMapper.toInsertCompanion(enriched),
      );

      return Right(enriched);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create group: ${e.toString()}',
          code: 'CREATE_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Group>> updateGroup(Group group) async {
    try {
      final normalizedName = group.name.trim();
      if (normalizedName.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Group name cannot be empty',
            code: 'EMPTY_GROUP_NAME',
          ),
        );
      }

      final enriched = group.copyWith(name: normalizedName);

      final existing = await _localSource.getGroupByName(
        normalizedName,
        _defaultTenantId,
      );
      if (existing != null && existing.id != enriched.id) {
        return const Left(
          ValidationFailure(
            message: 'A group with this name already exists',
            code: 'DUPLICATE_GROUP_NAME',
          ),
        );
      }

      await _localSource.updateGroup(
        GroupMapper.toUpdateCompanion(enriched),
        enriched.id,
      );

      return Right(enriched);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update group: ${e.toString()}',
          code: 'UPDATE_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Group>> renameGroup(String id, String newName) async {
    try {
      final trimmed = newName.trim();
      if (trimmed.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Group name cannot be empty',
            code: 'EMPTY_GROUP_NAME',
          ),
        );
      }

      final existing = await _localSource.getGroupByName(
        trimmed,
        _defaultTenantId,
      );
      if (existing != null && existing.id != id) {
        return const Left(
          ValidationFailure(
            message: 'A group with this name already exists',
            code: 'DUPLICATE_GROUP_NAME',
          ),
        );
      }

      final row = await _localSource.getGroupById(id);
      if (row == null) {
        return const Left(
          DatabaseFailure(
            message: 'Group not found',
            code: 'GROUP_NOT_FOUND',
          ),
        );
      }

      final companion = db.GroupsCompanion(
        name: Value(trimmed),
      );
      await _localSource.updateGroup(companion, id);

      final count = await _localSource.getSingleGroupMemberCount(id);
      return Right(GroupMapper.toDomain(row.copyWith(name: trimmed), memberCount: count));
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to rename group: ${e.toString()}',
          code: 'RENAME_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> deleteGroup(String id) async {
    try {
      await _localSource.deleteAllGroupMembers(id);
      await _localSource.deleteGroup(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete group: ${e.toString()}',
          code: 'DELETE_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Group>> getGroupById(String id) async {
    try {
      final row = await _localSource.getGroupById(id);
      if (row == null) {
        return const Left(
          DatabaseFailure(
            message: 'Group not found',
            code: 'GROUP_NOT_FOUND',
          ),
        );
      }
      final count = await _localSource.getSingleGroupMemberCount(id);
      return Right(GroupMapper.toDomain(row, memberCount: count));
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get group: ${e.toString()}',
          code: 'GET_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Group>>> listGroups({GroupFilter? filter}) async {
    try {
      final rows = await _localSource.getAllGroups(filter: filter);
      if (rows.isEmpty) return const Right([]);

      final groupIds = rows.map((r) => r.id).toList();
      final counts = await _localSource.getMemberCounts(groupIds);

      final groups = rows.map((row) {
        final count = counts[row.id] ?? 0;
        return GroupMapper.toDomain(row, memberCount: count);
      }).toList();

      return Right(groups);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list groups: ${e.toString()}',
          code: 'LIST_GROUPS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Group>>> searchGroups(String queryText) async {
    try {
      final rows = await _localSource.searchGroups(queryText);
      if (rows.isEmpty) return const Right([]);

      final groupIds = rows.map((r) => r.id).toList();
      final counts = await _localSource.getMemberCounts(groupIds);

      final groups = rows.map((row) {
        final count = counts[row.id] ?? 0;
        return GroupMapper.toDomain(row, memberCount: count);
      }).toList();

      return Right(groups);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search groups: ${e.toString()}',
          code: 'SEARCH_GROUPS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> addContactToGroup({
    required String groupId,
    required String contactId,
  }) async {
    try {
      final exists = await _localSource.isMember(groupId, contactId);
      if (exists) {
        return const Right(null);
      }

      await _localSource.insertGroupMember(groupId, contactId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to add contact to group: ${e.toString()}',
          code: 'ADD_MEMBER_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> removeContactFromGroup({
    required String groupId,
    required String contactId,
  }) async {
    try {
      final exists = await _localSource.isMember(groupId, contactId);
      if (!exists) {
        return const Right(null);
      }

      await _localSource.deleteGroupMember(groupId, contactId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to remove contact from group: ${e.toString()}',
          code: 'REMOVE_MEMBER_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<MembershipResult>> addMultipleContactsToGroup({
    required String groupId,
    required List<String> contactIds,
  }) async {
    try {
      var addedCount = 0;
      final failedIds = <String>[];

      final companions = <db.GroupMembersCompanion>[];

      for (final contactId in contactIds) {
        try {
          final alreadyMember = await _localSource.isMember(groupId, contactId);
          if (!alreadyMember) {
            companions.add(
              db.GroupMembersCompanion.insert(
                groupId: groupId,
                contactId: contactId,
              ),
            );
            addedCount++;
          }
        } on Exception {
          failedIds.add(contactId);
        }
      }

      if (companions.isNotEmpty) {
        await _localSource.batchInsertGroupMembers(companions);
      }

      return Right(
        MembershipResult(
          groupId: groupId,
          addedCount: addedCount,
          removedCount: 0,
          failedContactIds: failedIds,
        ),
      );
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to add multiple contacts: ${e.toString()}',
          code: 'BULK_ADD_MEMBER_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Contact>>> listContactsInGroup(String groupId) async {
    try {
      final rows = await _localSource.getContactsInGroup(groupId);
      final contacts = rows.map((row) => ContactMapper.toDomain(row)).toList();
      return Right(contacts);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list contacts in group: ${e.toString()}',
          code: 'LIST_CONTACTS_IN_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Group>>> listGroupsForContact(String contactId) async {
    try {
      final rows = await _localSource.getGroupsForContact(contactId);
      if (rows.isEmpty) return const Right([]);

      final groupIds = rows.map((r) => r.id).toList();
      final counts = await _localSource.getMemberCounts(groupIds);

      final groups = rows.map((row) {
        final count = counts[row.id] ?? 0;
        return GroupMapper.toDomain(row, memberCount: count);
      }).toList();

      return Right(groups);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list groups for contact: ${e.toString()}',
          code: 'LIST_GROUPS_FOR_CONTACT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> checkMembership({
    required String groupId,
    required String contactId,
  }) async {
    try {
      final result = await _localSource.isMember(groupId, contactId);
      return Right(result);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to check membership: ${e.toString()}',
          code: 'CHECK_MEMBERSHIP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<int>> getGroupMemberCount(String groupId) async {
    try {
      final count = await _localSource.getSingleGroupMemberCount(groupId);
      return Right(count);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get group member count: ${e.toString()}',
          code: 'MEMBER_COUNT_ERR',
        ),
      );
    }
  }
}
