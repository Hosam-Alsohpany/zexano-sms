import 'package:dartz/dartz.dart';

sealed class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

class NormalizationFailure extends Failure {
  const NormalizationFailure({required super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class MessagingFailure extends Failure {
  const MessagingFailure({required super.message, super.code});
}

class ContactImportFailure extends Failure {
  const ContactImportFailure({required super.message, super.code});
}

class WhatsAppFailure extends Failure {
  const WhatsAppFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class SettingsFailure extends Failure {
  const SettingsFailure({required super.message, super.code});
}

class BackupFailure extends Failure {
  const BackupFailure({required super.message, super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}

typedef AppResult<T> = Either<Failure, T>;
