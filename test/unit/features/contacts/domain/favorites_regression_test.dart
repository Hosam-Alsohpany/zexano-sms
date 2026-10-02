import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/database/local_database.dart' as appDb;
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/data/datasources/contacts_local_source.dart';
import 'package:zexano_sms/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/contacts/domain/models/duplicate_result.dart';
import 'package:zexano_sms/features/contacts/domain/models/import_result.dart';
import 'package:zexano_sms/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:zexano_sms/features/contacts/domain/value_objects/contact_filter.dart';
import 'package:zexano_sms/features/contacts/presentation/controllers/contact_list_notifier.dart';
import 'package:zexano_sms/features/contacts/presentation/providers/contacts_providers.dart';

class FakeContactsRepository implements ContactsRepository {
  final Map<String, Contact> _contacts = {};

  void addContact(Contact contact) {
    _contacts[contact.id] = contact;
  }

  @override
  Future<AppResult<List<Contact>>> listContacts({ContactFilter? filter}) async {
    var list = _contacts.values.toList();
    if (filter != null) {
      if (filter.favoritesOnly == true) {
        list = list.where((c) => c.isFavorite).toList();
      }
    }
    return Right(list);
  }

  @override
  Stream<List<Contact>> watchContacts({ContactFilter? filter}) {
    var list = _contacts.values.toList();
    if (filter != null) {
      if (filter.favoritesOnly == true) {
        list = list.where((c) => c.isFavorite).toList();
      }
    }
    return Stream.value(list);
  }

  @override
  Future<AppResult<List<Contact>>> searchContacts(String query) async {
    final lower = query.toLowerCase();
    final list = _contacts.values
        .where((c) =>
            c.fullName.toLowerCase().contains(lower) ||
            c.phoneNumber.contains(lower))
        .toList();
    return Right(list);
  }

  @override
  Future<AppResult<Contact>> toggleFavorite(String id) async {
    final contact = _contacts[id];
    if (contact == null) return Left(DatabaseFailure(message: 'Not found'));
    final updated = contact.copyWith(isFavorite: !contact.isFavorite);
    _contacts[id] = updated;
    return Right(updated);
  }

  @override
  Future<AppResult<Contact>> getContactById(String id) async {
    final contact = _contacts[id];
    if (contact == null) return Left(DatabaseFailure(message: 'Not found'));
    return Right(contact);
  }

  @override
  Future<AppResult<Contact>> createContact(Contact contact) async => Right(contact);
  @override
  Future<AppResult<Contact>> updateContact(Contact contact) async => Right(contact);
  @override
  Future<AppResult<void>> deleteContact(String id) async {
    _contacts.remove(id);
    return const Right(null);
  }
  @override
  Future<AppResult<ImportResult>> importDeviceContacts({required List<Contact> deviceContacts}) async =>
      const Right(ImportResult(imported: [], duplicates: [], skippedCount: 0, totalProcessed: 0));
  @override
  Future<AppResult<List<DuplicateResult>>> detectDuplicates(Contact contact) async =>
      const Right([]);
  @override
  Future<AppResult<void>> assignTagsToContact({required String contactId, required List<String> tagIds}) async =>
      const Right(null);
  @override
  Future<AppResult<void>> removeTagsFromContact({required String contactId, required List<String> tagIds}) async =>
      const Right(null);
}

void main() {
  bool sqliteAvailable = false;

  setUpAll(() async {
    try {
      final probe = appDb.AppDatabase.forTesting(NativeDatabase.memory());
      await probe.customStatement('SELECT 1');
      await probe.close();
      sqliteAvailable = true;
    } catch (_) {
      sqliteAvailable = false;
    }
  });

  group('ContactListNotifier Favorites State & Filtering (Pure Dart)', () {
    test('Initial state loads all contacts', () async {
      final fakeRepo = FakeContactsRepository();
      fakeRepo.addContact(Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'حن🤍',
        phoneNumber: '+967771111111',
        isFavorite: false,
        createdAt: 0,
      ));
      fakeRepo.addContact(Contact(
        id: '2',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'مد🤍',
        phoneNumber: '+967772222222',
        isFavorite: true,
        createdAt: 0,
      ));

      final container = ProviderContainer(
        overrides: [
          contactsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = ContactListNotifier(container.read(refProvider));
      // Wait for async load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.value, hasLength(2));
      expect(notifier.favoritesOnly, isFalse);
    });

    test('setFavoritesOnly(true) filters list to only isFavorite == true', () async {
      final fakeRepo = FakeContactsRepository();
      fakeRepo.addContact(Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'حن🤍',
        phoneNumber: '+967771111111',
        isFavorite: false,
        createdAt: 0,
      ));
      fakeRepo.addContact(Contact(
        id: '2',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'مد🤍',
        phoneNumber: '+967772222222',
        isFavorite: true,
        createdAt: 0,
      ));

      final container = ProviderContainer(
        overrides: [
          contactsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = ContactListNotifier(container.read(refProvider));
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.setFavoritesOnly(true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.favoritesOnly, isTrue);
      expect(notifier.state.value, hasLength(1));
      expect(notifier.state.value!.first.fullName, 'عمتي مد🤍');
    });

    test('Unfavoriting a contact while in favorites mode immediately removes it from the list', () async {
      final fakeRepo = FakeContactsRepository();
      fakeRepo.addContact(Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'مد🤍',
        phoneNumber: '+967772222222',
        isFavorite: true,
        createdAt: 0,
      ));

      final container = ProviderContainer(
        overrides: [
          contactsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = ContactListNotifier(container.read(refProvider));
      notifier.setFavoritesOnly(true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.value, hasLength(1));

      // Toggle favorite on contact '1' (from true to false)
      await notifier.toggleFavorite('1');

      // The contact should immediately be removed from the favorites list
      expect(notifier.state.value, isEmpty);
    });
  });

  group('Favorites Database Persistence (Drift / SQLite)', () {
    test('Toggles contact from not favorite -> favorite, persisted in SQLite', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final database = appDb.AppDatabase.forTesting(NativeDatabase.memory());
      await database.customStatement('PRAGMA foreign_keys = ON');
      await database.into(database.tenants).insert(
            appDb.TenantsCompanion.insert(
              id: 'default-tenant',
              name: 'Test Workspace',
              accountType: 'INDIVIDUAL',
              createdAt: 1000000,
            ),
          );
      final localSource = ContactsLocalSource(database);
      final repository = ContactsRepositoryImpl(
        localSource: localSource,
        normalizationEngine: NormalizationEngine(),
        defaultTenantId: 'default-tenant',
      );

      await database.into(database.contacts).insert(
            appDb.ContactsCompanion.insert(
              id: 'c1',
              tenantId: 'default-tenant',
              firstName: 'عمتي',
              lastName: 'حن🤍',
              phoneNumber: '+967771111111',
              normalizedPhone: '+967771111111',
              isFavorite: 0,
              createdAt: 1000000,
            ),
          );

      // Check initial state
      final initial = await repository.getContactById('c1');
      expect(initial.isRight(), isTrue);
      expect(initial.getOrElse(() => throw '').isFavorite, isFalse);

      // Toggle to favorite
      final toggled = await repository.toggleFavorite('c1');
      expect(toggled.isRight(), isTrue);
      expect(toggled.getOrElse(() => throw '').isFavorite, isTrue);

      // Verify reloaded state
      final reloaded = await repository.getContactById('c1');
      expect(reloaded.isRight(), isTrue);
      expect(reloaded.getOrElse(() => throw '').isFavorite, isTrue);

      await database.close();
    });

    test('Toggles contact from favorite -> not favorite, persisted in SQLite', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final database = appDb.AppDatabase.forTesting(NativeDatabase.memory());
      await database.customStatement('PRAGMA foreign_keys = ON');
      await database.into(database.tenants).insert(
            appDb.TenantsCompanion.insert(
              id: 'default-tenant',
              name: 'Test Workspace',
              accountType: 'INDIVIDUAL',
              createdAt: 1000000,
            ),
          );
      final localSource = ContactsLocalSource(database);
      final repository = ContactsRepositoryImpl(
        localSource: localSource,
        normalizationEngine: NormalizationEngine(),
        defaultTenantId: 'default-tenant',
      );

      await database.into(database.contacts).insert(
            appDb.ContactsCompanion.insert(
              id: 'c2',
              tenantId: 'default-tenant',
              firstName: 'عمتي',
              lastName: 'مد🤍',
              phoneNumber: '+967772222222',
              normalizedPhone: '+967772222222',
              isFavorite: 1,
              createdAt: 1000000,
            ),
          );

      // Initial
      final initial = await repository.getContactById('c2');
      expect(initial.getOrElse(() => throw '').isFavorite, isTrue);

      // Toggle to unfavorite
      final toggled = await repository.toggleFavorite('c2');
      expect(toggled.isRight(), isTrue);
      expect(toggled.getOrElse(() => throw '').isFavorite, isFalse);

      // Verify reloaded state
      final reloaded = await repository.getContactById('c2');
      expect(reloaded.getOrElse(() => throw '').isFavorite, isFalse);

      await database.close();
    });

    test('ContactFilter(favoritesOnly: true) returns only favorites from DB', () async {
      if (!sqliteAvailable) return markTestSkipped('sqlite3 not available');

      final database = appDb.AppDatabase.forTesting(NativeDatabase.memory());
      await database.customStatement('PRAGMA foreign_keys = ON');
      await database.into(database.tenants).insert(
            appDb.TenantsCompanion.insert(
              id: 'default-tenant',
              name: 'Test Workspace',
              accountType: 'INDIVIDUAL',
              createdAt: 1000000,
            ),
          );
      final localSource = ContactsLocalSource(database);
      final repository = ContactsRepositoryImpl(
        localSource: localSource,
        normalizationEngine: NormalizationEngine(),
        defaultTenantId: 'default-tenant',
      );

      await database.into(database.contacts).insert(
            appDb.ContactsCompanion.insert(
              id: 'c1',
              tenantId: 'default-tenant',
              firstName: 'عمتي',
              lastName: 'حن🤍',
              phoneNumber: '+967771111111',
              normalizedPhone: '+967771111111',
              isFavorite: 1,
              createdAt: 1000000,
            ),
          );
      await database.into(database.contacts).insert(
            appDb.ContactsCompanion.insert(
              id: 'c2',
              tenantId: 'default-tenant',
              firstName: 'عمتي',
              lastName: 'مد🤍',
              phoneNumber: '+967772222222',
              normalizedPhone: '+967772222222',
              isFavorite: 0,
              createdAt: 1000000,
            ),
          );
      await database.into(database.contacts).insert(
            appDb.ContactsCompanion.insert(
              id: 'c3',
              tenantId: 'default-tenant',
              firstName: 'عمتي',
              lastName: 'نس🤍',
              phoneNumber: '+967773333333',
              normalizedPhone: '+967773333333',
              isFavorite: 1,
              createdAt: 1000000,
            ),
          );

      final favResult = await repository.listContacts(
        filter: const ContactFilter(favoritesOnly: true),
      );
      final favList = favResult.getOrElse(() => []);
      expect(favList.length, 2);
      expect(favList.map((c) => c.fullName).toList(), containsAll(['عمتي حن🤍', 'عمتي نس🤍']));
      expect(favList.map((c) => c.fullName).toList(), isNot(contains('عمتي مد🤍')));

      await database.close();
    });
  });
}

final refProvider = Provider<Ref>((ref) => ref);
