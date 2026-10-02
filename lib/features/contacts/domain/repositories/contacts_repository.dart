import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../models/duplicate_result.dart';
import '../models/import_result.dart';
import '../value_objects/contact_filter.dart';

abstract class ContactsRepository {
  Future<AppResult<Contact>> createContact(Contact contact);

  Future<AppResult<Contact>> updateContact(Contact contact);

  Future<AppResult<void>> deleteContact(String id);

  Future<AppResult<Contact>> getContactById(String id);

  Future<AppResult<List<Contact>>> listContacts({ContactFilter? filter});

  Stream<List<Contact>> watchContacts({ContactFilter? filter});

  Future<AppResult<List<Contact>>> searchContacts(String query);

  Future<AppResult<Contact>> toggleFavorite(String id);

  Future<AppResult<ImportResult>> importDeviceContacts({
    required List<Contact> deviceContacts,
  });

  Future<AppResult<List<DuplicateResult>>> detectDuplicates(Contact contact);

  Future<AppResult<void>> assignTagsToContact({
    required String contactId,
    required List<String> tagIds,
  });

  Future<AppResult<void>> removeTagsFromContact({
    required String contactId,
    required List<String> tagIds,
  });
}
