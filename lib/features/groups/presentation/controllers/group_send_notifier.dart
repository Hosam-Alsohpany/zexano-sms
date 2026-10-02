import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Represents the outcome of a group SMS send attempt.
sealed class GroupSendStatus {
  const GroupSendStatus();
}

/// Initial state — no send attempted yet.
class GroupSendIdle extends GroupSendStatus {
  const GroupSendIdle();
}

/// Send in progress — UI should show loading indicator.
class GroupSendLoading extends GroupSendStatus {
  const GroupSendLoading();
}

/// Send dispatched successfully.
class GroupSendSuccess extends GroupSendStatus {
  const GroupSendSuccess();
}

/// Send was blocked because Zexano is not the Default SMS App.
/// UI must call [requestDefaultSmsRole] then retry.
class GroupSendNeedsDefaultRole extends GroupSendStatus {
  const GroupSendNeedsDefaultRole();
}

/// Send was cancelled by the user (e.g. rejected the Default SMS role prompt).
class GroupSendCancelled extends GroupSendStatus {
  const GroupSendCancelled();
}

/// Send failed with an error.
class GroupSendError extends GroupSendStatus {
  final String message;
  const GroupSendError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Lifecycle-safe send controller for Group SMS.
///
/// **Invariant #10:** The send operation is completely independent of any
/// BottomSheet or Dialog lifecycle. The user can close the compose sheet while
/// the send is in flight — the operation continues and state is updated via
/// Riverpod, not via BottomSheet BuildContext callbacks.
///
/// **Invariant #1 (Default SMS Gate):** The gate check (isDefaultSmsApp) is
/// performed BEFORE any DB row is created. If the app is not default, this
/// notifier transitions to [GroupSendNeedsDefaultRole]. The UI then launches
/// the Android role request dialog and calls [send] again after the user accepts.
///
/// This notifier does NOT hold any [BuildContext] reference.
class GroupSendNotifier extends StateNotifier<GroupSendStatus> {
  final SmsRepository _smsRepository;
  final Ref _ref;

  GroupSendNotifier(this._smsRepository, this._ref) : super(const GroupSendIdle());

  /// Sends an SMS to all members of [groupId].
  ///
  /// The Default SMS role check is done inside [SmsRepository.sendGroupSms]
  /// which returns [Left(DefaultSmsRoleFailure)] if the app is not default.
  /// The UI layer is responsible for calling the Android role intent when
  /// [GroupSendNeedsDefaultRole] is emitted.
  ///
  /// No DB rows are created until the role check passes.
  Future<void> send({
    required String groupId,
    required String messageBody,
  }) async {
    if (state is GroupSendLoading) return; // guard: no re-entrant sends

    final keepAliveLink = _ref.keepAlive();
    state = const GroupSendLoading();

    try {
      final result = await _smsRepository.sendGroupSms(
        groupId: groupId,
        messageBody: messageBody,
      );

      result.fold(
        (failure) {
          // Check if this is a Default SMS Role failure.
          // The code 'DEFAULT_SMS_ROLE_REQUIRED' is set by SmsRepositoryImpl
          // when isDefaultSmsApp() returns false.
          if (failure.code == 'DEFAULT_SMS_ROLE_REQUIRED') {
            state = const GroupSendNeedsDefaultRole();
          } else {
            state = GroupSendError(failure.message);
          }
        },
        (_) => state = const GroupSendSuccess(),
      );
    } catch (e) {
      state = GroupSendError('Unexpected error: $e');
    } finally {
      keepAliveLink.close();
    }
  }

  /// Resets the state to idle (e.g. after dismissing an error dialog).
  void reset() => state = const GroupSendIdle();
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Auto-disposed per-group send controller.
///
/// Auto-dispose ensures the state is cleaned up when the GroupDetailScreen
/// is popped — no memory leaks, no stale state.
final groupSendProvider =
    StateNotifierProvider.autoDispose<GroupSendNotifier, GroupSendStatus>(
  (ref) => GroupSendNotifier(sl<SmsRepository>(), ref),
);
