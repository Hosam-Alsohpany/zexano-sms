class AssistedBatchProgress {
  final String sessionId;
  final int total;
  final int completed;
  final int failed;
  final int currentIndex;
  final String? currentPhoneNumber;
  final String status;

  const AssistedBatchProgress({
    required this.sessionId,
    required this.total,
    this.completed = 0,
    this.failed = 0,
    this.currentIndex = 0,
    this.currentPhoneNumber,
    this.status = 'in_progress',
  });

  int get remaining => total - completed - failed;
  double get progressPercent =>
      total > 0 ? (completed + failed) / total : 0.0;
  bool get isComplete => status == 'completed' || status == 'cancelled';
  bool get hasRemaining => remaining > 0;

  AssistedBatchProgress copyWith({
    String? sessionId,
    int? total,
    int? completed,
    int? failed,
    int? currentIndex,
    String? currentPhoneNumber,
    String? status,
    bool clearCurrentPhone = false,
  }) {
    return AssistedBatchProgress(
      sessionId: sessionId ?? this.sessionId,
      total: total ?? this.total,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPhoneNumber: clearCurrentPhone
          ? null
          : (currentPhoneNumber ?? this.currentPhoneNumber),
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'AssistedBatchProgress($completed/$total, failed: $failed, status: $status)';
}
