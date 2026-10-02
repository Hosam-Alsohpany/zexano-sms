import 'package:flutter/services.dart';
import 'package:zexano_sms/core/utils/sms_logger.dart';

// ── Result ──────────────────────────────────────────────────────────────────

class SmsDispatchResult {
  final bool success;
  final String? errorMessage;

  /// The initial status to persist:
  ///   'queued'  — PendingIntent armed; SmsSentReceiver will update async.
  ///   'sent'    — Legacy path / non-Android fallback.
  ///   'failed'  — Dispatch error.
  final String status;

  const SmsDispatchResult({
    required this.success,
    this.errorMessage,
    this.status = 'sent',
  });
}

// ── Abstract interface ───────────────────────────────────────────────────────

abstract class SmsDispatcher {
  /// Send a single SMS.
  ///
  /// [messageId] is the Drift row UUID that uniquely identifies this message.
  /// Pass it so that [AndroidSmsDispatcher] can include it in the PendingIntent
  /// and [SmsSentReceiver] can update exactly the right DB row asynchronously.
  /// Null is accepted for backwards-compatible callers that do not yet supply it.
  Future<SmsDispatchResult> send({
    required String phoneNumber,
    required String messageBody,
    String channelType = 'sms',
    String? messageId,
  });

  /// Send to multiple phones sequentially, collecting per-phone results.
  ///
  /// [messageIds] aligns with [phoneNumbers] by index. When provided, each
  /// individual `send()` call includes its [messageId] so the platform arms
  /// a PendingIntent and [SmsSentReceiver] can update the exact DB row.
  Future<SmsDispatchSummary> sendBatch({
    required List<String> phoneNumbers,
    required String messageBody,
    String channelType = 'sms',
    List<String>? messageIds,
  }) async {
    final succeeded = <String>[];
    final failed = <SmsDispatchFailure>[];

    for (var i = 0; i < phoneNumbers.length; i++) {
      final phone = phoneNumbers[i];
      final mid = (messageIds != null && i < messageIds.length)
          ? messageIds[i]
          : null;
      final result = await send(
        phoneNumber: phone,
        messageBody: messageBody,
        channelType: channelType,
        messageId: mid,
      );
      SmsLogger.batchSendProgress(
        index: i + 1,
        total: phoneNumbers.length,
        phone: phone,
        messageId: mid ?? '(none)',
        success: result.success,
        status: result.status,
      );
      if (result.success) {
        succeeded.add(phone);
      } else {
        failed.add(
          SmsDispatchFailure(
            phoneNumber: phone,
            reason: result.errorMessage,
          ),
        );
      }
    }

    return SmsDispatchSummary(
      succeededPhones: succeeded,
      failedPhones: failed,
    );
  }
}

// ── Value objects ────────────────────────────────────────────────────────────

class SmsThrottleConfig {
  final int maxPerBatch;
  final int delayBetweenMessagesMs;

  const SmsThrottleConfig({
    this.maxPerBatch = 10,
    this.delayBetweenMessagesMs = 200,
  });
}

class SmsDispatchSummary {
  final List<String> succeededPhones;
  final List<SmsDispatchFailure> failedPhones;
  final int totalProcessed;

  const SmsDispatchSummary({
    required this.succeededPhones,
    required this.failedPhones,
  }) : totalProcessed = succeededPhones.length + failedPhones.length;
}

class SmsDispatchFailure {
  final String phoneNumber;
  final String? reason;

  const SmsDispatchFailure({
    required this.phoneNumber,
    this.reason,
  });
}

// ── No-op dispatcher (tests / non-mobile) ───────────────────────────────────

/// Does nothing and always returns success. Used in unit tests and on platforms
/// that don't support SMS.
class NoopSmsDispatcher extends SmsDispatcher {
  @override
  Future<SmsDispatchResult> send({
    required String phoneNumber,
    required String messageBody,
    String channelType = 'sms',
    String? messageId,
  }) async {
    return const SmsDispatchResult(success: true, status: 'sent');
  }
}

// ── Capability-aware dispatcher (non-Android mobile) ────────────────────────

/// Checks whether the platform supports SMS before forwarding.
class CapabilityAwareSmsDispatcher extends SmsDispatcher {
  final bool _canSend;
  final String? _capabilityError;

  CapabilityAwareSmsDispatcher({
    bool canSend = true,
    String? capabilityError,
  })  : _canSend = canSend,
        _capabilityError = capabilityError;

  @override
  Future<SmsDispatchResult> send({
    required String phoneNumber,
    required String messageBody,
    String channelType = 'sms',
    String? messageId,
  }) async {
    if (!_canSend) {
      return SmsDispatchResult(
        success: false,
        errorMessage: _capabilityError ?? 'SMS capability not available',
        status: 'failed',
      );
    }
    return const SmsDispatchResult(success: true, status: 'sent');
  }
}

// ── Android dispatcher ───────────────────────────────────────────────────────

/// Real Android dispatcher.
///
/// When [messageId] is provided it calls [sendSmsWithDelivery] on the platform
/// channel, which arms a PendingIntent so [SmsSentReceiver] can update the DB
/// row asynchronously.  The returned status is 'queued'.
///
/// When [messageId] is null (legacy / batch path) it falls back to plain
/// [sendSms] and returns 'sent' immediately.
class AndroidSmsDispatcher extends SmsDispatcher {
  static const _channel = MethodChannel('com.zexano.sms/sms');

  Future<bool> isDefaultSmsApp() async {
    try {
      return await _channel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestDefaultSmsApp() async {
    try {
      await _channel.invokeMethod<void>('requestDefaultSmsApp');
    } catch (_) {}
  }

  @override
  Future<SmsDispatchResult> send({
    required String phoneNumber,
    required String messageBody,
    String channelType = 'sms',
    String? messageId,
  }) async {
    // 1) Ensure permission.
    final hasPermission = await _channel.invokeMethod<bool>('hasSmsPermission');
    if (hasPermission != true) {
      final granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      if (granted != true) {
        return const SmsDispatchResult(
          success: false,
          errorMessage: 'SMS permission not granted',
          status: 'failed',
        );
      }
    }

    try {
      final Map<Object?, Object?> raw;

      if (messageId != null && messageId.isNotEmpty) {
        SmsLogger.dispatchPath(
          phone: phoneNumber,
          hasMessageId: true,
          method: 'sendSmsWithDelivery',
        );
        // Delivery-tracking path: SmsSentReceiver updates the row async.
        raw = await _channel.invokeMethod<Map<Object?, Object?>>(
              'sendSmsWithDelivery',
              {
                'phoneNumber': phoneNumber,
                'messageBody': messageBody,
                'messageId': messageId,
              },
            ) ??
            {};
      } else {
        SmsLogger.dispatchPath(
          phone: phoneNumber,
          hasMessageId: false,
          method: 'sendSms',
        );
        // Legacy path: no delivery tracking.
        raw = await _channel.invokeMethod<Map<Object?, Object?>>(
              'sendSms',
              {'phoneNumber': phoneNumber, 'messageBody': messageBody},
            ) ??
            {};
      }

      final result = Map<String, dynamic>.from(raw);
      final success = result['success'] == true;

      return SmsDispatchResult(
        success: success,
        errorMessage: success ? null : (result['error'] as String?),
        status: success
            ? (result['status'] as String? ?? 'sent') // 'queued' or 'sent'
            : 'failed',
      );
    } catch (e) {
      return SmsDispatchResult(
        success: false,
        errorMessage: 'Failed to send SMS: $e',
        status: 'failed',
      );
    }
  }
}

// ── Throttled dispatcher ─────────────────────────────────────────────────────

/// Wraps any [SmsDispatcher] and adds per-message delays to avoid carrier
/// rate-limiting when sending bulk messages.
class ThrottledSmsDispatcher extends SmsDispatcher {
  final SmsDispatcher _inner;
  final SmsThrottleConfig _config;

  ThrottledSmsDispatcher(
    this._inner, {
    SmsThrottleConfig config = const SmsThrottleConfig(),
  }) : _config = config;

  @override
  Future<SmsDispatchResult> send({
    required String phoneNumber,
    required String messageBody,
    String channelType = 'sms',
    String? messageId,
  }) async {
    return _inner.send(
      phoneNumber: phoneNumber,
      messageBody: messageBody,
      channelType: channelType,
      messageId: messageId,
    );
  }

  @override
  Future<SmsDispatchSummary> sendBatch({
    required List<String> phoneNumbers,
    required String messageBody,
    String channelType = 'sms',
    List<String>? messageIds,
  }) async {
    final succeeded = <String>[];
    final failed = <SmsDispatchFailure>[];

    for (var i = 0; i < phoneNumbers.length; i++) {
      if (i > 0 && _config.delayBetweenMessagesMs > 0) {
        await Future.delayed(
          Duration(milliseconds: _config.delayBetweenMessagesMs),
        );
      }

      final mid = (messageIds != null && i < messageIds.length)
          ? messageIds[i]
          : null;
      final result = await send(
        phoneNumber: phoneNumbers[i],
        messageBody: messageBody,
        channelType: channelType,
        messageId: mid,
      );

      SmsLogger.batchSendProgress(
        index: i + 1,
        total: phoneNumbers.length,
        phone: phoneNumbers[i],
        messageId: mid ?? '(none)',
        success: result.success,
        status: result.status,
      );

      if (result.success) {
        succeeded.add(phoneNumbers[i]);
      } else {
        failed.add(
          SmsDispatchFailure(
            phoneNumber: phoneNumbers[i],
            reason: result.errorMessage,
          ),
        );
      }
    }

    return SmsDispatchSummary(
      succeededPhones: succeeded,
      failedPhones: failed,
    );
  }
}
