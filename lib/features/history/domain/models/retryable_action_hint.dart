class RetryableActionHint {
  final String entryId;
  final String originalId;
  final String channelType;
  final bool hasRetryableFailures;
  final int failedCount;
  final String actionType;

  const RetryableActionHint({
    required this.entryId,
    required this.originalId,
    required this.channelType,
    required this.hasRetryableFailures,
    required this.failedCount,
    required this.actionType,
  });

  bool get isSmsRetry => actionType == 'retry_sms';
  bool get isWhatsAppRelaunch => actionType == 'relaunch_whatsapp';
}
