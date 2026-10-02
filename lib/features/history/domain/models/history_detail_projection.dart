import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

import '../entities/history_entry.dart';
import 'recipient_detail.dart';

class HistoryDetailProjection {
  final HistoryEntry entry;

  /// Full per-recipient breakdown — populated only for SMS batches.
  final List<RecipientDetail> recipients;

  final String? channelSpecificNotes;

  const HistoryDetailProjection({
    required this.entry,
    this.recipients = const [],
    this.channelSpecificNotes,
  });

  // ── Counts always from recipients (authoritative) ────────────────────────

  /// Actual total from the recipient list; falls back to entry count.
  int get totalCount =>
      recipients.isNotEmpty ? recipients.length : entry.totalRecipients;

  int get sentCount => sentRecipients.length;
  int get failedCount => failedRecipients.length;
  int get queuedCount => queuedRecipients.length;

  // ── Derived status from recipients ───────────────────────────────────────

  /// Status computed from the current recipient list.
  /// This is authoritative: always prefer this over entry.status in the UI.
  /// Uses [MessageStatusService.deriveBatchStatus] — same logic as History list.
  String get derivedStatus {
    if (entry.isInbound) return 'received';
    if (recipients.isEmpty) return entry.status;
    return MessageStatusService.deriveBatchStatus(
      sentCount: sentCount,
      failedCount: failedCount,
      queuedCount: queuedCount,
      total: totalCount,
    );
  }

  bool get hasChannelNotes => channelSpecificNotes != null;
  bool get hasRecipients => recipients.isNotEmpty;
  bool get isBulk => totalCount > 1;

  /// Recipients who received the message successfully.
  List<RecipientDetail> get sentRecipients =>
      recipients.where((r) => r.isSent).toList();

  /// Recipients for whom the send failed.
  List<RecipientDetail> get failedRecipients =>
      recipients.where((r) => r.isFailed).toList();

  /// Recipients whose message is still queued / in-flight.
  List<RecipientDetail> get queuedRecipients =>
      recipients.where((r) => r.isQueued).toList();

  // ── Legacy accessors kept for backward-compat ─────────────────────────────
  List<String> get recipientNames => recipients.map((r) => r.name).toList();
  List<String> get recipientPhones => recipients.map((r) => r.phone).toList();
}
