import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../models/import_result.dart';
import '../repositories/contacts_repository.dart';

class ImportDeviceContacts {
  final ContactsRepository repository;

  ImportDeviceContacts(this.repository);

  Future<AppResult<ImportResult>> call(List<Contact> deviceContacts) {
    return repository.importDeviceContacts(deviceContacts: deviceContacts);
  }
}
