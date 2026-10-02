class TagAssignment {
  final String contactId;
  final String tagId;

  const TagAssignment({
    required this.contactId,
    required this.tagId,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'tagId': tagId,
    };
  }

  factory TagAssignment.fromMap(Map<String, dynamic> map) {
    return TagAssignment(
      contactId: map['contactId'] as String,
      tagId: map['tagId'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagAssignment &&
        other.contactId == contactId &&
        other.tagId == tagId;
  }

  @override
  int get hashCode => Object.hash(contactId, tagId);

  @override
  String toString() => 'TagAssignment(contactId: $contactId, tagId: $tagId)';
}
