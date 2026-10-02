import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class SearchMessageHistory {
  final HistoryRepository repository;

  SearchMessageHistory(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String query, {
    int? limit,
    int? offset,
  }) {
    return repository.searchMessageHistory(
      query,
      limit: limit,
      offset: offset,
    );
  }
}
