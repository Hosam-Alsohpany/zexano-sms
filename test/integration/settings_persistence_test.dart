import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zexano_sms/features/settings/data/datasources/settings_local_source.dart';
import 'package:zexano_sms/features/settings/data/mappers/settings_mapper.dart';
import 'package:zexano_sms/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';

void main() {
  group('Settings persistence integration', () {
    late SharedPreferences prefs;
    late SettingsLocalSource localSource;
    late SettingsRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localSource = SettingsLocalSource(prefs);
      repository = SettingsRepositoryImpl(localSource);
    });

    test('full round-trip: set language, read back', () async {
      await repository.updateLanguage(LanguageCode.arabic);

      final result = await repository.getSettings();
      expect(result.isRight(), true);
      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.languageCode, LanguageCode.arabic);
    });

    test('full round-trip: set theme, read back', () async {
      await repository.updateTheme(ThemeOption.dark);

      final result = await repository.getSettings();
      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.themeOption, ThemeOption.dark);
    });

    test('full round-trip: set throttle interval, read back', () async {
      await repository.updateSmsThrottleInterval(
        SmsThrottleInterval.fromSeconds(5),
      );

      final result = await repository.getSettings();
      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.smsThrottleInterval.inSeconds, 5);
    });

    test('full round-trip: set backup preferences, read back', () async {
      await repository.updateBackupPreferences(
        autoBackupEnabled: true,
        autoBackupIntervalDays: 14,
        includeSms: false,
        includeWhatsApp: true,
        includeContacts: false,
      );

      final result = await repository.getSettings();
      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.autoBackupEnabled, true);
      expect(settings.autoBackupIntervalDays, 14);
      expect(settings.backupIncludeSms, false);
      expect(settings.backupIncludeWhatsApp, true);
      expect(settings.backupIncludeContacts, false);
    });

    test('full round-trip: set multiple settings cumulatively', () async {
      await repository.updateLanguage(LanguageCode.arabic);
      await repository.updateTheme(ThemeOption.dark);
      await repository.updateSmsThrottleInterval(
        SmsThrottleInterval.fromSeconds(10),
      );

      final result = await repository.getSettings();
      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.languageCode, LanguageCode.arabic);
      expect(settings.themeOption, ThemeOption.dark);
      expect(settings.smsThrottleInterval.inSeconds, 10);
      expect(settings.autoBackupEnabled, false);
    });

    test('resetAllNonDestructive clears all except language and theme',
        () async {
      await repository.updateLanguage(LanguageCode.arabic);
      await repository.updateTheme(ThemeOption.dark);
      await repository.updateSmsThrottleInterval(
        SmsThrottleInterval.fromSeconds(30),
      );
      await repository.updateBackupPreferences(
        autoBackupEnabled: true,
        autoBackupIntervalDays: 1,
        includeSms: false,
        includeWhatsApp: false,
        includeContacts: false,
      );

      await repository.resetAllNonDestructiveSettings();

      final result = await repository.getSettings();
      final settings = result.getOrElse(() => throw 'unexpected');

      expect(settings.languageCode, LanguageCode.arabic);
      expect(settings.themeOption, ThemeOption.dark);

      expect(settings.smsThrottleInterval.inSeconds, 1);
      expect(settings.autoBackupEnabled, false);
      expect(settings.autoBackupIntervalDays, 7);
      expect(settings.backupIncludeSms, true);
      expect(settings.backupIncludeWhatsApp, true);
      expect(settings.backupIncludeContacts, true);
    });

    test('multiple getSettings calls return consistent data', () async {
      await repository.updateLanguage(LanguageCode.arabic);

      final a = await repository.getSettings();
      final b = await repository.getSettings();

      expect(
        a.getOrElse(() => throw 'unexpected'),
        b.getOrElse(() => throw 'unexpected'),
      );
    });

    test('SettingsMapper maps preferences correctly', () {
      final map = <String, dynamic>{
        SettingsLocalSource.keyLanguageCode: 'ar',
        SettingsLocalSource.keyThemeOption: 'dark',
        SettingsLocalSource.keySmsThrottleSeconds: 5,
        SettingsLocalSource.keyAutoBackupEnabled: true,
        SettingsLocalSource.keyAutoBackupIntervalDays: 14,
        SettingsLocalSource.keyBackupIncludeSms: false,
        SettingsLocalSource.keyBackupIncludeWhatsApp: true,
        SettingsLocalSource.keyBackupIncludeContacts: false,
      };

      final settings = SettingsMapper.fromMap(map);
      expect(settings.languageCode, LanguageCode.arabic);
      expect(settings.themeOption, ThemeOption.dark);
      expect(settings.smsThrottleInterval.inSeconds, 5);
      expect(settings.autoBackupEnabled, true);
      expect(settings.autoBackupIntervalDays, 14);
      expect(settings.backupIncludeSms, false);
      expect(settings.backupIncludeWhatsApp, true);
      expect(settings.backupIncludeContacts, false);
    });
  });
}
