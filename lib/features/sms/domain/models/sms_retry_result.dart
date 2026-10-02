class SmsRetryResult {
  final int totalRetried;
  final int succeeded;
  final int failed;
  final List<String> stillFailedPhoneNumbers;

  const SmsRetryResult({
    required this.totalRetried,
    required this.succeeded,
    this.failed = 0,
    this.stillFailedPhoneNumbers = const [],
  });

  bool get allResolved => failed == 0;
  bool get hasProgress =>
      succeeded > 0 && stillFailedPhoneNumbers.length < totalRetried;
}
