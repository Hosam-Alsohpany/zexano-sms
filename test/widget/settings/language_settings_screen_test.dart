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
import 'package:zexano_sms/features/settings/presentation/screens/language_settings_screen.dart';

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
      home: const LanguageSettingsScreen(),
    ),
  );
}

void main() {
  testWidgets('Language settings screen shows English selected',
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

    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('العربية'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Language settings screen shows Arabic selected',
      (WidgetTester tester) async {
    final mockRepo = MockSettingsRepository();
    final settings = AppSettings(
      languageCode: LanguageCode.arabic,
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

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
