import 'phone_validation_rules.dart';

class PhoneValidationResult {
  final bool isValid;
  final String? normalizedNumber;
  final String? errorMessage;
  final String? countryCode;
  final String? nationalNumber;

  const PhoneValidationResult({
    required this.isValid,
    this.normalizedNumber,
    this.errorMessage,
    this.countryCode,
    this.nationalNumber,
  });
}

class PhoneValidator {

  PhoneValidationResult validate(String rawInput, {String? countryCode}) {
    final stripped = _stripFormatting(rawInput);
    if (stripped.isEmpty) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: 'Phone number is empty',
      );
    }

    final e164 = _toE164(stripped, countryCode: countryCode);
    if (e164.isEmpty) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: 'Could not normalize phone number',
      );
    }

    final detectedCode = PhoneValidationRules.detectCountryCode(e164);
    if (detectedCode == null) {
      return PhoneValidationResult(
        isValid: false,
        normalizedNumber: e164,
        errorMessage: 'Unknown country code in $e164',
      );
    }

    final rule = PhoneValidationRules.get(detectedCode);
    if (rule == null) {
      return PhoneValidationResult(
        isValid: false,
        normalizedNumber: e164,
        countryCode: detectedCode,
        errorMessage: 'No validation rules for $detectedCode',
      );
    }

    final nationalPart = e164.substring(detectedCode.length);
    final nationalLen = nationalPart.length;

    if (nationalLen < rule.minNationalLength) {
      return PhoneValidationResult(
        isValid: false,
        normalizedNumber: e164,
        countryCode: detectedCode,
        nationalNumber: nationalPart,
        errorMessage:
            'Phone number too short for ${rule.nameEn}: expected ${rule.minNationalLength} digits, got $nationalLen',
      );
    }

    if (nationalLen > rule.effectiveMaxNationalLength) {
      return PhoneValidationResult(
        isValid: false,
        normalizedNumber: e164,
        countryCode: detectedCode,
        nationalNumber: nationalPart,
        errorMessage:
            'Phone number too long for ${rule.nameEn}: expected at most ${rule.effectiveMaxNationalLength} digits, got $nationalLen',
      );
    }

    if (detectedCode == '+967') {
      if (!_hasValidYemeniPrefix(nationalPart)) {
        return PhoneValidationResult(
          isValid: false,
          normalizedNumber: e164,
          countryCode: detectedCode,
          nationalNumber: nationalPart,
          errorMessage:
              'Invalid Yemeni operator prefix in $nationalPart',
        );
      }
    }

    return PhoneValidationResult(
      isValid: true,
      normalizedNumber: e164,
      countryCode: detectedCode,
      nationalNumber: nationalPart,
    );
  }

  String _stripFormatting(String input) {
    return input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  String _toE164(String stripped, {String? countryCode}) {
    if (stripped.startsWith('+')) return stripped;

    if (stripped.startsWith('00')) return '+${stripped.substring(2)}';

    final cc = countryCode ?? '+967';

    if (stripped.startsWith('0')) return '$cc${stripped.substring(1)}';

    if (stripped.startsWith('7') && cc == '+967') {
      return '$cc$stripped';
    }

    return '$cc$stripped';
  }

  bool _hasValidYemeniPrefix(String nationalPart) {
    if (nationalPart.length < 2) return false;
    final prefix = nationalPart.substring(0, 2);
    return _yemeniPrefixes.contains(prefix);
  }

  static const _yemeniPrefixes = ['70', '71', '73', '77', '78'];
}
