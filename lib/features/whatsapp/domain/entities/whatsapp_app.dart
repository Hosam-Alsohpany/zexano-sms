class WhatsAppApp {
  final String packageName;
  final String appName;
  final bool isInstalled;
  final bool isPreferred;

  const WhatsAppApp({
    required this.packageName,
    required this.appName,
    this.isInstalled = false,
    this.isPreferred = false,
  });

  WhatsAppApp copyWith({
    String? packageName,
    String? appName,
    bool? isInstalled,
    bool? isPreferred,
  }) {
    return WhatsAppApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isInstalled: isInstalled ?? this.isInstalled,
      isPreferred: isPreferred ?? this.isPreferred,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsAppApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => 'WhatsAppApp($appName, installed: $isInstalled)';
}
