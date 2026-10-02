import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/domain/models/history_detail_projection.dart';
import 'package:zexano_sms/features/history/domain/models/recipient_detail.dart';

void main() {
  group('Issue 2 & Issue 1: RecipientDetail and HistoryDetailProjection', () {
    test('RecipientDetail correctly identifies received status and avoids false queued', () {
      const receivedRecipient = RecipientDetail(
        name: 'Ahmed',
        phone: '+967771234567',
        status: 'received',
        messageId: 'msg-rec-1',
        peerId: 'sms:+967771234567',
      );

      expect(receivedRecipient.isReceived, isTrue);
      expect(receivedRecipient.isSent, isFalse);
      expect(receivedRecipient.isFailed, isFalse);
      expect(receivedRecipient.isQueued, isFalse); // Invariant: received must NEVER be queued!
      expect(receivedRecipient.messageId, 'msg-rec-1');
      expect(receivedRecipient.peerId, 'sms:+967771234567');
    });

    test('RecipientDetail correctly identifies queued, sent, and failed for outbound', () {
      const queuedRecipient = RecipientDetail(
        name: 'Contact 1',
        phone: '+967771234567',
        status: 'queued',
      );
      expect(queuedRecipient.isQueued, isTrue);
      expect(queuedRecipient.isReceived, isFalse);
      expect(queuedRecipient.isSent, isFalse);
      expect(queuedRecipient.isFailed, isFalse);

      const sentRecipient = RecipientDetail(
        name: 'Contact 2',
        phone: '+967771234567',
        status: 'sent',
      );
      expect(sentRecipient.isSent, isTrue);
      expect(sentRecipient.isQueued, isFalse);
      expect(sentRecipient.isReceived, isFalse);

      const failedRecipient = RecipientDetail(
        name: 'Contact 3',
        phone: '+967771234567',
        status: 'failed',
      );
      expect(failedRecipient.isFailed, isTrue);
      expect(failedRecipient.isQueued, isFalse);
      expect(failedRecipient.isReceived, isFalse);
    });

    test('HistoryDetailProjection.derivedStatus returns "received" for inbound entries', () {
      const inboundEntry = HistoryEntry(
        id: 'inbound-entry-1',
        originalId: 'orig-1',
        tenantId: 'default',
        channelType: 'sms',
        messageBody: 'Inbound SMS content',
        status: 'received',
        direction: 'inbound',
        totalRecipients: 1,
        successCount: 0,
        failedCount: 0,
        createdAt: 1700000000,
        phoneNumber: '+967771234567',
      );

      final projection = HistoryDetailProjection(
        entry: inboundEntry,
        recipients: [
          RecipientDetail(
            name: 'Ahmed',
            phone: '+967771234567',
            status: 'received',
            messageId: 'msg-1',
            peerId: 'sms:+967771234567',
          ),
        ],
      );

      expect(projection.derivedStatus, 'received');
      expect(projection.queuedCount, 0);
      expect(projection.sentCount, 0);
      expect(projection.failedCount, 0);
    });

    test('HistoryDetailProjection.derivedStatus calculates outbound status correctly', () {
      const outboundEntry = HistoryEntry(
        id: 'outbound-entry-1',
        originalId: 'orig-2',
        tenantId: 'default',
        channelType: 'sms',
        messageBody: 'Outbound broadcast',
        status: 'sent',
        direction: 'outbound',
        totalRecipients: 3,
        successCount: 2,
        failedCount: 1,
        createdAt: 1700000000,
        phoneNumber: '+967771234567',
      );

      final projection = HistoryDetailProjection(
        entry: outboundEntry,
        recipients: const [
          RecipientDetail(name: 'A', phone: '+1', status: 'sent'),
          RecipientDetail(name: 'B', phone: '+2', status: 'sent'),
          RecipientDetail(name: 'C', phone: '+3', status: 'failed'),
        ],
      );

      expect(projection.derivedStatus, 'partial');
      expect(projection.sentCount, 2);
      expect(projection.failedCount, 1);
      expect(projection.queuedCount, 0);
    });
  });
}
