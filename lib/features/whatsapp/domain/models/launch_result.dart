class LaunchResult {
  final String recipientId;
  final bool success;
  final String? failureReason;

  const LaunchResult({
    required this.recipientId,
    required this.success,
    this.failureReason,
  });

  bool get hasFailed => !success;

  @override
  String toString() =>
      'LaunchResult(recipient: $recipientId, success: $success)';
}
