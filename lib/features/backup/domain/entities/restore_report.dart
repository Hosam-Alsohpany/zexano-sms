class RestoreReport {
  final int restoredContactCount;
  final int restoredSmsCount;
  final int restoredWaCount;
  final int failedItems;
  final List<String> warnings;
  final int totalProcessed;

  const RestoreReport({
    this.restoredContactCount = 0,
    this.restoredSmsCount = 0,
    this.restoredWaCount = 0,
    this.failedItems = 0,
    this.warnings = const [],
    this.totalProcessed = 0,
  });

  bool get hasFailures => failedItems > 0;
  bool get hasWarnings => warnings.isNotEmpty;
  int get totalRestored =>
      restoredContactCount + restoredSmsCount + restoredWaCount;

  @override
  String toString() =>
      'RestoreReport(contacts: $restoredContactCount, SMS: $restoredSmsCount, '
      'WhatsApp: $restoredWaCount, failed: $failedItems)';
}
