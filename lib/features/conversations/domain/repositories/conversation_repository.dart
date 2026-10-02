import 'package:zexano_sms/features/conversations/domain/entities/conversation.dart';
import 'package:zexano_sms/core/database/local_database.dart' show MessageHistoryData;

abstract class ConversationRepository {
  Stream<List<Conversation>> watchConversations();
  Stream<List<MessageHistoryData>> watchConversation(String peerId);
  Future<void> markAsRead(String peerId);
  Future<void> saveDraft(String peerId, String draft);
  Future<void> clearDraft(String peerId);
  Future<void> rebuildConversations();
  Future<void> sendReply(String peerId, String body);
}
