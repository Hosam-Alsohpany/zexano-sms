import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/contacts_repository.dart';

class RemoveTagsFromContact {
  final ContactsRepository repository;

  RemoveTagsFromContact(this.repository);

  Future<AppResult<void>> call({
    required String contactId,
    required List<String> tagIds,
  }) {
    return repository.removeTagsFromContact(
      contactId: contactId,
      tagIds: tagIds,
    );
  }
}
