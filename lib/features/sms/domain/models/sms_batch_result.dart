class SmsBatchResult {
  final String messageId;
  final int totalRequested;
  final int sentSuccessfully;
  final int failedCount;
  final List<String> failedPhoneNumbers;
  final String status;

  const SmsBatchResult({
    required this.messageId,
    required this.totalRequested,
    required this.sentSuccessfully,
    this.failedCount = 0,
    this.failedPhoneNumbers = const [],
    this.status = 'sent',
  });

  bool get hasFailures => failedCount > 0;
  bool get allSent => sentSuccessfully == totalRequested;
}
