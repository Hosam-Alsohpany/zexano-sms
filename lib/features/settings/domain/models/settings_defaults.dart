import '../value_objects/language_code.dart';
import '../value_objects/sms_throttle_interval.dart';
import '../value_objects/theme_option.dart';

abstract final class SettingsDefaults {
  static const LanguageCode languageCode = LanguageCode.english;
  static const ThemeOption themeOption = ThemeOption.light;
  static const String? preferredWhatsAppPackage = null;
  static SmsThrottleInterval get smsThrottleInterval =>
      SmsThrottleInterval.fromSeconds(1);
  static const bool autoBackupEnabled = false;
  static const int autoBackupIntervalDays = 7;
  static const bool backupIncludeSms = true;
  static const bool backupIncludeWhatsApp = true;
  static const bool backupIncludeContacts = true;
}
