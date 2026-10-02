import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class SearchContacts {
  final ContactsRepository repository;

  SearchContacts(this.repository);

  Future<AppResult<List<Contact>>> call(String query) {
    return repository.searchContacts(query);
  }
}
