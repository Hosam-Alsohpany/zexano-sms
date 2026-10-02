import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/groups/domain/entities/group.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_batch_result.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/sms/domain/services/sms_capability_service.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockSmsRepository extends Mock implements SmsRepository {}
class MockSmsCapabilityService extends Mock implements SmsCapabilityService {}

const _kBatchResult = SmsBatchResult(
  messageId: 'msg-1',
  totalRequested: 2,
  sentSuccessfully: 2,
  status: 'sent',
);

void main() {
  late MockGroupsRepository mockGroupsRepo;
  late MockSmsRepository mockSmsRepo;
  late MockSmsCapabilityService mockCapService;

  setUp(() {
    mockGroupsRepo = MockGroupsRepository();
    mockSmsRepo = MockSmsRepository();
    mockCapService = MockSmsCapabilityService();

    sl.reset();
    sl.registerLazySingleton<GroupsRepository>(() => mockGroupsRepo);
    sl.registerLazySingleton<SmsRepository>(() => mockSmsRepo);
    sl.registerLazySingleton<SmsCapabilityService>(() => mockCapService);

    when(() => mockGroupsRepo.getGroupById(any())).thenAnswer(
      (_) async => const Right(Group(
        id: 'g1',
        tenantId: 't1',
        name: 'Test Group',
        description: 'Test Desc',
        createdAt: 1000,
        memberCount: 2,
      )),
    );

    when(() => mockGroupsRepo.listContactsInGroup(any())).thenAnswer(
      (_) async => const Right([]),
    );

    when(() => mockCapService.checkCanSend()).thenAnswer(
      (_) async => SmsCapabilityStatus.canSend,
    );
  });

  tearDown(() {
    sl.reset();
  });

  testWidgets('Test 1: Open Group Send -> Click Cancel closes cleanly without lifecycle exception', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          home: GroupDetailScreen(groupId: 'g1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final sendButton = find.text('Send SMS to Group');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    final closeButton = find.byIcon(Icons.close);
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Test 2: Open Group Send -> Send completes -> sheet closes cleanly with snackbar', (tester) async {
    when(() => mockSmsRepo.sendGroupSms(
      groupId: any(named: 'groupId'),
      messageBody: any(named: 'messageBody'),
    )).thenAnswer((_) async => const Right(_kBatchResult));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          home: GroupDetailScreen(groupId: 'g1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.text('Send SMS to Group'));
    await tester.pumpAndSettle();

    // Type message
    await tester.enterText(find.byType(TextField), 'Hello Group');
    await tester.pump();

    // Tap Send
    await tester.tap(find.text('Send'));
    await tester.pump(); // Start send
    await tester.pumpAndSettle(); // Complete send and post-frame callback

    // Sheet should be closed
    expect(find.byType(TextField), findsNothing);

    // Snackbar should be displayed
    expect(find.text('Message sent to group'), findsOneWidget);
  });

  testWidgets('Test 3: Open Group Send -> In flight send -> no duplicate pop or disposal crash', (tester) async {
    final completer = Completer<Either<Failure, SmsBatchResult>>();
    when(() => mockSmsRepo.sendGroupSms(
      groupId: any(named: 'groupId'),
      messageBody: any(named: 'messageBody'),
    )).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          home: GroupDetailScreen(groupId: 'g1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.text('Send SMS to Group'));
    await tester.pumpAndSettle();

    // Type message
    await tester.enterText(find.byType(TextField), 'Async Message');
    await tester.pump();

    // Tap Send
    await tester.tap(find.text('Send'));
    await tester.pump(); // Now isSending = true

    // Close button should be disabled while sending
    final closeButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close));
    expect(closeButton.onPressed, isNull);

    // Now resolve send
    completer.complete(const Right(_kBatchResult));
    await tester.pumpAndSettle();

    // Sheet should be popped cleanly without duplicate pop (GroupDetailScreen still mounted)
    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
