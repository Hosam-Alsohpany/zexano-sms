import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/backup/data/services/integrity_service.dart';

void main() {
  late IntegrityService service;

  setUp(() {
    service = IntegrityService();
  });

  group('IntegrityService', () {
    test('computeChecksum returns consistent hash for same input', () {
      const content = 'test-data';
      expect(
        service.computeChecksum(content),
        service.computeChecksum(content),
      );
    });

    test('computeChecksum returns different hash for different input', () {
      expect(
        service.computeChecksum('data-a'),
        isNot(service.computeChecksum('data-b')),
      );
    });

    test('verifyChecksum returns true for matching checksum', () {
      const content = 'verify-me';
      final checksum = service.computeChecksum(content);
      expect(service.verifyChecksum(content, checksum), isTrue);
    });

    test('verifyChecksum returns false for mismatched checksum', () {
      expect(
        service.verifyChecksum('content', 'wrong-checksum'),
        isFalse,
      );
    });

    test('computeFileChecksum returns consistent hash for same bytes', () {
      final bytes = utf8.encode('file-content');
      expect(
        service.computeFileChecksum(bytes),
        service.computeFileChecksum(bytes),
      );
    });

    test('verifyFileChecksum validates correctly', () {
      final bytes = utf8.encode('file-data');
      final checksum = service.computeFileChecksum(bytes);
      expect(service.verifyFileChecksum(bytes, checksum), isTrue);
      expect(service.verifyFileChecksum(bytes, 'bad'), isFalse);
    });

    test('isSchemaVersionCompatible accepts version 1', () {
      expect(service.isSchemaVersionCompatible(1), isTrue);
    });

    test('isSchemaVersionCompatible rejects version 0', () {
      expect(service.isSchemaVersionCompatible(0), isFalse);
    });

    test('isSchemaVersionCompatible rejects future versions', () {
      expect(service.isSchemaVersionCompatible(999), isFalse);
    });

    test('currentSchemaVersion is 1', () {
      expect(service.currentSchemaVersion, 1);
    });
  });
}
