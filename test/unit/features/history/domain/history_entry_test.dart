import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';

void main() {
  group('HistoryEntry', () {
    const baseEntry = HistoryEntry(
      id: 'hist-1',
      originalId: 'msg-1',
      tenantId: 'tenant-1',
      channelType: 'sms',
      messageBody: 'Hello',
      status: 'queued',
      totalRecipients: 10,
      successCount: 5,
      failedCount: 2,
      createdAt: 1000000,
      contactName: 'John',
      phoneNumber: '+1234567890',
    );

    test('isCompleted returns true for completed status', () {
      expect(baseEntry.isCompleted, isFalse);
      expect(
        baseEntry.copyWith(status: 'completed').isCompleted,
        isTrue,
      );
    });

    test('isFailed returns true for failed status', () {
      expect(
        baseEntry.copyWith(status: 'failed').isFailed,
        isTrue,
      );
    });

    test('isPartial returns true for partial status', () {
      expect(
        baseEntry.copyWith(status: 'partial').isPartial,
        isTrue,
      );
    });

    test('allDone returns true when success+failed >= total', () {
      expect(baseEntry.allDone, isFalse);
      final done = baseEntry.copyWith(
        successCount: 8,
        failedCount: 2,
      );
      expect(done.allDone, isTrue);
    });

    test('copyWith updates specified fields', () {
      final updated = baseEntry.copyWith(
        status: 'completed',
        completedAt: 2000000,
      );
      expect(updated.status, 'completed');
      expect(updated.completedAt, 2000000);
      expect(updated.messageBody, baseEntry.messageBody);
    });

    test('copyWith clearCompletedAt works', () {
      final withTime = baseEntry.copyWith(completedAt: 2000000);
      expect(withTime.completedAt, 2000000);
      final cleared = withTime.copyWith(clearCompletedAt: true);
      expect(cleared.completedAt, isNull);
    });

    test('copyWith clearContactName works', () {
      final cleared = baseEntry.copyWith(clearContactName: true);
      expect(cleared.contactName, isNull);
    });

    test('copyWith clearPhoneNumber works', () {
      final cleared = baseEntry.copyWith(clearPhoneNumber: true);
      expect(cleared.phoneNumber, isNull);
    });

    test('equality based on id', () {
      expect(baseEntry, baseEntry.copyWith(status: 'failed'));
      expect(baseEntry, isNot(baseEntry.copyWith(id: 'other')));
    });

    test('toString contains key fields', () {
      final str = baseEntry.toString();
      expect(str, contains('hist-1'));
      // toString now shows direction, source and success/total — not channelType.
      expect(str, contains('outbound'));
      expect(str, contains('5/10'));
    });
  });
}
