import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class ToggleFavorite {
  final ContactsRepository repository;

  ToggleFavorite(this.repository);

  Future<AppResult<Contact>> call(String id) {
    return repository.toggleFavorite(id);
  }
}
