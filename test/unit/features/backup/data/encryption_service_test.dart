import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/backup/data/services/encryption_service.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';

void main() {
  late EncryptionService service;

  setUp(() {
    service = EncryptionService();
  });

  group('EncryptionService', () {
    test('encrypt and decrypt round-trip returns original text', () {
      const original = 'Hello World! This is a test message.';
      final passphrase = BackupPassphrase.create('my-test-pass-123')!;

      final encrypted = service.encrypt(original, passphrase);
      expect(encrypted, isNot(original));

      final decrypted = service.decrypt(encrypted, passphrase);
      expect(decrypted, original);
    });

    test('encrypt produces different ciphertexts for same plaintext', () {
      const plaintext = 'Test message';
      final passphrase = BackupPassphrase.create('another-pass-456')!;

      final a = service.encrypt(plaintext, passphrase);
      final b = service.encrypt(plaintext, passphrase);

      // IV randomization causes different outputs
      expect(a, isNot(b));
    });

    test('decrypt throws FormatException for invalid ciphertext', () {
      final passphrase = BackupPassphrase.create('test-pass-1234')!;
      expect(
        () => service.decrypt('invalid-base64!!!', passphrase),
        throwsFormatException,
      );
    });

    test('decrypt with wrong passphrase produces garbage', () {
      const original = 'Sensitive data';
      final correctPass = BackupPassphrase.create('correct-pass-123')!;
      final wrongPass = BackupPassphrase.create('wrong-pass-1234')!;

      final encrypted = service.encrypt(original, correctPass);

      expect(
        () => service.decrypt(encrypted, wrongPass),
        throwsArgumentError,
      );
    });

    test('encrypt and decrypt empty string', () {
      const original = '';
      final passphrase = BackupPassphrase.create('pass-for-empty')!;

      final encrypted = service.encrypt(original, passphrase);
      final decrypted = service.decrypt(encrypted, passphrase);
      expect(decrypted, original);
    });

    test('encrypt and decrypt long text', () {
      final original = 'A' * 10000;
      final passphrase = BackupPassphrase.create('long-text-pass')!;

      final encrypted = service.encrypt(original, passphrase);
      final decrypted = service.decrypt(encrypted, passphrase);
      expect(decrypted, original);
    });

    test('encrypt uses different IV each time producing different output', () {
      final passphrase = BackupPassphrase.create('iv-test-pass')!;
      const data = 'Data for IV test';
      final results = <String>{};
      for (var i = 0; i < 5; i++) {
        results.add(service.encrypt(data, passphrase));
      }
      expect(results.length, 5);
    });
  });
}
