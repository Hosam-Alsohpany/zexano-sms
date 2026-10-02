// Regression tests for HOTFIX BATCH C — Database Integrity Fixes
//
// Issues covered:
//   #1 — notes nullable: null stored in DB maps to '' in domain
//   #2 — operatorName nullable: null stored in DB maps to '' in domain
//   #3 — WhatsAppPreference UNIQUE(tenantId): one row per tenant enforced
//   #4 — ContactTags, GroupMembers ON DELETE CASCADE
//   #5 — StagedRecipients ON DELETE CASCADE when session is deleted
//
// Pure-Dart mapper tests (Groups #1/#2) always run — no native dependency.
// DB-backed tests require sqlite3.dll; on Windows Dart-VM they skip when absent.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:zexano_sms/core/database/local_database.dart' as appDb;
import 'package:zexano_sms/features/contacts/data/mappers/contact_mapper.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart'
    as domain;
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _uuid = Uuid();

appDb.AppDatabase _makeDb() =>
    appDb.AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _seedTenant(appDb.AppDatabase db) async {
  await db.customStatement('PRAGMA foreign_keys = ON');
  await db.into(db.tenants).insert(
        appDb.TenantsCompanion.insert(
          id: 'default-tenant',
          name: 'Test Workspace',
          accountType: 'INDIVIDUAL',
          createdAt: 1000000,
        ),
      );
}

Future<String> _insertContact(
  appDb.AppDatabase db, {
  String? id,
  String phone = '+9671000000',
}) async {
  final contactId = id ?? _uuid.v4();
  await db.into(db.contacts).insert(appDb.ContactsCompanion.insert(
        id: contactId,
        tenantId: 'default-tenant',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: phone,
        normalizedPhone: phone,
        isFavorite: 0,
        createdAt: 1000000,
      ));
  return contactId;
}

Future<String> _insertTag(appDb.AppDatabase db) async {
  final tagId = _uuid.v4();
  await db.into(db.tags).insert(appDb.TagsCompanion.insert(
        id: tagId,
        tenantId: 'default-tenant',
        name: 'TestTag',
        createdAt: 1000000,
      ));
  return tagId;
}

Future<String> _insertGroup(appDb.AppDatabase db) async {
  final groupId = _uuid.v4();
  await db.into(db.groups).insert(appDb.GroupsCompanion.insert(
        id: groupId,
        tenantId: 'default-tenant',
        name: 'TestGroup',
        description: '',
        createdAt: 1000000,
      ));
  return groupId;
}

Future<String> _insertSession(appDb.AppDatabase db) async {
  final sessionId = _uuid.v4();
  await db.into(db.assistedSessions).insert(
        appDb.AssistedSessionsCompanion.insert(
          sessionId: sessionId,
          tenantId: 'default-tenant',
          messageBody: 'Hello',
          totalRecipients: 1,
          completedRecipients: 0,
          failedRecipients: 0,
          currentIndex: 0,
          status: 'in_progress',
          createdAt: 1000000,
        ),
      );
  return sessionId;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Detect at runtime whether sqlite3 native library is available.
  // setUpAll runs before any test so the async probe fires correctly.
  bool sqliteAvailable = false;

  setUpAll(() async {
    try {
      final probe = _makeDb();
      await probe.customStatement('SELECT 1');
      await probe.close();
      sqliteAvailable = true;
    } catch (_) {
      sqliteAvailable = false;
    }
  });

  // ── Issue #1 — notes nullable (pure Dart, always run) ────────────────────

  group('Issue #1 — notes nullable (mapper, no DB)', () {
    test('toInsertCompanion stores empty notes as null', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        notes: '',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toInsertCompanion(contact);
      expect(companion.notes.value, isNull);
    });

    test('toInsertCompanion preserves non-empty notes', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        notes: 'Some note',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toInsertCompanion(contact);
      expect(companion.notes.value, equals('Some note'));
    });

    test('toUpdateCompanion stores empty notes as null', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        notes: '',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toUpdateCompanion(contact);
      expect(companion.notes.value, isNull);
    });
  });

  // ── Issue #2 — operatorName nullable (pure Dart, always run) ─────────────

  group('Issue #2 — operatorName nullable (mapper, no DB)', () {
    test('toInsertCompanion stores empty operatorName as null', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        operatorName: '',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toInsertCompanion(contact);
      expect(companion.operatorName.value, isNull);
    });

    test('toInsertCompanion preserves known operatorName', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        operatorName: 'Yemen Mobile',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toInsertCompanion(contact);
      expect(companion.operatorName.value, equals('Yemen Mobile'));
    });

    test('toUpdateCompanion stores empty operatorName as null', () {
      final contact = domain.Contact(
        id: _uuid.v4(),
        tenantId: 'default-tenant',
        operatorName: '',
        createdAt: 1000000,
      );
      final companion = ContactMapper.toUpdateCompanion(contact);
      expect(companion.operatorName.value, isNull);
    });
  });

  // ── DB-backed tests ───────────────────────────────────────────────────────
  // All tests below open an in-memory SQLite database.
  // They skip automatically when sqlite3.dll is not available on the host.

  group('Issue #1 — notes nullable (DB round-trip)', () {
    test('null notes stored in DB is read back as null, mapped to ""', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      final id = _uuid.v4();
      await db.into(db.contacts).insert(appDb.ContactsCompanion.insert(
            id: id,
            tenantId: 'default-tenant',
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '+9671111111',
            normalizedPhone: '+9671111111',
            notes: const Value(null),
            isFavorite: 0,
            createdAt: 1000000,
          ));

      final row = await (db.select(db.contacts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.notes, isNull);
      expect(ContactMapper.toDomain(row).notes, equals(''));
      await db.close();
    });
  });

  group('Issue #2 — operatorName nullable (DB round-trip)', () {
    test('null operatorName stored in DB is mapped to "" in domain', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      final id = _uuid.v4();
      await db.into(db.contacts).insert(appDb.ContactsCompanion.insert(
            id: id,
            tenantId: 'default-tenant',
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '+9671111113',
            normalizedPhone: '+9671111113',
            operatorName: const Value(null),
            isFavorite: 0,
            createdAt: 1000000,
          ));

      final row = await (db.select(db.contacts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      expect(ContactMapper.toDomain(row!).operatorName, equals(''));
      await db.close();
    });
  });

  group('Issue #3 — WhatsAppPreference UNIQUE(tenantId)', () {
    test('second insert for same tenant throws UNIQUE constraint error',
        () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      await db.into(db.whatsAppPreference).insert(
            appDb.WhatsAppPreferenceCompanion.insert(
              id: 'pref-1',
              tenantId: 'default-tenant',
              packageName: 'com.whatsapp',
              appName: 'WhatsApp',
              isSet: 1,
            ),
          );

      await expectLater(
        () => db.into(db.whatsAppPreference).insert(
              appDb.WhatsAppPreferenceCompanion.insert(
                id: 'pref-2',
                tenantId: 'default-tenant',
                packageName: 'com.whatsapp.w4b',
                appName: 'WhatsApp Business',
                isSet: 1,
              ),
            ),
        throwsA(anything),
        reason: 'UNIQUE(tenantId) must reject duplicate rows per tenant',
      );
      await db.close();
    });

    test('insertOrReplace on same id keeps exactly one row', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      await db.into(db.whatsAppPreference).insert(
            appDb.WhatsAppPreferenceCompanion.insert(
              id: 'preferred_whatsapp_app',
              tenantId: 'default-tenant',
              packageName: 'com.whatsapp',
              appName: 'WhatsApp',
              isSet: 1,
            ),
          );
      await db.into(db.whatsAppPreference).insert(
            appDb.WhatsAppPreferenceCompanion.insert(
              id: 'preferred_whatsapp_app',
              tenantId: 'default-tenant',
              packageName: 'com.whatsapp.w4b',
              appName: 'WhatsApp Business',
              isSet: 1,
            ),
            mode: InsertMode.insertOrReplace,
          );

      final rows = await db.select(db.whatsAppPreference).get();
      expect(rows.length, equals(1));
      expect(rows.first.packageName, equals('com.whatsapp.w4b'));
      await db.close();
    });
  });

  group('Issue #4 — ContactTags ON DELETE CASCADE', () {
    test('deleting a contact removes its ContactTags automatically', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      final contactId = await _insertContact(db);
      final tagId = await _insertTag(db);
      await db.into(db.contactTags).insert(
            appDb.ContactTagsCompanion.insert(
              contactId: contactId,
              tagId: tagId,
            ),
          );

      await (db.delete(db.contacts)
            ..where((t) => t.id.equals(contactId)))
          .go();

      final remaining = await (db.select(db.contactTags)
            ..where((t) => t.contactId.equals(contactId)))
          .get();
      expect(remaining, isEmpty,
          reason: 'ContactTags must cascade-delete with their contact');
      await db.close();
    });
  });

  group('Issue #4 — GroupMembers ON DELETE CASCADE', () {
    test('deleting a group removes its GroupMembers automatically', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      final contactId = await _insertContact(db, phone: '+9671000001');
      final groupId = await _insertGroup(db);
      await db.into(db.groupMembers).insert(
            appDb.GroupMembersCompanion.insert(
              groupId: groupId,
              contactId: contactId,
            ),
          );

      await (db.delete(db.groups)..where((t) => t.id.equals(groupId))).go();

      final remaining = await (db.select(db.groupMembers)
            ..where((t) => t.groupId.equals(groupId)))
          .get();
      expect(remaining, isEmpty,
          reason: 'GroupMembers must cascade-delete with their group');
      await db.close();
    });

    test('deleting a contact removes its group memberships automatically',
        () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);

      final contactId = await _insertContact(db, phone: '+9671000002');
      final groupId = await _insertGroup(db);
      await db.into(db.groupMembers).insert(
            appDb.GroupMembersCompanion.insert(
              groupId: groupId,
              contactId: contactId,
            ),
          );

      await (db.delete(db.contacts)
            ..where((t) => t.id.equals(contactId)))
          .go();

      final remaining = await (db.select(db.groupMembers)
            ..where((t) => t.contactId.equals(contactId)))
          .get();
      expect(remaining, isEmpty,
          reason: 'GroupMembers must cascade-delete with their contact');
      await db.close();
    });
  });

  group('Issue #5 — StagedRecipients ON DELETE CASCADE', () {
    test('deleting a session removes all its StagedRecipients automatically',
        () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final db = _makeDb();
      await _seedTenant(db);
      final sessionId = await _insertSession(db);

      for (var i = 0; i < 2; i++) {
        await db.into(db.stagedRecipients).insert(
              appDb.StagedRecipientsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                phoneNumber: '+96770000000$i',
                contactName: 'Recipient $i',
                status: 'pending',
                launchSuccess: 0,
              ),
            );
      }

      await (db.delete(db.assistedSessions)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();

      final remaining = await (db.select(db.stagedRecipients)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();
      expect(remaining, isEmpty,
          reason: 'StagedRecipients must cascade-delete with their session');
      await db.close();
    });
  });

  group('Schema version', () {
    test('AppDatabase.schemaVersion equals 4', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');
      final db = _makeDb();
      expect(db.schemaVersion, equals(4));
      await db.close();
    });
  });
}
