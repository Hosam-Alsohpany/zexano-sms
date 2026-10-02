import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/core/errors/failures.dart';

void main() {
  group('Failure types', () {
    test('DatabaseFailure preserves message and code', () {
      const failure = DatabaseFailure(message: 'DB error', code: 'ERR_001');
      expect(failure.message, 'DB error');
      expect(failure.code, 'ERR_001');
    });

    test('SettingsFailure preserves message', () {
      const failure = SettingsFailure(message: 'Settings error');
      expect(failure.message, 'Settings error');
      expect(failure.code, isNull);
    });

    test('BackupFailure preserves message and code', () {
      const failure = BackupFailure(
        message: 'Backup failed',
        code: 'BACKUP_ERR',
      );
      expect(failure.message, 'Backup failed');
      expect(failure.code, 'BACKUP_ERR');
    });

    test('AppResult is Either<Failure, T>', () {
      AppResult<String> result = const Right('success');
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => 'fallback'), 'success');

      result = Left(DatabaseFailure(message: 'fail'));
      expect(result.isLeft(), isTrue);
    });

    test('Multiple failure types are distinct', () {
      expect(
        DatabaseFailure(message: 'x'),
        isA<DatabaseFailure>(),
      );
      expect(
        SettingsFailure(message: 'x'),
        isA<SettingsFailure>(),
      );
      expect(DatabaseFailure(message: 'x'), isNot(isA<SettingsFailure>()));
    });
  });
}
