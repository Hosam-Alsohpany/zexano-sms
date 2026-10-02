class SmsValidationResult {
  final bool isValid;
  final List<String> errors;
  final int estimatedSegments;
  final int characterCount;

  const SmsValidationResult({
    required this.isValid,
    this.errors = const [],
    this.estimatedSegments = 1,
    this.characterCount = 0,
  });

  bool get hasEmptyBody => errors.any((e) => e.contains('empty'));
  bool get hasNoRecipients => errors.any((e) => e.contains('recipients'));
}
