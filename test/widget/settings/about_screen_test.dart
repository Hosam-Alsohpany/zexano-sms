import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/settings/domain/entities/app_settings.dart';
import 'package:zexano_sms/features/settings/domain/repositories/settings_repository.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/language_code.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/sms_throttle_interval.dart';
import 'package:zexano_sms/features/settings/domain/value_objects/theme_option.dart';
import 'package:zexano_sms/features/settings/presentation/providers/settings_providers.dart';
import 'package:zexano_sms/features/settings/presentation/screens/about_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

Widget createTestApp(SettingsRepository repo) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: const AboutScreen(),
    ),
  );
}

void main() {
  testWidgets('About screen displays app info', (WidgetTester tester) async {
    final mockRepo = MockSettingsRepository();
    final settings = AppSettings(
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
        .thenAnswer((_) async => Right(settings));

    await tester.pumpWidget(createTestApp(mockRepo));
    await tester.pumpAndSettle();

    expect(find.text('Zexano SMS'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('com.zexano.sms'), findsOneWidget);
  });

  testWidgets('About screen shows reset button', (WidgetTester tester) async {
    final mockRepo = MockSettingsRepository();
    final settings = AppSettings(
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
        .thenAnswer((_) async => Right(settings));
    when(() => mockRepo.resetAllNonDestructiveSettings())
        .thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(createTestApp(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    expect(find.text('Reset Settings'), findsOneWidget);
  });

  testWidgets('Reset button opens confirmation dialog',
      (WidgetTester tester) async {
    final mockRepo = MockSettingsRepository();
    final settings = AppSettings(
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
        .thenAnswer((_) async => Right(settings));

    await tester.pumpWidget(createTestApp(mockRepo));
    await tester.pumpAndSettle();

    final resetIcons = find.byIcon(Icons.restart_alt);
    expect(resetIcons, findsOneWidget);
    await tester.tap(resetIcons);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
