class MembershipResult {
  final String groupId;
  final int addedCount;
  final int removedCount;
  final List<String> failedContactIds;

  const MembershipResult({
    required this.groupId,
    required this.addedCount,
    required this.removedCount,
    this.failedContactIds = const [],
  });

  bool get hasFailures => failedContactIds.isNotEmpty;

  int get totalProcessed => addedCount + removedCount + failedContactIds.length;

  @override
  String toString() =>
      'MembershipResult(groupId: $groupId, added: $addedCount, removed: $removedCount, failures: ${failedContactIds.length})';
}
