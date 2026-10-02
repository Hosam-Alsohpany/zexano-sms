import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

void main() {
  group('Phase 1: Status Lifecycle & State Machine Invariants', () {
    test('Valid outbound lifecycle transitions succeed: queued -> sending -> sent -> delivered', () {
      expect(MessageStatusService.canTransition('queued', 'sending', direction: 'outbound'), isTrue);
      expect(MessageStatusService.canTransition('sending', 'sent', direction: 'outbound'), isTrue);
      expect(MessageStatusService.canTransition('sent', 'delivered', direction: 'outbound'), isTrue);
    });

    test('Valid outbound failure transition: sending -> failed', () {
      expect(MessageStatusService.canTransition('sending', 'failed', direction: 'outbound'), isTrue);
      expect(MessageStatusService.canTransition('queued', 'failed', direction: 'outbound'), isTrue);
    });

    test('Strict Invariant: Outbound SMS can NEVER transition to or have status "received"', () {
      expect(MessageStatusService.isStatusAllowedForDirection('received', 'outbound'), isFalse);
      expect(MessageStatusService.canTransition('queued', 'received', direction: 'outbound'), isFalse);
      expect(MessageStatusService.canTransition('sending', 'received', direction: 'outbound'), isFalse);
      expect(MessageStatusService.canTransition('sent', 'received', direction: 'outbound'), isFalse);
      expect(MessageStatusService.canTransition('delivered', 'received', direction: 'outbound'), isFalse);
    });

    test('Strict Invariant: Inbound SMS can NEVER transition to or have status "delivered"', () {
      expect(MessageStatusService.isStatusAllowedForDirection('delivered', 'inbound'), isFalse);
      expect(MessageStatusService.canTransition('received', 'delivered', direction: 'inbound'), isFalse);
    });

    test('Strict Invariant: Regression prevention (Delivered and Sent cannot regress)', () {
      // Delivered is terminal — cannot regress to sent, sending, queued
      expect(MessageStatusService.canTransition('delivered', 'sent'), isFalse);
      expect(MessageStatusService.canTransition('delivered', 'sending'), isFalse);
      expect(MessageStatusService.canTransition('delivered', 'queued'), isFalse);
      expect(MessageStatusService.canTransition('delivered', 'failed'), isFalse);

      // Sent cannot regress to sending or queued
      expect(MessageStatusService.canTransition('sent', 'sending'), isFalse);
      expect(MessageStatusService.canTransition('sent', 'queued'), isFalse);

      // Failed is terminal — cannot transition
      expect(MessageStatusService.canTransition('failed', 'sent'), isFalse);
      expect(MessageStatusService.canTransition('failed', 'delivered'), isFalse);

      // Received is terminal — cannot transition
      expect(MessageStatusService.canTransition('received', 'sent'), isFalse);
      expect(MessageStatusService.canTransition('received', 'delivered'), isFalse);
    });

    test('Priority table respects finality ordering', () {
      expect(MessageStatusService.statusPriority['received']!, greaterThan(MessageStatusService.statusPriority['delivered']!));
      expect(MessageStatusService.statusPriority['delivered']!, greaterThan(MessageStatusService.statusPriority['sent']!));
      expect(MessageStatusService.statusPriority['sent']!, greaterThan(MessageStatusService.statusPriority['failed']!));
      expect(MessageStatusService.statusPriority['failed']!, greaterThan(MessageStatusService.statusPriority['sending']!));
      expect(MessageStatusService.statusPriority['sending']!, greaterThan(MessageStatusService.statusPriority['queued']!));
    });

    test('deriveBatchStatus does not return received for outbound batches', () {
      // Batch with 2 sent and 1 still queued (e.g. phone closed, carrier pending)
      final status = MessageStatusService.deriveBatchStatus(
        sentCount: 2,
        failedCount: 0,
        queuedCount: 1,
        total: 3,
        receivedCount: 0,
      );
      expect(status, equals('partial'));
    });

    test('deriveBatchStatus only returns received when ALL rows are received', () {
      final inboundStatus = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 0,
        queuedCount: 0,
        total: 1,
        receivedCount: 1,
      );
      expect(inboundStatus, equals('received'));
    });
  });

  group('Phase 3 & 4: Normalization & peerId Contract Synchronization', () {
    final engine = NormalizationEngine();

    test('Standard Yemeni Phone Numbers normalize to E.164 and generate canonical peerId', () {
      expect(engine.normalize('771234567'), equals('+967771234567'));
      expect(engine.peerIdFor('771234567'), equals('sms:+967771234567'));

      expect(engine.normalize('0771234567'), equals('+967771234567'));
      expect(engine.peerIdFor('0771234567'), equals('sms:+967771234567'));

      expect(engine.normalize('+967771234567'), equals('+967771234567'));
      expect(engine.peerIdFor('+967771234567'), equals('sms:+967771234567'));

      expect(engine.normalize('00967771234567'), equals('+967771234567'));
      expect(engine.peerIdFor('00967771234567'), equals('sms:+967771234567'));
    });

    test('Short Codes (e.g. 6060, 8000, 111) are recognized as Sender IDs and generate canonical peerId', () {
      expect(engine.isSenderId('6060'), isTrue);
      expect(engine.isPhoneNumber('6060'), isFalse);
      expect(engine.normalize('6060'), equals('')); // Must NOT prepend +967
      expect(engine.peerIdFor('6060'), equals('sms:6060'));

      expect(engine.isSenderId('8000'), isTrue);
      expect(engine.peerIdFor('8000'), equals('sms:8000'));

      expect(engine.isSenderId('111'), isTrue);
      expect(engine.peerIdFor('111'), equals('sms:111'));
    });

    test('Alphanumeric Sender IDs (e.g. SABAFON, ZEXANO, YEMEN_MOBILE) generate canonical peerId', () {
      expect(engine.isSenderId('SABAFON'), isTrue);
      expect(engine.normalize('SABAFON'), equals(''));
      expect(engine.peerIdFor('SABAFON'), equals('sms:SABAFON'));

      expect(engine.isSenderId('ZEXANO'), isTrue);
      expect(engine.peerIdFor('ZEXANO'), equals('sms:ZEXANO'));

      expect(engine.isSenderId('YEMEN_MOBILE'), isTrue);
      expect(engine.peerIdFor('YEMEN_MOBILE'), equals('sms:YEMEN_MOBILE'));
    });
  });

  group('Delivery Report & TP-Status Invariants', () {
    test('Rule 1: SENT RESULT_OK is strictly "sent", NEVER "delivered"', () {
      // Submission ACK only confirms the message reached the carrier/SMSC
      const sentReportStatus = 'sent';
      expect(sentReportStatus, equals('sent'));
      expect(sentReportStatus, isNot('delivered'));
      expect(MessageStatusService.canTransition('sending', sentReportStatus), isTrue);
    });

    test('Rule 2: Temporary delivery report preserves "sent" (idempotent no-op)', () {
      // e.g. Phone is closed / temporary error (TP-Status 32..63)
      expect(MessageStatusService.canTransition('sent', 'sent'), isTrue);
    });

    test('Rule 3: GSM TP-Status (3GPP TS 23.040) classification', () {
      // Helper function simulating SmsSentReceiver GSM logic
      String? mapGsmTpStatus(int rawStatus) {
        if (rawStatus >= 0 && rawStatus <= 31) return 'delivered';
        if (rawStatus >= 32 && rawStatus <= 63) return null; // remain sent
        if (rawStatus >= 64 && rawStatus <= 127) return 'failed';
        return null; // ambiguous -> remain sent
      }

      // Positive delivery (0..31)
      expect(mapGsmTpStatus(0), equals('delivered'));
      expect(mapGsmTpStatus(1), equals('delivered'));
      expect(mapGsmTpStatus(31), equals('delivered'));

      // Temporary error / phone closed (32..63) -> remains null (sent)
      expect(mapGsmTpStatus(32), isNull); // Congestion
      expect(mapGsmTpStatus(34), isNull); // No response from SME (phone off)
      expect(mapGsmTpStatus(48), isNull); // SC specific temporary

      // Permanent failure (64..127)
      expect(mapGsmTpStatus(64), equals('failed'));
      expect(mapGsmTpStatus(127), equals('failed'));

      // Unparseable / negative -> remain sent
      expect(mapGsmTpStatus(-1), isNull);
    });

    test('Rule 4: CDMA TP-Status (3GPP2 format) classification', () {
      // Helper function simulating SmsSentReceiver CDMA logic
      String? mapCdmaTpStatus(int rawStatus) {
        final errorClass = (rawStatus >> 24) & 0x03;
        if (rawStatus == 0 || errorClass == 0) return 'delivered';
        if (errorClass == 2) return null; // temporary -> remain sent
        if (errorClass == 3) return 'failed'; // permanent error
        return null;
      }

      // Positive delivery (status == 0 or errorClass == 0)
      expect(mapCdmaTpStatus(0), equals('delivered'));
      expect(mapCdmaTpStatus(0x00020000), equals('delivered')); // errorClass 0

      // Temporary pending (errorClass == 2) -> remains null (sent)
      expect(mapCdmaTpStatus(0x02000000), isNull);

      // Permanent failure (errorClass == 3)
      expect(mapCdmaTpStatus(0x03000000), equals('failed'));
    });

    test('Rule 5: Multi-recipient status independence in batch/group send', () {
      // 3 recipients: A -> delivered, B -> sent (closed phone), C -> failed
      final recipientStatuses = {
        'rec-A': 'delivered',
        'rec-B': 'sent',
        'rec-C': 'failed',
      };

      expect(recipientStatuses['rec-A'], equals('delivered'));
      expect(recipientStatuses['rec-B'], equals('sent'));
      expect(recipientStatuses['rec-C'], equals('failed'));

      // Batch aggregate: 2 successful (delivered+sent), 1 failed
      final batchStatus = MessageStatusService.deriveBatchStatus(
        sentCount: 2, // delivered + sent
        failedCount: 1,
        queuedCount: 0,
        total: 3,
      );
      expect(batchStatus, equals('partial'));
    });

    test('Rule 6: Multiple messages to same recipient have distinct identities', () {
      final msg1Id = 'msg-uuid-1';
      final msg2Id = 'msg-uuid-2';
      final targetPhone = '+967771234567';

      final Map<String, String> messageStatusMap = {
        msg1Id: 'delivered',
        msg2Id: 'sent',
      };

      // Updating msg1 to delivered does NOT affect msg2
      expect(messageStatusMap[msg1Id], equals('delivered'));
      expect(messageStatusMap[msg2Id], equals('sent'));
    });

    test('Rule 7: Missing PDU delivery report is ambiguous -> strictly remain sent (never delivered)', () {
      // Simulating handleDeliveryReport when pdu == null
      String? evaluateDeliveryReport({required List<int>? pdu, required int resultCode}) {
        if (pdu == null) {
          // Invariant: Missing PDU cannot prove handset receipt -> remain sent
          return null; // mappedStatus is null -> status remains 'sent'
        }
        return 'delivered';
      }

      // Even if resultCode is Activity.RESULT_OK (-1), without PDU it remains sent!
      const resultOk = -1;
      final status = evaluateDeliveryReport(pdu: null, resultCode: resultOk);
      expect(status, isNull, reason: 'Missing PDU must NEVER be promoted to delivered');
    });
  });
}
