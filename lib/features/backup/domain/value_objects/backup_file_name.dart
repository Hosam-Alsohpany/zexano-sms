class BackupFileName {
  final String value;

  const BackupFileName._(this.value);

  static const String _extension = '.backup';
  static const String _jsonExtension = '.json';

  static BackupFileName generate({
    bool isEncrypted = false,
    String prefix = 'zexano_backup',
  }) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    final ext = isEncrypted ? _jsonExtension : _extension;
    return BackupFileName._('$prefix$timestamp$ext');
  }

  bool get isJson => value.endsWith(_jsonExtension);
  bool get isBackup => value.endsWith(_extension);

  @override
  String toString() => value;
}
