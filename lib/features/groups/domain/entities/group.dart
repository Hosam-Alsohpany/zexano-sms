class Group {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final int createdAt;
  final int memberCount;

  const Group({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description = '',
    required this.createdAt,
    this.memberCount = 0,
  });

  Group copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    int? createdAt,
    int? memberCount,
  }) {
    return Group(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'memberCount': memberCount,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: (map['createdAt'] as int?) ?? 0,
      memberCount: (map['memberCount'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Group(id: $id, name: $name, members: $memberCount)';
}
