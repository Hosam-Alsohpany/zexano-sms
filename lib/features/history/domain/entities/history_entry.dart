class HistoryEntry {
  final String id;
  final String originalId;
  final String tenantId;
  final String channelType;
  final String messageBody;
  final String status;
  final int totalRecipients;
  final int successCount;
  final int failedCount;
  final int createdAt;
  final int? completedAt;
  final String? contactName;
  final String? phoneNumber;

  // v5 fields ──────────────────────────────────────────────────────────────────
  /// Open string: 'manual' | 'contact' | 'group' | 'inbound' | …
  final String sourceType;

  /// 'outbound' for messages sent by Zexano, 'inbound' for received SMS.
  final String direction;

  /// Non-null when this was a group bulk send.
  final String? groupId;

  /// Human-readable name of the group (resolved at load time from the Groups
  /// table). Null for non-group sends or when the group has been deleted.
  final String? groupName;

  /// Epoch-seconds when the inbound SMS was received (inbound only).
  final int? receivedAt;
  // ────────────────────────────────────────────────────────────────────────────

  const HistoryEntry({
    required this.id,
    required this.originalId,
    required this.tenantId,
    required this.messageBody,
    this.channelType = 'sms',
    this.status = 'queued',
    this.totalRecipients = 0,
    this.successCount = 0,
    this.failedCount = 0,
    required this.createdAt,
    this.completedAt,
    this.contactName,
    this.phoneNumber,
    this.sourceType = 'manual',
    this.direction = 'outbound',
    this.groupId,
    this.groupName,
    this.receivedAt,
  });

  // ── Computed getters ─────────────────────────────────────────────────────────
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isPartial => status == 'partial';
  bool get allDone => successCount + failedCount >= totalRecipients;
  bool get isInbound => direction == 'inbound';
  bool get isOutbound => direction == 'outbound';
  bool get isGroupSend => groupId != null;

  /// Builds the localised display title for this entry.
  ///
  /// Resolution order (same logic used in [HistoryEntryTile]):
  ///   1. Group name (from Groups table, resolved at load time).
  ///   2. Broadcast label with recipient count for manual multi-recipient sends.
  ///   3. Contact name for single-recipient sends.
  ///   4. Phone number.
  ///   5. [fallback] (defaults to empty string).
  String buildDisplayTitle({
    required String Function(int) broadcastFormatter,
    String fallback = '',
  }) {
    if (groupName != null && groupName!.isNotEmpty) return groupName!;
    if (totalRecipients > 1) return broadcastFormatter(totalRecipients);
    if (contactName != null && contactName!.isNotEmpty) return contactName!;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) return phoneNumber!;
    return fallback;
  }

  // ── copyWith ─────────────────────────────────────────────────────────────────
  HistoryEntry copyWith({
    String? id,
    String? originalId,
    String? tenantId,
    String? channelType,
    String? messageBody,
    String? status,
    int? totalRecipients,
    int? successCount,
    int? failedCount,
    int? createdAt,
    int? completedAt,
    String? contactName,
    String? phoneNumber,
    String? sourceType,
    String? direction,
    String? groupId,
    String? groupName,
    int? receivedAt,
    bool clearCompletedAt = false,
    bool clearContactName = false,
    bool clearPhoneNumber = false,
    bool clearGroupId = false,
    bool clearGroupName = false,
    bool clearReceivedAt = false,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      tenantId: tenantId ?? this.tenantId,
      channelType: channelType ?? this.channelType,
      messageBody: messageBody ?? this.messageBody,
      status: status ?? this.status,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      contactName: clearContactName ? null : (contactName ?? this.contactName),
      phoneNumber: clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      sourceType: sourceType ?? this.sourceType,
      direction: direction ?? this.direction,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      groupName: clearGroupName ? null : (groupName ?? this.groupName),
      receivedAt: clearReceivedAt ? null : (receivedAt ?? this.receivedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HistoryEntry(id: $id, direction: $direction, source: $sourceType, '
      'status: $status, success: $successCount/$totalRecipients)';
}
