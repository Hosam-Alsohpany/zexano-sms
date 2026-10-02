import '../../domain/entities/app_settings.dart';
import '../../domain/models/settings_defaults.dart';
import '../../domain/value_objects/language_code.dart';
import '../../domain/value_objects/sms_throttle_interval.dart';
import '../../domain/value_objects/theme_option.dart';
import '../datasources/settings_local_source.dart';

class SettingsMapper {
  static AppSettings fromMap(Map<String, dynamic> map) {
    final languageCode = _resolveLanguageCode(
      map[SettingsLocalSource.keyLanguageCode] as String?,
    );
    final themeOption = _resolveThemeOption(
      map[SettingsLocalSource.keyThemeOption] as String?,
    );
    final preferredWhatsApp =
        map[SettingsLocalSource.keyPreferredWhatsApp] as String?;
    final smsThrottle = _resolveSmsThrottle(
      map[SettingsLocalSource.keySmsThrottleSeconds] as int?,
    );
    final autoBackupEnabled = _resolveBool(
      map[SettingsLocalSource.keyAutoBackupEnabled] as bool?,
      SettingsDefaults.autoBackupEnabled,
    );
    final autoBackupIntervalDays = _resolveInt(
      map[SettingsLocalSource.keyAutoBackupIntervalDays] as int?,
      SettingsDefaults.autoBackupIntervalDays,
    );
    final backupIncludeSms = _resolveBool(
      map[SettingsLocalSource.keyBackupIncludeSms] as bool?,
      SettingsDefaults.backupIncludeSms,
    );
    final backupIncludeWhatsApp = _resolveBool(
      map[SettingsLocalSource.keyBackupIncludeWhatsApp] as bool?,
      SettingsDefaults.backupIncludeWhatsApp,
    );
    final backupIncludeContacts = _resolveBool(
      map[SettingsLocalSource.keyBackupIncludeContacts] as bool?,
      SettingsDefaults.backupIncludeContacts,
    );

    return AppSettings(
      languageCode: languageCode,
      themeOption: themeOption,
      preferredWhatsAppPackage: preferredWhatsApp,
      smsThrottleInterval: smsThrottle,
      autoBackupEnabled: autoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays,
      backupIncludeSms: backupIncludeSms,
      backupIncludeWhatsApp: backupIncludeWhatsApp,
      backupIncludeContacts: backupIncludeContacts,
    );
  }

  static LanguageCode _resolveLanguageCode(String? value) {
    if (value != null) {
      final code = LanguageCode.create(value);
      if (code != null) return code;
    }
    return SettingsDefaults.languageCode;
  }

  static ThemeOption _resolveThemeOption(String? value) {
    if (value != null) {
      final option = ThemeOption.fromString(value);
      if (option != null) return option;
    }
    return SettingsDefaults.themeOption;
  }

  static SmsThrottleInterval _resolveSmsThrottle(int? seconds) {
    if (seconds != null) {
      return SmsThrottleInterval.fromSeconds(seconds);
    }
    return SettingsDefaults.smsThrottleInterval;
  }

  static bool _resolveBool(bool? value, bool defaultValue) {
    return value ?? defaultValue;
  }

  static int _resolveInt(int? value, int defaultValue) {
    return value ?? defaultValue;
  }
}
