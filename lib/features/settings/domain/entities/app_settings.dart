import '../value_objects/language_code.dart';
import '../value_objects/sms_throttle_interval.dart';
import '../value_objects/theme_option.dart';

class AppSettings {
  final LanguageCode languageCode;
  final ThemeOption themeOption;
  final String? preferredWhatsAppPackage;
  final SmsThrottleInterval smsThrottleInterval;
  final bool autoBackupEnabled;
  final int autoBackupIntervalDays;
  final bool backupIncludeSms;
  final bool backupIncludeWhatsApp;
  final bool backupIncludeContacts;

  const AppSettings({
    required this.languageCode,
    required this.themeOption,
    this.preferredWhatsAppPackage,
    required this.smsThrottleInterval,
    required this.autoBackupEnabled,
    required this.autoBackupIntervalDays,
    required this.backupIncludeSms,
    required this.backupIncludeWhatsApp,
    required this.backupIncludeContacts,
  });

  AppSettings copyWith({
    LanguageCode? languageCode,
    ThemeOption? themeOption,
    String? preferredWhatsAppPackage,
    bool clearWhatsAppPackage = false,
    SmsThrottleInterval? smsThrottleInterval,
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    bool? backupIncludeSms,
    bool? backupIncludeWhatsApp,
    bool? backupIncludeContacts,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeOption: themeOption ?? this.themeOption,
      preferredWhatsAppPackage: clearWhatsAppPackage
          ? null
          : (preferredWhatsAppPackage ?? this.preferredWhatsAppPackage),
      smsThrottleInterval: smsThrottleInterval ?? this.smsThrottleInterval,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupIntervalDays:
          autoBackupIntervalDays ?? this.autoBackupIntervalDays,
      backupIncludeSms: backupIncludeSms ?? this.backupIncludeSms,
      backupIncludeWhatsApp:
          backupIncludeWhatsApp ?? this.backupIncludeWhatsApp,
      backupIncludeContacts:
          backupIncludeContacts ?? this.backupIncludeContacts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          languageCode == other.languageCode &&
          themeOption == other.themeOption &&
          preferredWhatsAppPackage == other.preferredWhatsAppPackage &&
          smsThrottleInterval == other.smsThrottleInterval &&
          autoBackupEnabled == other.autoBackupEnabled &&
          autoBackupIntervalDays == other.autoBackupIntervalDays &&
          backupIncludeSms == other.backupIncludeSms &&
          backupIncludeWhatsApp == other.backupIncludeWhatsApp &&
          backupIncludeContacts == other.backupIncludeContacts;

  @override
  int get hashCode => Object.hash(
        languageCode,
        themeOption,
        preferredWhatsAppPackage,
        smsThrottleInterval,
        autoBackupEnabled,
        autoBackupIntervalDays,
        backupIncludeSms,
        backupIncludeWhatsApp,
        backupIncludeContacts,
      );

  @override
  String toString() => 'AppSettings('
      'language: $languageCode, '
      'theme: $themeOption, '
      'whatsApp: $preferredWhatsAppPackage, '
      'throttle: $smsThrottleInterval, '
      'autoBackup: $autoBackupEnabled/$autoBackupIntervalDays, '
      'includeSms: $backupIncludeSms, '
      'includeWhatsApp: $backupIncludeWhatsApp, '
      'includeContacts: $backupIncludeContacts'
      ')';
}
