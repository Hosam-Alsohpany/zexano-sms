class HistoryFilter {
  final String? channelType;
  final String? status;
  final int? dateFrom;
  final int? dateTo;
  final String? contactId;
  final String? groupId;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const HistoryFilter({
    this.channelType,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.contactId,
    this.groupId,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  HistoryFilter copyWith({
    String? channelType,
    String? status,
    int? dateFrom,
    int? dateTo,
    String? contactId,
    String? groupId,
    String? searchQuery,
    int? limit,
    int? offset,
    bool clearChannelType = false,
    bool clearStatus = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearContactId = false,
    bool clearGroupId = false,
    bool clearSearchQuery = false,
    bool clearLimit = false,
    bool clearOffset = false,
  }) {
    return HistoryFilter(
      channelType:
          clearChannelType ? null : (channelType ?? this.channelType),
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      contactId: clearContactId ? null : (contactId ?? this.contactId),
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      limit: clearLimit ? null : (limit ?? this.limit),
      offset: clearOffset ? null : (offset ?? this.offset),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryFilter &&
        other.channelType == channelType &&
        other.status == status &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.contactId == contactId &&
        other.groupId == groupId &&
        other.searchQuery == searchQuery &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode =>
      Object.hash(channelType, status, dateFrom, dateTo,
          contactId, groupId, searchQuery, limit, offset);
}
