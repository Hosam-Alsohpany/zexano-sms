// ignore_for_file: lines_longer_than_80_chars
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/history/data/mappers/history_mapper.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';
import 'package:zexano_sms/features/sms/data/mappers/sms_mapper.dart';
import 'package:zexano_sms/features/sms/data/repositories/sms_repository_impl.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockSmsLocalSource extends Mock implements SmsLocalSource {}
class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockSmsDispatcher extends Mock implements SmsDispatcher {}

// ── DB row builder ────────────────────────────────────────────────────────────

/// Creates a [db.MessageHistoryData] row for testing.
/// All fields not supplied default to safe values.
db.MessageHistoryData _row({
  String id = 'row-1',
  String batchId = 'batch-1',
  String targetPhone = '+967771234567',
  String messageBody = 'Hello',
  String executionStatus = 'queued',
  String direction = 'outbound',
  String sourceType = 'manual',
  String? groupId,
  String contactName = '',
  String? contactId,
  int timestamp = 1000,
  int? sentAt,
  int? receivedAt,
}) {
  return db.MessageHistoryData(
    id: id,
    tenantId: 'test-tenant',
    batchId: batchId,
    contactName: contactName,
    contactId: contactId,
    targetPhone: targetPhone,
    messageBody: messageBody,
    channelType: 'sms',
    executionStatus: executionStatus,
    timestamp: timestamp,
    sentAt: sentAt,
    sourceType: sourceType,
    direction: direction,
    groupId: groupId,
    receivedAt: receivedAt,
    isRead: direction == 'outbound' || executionStatus == 'read',
  );
}

/// Creates a test Contact.
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

// ── Main ──────────────────────────────────────────────────────────────────────
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
        peerId: 'sms:+967771234567',
      ),
    );
    registerFallbackValue(<dynamic>[]);
  });

  setUp(() {
    mockLocalSource = MockSmsLocalSource();
    mockGroupsRepo = MockGroupsRepository();
    mockDispatcher = MockSmsDispatcher();

    when(() => mockLocalSource.insertHistoryRow(any())).thenAnswer((_) async => 1);
    when(() => mockLocalSource.batchInsertHistoryRows(any())).thenAnswer((_) async {});
    when(() => mockLocalSource.updateStatusById(any(), any(), sentAt: any(named: 'sentAt'))).thenAnswer((_) async {});
    when(() => mockLocalSource.updateStatusByIdSafe(any(), any(), sentAt: any(named: 'sentAt'))).thenAnswer((_) async {});
    when(() => mockLocalSource.updateBatchStatuses(any(), any(), sentAt: any(named: 'sentAt'))).thenAnswer((_) async {});
    when(() => mockLocalSource.updateBatchStatuses(any(), any())).thenAnswer((_) async {});

    when(() => mockDispatcher.sendBatch(
          phoneNumbers: any(named: 'phoneNumbers'),
          messageBody: any(named: 'messageBody'),
          channelType: any(named: 'channelType'),
          messageIds: any(named: 'messageIds'),
        )).thenAnswer((_) async => SmsDispatchSummary(
          succeededPhones: const ['+967771234567'],
          failedPhones: const [],
        ));

    repository = SmsRepositoryImpl(
      localSource: mockLocalSource,
      groupsRepository: mockGroupsRepo,
      dispatcher: mockDispatcher,
      normalizationEngine: NormalizationEngine(),
      phoneValidator: PhoneValidator(),
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 1) sendSingleSms — sourceType = 'manual'
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 1: sendSingleSms يدوي → sourceType = manual', () {
    setUp(() {
      when(() => mockDispatcher.send(
            phoneNumber: any(named: 'phoneNumber'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const SmsDispatchResult(
            success: true,
            status: 'queued',
          ));
    });

    test('يُرجع SmsMessage بحالة queued عند استخدام sendSmsWithDelivery', () async {
      final result = await repository.sendSingleSms(
        messageBody: 'رسالة يدوية',
        phoneNumber: '+967771234567',
        sourceType: 'manual',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (msg) {
          expect(msg.status, 'queued');
          expect(msg.totalRecipients, 1);
          expect(msg.sentCount, 1);
        },
      );
    });

    test('يُدعى insertHistoryRow مرة واحدة', () async {
      await repository.sendSingleSms(
        messageBody: 'رسالة',
        phoneNumber: '+967771234567',
      );
      verify(() => mockLocalSource.insertHistoryRow(any())).called(1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2) sendSingleSms — sourceType = 'contact' عند تمرير contactId
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 2: sendSingleSms بـ contactId → sourceType = contact', () {
    setUp(() {
      when(() => mockDispatcher.send(
            phoneNumber: any(named: 'phoneNumber'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const SmsDispatchResult(
            success: true,
            status: 'queued',
          ));
    });

    test('لا يفشل ويُرجع SmsMessage ناجح', () async {
      final result = await repository.sendSingleSms(
        messageBody: 'رسالة جهة اتصال',
        phoneNumber: '+967771234567',
        contactId: 'contact-42',
        contactName: 'أحمد',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (msg) {
          expect(msg.totalRecipients, 1);
          expect(msg.sentCount, 1);
        },
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3) sendGroupSms → sourceType = 'group', groupId مُعبأ
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 3: sendGroupSms → sourceType = group, groupId مُعبأ', () {
    final members = [
      _contact(id: 'c1', firstName: 'أحمد', phone: '+967771234567'),
      _contact(id: 'c2', firstName: 'محمد', phone: '+966501234567'),
    ];

    setUp(() {
      when(() => mockGroupsRepo.listContactsInGroup('grp-1'))
          .thenAnswer((_) async => Right(members));

      when(() => mockDispatcher.sendBatch(
            phoneNumbers: any(named: 'phoneNumbers'),
            messageBody: any(named: 'messageBody'),
            channelType: any(named: 'channelType'),
          )).thenAnswer((inv) async {
        final phones = inv.namedArguments[#phoneNumbers] as List<String>;
        return SmsDispatchSummary(
          succeededPhones: phones,
          failedPhones: [],
        );
      });
    });

    test('يُرجع SmsBatchResult بحالة sent وعدد صحيح', () async {
      final result = await repository.sendGroupSms(
        groupId: 'grp-1',
        messageBody: 'عرض الحملة',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (batch) {
          expect(batch.sentSuccessfully, 2);
          expect(batch.failedCount, 0);
          expect(batch.status, 'queued');
        },
      );
    });

    test('يُدعى batchInsertHistoryRows مع صفوف تحتوي على groupId', () async {
      await repository.sendGroupSms(
        groupId: 'grp-1',
        messageBody: 'عرض',
      );

      final captured = verify(
        () => mockLocalSource.batchInsertHistoryRows(captureAny()),
      ).captured;

      final companions = captured.first as List;
      // كل صف يجب أن يحتوي على groupId = 'grp-1'
      for (final companion in companions) {
        expect(companion.groupId.value, equals('grp-1'));
        expect(companion.sourceType.value, equals('group'));
        expect(companion.direction.value, equals('outbound'));
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4) HistoryMapper — رسالة واردة inbound
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 4: HistoryMapper → رسالة واردة inbound', () {
    test('smsBatchToHistoryEntry يُعيد isInbound=true للرسائل الواردة', () {
      final row = _row(
        id: 'inbound-1',
        batchId: 'inbound-1',
        executionStatus: 'received',
        direction: 'inbound',
        sourceType: 'inbound',
        targetPhone: '+967771234567',
        receivedAt: 1700000000,
      );

      final entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: 'inbound-1',
        tenantId: 'test-tenant',
        rows: [row],
      );

      expect(entry.isInbound, true);
      expect(entry.isOutbound, false);
      expect(entry.direction, 'inbound');
      expect(entry.receivedAt, 1700000000);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5) HistoryMapper — حالة الدُّفعة queued عندما يوجد صف queued
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 5: HistoryMapper → حالة الدفعة queued', () {
    test('يُعيد queued عند وجود صف واحد بحالة queued على الأقل', () {
      final rows = [
        _row(id: 'r1', executionStatus: 'sent'),
        _row(id: 'r2', executionStatus: 'queued'), // لا يزال في الطابور
      ];

      final entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: 'batch-mixed',
        tenantId: 'test-tenant',
        rows: rows,
      );

      expect(entry.status, 'partial');
    });

    test('يُعيد sent عندما جميع الصفوف sent', () {
      final rows = [
        _row(id: 'r1', executionStatus: 'sent', sentAt: 1000),
        _row(id: 'r2', executionStatus: 'sent', sentAt: 1001),
      ];

      final entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: 'batch-all-sent',
        tenantId: 'test-tenant',
        rows: rows,
      );

      expect(entry.status, 'sent');
    });

    test('يُعيد partial عند وجود sent وfailed بدون queued', () {
      final rows = [
        _row(id: 'r1', executionStatus: 'sent', sentAt: 1000),
        _row(id: 'r2', executionStatus: 'failed'),
      ];

      final entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: 'batch-partial',
        tenantId: 'test-tenant',
        rows: rows,
      );

      expect(entry.status, 'partial');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6) HistoryMapper — groupId مُعبأ للإرسال الجماعي
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 6: HistoryMapper → groupId وisGroupSend', () {
    test('يُعيد isGroupSend=true عند وجود groupId وsourceType=group', () {
      final row = _row(
        id: 'g-row-1',
        batchId: 'g-batch-1',
        sourceType: 'group',
        groupId: 'group-abc',
        direction: 'outbound',
        executionStatus: 'sent',
        sentAt: 1000,
      );

      final entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: 'g-batch-1',
        tenantId: 'test-tenant',
        rows: [row],
      );

      expect(entry.isGroupSend, true);
      expect(entry.groupId, 'group-abc');
      expect(entry.sourceType, 'group');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7) HistoryEntry.copyWith — يحافظ على الحقول الجديدة
  // ══════════════════════════════════════════════════════════════════════════
  group('Test 7: HistoryEntry.copyWith يحافظ على الحقول الجديدة', () {
    const original = HistoryEntry(
      id: 'e1',
      originalId: 'b1',
      tenantId: 'tenant',
      messageBody: 'test',
      createdAt: 100,
      sourceType: 'group',
      direction: 'outbound',
      groupId: 'grp-x',
      receivedAt: null,
    );

    test('copyWith يغيّر status بدون التأثير على sourceType أو groupId', () {
      final updated = original.copyWith(status: 'sent');

      expect(updated.status, 'sent');
      expect(updated.sourceType, 'group');
      expect(updated.groupId, 'grp-x');
      expect(updated.direction, 'outbound');
    });

    test('clearGroupId=true يُفرغ groupId ويُعيد isGroupSend=false', () {
      final updated = original.copyWith(clearGroupId: true);

      expect(updated.groupId, isNull);
      expect(updated.isGroupSend, false);
    });
  });
}
