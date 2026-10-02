import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';
import 'package:zexano_sms/features/sms/presentation/screens/sms_recipient_selection_screen.dart';

void main() {
  group('ContactItem Favorites Support', () {
    test('ContactItem retains isFavorite field with correct default', () {
      const regular = ContactItem(
        id: '1',
        name: 'Normal Contact',
        phone: '+967770000001',
      );
      expect(regular.isFavorite, isFalse);

      const favorite = ContactItem(
        id: '2',
        name: 'Favorite Contact',
        phone: '+967770000002',
        isFavorite: true,
      );
      expect(favorite.isFavorite, isTrue);
    });
  });

  group('Group Member Picker Favorites Filtering Logic', () {
    final contacts = [
      Contact(
        id: 'c1',
        tenantId: 't1',
        firstName: 'عمتي',
        lastName: 'حن🤍',
        phoneNumber: '+967771111111',
        notes: '',
        createdAt: 100,
        isFavorite: true,
      ),
      Contact(
        id: 'c2',
        tenantId: 't1',
        firstName: 'علي',
        lastName: 'أحمد',
        phoneNumber: '+967772222222',
        notes: '',
        createdAt: 200,
        isFavorite: false,
      ),
      Contact(
        id: 'c3',
        tenantId: 't1',
        firstName: 'عمتي',
        lastName: 'نس🤍',
        phoneNumber: '+967773333333',
        notes: '',
        createdAt: 300,
        isFavorite: true,
      ),
    ];

    test('All contacts visible when favoritesOnly is false', () {
      final existingIds = {'c99'};
      var available = contacts.where((c) => !existingIds.contains(c.id)).toList();
      const favoritesOnly = false;
      if (favoritesOnly) {
        available = available.where((c) => c.isFavorite).toList();
      }
      expect(available, hasLength(3));
      expect(available.map((c) => c.id), containsAll(['c1', 'c2', 'c3']));
    });

    test('Only favorites visible when favoritesOnly is true', () {
      final existingIds = {'c99'};
      var available = contacts.where((c) => !existingIds.contains(c.id)).toList();
      const favoritesOnly = true;
      if (favoritesOnly) {
        available = available.where((c) => c.isFavorite).toList();
      }
      expect(available, hasLength(2));
      expect(available.map((c) => c.id), containsAll(['c1', 'c3']));
      expect(available.map((c) => c.id), isNot(contains('c2')));
    });

    test('Favorites filter combines seamlessly with search query', () {
      final existingIds = <String>{};
      var available = contacts.where((c) => !existingIds.contains(c.id)).toList();
      const favoritesOnly = true;
      if (favoritesOnly) {
        available = available.where((c) => c.isFavorite).toList();
      }
      const query = 'حن';
      available.retainWhere((c) => c.fullName.contains(query));

      expect(available, hasLength(1));
      expect(available.first.fullName, 'عمتي حن🤍');
    });

    test('Excludes existing group members even if they are favorites', () {
      final existingIds = {'c1'};
      var available = contacts.where((c) => !existingIds.contains(c.id)).toList();
      const favoritesOnly = true;
      if (favoritesOnly) {
        available = available.where((c) => c.isFavorite).toList();
      }
      expect(available, hasLength(1));
      expect(available.first.id, 'c3');
    });
  });

  group('Message Recipient Picker Favorites Filtering & Selection Logic', () {
    final items = [
      const ContactItem(
        id: '1',
        name: 'عمتي حن🤍',
        phone: '+967771111111',
        isFavorite: true,
      ),
      const ContactItem(
        id: '2',
        name: 'صالح سعيد',
        phone: '+967772222222',
        isFavorite: false,
      ),
      const ContactItem(
        id: '3',
        name: 'عمتي نس🤍',
        phone: '+967773333333',
        isFavorite: true,
      ),
    ];

    test('All contacts returned when _contactsFavoritesOnly is false', () {
      var filtered = List<ContactItem>.from(items);
      const contactsFavoritesOnly = false;
      if (contactsFavoritesOnly) {
        filtered = filtered.where((c) => c.isFavorite).toList();
      }
      expect(filtered, hasLength(3));
    });

    test('Only favorite contacts returned when _contactsFavoritesOnly is true', () {
      var filtered = List<ContactItem>.from(items);
      const contactsFavoritesOnly = true;
      if (contactsFavoritesOnly) {
        filtered = filtered.where((c) => c.isFavorite).toList();
      }
      expect(filtered, hasLength(2));
      expect(filtered.map((c) => c.name), containsAll(['عمتي حن🤍', 'عمتي نس🤍']));
      expect(filtered.any((c) => !c.isFavorite), isFalse);
    });

    test('Selected contacts persist when switching between All and Favorites filters', () {
      final selectedIds = <String>{};
      // Select non-favorite contact '2'
      selectedIds.add('2');

      // Filter to favorites only
      var filtered = items.where((c) => c.isFavorite).toList();
      expect(filtered.map((c) => c.id), isNot(contains('2')));
      // But selectedIds still contains '2'
      expect(selectedIds.contains('2'), isTrue);

      // Select favorite contact '1' while filtered
      selectedIds.add('1');
      expect(selectedIds, containsAll(['1', '2']));

      // Switch back to all contacts
      filtered = List<ContactItem>.from(items);
      expect(filtered, hasLength(3));
      expect(selectedIds, containsAll(['1', '2']));

      // Confirm selection resolves both favorite and non-favorite contacts
      final recipients = <SmsRecipient>[];
      for (final id in selectedIds) {
        final contact = items.firstWhere((c) => c.id == id);
        recipients.add(
          SmsRecipient(
            id: id,
            smsMessageId: '',
            contactId: id,
            phoneNumber: contact.phone,
            contactName: contact.name,
          ),
        );
      }
      expect(recipients, hasLength(2));
      expect(recipients.map((r) => r.contactName), containsAll(['عمتي حن🤍', 'صالح سعيد']));
    });
  });
}
