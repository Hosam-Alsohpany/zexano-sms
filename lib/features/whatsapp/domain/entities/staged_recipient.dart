class StagedRecipient {
  final String id;
  final String sessionId;
  final String phoneNumber;
  final String contactName;
  final String? contactId;
  final String status;
  final bool launchSuccess;
  final String? failureReason;
  final int? attemptedAt;

  const StagedRecipient({
    required this.id,
    required this.sessionId,
    required this.phoneNumber,
    this.contactName = '',
    this.contactId,
    this.status = 'pending',
    this.launchSuccess = false,
    this.failureReason,
    this.attemptedAt,
  });

  bool get isPending => status == 'pending';
  bool get isLaunched => status == 'launched';
  bool get isFailed => status == 'failed';
  bool get isSkipped => status == 'skipped';

  StagedRecipient copyWith({
    String? id,
    String? sessionId,
    String? phoneNumber,
    String? contactName,
    String? contactId,
    String? status,
    bool? launchSuccess,
    String? failureReason,
    int? attemptedAt,
    bool clearContactId = false,
    bool clearFailureReason = false,
    bool clearAttemptedAt = false,
  }) {
    return StagedRecipient(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      contactId: clearContactId ? null : (contactId ?? this.contactId),
      status: status ?? this.status,
      launchSuccess: launchSuccess ?? this.launchSuccess,
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
      attemptedAt:
          clearAttemptedAt ? null : (attemptedAt ?? this.attemptedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StagedRecipient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StagedRecipient(phone: $phoneNumber, status: $status)';
}
