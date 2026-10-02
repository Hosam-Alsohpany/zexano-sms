import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/shared/contact_identity_resolver.dart';

class MockSmsLocalSource extends Mock implements SmsLocalSource {}

void main() {
  group('Unified Identity Resolution Contract Tests', () {
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

    test('Priority 1: Contact table matches company name for phone number (with or without peerId prefix)', () async {
      const companyContact = db.Contact(
        id: 'c-1',
        tenantId: 'default-tenant',
        firstName: 'شركة الشملان',
        lastName: '',
        phoneNumber: '771234567',
        normalizedPhone: '+967771234567',
        operatorName: 'YemenMobile',
        notes: '',
        isFavorite: 0,
        createdAt: 1000,
      );

      when(() => mockLocalSource.getContactByAnyPhone('+967771234567'))
          .thenAnswer((_) async => companyContact);

      // Raw phone
      final nameFromPhone = await resolver.resolveName(
        phoneOrSender: '771234567',
        storedName: '',
      );
      expect(nameFromPhone, equals('شركة الشملان'));

      // peerId formatted
      final nameFromPeerId = await resolver.resolveName(
        phoneOrSender: 'sms:+967771234567',
        storedName: '',
      );
      expect(nameFromPeerId, equals('شركة الشملان'));
    });

    test('Short code (6060 / 8000) resolves to stored name if available, or clean short code fallback', () async {
      when(() => mockLocalSource.getContactByAnyPhone('6060'))
          .thenAnswer((_) async => null);

      // With stored name
      final nameWithStored = await resolver.resolveName(
        phoneOrSender: 'sms:6060',
        storedName: 'خدمة العملاء 6060',
      );
      expect(nameWithStored, equals('خدمة العملاء 6060'));

      // Without stored name
      final rawShortCode = await resolver.resolveName(
        phoneOrSender: 'sms:6060',
        storedName: '',
      );
      expect(rawShortCode, equals('6060'));
    });

    test('Alphanumeric Sender ID (SABAFON / ZEXANO) resolves to stored name or sender ID', () async {
      when(() => mockLocalSource.getContactByAnyPhone('SABAFON'))
          .thenAnswer((_) async => null);

      // Raw sender ID
      final rawSender = await resolver.resolveName(
        phoneOrSender: 'SABAFON',
        storedName: '',
      );
      expect(rawSender, equals('SABAFON'));

      // From peerId
      final peerSender = await resolver.resolveName(
        phoneOrSender: 'sms:SABAFON',
        storedName: 'سبأفون الرسمية',
      );
      expect(peerSender, equals('سبأفون الرسمية'));
    });

    test('Unknown phone number returns clean raw phone fallback', () async {
      when(() => mockLocalSource.getContactByAnyPhone(any()))
          .thenAnswer((_) async => null);

      final name = await resolver.resolveName(
        phoneOrSender: '+967770999999',
        storedName: '',
      );
      expect(name, equals('+967770999999'));

      final fromPeer = await resolver.resolveName(
        phoneOrSender: 'sms:+967770999999',
        storedName: '',
      );
      expect(fromPeer, equals('+967770999999'));
    });
  });
}
