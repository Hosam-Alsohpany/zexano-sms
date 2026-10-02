import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/phone/phone_validation_rules.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';

void main() {
  group('PhoneValidationRules', () {
    test('has all 30 countries', () {
      expect(PhoneValidationRules.all.length, 30);
    });

    test('detectCountryCode matches longest prefix first', () {
      expect(PhoneValidationRules.detectCountryCode('+212612345678'), '+212');
      expect(PhoneValidationRules.detectCountryCode('+213612345678'), '+213');
      expect(PhoneValidationRules.detectCountryCode('+218912345678'), '+218');
      expect(PhoneValidationRules.detectCountryCode('+21612345678'), '+216');
      expect(PhoneValidationRules.detectCountryCode('+201012345678'), '+20');
      expect(PhoneValidationRules.detectCountryCode('+11234567890'), '+1');
    });

    test('has country rules accessible by code', () {
      final rule = PhoneValidationRules.get('+967');
      expect(rule, isNotNull);
      expect(rule!.nameEn, 'Yemen');
      expect(rule.minNationalLength, 9);
    });
  });

  group('PhoneValidator', () {
    late PhoneValidator validator;

    setUp(() {
      validator = PhoneValidator();
    });

    group('strip formatting', () {
      test('removes spaces', () {
        final result = validator.validate('+967 771 234 567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967771234567');
      });

      test('removes dashes', () {
        final result = validator.validate('+967-771-234-567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967771234567');
      });

      test('removes parentheses', () {
        final result = validator.validate('+1 (212) 555-1234');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+12125551234');
      });

      test('empty input returns invalid', () {
        final result = validator.validate('');
        expect(result.isValid, false);
      });
    });

    group('Yemen +967', () {
      test('correct 9-digit number', () {
        final result = validator.validate('771234567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967771234567');
        expect(result.nationalNumber, '771234567');
      });

      test('correct with 0 prefix', () {
        final result = validator.validate('0771234567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967771234567');
      });

      test('correct with + prefix', () {
        final result = validator.validate('+967771234567');
        expect(result.isValid, true);
        expect(result.nationalNumber, '771234567');
      });

      test('too short (8 digits)', () {
        final result = validator.validate('77123456');
        expect(result.isValid, false);
      });

      test('too long (10 digits)', () {
        final result = validator.validate('7712345678');
        expect(result.isValid, false);
      });

      test('invalid operator prefix (74)', () {
        final result = validator.validate('741234567');
        expect(result.isValid, false);
      });

      test('valid operator 70 (YTelecom)', () {
        final result = validator.validate('701234567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967701234567');
      });

      test('valid operator 78 (YemenMobile)', () {
        final result = validator.validate('781234567');
        expect(result.isValid, true);
        expect(result.normalizedNumber, '+967781234567');
      });
    });

    group('Saudi Arabia +966', () {
      test('correct 9-digit', () {
        final result = validator.validate('+966501234567',
            countryCode: '+966');
        expect(result.isValid, true);
        expect(result.nationalNumber, '501234567');
      });

      test('too short (8 digits)', () {
        final result = validator.validate('+96650123456',
            countryCode: '+966');
        expect(result.isValid, false);
      });

      test('too long (10 digits)', () {
        final result = validator.validate('+9665012345678',
            countryCode: '+966');
        expect(result.isValid, false);
      });
    });

    group('Egypt +20', () {
      test('correct 10-digit', () {
        final result = validator.validate('+201001234567');
        expect(result.isValid, true);
        expect(result.nationalNumber, '1001234567');
      });

      test('too short (9 digits)', () {
        final result = validator.validate('+20100123456');
        expect(result.isValid, false);
      });

      test('too long (11 digits)', () {
        final result = validator.validate('+2010012345678');
        expect(result.isValid, false);
      });
    });

    group('US / Canada +1', () {
      test('correct 10-digit', () {
        final result = validator.validate('+12125551234');
        expect(result.isValid, true);
        expect(result.nationalNumber, '2125551234');
      });

      test('too short (9 digits)', () {
        final result = validator.validate('+1212555123');
        expect(result.isValid, false);
      });

      test('too long (11 digits)', () {
        final result = validator.validate('+121255512345');
        expect(result.isValid, false);
      });
    });

    group('Germany +49 (range 10-11)', () {
      test('correct 10-digit', () {
        final result = validator.validate('+491512345678');
        expect(result.isValid, true);
        expect(result.nationalNumber, '1512345678');
      });

      test('correct 11-digit', () {
        final result = validator.validate('+4915123456789');
        expect(result.isValid, true);
        expect(result.nationalNumber, '15123456789');
      });

      test('too short (9 digits)', () {
        final result = validator.validate('+49151234567');
        expect(result.isValid, false);
      });

      test('too long (12 digits)', () {
        final result = validator.validate('+49151234567890');
        expect(result.isValid, false);
      });
    });

    group('South Korea +82 (range 9-10)', () {
      test('correct 9-digit', () {
        final result = validator.validate('+82101234567');
        expect(result.isValid, true);
        expect(result.nationalNumber, '101234567');
      });

      test('correct 10-digit', () {
        final result = validator.validate('+821012345678');
        expect(result.isValid, true);
        expect(result.nationalNumber, '1012345678');
      });

      test('too short (8 digits)', () {
        final result = validator.validate('+8210123456');
        expect(result.isValid, false);
      });

      test('too long (11 digits)', () {
        final result = validator.validate('+8210123456789');
        expect(result.isValid, false);
      });
    });

    group('China +86', () {
      test('correct 11-digit', () {
        final result = validator.validate('+8613912345678');
        expect(result.isValid, true);
        expect(result.nationalNumber, '13912345678');
      });

      test('too short (10 digits)', () {
        final result = validator.validate('+861391234567');
        expect(result.isValid, false);
      });

      test('too long (12 digits)', () {
        final result = validator.validate('+86139123456789');
        expect(result.isValid, false);
      });
    });

    group('all 30 countries valid', () {
      // test data: (countryCode, sampleNationalNumber)
      final samples = <(String, String)>[
        ('+967', '771234567'),
        ('+966', '501234567'),
        ('+971', '501234567'),
        ('+965', '50123456'),
        ('+974', '50123456'),
        ('+968', '50123456'),
        ('+973', '50123456'),
        ('+962', '791234567'),
        ('+20', '1001234567'),
        ('+963', '912345678'),
        ('+964', '7912345678'),
        ('+218', '912345678'),
        ('+249', '912345678'),
        ('+213', '671234567'),
        ('+212', '612345678'),
        ('+216', '20123456'),
        ('+1', '2125551234'),
        ('+44', '7912345678'),
        ('+49', '1512345678'),
        ('+33', '612345678'),
        ('+39', '3123456789'),
        ('+34', '612345678'),
        ('+31', '612345678'),
        ('+46', '701234567'),
        ('+41', '791234567'),
        ('+61', '412345678'),
        ('+91', '9876543210'),
        ('+86', '13912345678'),
        ('+81', '9012345678'),
        ('+82', '101234567'),
      ];

      for (final (code, national) in samples) {
        test('$code$national is valid', () {
          final full = '$code$national';
          final result = PhoneValidator().validate(full);
          expect(result.isValid, true,
              reason: 'Expected $full to be valid, got: ${result.errorMessage}');
          expect(result.countryCode, code);
          expect(result.nationalNumber, national);
        });
      }
    });

    group('all 30 countries invalid short', () {
      for (final entry in PhoneValidationRules.all.entries) {
        final code = entry.key;
        final rule = entry.value;
        final shortLen = rule.minNationalLength - 1;
        // build a national part that is one digit short
        final shortNational = '1' * (shortLen > 0 ? shortLen : 0);
        if (shortNational.isEmpty) continue; // skip impossible
        test('$code ($shortLen digits) is too short', () {
          final full = '$code$shortNational';
          final result = PhoneValidator().validate(full);
          expect(result.isValid, false,
              reason: 'Expected $full to be invalid (short)');
        });
      }
    });

    group('all 30 countries invalid long', () {
      for (final entry in PhoneValidationRules.all.entries) {
        final code = entry.key;
        final rule = entry.value;
        final longLen = rule.effectiveMaxNationalLength + 1;
        final longNational = '1' * longLen;
        test('$code ($longLen digits) is too long', () {
          final full = '$code$longNational';
          final result = PhoneValidator().validate(full);
          expect(result.isValid, false,
              reason: 'Expected $full to be invalid (long)');
        });
      }
    });
  });
}
