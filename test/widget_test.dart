import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/main.dart';

void main() {
  testWidgets('App renders shell navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BulkMessageApp()));
    await tester.pumpAndSettle();
    expect(find.byType(BulkMessageApp), findsOneWidget);
  });
}
