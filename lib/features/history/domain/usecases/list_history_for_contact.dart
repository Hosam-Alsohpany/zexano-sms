import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class ListHistoryForContact {
  final HistoryRepository repository;

  ListHistoryForContact(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String contactId, {
    int? limit,
    int? offset,
  }) {
    return repository.listHistoryForContact(
      contactId,
      limit: limit,
      offset: offset,
    );
  }
}
