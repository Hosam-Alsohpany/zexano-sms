class MessageTemplate {
  final String id;
  final String tenantId;
  final String title;
  final String bodyContent;
  final int createdAt;

  const MessageTemplate({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.bodyContent,
    required this.createdAt,
  });
}
