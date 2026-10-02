import 'package:flutter/foundation.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';

/// مُسجِّل تشخيصي مؤقت لمسار إرسال SMS
/// يمكن تعطيله في الإنتاج بضبط [enabled] = false
class SmsLogger {
  static bool enabled = kDebugMode;

  static void groupSelected({
    required String groupId,
    required String groupName,
    required int memberCount,
  }) {
    if (!enabled) return;
    debugPrint(
      '\n╔══════════════════════════════════════╗\n'
      '║  [SmsLogger] GROUP SELECTED          ║\n'
      '╠══════════════════════════════════════╣\n'
      '║  Name  : $groupName\n'
      '║  ID    : $groupId\n'
      '║  Members: $memberCount\n'
      '╚══════════════════════════════════════╝',
    );
  }

  static void recipientsResolved({
    required String groupName,
    required List<SmsRecipient> recipients,
    required List<String> skippedPhones,
  }) {
    if (!enabled) return;
    final buffer = StringBuffer();
    buffer.writeln('\n╔══════════════════════════════════════╗');
    buffer.writeln('║  [SmsLogger] RECIPIENTS RESOLVED     ║');
    buffer.writeln('╠══════════════════════════════════════╣');
    buffer.writeln('║  Group  : $groupName');
    buffer.writeln('║  Valid  : ${recipients.length}');
    buffer.writeln('║  Skipped: ${skippedPhones.length}');
    buffer.writeln('╠── Valid Recipients ───────────────────');
    for (var i = 0; i < recipients.length; i++) {
      buffer.writeln('║  ${i + 1}. ${recipients[i].phoneNumber}  (${recipients[i].contactName})');
    }
    if (skippedPhones.isNotEmpty) {
      buffer.writeln('╠── Skipped (invalid/empty) ────────────');
      for (final p in skippedPhones) {
        buffer.writeln('║  ✗ $p');
      }
    }
    buffer.writeln('╚══════════════════════════════════════╝');
    debugPrint(buffer.toString());
  }

  static void bulkSmsStarted({
    required int totalRecipients,
    required int validRecipients,
    required int invalidRecipients,
    required String messageBody,
  }) {
    if (!enabled) return;
    debugPrint(
      '\n╔══════════════════════════════════════╗\n'
      '║  [SmsLogger] BULK SMS STARTED        ║\n'
      '╠══════════════════════════════════════╣\n'
      '║  Total       : $totalRecipients\n'
      '║  Valid        : $validRecipients\n'
      '║  Invalid      : $invalidRecipients\n'
      '║  Msg length   : ${messageBody.length} chars\n'
      '╚══════════════════════════════════════╝',
    );
  }

  static void bulkSmsCompleted({
    required int sent,
    required int failed,
    required List<String> failedPhones,
  }) {
    if (!enabled) return;
    debugPrint(
      '\n╔══════════════════════════════════════╗\n'
      '║  [SmsLogger] BULK SMS COMPLETED      ║\n'
      '╠══════════════════════════════════════╣\n'
      '║  Sent  : $sent\n'
      '║  Failed: $failed\n'
      '║  Failed phones: ${failedPhones.join(", ")}\n'
      '╚══════════════════════════════════════╝',
    );
  }

  static void phoneValidation({
    required String raw,
    required String normalized,
    required bool isValid,
    String? reason,
  }) {
    if (!enabled) return;
    final mark = isValid ? '✓' : '✗';
    debugPrint(
      '[SmsLogger] $mark Phone: $raw → $normalized'
      '${isValid ? "" : "  (INVALID: $reason)"}',
    );
  }

  /// Logs each individual dispatch inside a batch send.
  /// [index] = position in batch (1-based for readability)
  static void batchSendProgress({
    required int index,
    required int total,
    required String phone,
    required String messageId,
    required bool success,
    required String status,
  }) {
    if (!enabled) return;
    debugPrint(
      '\n╔══ [SmsLogger] BATCH SEND PROGRESS ══════╗\n'
      '║  Message  : $index / $total\n'
      '║  Phone    : $phone\n'
      '║  RowID    : $messageId\n'
      '║  Result   : ${success ? "✓" : "✗"}\n'
      '║  Status   : $status\n'
      '╚═══════════════════════════════════════════╝',
    );
  }

  /// Logs which platform path is taken for a single SMS send.
  static void dispatchPath({
    required String phone,
    required bool hasMessageId,
    required String method,
  }) {
    if (!enabled) return;
    debugPrint(
      '[SmsLogger] DISPATCH: phone=$phone hasId=$hasMessageId method=$method',
    );
  }

  /// Logs phone → rowId mapping used to track batch rows.
  static void phoneRowMapping({
    required String phone,
    required String rowId,
  }) {
    if (!enabled) return;
    debugPrint('[SmsLogger] MAP: phone=$phone → rowId=$rowId');
  }

  /// Logs when markTablesUpdated is called for status updates.
  static void statusUpdateNotification({
    required String messageId,
    required String status,
  }) {
    if (!enabled) return;
    debugPrint(
      '[SmsLogger] NOTIFY: markTablesUpdated for id=$messageId status=$status',
    );
  }
}
