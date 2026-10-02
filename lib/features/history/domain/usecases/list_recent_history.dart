import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class ListRecentHistory {
  final HistoryRepository repository;

  ListRecentHistory(this.repository);

  Future<AppResult<List<HistoryEntry>>> call({
    int? limit,
    int? offset,
  }) {
    return repository.listRecentHistory(
      limit: limit,
      offset: offset,
    );
  }
}
