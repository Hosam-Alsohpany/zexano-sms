import 'package:zexano_sms/features/conversations/domain/entities/conversation.dart';
import 'package:zexano_sms/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:zexano_sms/features/conversations/data/datasources/conversation_local_source.dart';
import 'package:zexano_sms/core/database/local_database.dart' hide Conversation;
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationLocalSource _localSource;
  final SmsDispatcher _smsDispatcher;
  final AppDatabase _database;
  final SmsLocalSource _smsLocalSource;

  ConversationRepositoryImpl(
    this._localSource,
    this._smsDispatcher,
    this._database,
    this._smsLocalSource,
  );

  @override
  Stream<List<Conversation>> watchConversations() {
    return _localSource.watchConversations().map((list) {
      return list.map((item) {
        return Conversation(
          peerId: item.conversation.peerId,
          contactName: item.contactName,
          lastMessageBody: item.lastMessageBody,
          lastMessageId: item.conversation.lastMessageId,
          lastMessageTimestamp: item.conversation.lastMessageTimestamp,
          unreadCount: item.conversation.unreadCount,
          draft: item.conversation.draft,
          isPinned: item.conversation.isPinned,
          isMuted: item.conversation.isMuted,
          updatedAt: item.conversation.updatedAt,
        );
      }).toList();
    });
  }

  @override
  Stream<List<MessageHistoryData>> watchConversation(String peerId) {
    return _localSource.watchConversation(peerId);
  }

  @override
  Future<void> markAsRead(String peerId) async {
    await _localSource.markAsRead(peerId);
  }
  
  @override
  Future<void> saveDraft(String peerId, String draft) async {
    await _localSource.saveDraft(peerId, draft);
  }

  @override
  Future<void> clearDraft(String peerId) async {
    await _localSource.clearDraft(peerId);
  }

  @override
  Future<void> rebuildConversations() async {
    await _localSource.rebuildConversations();
  }
  
  @override
  Future<void> sendReply(String peerId, String body) async {
    // 1. Generate UUID
    final messageId = const Uuid().v4();

    // Extract targetPhone from peerId (strip 'sms:' prefix)
    final targetPhone = peerId.startsWith('sms:') ? peerId.substring(4) : peerId;

    // 2. Live contact lookup — resolves the real name at reply time.
    // Falls back to empty string if not in contacts.
    final contact = await _smsLocalSource.getContactByAnyPhone(targetPhone);
    final contactName = contact != null
        ? '${contact.firstName} ${contact.lastName}'.trim()
        : '';

    // 3. Insert into MessageHistory as 'queued'.
    // sourceType='manual' is in the Allowlist → trigger upserts the Conversation row.
    await _database.into(_database.messageHistory).insert(
      MessageHistoryCompanion.insert(
        id: messageId,
        tenantId: 'default-tenant',
        batchId: const Uuid().v4(), // 1-to-1 reply gets its own batch ID
        contactName: contactName,   // real name from contacts
        targetPhone: targetPhone,
        peerId: drift.Value(peerId),
        isRead: const drift.Value(true), // Outbound are always read
        messageBody: body,
        channelType: 'sms',
        executionStatus: 'queued',
        sourceType: const drift.Value('manual'), // Allowlist → creates/updates Conversation
        direction: const drift.Value('outbound'),
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );

    // 4. Dispatch the SMS
    await _smsDispatcher.send(
      phoneNumber: targetPhone,
      messageBody: body,
      messageId: messageId,
    );
  }
}
