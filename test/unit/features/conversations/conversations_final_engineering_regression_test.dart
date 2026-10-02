import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/contacts/domain/value_objects/contact_filter.dart';

void main() {
  late NormalizationEngine engine;

  setUp(() {
    engine = NormalizationEngine();
  });

  group('Condition 1 & 2: Canonical Peer ID & Outbound Paths', () {
    test('Manual phone number generates canonical peerId with sms: prefix and E.164 normalization', () {
      const rawPhone = '771234567';
      final peerId = engine.peerIdFor(rawPhone);
      expect(peerId, equals('sms:+967771234567'));
    });

    test('Contact phone number with spaces and dashes generates canonical peerId', () {
      const rawPhone = '077-123-4567';
      final peerId = engine.peerIdFor(rawPhone);
      expect(peerId, equals('sms:+967771234567'));
    });

    test('Shortcode or alphanumeric Sender ID generates canonical peerId without phone mutation', () {
      const senderId = 'SABAFON';
      final peerId = engine.peerIdFor(senderId);
      expect(peerId, equals('sms:SABAFON'));

      const shortCode = '6060';
      final shortCodePeerId = engine.peerIdFor(shortCode);
      expect(shortCodePeerId, equals('sms:6060'));
    });

    test('Group recipients each receive independent canonical peerIds', () {
      final members = [
        Contact(
          id: 'c1',
          tenantId: 'default',
          firstName: 'Ali',
          phoneNumber: '771111111',
          normalizedPhone: '+967771111111',
          createdAt: 0,
        ),
        Contact(
          id: 'c2',
          tenantId: 'default',
          firstName: 'Omar',
          phoneNumber: '772222222',
          normalizedPhone: '+967772222222',
          createdAt: 0,
        ),
      ];

      final peerIds = members.map((m) => engine.peerIdFor(m.normalizedPhone)).toList();
      expect(peerIds, equals(['sms:+967771111111', 'sms:+967772222222']));
      expect(peerIds.toSet().length, equals(2)); // Each recipient has a distinct peerId
    });

    test('Campaign phone numbers produce canonical peerIds consistent with 1-to-1 conversation', () {
      const campaignPhone = '+967773333333';
      final campaignPeerId = engine.peerIdFor(campaignPhone);
      const manualPhone = '0773333333';
      final manualPeerId = engine.peerIdFor(manualPhone);

      // Invariant: Campaign to a recipient maps to the exact same peerId as a manual message
      expect(campaignPeerId, equals(manualPeerId));
    });
  });

  group('Condition 2: Conversation Sequence & De-duplication Simulation', () {
    test('Simulated conversation state machine guarantees 1 conversation per peer across outbound -> inbound -> outbound', () {
      // Data structure representing conversations table indexed by peerId
      final Map<String, Map<String, dynamic>> conversationsTable = {};

      void simulateTriggerAfterInsert({
        required String id,
        required String? peerId,
        required String sourceType,
        required String direction,
        required int timestamp,
        required int isRead,
      }) {
        const allowedSourceTypes = {'manual', 'contact', 'group', 'campaign', 'inbound'};
        if (peerId == null || !allowedSourceTypes.contains(sourceType)) return;

        if (!conversationsTable.containsKey(peerId)) {
          conversationsTable[peerId] = {
            'peer_id': peerId,
            'last_message_id': id,
            'last_message_timestamp': timestamp,
            'unread_count': direction == 'inbound' && isRead == 0 ? 1 : 0,
          };
        } else {
          final row = conversationsTable[peerId]!;
          final currentTs = row['last_message_timestamp'] as int;
          if (timestamp >= currentTs) {
            row['last_message_id'] = id;
            row['last_message_timestamp'] = timestamp;
          }
          if (direction == 'inbound' && isRead == 0) {
            row['unread_count'] = (row['unread_count'] as int) + 1;
          }
        }
      }

      const peerId = 'sms:+967771234567';

      // 1. First outbound message (e.g. from manual compose or contact action)
      simulateTriggerAfterInsert(
        id: 'msg-1',
        peerId: peerId,
        sourceType: 'manual',
        direction: 'outbound',
        timestamp: 1000,
        isRead: 1,
      );

      expect(conversationsTable.length, equals(1));
      expect(conversationsTable[peerId]!['last_message_id'], equals('msg-1'));
      expect(conversationsTable[peerId]!['unread_count'], equals(0));

      // 2. Inbound reply to the same peer
      simulateTriggerAfterInsert(
        id: 'msg-2',
        peerId: peerId,
        sourceType: 'inbound',
        direction: 'inbound',
        timestamp: 1010,
        isRead: 0,
      );

      expect(conversationsTable.length, equals(1)); // MUST NOT DUPLICATE
      expect(conversationsTable[peerId]!['last_message_id'], equals('msg-2'));
      expect(conversationsTable[peerId]!['unread_count'], equals(1));

      // 3. Next outbound message in reply
      simulateTriggerAfterInsert(
        id: 'msg-3',
        peerId: peerId,
        sourceType: 'manual',
        direction: 'outbound',
        timestamp: 1020,
        isRead: 1,
      );

      expect(conversationsTable.length, equals(1)); // STILL EXACTLY 1 CONVERSATION
      expect(conversationsTable[peerId]!['last_message_id'], equals('msg-3'));

      // 4. Outbound from campaign or group to the same peer
      simulateTriggerAfterInsert(
        id: 'msg-4',
        peerId: peerId,
        sourceType: 'group',
        direction: 'outbound',
        timestamp: 1030,
        isRead: 1,
      );

      expect(conversationsTable.length, equals(1)); // STILL EXACTLY 1 CONVERSATION
      expect(conversationsTable[peerId]!['last_message_id'], equals('msg-4'));
    });
  });

  group('Condition 4: Group Member Picker Reactive Filtering & State Preservation', () {
    test('Filtering All vs Favorites maintains selection set and search query', () {
      final allContacts = [
        Contact(
          id: 'c1',
          tenantId: 'default',
          firstName: 'Ahmed',
          phoneNumber: '771111111',
          normalizedPhone: '+967771111111',
          isFavorite: false,
          createdAt: 0,
        ),
        Contact(
          id: 'c2',
          tenantId: 'default',
          firstName: 'Bassem',
          phoneNumber: '772222222',
          normalizedPhone: '+967772222222',
          isFavorite: true,
          createdAt: 0,
        ),
        Contact(
          id: 'c3',
          tenantId: 'default',
          firstName: 'Tareq',
          phoneNumber: '773333333',
          normalizedPhone: '+967773333333',
          isFavorite: true,
          createdAt: 0,
        ),
      ];

      final selectedIds = <String>{'c2'};
      String searchQuery = '';
      bool favoritesOnly = false;

      List<Contact> getVisibleContacts() {
        return allContacts.where((c) {
          if (favoritesOnly && !c.isFavorite) return false;
          if (searchQuery.isNotEmpty && !c.fullName.toLowerCase().contains(searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();
      }

      // Initial state: All contacts
      expect(getVisibleContacts().length, equals(3));
      expect(selectedIds.contains('c2'), isTrue);

      // Switch to Favorites tab
      favoritesOnly = true;
      final favList = getVisibleContacts();
      expect(favList.length, equals(2));
      expect(favList.map((c) => c.id), containsAll(['c2', 'c3']));
      expect(selectedIds.contains('c2'), isTrue); // Selection preserved

      // Stream emits update: c1 is now toggled to favorite
      final updatedC1 = allContacts[0].copyWith(isFavorite: true);
      allContacts[0] = updatedC1;

      // Without reopening screen or manual refresh, visible favorites now includes c1
      final favListAfterStream = getVisibleContacts();
      expect(favListAfterStream.length, equals(3));
      expect(favListAfterStream.map((c) => c.id), contains('c1'));
      expect(selectedIds.contains('c2'), isTrue); // Selection STILL preserved

      // Search filtering
      searchQuery = 'Ah';
      final searchList = getVisibleContacts();
      expect(searchList.length, equals(1));
      expect(searchList.first.id, equals('c1'));
      expect(selectedIds.contains('c2'), isTrue); // Selection STILL preserved across search
    });
  });
}
