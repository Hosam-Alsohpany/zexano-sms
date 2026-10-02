import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class FilterHistoryByStatus {
  final HistoryRepository repository;

  FilterHistoryByStatus(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String status, {
    int? limit,
    int? offset,
  }) {
    return repository.filterHistoryByStatus(
      status,
      limit: limit,
      offset: offset,
    );
  }
}
