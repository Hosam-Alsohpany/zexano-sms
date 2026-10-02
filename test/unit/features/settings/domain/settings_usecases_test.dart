import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/settings/domain/entities/app_settings.dart';
import 'package:zexano_sms/features/settings/domain/entities/build_info.dart';
import 'package:zexano_sms/features/settings/domain/repositories/settings_repository.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  group('SettingsRepository delegation', () {
    test('getSettings delegates to repository', () async {
    final expected = AppSettings(
      languageCode: LanguageCode.english,
      themeOption: ThemeOption.light,
      smsThrottleInterval: SmsThrottleInterval.fromSeconds(0),
        autoBackupEnabled: false,
        autoBackupIntervalDays: 7,
        backupIncludeSms: true,
        backupIncludeWhatsApp: false,
        backupIncludeContacts: true,
      );
      when(() => mockRepo.getSettings())
          .thenAnswer((_) async => Right(expected));

      final result = await mockRepo.getSettings();
      expect(result, Right(expected));
    });

    test('getSettings returns failure on error', () async {
      final failure = SettingsFailure(message: 'DB error');
      when(() => mockRepo.getSettings())
          .thenAnswer((_) async => Left(failure));

      final result = await mockRepo.getSettings();
      expect(result, Left(failure));
    });

    test('updateLanguage delegates to repository', () async {
      when(
        () => mockRepo.updateLanguage(LanguageCode.arabic),
      ).thenAnswer((_) async => const Right(null));

      final result = await mockRepo.updateLanguage(LanguageCode.arabic);
      expect(result.isRight(), true);
      verify(() => mockRepo.updateLanguage(LanguageCode.arabic)).called(1);
    });

    test('updateTheme delegates to repository', () async {
      when(
        () => mockRepo.updateTheme(ThemeOption.dark),
      ).thenAnswer((_) async => const Right(null));

      final result = await mockRepo.updateTheme(ThemeOption.dark);
      expect(result.isRight(), true);
      verify(() => mockRepo.updateTheme(ThemeOption.dark)).called(1);
    });

    test('updateSmsThrottleInterval delegates to repository', () async {
      when(
        () => mockRepo.updateSmsThrottleInterval(
          SmsThrottleInterval.fromSeconds(3),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await mockRepo.updateSmsThrottleInterval(
        SmsThrottleInterval.fromSeconds(3),
      );
      expect(result.isRight(), true);
    });

    test('updateBackupPreferences delegates to repository', () async {
      when(
        () => mockRepo.updateBackupPreferences(
          autoBackupEnabled: true,
          autoBackupIntervalDays: 14,
          includeSms: true,
          includeWhatsApp: false,
          includeContacts: true,
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await mockRepo.updateBackupPreferences(
        autoBackupEnabled: true,
        autoBackupIntervalDays: 14,
        includeSms: true,
        includeWhatsApp: false,
        includeContacts: true,
      );
      expect(result.isRight(), true);
    });

    test('resetSettings delegates to repository', () async {
      when(
        () => mockRepo.resetSettings(['key1', 'key2']),
      ).thenAnswer((_) async => const Right(null));

      final result = await mockRepo.resetSettings(['key1', 'key2']);
      expect(result.isRight(), true);
    });

    test('resetAllNonDestructiveSettings delegates to repository', () async {
      when(() => mockRepo.resetAllNonDestructiveSettings())
          .thenAnswer((_) async => const Right(null));

      final result = await mockRepo.resetAllNonDestructiveSettings();
      expect(result.isRight(), true);
    });

    test('getBuildInfo delegates to repository', () async {
      when(() => mockRepo.getBuildInfo()).thenAnswer(
        (_) async => Right(const BuildInfo(
          appName: 'Test',
          packageName: 'com.test',
          versionName: '2.0.0',
          versionCode: 2,
        )),
      );

      final result = await mockRepo.getBuildInfo();
      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw 'error').versionName, '2.0.0');
    });
  });
}
