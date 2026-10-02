import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/messaging/presentation/screens/messaging_screen.dart';

void main() {
  testWidgets('MessagingScreen renders hub title and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
          home: const MessagingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Messaging'), findsOneWidget);
    expect(find.text('Choose a channel to send your message'), findsOneWidget);
  });

  testWidgets('MessagingScreen shows SMS and WhatsApp action cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
          home: const MessagingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Send SMS'), findsOneWidget);
    expect(find.text('Send WhatsApp'), findsOneWidget);
  });

  testWidgets('MessagingScreen shows View History button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
          home: const MessagingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View History'), findsOneWidget);
  });
}
