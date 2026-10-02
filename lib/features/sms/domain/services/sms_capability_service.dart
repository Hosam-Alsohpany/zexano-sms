import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ── Result type ───────────────────────────────────────────────────────────────

/// Result of [SmsCapabilityService.checkCanSend].
enum SmsCapabilityStatus {
  /// App is the Default SMS App and has SMS permission — can send immediately.
  canSend,

  /// App is not the Default SMS App. UI must launch the role request dialog.
  needsDefaultRole,

  /// SMS permission is not granted. UI must request permission.
  permissionDenied,

  /// SMS is not supported on this platform (non-Android).
  notSupported,
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Single gate for all SMS capability checks.
///
/// **Invariant #1:** This service is the ONLY place that checks Default SMS
/// role status. All send paths (single, bulk, group, retry) call this service
/// BEFORE creating any [MessageHistory] rows.
///
/// **Architecture decision:** This service wraps the Android MethodChannel
/// calls that are also available on [AndroidSmsDispatcher]. It exists as a
/// separate singleton so the UI layer can call it without going through the
/// Repository, and without the Repository holding UI-level dependencies.
///
/// Flow:
/// ```
/// UI calls SmsCapabilityService.checkCanSend()
///   → 'canSend'         → UI calls SmsRepository.send*(...)
///   → 'needsDefaultRole' → UI launches role dialog, on accept → retry checkCanSend
///   → 'permissionDenied' → UI requests permission
///   → 'notSupported'     → UI shows error
/// ```
class SmsCapabilityService {
  static const _channel = MethodChannel('com.zexano.sms/sms');

  /// Checks whether the app can currently send SMS.
  ///
  /// Returns [SmsCapabilityStatus] — the UI decides what to do next.
  /// Does NOT launch any dialogs or modify state.
  Future<SmsCapabilityStatus> checkCanSend() async {
    try {
      // 1. Check SMS permission first.
      final hasPermission =
          await _channel.invokeMethod<bool>('hasSmsPermission') ?? false;
      if (!hasPermission) {
        if (kDebugMode) debugPrint('[SmsCapabilityService] SMS permission not granted');
        return SmsCapabilityStatus.permissionDenied;
      }

      // 2. Check Default SMS App role.
      final isDefault =
          await _channel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
      if (!isDefault) {
        if (kDebugMode) debugPrint('[SmsCapabilityService] not default SMS app');
        return SmsCapabilityStatus.needsDefaultRole;
      }

      if (kDebugMode) debugPrint('[SmsCapabilityService] canSend=true');
      return SmsCapabilityStatus.canSend;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[SmsCapabilityService] platform error ${e.message}');
      // On non-Android or if channel is unavailable, treat as not supported.
      return SmsCapabilityStatus.notSupported;
    } catch (_) {
      return SmsCapabilityStatus.notSupported;
    }
  }

  /// Launches the Android Default SMS Role request UI.
  ///
  /// Returns `true` if the user accepted and the app is now the default.
  /// Returns `false` if the user rejected or if the dialog could not be shown.
  ///
  /// This method awaits [startActivityForResult] via the MethodChannel — it
  /// only returns after the user has made a choice in the system dialog.
  Future<bool> requestDefaultSmsRole() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestDefaultSmsApp') ?? false;
      if (kDebugMode) debugPrint('[SmsCapabilityService] requestDefaultSmsApp result=$result');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[SmsCapabilityService] requestDefaultSmsApp error ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Requests SMS permission via the Android runtime permission system.
  ///
  /// Returns `true` if granted.
  Future<bool> requestSmsPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestSmsPermission') ?? false;
      return result;
    } on PlatformException {
      return false;
    }
  }
}
