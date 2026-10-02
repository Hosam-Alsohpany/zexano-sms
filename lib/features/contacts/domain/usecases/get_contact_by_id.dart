import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class GetContactById {
  final ContactsRepository repository;

  GetContactById(this.repository);

  Future<AppResult<Contact>> call(String id) {
    return repository.getContactById(id);
  }
}
