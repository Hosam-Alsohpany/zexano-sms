import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_config.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_file_name.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';

void main() {
  group('BackupFileName', () {
    test('generate creates name with .backup extension by default', () {
      final name = BackupFileName.generate();
      expect(name.value, endsWith('.backup'));
      expect(name.isJson, isFalse);
      expect(name.isBackup, isTrue);
    });

    test('generate creates name with .json extension when encrypted', () {
      final name = BackupFileName.generate(isEncrypted: true);
      expect(name.value, endsWith('.json'));
      expect(name.isJson, isTrue);
      expect(name.isBackup, isFalse);
    });

    test('generate uses prefix correctly', () {
      final name = BackupFileName.generate(prefix: 'custom_');
      expect(name.value, startsWith('custom_'));
    });

    test('toString returns value', () {
      final name = BackupFileName.generate();
      expect(name.toString(), name.value);
    });
  });

  group('BackupPassphrase', () {
    test('create returns null for too short passphrase', () {
      expect(BackupPassphrase.create('short'), isNull);
      expect(BackupPassphrase.create(''), isNull);
    });

    test('create returns passphrase for valid length', () {
      final pass = BackupPassphrase.create('valid-passphrase-here');
      expect(pass, isNotNull);
      expect(pass!.value, 'valid-passphrase-here');
    });

    test('create returns null for too long passphrase', () {
      final long = 'a' * 129;
      expect(BackupPassphrase.create(long), isNull);
    });

    test('isValid returns true for valid passphrase', () {
      final pass = BackupPassphrase.create('eightchar');
      expect(pass, isNotNull);
      expect(pass!.isValid, isTrue);
    });

    test('equality based on value', () {
      final a = BackupPassphrase.create('my-long-pass-123');
      final b = BackupPassphrase.create('my-long-pass-123');
      expect(a, b);
    });
  });

  group('BackupConfig', () {
    test('defaults enable everything non-encrypted', () {
      const config = BackupConfig();
      expect(config.includeSms, isTrue);
      expect(config.includeWhatsApp, isTrue);
      expect(config.includeContacts, isTrue);
      expect(config.isEncrypted, isFalse);
    });

    test('isValid returns false when encrypted without passphrase', () {
      const config = BackupConfig(isEncrypted: true);
      expect(config.isValid, isFalse);
    });

    test('isValid returns true when encrypted with passphrase', () {
      const config = BackupConfig(
        isEncrypted: true,
        passphrase: 'some-passphrase',
      );
      expect(config.isValid, isTrue);
    });

    test('isValid returns false when nothing selected', () {
      const config = BackupConfig(
        includeSms: false,
        includeWhatsApp: false,
        includeContacts: false,
      );
      expect(config.isValid, isFalse);
    });

    test('selectedChannels returns enabled channels', () {
      const config = BackupConfig(
        includeSms: true,
        includeWhatsApp: false,
        includeContacts: false,
      );
      expect(config.selectedChannels, ['sms']);
    });

    test('copyWith updates fields', () {
      const config = BackupConfig();
      final modified = config.copyWith(
        includeSms: false,
        isEncrypted: true,
      );
      expect(modified.includeSms, isFalse);
      expect(modified.isEncrypted, isTrue);
      expect(modified.includeWhatsApp, isTrue);
    });

    test('copyWith clearPassphrase clears passphrase', () {
      const config = BackupConfig(passphrase: 'secret');
      final cleared = config.copyWith(clearPassphrase: true);
      expect(cleared.passphrase, isNull);
    });
  });
}
