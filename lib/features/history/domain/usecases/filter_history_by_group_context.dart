import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class FilterHistoryByGroupContext {
  final HistoryRepository repository;

  FilterHistoryByGroupContext(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String groupId, {
    int? limit,
    int? offset,
  }) {
    return repository.filterHistoryByGroupContext(
      groupId,
      limit: limit,
      offset: offset,
    );
  }
}
