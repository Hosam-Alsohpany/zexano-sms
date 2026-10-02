import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/features/backup/domain/entities/restore_report.dart';
import 'package:zexano_sms/features/backup/domain/models/restore_preview.dart';
import 'package:zexano_sms/features/backup/domain/models/verification_result.dart';
import 'package:zexano_sms/features/backup/domain/repositories/backup_repository.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';
import 'package:zexano_sms/features/backup/presentation/providers/backup_providers.dart';

enum RestoreStep { selecting, validating, previewing, confirming, restoring, completed, error }

class RestoreFlowState {
  final RestoreStep step;
  final String? selectedFilePath;
  final String? selectedFileName;
  final bool isEncrypted;
  final String passphrase;
  final String passphraseConfirm;
  final RestorePreview? preview;
  final RestoreReport? report;
  final VerificationResult? validation;
  final String? errorMessage;
  final bool confirmed;

  const RestoreFlowState({
    this.step = RestoreStep.selecting,
    this.selectedFilePath,
    this.selectedFileName,
    this.isEncrypted = false,
    this.passphrase = '',
    this.passphraseConfirm = '',
    this.preview,
    this.report,
    this.validation,
    this.errorMessage,
    this.confirmed = false,
  });

  bool get canConfirm =>
      preview != null &&
      (isEncrypted
          ? (passphrase.length >= 8 && passphrase == passphraseConfirm)
          : true);

  RestoreFlowState copyWith({
    RestoreStep? step,
    String? selectedFilePath,
    String? selectedFileName,
    bool? isEncrypted,
    String? passphrase,
    String? passphraseConfirm,
    RestorePreview? preview,
    RestoreReport? report,
    VerificationResult? validation,
    String? errorMessage,
    bool? confirmed,
    bool clearPreview = false,
    bool clearReport = false,
    bool clearError = false,
    bool clearValidation = false,
  }) {
    return RestoreFlowState(
      step: step ?? this.step,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      passphrase: passphrase ?? this.passphrase,
      passphraseConfirm: passphraseConfirm ?? this.passphraseConfirm,
      preview: clearPreview ? null : (preview ?? this.preview),
      report: clearReport ? null : (report ?? this.report),
      validation: clearValidation ? null : (validation ?? this.validation),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

class RestoreNotifier extends StateNotifier<RestoreFlowState> {
  final BackupRepository _repository;

  RestoreNotifier(this._repository) : super(const RestoreFlowState());

  void selectBackupFile(String filePath, String fileName, bool isEncrypted) {
    state = state.copyWith(
      step: RestoreStep.validating,
      selectedFilePath: filePath,
      selectedFileName: fileName,
      isEncrypted: isEncrypted,
    );
    _validateAndPreview(filePath, isEncrypted);
  }

  void setPassphrase(String value) {
    state = state.copyWith(passphrase: value);
  }

  void setPassphraseConfirm(String value) {
    state = state.copyWith(passphraseConfirm: value);
  }

  void confirmDestructive() {
    state = state.copyWith(confirmed: true, step: RestoreStep.restoring);
    _executeRestore();
  }

  void reset() {
    state = const RestoreFlowState();
  }

  Future<void> _validateAndPreview(String filePath, bool isEncrypted) async {
    try {
      BackupPassphrase? passphraseObj;
      if (isEncrypted && state.passphrase.isNotEmpty) {
        passphraseObj = BackupPassphrase.create(state.passphrase);
      }

      final validation = await _repository.validateRestoreCandidate(
        filePath,
        passphrase: passphraseObj,
      );

      VerificationResult? validationResult;
      validation.fold(
        (_) {},
        (r) => validationResult = r,
      );

      final validated = validationResult;
      if (validated == null) {
        state = state.copyWith(step: RestoreStep.error, errorMessage: 'Invalid backup file');
        return;
      }

      state = state.copyWith(validation: validated);

      if (validated.isValid) {
        final outcome = await _repository.previewRestoreSummary(
          filePath,
          passphrase: passphraseObj,
        );

        outcome.fold(
          (failure) {
            state = state.copyWith(
              step: RestoreStep.error,
              errorMessage: failure.message,
            );
          },
          (preview) {
            state = state.copyWith(
              step: RestoreStep.previewing,
              preview: preview,
              clearError: true,
            );
          },
        );
      } else {
        state = state.copyWith(
          step: RestoreStep.error,
          errorMessage: validation.fold(
            (f) => f.message,
            (v) => v.errorMessage ?? 'Invalid backup file',
          ),
        );
      }
    } on Exception catch (e) {
      state = state.copyWith(
        step: RestoreStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _executeRestore() async {
    try {
      if (state.selectedFilePath == null) {
        state = state.copyWith(
          step: RestoreStep.error,
          errorMessage: 'No backup file selected',
        );
        return;
      }

      final outcome = await _repository.confirmDestructiveRestore(
        filePath: state.selectedFilePath!,
        confirmed: true,
        passphrase: state.passphrase.isNotEmpty
            ? BackupPassphrase.create(state.passphrase)
            : null,
      );

      outcome.fold(
        (failure) {
          state = state.copyWith(
            step: RestoreStep.error,
            errorMessage: failure.message,
          );
        },
        (report) {
          state = state.copyWith(
            step: RestoreStep.completed,
            report: report,
            clearError: true,
          );
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(
        step: RestoreStep.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final restoreNotifierProvider =
    StateNotifierProvider.autoDispose<RestoreNotifier, RestoreFlowState>(
        (ref) {
  return RestoreNotifier(ref.read(backupRepositoryProvider));
});
