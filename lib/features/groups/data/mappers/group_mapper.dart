import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/features/groups/domain/entities/group.dart';

class GroupMapper {
  static Group toDomain(
    db.Group row, {
    int memberCount = 0,
  }) {
    return Group(
      id: row.id,
      tenantId: row.tenantId,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      memberCount: memberCount,
    );
  }

  static db.GroupsCompanion toInsertCompanion(Group group) {
    return db.GroupsCompanion.insert(
      id: group.id,
      tenantId: group.tenantId,
      name: group.name,
      description: group.description,
      createdAt: group.createdAt,
    );
  }

  static db.GroupsCompanion toUpdateCompanion(Group group) {
    return db.GroupsCompanion(
      id: Value(group.id),
      tenantId: Value(group.tenantId),
      name: Value(group.name),
      description: Value(group.description),
      createdAt: Value(group.createdAt),
    );
  }
}
