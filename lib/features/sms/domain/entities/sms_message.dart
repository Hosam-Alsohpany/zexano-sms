class SmsMessage {
  final String id;
  final String tenantId;
  final String messageBody;
  final String channelType;
  final String status;
  final int totalRecipients;
  final int sentCount;
  final int failedCount;
  final int createdAt;
  final int? sentAt;

  const SmsMessage({
    required this.id,
    required this.tenantId,
    required this.messageBody,
    this.channelType = 'sms',
    this.status = 'queued',
    this.totalRecipients = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    required this.createdAt,
    this.sentAt,
  });

  SmsMessage copyWith({
    String? id,
    String? tenantId,
    String? messageBody,
    String? channelType,
    String? status,
    int? totalRecipients,
    int? sentCount,
    int? failedCount,
    int? createdAt,
    int? sentAt,
    bool clearSentAt = false,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      messageBody: messageBody ?? this.messageBody,
      channelType: channelType ?? this.channelType,
      status: status ?? this.status,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      createdAt: createdAt ?? this.createdAt,
      sentAt: clearSentAt ? null : (sentAt ?? this.sentAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'messageBody': messageBody,
      'channelType': channelType,
      'status': status,
      'totalRecipients': totalRecipients,
      'sentCount': sentCount,
      'failedCount': failedCount,
      'createdAt': createdAt,
      'sentAt': sentAt,
    };
  }

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      messageBody: map['messageBody'] as String,
      channelType: (map['channelType'] as String?) ?? 'sms',
      status: (map['status'] as String?) ?? 'queued',
      totalRecipients: (map['totalRecipients'] as int?) ?? 0,
      sentCount: (map['sentCount'] as int?) ?? 0,
      failedCount: (map['failedCount'] as int?) ?? 0,
      createdAt: map['createdAt'] as int,
      sentAt: map['sentAt'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmsMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SmsMessage(id: $id, status: $status, sent: $sentCount/$totalRecipients)';
}
