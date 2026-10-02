import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

class ContactMapper {
  static Contact toDomain(
    db.Contact row, {
    List<String> tagIds = const [],
  }) {
    return Contact(
      id: row.id,
      tenantId: row.tenantId,
      firstName: row.firstName,
      lastName: row.lastName,
      phoneNumber: row.phoneNumber,
      normalizedPhone: row.normalizedPhone,
      // Issue #2: operatorName is nullable in DB; map null → '' for the domain.
      operatorName: row.operatorName ?? '',
      // Issue #1: notes is nullable in DB; map null → '' for the domain.
      notes: row.notes ?? '',
      isFavorite: row.isFavorite == 1,
      createdAt: row.createdAt,
      tagIds: tagIds.toSet(),
    );
  }

  static db.ContactsCompanion toInsertCompanion(Contact contact) {
    return db.ContactsCompanion.insert(
      id: contact.id,
      tenantId: contact.tenantId,
      firstName: contact.firstName,
      lastName: contact.lastName,
      phoneNumber: contact.phoneNumber,
      normalizedPhone: contact.normalizedPhone,
      // Store null when the operator is unknown/empty (Issue #2).
      operatorName: Value(contact.operatorName.isEmpty ? null : contact.operatorName),
      // Store null when notes are empty (Issue #1).
      notes: Value(contact.notes.isEmpty ? null : contact.notes),
      isFavorite: contact.isFavorite ? 1 : 0,
      createdAt: contact.createdAt,
    );
  }

  static db.ContactsCompanion toUpdateCompanion(Contact contact) {
    return db.ContactsCompanion(
      id: Value(contact.id),
      tenantId: Value(contact.tenantId),
      firstName: Value(contact.firstName),
      lastName: Value(contact.lastName),
      phoneNumber: Value(contact.phoneNumber),
      normalizedPhone: Value(contact.normalizedPhone),
      // Store null when the operator is unknown/empty (Issue #2).
      operatorName: Value(contact.operatorName.isEmpty ? null : contact.operatorName),
      // Store null when notes are empty (Issue #1).
      notes: Value(contact.notes.isEmpty ? null : contact.notes),
      isFavorite: Value(contact.isFavorite ? 1 : 0),
      createdAt: Value(contact.createdAt),
    );
  }
}
