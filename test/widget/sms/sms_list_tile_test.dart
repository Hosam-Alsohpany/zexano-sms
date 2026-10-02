import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/presentation/widgets/sms_list_tile.dart';

void main() {
  final now = DateTime.now();
  final recentEpoch = now.millisecondsSinceEpoch ~/ 1000;

  SmsMessage _message({
    int sentCount = 3,
    int totalRecipients = 5,
    String status = 'sent',
  }) {
    return SmsMessage(
      id: 'msg-1',
      tenantId: 'default-tenant',
      messageBody: 'Hello there!',
      status: status,
      totalRecipients: totalRecipients,
      sentCount: sentCount,
      createdAt: recentEpoch,
    );
  }

  Widget _buildApp(SmsMessage message) {
    return MaterialApp(
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
      home: Scaffold(
        body: SmsListTile(
          message: message,
          onTap: () {},
        ),
      ),
    );
  }

  testWidgets('shows sentCount/totalRecipients format', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message(sentCount: 3, totalRecipients: 5)));
    await tester.pumpAndSettle();

    expect(find.text('3/5 Recipients'), findsOneWidget);
  });

  testWidgets('shows message body', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message()));
    await tester.pumpAndSettle();

    expect(find.text('Hello there!'), findsOneWidget);
  });

  testWidgets('shows sent status badge', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message(status: 'sent')));
    await tester.pumpAndSettle();

    expect(find.text('Sent'), findsOneWidget);
  });

  testWidgets('shows failed status badge', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message(status: 'failed')));
    await tester.pumpAndSettle();

    expect(find.text('Failed'), findsOneWidget);
  });

  testWidgets('shows partial status badge', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message(status: 'partial')));
    await tester.pumpAndSettle();

    expect(find.text('Partial'), findsOneWidget);
  });

  testWidgets('shows queued status badge', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(_message(status: 'queued')));
    await tester.pumpAndSettle();

    expect(find.text('Queued'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
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
        home: Scaffold(
          body: SmsListTile(
            message: _message(),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(SmsListTile));
    expect(tapped, isTrue);
  });
}
