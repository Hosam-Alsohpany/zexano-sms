import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/routes/shell_screen.dart';

class _MockNavigationShell extends StatelessWidget {
  final Widget child;
  const _MockNavigationShell({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

void main() {
  testWidgets('AppShell renders NavigationBar', (WidgetTester tester) async {
    final navShell = StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/contacts',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Contacts'))),
              ),
            ),
          ],
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/contacts',
      routes: [navShell],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
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
      ),
    );
    await tester.pump();
    await tester.pump();

    final navbar = find.byType(NavigationBar);
    expect(navbar, findsOneWidget);
  });
}
