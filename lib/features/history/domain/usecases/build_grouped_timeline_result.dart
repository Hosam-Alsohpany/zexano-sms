import 'package:zexano_sms/core/errors/failures.dart';
import '../models/grouped_timeline_result.dart';
import '../repositories/history_repository.dart';
import '../value_objects/history_filter.dart';

class BuildGroupedTimelineResult {
  final HistoryRepository repository;

  BuildGroupedTimelineResult(this.repository);

  Future<AppResult<List<GroupedTimelineResult>>> call({
    HistoryFilter? filter,
  }) {
    return repository.buildGroupedTimeline(filter: filter);
  }
}
