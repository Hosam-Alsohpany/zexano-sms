import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/contacts_repository.dart';

class AssignTagsToContact {
  final ContactsRepository repository;

  AssignTagsToContact(this.repository);

  Future<AppResult<void>> call({
    required String contactId,
    required List<String> tagIds,
  }) {
    return repository.assignTagsToContact(
      contactId: contactId,
      tagIds: tagIds,
    );
  }
}
