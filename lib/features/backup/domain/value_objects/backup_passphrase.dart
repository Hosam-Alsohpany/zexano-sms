class BackupPassphrase {
  final String value;

  const BackupPassphrase._(this.value);

  static const int minLength = 8;
  static const int maxLength = 128;

  static BackupPassphrase? create(String input) {
    if (input.length < minLength || input.length > maxLength) {
      return null;
    }
    if (input.trim().isEmpty) return null;
    return BackupPassphrase._(input);
  }

  bool get isValid => value.length >= minLength && value.length <= maxLength;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupPassphrase && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
