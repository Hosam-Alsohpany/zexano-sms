import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/settings/domain/entities/app_settings.dart';
import 'package:zexano_sms/features/settings/domain/repositories/settings_repository.dart';
import '../controllers/settings_notifier.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return sl<SettingsRepository>();
});

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => switch (settings.themeOption.value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    },
    loading: () => ThemeMode.light,
    error: (_, __) => ThemeMode.light,
  );
});

final localeProvider = Provider<Locale>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => Locale(settings.languageCode.value),
    loading: () => const Locale('en'),
    error: (_, __) => const Locale('en'),
  );
});
