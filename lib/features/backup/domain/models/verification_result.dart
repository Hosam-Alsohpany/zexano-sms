class VerificationResult {
  final bool isValid;
  final bool checksumMatch;
  final bool fileSizeValid;
  final String? errorMessage;

  const VerificationResult({
    required this.isValid,
    this.checksumMatch = false,
    this.fileSizeValid = false,
    this.errorMessage,
  });

  bool get isCorrupted => !isValid;

  factory VerificationResult.success() =>
      const VerificationResult(isValid: true, checksumMatch: true, fileSizeValid: true);

  factory VerificationResult.failure(String message) =>
      VerificationResult(isValid: false, errorMessage: message);
}
