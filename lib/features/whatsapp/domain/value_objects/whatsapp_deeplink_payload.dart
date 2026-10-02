class WhatsAppDeeplinkPayload {
  final String phoneNumber;
  final String messageBody;
  final String packageName;
  final String uri;

  const WhatsAppDeeplinkPayload({
    required this.phoneNumber,
    required this.messageBody,
    required this.packageName,
    required this.uri,
  });

  WhatsAppDeeplinkPayload copyWith({
    String? phoneNumber,
    String? messageBody,
    String? packageName,
    String? uri,
  }) {
    return WhatsAppDeeplinkPayload(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      messageBody: messageBody ?? this.messageBody,
      packageName: packageName ?? this.packageName,
      uri: uri ?? this.uri,
    );
  }

  static String buildWaMeLink(String phoneNumber, String message) {
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$phoneNumber?text=$encoded';
  }

  static String buildIntentUri(
    String phoneNumber,
    String message,
    String packageName,
  ) {
    final encoded = Uri.encodeComponent(message);
    return 'whatsapp://send?phone=$phoneNumber&text=$encoded';
  }
}
