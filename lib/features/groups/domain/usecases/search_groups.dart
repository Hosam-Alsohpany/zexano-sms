import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class SearchGroups {
  final GroupsRepository repository;

  SearchGroups(this.repository);

  Future<AppResult<List<Group>>> call(String query) {
    return repository.searchGroups(query);
  }
}
