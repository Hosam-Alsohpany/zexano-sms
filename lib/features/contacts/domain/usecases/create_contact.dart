import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class CreateContact {
  final ContactsRepository repository;

  CreateContact(this.repository);

  Future<AppResult<Contact>> call(Contact contact) {
    return repository.createContact(contact);
  }
}
