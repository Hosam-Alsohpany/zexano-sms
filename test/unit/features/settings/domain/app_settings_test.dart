import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/settings/domain/entities/app_settings.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';

void main() {
  group('AppSettings', () {
    final defaults = AppSettings(
      languageCode: LanguageCode.english,
      themeOption: ThemeOption.light,
      smsThrottleInterval: SmsThrottleInterval.fromSeconds(0),
      autoBackupEnabled: false,
      autoBackupIntervalDays: 7,
      backupIncludeSms: true,
      backupIncludeWhatsApp: false,
      backupIncludeContacts: true,
    );

    test('copyWith updates specified fields', () {
      final modified = defaults.copyWith(
        languageCode: LanguageCode.arabic,
        themeOption: ThemeOption.dark,
      );
      expect(modified.languageCode, LanguageCode.arabic);
      expect(modified.themeOption, ThemeOption.dark);
      expect(modified.autoBackupEnabled, defaults.autoBackupEnabled);
    });

    test('copyWith clearWhatsAppPackage clears package', () {
      final withPackage = defaults.copyWith(
        preferredWhatsAppPackage: 'com.whatsapp',
      );
      expect(withPackage.preferredWhatsAppPackage, 'com.whatsapp');

      final cleared = withPackage.copyWith(clearWhatsAppPackage: true);
      expect(cleared.preferredWhatsAppPackage, isNull);
    });

    test('equality based on all fields', () {
      expect(defaults, defaults.copyWith());
      expect(
        defaults,
        isNot(defaults.copyWith(languageCode: LanguageCode.arabic)),
      );
    });

    test('hashCode consistent with equality', () {
      expect(
        defaults.hashCode,
        defaults.copyWith().hashCode,
      );
    });

    test('toString contains key fields', () {
      final str = defaults.toString();
      expect(str, contains('language:'));
      expect(str, contains('theme:'));
      expect(str, contains('throttle:'));
    });
  });

  group('LanguageCode', () {
    test('create returns null for unsupported code', () {
      expect(LanguageCode.create('fr'), isNull);
      expect(LanguageCode.create(''), isNull);
      expect(LanguageCode.create('   '), isNull);
    });

    test('create returns LanguageCode for en and ar', () {
      expect(LanguageCode.create('en'), LanguageCode.english);
      expect(LanguageCode.create('ar'), LanguageCode.arabic);
    });

    test('create is case-insensitive', () {
      expect(LanguageCode.create('EN'), LanguageCode.english);
      expect(LanguageCode.create('AR'), LanguageCode.arabic);
    });

    test('isValid returns true only for supported codes', () {
      expect(LanguageCode.isValid('en'), isTrue);
      expect(LanguageCode.isValid('ar'), isTrue);
      expect(LanguageCode.isValid('fr'), isFalse);
    });

    test('isArabic and isEnglish helpers', () {
      expect(LanguageCode.english.isEnglish, isTrue);
      expect(LanguageCode.english.isArabic, isFalse);
      expect(LanguageCode.arabic.isArabic, isTrue);
      expect(LanguageCode.arabic.isEnglish, isFalse);
    });

    test('equality based on value', () {
      expect(LanguageCode.create('en'), LanguageCode.english);
      expect(LanguageCode.english, isNot(LanguageCode.arabic));
    });
  });

  group('ThemeOption', () {
    test('fromString returns null for unsupported value', () {
      expect(ThemeOption.fromString('blue'), isNull);
      expect(ThemeOption.fromString(''), isNull);
    });

    test('fromString returns correct option', () {
      expect(ThemeOption.fromString('light'), ThemeOption.light);
      expect(ThemeOption.fromString('dark'), ThemeOption.dark);
      expect(ThemeOption.fromString('system'), ThemeOption.system);
    });

    test('fromString is case-insensitive', () {
      expect(ThemeOption.fromString('LIGHT'), ThemeOption.light);
      expect(ThemeOption.fromString('DARK'), ThemeOption.dark);
    });

    test('isValid returns true only for supported values', () {
      expect(ThemeOption.isValid('light'), isTrue);
      expect(ThemeOption.isValid('dark'), isTrue);
      expect(ThemeOption.isValid('system'), isTrue);
      expect(ThemeOption.isValid('auto'), isFalse);
    });

    test('isLight, isDark, isSystem helpers', () {
      expect(ThemeOption.light.isLight, isTrue);
      expect(ThemeOption.light.isDark, isFalse);
      expect(ThemeOption.dark.isDark, isTrue);
      expect(ThemeOption.system.isSystem, isTrue);
    });

    test('equality based on value', () {
      expect(ThemeOption.light, ThemeOption.fromString('light'));
      expect(ThemeOption.light, isNot(ThemeOption.dark));
    });
  });

  group('SmsThrottleInterval', () {
    test('zero duration is valid', () {
      expect(SmsThrottleInterval.fromSeconds(0).inSeconds, 0);
    });

    test('fromSeconds clamps to valid range', () {
      expect(SmsThrottleInterval.fromSeconds(-1).inSeconds, 0);
      expect(SmsThrottleInterval.fromSeconds(100).inSeconds, 60);
    });

    test('fromSeconds preserves mid-range values', () {
      expect(SmsThrottleInterval.fromSeconds(5).inSeconds, 5);
      expect(SmsThrottleInterval.fromSeconds(30).inSeconds, 30);
    });

    test('create returns null for out-of-range duration', () {
      expect(
        SmsThrottleInterval.create(const Duration(seconds: -1)),
        isNull,
      );
      expect(
        SmsThrottleInterval.create(const Duration(seconds: 120)),
        isNull,
      );
    });

    test('create returns interval for valid duration', () {
      final interval = SmsThrottleInterval.create(
        const Duration(seconds: 3),
      );
      expect(interval, isNotNull);
      expect(interval!.inSeconds, 3);
    });

    test('isValidSeconds returns correct result', () {
      expect(SmsThrottleInterval.isValidSeconds(0), isTrue);
      expect(SmsThrottleInterval.isValidSeconds(30), isTrue);
      expect(SmsThrottleInterval.isValidSeconds(60), isTrue);
      expect(SmsThrottleInterval.isValidSeconds(-1), isFalse);
      expect(SmsThrottleInterval.isValidSeconds(61), isFalse);
    });

    test('equality based on duration', () {
      expect(
        SmsThrottleInterval.fromSeconds(5),
        SmsThrottleInterval.fromSeconds(5),
      );
      expect(
        SmsThrottleInterval.fromSeconds(3),
        isNot(SmsThrottleInterval.fromSeconds(5)),
      );
    });
  });
}
