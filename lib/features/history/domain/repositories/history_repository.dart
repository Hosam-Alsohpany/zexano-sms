import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/history_entry.dart';
import '../models/grouped_timeline_result.dart';
import '../models/history_detail_projection.dart';
import '../models/retryable_action_hint.dart';
import '../value_objects/history_filter.dart';

abstract class HistoryRepository {
  Future<AppResult<List<HistoryEntry>>> listMessageHistory({
    int? limit,
    int? offset,
  });

  /// Live stream — re-emits whenever [messageHistory] table changes.
  /// Used by [HistoryNotifier] to enable real-time UI updates without
  /// manual refresh calls or polling.
  Stream<List<HistoryEntry>> watchMessageHistory();

  /// Reactive detail stream for a single entry.
  ///
  /// For SMS: only watches the specific batch rows — not the full table.
  /// Re-emits whenever a status update, sentAt, or contactName changes for
  /// any row in the batch.
  ///
  /// For WA: emits once (WA sessions are not live-updated the same way).
  Stream<AppResult<HistoryDetailProjection>> watchHistoryDetail(String id);

  Future<AppResult<HistoryEntry?>> getHistoryEntryById(String id);

  Future<AppResult<List<HistoryEntry>>> searchMessageHistory(
    String query, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> filterHistoryByChannel(
    String channelType, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> filterHistoryByStatus(
    String status, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> filterHistoryByDateRange({
    required int dateFrom,
    required int dateTo,
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> filterHistoryByContact(
    String contactId, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> filterHistoryByGroupContext(
    String groupId, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> listRecentHistory({
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> listHistoryForContact(
    String contactId, {
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> listFailedHistory({
    int? limit,
    int? offset,
  });

  Future<AppResult<List<HistoryEntry>>> listRetryableHistory({
    int? limit,
    int? offset,
  });

  Future<AppResult<bool>> deleteHistoryEntry(String id);

  /// Deletes multiple history entries in a single atomic transaction.
  ///
  /// **Invariant #13:** Batch deletion is a single transaction.
  ///   - 0 ids → no-op, returns Right(0)
  ///   - N ids → one transaction, all-or-nothing
  ///
  /// [ids] are the `originalId` (batchId) values from [HistoryEntry].
  Future<AppResult<int>> deleteHistoryEntries(List<String> ids);

  Future<AppResult<int>> clearHistory({String? channelType});


  Future<AppResult<List<GroupedTimelineResult>>> buildGroupedTimeline({
    HistoryFilter? filter,
  });

  Future<AppResult<HistoryDetailProjection>> getHistoryDetail(String id);

  Future<AppResult<RetryableActionHint?>> getRetryableActionHint(
      String entryId);
}
