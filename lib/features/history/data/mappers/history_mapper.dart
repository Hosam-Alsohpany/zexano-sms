import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class HistoryMapper {
  // ── SMS ───────────────────────────────────────────────────────────────────

  /// Converts a list of [db.MessageHistoryData] rows sharing the same
  /// [batchId] into a single [HistoryEntry].
  ///
  /// For an **inbound** single-row batch, [direction] and [sourceType] are read
  /// directly from the row so the correct values propagate to the UI.
  ///
  /// [groupName] is resolved externally (from the Groups table via
  /// [HistoryRepositoryImpl]) and passed in — the mapper itself does not
  /// perform any DB look-ups.
  static HistoryEntry smsBatchToHistoryEntry({
    required String batchId,
    required String tenantId,
    required List<db.MessageHistoryData> rows,
    String? groupName,
  }) {
    if (rows.isEmpty) {
      throw ArgumentError('Cannot build HistoryEntry from empty SMS rows');
    }
    final first = rows.first;

    // ── Direction-aware status aggregation ────────────────────────────────
    // Invariant #2: `received` is an inbound-only terminal state.
    // It is NOT an outbound success. Pure inbound batches short-circuit here
    // and never pass through deriveBatchStatus (which is outbound-only logic).
    final sentCount =
        rows.where((r) => MessageStatusService.isSuccess(r.executionStatus)).length;
    final failedCount =
        rows.where((r) => MessageStatusService.isFailed(r.executionStatus)).length;
    final queuedCount = rows
        .where((r) => MessageStatusService.isPending(r.executionStatus))
        .length;
    final receivedCount =
        rows.where((r) => MessageStatusService.isInbound(r.executionStatus)).length;

    // Short-circuit: pure inbound batch or inbound direction → status = 'received' (no deriveBatchStatus)
    final String status;
    if (first.direction == 'inbound' || receivedCount == rows.length) {
      // All rows are inbound — this is a received message, not a send result.
      status = 'received';
    } else {
      status = MessageStatusService.deriveBatchStatus(
        sentCount: sentCount,
        failedCount: failedCount,
        queuedCount: queuedCount,
        total: rows.length,
        receivedCount: receivedCount,
      );
    }

    // ── Latest sentAt across the batch ───────────────────────────────────
    final sentAtValues = rows
        .where((r) => r.sentAt != null)
        .map((r) => r.sentAt!)
        .toList()
      ..sort();
    final latestSentAt = sentAtValues.isNotEmpty ? sentAtValues.last : null;

    // ── Contact display info ───────────────────────────────────────────
    // For a bulk batch (> 1 recipient) we deliberately leave contactName null
    // so the tile falls through to the "X recipients" / group-name path.
    // For a single-recipient batch we use the contact name from the row.
    final isBulk = rows.length > 1;
    final contactName =
        !isBulk && first.contactName.isNotEmpty ? first.contactName : null;

    // v5 fields: read from DB; fall back to 'outbound'/'manual' for old rows
    final direction = first.direction;
    final sourceType = first.sourceType;
    final groupId = first.groupId;
    final receivedAt = first.receivedAt;

    return HistoryEntry(
      id: 'sms_$batchId',
      originalId: batchId,
      tenantId: tenantId,
      channelType: first.channelType,
      messageBody: first.messageBody,
      status: status,
      totalRecipients: rows.length,
      successCount: sentCount,
      failedCount: failedCount,
      createdAt: first.timestamp,
      completedAt: latestSentAt,
      contactName: contactName,
      phoneNumber: isBulk ? null : first.targetPhone,
      sourceType: sourceType,
      direction: direction,
      groupId: groupId,
      groupName: groupName,
      receivedAt: receivedAt,
    );
  }

  // ── WhatsApp ──────────────────────────────────────────────────────────────

  static HistoryEntry whatsAppSessionToHistoryEntry({
    required db.AssistedSession row,
    required String tenantId,
  }) {
    final status = switch (row.status) {
      'completed' => 'completed',
      'cancelled' => 'cancelled',
      'in_progress' => 'in_progress',
      _ => row.status,
    };

    return HistoryEntry(
      id: 'wa_${row.sessionId}',
      originalId: row.sessionId,
      tenantId: tenantId,
      channelType: 'whatsapp',
      messageBody: row.messageBody,
      status: status,
      totalRecipients: row.totalRecipients,
      successCount: row.completedRecipients,
      failedCount: row.failedRecipients,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
      // WhatsApp sessions have no direction/source concept yet.
      direction: 'outbound',
      sourceType: 'whatsapp',
    );
  }
}
