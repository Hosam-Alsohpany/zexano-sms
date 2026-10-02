class GroupFilter {
  final String? query;
  final String? contactId;
  final int? limit;
  final int? offset;

  const GroupFilter({
    this.query,
    this.contactId,
    this.limit,
    this.offset,
  });

  GroupFilter copyWith({
    String? query,
    String? contactId,
    int? limit,
    int? offset,
    bool clearQuery = false,
    bool clearContactId = false,
    bool clearLimit = false,
    bool clearOffset = false,
  }) {
    return GroupFilter(
      query: clearQuery ? null : (query ?? this.query),
      contactId: clearContactId ? null : (contactId ?? this.contactId),
      limit: clearLimit ? null : (limit ?? this.limit),
      offset: clearOffset ? null : (offset ?? this.offset),
    );
  }
}
