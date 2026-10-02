class WhatsAppValidationResult {
  final bool isValid;
  final List<String> errors;
  final int estimatedCharacterCount;
  final bool hasInstalledApp;

  const WhatsAppValidationResult({
    required this.isValid,
    this.errors = const [],
    this.estimatedCharacterCount = 0,
    this.hasInstalledApp = false,
  });

  bool get hasEmptyBody => errors.any((e) => e.contains('empty'));
  bool get hasNoRecipients => errors.any((e) => e.contains('recipients'));
  bool get hasNoApp => !hasInstalledApp;

  @override
  String toString() =>
      'WhatsAppValidationResult(valid: $isValid, errors: $errors)';
}
