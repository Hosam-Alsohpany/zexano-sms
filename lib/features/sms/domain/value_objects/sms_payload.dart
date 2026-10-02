import '../models/sms_recipient.dart';

class SmsPayload {
  final String messageBody;
  final List<SmsRecipient> recipients;
  final String channelType;
  final int estimatedSegments;
  final int characterCount;

  const SmsPayload({
    required this.messageBody,
    required this.recipients,
    this.channelType = 'sms',
    this.estimatedSegments = 1,
    this.characterCount = 0,
  });

  int get recipientCount => recipients.length;

  SmsPayload copyWith({
    String? messageBody,
    List<SmsRecipient>? recipients,
    String? channelType,
    int? estimatedSegments,
    int? characterCount,
  }) {
    return SmsPayload(
      messageBody: messageBody ?? this.messageBody,
      recipients: recipients ?? this.recipients,
      channelType: channelType ?? this.channelType,
      estimatedSegments: estimatedSegments ?? this.estimatedSegments,
      characterCount: characterCount ?? this.characterCount,
    );
  }

  static int calculateSegments(String body) {
    final length = body.length;
    if (length <= 160) return 1;
    if (length <= 306) return 2;
    return ((length + 152) / 153).ceil();
  }
}
