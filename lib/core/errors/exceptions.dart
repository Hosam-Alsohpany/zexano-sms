class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($code): $message';
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class NormalizationException extends AppException {
  const NormalizationException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class MessagingException extends AppException {
  const MessagingException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class ContactImportException extends AppException {
  const ContactImportException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}
