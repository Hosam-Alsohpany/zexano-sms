import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/groups_repository.dart';

class DeleteGroup {
  final GroupsRepository repository;

  DeleteGroup(this.repository);

  Future<AppResult<void>> call(String id) {
    return repository.deleteGroup(id);
  }
}
