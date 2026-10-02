// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $TenantsTable extends Tenants with TableInfo<$TenantsTable, Tenant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, accountType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenants';
  @override
  VerificationContext validateIntegrity(Insertable<Tenant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tenant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tenant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TenantsTable createAlias(String alias) {
    return $TenantsTable(attachedDatabase, alias);
  }
}

class Tenant extends DataClass implements Insertable<Tenant> {
  final String id;
  final String name;
  final String accountType;
  final int createdAt;
  const Tenant(
      {required this.id,
      required this.name,
      required this.accountType,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TenantsCompanion toCompanion(bool nullToAbsent) {
    return TenantsCompanion(
      id: Value(id),
      name: Value(name),
      accountType: Value(accountType),
      createdAt: Value(createdAt),
    );
  }

  factory Tenant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tenant(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Tenant copyWith(
          {String? id, String? name, String? accountType, int? createdAt}) =>
      Tenant(
        id: id ?? this.id,
        name: name ?? this.name,
        accountType: accountType ?? this.accountType,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Tenant(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, accountType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tenant &&
          other.id == this.id &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.createdAt == this.createdAt);
}

class TenantsCompanion extends UpdateCompanion<Tenant> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> accountType;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TenantsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantsCompanion.insert({
    required String id,
    required String name,
    required String accountType,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        accountType = Value(accountType),
        createdAt = Value(createdAt);
  static Insertable<Tenant> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? accountType,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TenantsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedPhoneMeta =
      const VerificationMeta('normalizedPhone');
  @override
  late final GeneratedColumn<String> normalizedPhone = GeneratedColumn<String>(
      'normalized_phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operatorNameMeta =
      const VerificationMeta('operatorName');
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
      'operator_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        firstName,
        lastName,
        phoneNumber,
        normalizedPhone,
        operatorName,
        notes,
        isFavorite,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<Contact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('normalized_phone')) {
      context.handle(
          _normalizedPhoneMeta,
          normalizedPhone.isAcceptableOrUnknown(
              data['normalized_phone']!, _normalizedPhoneMeta));
    } else if (isInserting) {
      context.missing(_normalizedPhoneMeta);
    }
    if (data.containsKey('operator_name')) {
      context.handle(
          _operatorNameMeta,
          operatorName.isAcceptableOrUnknown(
              data['operator_name']!, _operatorNameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {normalizedPhone},
      ];
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      normalizedPhone: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_phone'])!,
      operatorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operator_name']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;
  final String tenantId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String normalizedPhone;
  final String? operatorName;
  final String? notes;
  final int isFavorite;
  final int createdAt;
  const Contact(
      {required this.id,
      required this.tenantId,
      required this.firstName,
      required this.lastName,
      required this.phoneNumber,
      required this.normalizedPhone,
      this.operatorName,
      this.notes,
      required this.isFavorite,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['phone_number'] = Variable<String>(phoneNumber);
    map['normalized_phone'] = Variable<String>(normalizedPhone);
    if (!nullToAbsent || operatorName != null) {
      map['operator_name'] = Variable<String>(operatorName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_favorite'] = Variable<int>(isFavorite);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      firstName: Value(firstName),
      lastName: Value(lastName),
      phoneNumber: Value(phoneNumber),
      normalizedPhone: Value(normalizedPhone),
      operatorName: operatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(operatorName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      normalizedPhone: serializer.fromJson<String>(json['normalizedPhone']),
      operatorName: serializer.fromJson<String?>(json['operatorName']),
      notes: serializer.fromJson<String?>(json['notes']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'normalizedPhone': serializer.toJson<String>(normalizedPhone),
      'operatorName': serializer.toJson<String?>(operatorName),
      'notes': serializer.toJson<String?>(notes),
      'isFavorite': serializer.toJson<int>(isFavorite),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Contact copyWith(
          {String? id,
          String? tenantId,
          String? firstName,
          String? lastName,
          String? phoneNumber,
          String? normalizedPhone,
          Value<String?> operatorName = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          int? isFavorite,
          int? createdAt}) =>
      Contact(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        normalizedPhone: normalizedPhone ?? this.normalizedPhone,
        operatorName:
            operatorName.present ? operatorName.value : this.operatorName,
        notes: notes.present ? notes.value : this.notes,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('normalizedPhone: $normalizedPhone, ')
          ..write('operatorName: $operatorName, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, firstName, lastName,
      phoneNumber, normalizedPhone, operatorName, notes, isFavorite, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.phoneNumber == this.phoneNumber &&
          other.normalizedPhone == this.normalizedPhone &&
          other.operatorName == this.operatorName &&
          other.notes == this.notes &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> phoneNumber;
  final Value<String> normalizedPhone;
  final Value<String?> operatorName;
  final Value<String?> notes;
  final Value<int> isFavorite;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.normalizedPhone = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String tenantId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String normalizedPhone,
    this.operatorName = const Value.absent(),
    this.notes = const Value.absent(),
    required int isFavorite,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        firstName = Value(firstName),
        lastName = Value(lastName),
        phoneNumber = Value(phoneNumber),
        normalizedPhone = Value(normalizedPhone),
        isFavorite = Value(isFavorite),
        createdAt = Value(createdAt);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? phoneNumber,
    Expression<String>? normalizedPhone,
    Expression<String>? operatorName,
    Expression<String>? notes,
    Expression<int>? isFavorite,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (normalizedPhone != null) 'normalized_phone': normalizedPhone,
      if (operatorName != null) 'operator_name': operatorName,
      if (notes != null) 'notes': notes,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String>? phoneNumber,
      Value<String>? normalizedPhone,
      Value<String?>? operatorName,
      Value<String?>? notes,
      Value<int>? isFavorite,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ContactsCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (normalizedPhone.present) {
      map['normalized_phone'] = Variable<String>(normalizedPhone.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('normalizedPhone: $normalizedPhone, ')
          ..write('operatorName: $operatorName, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, tenantId, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String tenantId;
  final String name;
  final int createdAt;
  const Tag(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Tag copyWith({String? id, String? tenantId, String? name, int? createdAt}) =>
      Tag(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TagsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactTagsTable extends ContactTags
    with TableInfo<$ContactTagsTable, ContactTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tags (id)'));
  @override
  List<GeneratedColumn> get $columns => [contactId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_tags';
  @override
  VerificationContext validateIntegrity(Insertable<ContactTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId, tagId};
  @override
  ContactTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactTag(
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $ContactTagsTable createAlias(String alias) {
    return $ContactTagsTable(attachedDatabase, alias);
  }
}

class ContactTag extends DataClass implements Insertable<ContactTag> {
  final String contactId;
  final String tagId;
  const ContactTag({required this.contactId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<String>(contactId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  ContactTagsCompanion toCompanion(bool nullToAbsent) {
    return ContactTagsCompanion(
      contactId: Value(contactId),
      tagId: Value(tagId),
    );
  }

  factory ContactTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactTag(
      contactId: serializer.fromJson<String>(json['contactId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<String>(contactId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  ContactTag copyWith({String? contactId, String? tagId}) => ContactTag(
        contactId: contactId ?? this.contactId,
        tagId: tagId ?? this.tagId,
      );
  @override
  String toString() {
    return (StringBuffer('ContactTag(')
          ..write('contactId: $contactId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contactId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactTag &&
          other.contactId == this.contactId &&
          other.tagId == this.tagId);
}

class ContactTagsCompanion extends UpdateCompanion<ContactTag> {
  final Value<String> contactId;
  final Value<String> tagId;
  final Value<int> rowid;
  const ContactTagsCompanion({
    this.contactId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactTagsCompanion.insert({
    required String contactId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : contactId = Value(contactId),
        tagId = Value(tagId);
  static Insertable<ContactTag> custom({
    Expression<String>? contactId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactTagsCompanion copyWith(
      {Value<String>? contactId, Value<String>? tagId, Value<int>? rowid}) {
    return ContactTagsCompanion(
      contactId: contactId ?? this.contactId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactTagsCompanion(')
          ..write('contactId: $contactId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tenantId, name, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final int createdAt;
  const Group(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.description,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Group copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? description,
          int? createdAt}) =>
      Group(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> description;
  final Value<int> createdAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String description,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        description = Value(description),
        createdAt = Value(createdAt);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? description,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (id) ON DELETE CASCADE'));
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [groupId, contactId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, contactId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_id'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String groupId;
  final String contactId;
  const GroupMember({required this.groupId, required this.contactId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['contact_id'] = Variable<String>(contactId);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      contactId: Value(contactId),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['groupId']),
      contactId: serializer.fromJson<String>(json['contactId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'contactId': serializer.toJson<String>(contactId),
    };
  }

  GroupMember copyWith({String? groupId, String? contactId}) => GroupMember(
        groupId: groupId ?? this.groupId,
        contactId: contactId ?? this.contactId,
      );
  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, contactId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.contactId == this.contactId);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<String> contactId;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String contactId,
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        contactId = Value(contactId);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<String>? contactId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (contactId != null) 'contact_id': contactId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? groupId, Value<String>? contactId, Value<int>? rowid}) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      contactId: contactId ?? this.contactId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageTemplatesTable extends MessageTemplates
    with TableInfo<$MessageTemplatesTable, MessageTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyContentMeta =
      const VerificationMeta('bodyContent');
  @override
  late final GeneratedColumn<String> bodyContent = GeneratedColumn<String>(
      'body_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tenantId, title, bodyContent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_templates';
  @override
  VerificationContext validateIntegrity(Insertable<MessageTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_content')) {
      context.handle(
          _bodyContentMeta,
          bodyContent.isAcceptableOrUnknown(
              data['body_content']!, _bodyContentMeta));
    } else if (isInserting) {
      context.missing(_bodyContentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      bodyContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MessageTemplatesTable createAlias(String alias) {
    return $MessageTemplatesTable(attachedDatabase, alias);
  }
}

class MessageTemplate extends DataClass implements Insertable<MessageTemplate> {
  final String id;
  final String tenantId;
  final String title;
  final String bodyContent;
  final int createdAt;
  const MessageTemplate(
      {required this.id,
      required this.tenantId,
      required this.title,
      required this.bodyContent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['title'] = Variable<String>(title);
    map['body_content'] = Variable<String>(bodyContent);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MessageTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MessageTemplatesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      title: Value(title),
      bodyContent: Value(bodyContent),
      createdAt: Value(createdAt),
    );
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageTemplate(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      title: serializer.fromJson<String>(json['title']),
      bodyContent: serializer.fromJson<String>(json['bodyContent']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'title': serializer.toJson<String>(title),
      'bodyContent': serializer.toJson<String>(bodyContent),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MessageTemplate copyWith(
          {String? id,
          String? tenantId,
          String? title,
          String? bodyContent,
          int? createdAt}) =>
      MessageTemplate(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        title: title ?? this.title,
        bodyContent: bodyContent ?? this.bodyContent,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('MessageTemplate(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('title: $title, ')
          ..write('bodyContent: $bodyContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, title, bodyContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageTemplate &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.title == this.title &&
          other.bodyContent == this.bodyContent &&
          other.createdAt == this.createdAt);
}

class MessageTemplatesCompanion extends UpdateCompanion<MessageTemplate> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> title;
  final Value<String> bodyContent;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MessageTemplatesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyContent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageTemplatesCompanion.insert({
    required String id,
    required String tenantId,
    required String title,
    required String bodyContent,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        title = Value(title),
        bodyContent = Value(bodyContent),
        createdAt = Value(createdAt);
  static Insertable<MessageTemplate> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? title,
    Expression<String>? bodyContent,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (title != null) 'title': title,
      if (bodyContent != null) 'body_content': bodyContent,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? title,
      Value<String>? bodyContent,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return MessageTemplatesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      bodyContent: bodyContent ?? this.bodyContent,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyContent.present) {
      map['body_content'] = Variable<String>(bodyContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('title: $title, ')
          ..write('bodyContent: $bodyContent, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageHistoryTable extends MessageHistory
    with TableInfo<$MessageHistoryTable, MessageHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _batchIdMeta =
      const VerificationMeta('batchId');
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
      'batch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactNameMeta =
      const VerificationMeta('contactName');
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
      'contact_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetPhoneMeta =
      const VerificationMeta('targetPhone');
  @override
  late final GeneratedColumn<String> targetPhone = GeneratedColumn<String>(
      'target_phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageBodyMeta =
      const VerificationMeta('messageBody');
  @override
  late final GeneratedColumn<String> messageBody = GeneratedColumn<String>(
      'message_body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _channelTypeMeta =
      const VerificationMeta('channelType');
  @override
  late final GeneratedColumn<String> channelType = GeneratedColumn<String>(
      'channel_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _executionStatusMeta =
      const VerificationMeta('executionStatus');
  @override
  late final GeneratedColumn<String> executionStatus = GeneratedColumn<String>(
      'execution_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
      'sent_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('outbound'));
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
      'received_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        batchId,
        contactName,
        contactId,
        targetPhone,
        messageBody,
        channelType,
        executionStatus,
        timestamp,
        sentAt,
        sourceType,
        direction,
        groupId,
        receivedAt,
        peerId,
        isRead
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_history';
  @override
  VerificationContext validateIntegrity(Insertable<MessageHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(_batchIdMeta,
          batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta));
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
          _contactNameMeta,
          contactName.isAcceptableOrUnknown(
              data['contact_name']!, _contactNameMeta));
    } else if (isInserting) {
      context.missing(_contactNameMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    }
    if (data.containsKey('target_phone')) {
      context.handle(
          _targetPhoneMeta,
          targetPhone.isAcceptableOrUnknown(
              data['target_phone']!, _targetPhoneMeta));
    } else if (isInserting) {
      context.missing(_targetPhoneMeta);
    }
    if (data.containsKey('message_body')) {
      context.handle(
          _messageBodyMeta,
          messageBody.isAcceptableOrUnknown(
              data['message_body']!, _messageBodyMeta));
    } else if (isInserting) {
      context.missing(_messageBodyMeta);
    }
    if (data.containsKey('channel_type')) {
      context.handle(
          _channelTypeMeta,
          channelType.isAcceptableOrUnknown(
              data['channel_type']!, _channelTypeMeta));
    } else if (isInserting) {
      context.missing(_channelTypeMeta);
    }
    if (data.containsKey('execution_status')) {
      context.handle(
          _executionStatusMeta,
          executionStatus.isAcceptableOrUnknown(
              data['execution_status']!, _executionStatusMeta));
    } else if (isInserting) {
      context.missing(_executionStatusMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      batchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_id'])!,
      contactName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_name'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_id']),
      targetPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_phone'])!,
      messageBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_body'])!,
      channelType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}channel_type'])!,
      executionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}execution_status'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sent_at']),
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}received_at']),
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id']),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $MessageHistoryTable createAlias(String alias) {
    return $MessageHistoryTable(attachedDatabase, alias);
  }
}

class MessageHistoryData extends DataClass
    implements Insertable<MessageHistoryData> {
  final String id;
  final String tenantId;
  final String batchId;
  final String contactName;
  final String? contactId;
  final String targetPhone;
  final String messageBody;
  final String channelType;
  final String executionStatus;
  final int timestamp;
  final int? sentAt;

  /// Open TEXT field — valid values: manual | contact | group | import | api …
  /// Stored as plain text so new source types never require a schema migration.
  final String sourceType;

  /// Outbound messages sent by Zexano; inbound messages received from the user.
  final String direction;

  /// Non-null when the message was sent as part of a group bulk send.
  final String? groupId;

  /// Epoch-seconds timestamp of when an inbound SMS was received.
  final int? receivedAt;
  final String? peerId;
  final bool isRead;
  const MessageHistoryData(
      {required this.id,
      required this.tenantId,
      required this.batchId,
      required this.contactName,
      this.contactId,
      required this.targetPhone,
      required this.messageBody,
      required this.channelType,
      required this.executionStatus,
      required this.timestamp,
      this.sentAt,
      required this.sourceType,
      required this.direction,
      this.groupId,
      this.receivedAt,
      this.peerId,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['batch_id'] = Variable<String>(batchId);
    map['contact_name'] = Variable<String>(contactName);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['target_phone'] = Variable<String>(targetPhone);
    map['message_body'] = Variable<String>(messageBody);
    map['channel_type'] = Variable<String>(channelType);
    map['execution_status'] = Variable<String>(executionStatus);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<int>(sentAt);
    }
    map['source_type'] = Variable<String>(sourceType);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<int>(receivedAt);
    }
    if (!nullToAbsent || peerId != null) {
      map['peer_id'] = Variable<String>(peerId);
    }
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  MessageHistoryCompanion toCompanion(bool nullToAbsent) {
    return MessageHistoryCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      batchId: Value(batchId),
      contactName: Value(contactName),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      targetPhone: Value(targetPhone),
      messageBody: Value(messageBody),
      channelType: Value(channelType),
      executionStatus: Value(executionStatus),
      timestamp: Value(timestamp),
      sentAt:
          sentAt == null && nullToAbsent ? const Value.absent() : Value(sentAt),
      sourceType: Value(sourceType),
      direction: Value(direction),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      peerId:
          peerId == null && nullToAbsent ? const Value.absent() : Value(peerId),
      isRead: Value(isRead),
    );
  }

  factory MessageHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageHistoryData(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      contactName: serializer.fromJson<String>(json['contactName']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      targetPhone: serializer.fromJson<String>(json['targetPhone']),
      messageBody: serializer.fromJson<String>(json['messageBody']),
      channelType: serializer.fromJson<String>(json['channelType']),
      executionStatus: serializer.fromJson<String>(json['executionStatus']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      sentAt: serializer.fromJson<int?>(json['sentAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      direction: serializer.fromJson<String>(json['direction']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      receivedAt: serializer.fromJson<int?>(json['receivedAt']),
      peerId: serializer.fromJson<String?>(json['peerId']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'batchId': serializer.toJson<String>(batchId),
      'contactName': serializer.toJson<String>(contactName),
      'contactId': serializer.toJson<String?>(contactId),
      'targetPhone': serializer.toJson<String>(targetPhone),
      'messageBody': serializer.toJson<String>(messageBody),
      'channelType': serializer.toJson<String>(channelType),
      'executionStatus': serializer.toJson<String>(executionStatus),
      'timestamp': serializer.toJson<int>(timestamp),
      'sentAt': serializer.toJson<int?>(sentAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'direction': serializer.toJson<String>(direction),
      'groupId': serializer.toJson<String?>(groupId),
      'receivedAt': serializer.toJson<int?>(receivedAt),
      'peerId': serializer.toJson<String?>(peerId),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  MessageHistoryData copyWith(
          {String? id,
          String? tenantId,
          String? batchId,
          String? contactName,
          Value<String?> contactId = const Value.absent(),
          String? targetPhone,
          String? messageBody,
          String? channelType,
          String? executionStatus,
          int? timestamp,
          Value<int?> sentAt = const Value.absent(),
          String? sourceType,
          String? direction,
          Value<String?> groupId = const Value.absent(),
          Value<int?> receivedAt = const Value.absent(),
          Value<String?> peerId = const Value.absent(),
          bool? isRead}) =>
      MessageHistoryData(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        batchId: batchId ?? this.batchId,
        contactName: contactName ?? this.contactName,
        contactId: contactId.present ? contactId.value : this.contactId,
        targetPhone: targetPhone ?? this.targetPhone,
        messageBody: messageBody ?? this.messageBody,
        channelType: channelType ?? this.channelType,
        executionStatus: executionStatus ?? this.executionStatus,
        timestamp: timestamp ?? this.timestamp,
        sentAt: sentAt.present ? sentAt.value : this.sentAt,
        sourceType: sourceType ?? this.sourceType,
        direction: direction ?? this.direction,
        groupId: groupId.present ? groupId.value : this.groupId,
        receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
        peerId: peerId.present ? peerId.value : this.peerId,
        isRead: isRead ?? this.isRead,
      );
  @override
  String toString() {
    return (StringBuffer('MessageHistoryData(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('batchId: $batchId, ')
          ..write('contactName: $contactName, ')
          ..write('contactId: $contactId, ')
          ..write('targetPhone: $targetPhone, ')
          ..write('messageBody: $messageBody, ')
          ..write('channelType: $channelType, ')
          ..write('executionStatus: $executionStatus, ')
          ..write('timestamp: $timestamp, ')
          ..write('sentAt: $sentAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('direction: $direction, ')
          ..write('groupId: $groupId, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('peerId: $peerId, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      batchId,
      contactName,
      contactId,
      targetPhone,
      messageBody,
      channelType,
      executionStatus,
      timestamp,
      sentAt,
      sourceType,
      direction,
      groupId,
      receivedAt,
      peerId,
      isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageHistoryData &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.batchId == this.batchId &&
          other.contactName == this.contactName &&
          other.contactId == this.contactId &&
          other.targetPhone == this.targetPhone &&
          other.messageBody == this.messageBody &&
          other.channelType == this.channelType &&
          other.executionStatus == this.executionStatus &&
          other.timestamp == this.timestamp &&
          other.sentAt == this.sentAt &&
          other.sourceType == this.sourceType &&
          other.direction == this.direction &&
          other.groupId == this.groupId &&
          other.receivedAt == this.receivedAt &&
          other.peerId == this.peerId &&
          other.isRead == this.isRead);
}

class MessageHistoryCompanion extends UpdateCompanion<MessageHistoryData> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> batchId;
  final Value<String> contactName;
  final Value<String?> contactId;
  final Value<String> targetPhone;
  final Value<String> messageBody;
  final Value<String> channelType;
  final Value<String> executionStatus;
  final Value<int> timestamp;
  final Value<int?> sentAt;
  final Value<String> sourceType;
  final Value<String> direction;
  final Value<String?> groupId;
  final Value<int?> receivedAt;
  final Value<String?> peerId;
  final Value<bool> isRead;
  final Value<int> rowid;
  const MessageHistoryCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.contactName = const Value.absent(),
    this.contactId = const Value.absent(),
    this.targetPhone = const Value.absent(),
    this.messageBody = const Value.absent(),
    this.channelType = const Value.absent(),
    this.executionStatus = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.direction = const Value.absent(),
    this.groupId = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.peerId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageHistoryCompanion.insert({
    required String id,
    required String tenantId,
    required String batchId,
    required String contactName,
    this.contactId = const Value.absent(),
    required String targetPhone,
    required String messageBody,
    required String channelType,
    required String executionStatus,
    required int timestamp,
    this.sentAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.direction = const Value.absent(),
    this.groupId = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.peerId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        batchId = Value(batchId),
        contactName = Value(contactName),
        targetPhone = Value(targetPhone),
        messageBody = Value(messageBody),
        channelType = Value(channelType),
        executionStatus = Value(executionStatus),
        timestamp = Value(timestamp);
  static Insertable<MessageHistoryData> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? batchId,
    Expression<String>? contactName,
    Expression<String>? contactId,
    Expression<String>? targetPhone,
    Expression<String>? messageBody,
    Expression<String>? channelType,
    Expression<String>? executionStatus,
    Expression<int>? timestamp,
    Expression<int>? sentAt,
    Expression<String>? sourceType,
    Expression<String>? direction,
    Expression<String>? groupId,
    Expression<int>? receivedAt,
    Expression<String>? peerId,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (batchId != null) 'batch_id': batchId,
      if (contactName != null) 'contact_name': contactName,
      if (contactId != null) 'contact_id': contactId,
      if (targetPhone != null) 'target_phone': targetPhone,
      if (messageBody != null) 'message_body': messageBody,
      if (channelType != null) 'channel_type': channelType,
      if (executionStatus != null) 'execution_status': executionStatus,
      if (timestamp != null) 'timestamp': timestamp,
      if (sentAt != null) 'sent_at': sentAt,
      if (sourceType != null) 'source_type': sourceType,
      if (direction != null) 'direction': direction,
      if (groupId != null) 'group_id': groupId,
      if (receivedAt != null) 'received_at': receivedAt,
      if (peerId != null) 'peer_id': peerId,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageHistoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? batchId,
      Value<String>? contactName,
      Value<String?>? contactId,
      Value<String>? targetPhone,
      Value<String>? messageBody,
      Value<String>? channelType,
      Value<String>? executionStatus,
      Value<int>? timestamp,
      Value<int?>? sentAt,
      Value<String>? sourceType,
      Value<String>? direction,
      Value<String?>? groupId,
      Value<int?>? receivedAt,
      Value<String?>? peerId,
      Value<bool>? isRead,
      Value<int>? rowid}) {
    return MessageHistoryCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      batchId: batchId ?? this.batchId,
      contactName: contactName ?? this.contactName,
      contactId: contactId ?? this.contactId,
      targetPhone: targetPhone ?? this.targetPhone,
      messageBody: messageBody ?? this.messageBody,
      channelType: channelType ?? this.channelType,
      executionStatus: executionStatus ?? this.executionStatus,
      timestamp: timestamp ?? this.timestamp,
      sentAt: sentAt ?? this.sentAt,
      sourceType: sourceType ?? this.sourceType,
      direction: direction ?? this.direction,
      groupId: groupId ?? this.groupId,
      receivedAt: receivedAt ?? this.receivedAt,
      peerId: peerId ?? this.peerId,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (targetPhone.present) {
      map['target_phone'] = Variable<String>(targetPhone.value);
    }
    if (messageBody.present) {
      map['message_body'] = Variable<String>(messageBody.value);
    }
    if (channelType.present) {
      map['channel_type'] = Variable<String>(channelType.value);
    }
    if (executionStatus.present) {
      map['execution_status'] = Variable<String>(executionStatus.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageHistoryCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('batchId: $batchId, ')
          ..write('contactName: $contactName, ')
          ..write('contactId: $contactId, ')
          ..write('targetPhone: $targetPhone, ')
          ..write('messageBody: $messageBody, ')
          ..write('channelType: $channelType, ')
          ..write('executionStatus: $executionStatus, ')
          ..write('timestamp: $timestamp, ')
          ..write('sentAt: $sentAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('direction: $direction, ')
          ..write('groupId: $groupId, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('peerId: $peerId, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssistedSessionsTable extends AssistedSessions
    with TableInfo<$AssistedSessionsTable, AssistedSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssistedSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _messageBodyMeta =
      const VerificationMeta('messageBody');
  @override
  late final GeneratedColumn<String> messageBody = GeneratedColumn<String>(
      'message_body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalRecipientsMeta =
      const VerificationMeta('totalRecipients');
  @override
  late final GeneratedColumn<int> totalRecipients = GeneratedColumn<int>(
      'total_recipients', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedRecipientsMeta =
      const VerificationMeta('completedRecipients');
  @override
  late final GeneratedColumn<int> completedRecipients = GeneratedColumn<int>(
      'completed_recipients', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _failedRecipientsMeta =
      const VerificationMeta('failedRecipients');
  @override
  late final GeneratedColumn<int> failedRecipients = GeneratedColumn<int>(
      'failed_recipients', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentIndexMeta =
      const VerificationMeta('currentIndex');
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
      'current_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        tenantId,
        messageBody,
        totalRecipients,
        completedRecipients,
        failedRecipients,
        currentIndex,
        status,
        createdAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assisted_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<AssistedSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('message_body')) {
      context.handle(
          _messageBodyMeta,
          messageBody.isAcceptableOrUnknown(
              data['message_body']!, _messageBodyMeta));
    } else if (isInserting) {
      context.missing(_messageBodyMeta);
    }
    if (data.containsKey('total_recipients')) {
      context.handle(
          _totalRecipientsMeta,
          totalRecipients.isAcceptableOrUnknown(
              data['total_recipients']!, _totalRecipientsMeta));
    } else if (isInserting) {
      context.missing(_totalRecipientsMeta);
    }
    if (data.containsKey('completed_recipients')) {
      context.handle(
          _completedRecipientsMeta,
          completedRecipients.isAcceptableOrUnknown(
              data['completed_recipients']!, _completedRecipientsMeta));
    } else if (isInserting) {
      context.missing(_completedRecipientsMeta);
    }
    if (data.containsKey('failed_recipients')) {
      context.handle(
          _failedRecipientsMeta,
          failedRecipients.isAcceptableOrUnknown(
              data['failed_recipients']!, _failedRecipientsMeta));
    } else if (isInserting) {
      context.missing(_failedRecipientsMeta);
    }
    if (data.containsKey('current_index')) {
      context.handle(
          _currentIndexMeta,
          currentIndex.isAcceptableOrUnknown(
              data['current_index']!, _currentIndexMeta));
    } else if (isInserting) {
      context.missing(_currentIndexMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  AssistedSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssistedSession(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      messageBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_body'])!,
      totalRecipients: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_recipients'])!,
      completedRecipients: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_recipients'])!,
      failedRecipients: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}failed_recipients'])!,
      currentIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_index'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $AssistedSessionsTable createAlias(String alias) {
    return $AssistedSessionsTable(attachedDatabase, alias);
  }
}

class AssistedSession extends DataClass implements Insertable<AssistedSession> {
  final String sessionId;
  final String tenantId;
  final String messageBody;
  final int totalRecipients;
  final int completedRecipients;
  final int failedRecipients;
  final int currentIndex;
  final String status;
  final int createdAt;
  final int? completedAt;
  const AssistedSession(
      {required this.sessionId,
      required this.tenantId,
      required this.messageBody,
      required this.totalRecipients,
      required this.completedRecipients,
      required this.failedRecipients,
      required this.currentIndex,
      required this.status,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['message_body'] = Variable<String>(messageBody);
    map['total_recipients'] = Variable<int>(totalRecipients);
    map['completed_recipients'] = Variable<int>(completedRecipients);
    map['failed_recipients'] = Variable<int>(failedRecipients);
    map['current_index'] = Variable<int>(currentIndex);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  AssistedSessionsCompanion toCompanion(bool nullToAbsent) {
    return AssistedSessionsCompanion(
      sessionId: Value(sessionId),
      tenantId: Value(tenantId),
      messageBody: Value(messageBody),
      totalRecipients: Value(totalRecipients),
      completedRecipients: Value(completedRecipients),
      failedRecipients: Value(failedRecipients),
      currentIndex: Value(currentIndex),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory AssistedSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssistedSession(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      messageBody: serializer.fromJson<String>(json['messageBody']),
      totalRecipients: serializer.fromJson<int>(json['totalRecipients']),
      completedRecipients:
          serializer.fromJson<int>(json['completedRecipients']),
      failedRecipients: serializer.fromJson<int>(json['failedRecipients']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'tenantId': serializer.toJson<String>(tenantId),
      'messageBody': serializer.toJson<String>(messageBody),
      'totalRecipients': serializer.toJson<int>(totalRecipients),
      'completedRecipients': serializer.toJson<int>(completedRecipients),
      'failedRecipients': serializer.toJson<int>(failedRecipients),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  AssistedSession copyWith(
          {String? sessionId,
          String? tenantId,
          String? messageBody,
          int? totalRecipients,
          int? completedRecipients,
          int? failedRecipients,
          int? currentIndex,
          String? status,
          int? createdAt,
          Value<int?> completedAt = const Value.absent()}) =>
      AssistedSession(
        sessionId: sessionId ?? this.sessionId,
        tenantId: tenantId ?? this.tenantId,
        messageBody: messageBody ?? this.messageBody,
        totalRecipients: totalRecipients ?? this.totalRecipients,
        completedRecipients: completedRecipients ?? this.completedRecipients,
        failedRecipients: failedRecipients ?? this.failedRecipients,
        currentIndex: currentIndex ?? this.currentIndex,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  @override
  String toString() {
    return (StringBuffer('AssistedSession(')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('messageBody: $messageBody, ')
          ..write('totalRecipients: $totalRecipients, ')
          ..write('completedRecipients: $completedRecipients, ')
          ..write('failedRecipients: $failedRecipients, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId,
      tenantId,
      messageBody,
      totalRecipients,
      completedRecipients,
      failedRecipients,
      currentIndex,
      status,
      createdAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistedSession &&
          other.sessionId == this.sessionId &&
          other.tenantId == this.tenantId &&
          other.messageBody == this.messageBody &&
          other.totalRecipients == this.totalRecipients &&
          other.completedRecipients == this.completedRecipients &&
          other.failedRecipients == this.failedRecipients &&
          other.currentIndex == this.currentIndex &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class AssistedSessionsCompanion extends UpdateCompanion<AssistedSession> {
  final Value<String> sessionId;
  final Value<String> tenantId;
  final Value<String> messageBody;
  final Value<int> totalRecipients;
  final Value<int> completedRecipients;
  final Value<int> failedRecipients;
  final Value<int> currentIndex;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const AssistedSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.messageBody = const Value.absent(),
    this.totalRecipients = const Value.absent(),
    this.completedRecipients = const Value.absent(),
    this.failedRecipients = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssistedSessionsCompanion.insert({
    required String sessionId,
    required String tenantId,
    required String messageBody,
    required int totalRecipients,
    required int completedRecipients,
    required int failedRecipients,
    required int currentIndex,
    required String status,
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        tenantId = Value(tenantId),
        messageBody = Value(messageBody),
        totalRecipients = Value(totalRecipients),
        completedRecipients = Value(completedRecipients),
        failedRecipients = Value(failedRecipients),
        currentIndex = Value(currentIndex),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<AssistedSession> custom({
    Expression<String>? sessionId,
    Expression<String>? tenantId,
    Expression<String>? messageBody,
    Expression<int>? totalRecipients,
    Expression<int>? completedRecipients,
    Expression<int>? failedRecipients,
    Expression<int>? currentIndex,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (messageBody != null) 'message_body': messageBody,
      if (totalRecipients != null) 'total_recipients': totalRecipients,
      if (completedRecipients != null)
        'completed_recipients': completedRecipients,
      if (failedRecipients != null) 'failed_recipients': failedRecipients,
      if (currentIndex != null) 'current_index': currentIndex,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssistedSessionsCompanion copyWith(
      {Value<String>? sessionId,
      Value<String>? tenantId,
      Value<String>? messageBody,
      Value<int>? totalRecipients,
      Value<int>? completedRecipients,
      Value<int>? failedRecipients,
      Value<int>? currentIndex,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int?>? completedAt,
      Value<int>? rowid}) {
    return AssistedSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tenantId: tenantId ?? this.tenantId,
      messageBody: messageBody ?? this.messageBody,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      completedRecipients: completedRecipients ?? this.completedRecipients,
      failedRecipients: failedRecipients ?? this.failedRecipients,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (messageBody.present) {
      map['message_body'] = Variable<String>(messageBody.value);
    }
    if (totalRecipients.present) {
      map['total_recipients'] = Variable<int>(totalRecipients.value);
    }
    if (completedRecipients.present) {
      map['completed_recipients'] = Variable<int>(completedRecipients.value);
    }
    if (failedRecipients.present) {
      map['failed_recipients'] = Variable<int>(failedRecipients.value);
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssistedSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('messageBody: $messageBody, ')
          ..write('totalRecipients: $totalRecipients, ')
          ..write('completedRecipients: $completedRecipients, ')
          ..write('failedRecipients: $failedRecipients, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagedRecipientsTable extends StagedRecipients
    with TableInfo<$StagedRecipientsTable, StagedRecipient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagedRecipientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES assisted_sessions (session_id) ON DELETE CASCADE'));
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactNameMeta =
      const VerificationMeta('contactName');
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
      'contact_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _launchSuccessMeta =
      const VerificationMeta('launchSuccess');
  @override
  late final GeneratedColumn<int> launchSuccess = GeneratedColumn<int>(
      'launch_success', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _failureReasonMeta =
      const VerificationMeta('failureReason');
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
      'failure_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attemptedAtMeta =
      const VerificationMeta('attemptedAt');
  @override
  late final GeneratedColumn<int> attemptedAt = GeneratedColumn<int>(
      'attempted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        phoneNumber,
        contactName,
        contactId,
        status,
        launchSuccess,
        failureReason,
        attemptedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staged_recipients';
  @override
  VerificationContext validateIntegrity(Insertable<StagedRecipient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
          _contactNameMeta,
          contactName.isAcceptableOrUnknown(
              data['contact_name']!, _contactNameMeta));
    } else if (isInserting) {
      context.missing(_contactNameMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('launch_success')) {
      context.handle(
          _launchSuccessMeta,
          launchSuccess.isAcceptableOrUnknown(
              data['launch_success']!, _launchSuccessMeta));
    } else if (isInserting) {
      context.missing(_launchSuccessMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
          _failureReasonMeta,
          failureReason.isAcceptableOrUnknown(
              data['failure_reason']!, _failureReasonMeta));
    }
    if (data.containsKey('attempted_at')) {
      context.handle(
          _attemptedAtMeta,
          attemptedAt.isAcceptableOrUnknown(
              data['attempted_at']!, _attemptedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StagedRecipient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StagedRecipient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      contactName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_name'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      launchSuccess: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}launch_success'])!,
      failureReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_reason']),
      attemptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempted_at']),
    );
  }

  @override
  $StagedRecipientsTable createAlias(String alias) {
    return $StagedRecipientsTable(attachedDatabase, alias);
  }
}

class StagedRecipient extends DataClass implements Insertable<StagedRecipient> {
  final String id;
  final String sessionId;
  final String phoneNumber;
  final String contactName;
  final String? contactId;
  final String status;
  final int launchSuccess;
  final String? failureReason;
  final int? attemptedAt;
  const StagedRecipient(
      {required this.id,
      required this.sessionId,
      required this.phoneNumber,
      required this.contactName,
      this.contactId,
      required this.status,
      required this.launchSuccess,
      this.failureReason,
      this.attemptedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['phone_number'] = Variable<String>(phoneNumber);
    map['contact_name'] = Variable<String>(contactName);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['status'] = Variable<String>(status);
    map['launch_success'] = Variable<int>(launchSuccess);
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    if (!nullToAbsent || attemptedAt != null) {
      map['attempted_at'] = Variable<int>(attemptedAt);
    }
    return map;
  }

  StagedRecipientsCompanion toCompanion(bool nullToAbsent) {
    return StagedRecipientsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      phoneNumber: Value(phoneNumber),
      contactName: Value(contactName),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      status: Value(status),
      launchSuccess: Value(launchSuccess),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      attemptedAt: attemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(attemptedAt),
    );
  }

  factory StagedRecipient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StagedRecipient(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      contactName: serializer.fromJson<String>(json['contactName']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      status: serializer.fromJson<String>(json['status']),
      launchSuccess: serializer.fromJson<int>(json['launchSuccess']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      attemptedAt: serializer.fromJson<int?>(json['attemptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'contactName': serializer.toJson<String>(contactName),
      'contactId': serializer.toJson<String?>(contactId),
      'status': serializer.toJson<String>(status),
      'launchSuccess': serializer.toJson<int>(launchSuccess),
      'failureReason': serializer.toJson<String?>(failureReason),
      'attemptedAt': serializer.toJson<int?>(attemptedAt),
    };
  }

  StagedRecipient copyWith(
          {String? id,
          String? sessionId,
          String? phoneNumber,
          String? contactName,
          Value<String?> contactId = const Value.absent(),
          String? status,
          int? launchSuccess,
          Value<String?> failureReason = const Value.absent(),
          Value<int?> attemptedAt = const Value.absent()}) =>
      StagedRecipient(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        contactName: contactName ?? this.contactName,
        contactId: contactId.present ? contactId.value : this.contactId,
        status: status ?? this.status,
        launchSuccess: launchSuccess ?? this.launchSuccess,
        failureReason:
            failureReason.present ? failureReason.value : this.failureReason,
        attemptedAt: attemptedAt.present ? attemptedAt.value : this.attemptedAt,
      );
  @override
  String toString() {
    return (StringBuffer('StagedRecipient(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('contactName: $contactName, ')
          ..write('contactId: $contactId, ')
          ..write('status: $status, ')
          ..write('launchSuccess: $launchSuccess, ')
          ..write('failureReason: $failureReason, ')
          ..write('attemptedAt: $attemptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, phoneNumber, contactName,
      contactId, status, launchSuccess, failureReason, attemptedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagedRecipient &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.phoneNumber == this.phoneNumber &&
          other.contactName == this.contactName &&
          other.contactId == this.contactId &&
          other.status == this.status &&
          other.launchSuccess == this.launchSuccess &&
          other.failureReason == this.failureReason &&
          other.attemptedAt == this.attemptedAt);
}

class StagedRecipientsCompanion extends UpdateCompanion<StagedRecipient> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> phoneNumber;
  final Value<String> contactName;
  final Value<String?> contactId;
  final Value<String> status;
  final Value<int> launchSuccess;
  final Value<String?> failureReason;
  final Value<int?> attemptedAt;
  final Value<int> rowid;
  const StagedRecipientsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.contactName = const Value.absent(),
    this.contactId = const Value.absent(),
    this.status = const Value.absent(),
    this.launchSuccess = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.attemptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StagedRecipientsCompanion.insert({
    required String id,
    required String sessionId,
    required String phoneNumber,
    required String contactName,
    this.contactId = const Value.absent(),
    required String status,
    required int launchSuccess,
    this.failureReason = const Value.absent(),
    this.attemptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        phoneNumber = Value(phoneNumber),
        contactName = Value(contactName),
        status = Value(status),
        launchSuccess = Value(launchSuccess);
  static Insertable<StagedRecipient> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? phoneNumber,
    Expression<String>? contactName,
    Expression<String>? contactId,
    Expression<String>? status,
    Expression<int>? launchSuccess,
    Expression<String>? failureReason,
    Expression<int>? attemptedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (contactName != null) 'contact_name': contactName,
      if (contactId != null) 'contact_id': contactId,
      if (status != null) 'status': status,
      if (launchSuccess != null) 'launch_success': launchSuccess,
      if (failureReason != null) 'failure_reason': failureReason,
      if (attemptedAt != null) 'attempted_at': attemptedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StagedRecipientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? phoneNumber,
      Value<String>? contactName,
      Value<String?>? contactId,
      Value<String>? status,
      Value<int>? launchSuccess,
      Value<String?>? failureReason,
      Value<int?>? attemptedAt,
      Value<int>? rowid}) {
    return StagedRecipientsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      contactId: contactId ?? this.contactId,
      status: status ?? this.status,
      launchSuccess: launchSuccess ?? this.launchSuccess,
      failureReason: failureReason ?? this.failureReason,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (launchSuccess.present) {
      map['launch_success'] = Variable<int>(launchSuccess.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<int>(attemptedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagedRecipientsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('contactName: $contactName, ')
          ..write('contactId: $contactId, ')
          ..write('status: $status, ')
          ..write('launchSuccess: $launchSuccess, ')
          ..write('failureReason: $failureReason, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WhatsAppPreferenceTable extends WhatsAppPreference
    with TableInfo<$WhatsAppPreferenceTable, WhatsAppPreferenceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WhatsAppPreferenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tenants (id)'));
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appNameMeta =
      const VerificationMeta('appName');
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
      'app_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSetMeta = const VerificationMeta('isSet');
  @override
  late final GeneratedColumn<int> isSet = GeneratedColumn<int>(
      'is_set', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tenantId, packageName, appName, isSet];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'whats_app_preference';
  @override
  VerificationContext validateIntegrity(
      Insertable<WhatsAppPreferenceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(_appNameMeta,
          appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta));
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('is_set')) {
      context.handle(
          _isSetMeta, isSet.isAcceptableOrUnknown(data['is_set']!, _isSetMeta));
    } else if (isInserting) {
      context.missing(_isSetMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {tenantId},
      ];
  @override
  WhatsAppPreferenceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WhatsAppPreferenceData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      appName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_name'])!,
      isSet: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_set'])!,
    );
  }

  @override
  $WhatsAppPreferenceTable createAlias(String alias) {
    return $WhatsAppPreferenceTable(attachedDatabase, alias);
  }
}

class WhatsAppPreferenceData extends DataClass
    implements Insertable<WhatsAppPreferenceData> {
  final String id;
  final String tenantId;
  final String packageName;
  final String appName;
  final int isSet;
  const WhatsAppPreferenceData(
      {required this.id,
      required this.tenantId,
      required this.packageName,
      required this.appName,
      required this.isSet});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['is_set'] = Variable<int>(isSet);
    return map;
  }

  WhatsAppPreferenceCompanion toCompanion(bool nullToAbsent) {
    return WhatsAppPreferenceCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      packageName: Value(packageName),
      appName: Value(appName),
      isSet: Value(isSet),
    );
  }

  factory WhatsAppPreferenceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WhatsAppPreferenceData(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      isSet: serializer.fromJson<int>(json['isSet']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'isSet': serializer.toJson<int>(isSet),
    };
  }

  WhatsAppPreferenceData copyWith(
          {String? id,
          String? tenantId,
          String? packageName,
          String? appName,
          int? isSet}) =>
      WhatsAppPreferenceData(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        packageName: packageName ?? this.packageName,
        appName: appName ?? this.appName,
        isSet: isSet ?? this.isSet,
      );
  @override
  String toString() {
    return (StringBuffer('WhatsAppPreferenceData(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('isSet: $isSet')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, packageName, appName, isSet);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WhatsAppPreferenceData &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.isSet == this.isSet);
}

class WhatsAppPreferenceCompanion
    extends UpdateCompanion<WhatsAppPreferenceData> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<int> isSet;
  final Value<int> rowid;
  const WhatsAppPreferenceCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.isSet = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WhatsAppPreferenceCompanion.insert({
    required String id,
    required String tenantId,
    required String packageName,
    required String appName,
    required int isSet,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        packageName = Value(packageName),
        appName = Value(appName),
        isSet = Value(isSet);
  static Insertable<WhatsAppPreferenceData> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<int>? isSet,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (isSet != null) 'is_set': isSet,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WhatsAppPreferenceCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? packageName,
      Value<String>? appName,
      Value<int>? isSet,
      Value<int>? rowid}) {
    return WhatsAppPreferenceCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSet: isSet ?? this.isSet,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (isSet.present) {
      map['is_set'] = Variable<int>(isSet.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WhatsAppPreferenceCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('isSet: $isSet, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
      'last_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageTimestampMeta =
      const VerificationMeta('lastMessageTimestamp');
  @override
  late final GeneratedColumn<int> lastMessageTimestamp = GeneratedColumn<int>(
      'last_message_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  @override
  late final GeneratedColumn<String> draft = GeneratedColumn<String>(
      'draft', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isMutedMeta =
      const VerificationMeta('isMuted');
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
      'is_muted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_muted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        peerId,
        lastMessageId,
        lastMessageTimestamp,
        unreadCount,
        draft,
        isPinned,
        isMuted,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
          _lastMessageIdMeta,
          lastMessageId.isAcceptableOrUnknown(
              data['last_message_id']!, _lastMessageIdMeta));
    }
    if (data.containsKey('last_message_timestamp')) {
      context.handle(
          _lastMessageTimestampMeta,
          lastMessageTimestamp.isAcceptableOrUnknown(
              data['last_message_timestamp']!, _lastMessageTimestampMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    if (data.containsKey('draft')) {
      context.handle(
          _draftMeta, draft.isAcceptableOrUnknown(data['draft']!, _draftMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_muted')) {
      context.handle(_isMutedMeta,
          isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {peerId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
      lastMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_message_id']),
      lastMessageTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_message_timestamp']),
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
      draft: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isMuted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_muted'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String peerId;
  final String? lastMessageId;
  final int? lastMessageTimestamp;
  final int unreadCount;
  final String? draft;
  final bool isPinned;
  final bool isMuted;
  final int updatedAt;
  const Conversation(
      {required this.peerId,
      this.lastMessageId,
      this.lastMessageTimestamp,
      required this.unreadCount,
      this.draft,
      required this.isPinned,
      required this.isMuted,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['peer_id'] = Variable<String>(peerId);
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageTimestamp != null) {
      map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || draft != null) {
      map['draft'] = Variable<String>(draft);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_muted'] = Variable<bool>(isMuted);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      peerId: Value(peerId),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessageTimestamp: lastMessageTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageTimestamp),
      unreadCount: Value(unreadCount),
      draft:
          draft == null && nullToAbsent ? const Value.absent() : Value(draft),
      isPinned: Value(isPinned),
      isMuted: Value(isMuted),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      peerId: serializer.fromJson<String>(json['peerId']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessageTimestamp:
          serializer.fromJson<int?>(json['lastMessageTimestamp']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      draft: serializer.fromJson<String?>(json['draft']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'peerId': serializer.toJson<String>(peerId),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessageTimestamp': serializer.toJson<int?>(lastMessageTimestamp),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'draft': serializer.toJson<String?>(draft),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isMuted': serializer.toJson<bool>(isMuted),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Conversation copyWith(
          {String? peerId,
          Value<String?> lastMessageId = const Value.absent(),
          Value<int?> lastMessageTimestamp = const Value.absent(),
          int? unreadCount,
          Value<String?> draft = const Value.absent(),
          bool? isPinned,
          bool? isMuted,
          int? updatedAt}) =>
      Conversation(
        peerId: peerId ?? this.peerId,
        lastMessageId:
            lastMessageId.present ? lastMessageId.value : this.lastMessageId,
        lastMessageTimestamp: lastMessageTimestamp.present
            ? lastMessageTimestamp.value
            : this.lastMessageTimestamp,
        unreadCount: unreadCount ?? this.unreadCount,
        draft: draft.present ? draft.value : this.draft,
        isPinned: isPinned ?? this.isPinned,
        isMuted: isMuted ?? this.isMuted,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('peerId: $peerId, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('draft: $draft, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(peerId, lastMessageId, lastMessageTimestamp,
      unreadCount, draft, isPinned, isMuted, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.peerId == this.peerId &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessageTimestamp == this.lastMessageTimestamp &&
          other.unreadCount == this.unreadCount &&
          other.draft == this.draft &&
          other.isPinned == this.isPinned &&
          other.isMuted == this.isMuted &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> peerId;
  final Value<String?> lastMessageId;
  final Value<int?> lastMessageTimestamp;
  final Value<int> unreadCount;
  final Value<String?> draft;
  final Value<bool> isPinned;
  final Value<bool> isMuted;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.peerId = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.draft = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String peerId,
    this.lastMessageId = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.draft = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : peerId = Value(peerId),
        updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? peerId,
    Expression<String>? lastMessageId,
    Expression<int>? lastMessageTimestamp,
    Expression<int>? unreadCount,
    Expression<String>? draft,
    Expression<bool>? isPinned,
    Expression<bool>? isMuted,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (peerId != null) 'peer_id': peerId,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessageTimestamp != null)
        'last_message_timestamp': lastMessageTimestamp,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (draft != null) 'draft': draft,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isMuted != null) 'is_muted': isMuted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? peerId,
      Value<String?>? lastMessageId,
      Value<int?>? lastMessageTimestamp,
      Value<int>? unreadCount,
      Value<String?>? draft,
      Value<bool>? isPinned,
      Value<bool>? isMuted,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      peerId: peerId ?? this.peerId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      draft: draft ?? this.draft,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessageTimestamp.present) {
      map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('peerId: $peerId, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('draft: $draft, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TenantsTable tenants = $TenantsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ContactTagsTable contactTags = $ContactTagsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $MessageTemplatesTable messageTemplates =
      $MessageTemplatesTable(this);
  late final $MessageHistoryTable messageHistory = $MessageHistoryTable(this);
  late final $AssistedSessionsTable assistedSessions =
      $AssistedSessionsTable(this);
  late final $StagedRecipientsTable stagedRecipients =
      $StagedRecipientsTable(this);
  late final $WhatsAppPreferenceTable whatsAppPreference =
      $WhatsAppPreferenceTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tenants,
        contacts,
        tags,
        contactTags,
        groups,
        groupMembers,
        messageTemplates,
        messageHistory,
        assistedSessions,
        stagedRecipients,
        whatsAppPreference,
        conversations
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('contact_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('groups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_members', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_members', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('assisted_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('staged_recipients', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}
