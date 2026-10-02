import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

void main() {
  const baseContact = Contact(
    id: 'contact-1',
    tenantId: 'tenant-1',
    firstName: 'John',
    lastName: 'Doe',
    phoneNumber: '+1234567890',
    normalizedPhone: '1234567890',
    operatorName: 'Test Mobile',
    notes: 'A note',
    isFavorite: false,
    createdAt: 1000000,
    tagIds: {'tag-1'},
  );

  group('Contact', () {
    test('fullName combines first and last name', () {
      expect(baseContact.fullName, 'John Doe');
    });

    test('fullName returns phone when both names are empty', () {
      final noName = baseContact.copyWith(firstName: '', lastName: '');
      expect(noName.fullName, baseContact.phoneNumber);
    });

    test('fullName returns lastName when firstName is empty', () {
      final noFirst = baseContact.copyWith(firstName: '');
      expect(noFirst.fullName, 'Doe');
    });

    test('initials returns first letters uppercased', () {
      expect(baseContact.initials, 'JD');
    });

    test('initials returns ? when both names empty', () {
      final noName = baseContact.copyWith(firstName: '', lastName: '');
      expect(noName.initials, '?');
    });

    test('copyWith preserves unchanged fields', () {
      final copied = baseContact.copyWith(firstName: 'Jane');
      expect(copied.id, baseContact.id);
      expect(copied.lastName, baseContact.lastName);
      expect(copied.firstName, 'Jane');
    });

    test('copyWith with no args returns equal object', () {
      expect(baseContact.copyWith(), baseContact);
    });

    test('toMap serializes all fields', () {
      final map = baseContact.toMap();
      expect(map['id'], 'contact-1');
      expect(map['firstName'], 'John');
      expect(map['lastName'], 'Doe');
      expect(map['phoneNumber'], '+1234567890');
      expect(map['normalizedPhone'], '1234567890');
      expect(map['isFavorite'], 0);
      expect(map['createdAt'], 1000000);
    });

    test('fromMap deserializes correctly', () {
      final contact = Contact.fromMap({
        'id': 'contact-2',
        'tenantId': 'tenant-1',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'phoneNumber': '+9876543210',
        'normalizedPhone': '9876543210',
        'operatorName': 'Other Mobile',
        'notes': 'Another note',
        'isFavorite': 1,
        'createdAt': 2000000,
      });
      expect(contact.id, 'contact-2');
      expect(contact.fullName, 'Jane Smith');
      expect(contact.isFavorite, isTrue);
    });

    test('fromMap handles null fields', () {
      final contact = Contact.fromMap({
        'id': 'contact-3',
        'tenantId': 'tenant-1',
        'firstName': null,
        'lastName': null,
        'phoneNumber': null,
        'createdAt': null,
      });
      expect(contact.firstName, '');
      expect(contact.createdAt, 0);
    });

    test('equality based on id only', () {
      expect(
        baseContact,
        baseContact.copyWith(firstName: 'Different'),
      );
      expect(
        baseContact,
        isNot(baseContact.copyWith(id: 'different-id')),
      );
    });

    test('toString contains id and fullName', () {
      final str = baseContact.toString();
      expect(str, contains('contact-1'));
      expect(str, contains('John Doe'));
    });
  });
}
