import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/domain/models/history_detail_projection.dart';
import 'package:zexano_sms/features/history/domain/models/recipient_detail.dart';
import 'package:zexano_sms/features/history/domain/value_objects/history_filter_state.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

void main() {
  final normalizationEngine = NormalizationEngine();

  group('History Module Refactor — Verification Tests', () {
    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Single recipient message flow & status progression
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 1: Single recipient status progression queued -> sending -> sent -> delivered', () {
      // 1. Queued
      expect(MessageStatusService.isPending('queued'), isTrue);
      expect(MessageStatusService.isSuccess('queued'), isFalse);

      // 2. Sending
      expect(MessageStatusService.isPending('sending'), isTrue);

      // 3. Sent
      expect(MessageStatusService.isSuccess('sent'), isTrue);

      // 4. Delivered — both 'sent' and 'delivered' are successes!
      expect(MessageStatusService.isSuccess('delivered'), isTrue);

      final recipient = const RecipientDetail(
        name: 'Hosam',
        phone: '+967771234567',
        status: 'delivered',
      );
      expect(recipient.isSent, isTrue);

      final detail = HistoryDetailProjection(
        entry: const HistoryEntry(
          id: 'sms_1',
          originalId: '1',
          tenantId: 'tenant',
          messageBody: 'Hello',
          createdAt: 1000,
          status: 'delivered',
          totalRecipients: 1,
          successCount: 1,
        ),
        recipients: [recipient],
      );

      // Derived status from recipients must be 'sent' (all successful)
      expect(detail.derivedStatus, equals('sent'));
      expect(detail.sentCount, equals(1));
      expect(detail.failedCount, equals(0));
      expect(detail.queuedCount, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Multi-recipient 3/3 delivered (all sent)
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 2: Multi-recipient 3/3 delivered results in "sent" status, not "queued"', () {
      final status = MessageStatusService.deriveBatchStatus(
        sentCount: 3,
        failedCount: 0,
        queuedCount: 0,
        total: 3,
      );

      expect(status, equals('sent'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Partial delivery (2 delivered, 1 failed)
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 3: Mixed status (2 delivered, 1 failed) results in "partial"', () {
      final status = MessageStatusService.deriveBatchStatus(
        sentCount: 2,
        failedCount: 1,
        queuedCount: 0,
        total: 3,
      );

      expect(status, equals('partial'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Group send title (shows group name, NOT Broadcast)
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 4: Group send displays Group Name', () {
      const entry = HistoryEntry(
        id: 'sms_batch_1',
        originalId: 'batch_1',
        tenantId: 'tenant',
        messageBody: 'Group Announcement',
        createdAt: 1000,
        totalRecipients: 15,
        groupId: 'grp_123',
        groupName: 'Sales Team',
      );

      final title = entry.buildDisplayTitle(
        broadcastFormatter: (n) => 'Broadcast ($n recipients)',
        fallback: 'Unknown',
      );

      expect(title, equals('Sales Team'));
      expect(title, isNot(contains('Broadcast')));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Manual multi-recipient title (shows Broadcast (3 recipients))
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 5: Manual multi-recipient displays localized Broadcast title', () {
      const entry = HistoryEntry(
        id: 'sms_batch_2',
        originalId: 'batch_2',
        tenantId: 'tenant',
        messageBody: 'Manual Multi Send',
        createdAt: 1000,
        totalRecipients: 3,
        groupId: null,
        groupName: null,
      );

      final titleEn = entry.buildDisplayTitle(
        broadcastFormatter: (n) => 'Broadcast ($n recipients)',
        fallback: 'Unknown',
      );
      expect(titleEn, equals('Broadcast (3 recipients)'));

      final titleAr = entry.buildDisplayTitle(
        broadcastFormatter: (n) => 'إرسال جماعي ($n مستلم)',
        fallback: 'غير معروف',
      );
      expect(titleAr, equals('إرسال جماعي (3 مستلم)'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Sender ID detection & Inbound Direction Support
    // ─────────────────────────────────────────────────────────────────────────
    test('Test 6: Sender IDs (111, YT, OTP) are NOT normalized as phone numbers', () {
      expect(normalizationEngine.isPhoneNumber('111'), isFalse);
      expect(normalizationEngine.isPhoneNumber('6060'), isFalse);
      expect(normalizationEngine.isPhoneNumber('8000'), isFalse);
      expect(normalizationEngine.isPhoneNumber('YT'), isFalse);
      expect(normalizationEngine.isPhoneNumber('OTP'), isFalse);
      expect(normalizationEngine.isPhoneNumber('Yemen Mobile'), isFalse);

      // Valid phone numbers return true
      expect(normalizationEngine.isPhoneNumber('+967771234567'), isTrue);
      expect(normalizationEngine.isPhoneNumber('771234567'), isTrue);
      expect(normalizationEngine.isPhoneNumber('0771234567'), isTrue);
    });

    test('Test 6b: Inbound HistoryEntry carries direction="inbound" and receivedAt', () {
      const entry = HistoryEntry(
        id: 'sms_inbound_1',
        originalId: 'inbound_1',
        tenantId: 'tenant',
        messageBody: 'Inbound Verification Code',
        createdAt: 1000,
        direction: 'inbound',
        sourceType: 'inbound',
        receivedAt: 1005,
        phoneNumber: '+967771234567',
        contactName: 'Ahlam',
      );

      expect(entry.isInbound, isTrue);
      expect(entry.isOutbound, isFalse);
      expect(entry.receivedAt, equals(1005));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // State Transition Map Tests (Regression Prevention)
    // ─────────────────────────────────────────────────────────────────────────
    test('State Transition Map: prevents retrograde status changes', () {
      // Allowed forward transitions
      expect(MessageStatusService.canTransition('queued', 'sending'), isTrue);
      expect(MessageStatusService.canTransition('queued', 'sent'), isTrue);
      expect(MessageStatusService.canTransition('sending', 'sent'), isTrue);
      expect(MessageStatusService.canTransition('sent', 'delivered'), isTrue);

      // Prohibited backward/regressive transitions
      expect(MessageStatusService.canTransition('delivered', 'failed'), isFalse);
      expect(MessageStatusService.canTransition('delivered', 'queued'), isFalse);
      expect(MessageStatusService.canTransition('sent', 'queued'), isFalse);
      expect(MessageStatusService.canTransition('sent', 'failed'), isFalse);
      expect(MessageStatusService.canTransition('failed', 'queued'), isFalse);
      expect(MessageStatusService.canTransition('failed', 'sent'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // HistoryFilterState Tests
    // ─────────────────────────────────────────────────────────────────────────
    test('HistoryFilterState: default values and computed date ranges', () {
      const state = HistoryFilterState();
      expect(state.isDefault, isTrue);
      expect(state.channelType, equals('all'));
      expect(state.direction, equals('all'));
      expect(state.status, isNull);
      expect(state.sourceType, isNull);

      final updated = state.copyWith(status: 'sent', direction: 'inbound');
      expect(updated.isDefault, isFalse);
      expect(updated.status, equals('sent'));
      expect(updated.direction, equals('inbound'));
    });
  });
}
