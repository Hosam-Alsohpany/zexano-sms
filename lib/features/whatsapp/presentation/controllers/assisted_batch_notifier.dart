import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/assisted_batch_progress.dart';
import 'package:zexano_sms/features/whatsapp/presentation/providers/whatsapp_providers.dart';

class AssistedBatchState {
  final AssistedSession? session;
  final StagedRecipient? currentRecipient;
  final AssistedBatchProgress progress;
  final bool isLaunching;
  final String? errorMessage;

  const AssistedBatchState({
    this.session,
    this.currentRecipient,
    required this.progress,
    this.isLaunching = false,
    this.errorMessage,
  });

  AssistedBatchState copyWith({
    AssistedSession? session,
    StagedRecipient? currentRecipient,
    AssistedBatchProgress? progress,
    bool? isLaunching,
    String? errorMessage,
    bool clearRecipient = false,
    bool clearError = false,
  }) {
    return AssistedBatchState(
      session: session ?? this.session,
      currentRecipient:
          clearRecipient ? null : (currentRecipient ?? this.currentRecipient),
      progress: progress ?? this.progress,
      isLaunching: isLaunching ?? this.isLaunching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AssistedBatchNotifier extends StateNotifier<AssistedBatchState> {
  final Ref _ref;

  AssistedBatchNotifier(this._ref)
      : super(AssistedBatchState(
          progress: const AssistedBatchProgress(
            sessionId: '',
            total: 0,
            status: 'idle',
          ),
        ));

  Future<void> startSession(AssistedSession session) async {
    state = AssistedBatchState(
      session: session,
      progress: AssistedBatchProgress(
        sessionId: session.sessionId,
        total: session.totalRecipients,
        status: 'in_progress',
      ),
    );
    await advance();
  }

  Future<void> advance() async {
    final sessionId = state.progress.sessionId;
    if (sessionId.isEmpty) return;

    final repo = _ref.read(whatsAppRepositoryProvider);
    final result = await repo.advanceToNext(sessionId);
    result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
          clearRecipient: true,
        );
      },
      (next) {
        if (next == null) {
          state = state.copyWith(
            progress: state.progress.copyWith(
              status: 'completed',
            ),
            clearRecipient: true,
          );
        } else {
          final updatedProgress = state.progress.copyWith(
            currentIndex: state.progress.currentIndex + 1,
            currentPhoneNumber: next.phoneNumber,
          );
          state = AssistedBatchState(
            session: state.session,
            currentRecipient: next,
            progress: updatedProgress,
          );
        }
      },
    );
  }

  Future<void> launchCurrent() async {
    final recipient = state.currentRecipient;
    if (recipient == null) return;

    state = state.copyWith(isLaunching: true, clearError: true);

    final repo = _ref.read(whatsAppRepositoryProvider);
    final result = await repo.launchRecipient(recipient.id);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLaunching: false,
          errorMessage: failure.message,
        );
      },
      (launchResult) async {
        if (launchResult.success) {
          state = state.copyWith(
            isLaunching: false,
            progress: state.progress.copyWith(
              completed: state.progress.completed + 1,
            ),
          );
        } else {
          state = state.copyWith(
            isLaunching: false,
            progress: state.progress.copyWith(
              failed: state.progress.failed + 1,
            ),
            errorMessage: launchResult.failureReason,
          );
        }
      },
    );
  }

  Future<void> markSent() async {
    final recipient = state.currentRecipient;
    if (recipient == null) return;

    final repo = _ref.read(whatsAppRepositoryProvider);
    await repo.launchRecipient(recipient.id);

    state = state.copyWith(
      progress: state.progress.copyWith(
        completed: state.progress.completed + 1,
      ),
    );
  }

  Future<void> skipCurrent() async {
    state = state.copyWith(
      progress: state.progress.copyWith(
        failed: state.progress.failed + 1,
      ),
    );
    await advance();
  }

  void cancelSession() {
    state = state.copyWith(
      progress: state.progress.copyWith(status: 'cancelled'),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = AssistedBatchState(
      progress: const AssistedBatchProgress(
        sessionId: '',
        total: 0,
        status: 'idle',
      ),
    );
  }
}

final assistedBatchProvider =
    StateNotifierProvider<AssistedBatchNotifier, AssistedBatchState>((ref) {
  return AssistedBatchNotifier(ref);
});
