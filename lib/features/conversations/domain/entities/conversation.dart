class Conversation {
  final String peerId;
  final String? contactName;
  final String? lastMessageId;
  final int? lastMessageTimestamp;
  final int unreadCount;
  final String? draft;
  final bool isPinned;
  final bool isMuted;
  final int updatedAt;
  /// The body of the most recent message — derived via JOIN (no redundant column).
  final String? lastMessageBody;

  Conversation({
    required this.peerId,
    this.contactName,
    this.lastMessageId,
    this.lastMessageTimestamp,
    required this.unreadCount,
    this.draft,
    required this.isPinned,
    required this.isMuted,
    required this.updatedAt,
    this.lastMessageBody,
  });
}
