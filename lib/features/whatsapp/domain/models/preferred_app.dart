class PreferredApp {
  final String packageName;
  final String appName;
  final bool isSet;

  const PreferredApp({
    required this.packageName,
    required this.appName,
    this.isSet = false,
  });

  @override
  String toString() =>
      'PreferredApp($appName, package: $packageName, set: $isSet)';
}
