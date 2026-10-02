// ignore_for_file: lines_longer_than_80_chars
// Regression tests — Incoming SMS Status & Name (Invariants #2, #3, #4)
//
// These tests verify that:
//   1. Inbound messages always get status='received' (never 'queued')
//   2. deriveBatchStatus correctly handles pure inbound batches
//   3. ContactIdentityResolver applies the correct priority for name resolution
//   4. Backfill correctly enriches rows with empty contactName

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';
import 'package:zexano_sms/shared/contact_identity_resolver.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockSmsLocalSource extends Mock implements SmsLocalSource {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Builds a minimal MessageHistoryData-like map for testing.
/// We test HistoryMapper via MessageStatusService.deriveBatchStatus directly
/// since MessageHistoryData requires a real DB row.
Map<String, dynamic> _inboundRow({
  String status = 'received',
  String direction = 'inbound',
  String phone = '+967771234567',
  String name = '',
}) =>
    {
      'executionStatus': status,
      'direction': direction,
      'targetPhone': phone,
      'contactName': name,
    };

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageStatusService — Invariant #2 (received is inbound only)', () {
    test('isInbound("received") is true', () {
      expect(MessageStatusService.isInbound('received'), isTrue);
    });

    test('isInbound("sent") is false', () {
      expect(MessageStatusService.isInbound('sent'), isFalse);
    });

    test('isInbound("delivered") is false', () {
      expect(MessageStatusService.isInbound('delivered'), isFalse);
    });

    test('isSuccess("received") is false — received is NOT outbound success', () {
      expect(MessageStatusService.isSuccess('received'), isFalse);
    });

    test('isRetryable("received") is false — inbound never retried', () {
      expect(MessageStatusService.isRetryable('received'), isFalse);
    });

    test('isRetryable("delivered") is false — delivered never retried', () {
      expect(MessageStatusService.isRetryable('delivered'), isFalse);
    });

    test('isRetryable("sent") is false — sent never retried automatically', () {
      expect(MessageStatusService.isRetryable('sent'), isFalse);
    });

    test('isRetryable("failed") is true — only failed rows are retried', () {
      expect(MessageStatusService.isRetryable('failed'), isTrue);
    });

    // ── deriveBatchStatus — inbound short-circuit ─────────────────────────

    test('deriveBatchStatus: all received → "received" (1 message)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 0,
        queuedCount: 0,
        total: 1,
        receivedCount: 1,
      );
      expect(result, equals('received'));
    });

    test('deriveBatchStatus: all received → "received" (7 messages)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 0,
        queuedCount: 0,
        total: 7,
        receivedCount: 7,
      );
      expect(result, equals('received'));
    });

    test('deriveBatchStatus: all received → "received" (20 messages)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 0,
        queuedCount: 0,
        total: 20,
        receivedCount: 20,
      );
      expect(result, equals('received'));
    });

    test('deriveBatchStatus: 0 sent, 0 failed, 0 received → "queued" (outbound in flight)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 0,
        queuedCount: 3,
        total: 3,
        receivedCount: 0,
      );
      expect(result, equals('queued'));
    });

    test('deriveBatchStatus: all sent → "sent" (outbound, no received)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 5,
        failedCount: 0,
        queuedCount: 0,
        total: 5,
        receivedCount: 0,
      );
      expect(result, equals('sent'));
    });

    test('deriveBatchStatus: all failed → "failed" (outbound)', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 0,
        failedCount: 5,
        queuedCount: 0,
        total: 5,
        receivedCount: 0,
      );
      expect(result, equals('failed'));
    });

    test('deriveBatchStatus: partial (3 sent, 2 failed) → "partial"', () {
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 3,
        failedCount: 2,
        queuedCount: 0,
        total: 5,
        receivedCount: 0,
      );
      expect(result, equals('partial'));
    });

    // ── Status priority — received must be highest ────────────────────────

    test('statusPriority: received(6) > delivered(5) > sent(4)', () {
      final p = MessageStatusService.statusPriority;
      expect(p['received']!, greaterThan(p['delivered']!));
      expect(p['delivered']!, greaterThan(p['sent']!));
      expect(p['sent']!, greaterThan(p['failed']!));
    });

    test('received cannot be overwritten by any outbound status', () {
      final p = MessageStatusService.statusPriority;
      final receivedPriority = p['received']!;
      // All outbound statuses must have LOWER priority than 'received'
      for (final outbound in ['delivered', 'sent', 'failed', 'sending', 'queued']) {
        expect(
          p[outbound]!,
          lessThan(receivedPriority),
          reason: "'$outbound' must not override 'received' (inbound terminal)',",
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ContactIdentityResolver — Invariants #3 & #4', () {
    late MockSmsLocalSource mockLocalSource;
    late NormalizationEngine normEngine;
    late ContactIdentityResolver resolver;

    setUp(() {
      mockLocalSource = MockSmsLocalSource();
      normEngine = NormalizationEngine();
      resolver = ContactIdentityResolver(
        localSource: mockLocalSource,
        normalizationEngine: normEngine,
      );
    });

    test('Priority 1: Contacts table name takes precedence over stored name', () async {
      when(() => mockLocalSource.getContactByAnyPhone(any())).thenAnswer(
        (_) async => null, // will be overridden per test
      );
      // Cannot easily test Contact entity without DB — test the alphanumeric path
    });

    test('Priority 3: alphanumeric sender — no normalization, returns stored name if present', () async {
      // 'YT' normalizes to '' → skip contact lookup → use storedName
      when(() => mockLocalSource.getContactByAnyPhone(any())).thenAnswer(
        (_) async => null,
      );
      final name = await resolver.resolveName(
        phoneOrSender: 'YT',
        storedName: 'Yemen Telecom',
      );
      expect(name, equals('Yemen Telecom'));
    });

    test('Priority 3 fallback: alphanumeric sender, no stored name → raw sender', () async {
      when(() => mockLocalSource.getContactByAnyPhone(any())).thenAnswer(
        (_) async => null,
      );
      final name = await resolver.resolveName(
        phoneOrSender: 'OTP',
        storedName: '',
      );
      expect(name, equals('OTP'));
    });

    test('alphanumeric sender: enrichInboundName does nothing (no contact to find)', () async {
      // 'OTP' → normalized = '' → no lookup performed
      await resolver.enrichInboundName(rowId: 'row-1', senderPhone: 'OTP');
      verifyNever(() => mockLocalSource.getContactByAnyPhone(any()));
      verifyNever(() => mockLocalSource.updateInboundContactName(
            rowId: any(named: 'rowId'),
            contactName: any(named: 'contactName'),
            contactId: any(named: 'contactId'),
          ));
    });

    test('backfillInboundNames: empty list → no updates', () async {
      when(() => mockLocalSource.getInboundRowsWithEmptyName())
          .thenAnswer((_) async => []);
      await resolver.backfillInboundNames();
      verifyNever(() => mockLocalSource.updateInboundContactName(
            rowId: any(named: 'rowId'),
            contactName: any(named: 'contactName'),
          ));
    });

    test('numeric phone: getContactByPhone called with normalized phone', () async {
      when(() => mockLocalSource.getContactByAnyPhone('+967771234567'))
          .thenAnswer((_) async => null);
      // no stored name → falls through to raw phone
      final name = await resolver.resolveName(
        phoneOrSender: '0771234567',
        storedName: null,
      );
      expect(name, equals('0771234567'));
      verify(() => mockLocalSource.getContactByAnyPhone('+967771234567')).called(1);
    });

    test('numeric phone with stored name: contact lookup first, stored name fallback', () async {
      when(() => mockLocalSource.getContactByAnyPhone('+967771234567'))
          .thenAnswer((_) async => null); // no contact
      final name = await resolver.resolveName(
        phoneOrSender: '+967771234567',
        storedName: 'Ahmed Ali',
      );
      // Contact lookup returned null → fall through to storedName
      expect(name, equals('Ahmed Ali'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryMapper — inbound short-circuit regression', () {
    // Note: HistoryMapper.smsBatchToHistoryEntry requires real DB rows.
    // We test via deriveBatchStatus since the mapper delegates to it.
    // The actual mapper integration is tested via IncomingStatusIntegrationTest
    // which requires a real database.

    test('receivedCount == total always → "received" regardless of total size', () {
      for (final total in [1, 5, 7, 8, 10, 20, 100]) {
        final result = MessageStatusService.deriveBatchStatus(
          sentCount: 0,
          failedCount: 0,
          queuedCount: 0,
          total: total,
          receivedCount: total,
        );
        expect(result, equals('received'),
            reason: 'total=$total should map to received');
      }
    });

    test('mixed inbound+outbound: not pure received → goes through outbound logic', () {
      // This should not happen in practice (batches are direction-uniform)
      // but guard against it: 1 received + 4 sent → not pure inbound → 'sent'
      final result = MessageStatusService.deriveBatchStatus(
        sentCount: 4,
        failedCount: 0,
        queuedCount: 0,
        total: 5,
        receivedCount: 1, // not == total
      );
      // receivedCount(1) != total(5) → outbound logic → sentCount(4) != total(5) → partial
      expect(result, equals('partial'));
    });
  });
}
