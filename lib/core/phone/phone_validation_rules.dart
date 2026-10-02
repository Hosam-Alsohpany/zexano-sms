class CountryPhoneRule {
  final String code;
  final String nameEn;
  final String nameAr;
  final String iso;
  final int minNationalLength;
  final int maxNationalLength;

  const CountryPhoneRule({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.iso,
    required this.minNationalLength,
    this.maxNationalLength = -1,
  });

  int get effectiveMaxNationalLength =>
      maxNationalLength > 0 ? maxNationalLength : minNationalLength;
}

class PhoneValidationRules {
  static const Map<String, CountryPhoneRule> _rules = {
    '+967': CountryPhoneRule(
      code: '+967',
      nameEn: 'Yemen',
      nameAr: 'اليمن',
      iso: 'YE',
      minNationalLength: 9,
    ),
    '+966': CountryPhoneRule(
      code: '+966',
      nameEn: 'Saudi Arabia',
      nameAr: 'السعودية',
      iso: 'SA',
      minNationalLength: 9,
    ),
    '+971': CountryPhoneRule(
      code: '+971',
      nameEn: 'United Arab Emirates',
      nameAr: 'الإمارات',
      iso: 'AE',
      minNationalLength: 9,
    ),
    '+965': CountryPhoneRule(
      code: '+965',
      nameEn: 'Kuwait',
      nameAr: 'الكويت',
      iso: 'KW',
      minNationalLength: 8,
    ),
    '+974': CountryPhoneRule(
      code: '+974',
      nameEn: 'Qatar',
      nameAr: 'قطر',
      iso: 'QA',
      minNationalLength: 8,
    ),
    '+968': CountryPhoneRule(
      code: '+968',
      nameEn: 'Oman',
      nameAr: 'عُمان',
      iso: 'OM',
      minNationalLength: 8,
    ),
    '+973': CountryPhoneRule(
      code: '+973',
      nameEn: 'Bahrain',
      nameAr: 'البحرين',
      iso: 'BH',
      minNationalLength: 8,
    ),
    '+962': CountryPhoneRule(
      code: '+962',
      nameEn: 'Jordan',
      nameAr: 'الأردن',
      iso: 'JO',
      minNationalLength: 9,
    ),
    '+20': CountryPhoneRule(
      code: '+20',
      nameEn: 'Egypt',
      nameAr: 'مصر',
      iso: 'EG',
      minNationalLength: 10,
    ),
    '+963': CountryPhoneRule(
      code: '+963',
      nameEn: 'Syria',
      nameAr: 'سوريا',
      iso: 'SY',
      minNationalLength: 9,
    ),
    '+964': CountryPhoneRule(
      code: '+964',
      nameEn: 'Iraq',
      nameAr: 'العراق',
      iso: 'IQ',
      minNationalLength: 10,
    ),
    '+218': CountryPhoneRule(
      code: '+218',
      nameEn: 'Libya',
      nameAr: 'ليبيا',
      iso: 'LY',
      minNationalLength: 9,
    ),
    '+249': CountryPhoneRule(
      code: '+249',
      nameEn: 'Sudan',
      nameAr: 'السودان',
      iso: 'SD',
      minNationalLength: 9,
    ),
    '+213': CountryPhoneRule(
      code: '+213',
      nameEn: 'Algeria',
      nameAr: 'الجزائر',
      iso: 'DZ',
      minNationalLength: 9,
    ),
    '+212': CountryPhoneRule(
      code: '+212',
      nameEn: 'Morocco',
      nameAr: 'المغرب',
      iso: 'MA',
      minNationalLength: 9,
    ),
    '+216': CountryPhoneRule(
      code: '+216',
      nameEn: 'Tunisia',
      nameAr: 'تونس',
      iso: 'TN',
      minNationalLength: 8,
    ),
    '+1': CountryPhoneRule(
      code: '+1',
      nameEn: 'US / Canada',
      nameAr: 'أمريكا / كندا',
      iso: 'US',
      minNationalLength: 10,
    ),
    '+44': CountryPhoneRule(
      code: '+44',
      nameEn: 'United Kingdom',
      nameAr: 'المملكة المتحدة',
      iso: 'GB',
      minNationalLength: 10,
    ),
    '+49': CountryPhoneRule(
      code: '+49',
      nameEn: 'Germany',
      nameAr: 'ألمانيا',
      iso: 'DE',
      minNationalLength: 10,
      maxNationalLength: 11,
    ),
    '+33': CountryPhoneRule(
      code: '+33',
      nameEn: 'France',
      nameAr: 'فرنسا',
      iso: 'FR',
      minNationalLength: 9,
    ),
    '+39': CountryPhoneRule(
      code: '+39',
      nameEn: 'Italy',
      nameAr: 'إيطاليا',
      iso: 'IT',
      minNationalLength: 10,
    ),
    '+34': CountryPhoneRule(
      code: '+34',
      nameEn: 'Spain',
      nameAr: 'إسبانيا',
      iso: 'ES',
      minNationalLength: 9,
    ),
    '+31': CountryPhoneRule(
      code: '+31',
      nameEn: 'Netherlands',
      nameAr: 'هولندا',
      iso: 'NL',
      minNationalLength: 9,
    ),
    '+46': CountryPhoneRule(
      code: '+46',
      nameEn: 'Sweden',
      nameAr: 'السويد',
      iso: 'SE',
      minNationalLength: 9,
    ),
    '+41': CountryPhoneRule(
      code: '+41',
      nameEn: 'Switzerland',
      nameAr: 'سويسرا',
      iso: 'CH',
      minNationalLength: 9,
    ),
    '+61': CountryPhoneRule(
      code: '+61',
      nameEn: 'Australia',
      nameAr: 'أستراليا',
      iso: 'AU',
      minNationalLength: 9,
    ),
    '+91': CountryPhoneRule(
      code: '+91',
      nameEn: 'India',
      nameAr: 'الهند',
      iso: 'IN',
      minNationalLength: 10,
    ),
    '+86': CountryPhoneRule(
      code: '+86',
      nameEn: 'China',
      nameAr: 'الصين',
      iso: 'CN',
      minNationalLength: 11,
    ),
    '+81': CountryPhoneRule(
      code: '+81',
      nameEn: 'Japan',
      nameAr: 'اليابان',
      iso: 'JP',
      minNationalLength: 10,
    ),
    '+82': CountryPhoneRule(
      code: '+82',
      nameEn: 'South Korea',
      nameAr: 'كوريا الجنوبية',
      iso: 'KR',
      minNationalLength: 9,
      maxNationalLength: 10,
    ),
  };

  static final List<String> _sortedCodes = _rules.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static CountryPhoneRule? get(String code) => _rules[code];

  static String? detectCountryCode(String e164) {
    for (final code in _sortedCodes) {
      if (e164.startsWith(code)) return code;
    }
    return null;
  }

  static Map<String, CountryPhoneRule> get all => Map.unmodifiable(_rules);

  static bool has(String code) => _rules.containsKey(code);
}
