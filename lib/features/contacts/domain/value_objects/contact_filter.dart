class ContactFilter {
  final String? query;
  final String? operatorName;
  final bool? favoritesOnly;
  final Set<String>? tagIds;
  final String? groupId;
  final int? limit;
  final int? offset;

  const ContactFilter({
    this.query,
    this.operatorName,
    this.favoritesOnly,
    this.tagIds,
    this.groupId,
    this.limit,
    this.offset,
  });

  ContactFilter copyWith({
    String? query,
    String? operatorName,
    bool? favoritesOnly,
    Set<String>? tagIds,
    String? groupId,
    int? limit,
    int? offset,
    bool clearQuery = false,
    bool clearOperator = false,
    bool clearFavorites = false,
    bool clearTagIds = false,
    bool clearGroupId = false,
    bool clearLimit = false,
    bool clearOffset = false,
  }) {
    return ContactFilter(
      query: clearQuery ? null : (query ?? this.query),
      operatorName: clearOperator ? null : (operatorName ?? this.operatorName),
      favoritesOnly: clearFavorites ? null : (favoritesOnly ?? this.favoritesOnly),
      tagIds: clearTagIds ? null : (tagIds ?? this.tagIds),
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      limit: clearLimit ? null : (limit ?? this.limit),
      offset: clearOffset ? null : (offset ?? this.offset),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (query != null) 'query': query,
      if (operatorName != null) 'operatorName': operatorName,
      if (favoritesOnly != null) 'favoritesOnly': favoritesOnly,
      if (tagIds != null && tagIds!.isNotEmpty) 'tagIds': tagIds!.toList(),
      if (groupId != null) 'groupId': groupId,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
  }
}
