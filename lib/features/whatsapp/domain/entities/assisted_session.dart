class AssistedSession {
  final String sessionId;
  final String messageBody;
  final int totalRecipients;
  final int completedRecipients;
  final int failedRecipients;
  final int currentIndex;
  final String status;
  final int createdAt;
  final int? completedAt;

  const AssistedSession({
    required this.sessionId,
    required this.messageBody,
    this.totalRecipients = 0,
    this.completedRecipients = 0,
    this.failedRecipients = 0,
    this.currentIndex = 0,
    this.status = 'in_progress',
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isInProgress => status == 'in_progress';
  bool get allDone => completedRecipients + failedRecipients >= totalRecipients;

  AssistedSession copyWith({
    String? sessionId,
    String? messageBody,
    int? totalRecipients,
    int? completedRecipients,
    int? failedRecipients,
    int? currentIndex,
    String? status,
    int? createdAt,
    int? completedAt,
    bool clearCompletedAt = false,
  }) {
    return AssistedSession(
      sessionId: sessionId ?? this.sessionId,
      messageBody: messageBody ?? this.messageBody,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      completedRecipients: completedRecipients ?? this.completedRecipients,
      failedRecipients: failedRecipients ?? this.failedRecipients,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssistedSession && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() =>
      'AssistedSession(id: $sessionId, status: $status, '
      'progress: $completedRecipients/$totalRecipients)';
}
