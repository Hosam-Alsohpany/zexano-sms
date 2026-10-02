import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class FilterHistoryByChannel {
  final HistoryRepository repository;

  FilterHistoryByChannel(this.repository);

  Future<AppResult<List<HistoryEntry>>> call(
    String channelType, {
    int? limit,
    int? offset,
  }) {
    return repository.filterHistoryByChannel(
      channelType,
      limit: limit,
      offset: offset,
    );
  }
}
