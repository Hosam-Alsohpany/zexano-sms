class NormalizationEngine {
  static const String _defaultCountryCode = '+967';

  /// أرقام اليمن: +967 + 9 أرقام = 13 حرفاً إجمالاً
  static const int _yemeniLocalLength = 9;

  static const Map<String, List<String>> _operatorPrefixes = {
    'YemenMobile': ['77', '78'],
    'Sabafon': ['73'],
    'YOU': ['71'],
    'YTelecom': ['70'],
  };

  static final List<String> _allPrefixes =
      _operatorPrefixes.values.expand((p) => p).toList();

  /// تحويل أي صيغة لرقم الهاتف إلى الصيغة الدولية الموحّدة
  String normalize(String rawInput, {String countryCode = _defaultCountryCode}) {
    if (rawInput.isEmpty) return '';

    // Alphanumeric or short numeric Sender IDs (e.g. YT, OTP, 111, 6060)
    // cannot be normalized to a phone number.
    if (isSenderId(rawInput)) return '';

    // إزالة كل الرموز غير الرقمية عدا علامة +
    String digits = rawInput.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return '';

    // الصيغة الدولية (تبدأ بـ +)
    if (digits.startsWith('+')) return digits;

    // الصيغة الدولية بـ 00 (مثال: 00967XXXXXXX أو 0044XXXXXXX)
    if (digits.startsWith('00')) return '+${digits.substring(2)}';

    // صفر محلي (مثال: 0771234567)
    if (digits.startsWith('0')) return '$countryCode${digits.substring(1)}';

    // رقم دولي بدون + لكن يبدأ برمز اليمن 967 (مثال: 967771234567)
    // يجب معالجته قبل الحالة الافتراضية وإلا ينتج +967967771234567 — خطأ!
    // هذه الحالة كانت ناقصة وتُسبب اختلاف peerId بين Kotlin وFlutter.
    if (digits.startsWith('967')) return '+$digits';

    // رقم يمني يبدأ بـ 7 مباشرة (مثال: 771234567)
    if (digits.startsWith('7') && countryCode == '+967') {
      return '$countryCode$digits';
    }

    // باقي الحالات: أضف رمز الدولة المحدد
    return '$countryCode$digits';
  }

  /// التحقق من صحة الرقم المُوحَّد
  bool validate(String normalizedInput) {
    if (normalizedInput.isEmpty) return false;
    if (!normalizedInput.startsWith('+')) return false;

    final digitsOnly = normalizedInput.replaceAll(RegExp(r'[^\d]'), '');

    // الحد الأدنى 7 أرقام (مع رمز الدولة)، الحد الأقصى 15 وفق ITU-T E.164
    if (digitsOnly.length < 7 || digitsOnly.length > 15) return false;

    // التحقق الخاص بأرقام اليمن
    if (normalizedInput.startsWith('+967')) {
      final localPart = normalizedInput.substring(4); // بعد +967

      // الطول المحلي: 8 أو 9 أرقام (قديم أو حديث)
      if (localPart.length < 8 || localPart.length > _yemeniLocalLength) {
        return false;
      }

      // التحقق من البادئة (أول رقمين من الرقم المحلي)
      final prefix = localPart.substring(0, 2);
      return _allPrefixes.contains(prefix);
    }

    // باقي الدول: القبول طالما الطول منطقي
    return true;
  }

  String extractOperator(String normalizedInput) {
    if (normalizedInput.length < 6) return 'Unknown';
    if (!normalizedInput.startsWith(_defaultCountryCode)) return 'Unknown';

    final prefix = normalizedInput.substring(4, 6);
    for (final entry in _operatorPrefixes.entries) {
      if (entry.value.contains(prefix)) {
        return entry.key;
      }
    }

    return 'Unknown';
  }

  bool hasYemeniPrefix(String rawInput) {
    final digits = rawInput.replaceAll(RegExp(r'[^\d+]'), '');
    return digits.startsWith('+967') ||
        digits.startsWith('00967') ||
        digits.startsWith('0') ||
        digits.startsWith('7');
  }

  // ── Sender ID detection ──────────────────────────────────────────────────

  /// Returns `true` when [input] looks like a valid phone number that should
  /// be normalised, and `false` when it should be treated as an alphanumeric
  /// Sender ID (e.g. "YT", "OTP", "111", "6060", "8000").
  ///
  /// Rules (applied in order):
  ///   1. Contains ANY letter → Sender ID (e.g. YT, OTP, Zain, Yemen Mobile)
  ///   2. After stripping +/0/spaces, fewer than 5 digits → Sender ID
  ///      (5-digit min because no phone number has < 5 local digits)
  ///   3. Otherwise → phone number → normalise normally
  bool isPhoneNumber(String input) {
    if (input.isEmpty) return false;

    // Rule 1: any letter = Sender ID.
    if (input.contains(RegExp(r'[a-zA-Z\u0600-\u06ff]'))) return false;

    // Strip all non-digit characters for the length check.
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');

    // Rule 2: very short digit-only codes (e.g. 111, 6060, 8000).
    if (digitsOnly.length < 5) return false;

    return true;
  }

  /// Inverse of [isPhoneNumber] — returns `true` when [input] is a
  /// Sender ID that must NOT be passed through [normalize].
  bool isSenderId(String input) => !isPhoneNumber(input);

  /// Canonical generator for `peerId` used uniformly across
  /// SQLite message_history, conversations, and UI routing.
  String peerIdFor(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'sms:unknown';
    if (trimmed.startsWith('sms:')) return trimmed;

    if (isSenderId(trimmed)) {
      final clean = trimmed.replaceAll(RegExp(r'\s+'), '');
      return 'sms:$clean';
    }

    final normalized = normalize(trimmed);
    if (normalized.isEmpty) {
      final clean = trimmed.replaceAll(RegExp(r'\s+'), '');
      return 'sms:$clean';
    }
    return 'sms:$normalized';
  }
}
