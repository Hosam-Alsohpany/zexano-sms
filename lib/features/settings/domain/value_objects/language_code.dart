class LanguageCode {
  final String value;

  const LanguageCode._(this.value);

  static const List<String> supportedCodes = ['en', 'ar'];

  static LanguageCode? create(String input) {
    final normalized = input.trim().toLowerCase();
    if (!supportedCodes.contains(normalized)) return null;
    return LanguageCode._(normalized);
  }

  static const LanguageCode english = LanguageCode._('en');
  static const LanguageCode arabic = LanguageCode._('ar');

  bool get isArabic => value == 'ar';
  bool get isEnglish => value == 'en';

  static bool isValid(String input) {
    return supportedCodes.contains(input.trim().toLowerCase());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LanguageCode && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LanguageCode($value)';
}
