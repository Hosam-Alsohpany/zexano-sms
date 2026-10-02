import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/presentation/widgets/history_filter_bar.dart';

void main() {
  Widget _buildApp({
    required Function(String query) onSearch,
    Function(String channel)? onChannelFilter,
  }) {
    return ProviderScope(
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
        home: Scaffold(
          body: HistoryFilterBar(
            onSearch: onSearch,
            onChannelFilter: onChannelFilter,
          ),
        ),
      ),
    );
  }

  testWidgets('renders search field', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(onSearch: (_) {}));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('renders all channel filter chips', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(onSearch: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('All Channels'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('calls onSearch when text is entered', (WidgetTester tester) async {
    String? searchQuery;
    await tester.pumpWidget(_buildApp(onSearch: (q) => searchQuery = q));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    expect(searchQuery, 'hello');
  });

  testWidgets('calls onChannelFilter when SMS chip is tapped', (WidgetTester tester) async {
    String? channelFilter;
    await tester.pumpWidget(_buildApp(
      onSearch: (_) {},
      onChannelFilter: (c) => channelFilter = c,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SMS'));
    await tester.pump();

    expect(channelFilter, 'sms');
  });

  testWidgets('calls onChannelFilter when WhatsApp chip is tapped', (WidgetTester tester) async {
    String? channelFilter;
    await tester.pumpWidget(_buildApp(
      onSearch: (_) {},
      onChannelFilter: (c) => channelFilter = c,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WhatsApp'));
    await tester.pump();

    expect(channelFilter, 'whatsapp');
  });

  testWidgets('calls onChannelFilter with all when All Channels chip is tapped', (WidgetTester tester) async {
    String? channelFilter;
    await tester.pumpWidget(_buildApp(
      onSearch: (_) {},
      onChannelFilter: (c) => channelFilter = c,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Channels'));
    await tester.pump();

    expect(channelFilter, 'all');
  });
}
