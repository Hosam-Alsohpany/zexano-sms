/// Single Source of Truth for all message execution status logic.
///
/// Rules:
/// - [isSuccess]: `sent` OR `delivered` are both successes.
/// - [deriveBatchStatus]: canonical aggregation logic used identically by
///   History, Detail, and SMS features.
/// - [canTransition]: State Transition Map prevents status regressions;
///   e.g. Delivered → Queued is NEVER allowed.
/// - [statusPriority]: used by [SmsLocalSource.updateStatusByIdSafe].
library message_status_service;

// ── Enum ─────────────────────────────────────────────────────────────────────

/// Typed representation of [MessageHistory.executionStatus] DB values.
///
/// The DB column remains a plain TEXT field. This enum lives in the
/// domain/service layer to eliminate string-literal typos across the codebase.
/// Use [fromString] / [toValue] at the data-layer boundary.
enum MessageExecutionStatus {
  queued,
  sending,
  sent,
  delivered,
  failed,
  received, // inbound SMS
  unknown; // defensive: any unrecognised DB value

  // ── Deserialisation ────────────────────────────────────────────────────────

  static MessageExecutionStatus fromString(String? raw) {
    return switch (raw) {
      'queued'    => queued,
      'sending'   => sending,
      'sent'      => sent,
      'delivered' => delivered,
      'failed'    => failed,
      'received'  => received,
      _           => unknown,
    };
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  String toValue() {
    return switch (this) {
      queued    => 'queued',
      sending   => 'sending',
      sent      => 'sent',
      delivered => 'delivered',
      failed    => 'failed',
      received  => 'received',
      unknown   => 'unknown',
    };
  }

  // ── Semantic getters ──────────────────────────────────────────────────────

  /// Both `sent` and `delivered` are considered successful **outbound** outcomes.
  /// Does NOT include `received` — inbound messages are not outbound successes.
  bool get isSuccess => this == sent || this == delivered;

  bool get isFailed => this == failed;

  /// Message is still in-flight (not yet confirmed or rejected).
  bool get isPending => this == queued || this == sending;

  /// True only for inbound messages (direction = 'inbound', executionStatus = 'received').
  /// This is a distinct terminal state — separate from the outbound success/failure path.
  bool get isInbound => this == received;

  /// Terminal states allow no further transitions.
  /// `received` is terminal — inbound messages are never retried or status-updated.
  bool get isTerminal => this == sent || this == delivered || this == failed || this == received;
}

// ── Service ───────────────────────────────────────────────────────────────────

class MessageStatusService {
  const MessageStatusService._();

  // ── String-level helpers (DB/Drift boundary) ──────────────────────────────

  /// `true` when [status] represents a successful delivery.
  ///
  /// Both `'sent'` and `'delivered'` are successes.
  /// This is the ONE AND ONLY definition of "success" in the project.
  /// True for outbound send successes: `sent` or `delivered`.
  /// Does NOT include `received` — use [isInbound] for inbound check.
  static bool isSuccess(String status) =>
      status == 'sent' || status == 'delivered';

  static bool isFailed(String status) => status == 'failed';

  static bool isPending(String status) =>
      status == 'queued' || status == 'sending';

  /// True for inbound messages only (`received`).
  /// Inbound messages are NOT outbound successes or failures.
  static bool isInbound(String status) => status == 'received';

  /// True if this status represents a retryable failure.
  ///
  /// Only `failed` outbound messages are retryable.
  /// `received`, `sent`, `delivered`, `queued`, `sending` are never retryable.
  static bool isRetryable(String status) => status == 'failed';

  // ── Priority table ────────────────────────────────────────────────────────

  /// Status priority for safe update checks.
  ///
  /// Higher number = more final state. A row must only move to an equal or
  /// higher-priority status — NEVER backward.
  ///
  ///   received(6) > delivered(5) > sent(4) > failed(3) > sending(2) > queued(1)
  ///
  /// `received` has priority 6 — it is a terminal inbound state and must NEVER
  /// be overwritten by any outbound status update from SmsSentReceiver.
  static const Map<String, int> statusPriority = {
    'received':  6, // terminal inbound — highest priority, never overwritten
    'delivered': 5,
    'sent':      4,
    'failed':    3,
    'sending':   2,
    'queued':    1,
  };

  // ── State Transition Map ──────────────────────────────────────────────────

  /// Allowed status transitions.
  ///
  /// Empty set = terminal (no further transitions). Transitions not listed
  /// are rejected by [canTransition].
  ///
  ///   queued   → sending | sent | failed | delivered
  ///   sending  → sent | failed | delivered
  ///   sent     → delivered
  ///   delivered → (terminal)
  ///   failed   → (terminal)
  ///   received → (terminal, inbound only)
  static const Map<String, Set<String>> _allowedTransitions = {
    'queued':    {'sending', 'sent', 'failed', 'delivered'},
    'sending':   {'sent', 'failed', 'delivered'},
    'sent':      {'delivered'},
    'delivered': {},
    'failed':    {},
    'received':  {},
  };

  /// Validates whether a status is semantically compatible with the message direction.
  ///
  /// Invariants:
  /// - Outbound message can NEVER have status `received`.
  /// - Inbound message can NEVER have status `delivered`.
  static bool isStatusAllowedForDirection(String status, String direction) {
    if (direction == 'outbound' && status == 'received') return false;
    if (direction == 'inbound' && status == 'delivered') return false;
    return true;
  }

  /// Returns `true` if transitioning [from] → [to] is semantically valid.
  ///
  /// If [direction] is provided, additionally enforces direction invariants:
  /// - Outbound messages can NEVER transition to `received`.
  /// - Inbound messages can NEVER transition to `delivered`.
  ///
  /// If [from] is unknown (e.g. legacy value), the transition is allowed to
  /// avoid blocking status updates for old rows.
  static bool canTransition(String from, String to, {String? direction}) {
    if (direction != null && !isStatusAllowedForDirection(to, direction)) {
      return false;
    }
    if (from == to) return true; // idempotent / no-op (e.g. temporary report sent -> sent)
    final allowed = _allowedTransitions[from];
    if (allowed == null) return true; // unknown state — allow
    if (allowed.isEmpty) return false; // terminal state
    return allowed.contains(to);
  }

  // ── Batch status derivation ───────────────────────────────────────────────

  /// Derives aggregate status from per-recipient counts.
  ///
  /// **Inbound-aware:** if ALL rows are `received` (inbound), returns `'received'`
  /// immediately without going through outbound status logic. This is the fix
  /// for the bug where inbound messages showed `'queued'` status.
  ///
  /// Priority rules (outbound):
  ///   1. All received (receivedCount == total)        → `received`  ← inbound only
  ///   2. Nothing confirmed yet (sent==0, failed==0)   → `queued`
  ///   3. All successful (sentCount == total)          → `sent`
  ///   4. All failed    (failedCount == total)         → `failed`
  ///   5. Mixed results                               → `partial`
  ///
  /// [sentCount] MUST include both `sent` and `delivered` rows.
  /// [receivedCount] is the count of rows with `executionStatus == 'received'`.
  static String deriveBatchStatus({
    required int sentCount,
    required int failedCount,
    required int queuedCount,
    required int total,
    int receivedCount = 0,
  }) {
    if (total == 0) return 'queued';
    // Short-circuit: pure inbound batch → 'received' (invariant #2)
    if (receivedCount == total) return 'received';
    if (sentCount == 0 && failedCount == 0) return 'queued';
    if (sentCount == total) return 'sent';
    if (failedCount == total) return 'failed';
    return 'partial';
  }
}
