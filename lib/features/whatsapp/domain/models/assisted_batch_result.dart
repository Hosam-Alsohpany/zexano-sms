class AssistedBatchResult {
  final String sessionId;
  final int totalRecipients;
  final int launchedSuccessfully;
  final int failedCount;
  final int skippedCount;

  const AssistedBatchResult({
    required this.sessionId,
    required this.totalRecipients,
    required this.launchedSuccessfully,
    this.failedCount = 0,
    this.skippedCount = 0,
  });

  bool get hasFailures => failedCount > 0;
  bool get allLaunched => launchedSuccessfully == totalRecipients;

  @override
  String toString() =>
      'AssistedBatchResult(session: $sessionId, launched: '
      '$launchedSuccessfully/$totalRecipients, failed: $failedCount)';
}
