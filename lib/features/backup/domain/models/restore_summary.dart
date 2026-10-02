class RestoreSummary {
  final int attemptedCount;
  final int succeededCount;
  final int failedCount;
  final int skippedCount;
  final List<String> errors;
  final List<String> warnings;

  const RestoreSummary({
    this.attemptedCount = 0,
    this.succeededCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get allSucceeded => failedCount == 0 && errors.isEmpty;
}
