// Regression tests for HOTFIX BATCH A — Issue #2
// Verifies that:
//   • NoopWhatsAppLauncher fabricates installed apps (documents the bug)
//   • CapabilityAwareWhatsAppLauncher returns canDetect=false / canLaunch=false
//     and an honest failure on platforms where WhatsApp is not launchable
//   • CapabilityAwareWhatsAppLauncher correctly succeeds when both flags are true

import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/whatsapp/data/launcher/whatsapp_launcher.dart';

void main() {
  group('NoopWhatsAppLauncher (documents the bug — must NOT be wired in production)', () {
    late NoopWhatsAppLauncher sut;

    setUp(() => sut = NoopWhatsAppLauncher());

    test('reports canDetectApps=true unconditionally', () {
      expect(sut.canDetectApps, isTrue);
    });

    test('reports canLaunch=true unconditionally', () {
      expect(sut.canLaunch, isTrue);
    });

    test('detectInstalledApps fabricates two apps regardless of reality', () async {
      final apps = await sut.detectInstalledApps();
      // These are fake — there may be no WhatsApp on the test machine.
      expect(apps, hasLength(2));
      expect(apps.any((a) => a.packageName == 'com.whatsapp'), isTrue);
    });

    test('launch always returns success without opening anything', () async {
      final result = await sut.launch(
        recipientId: 'r-1',
        phoneNumber: '+9671234567',
        messageBody: 'hello',
        packageName: 'com.whatsapp',
      );
      // This is fake success — the bug.
      expect(result.success, isTrue);
    });
  });

  group('CapabilityAwareWhatsAppLauncher — canDetect=false, canLaunch=false (non-mobile)', () {
    late CapabilityAwareWhatsAppLauncher sut;

    setUp(() => sut = CapabilityAwareWhatsAppLauncher(
          canDetect: false,
          canLaunch: false,
          capabilityError: 'WhatsApp launching is not supported on this platform',
        ));

    test('canDetectApps returns false', () {
      expect(sut.canDetectApps, isFalse);
    });

    test('canLaunch returns false', () {
      expect(sut.canLaunch, isFalse);
    });

    test('detectInstalledApps returns an empty list, not fabricated apps', () async {
      final apps = await sut.detectInstalledApps();
      expect(apps, isEmpty,
          reason: 'Must not fabricate WhatsApp presence on non-mobile platforms');
    });

    test('launch returns failure with a non-null failureReason', () async {
      final result = await sut.launch(
        recipientId: 'r-1',
        phoneNumber: '+9671234567',
        messageBody: 'hello',
        packageName: 'com.whatsapp',
      );
      expect(result.success, isFalse,
          reason: 'Must NOT silently return success when launch is impossible');
      expect(result.failureReason, isNotNull);
      expect(result.failureReason, contains('not supported'));
    });

    test('launch carries the original recipientId in the result', () async {
      final result = await sut.launch(
        recipientId: 'r-42',
        phoneNumber: '+9671234567',
        messageBody: 'hello',
        packageName: 'com.whatsapp',
      );
      expect(result.recipientId, 'r-42');
    });
  });

  group('CapabilityAwareWhatsAppLauncher — canDetect=true, canLaunch=true (mobile)', () {
    late CapabilityAwareWhatsAppLauncher sut;

    setUp(() => sut = CapabilityAwareWhatsAppLauncher(
          canDetect: true,
          canLaunch: true,
        ));

    test('canDetectApps returns true', () {
      expect(sut.canDetectApps, isTrue);
    });

    test('detectInstalledApps returns at least one app', () async {
      final apps = await sut.detectInstalledApps();
      expect(apps, isNotEmpty);
    });

    test('launch returns success', () async {
      final result = await sut.launch(
        recipientId: 'r-1',
        phoneNumber: '+9671234567',
        messageBody: 'hello',
        packageName: 'com.whatsapp',
      );
      expect(result.success, isTrue);
      expect(result.failureReason, isNull);
    });
  });

  group('CapabilityAwareWhatsAppLauncher — mixed capabilities', () {
    test('canDetect=true but canLaunch=false: detectInstalledApps works, launch fails', () async {
      final sut = CapabilityAwareWhatsAppLauncher(
        canDetect: true,
        canLaunch: false,
        capabilityError: 'Launch blocked',
      );
      final apps = await sut.detectInstalledApps();
      expect(apps, isNotEmpty);

      final result = await sut.launch(
        recipientId: 'r-2',
        phoneNumber: '+9671234567',
        messageBody: 'hi',
        packageName: 'com.whatsapp',
      );
      expect(result.success, isFalse);
      expect(result.failureReason, contains('blocked'));
    });
  });
}
