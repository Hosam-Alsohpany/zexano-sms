import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class UpdateContact {
  final ContactsRepository repository;

  UpdateContact(this.repository);

  Future<AppResult<Contact>> call(Contact contact) {
    return repository.updateContact(contact);
  }
}
