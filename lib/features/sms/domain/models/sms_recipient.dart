class SmsRecipient {
  final String id;
  final String smsMessageId;
  final String? contactId;
  final String phoneNumber;
  final String contactName;
  final String status;
  final String? failureReason;
  final int? sentAt;

  const SmsRecipient({
    required this.id,
    required this.smsMessageId,
    this.contactId,
    required this.phoneNumber,
    this.contactName = '',
    this.status = 'pending',
    this.failureReason,
    this.sentAt,
  });

  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';

  SmsRecipient copyWith({
    String? id,
    String? smsMessageId,
    String? contactId,
    String? phoneNumber,
    String? contactName,
    String? status,
    String? failureReason,
    int? sentAt,
    bool clearContactId = false,
    bool clearFailureReason = false,
    bool clearSentAt = false,
  }) {
    return SmsRecipient(
      id: id ?? this.id,
      smsMessageId: smsMessageId ?? this.smsMessageId,
      contactId: clearContactId ? null : (contactId ?? this.contactId),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      status: status ?? this.status,
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
      sentAt: clearSentAt ? null : (sentAt ?? this.sentAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'smsMessageId': smsMessageId,
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'status': status,
      'failureReason': failureReason,
      'sentAt': sentAt,
    };
  }

  factory SmsRecipient.fromMap(Map<String, dynamic> map) {
    return SmsRecipient(
      id: map['id'] as String,
      smsMessageId: map['smsMessageId'] as String,
      contactId: map['contactId'] as String?,
      phoneNumber: map['phoneNumber'] as String,
      contactName: (map['contactName'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      failureReason: map['failureReason'] as String?,
      sentAt: map['sentAt'] as int?,
    );
  }

  @override
  String toString() =>
      'SmsRecipient(phone: $phoneNumber, status: $status)';
}
