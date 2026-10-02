import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zexano_sms/features/settings/data/datasources/settings_local_source.dart';
import 'package:zexano_sms/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late SettingsLocalSource localSource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    localSource = SettingsLocalSource(mockPrefs);
    repository = SettingsRepositoryImpl(localSource);
  });

  group('SettingsRepositoryImpl', () {
    test('getSettings returns default settings when no values stored', () async {
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.getSettings();
      expect(result.isRight(), true);

      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.languageCode, LanguageCode.english);
      expect(settings.themeOption, ThemeOption.light);
      expect(settings.smsThrottleInterval.inSeconds, 1);
      expect(settings.autoBackupEnabled, false);
    });

    test('getSettings returns stored values when present', () async {
      when(() => mockPrefs.get(SettingsLocalSource.keyLanguageCode))
          .thenReturn('ar');
      when(() => mockPrefs.get(SettingsLocalSource.keyThemeOption))
          .thenReturn('dark');
      when(() => mockPrefs.get(SettingsLocalSource.keySmsThrottleSeconds))
          .thenReturn(5);
      when(() => mockPrefs.get(SettingsLocalSource.keyAutoBackupEnabled))
          .thenReturn(true);
      when(() => mockPrefs.get(SettingsLocalSource.keyAutoBackupIntervalDays))
          .thenReturn(14);
      when(() => mockPrefs.get(SettingsLocalSource.keyBackupIncludeSms))
          .thenReturn(true);
      when(() => mockPrefs.get(SettingsLocalSource.keyBackupIncludeWhatsApp))
          .thenReturn(true);
      when(() => mockPrefs.get(SettingsLocalSource.keyBackupIncludeContacts))
          .thenReturn(false);
      when(() => mockPrefs.get(SettingsLocalSource.keyPreferredWhatsApp))
          .thenReturn(null);

      final result = await repository.getSettings();
      expect(result.isRight(), true);

      final settings = result.getOrElse(() => throw 'unexpected');
      expect(settings.languageCode, LanguageCode.arabic);
      expect(settings.themeOption, ThemeOption.dark);
      expect(settings.smsThrottleInterval.inSeconds, 5);
      expect(settings.autoBackupEnabled, true);
      expect(settings.autoBackupIntervalDays, 14);
      expect(settings.backupIncludeSms, true);
      expect(settings.backupIncludeWhatsApp, true);
      expect(settings.backupIncludeContacts, false);
    });

    test('getSettings returns Left on exception', () async {
      when(() => mockPrefs.get(any())).thenThrow(Exception('Storage error'));

      final result = await repository.getSettings();
      expect(result.isLeft(), true);
    });

    test('updateLanguage persists language code', () async {
      when(
        () => mockPrefs.setString(
          SettingsLocalSource.keyLanguageCode,
          'ar',
        ),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.updateLanguage(LanguageCode.arabic);
      expect(result.isRight(), true);

      verify(
        () => mockPrefs.setString(
          SettingsLocalSource.keyLanguageCode,
          'ar',
        ),
      ).called(1);
    });

    test('updateTheme persists theme option', () async {
      when(
        () => mockPrefs.setString(
          SettingsLocalSource.keyThemeOption,
          'dark',
        ),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.updateTheme(ThemeOption.dark);
      expect(result.isRight(), true);

      verify(
        () => mockPrefs.setString(
          SettingsLocalSource.keyThemeOption,
          'dark',
        ),
      ).called(1);
    });

    test('updateSmsThrottleInterval persists interval', () async {
      when(
        () => mockPrefs.setInt(
          SettingsLocalSource.keySmsThrottleSeconds,
          10,
        ),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.updateSmsThrottleInterval(
        SmsThrottleInterval.fromSeconds(10),
      );
      expect(result.isRight(), true);

      verify(
        () => mockPrefs.setInt(
          SettingsLocalSource.keySmsThrottleSeconds,
          10,
        ),
      ).called(1);
    });

    test('updateBackupPreferences persists backup settings', () async {
      when(
        () => mockPrefs.setBool(
          SettingsLocalSource.keyAutoBackupEnabled,
          true,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setInt(
          SettingsLocalSource.keyAutoBackupIntervalDays,
          7,
        ),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.updateBackupPreferences(
        autoBackupEnabled: true,
        autoBackupIntervalDays: 7,
      );
      expect(result.isRight(), true);
    });

    test('resetAllNonDestructiveSettings preserves language and theme', () async {
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
      when(() => mockPrefs.get(any())).thenReturn(null);

      final result = await repository.resetAllNonDestructiveSettings();
      expect(result.isRight(), true);

      verify(() => mockPrefs.remove(
        SettingsLocalSource.keySmsThrottleSeconds,
      )).called(1);
      verifyNever(() => mockPrefs.remove(
        SettingsLocalSource.keyLanguageCode,
      ));
      verifyNever(() => mockPrefs.remove(
        SettingsLocalSource.keyThemeOption,
      ));
    });

    test('validateSettingValue returns true for valid language code', () async {
      final result = await repository.validateSettingValue(
        SettingsLocalSource.keyLanguageCode,
        'en',
      );
      expect(result.getOrElse(() => false), isTrue);
    });

    test('validateSettingValue returns false for invalid language code', () async {
      final result = await repository.validateSettingValue(
        SettingsLocalSource.keyLanguageCode,
        'fr',
      );
      expect(result.getOrElse(() => true), isFalse);
    });

    test('getBuildInfo returns hardcoded values', () async {
      final result = await repository.getBuildInfo();
      expect(result.isRight(), true);
      final info = result.getOrElse(() => throw 'unexpected');
      expect(info.appName, 'Zexano SMS');
      expect(info.versionName, '1.0.0');
      expect(info.packageName, 'com.zexano.sms');
      expect(info.versionCode, 1);
    });
  });
}
