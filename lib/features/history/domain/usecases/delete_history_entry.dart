import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/history_repository.dart';

class DeleteHistoryEntry {
  final HistoryRepository repository;

  DeleteHistoryEntry(this.repository);

  Future<AppResult<bool>> call(String id) {
    return repository.deleteHistoryEntry(id);
  }
}
