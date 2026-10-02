import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;

/// Holds a conversation row plus the derived display data from JOINs.
/// [lastMessageBody] comes from message_history via lastMessageId FK.
/// [contactName] comes from contacts via normalizedPhone (substr(peer_id,5)).
class ConversationWithContact {
  final db.Conversation conversation;
  final String? lastMessageBody;
  final String? contactName;

  ConversationWithContact({
    required this.conversation,
    this.lastMessageBody,
    this.contactName,
  });
}

class ConversationLocalSource {
  final db.AppDatabase _database;

  ConversationLocalSource(this._database);

  /// Streams all conversations ordered by last_message_timestamp DESC.
  ///
  /// JOIN chain:
  ///   conversations
  ///     → LEFT JOIN message_history ON lastMessageId = id   (lastMessageBody)
  ///     → LEFT JOIN contacts ON normalizedPhone = substr(peer_id, 5)  (contactName)
  ///
  /// Using substr(peer_id, 5) instead of contactId because:
  ///   - contactId may be NULL for messages written by Kotlin before Flutter enriches
  ///   - normalizedPhone is always stable (peerId is now mandatory)
  ///   - Avoids fragile 'sms:' || contacts.normalized_phone string concatenation
  Stream<List<ConversationWithContact>> watchConversations() {
    return (_database.select(_database.conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageTimestamp)]))
        .join([
          // JOIN 1: get lastMessageBody from message_history via FK (lastMessageId → id)
          leftOuterJoin(
            _database.messageHistory,
            _database.conversations.lastMessageId
                .equalsExp(_database.messageHistory.id),
          ),
          // JOIN 2: get contact name via normalizedPhone or phoneNumber extracted from peerId.
          // peer_id = 'sms:+967...' or 'sms:6060' or 'sms:SABAFON'
          leftOuterJoin(
            _database.contacts,
            _database.contacts.normalizedPhone.equalsExp(
              const CustomExpression<String>('substr(conversations.peer_id, 5)'),
            ) | _database.contacts.phoneNumber.equalsExp(
              const CustomExpression<String>('substr(conversations.peer_id, 5)'),
            ),
          ),
        ])
        .watch()
        .map((rows) => rows.map((row) {
              final conv    = row.readTable(_database.conversations);
              final msg     = row.readTableOrNull(_database.messageHistory);
              final contact = row.readTableOrNull(_database.contacts);

              final liveContactName = contact != null
                  ? '${contact.firstName} ${contact.lastName}'.trim()
                  : null;
              final rawIdentifier = conv.peerId.startsWith('sms:')
                  ? conv.peerId.substring(4)
                  : conv.peerId;
              final contactName = (liveContactName != null && liveContactName.isNotEmpty)
                  ? liveContactName
                  : (msg?.contactName != null && msg!.contactName.trim().isNotEmpty
                      ? msg.contactName.trim()
                      : rawIdentifier);

              return ConversationWithContact(
                conversation:    conv,
                lastMessageBody: msg?.messageBody,
                contactName:     contactName,
              );
            }).toList());
  }

  /// Streams all messages for a given peerId, ordered chronologically.
  Stream<List<db.MessageHistoryData>> watchConversation(String peerId) {
    return (_database.select(_database.messageHistory)
          ..where((tbl) => tbl.peerId.equals(peerId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.timestamp),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch();
  }

  /// Live stream of the contact name for [peerId].
  /// Used by ConversationDetailScreen's AppBar so it updates when
  /// the contact name changes in the Contacts table.
  Stream<String?> watchContactNameByPeer(String peerId) {
    final clean = peerId.startsWith('sms:') ? peerId.substring(4) : peerId;
    final alt = clean.startsWith('+967') ? clean.substring(4) : '+967$clean';
    return _database.customSelect(
      'SELECT first_name, last_name FROM contacts WHERE normalized_phone = ?1 OR phone_number = ?1 OR normalized_phone = ?2 OR phone_number = ?2 LIMIT 1',
      variables: [
        Variable.withString(clean),
        Variable.withString(alt),
      ],
      readsFrom: {_database.contacts},
    ).watchSingleOrNull().map((row) {
      if (row == null) return null;
      final first = row.read<String>('first_name');
      final last = row.read<String>('last_name');
      final full = '$first $last'.trim();
      return full.isNotEmpty ? full : null;
    });
  }

  /// Marks all unread inbound messages in a conversation as read.
  /// The SQLite trigger (trg_mh_after_update) automatically decrements unread_count.
  Future<void> markAsRead(String peerId) async {
    await (_database.update(_database.messageHistory)
          ..where((tbl) =>
              tbl.peerId.equals(peerId) &
              tbl.direction.equals('inbound') &
              tbl.isRead.equals(false)))
        .write(const db.MessageHistoryCompanion(isRead: Value(true)));
  }

  Future<void> saveDraft(String peerId, String draft) async {
    await (_database.update(_database.conversations)
          ..where((tbl) => tbl.peerId.equals(peerId)))
        .write(db.ConversationsCompanion(draft: Value(draft)));
  }

  Future<void> clearDraft(String peerId) async {
    await (_database.update(_database.conversations)
          ..where((tbl) => tbl.peerId.equals(peerId)))
        .write(const db.ConversationsCompanion(draft: Value(null)));
  }

  /// Fallback: completely clears and rebuilds via SQL backfill.
  /// Prefer [AppDatabase.backfillConversationsFromHistory] for startup use.
  Future<void> rebuildConversations() async {
    await _database.backfillConversationsFromHistory();
  }

  Future<void> deleteConversations(List<String> peerIds) async {
    if (peerIds.isEmpty) return;
    await _database.transaction(() async {
      await (_database.delete(_database.messageHistory)
            ..where((tbl) => tbl.peerId.isIn(peerIds)))
          .go();
      await (_database.delete(_database.conversations)
            ..where((tbl) => tbl.peerId.isIn(peerIds)))
          .go();
    });
  }
}
