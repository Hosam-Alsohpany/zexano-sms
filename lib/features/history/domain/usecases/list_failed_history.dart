import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class ListFailedHistory {
  final HistoryRepository repository;

  ListFailedHistory(this.repository);

  Future<AppResult<List<HistoryEntry>>> call({
    int? limit,
    int? offset,
  }) {
    return repository.listFailedHistory(
      limit: limit,
      offset: offset,
    );
  }
}
