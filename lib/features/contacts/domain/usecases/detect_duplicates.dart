import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/contact.dart';
import '../models/duplicate_result.dart';
import '../repositories/contacts_repository.dart';

class DetectDuplicates {
  final ContactsRepository repository;

  DetectDuplicates(this.repository);

  Future<AppResult<List<DuplicateResult>>> call(Contact contact) {
    return repository.detectDuplicates(contact);
  }
}
