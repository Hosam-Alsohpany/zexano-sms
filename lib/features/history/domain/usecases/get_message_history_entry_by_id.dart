import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class GetMessageHistoryEntryById {
  final HistoryRepository repository;

  GetMessageHistoryEntryById(this.repository);

  Future<AppResult<HistoryEntry?>> call(String id) {
    return repository.getHistoryEntryById(id);
  }
}
