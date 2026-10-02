class BackupMetadata {
  final String id;
  final String fileName;
  final int createdAt;
  final int fileSize;
  final int entryCount;
  final String checksum;
  final int version;
  final bool isEncrypted;
  final List<String> channelTypes;

  const BackupMetadata({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.entryCount,
    required this.checksum,
    this.version = 1,
    this.isEncrypted = false,
    this.channelTypes = const ['sms', 'whatsapp'],
  });

  BackupMetadata copyWith({
    String? id,
    String? fileName,
    int? createdAt,
    int? fileSize,
    int? entryCount,
    String? checksum,
    int? version,
    bool? isEncrypted,
    List<String>? channelTypes,
    bool clearChannelTypes = false,
  }) {
    return BackupMetadata(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      entryCount: entryCount ?? this.entryCount,
      checksum: checksum ?? this.checksum,
      version: version ?? this.version,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      channelTypes:
          clearChannelTypes ? [] : (channelTypes ?? this.channelTypes),
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupMetadata && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BackupMetadata(id: $id, fileName: $fileName, '
      'entries: $entryCount, encrypted: $isEncrypted)';
}
