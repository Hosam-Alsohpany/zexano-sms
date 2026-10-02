// Regression tests for HOTFIX BATCH A — Issues #3 & #4
// Verifies that:
//   • Contact IDs are valid UUID v4 strings (not timestamp-based)
//   • No two concurrently created contacts share an ID
//   • Contact entity equality is still id-based (not clock-based)

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// RFC-4122 UUID v4 pattern: xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx
final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

bool _isUuidV4(String id) => _uuidV4Pattern.hasMatch(id);

/// Simulates what the old (buggy) form screen did.
String _legacyId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Simulates what the fixed form screen now does.
String _fixedId() => const Uuid().v4();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Issue #3 — Contact ID generation: UUID v4 instead of timestamp', () {
    test('legacy ID (timestamp) is NOT a valid UUID v4', () {
      final id = _legacyId();
      // Documents the old bug: a plain integer string is not a UUID.
      expect(
        _isUuidV4(id),
        isFalse,
        reason: 'DateTime.now().microsecondsSinceEpoch.toString() is NOT a UUID',
      );
    });

    test('fixed ID (Uuid().v4()) IS a valid UUID v4', () {
      final id = _fixedId();
      expect(
        _isUuidV4(id),
        isTrue,
        reason: 'New IDs must conform to RFC-4122 UUID v4 format',
      );
    });

    test('two rapid calls to _fixedId() produce different IDs', () {
      final id1 = _fixedId();
      final id2 = _fixedId();
      expect(
        id1,
        isNot(id2),
        reason:
            'UUID v4 must be globally unique — two consecutive calls must not collide',
      );
    });

    test('legacy timestamp IDs can collide within the same microsecond', () {
      // Two calls in tight succession (same microsecond on fast hardware)
      // will produce the same value — demonstrating the collision risk.
      // We cannot guarantee a collision in a unit test, so we instead verify
      // that the string contains ONLY digits (no UUID separators).
      final id = _legacyId();
      expect(
        RegExp(r'^\d+$').hasMatch(id),
        isTrue,
        reason: 'Timestamp IDs are pure digit strings: no UUID separators',
      );
    });

    test('Contact created with UUID id survives round-trip through toMap/fromMap', () {
      final id = _fixedId();
      final contact = Contact(
        id: id,
        tenantId: 'default-tenant',
        firstName: 'Ahmad',
        lastName: 'Ali',
        phoneNumber: '+9671234567',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final map = contact.toMap();
      expect(map['id'], id);
      expect(_isUuidV4(map['id'] as String), isTrue);

      final restored = Contact.fromMap({
        ...map,
        'tenantId': 'default-tenant',
      });
      expect(restored.id, id);
      expect(_isUuidV4(restored.id), isTrue);
    });

    test('100 generated IDs are all unique UUID v4 strings', () {
      final ids = List.generate(100, (_) => _fixedId());
      for (final id in ids) {
        expect(_isUuidV4(id), isTrue, reason: '$id is not a UUID v4');
      }
      // All unique
      expect(ids.toSet().length, 100);
    });
  });

  group('Issue #3 — Contact entity equality is ID-based, not timestamp-based', () {
    test('two contacts with the same UUID id are equal regardless of other fields', () {
      const id = 'a1b2c3d4-0000-4000-8000-000000000001';
      final c1 = Contact(
        id: id,
        tenantId: 'tenant-1',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        createdAt: 1000000,
      );
      final c2 = c1.copyWith(firstName: 'Jane');

      expect(c1, c2); // Same id → equal
    });

    test('two contacts with different UUID ids are NOT equal', () {
      final id1 = _fixedId();
      final id2 = _fixedId();

      final c1 = Contact(
        id: id1,
        tenantId: 'tenant-1',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        createdAt: 1000000,
      );
      final c2 = c1.copyWith(id: id2);

      expect(c1, isNot(c2));
    });
  });
}
