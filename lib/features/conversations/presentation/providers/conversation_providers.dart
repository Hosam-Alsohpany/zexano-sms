import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/conversations/data/datasources/conversation_local_source.dart';
import 'package:zexano_sms/features/conversations/domain/entities/conversation.dart';
import 'package:zexano_sms/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:zexano_sms/core/database/local_database.dart' show MessageHistoryData;

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return sl<ConversationRepository>();
});

final conversationLocalSourceProvider = Provider<ConversationLocalSource>((ref) {
  return sl<ConversationLocalSource>();
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.watchConversations();
});

final conversationDetailProvider = StreamProvider.family<List<MessageHistoryData>, String>((ref, peerId) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.watchConversation(peerId);
});

/// Live stream of the contact name for a given [peerId].
/// Updates automatically when the contact name changes in the Contacts table.
/// Used by ConversationDetailScreen's AppBar.
final contactNameForPeerProvider = StreamProvider.family<String?, String>((ref, peerId) {
  final localSource = ref.watch(conversationLocalSourceProvider);
  return localSource.watchContactNameByPeer(peerId);
});
