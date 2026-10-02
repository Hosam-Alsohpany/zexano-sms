// ignore_for_file: lines_longer_than_80_chars
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';
import 'package:zexano_sms/features/sms/data/mappers/sms_mapper.dart';
import 'package:zexano_sms/features/sms/data/repositories/sms_repository_impl.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────
class MockSmsLocalSource extends Mock implements SmsLocalSource {}
class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockSmsDispatcher extends Mock implements SmsDispatcher {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// يُنشئ Contact بسيطاً للاختبار
Contact _contact({
  required String id,
  required String firstName,
  required String phone,
  String normalizedPhone = '',
}) {
  return Contact(
    id: id,
    tenantId: 'test-tenant',
    firstName: firstName,
    phoneNumber: phone,
    normalizedPhone: normalizedPhone.isNotEmpty ? normalizedPhone : phone,
    createdAt: 0,
  );
}

void main() {
  late SmsRepository repository;
  late MockSmsLocalSource mockLocalSource;
  late MockGroupsRepository mockGroupsRepo;
  late MockSmsDispatcher mockDispatcher;

  setUpAll(() {
    registerFallbackValue(
      SmsMapper.historyRowCompanion(
        id: 'fallback-id',
        tenantId: 'fallback-tenant',
        batchId: 'fallback-batch',
        targetPhone: '+967771234567',
        messageBody: 'fallback',
        channelType: 'sms',
        contactName: '',
        timestamp: 0,
        peerId: 'sms:+967771234567',
      ),
    );
    registerFallbackValue(<dynamic>[]);
  });

  setUp(() {
    mockLocalSource = MockSmsLocalSource();
    mockGroupsRepo = MockGroupsRepository();
    mockDispatcher = MockSmsDispatcher();

    when(() => mockLocalSource.batchInsertHistoryRows(any())).thenAnswer((_) async {});
    when(() => mockLocalSource.updateStatusByIdSafe(any(), any(), sentAt: any(named: 'sentAt'))).thenAnswer((_) async {});
    when(() => mockDispatcher.sendBatch(
          phoneNumbers: any(named: 'phoneNumbers'),
          messageBody: any(named: 'messageBody'),
          channelType: any(named: 'channelType'),
          messageIds: any(named: 'messageIds'),
        )).thenAnswer((_) async => SmsDispatchSummary(
          succeededPhones: const ['+967771234567', '+967771234568', '+967771234569'],
          failedPhones: const [],
        ));

    repository = SmsRepositoryImpl(
      localSource: mockLocalSource,
      groupsRepository: mockGroupsRepo,
      dispatcher: mockDispatcher,
      normalizationEngine: NormalizationEngine(),
      phoneValidator: PhoneValidator(),
    );
    when(() => mockLocalSource.updateBatchStatuses(any(), any()))
        .thenAnswer((_) async {});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: 3 أعضاء صحيحيين
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – مجموعة بـ 3 أعضاء صحيحيين', () {
    final members = [
      _contact(id: 'c1', firstName: 'أحمد', phone: '+967771234567'),
      _contact(id: 'c2', firstName: 'محمد', phone: '+966501234567'),
      _contact(id: 'c3', firstName: 'سارة', phone: '+14155552671'),
    ];

    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('group-1'))
          .thenAnswer((_) async => Right(members));

      when(() => mockDispatcher.sendBatch(
                phoneNumbers: any(named: 'phoneNumbers'),
                messageBody: any(named: 'messageBody'),
                channelType: any(named: 'channelType'),
              ))
          .thenAnswer((invocation) async {
        final phones = invocation.namedArguments[#phoneNumbers] as List<String>;
        return SmsDispatchSummary(
          succeededPhones: phones,
          failedPhones: [],
        );
      });
    });

    test('يُرسل لجميع الأعضاء الثلاثة ويُرجع sentSuccessfully=3', () async {
      final result = await repository.sendGroupSms(
        groupId: 'group-1',
        messageBody: 'رسالة اختبار',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (batch) {
          expect(batch.sentSuccessfully, 3);
          expect(batch.failedCount, 0);
          expect(MessageStatusService.isPending(batch.status) || batch.status == 'queued' || batch.status == 'sent', true);
        },
      );

      // التحقق أن dispatcher استُدعي بـ 3 أرقام
      final captured = verify(() => mockDispatcher.sendBatch(
            phoneNumbers: captureAny(named: 'phoneNumbers'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
            messageIds: any(named: 'messageIds'),
          )).captured;
      final phones = captured.first as List<String>;
      expect(phones.length, 3);
      expect(phones, containsAll(['+967771234567', '+966501234567', '+14155552671']));
    });

    test('يحفظ سجل في قاعدة البيانات لكل عضو', () async {
      await repository.sendGroupSms(
        groupId: 'group-1',
        messageBody: 'رسالة',
      );

      verify(() => mockLocalSource.batchInsertHistoryRows(any())).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: مجموعة فارغة
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – مجموعة فارغة', () {
    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('empty-group'))
          .thenAnswer((_) async => const Right([]));
    });

    test('يُرجع ValidationFailure مع كود GROUP_EMPTY', () async {
      final result = await repository.sendGroupSms(
        groupId: 'empty-group',
        messageBody: 'رسالة',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.code, 'GROUP_EMPTY');
        },
        (_) => fail('expected failure'),
      );

      // لا يجب أن يُستدعى dispatcher أبداً
      verifyNever(() => mockDispatcher.sendBatch(
            phoneNumbers: any(named: 'phoneNumbers'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
            messageIds: any(named: 'messageIds'),
          ));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: عضو برقم خاطئ (بدون normalizedPhone)
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – عضو بـ phoneNumber فارغ', () {
    final members = [
      _contact(id: 'c1', firstName: 'صالح', phone: '+967771234567'),
      _contact(id: 'c2', firstName: 'بدون رقم', phone: '', normalizedPhone: ''),
      _contact(id: 'c3', firstName: 'خالد', phone: '+966501234567'),
    ];

    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('partial-group'))
          .thenAnswer((_) async => Right(members));

      when(() => mockDispatcher.sendBatch(
                phoneNumbers: any(named: 'phoneNumbers'),
                messageBody: any(named: 'messageBody'),
                channelType: any(named: 'channelType'),
                messageIds: any(named: 'messageIds'),
              ))
          .thenAnswer((invocation) async {
        final phones = invocation.namedArguments[#phoneNumbers] as List<String>;
        return SmsDispatchSummary(
          succeededPhones: phones,
          failedPhones: const [],
        );
      });
    });

    test('يُرسل للأعضاء ذوي الأرقام الصحيحة فقط (2 من 3) ولا يفشل الكل', () async {
      final result = await repository.sendGroupSms(
        groupId: 'partial-group',
        messageBody: 'رسالة',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (batch) {
          // يجب أن يُرسل فقط لمن لديه رقم (2 فقط من أصل 3)
          expect(batch.totalRequested, 2);
          expect(batch.sentSuccessfully, 2);
          expect(batch.failedCount, 0);
        },
      );

      final captured = verify(() => mockDispatcher.sendBatch(
            phoneNumbers: captureAny(named: 'phoneNumbers'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
            messageIds: any(named: 'messageIds'),
          )).captured;
      final phones = captured.first as List<String>;
      expect(phones.length, 2);
      expect(phones, isNot(contains(''))); // لا يجب أن يكون هناك رقم فارغ
      expect(phones, contains('+967771234567'));
      expect(phones, contains('+966501234567'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: أعضاء من دول متعددة
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – أعضاء من دول متعددة', () {
    final multiCountryMembers = [
      _contact(id: 'c1', firstName: 'يمن', phone: '+967771234567'),
      _contact(id: 'c2', firstName: 'سعودي', phone: '+966501234567'),
      _contact(id: 'c3', firstName: 'أمريكي', phone: '+14155552671'),
      _contact(id: 'c4', firstName: 'بريطاني', phone: '+447700900000'),
      _contact(id: 'c5', firstName: 'إماراتي', phone: '+971501234567'),
    ];

    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('multi-country'))
          .thenAnswer((_) async => Right(multiCountryMembers));

      when(() => mockDispatcher.sendBatch(
                phoneNumbers: any(named: 'phoneNumbers'),
                messageBody: any(named: 'messageBody'),
                channelType: any(named: 'channelType'),
                messageIds: any(named: 'messageIds'),
              ))
          .thenAnswer((invocation) async {
        final phones = invocation.namedArguments[#phoneNumbers] as List<String>;
        return SmsDispatchSummary(
          succeededPhones: phones,
          failedPhones: const [],
        );
      });
    });

    test('يُرسل لجميع الدول الخمس بنجاح', () async {
      final result = await repository.sendGroupSms(
        groupId: 'multi-country',
        messageBody: 'Hello World',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (batch) {
          expect(batch.sentSuccessfully, 5);
          expect(batch.failedCount, 0);
          expect(MessageStatusService.isPending(batch.status) || batch.status == 'queued' || batch.status == 'sent', true);
        },
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: فشل تحميل الأعضاء من قاعدة البيانات
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – فشل تحميل المجموعة', () {
    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('bad-group'))
          .thenAnswer((_) async => const Left(DatabaseFailure(
                message: 'DB connection failed',
                code: 'DB_ERR',
              )));
    });

    test('يُرجع MessagingFailure عند فشل استرداد الأعضاء', () async {
      final result = await repository.sendGroupSms(
        groupId: 'bad-group',
        messageBody: 'رسالة',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure.message, contains('DB connection failed'));
        },
        (_) => fail('expected failure'),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group: إرسال جزئي – بعض النجاح وبعض الفشل
  // ═══════════════════════════════════════════════════════════════════════════
  group('sendGroupSms – إرسال جزئي', () {
    final members = [
      _contact(id: 'c1', firstName: 'أحمد', phone: '+967771234567'),
      _contact(id: 'c2', firstName: 'محمد', phone: '+967773456789'),
      _contact(id: 'c3', firstName: 'سارة', phone: '+967770987654'),
    ];

    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('partial-send'))
          .thenAnswer((_) async => Right(members));

      // نجح c1 وc3، فشل c2
      when(() => mockDispatcher.sendBatch(
                phoneNumbers: any(named: 'phoneNumbers'),
                messageBody: any(named: 'messageBody'),
                channelType: any(named: 'channelType'),
                messageIds: any(named: 'messageIds'),
              ))
          .thenAnswer((_) async => SmsDispatchSummary(
                succeededPhones: ['+967771234567', '+967770987654'],
                failedPhones: [
                  SmsDispatchFailure(phoneNumber: '+967773456789', reason: 'Network error'),
                ],
              ));
    });

    test('يُرجع حالة partial مع العدد الصحيح للنجاح والفشل', () async {
      final result = await repository.sendGroupSms(
        groupId: 'partial-send',
        messageBody: 'رسالة جزئية',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (batch) {
          expect(batch.sentSuccessfully, 2);
          expect(batch.failedCount, 1);
          expect(batch.status, 'partial');
          expect(batch.failedPhoneNumbers, contains('+967773456789'));
        },
      );
    });
  });
}
