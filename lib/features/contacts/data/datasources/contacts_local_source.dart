import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart';
import 'package:zexano_sms/features/contacts/domain/value_objects/contact_filter.dart';

class ContactsLocalSource {
  final AppDatabase _db;

  ContactsLocalSource(this._db);

  Future<void> insertContact(ContactsCompanion companion) async {
    await _db.into(_db.contacts).insert(companion);
  }

  Future<void> updateContact(ContactsCompanion companion, String id) async {
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      companion,
    );
  }

  Future<void> deleteContact(String id) async {
    await (_db.delete(_db.contacts)..where((t) => t.id.equals(id))).go();
  }

  Future<Contact?> getContactById(String id) async {
    return await (_db.select(_db.contacts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Contact>> getAllContacts({ContactFilter? filter}) async {
    final query = _db.select(_db.contacts);

    if (filter != null) {
      if (filter.favoritesOnly == true) {
        query.where((t) => t.isFavorite.equals(1));
      }
      if (filter.operatorName != null) {
        query.where((t) => t.operatorName.equals(filter.operatorName!));
      }
      if (filter.limit != null) {
        query.limit(filter.limit!);
      }
    }

    query.orderBy([
      (t) => OrderingTerm.asc(t.firstName),
      (t) => OrderingTerm.asc(t.lastName),
    ]);

    return await query.get();
  }

  Stream<List<Contact>> watchAllContacts({ContactFilter? filter}) {
    final query = _db.select(_db.contacts);

    if (filter != null) {
      if (filter.favoritesOnly == true) {
        query.where((t) => t.isFavorite.equals(1));
      }
      if (filter.operatorName != null) {
        query.where((t) => t.operatorName.equals(filter.operatorName!));
      }
      if (filter.limit != null) {
        query.limit(filter.limit!);
      }
    }

    query.orderBy([
      (t) => OrderingTerm.asc(t.firstName),
      (t) => OrderingTerm.asc(t.lastName),
    ]);

    return query.watch();
  }

  Future<List<Contact>> searchContacts(String query) async {
    final searchTerm = '%${query.toLowerCase()}%';
    return await (_db.select(_db.contacts)
          ..where(
            (t) => t.firstName.lower().like(searchTerm) |
                t.lastName.lower().like(searchTerm) |
                t.phoneNumber.like(searchTerm) |
                t.normalizedPhone.like(searchTerm),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.firstName),
            (t) => OrderingTerm.asc(t.lastName),
          ]))
        .get();
  }

  Future<Contact?> getByNormalizedPhone(String phone) async {
    return await (_db.select(_db.contacts)
          ..where((t) => t.normalizedPhone.equals(phone)))
        .getSingleOrNull();
  }

  Future<List<Contact>> getByNormalizedPhones(List<String> phones) async {
    return await (_db.select(_db.contacts)
          ..where((t) => t.normalizedPhone.isIn(phones)))
        .get();
  }

  Future<List<String>> getTagIdsForContact(String contactId) async {
    final rows = await (_db.select(_db.contactTags)
          ..where((t) => t.contactId.equals(contactId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  Future<void> insertContactTag(String contactId, String tagId) async {
    await _db.into(_db.contactTags).insert(
      ContactTagsCompanion.insert(
        contactId: contactId,
        tagId: tagId,
      ),
    );
  }

  Future<void> deleteContactTags(
    String contactId,
    List<String> tagIds,
  ) async {
    await (_db.delete(_db.contactTags)
          ..where(
            (t) =>
                t.contactId.equals(contactId) & t.tagId.isIn(tagIds),
          ))
        .go();
  }

  Future<void> deleteAllContactTags(String contactId) async {
    await (_db.delete(_db.contactTags)
          ..where((t) => t.contactId.equals(contactId)))
        .go();
  }
}
