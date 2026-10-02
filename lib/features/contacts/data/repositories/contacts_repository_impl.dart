import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/data/datasources/contacts_local_source.dart';
import 'package:zexano_sms/features/contacts/data/mappers/contact_mapper.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/contacts/domain/models/duplicate_result.dart';
import 'package:zexano_sms/features/contacts/domain/models/import_result.dart';
import 'package:zexano_sms/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:zexano_sms/features/contacts/domain/value_objects/contact_filter.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsLocalSource _localSource;
  final NormalizationEngine _normalizationEngine;
  final String _defaultTenantId;

  ContactsRepositoryImpl({
    required ContactsLocalSource localSource,
    required NormalizationEngine normalizationEngine,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _normalizationEngine = normalizationEngine,
        _defaultTenantId = defaultTenantId;

  @override
  Future<AppResult<Contact>> createContact(Contact contact) async {
    try {
      final normalized = _normalizationEngine.normalize(contact.phoneNumber);
      final operatorRaw = _normalizationEngine.extractOperator(normalized);
      // 'Unknown' is a sentinel — represent it as '' so the mapper stores null.
      final operator = operatorRaw == 'Unknown' ? '' : operatorRaw;

      final enriched = contact.copyWith(
        tenantId: _defaultTenantId,
        normalizedPhone: normalized,
        operatorName: operator,
      );

      await _localSource.insertContact(
        ContactMapper.toInsertCompanion(enriched),
      );

      return Right(enriched);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create contact: ${e.toString()}',
          code: 'CREATE_CONTACT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Contact>> updateContact(Contact contact) async {
    try {
      final normalized = _normalizationEngine.normalize(contact.phoneNumber);
      final operatorRaw = _normalizationEngine.extractOperator(normalized);
      // 'Unknown' is a sentinel — represent it as '' so the mapper stores null.
      final operator = operatorRaw == 'Unknown' ? '' : operatorRaw;

      final enriched = contact.copyWith(
        normalizedPhone: normalized,
        operatorName: operator,
      );

      await _localSource.updateContact(
        ContactMapper.toUpdateCompanion(enriched),
        enriched.id,
      );

      return Right(enriched);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update contact: ${e.toString()}',
          code: 'UPDATE_CONTACT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> deleteContact(String id) async {
    try {
      await _localSource.deleteAllContactTags(id);
      await _localSource.deleteContact(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete contact: ${e.toString()}',
          code: 'DELETE_CONTACT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Contact>> getContactById(String id) async {
    try {
      final row = await _localSource.getContactById(id);
      if (row == null) {
        return const Left(
          DatabaseFailure(
            message: 'Contact not found',
            code: 'CONTACT_NOT_FOUND',
          ),
        );
      }
      final tagIds = await _localSource.getTagIdsForContact(id);
      return Right(ContactMapper.toDomain(row, tagIds: tagIds));
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get contact: ${e.toString()}',
          code: 'GET_CONTACT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Contact>>> listContacts({ContactFilter? filter}) async {
    try {
      final rows = await _localSource.getAllContacts(filter: filter);
      final contacts = <Contact>[];
      for (final row in rows) {
        final tagIds = await _localSource.getTagIdsForContact(row.id);
        contacts.add(ContactMapper.toDomain(row, tagIds: tagIds));
      }
      return Right(contacts);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list contacts: ${e.toString()}',
          code: 'LIST_CONTACTS_ERR',
        ),
      );
    }
  }

  @override
  Stream<List<Contact>> watchContacts({ContactFilter? filter}) {
    return _localSource.watchAllContacts(filter: filter).map((rows) {
      return rows.map((row) => ContactMapper.toDomain(row)).toList();
    });
  }

  @override
  Future<AppResult<List<Contact>>> searchContacts(String query) async {
    try {
      final rows = await _localSource.searchContacts(query);
      final contacts = <Contact>[];
      for (final row in rows) {
        final tagIds = await _localSource.getTagIdsForContact(row.id);
        contacts.add(ContactMapper.toDomain(row, tagIds: tagIds));
      }
      return Right(contacts);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search contacts: ${e.toString()}',
          code: 'SEARCH_CONTACTS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<Contact>> toggleFavorite(String id) async {
    try {
      final row = await _localSource.getContactById(id);
      if (row == null) {
        return const Left(
          DatabaseFailure(
            message: 'Contact not found',
            code: 'CONTACT_NOT_FOUND',
          ),
        );
      }

      final newFav = row.isFavorite == 1 ? 0 : 1;
      final companion = db.ContactsCompanion(
        isFavorite: Value(newFav),
      );
      await _localSource.updateContact(companion, id);

      final tagIds = await _localSource.getTagIdsForContact(id);
      final updated = ContactMapper.toDomain(
        row.copyWith(isFavorite: newFav),
        tagIds: tagIds,
      );
      return Right(updated);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to toggle favorite: ${e.toString()}',
          code: 'TOGGLE_FAVORITE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<ImportResult>> importDeviceContacts({
    required List<Contact> deviceContacts,
  }) async {
    try {
      final imported = <Contact>[];
      final duplicates = <DuplicateResult>[];
      var skipped = 0;

      final normalizedToContact = <String, Contact>{};
      final normalizedPhones = <String>[];

      for (final raw in deviceContacts) {
        final normalized = _normalizationEngine.normalize(raw.phoneNumber);
        if (normalized.isEmpty) {
          skipped++;
          continue;
        }

        final operatorRaw = _normalizationEngine.extractOperator(normalized);
        final operator = operatorRaw == 'Unknown' ? '' : operatorRaw;
        final enriched = raw.copyWith(
          tenantId: _defaultTenantId,
          normalizedPhone: normalized,
          operatorName: operator,
        );

        normalizedToContact[normalized] = enriched;
        normalizedPhones.add(normalized);
      }

      final existing =
          await _localSource.getByNormalizedPhones(normalizedPhones);
      final existingPhones = existing.map((e) => e.normalizedPhone).toSet();

      for (final entry in normalizedToContact.entries) {
        final normalized = entry.key;
        final contact = entry.value;

        if (existingPhones.contains(normalized)) {
          final matchedRow =
              existing.firstWhere((e) => e.normalizedPhone == normalized);
          duplicates.add(
            DuplicateResult(
              existing: ContactMapper.toDomain(matchedRow),
              incoming: contact,
              matchScore: 1.0,
              matchedFields: ['normalizedPhone'],
            ),
          );
          skipped++;
          continue;
        }

        await _localSource.insertContact(
          ContactMapper.toInsertCompanion(contact),
        );
        imported.add(contact);
      }

      return Right(
        ImportResult(
          imported: imported,
          duplicates: duplicates,
          skippedCount: skipped,
          totalProcessed: deviceContacts.length,
        ),
      );
    } on Exception catch (e) {
      return Left(
        ContactImportFailure(
          message: 'Failed to import contacts: ${e.toString()}',
          code: 'IMPORT_CONTACTS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<DuplicateResult>>> detectDuplicates(
    Contact contact,
  ) async {
    try {
      final normalized = _normalizationEngine.normalize(contact.phoneNumber);
      if (normalized.isEmpty) {
        return const Right([]);
      }

      final matched = await _localSource.getByNormalizedPhone(normalized);
      if (matched == null) {
        return const Right([]);
      }

      return Right([
        DuplicateResult(
          existing: ContactMapper.toDomain(matched),
          incoming: contact,
          matchScore: 1.0,
          matchedFields: ['normalizedPhone'],
        ),
      ]);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to detect duplicates: ${e.toString()}',
          code: 'DETECT_DUPLICATE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> assignTagsToContact({
    required String contactId,
    required List<String> tagIds,
  }) async {
    try {
      for (final tagId in tagIds) {
        await _localSource.insertContactTag(contactId, tagId);
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to assign tags: ${e.toString()}',
          code: 'ASSIGN_TAGS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> removeTagsFromContact({
    required String contactId,
    required List<String> tagIds,
  }) async {
    try {
      await _localSource.deleteContactTags(contactId, tagIds);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to remove tags: ${e.toString()}',
          code: 'REMOVE_TAGS_ERR',
        ),
      );
    }
  }
}
