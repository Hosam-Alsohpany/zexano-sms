import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';

void main() {
  late NormalizationEngine engine;

  setUp(() => engine = NormalizationEngine());

  group('validate()', () {
    test('accepts valid international number with +', () {
      expect(engine.validate('+447700900000'), isTrue);
    });

    test('accepts US number with country code', () {
      expect(engine.validate('+14155552671'), isTrue);
    });

    test('accepts international number at max E.164 length (15 digits)', () {
      expect(engine.validate('+123456789012345'), isTrue);
    });

    test('accepts valid Yemeni number with known operator prefix', () {
      expect(engine.validate('+967771234567'), isTrue);
    });

    test('rejects Yemeni number with invalid operator prefix', () {
      expect(engine.validate('+967791234567'), isFalse);
    });

    test('rejects empty string', () {
      expect(engine.validate(''), isFalse);
    });

    test('rejects number without + prefix', () {
      expect(engine.validate('447700900000'), isFalse);
    });

    test('rejects number that is too short (fewer than 7 digits)', () {
      expect(engine.validate('+12345'), isFalse);
    });

    test('rejects number that exceeds E.164 max (16 digits)', () {
      expect(engine.validate('+12345678901234567'), isFalse);
    });

    test('rejects Yemeni number with local part shorter than 8 digits', () {
      expect(engine.validate('+96777123'), isFalse);
    });

    test('rejects Yemeni number with local part longer than 9 digits', () {
      expect(engine.validate('+9677712345678'), isFalse);
    });

    test('accepts Yemeni Sabafon number', () {
      expect(engine.validate('+967731234567'), isTrue);
    });

    test('accepts Yemeni YOU number', () {
      expect(engine.validate('+967711234567'), isTrue);
    });

    test('accepts Yemeni YTelecom number', () {
      expect(engine.validate('+967701234567'), isTrue);
    });
  });

  group('normalize()', () {
    test('passes through already normalized number', () {
      expect(engine.normalize('+967771234567'), '+967771234567');
    });

    test('converts 00 prefix to +', () {
      expect(engine.normalize('00967771234567'), '+967771234567');
    });

    test('adds default country code for local 0 prefix', () {
      expect(engine.normalize('0771234567'), '+967771234567');
    });

    test('adds country code for number starting with 7 (Yemen)', () {
      expect(engine.normalize('771234567'), '+967771234567');
    });

    test('strips non-digit characters except +', () {
      expect(engine.normalize('+967 771 234 567'), '+967771234567');
    });

    test('uses custom country code when provided', () {
      expect(engine.normalize('0771234567', countryCode: '+44'), '+44771234567');
    });

    test('returns empty string for empty input', () {
      expect(engine.normalize(''), '');
    });

    test('returns empty string for alphanumeric Sender IDs (YT, OTP, YemenMobile, ZEXANO)', () {
      expect(engine.normalize('YT'), '');
      expect(engine.normalize('OTP'), '');
      expect(engine.normalize('YemenMobile'), '');
      expect(engine.normalize('ZEXANO'), '');
    });

    test('returns empty string for short numeric Sender IDs (111, 6060, 8000)', () {
      expect(engine.normalize('111'), '');
      expect(engine.normalize('6060'), '');
      expect(engine.normalize('8000'), '');
    });
  });

  group('isSenderId() and isPhoneNumber()', () {
    test('identifies alphanumeric sender IDs correctly', () {
      expect(engine.isSenderId('YT'), isTrue);
      expect(engine.isSenderId('OTP'), isTrue);
      expect(engine.isSenderId('YemenMobile'), isTrue);
      expect(engine.isSenderId('ZEXANO'), isTrue);
    });

    test('identifies short numeric sender IDs correctly', () {
      expect(engine.isSenderId('111'), isTrue);
      expect(engine.isSenderId('6060'), isTrue);
      expect(engine.isSenderId('8000'), isTrue);
    });

    test('identifies valid phone numbers correctly', () {
      expect(engine.isPhoneNumber('+967771234567'), isTrue);
      expect(engine.isPhoneNumber('0771234567'), isTrue);
      expect(engine.isPhoneNumber('771234567'), isTrue);
    });
  });

  group('extractOperator()', () {
    test('recognizes YemenMobile prefix 77', () {
      expect(engine.extractOperator('+967771234567'), 'YemenMobile');
    });

    test('recognizes Sabafon prefix 73', () {
      expect(engine.extractOperator('+967731234567'), 'Sabafon');
    });

    test('recognizes YOU prefix 71', () {
      expect(engine.extractOperator('+967711234567'), 'YOU');
    });

    test('recognizes YTelecom prefix 70', () {
      expect(engine.extractOperator('+967701234567'), 'YTelecom');
    });

    test('returns Unknown for non-Yemeni number', () {
      expect(engine.extractOperator('+447700900000'), 'Unknown');
    });

    test('returns Unknown for unknown prefix', () {
      expect(engine.extractOperator('+967751234567'), 'Unknown');
    });
  });
}
