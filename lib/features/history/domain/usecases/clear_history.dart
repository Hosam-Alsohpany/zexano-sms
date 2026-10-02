import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/history_repository.dart';

class ClearHistory {
  final HistoryRepository repository;

  ClearHistory(this.repository);

  Future<AppResult<int>> call({String? channelType}) {
    return repository.clearHistory(channelType: channelType);
  }
}
