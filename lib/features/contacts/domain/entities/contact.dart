class Contact {
  final String id;
  final String tenantId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String normalizedPhone;
  final String operatorName;
  final String notes;
  final bool isFavorite;
  final int createdAt;
  final Set<String> tagIds;

  const Contact({
    required this.id,
    required this.tenantId,
    this.firstName = '',
    this.lastName = '',
    this.phoneNumber = '',
    this.normalizedPhone = '',
    this.operatorName = '',
    this.notes = '',
    this.isFavorite = false,
    required this.createdAt,
    this.tagIds = const {},
  });

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return phoneNumber;
    if (firstName.isEmpty) return lastName;
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  String get initials {
    final firstChar = firstName.trim().isNotEmpty
        ? String.fromCharCode(firstName.trim().runes.first)
        : '';
    final lastChar = lastName.trim().isNotEmpty
        ? String.fromCharCode(lastName.trim().runes.first)
        : '';
    if (firstChar.isEmpty && lastChar.isEmpty) return '?';
    return '$firstChar$lastChar'.toUpperCase();
  }

  Contact copyWith({
    String? id,
    String? tenantId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? normalizedPhone,
    String? operatorName,
    String? notes,
    bool? isFavorite,
    int? createdAt,
    Set<String>? tagIds,
  }) {
    return Contact(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      operatorName: operatorName ?? this.operatorName,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'normalizedPhone': normalizedPhone,
      'operatorName': operatorName,
      'notes': notes,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      firstName: (map['firstName'] as String?) ?? '',
      lastName: (map['lastName'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      normalizedPhone: (map['normalizedPhone'] as String?) ?? '',
      operatorName: (map['operatorName'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      isFavorite: (map['isFavorite'] as int?) == 1,
      createdAt: (map['createdAt'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Contact(id: $id, fullName: $fullName, normalizedPhone: $normalizedPhone)';
}
