import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/contacts_repository.dart';

class DeleteContact {
  final ContactsRepository repository;

  DeleteContact(this.repository);

  Future<AppResult<void>> call(String id) {
    return repository.deleteContact(id);
  }
}
