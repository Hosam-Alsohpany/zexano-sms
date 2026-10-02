class RestorePreview {
  final int totalEntries;
  final int contactCount;
  final int smsMessageCount;
  final int whatsAppSessionCount;
  final int templateCount;
  final int groupCount;
  final int version;

  const RestorePreview({
    required this.totalEntries,
    this.contactCount = 0,
    this.smsMessageCount = 0,
    this.whatsAppSessionCount = 0,
    this.templateCount = 0,
    this.groupCount = 0,
    this.version = 1,
  });

  bool get hasContacts => contactCount > 0;
  bool get hasMessages => smsMessageCount > 0 || whatsAppSessionCount > 0;
}
