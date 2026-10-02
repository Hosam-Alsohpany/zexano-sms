import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';

void main() {
  group('SmsMessage', () {
    const baseMsg = SmsMessage(
      id: 'msg-1',
      tenantId: 'tenant-1',
      messageBody: 'Hello World',
      channelType: 'sms',
      status: 'queued',
      totalRecipients: 10,
      sentCount: 5,
      failedCount: 2,
      createdAt: 1000000,
      sentAt: 2000000,
    );

    test('copyWith updates specified fields', () {
      final sent = baseMsg.copyWith(status: 'sent');
      expect(sent.status, 'sent');
      expect(sent.messageBody, baseMsg.messageBody);
    });

    test('copyWith handles clearSentAt', () {
      final cleared = baseMsg.copyWith(clearSentAt: true);
      expect(cleared.sentAt, isNull);
    });

    test('toMap serializes all fields', () {
      final map = baseMsg.toMap();
      expect(map['id'], 'msg-1');
      expect(map['messageBody'], 'Hello World');
      expect(map['status'], 'queued');
      expect(map['sentCount'], 5);
      expect(map['failedCount'], 2);
      expect(map['sentAt'], 2000000);
    });

    test('fromMap deserializes correctly', () {
      final msg = SmsMessage.fromMap({
        'id': 'msg-2',
        'tenantId': 'tenant-1',
        'messageBody': 'Test',
        'createdAt': 3000000,
      });
      expect(msg.id, 'msg-2');
      expect(msg.messageBody, 'Test');
      expect(msg.status, 'queued');
      expect(msg.sentAt, isNull);
    });

    test('equality based on id', () {
      expect(baseMsg, baseMsg.copyWith(status: 'failed'));
      expect(baseMsg, isNot(baseMsg.copyWith(id: 'other')));
    });

    test('toString contains key fields', () {
      final str = baseMsg.toString();
      expect(str, contains('msg-1'));
      expect(str, contains('queued'));
      expect(str, contains('5/10'));
    });
  });
}
