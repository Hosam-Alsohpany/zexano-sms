import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class FilterHistoryByContact {
  final HistoryRepository repository;

  FilterHistoryByContact(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String contactId, {
    int? limit,
    int? offset,
  }) {
    return repository.filterHistoryByContact(
      contactId,
      limit: limit,
      offset: offset,
    );
  }
}
