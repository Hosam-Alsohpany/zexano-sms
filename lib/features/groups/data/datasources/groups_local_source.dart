import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart';
import 'package:zexano_sms/features/groups/domain/value_objects/group_filter.dart';

class GroupsLocalSource {
  final AppDatabase _db;

  GroupsLocalSource(this._db);

  Future<void> insertGroup(GroupsCompanion companion) async {
    await _db.into(_db.groups).insert(companion);
  }

  Future<void> updateGroup(GroupsCompanion companion, String id) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(id))).write(
      companion,
    );
  }

  Future<void> deleteGroup(String id) async {
    await (_db.delete(_db.groups)..where((t) => t.id.equals(id))).go();
  }

  Future<Group?> getGroupById(String id) async {
    return await (_db.select(_db.groups)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Group?> getGroupByName(String name, String tenantId) async {
    return await (_db.select(_db.groups)
          ..where((t) => t.name.equals(name) & t.tenantId.equals(tenantId)))
        .getSingleOrNull();
  }

  Future<List<Group>> getAllGroups({GroupFilter? filter}) async {
    if (filter != null && filter.contactId != null) {
      final memberRows = await (_db.select(_db.groupMembers)
            ..where((t) => t.contactId.equals(filter.contactId!)))
          .get();
      final groupIds = memberRows.map((r) => r.groupId).toList();
      if (groupIds.isEmpty) return [];

      final query = _db.select(_db.groups)
        ..where((t) => t.id.isIn(groupIds))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]);

      if (filter.limit != null) {
        query.limit(filter.limit!);
      }

      return await query.get();
    }

    final query = _db.select(_db.groups);

    if (filter != null) {
      if (filter.query != null && filter.query!.isNotEmpty) {
        final term = '%${filter.query!.toLowerCase()}%';
        query.where((t) => t.name.lower().like(term));
      }

      if (filter.limit != null) {
        query.limit(filter.limit!);
      }
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);

    return await query.get();
  }

  Future<List<Group>> searchGroups(String queryText) async {
    final term = '%${queryText.toLowerCase()}%';
    return await (_db.select(_db.groups)
          ..where((t) => t.name.lower().like(term))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<Map<String, int>> getMemberCounts(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};
    final rows = await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.isIn(groupIds)))
        .get();
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row.groupId] = (counts[row.groupId] ?? 0) + 1;
    }
    return counts;
  }

  Future<int> getSingleGroupMemberCount(String groupId) async {
    final rows = await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    return rows.length;
  }

  Future<List<Contact>> getContactsInGroup(String groupId) async {
    final memberRows = await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
    final contactIds = memberRows.map((r) => r.contactId).toList();
    if (contactIds.isEmpty) return [];

    return await (_db.select(_db.contacts)
          ..where((t) => t.id.isIn(contactIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.firstName),
            (t) => OrderingTerm.asc(t.lastName),
          ]))
        .get();
  }

  Future<List<Group>> getGroupsForContact(String contactId) async {
    final memberRows = await (_db.select(_db.groupMembers)
          ..where((t) => t.contactId.equals(contactId)))
        .get();
    final groupIds = memberRows.map((r) => r.groupId).toList();
    if (groupIds.isEmpty) return [];

    return await (_db.select(_db.groups)
          ..where((t) => t.id.isIn(groupIds))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> insertGroupMember(String groupId, String contactId) async {
    await _db.into(_db.groupMembers).insert(
      GroupMembersCompanion.insert(
        groupId: groupId,
        contactId: contactId,
      ),
    );
  }

  Future<void> deleteGroupMember(String groupId, String contactId) async {
    await (_db.delete(_db.groupMembers)
          ..where(
            (t) => t.groupId.equals(groupId) & t.contactId.equals(contactId),
          ))
        .go();
  }

  Future<void> deleteAllGroupMembers(String groupId) async {
    await (_db.delete(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId)))
        .go();
  }

  Future<bool> isMember(String groupId, String contactId) async {
    final row = await (_db.select(_db.groupMembers)
          ..where(
            (t) => t.groupId.equals(groupId) & t.contactId.equals(contactId),
          ))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> batchInsertGroupMembers(
    List<GroupMembersCompanion> companions,
  ) async {
    await _db.batch((batch) {
      batch.insertAll(_db.groupMembers, companions);
    });
  }
}
