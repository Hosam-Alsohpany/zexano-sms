import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class FilterHistoryByDateRange {
  final HistoryRepository repository;

  FilterHistoryByDateRange(this.repository);

  Future<AppResult<List<HistoryEntry>>> call({
    required int dateFrom,
    required int dateTo,
    int? limit,
    int? offset,
  }) {
    return repository.filterHistoryByDateRange(
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }
}
