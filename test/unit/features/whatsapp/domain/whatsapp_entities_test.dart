import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/whatsapp_app.dart';

void main() {
  group('WhatsAppApp', () {
    test('copyWith updates fields', () {
      final app = const WhatsAppApp(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isInstalled: false,
      );
      final installed = app.copyWith(isInstalled: true);
      expect(installed.packageName, 'com.whatsapp');
      expect(installed.isInstalled, isTrue);
    });

    test('equality based on packageName', () {
      expect(
        const WhatsAppApp(packageName: 'com.whatsapp', appName: 'WA'),
        const WhatsAppApp(packageName: 'com.whatsapp', appName: 'Different'),
      );
      expect(
        const WhatsAppApp(packageName: 'com.whatsapp', appName: 'WA'),
        isNot(
          const WhatsAppApp(packageName: 'com.whatsapp.business', appName: 'WA'),
        ),
      );
    });

    test('toString contains appName and installed status', () {
      final app = const WhatsAppApp(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isInstalled: true,
      );
      expect(app.toString(), contains('WhatsApp'));
      expect(app.toString(), contains('true'));
    });
  });

  group('AssistedSession', () {
    const baseSession = AssistedSession(
      sessionId: 'session-1',
      messageBody: 'Hello',
      totalRecipients: 10,
      completedRecipients: 4,
      failedRecipients: 1,
      currentIndex: 5,
      status: 'in_progress',
      createdAt: 1000000,
    );

    test('isCompleted returns true when status is completed', () {
      expect(baseSession.isCompleted, isFalse);
      expect(
        baseSession.copyWith(status: 'completed').isCompleted,
        isTrue,
      );
    });

    test('isCancelled returns true when status is cancelled', () {
      expect(baseSession.isCancelled, isFalse);
      expect(
        baseSession.copyWith(status: 'cancelled').isCancelled,
        isTrue,
      );
    });

    test('isInProgress returns true when status is in_progress', () {
      expect(baseSession.isInProgress, isTrue);
    });

    test('allDone returns true when progress >= total', () {
      expect(baseSession.allDone, isFalse);
      final done = baseSession.copyWith(
        completedRecipients: 9,
        failedRecipients: 1,
      );
      expect(done.allDone, isTrue);
    });

    test('copyWith updates specified fields', () {
      final updated = baseSession.copyWith(
        completedRecipients: 10,
        status: 'completed',
      );
      expect(updated.completedRecipients, 10);
      expect(updated.totalRecipients, baseSession.totalRecipients);
    });

    test('copyWith handles clearCompletedAt', () {
      final withTime = baseSession.copyWith(completedAt: 3000000);
      expect(withTime.completedAt, 3000000);
      final cleared = withTime.copyWith(clearCompletedAt: true);
      expect(cleared.completedAt, isNull);
    });

    test('equality based on sessionId', () {
      expect(baseSession, baseSession.copyWith(status: 'failed'));
      expect(baseSession, isNot(baseSession.copyWith(sessionId: 'other')));
    });

    test('toString contains key fields', () {
      final str = baseSession.toString();
      expect(str, contains('session-1'));
      expect(str, contains('in_progress'));
      expect(str, contains('4/10'));
    });
  });

  group('StagedRecipient', () {
    const baseRecipient = StagedRecipient(
      id: 'recip-1',
      sessionId: 'session-1',
      phoneNumber: '+1234567890',
      contactName: 'John Doe',
      contactId: 'contact-1',
      status: 'pending',
      launchSuccess: false,
      attemptedAt: null,
    );

    test('status helpers return correct values', () {
      expect(baseRecipient.isPending, isTrue);
      expect(baseRecipient.isLaunched, isFalse);
      expect(baseRecipient.isFailed, isFalse);
      expect(baseRecipient.isSkipped, isFalse);

      final launched = baseRecipient.copyWith(status: 'launched');
      expect(launched.isLaunched, isTrue);

      final failed = baseRecipient.copyWith(status: 'failed');
      expect(failed.isFailed, isTrue);

      final skipped = baseRecipient.copyWith(status: 'skipped');
      expect(skipped.isSkipped, isTrue);
    });

    test('copyWith updates fields', () {
      final updated = baseRecipient.copyWith(
        status: 'launched',
        launchSuccess: true,
      );
      expect(updated.status, 'launched');
      expect(updated.launchSuccess, isTrue);
    });

    test('copyWith clearContactId works', () {
      final cleared = baseRecipient.copyWith(clearContactId: true);
      expect(cleared.contactId, isNull);
    });

    test('equality based on id', () {
      expect(baseRecipient, baseRecipient.copyWith(status: 'launched'));
      expect(baseRecipient, isNot(baseRecipient.copyWith(id: 'other')));
    });

    test('toString contains phone and status', () {
      final str = baseRecipient.toString();
      expect(str, contains('+1234567890'));
      expect(str, contains('pending'));
    });
  });
}
