import 'dart:convert';

class BackupExportDto {
  final BackupManifestDto manifest;
  final Map<String, List<Map<String, dynamic>>> data;

  const BackupExportDto({
    required this.manifest,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'manifest': manifest.toJson(),
    'data': data.map((k, v) => MapEntry(k, v)),
  };

  factory BackupExportDto.fromJson(Map<String, dynamic> json) {
    final dataMap = <String, List<Map<String, dynamic>>>{};
    if (json['data'] != null) {
      for (final entry in (json['data'] as Map<String, dynamic>).entries) {
        dataMap[entry.key] = (entry.value as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    }
    return BackupExportDto(
      manifest: BackupManifestDto.fromJson(json['manifest'] as Map<String, dynamic>),
      data: dataMap,
    );
  }

  String serialize() => jsonEncode(toJson());

  factory BackupExportDto.deserialize(String json) =>
      BackupExportDto.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

class BackupManifestDto {
  final int version;
  final int createdAt;
  final List<String> includedTables;
  final Map<String, int> entryCounts;
  final bool isEncrypted;
  final String? checksum;

  const BackupManifestDto({
    this.version = 1,
    required this.createdAt,
    this.includedTables = const [],
    this.entryCounts = const {},
    this.isEncrypted = false,
    this.checksum,
  });

  int get totalEntries =>
      entryCounts.values.fold(0, (sum, count) => sum + count);

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt,
    'includedTables': includedTables,
    'entryCounts': entryCounts,
    'isEncrypted': isEncrypted,
    if (checksum != null) 'checksum': checksum,
  };

  factory BackupManifestDto.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    if (json['entryCounts'] != null) {
      for (final entry in (json['entryCounts'] as Map<String, dynamic>).entries) {
        counts[entry.key] = (entry.value as num).toInt();
      }
    }
    return BackupManifestDto(
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: (json['createdAt'] as num).toInt(),
      includedTables: (json['includedTables'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entryCounts: counts,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      checksum: json['checksum'] as String?,
    );
  }
}

class BackupFileHeaderDto {
  final BackupManifestDto manifest;
  final String? payload;

  const BackupFileHeaderDto({
    required this.manifest,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'manifest': manifest.toJson(),
    if (manifest.isEncrypted && payload != null) 'payload': payload,
    if (!manifest.isEncrypted) ...manifest.toJson(),
  };

  factory BackupFileHeaderDto.fromJson(Map<String, dynamic> json) {
    return BackupFileHeaderDto(
      manifest: BackupManifestDto.fromJson(json['manifest'] as Map<String, dynamic>),
      payload: json['payload'] as String?,
    );
  }
}
