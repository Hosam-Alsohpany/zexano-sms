import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_contacts/properties/name.dart' as fcp;
import 'package:flutter_contacts/properties/phone.dart' as fpp;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/features/contacts/data/handlers/device_contacts_handler.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

void main() {
  late DeviceContactsHandler handler;

  setUp(() {
    handler = DeviceContactsHandler(uuid: const Uuid());
  });

  group('DeviceContactsHandler Contact Name Import & Unicode Fidelity', () {
    test('Regression test: عمتي حن🤍, عمتي مد🤍, عمتي نس🤍 preserve full names', () {
      // Simulating what Android Contacts Provider returns:
      // displayName holds the unparsed full name.
      // StructuredName may split it arbitrarily (e.g. middle_name for حن🤍 and مد🤍).
      final contact1 = fc.Contact(
        id: 'id-1',
        displayName: 'عمتي حن🤍',
        name: fcp.Name(first: 'عمتي', middle: 'حن🤍', last: ''),
        phones: [fpp.Phone('+967771111111')],
      );

      final contact2 = fc.Contact(
        id: 'id-2',
        displayName: 'عمتي مد🤍',
        name: fcp.Name(first: 'عمتي', middle: 'مد🤍', last: ''),
        phones: [fpp.Phone('+967772222222')],
      );

      final contact3 = fc.Contact(
        id: 'id-3',
        displayName: 'عمتي نس🤍',
        name: fcp.Name(first: 'عمتي', middle: '', last: 'نس🤍'),
        phones: [fpp.Phone('+967773333333')],
      );

      // Verify mapping logic inside handler
      final appContacts = [contact1, contact2, contact3]
          .map(handler.mapToAppContact)
          .toList();

      expect(appContacts[0].fullName, equals('عمتي حن🤍'));
      expect(appContacts[0].phoneNumber, equals('+967771111111'));

      expect(appContacts[1].fullName, equals('عمتي مد🤍'));
      expect(appContacts[1].phoneNumber, equals('+967772222222'));

      expect(appContacts[2].fullName, equals('عمتي نس🤍'));
      expect(appContacts[2].phoneNumber, equals('+967773333333'));
    });

    test('Regression test: Multi-word Arabic names and emojis', () {
      final testCases = [
        ('محمد أحمد علي', '+967770000001'),
        ('محمد أحمد علي 🤍', '+967770000002'),
        ('عبدالله محمد أحمد', '+967770000003'),
        ('أحمد محمد 😊', '+967770000004'),
        ('محمد أحمد 👨💻', '+967770000005'),
        ('🤍 عمتي', '+967770000006'),
        ('😊 أحمد', '+967770000007'),
        ('محمد أحمد علي 🤍 😊', '+967770000008'),
      ];

      for (final (name, phone) in testCases) {
        final fcContact = fc.Contact(
          id: 'id-${name.hashCode}',
          displayName: name,
          name: fcp.Name(first: name),
          phones: [fpp.Phone(phone)],
        );

        final mapped = handler.mapToAppContact(fcContact);
        expect(mapped.fullName, equals(name), reason: 'Failed for name: $name');
        expect(mapped.phoneNumber, equals(phone));
      }
    });

    test('Fallback when displayName is empty combines all structured name parts', () {
      final fcContact = fc.Contact(
        id: 'id-empty-display',
        displayName: '',
        name: fcp.Name(
          prefix: 'دكتور',
          first: 'محمد',
          middle: 'أحمد',
          last: 'علي',
          suffix: 'حفظه الله',
        ),
        phones: [fpp.Phone('+967779999999')],
      );

      final mapped = handler.mapToAppContact(fcContact);
      expect(mapped.fullName, equals('دكتور محمد أحمد علي حفظه الله'));
      expect(mapped.phoneNumber, equals('+967779999999'));
    });

    test('Initials handling with leading emoji and Arabic characters does not crash or corrupt', () {
      final c1 = const Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'عمتي حن🤍',
        createdAt: 0,
      );
      expect(c1.initials, equals('ع'));

      final c2 = const Contact(
        id: '2',
        tenantId: 'default',
        firstName: '🤍 عمتي',
        createdAt: 0,
      );
      expect(c2.initials, equals('🤍'));

      final c3 = const Contact(
        id: '3',
        tenantId: 'default',
        firstName: '😊 أحمد',
        createdAt: 0,
      );
      expect(c3.initials, equals('😊'));

      final c4 = const Contact(
        id: '4',
        tenantId: 'default',
        firstName: 'محمد',
        lastName: 'علي',
        createdAt: 0,
      );
      expect(c4.initials, equals('مع'));
    });
  });
}
