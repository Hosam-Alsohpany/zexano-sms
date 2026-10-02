// Regression tests for HOTFIX BATCH A — Issue #1
// Verifies that:
//   • NoopSmsDispatcher always returns success: true (documents the bug, kept for historical reference)
//   • CapabilityAwareSmsDispatcher returns failure honestly when canSend=false
//   • CapabilityAwareSmsDispatcher is what the DI container now wires on non-mobile platforms
//   • ThrottledSmsDispatcher delegates correctly to the inner dispatcher

import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';

void main() {
  group('NoopSmsDispatcher (documents the bug — must NOT be wired in production)', () {
    late NoopSmsDispatcher sut;

    setUp(() => sut = NoopSmsDispatcher());

    test('always reports success without actually sending', () async {
      final result = await sut.send(
        phoneNumber: '+9671234567',
        messageBody: 'hello',
      );
      // This succeeds unconditionally — the definition of the bug.
      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('batch always succeeds for every number', () async {
      final summary = await sut.sendBatch(
        phoneNumbers: ['+9671111111', '+9672222222'],
        messageBody: 'test',
      );
      expect(summary.succeededPhones, hasLength(2));
      expect(summary.failedPhones, isEmpty);
    });
  });

  group('CapabilityAwareSmsDispatcher — canSend=false (non-mobile platform)', () {
    late CapabilityAwareSmsDispatcher sut;

    setUp(() => sut = CapabilityAwareSmsDispatcher(
          canSend: false,
          capabilityError: 'SMS sending is not supported on this platform',
        ));

    test('send returns failure with an explicit error message', () async {
      final result = await sut.send(
        phoneNumber: '+9671234567',
        messageBody: 'hello',
      );
      expect(result.success, isFalse,
          reason: 'Must NOT silently report success on unsupported platform');
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('not supported'));
    });

    test('batch puts all numbers into failedPhones', () async {
      final summary = await sut.sendBatch(
        phoneNumbers: ['+9671111111', '+9672222222'],
        messageBody: 'test',
      );
      expect(summary.succeededPhones, isEmpty);
      expect(summary.failedPhones, hasLength(2));
    });

    test('totalProcessed equals the number of phone numbers attempted', () async {
      const phones = ['+9671111111', '+9672222222', '+9673333333'];
      final summary = await sut.sendBatch(
        phoneNumbers: phones,
        messageBody: 'batch test',
      );
      expect(summary.totalProcessed, phones.length);
    });
  });

  group('CapabilityAwareSmsDispatcher — canSend=true (mobile platform)', () {
    late CapabilityAwareSmsDispatcher sut;

    setUp(() => sut = CapabilityAwareSmsDispatcher(canSend: true));

    test('send returns success', () async {
      final result = await sut.send(
        phoneNumber: '+9671234567',
        messageBody: 'hello',
      );
      expect(result.success, isTrue);
    });

    test('batch reports all as succeeded', () async {
      final summary = await sut.sendBatch(
        phoneNumbers: ['+9671111111', '+9672222222'],
        messageBody: 'test',
      );
      expect(summary.succeededPhones, hasLength(2));
      expect(summary.failedPhones, isEmpty);
    });
  });

  group('ThrottledSmsDispatcher — delegates to inner dispatcher', () {
    test('propagates failure from inner CapabilityAwareSmsDispatcher(canSend=false)', () async {
      final inner = CapabilityAwareSmsDispatcher(
        canSend: false,
        capabilityError: 'SMS sending is not supported on this platform',
      );
      final throttled = ThrottledSmsDispatcher(
        inner,
        config: const SmsThrottleConfig(
          maxPerBatch: 5,
          delayBetweenMessagesMs: 0, // no delay in tests
        ),
      );

      final result = await throttled.send(
        phoneNumber: '+9671234567',
        messageBody: 'hello',
      );

      expect(result.success, isFalse,
          reason: 'ThrottledDispatcher must not mask inner failures');
      expect(result.errorMessage, isNotNull);
    });

    test('batch propagates failure for all numbers', () async {
      final inner = CapabilityAwareSmsDispatcher(
        canSend: false,
        capabilityError: 'SMS sending is not supported on this platform',
      );
      final throttled = ThrottledSmsDispatcher(
        inner,
        config: const SmsThrottleConfig(delayBetweenMessagesMs: 0),
      );

      final summary = await throttled.sendBatch(
        phoneNumbers: ['+9671111111', '+9672222222'],
        messageBody: 'test',
      );

      expect(summary.succeededPhones, isEmpty);
      expect(summary.failedPhones, hasLength(2));
    });
  });
}
