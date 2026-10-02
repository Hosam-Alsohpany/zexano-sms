class BuildInfo {
  final String appName;
  final String packageName;
  final String versionName;
  final int versionCode;

  const BuildInfo({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
  });

  String get displayVersion => '$versionName ($versionCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildInfo &&
          appName == other.appName &&
          packageName == other.packageName &&
          versionName == other.versionName &&
          versionCode == other.versionCode;

  @override
  int get hashCode =>
      Object.hash(appName, packageName, versionName, versionCode);

  @override
  String toString() =>
      'BuildInfo($appName $versionName, package: $packageName)';
}
