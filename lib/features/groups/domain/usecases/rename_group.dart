import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class RenameGroup {
  final GroupsRepository repository;

  RenameGroup(this.repository);

  Future<AppResult<Group>> call(String id, String newName) {
    return repository.renameGroup(id, newName);
  }
}
