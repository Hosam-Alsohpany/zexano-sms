class BackupManifest {
  final int version;
  final int createdAt;
  final List<String> includedTables;
  final Map<String, int> entryCounts;
  final bool isEncrypted;
  final String? checksum;

  const BackupManifest({
    this.version = 1,
    required this.createdAt,
    this.includedTables = const [],
    this.entryCounts = const {},
    this.isEncrypted = false,
    this.checksum,
  });

  int get totalEntries =>
      entryCounts.values.fold(0, (sum, count) => sum + count);

  bool get isEmpty => totalEntries == 0;

  bool containsTable(String table) => includedTables.contains(table);
}
