import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';
import '../value_objects/group_filter.dart';

class ListGroups {
  final GroupsRepository repository;

  ListGroups(this.repository);

  Future<AppResult<List<Group>>> call({GroupFilter? filter}) {
    return repository.listGroups(filter: filter);
  }
}
