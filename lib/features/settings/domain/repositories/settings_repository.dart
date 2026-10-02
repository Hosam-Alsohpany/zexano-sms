import 'dart:async';

import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../entities/build_info.dart';
import '../value_objects/language_code.dart';
import '../value_objects/sms_throttle_interval.dart';
import '../value_objects/theme_option.dart';

abstract class SettingsRepository {
  Future<AppResult<AppSettings>> getSettings();

  Future<AppResult<Stream<AppSettings>>> observeSettings();

  Future<AppResult<void>> updateLanguage(LanguageCode language);

  Future<AppResult<void>> updateTheme(ThemeOption theme);

  Future<AppResult<void>> updatePreferredWhatsApp(String? packageName);

  Future<AppResult<void>> updateSmsThrottleInterval(
    SmsThrottleInterval interval,
  );

  Future<AppResult<void>> updateBackupPreferences({
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
  });

  Future<AppResult<void>> resetSettings(List<String> settingKeys);

  Future<AppResult<void>> resetAllNonDestructiveSettings();

  Future<AppResult<BuildInfo>> getBuildInfo();

  Future<AppResult<bool>> validateSettingValue(String key, dynamic value);
}
