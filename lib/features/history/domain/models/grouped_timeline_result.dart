import '../entities/history_entry.dart';

class GroupedTimelineResult {
  final String dateLabel;
  final List<HistoryEntry> entries;

  const GroupedTimelineResult({
    required this.dateLabel,
    required this.entries,
  });

  int get totalCount => entries.length;
  int get successCount => entries.fold(0, (sum, e) => sum + e.successCount);
  int get failedCount => entries.fold(0, (sum, e) => sum + e.failedCount);
}
