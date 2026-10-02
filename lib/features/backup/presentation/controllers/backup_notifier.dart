import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zexano_sms/features/backup/domain/entities/backup_metadata.dart';
import 'package:zexano_sms/features/backup/domain/repositories/backup_repository.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_config.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_file_name.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';
import 'package:zexano_sms/features/backup/presentation/providers/backup_providers.dart';

Future<Directory> _getBackupsDirectory() async {
  final dir = await getApplicationDocumentsDirectory();
  final backupDir = Directory('${dir.path}/backups');
  if (!backupDir.existsSync()) {
    backupDir.createSync(recursive: true);
  }
  return backupDir;
}

enum BackupFlowStep { typeSelection, configuration, passphrase, creating, success, error }

class CreateBackupState {
  final BackupFlowStep step;
  final bool isEncrypted;
  final bool includeSms;
  final bool includeWhatsApp;
  final bool includeContacts;
  final String passphrase;
  final String passphraseConfirm;
  final String? errorMessage;
  final BackupMetadata? createdMetadata;

  const CreateBackupState({
    this.step = BackupFlowStep.typeSelection,
    this.isEncrypted = false,
    this.includeSms = true,
    this.includeWhatsApp = true,
    this.includeContacts = true,
    this.passphrase = '',
    this.passphraseConfirm = '',
    this.errorMessage,
    this.createdMetadata,
  });

  bool get canProceedFromType => true;

  bool get canProceedFromConfig =>
      includeSms || includeWhatsApp || includeContacts;

  bool get canProceedFromPassphrase =>
      isEncrypted
          ? (passphrase.length >= 8 && passphrase == passphraseConfirm)
          : true;

  bool get isCreating => step == BackupFlowStep.creating;

  CreateBackupState copyWith({
    BackupFlowStep? step,
    bool? isEncrypted,
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
    String? passphrase,
    String? passphraseConfirm,
    String? errorMessage,
    BackupMetadata? createdMetadata,
    bool clearError = false,
    bool clearCreated = false,
  }) {
    return CreateBackupState(
      step: step ?? this.step,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      includeSms: includeSms ?? this.includeSms,
      includeWhatsApp: includeWhatsApp ?? this.includeWhatsApp,
      includeContacts: includeContacts ?? this.includeContacts,
      passphrase: passphrase ?? this.passphrase,
      passphraseConfirm: passphraseConfirm ?? this.passphraseConfirm,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdMetadata:
          clearCreated ? null : (createdMetadata ?? this.createdMetadata),
    );
  }
}

class CreateBackupNotifier extends StateNotifier<CreateBackupState> {
  final BackupRepository _repository;

  CreateBackupNotifier(this._repository) : super(const CreateBackupState());

  void setEncrypted(bool value) {
    state = state.copyWith(
      isEncrypted: value,
      step: BackupFlowStep.configuration,
    );
  }

  void setNotEncrypted() {
    state = state.copyWith(isEncrypted: false, step: BackupFlowStep.creating);
    _createBackup();
  }

  void toggleSms() => state = state.copyWith(includeSms: !state.includeSms);
  void toggleWhatsApp() =>
      state = state.copyWith(includeWhatsApp: !state.includeWhatsApp);
  void toggleContacts() =>
      state = state.copyWith(includeContacts: !state.includeContacts);

  void goToPassphrase() {
    state = state.copyWith(step: BackupFlowStep.passphrase);
  }

  void goToConfig() {
    state = state.copyWith(step: BackupFlowStep.configuration);
  }

  void setPassphrase(String value) {
    state = state.copyWith(passphrase: value);
  }

  void setPassphraseConfirm(String value) {
    state = state.copyWith(passphraseConfirm: value);
  }

  void createBackup() {
    state = state.copyWith(step: BackupFlowStep.creating, clearError: true);
    _createBackup();
  }

  void reset() {
    state = const CreateBackupState();
  }

  Future<void> _createBackup() async {
    try {
      BackupMetadata? result;
      final fileName = BackupFileName.generate(
        isEncrypted: state.isEncrypted,
      );

      if (state.isEncrypted) {
        final passphraseObj = BackupPassphrase.create(state.passphrase);
        if (passphraseObj == null) {
          state = state.copyWith(
            step: BackupFlowStep.error,
            errorMessage: 'Passphrase must be at least 8 characters',
          );
          return;
        }

        final config = BackupConfig(
          includeSms: state.includeSms,
          includeWhatsApp: state.includeWhatsApp,
          includeContacts: state.includeContacts,
          isEncrypted: true,
        );

        final outcome = await _repository.createEncryptedJsonBackup(
          fileName: fileName,
          config: config,
          passphrase: passphraseObj,
        );

        outcome.fold(
          (failure) {
            state = state.copyWith(
              step: BackupFlowStep.error,
              errorMessage: failure.message,
            );
          },
          (metadata) {
            result = metadata;
          },
        );
        if (result == null) return;
      } else {
        final outcome = await _repository.createSqliteBackup(
          fileName: fileName,
        );

        outcome.fold(
          (failure) {
            state = state.copyWith(
              step: BackupFlowStep.error,
              errorMessage: failure.message,
            );
          },
          (metadata) {
            result = metadata;
          },
        );
        if (result == null) return;
      }

      state = state.copyWith(
        step: BackupFlowStep.success,
        createdMetadata: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        step: BackupFlowStep.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final createBackupNotifierProvider =
    StateNotifierProvider.autoDispose<CreateBackupNotifier, CreateBackupState>(
        (ref) {
  return CreateBackupNotifier(ref.read(backupRepositoryProvider));
});

enum BackupListStatus { initial, loading, loaded, error }

class BackupListState {
  final BackupListStatus status;
  final List<BackupMetadata> backups;
  final String? errorMessage;

  const BackupListState({
    this.status = BackupListStatus.initial,
    this.backups = const [],
    this.errorMessage,
  });

  BackupListState copyWith({
    BackupListStatus? status,
    List<BackupMetadata>? backups,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BackupListState(
      status: status ?? this.status,
      backups: backups ?? this.backups,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BackupListNotifier extends StateNotifier<BackupListState> {
  final BackupRepository _repository;

  BackupListNotifier(this._repository) : super(const BackupListState());

  Future<void> loadBackups() async {
    state = state.copyWith(status: BackupListStatus.loading, clearError: true);
    try {
      final backupsDir = await _getBackupsDirectory();
      final files = backupsDir.listSync().whereType<File>().toList();
      final metadatas = <BackupMetadata>[];
      for (final file in files) {
        final outcome = await _repository.readBackupMetadata(file.path);
        outcome.fold(
          (_) {},
          (metadata) => metadatas.add(metadata),
        );
      }
      metadatas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        status: BackupListStatus.loaded,
        backups: metadatas,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: BackupListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
      await loadBackups();
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> importBackup(String sourcePath) async {
    try {
      final outcome = await _repository.importBackupFile(sourcePath);
      outcome.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (_) {
          loadBackups();
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final backupListNotifierProvider =
    StateNotifierProvider.autoDispose<BackupListNotifier, BackupListState>(
        (ref) {
  return BackupListNotifier(ref.read(backupRepositoryProvider));
});
