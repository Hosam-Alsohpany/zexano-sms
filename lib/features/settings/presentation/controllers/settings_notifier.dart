import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/settings/domain/entities/app_settings.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';
import '../providers/settings_providers.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final result = await repo.getSettings();
    return result.fold(
      (f) => throw Exception(f.message),
      (s) => s,
    );
  }

  Future<void> setLanguage(LanguageCode language) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateLanguage(language);
    result.fold(
      (f) => _setError(f),
      (_) => _update((s) => s.copyWith(languageCode: language)),
    );
  }

  Future<void> setTheme(ThemeOption theme) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateTheme(theme);
    result.fold(
      (f) => _setError(f),
      (_) => _update((s) => s.copyWith(themeOption: theme)),
    );
  }

  Future<void> setPreferredWhatsApp(String? packageName) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updatePreferredWhatsApp(packageName);
    result.fold(
      (f) => _setError(f),
      (_) => _update((s) => s.copyWith(
            preferredWhatsAppPackage: packageName,
            clearWhatsAppPackage: packageName == null,
          )),
    );
  }

  Future<void> setSmsThrottleInterval(SmsThrottleInterval interval) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateSmsThrottleInterval(interval);
    result.fold(
      (f) => _setError(f),
      (_) => _update((s) => s.copyWith(smsThrottleInterval: interval)),
    );
  }

  Future<void> setBackupPreferences({
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateBackupPreferences(
      autoBackupEnabled: autoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays,
      includeSms: includeSms,
      includeWhatsApp: includeWhatsApp,
      includeContacts: includeContacts,
    );
    result.fold(
      (f) => _setError(f),
      (_) => _update((s) => s.copyWith(
            autoBackupEnabled: autoBackupEnabled ?? s.autoBackupEnabled,
            autoBackupIntervalDays:
                autoBackupIntervalDays ?? s.autoBackupIntervalDays,
            backupIncludeSms: includeSms ?? s.backupIncludeSms,
            backupIncludeWhatsApp: includeWhatsApp ?? s.backupIncludeWhatsApp,
            backupIncludeContacts: includeContacts ?? s.backupIncludeContacts,
          )),
    );
  }

  Future<void> resetAllNonDestructive() async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.resetAllNonDestructiveSettings();
    result.fold(
      (f) => _setError(f),
      (_) => ref.invalidateSelf(),
    );
  }

  void _update(AppSettings Function(AppSettings) transform) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(transform(current));
    }
  }

  void _setError(Failure f) {
    state = AsyncValue.error(f.message, StackTrace.current);
  }
}
