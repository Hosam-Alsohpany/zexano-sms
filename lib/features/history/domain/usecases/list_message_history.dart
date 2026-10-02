import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class ListMessageHistory {
  final HistoryRepository repository;

  ListMessageHistory(this.repository);

  Future<AppResult<List<HistoryEntry>>> call({
    int? limit,
    int? offset,
  }) {
    return repository.listMessageHistory(
      limit: limit,
      offset: offset,
    );
  }
}
