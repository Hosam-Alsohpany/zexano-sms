import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';
import '../value_objects/contact_filter.dart';

class ListContacts {
  final ContactsRepository repository;

  ListContacts(this.repository);

  Future<AppResult<List<Contact>>> call({ContactFilter? filter}) {
    return repository.listContacts(filter: filter);
  }
}
