// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BusinessesTableTable extends BusinessesTable
    with TableInfo<$BusinessesTableTable, BusinessesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users_table (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _industryMeta = const VerificationMeta(
    'industry',
  );
  @override
  late final GeneratedColumn<String> industry = GeneratedColumn<String>(
    'industry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('VND'),
  );
  static const VerificationMeta _annualRevenueMeta = const VerificationMeta(
    'annualRevenue',
  );
  @override
  late final GeneratedColumn<double> annualRevenue = GeneratedColumn<double>(
    'annual_revenue',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeCountMeta = const VerificationMeta(
    'employeeCount',
  );
  @override
  late final GeneratedColumn<int> employeeCount = GeneratedColumn<int>(
    'employee_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    name,
    industry,
    country,
    currency,
    annualRevenue,
    employeeCount,
    stage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'businesses_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('industry')) {
      context.handle(
        _industryMeta,
        industry.isAcceptableOrUnknown(data['industry']!, _industryMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('annual_revenue')) {
      context.handle(
        _annualRevenueMeta,
        annualRevenue.isAcceptableOrUnknown(
          data['annual_revenue']!,
          _annualRevenueMeta,
        ),
      );
    }
    if (data.containsKey('employee_count')) {
      context.handle(
        _employeeCountMeta,
        employeeCount.isAcceptableOrUnknown(
          data['employee_count']!,
          _employeeCountMeta,
        ),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      industry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}industry'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      annualRevenue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_revenue'],
      ),
      employeeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employee_count'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BusinessesTableTable createAlias(String alias) {
    return $BusinessesTableTable(attachedDatabase, alias);
  }
}

class BusinessesTableData extends DataClass
    implements Insertable<BusinessesTableData> {
  final String id;
  final String ownerId;
  final String name;
  final String? industry;
  final String? country;
  final String currency;
  final double? annualRevenue;
  final int? employeeCount;
  final String? stage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BusinessesTableData({
    required this.id,
    required this.ownerId,
    required this.name,
    this.industry,
    this.country,
    required this.currency,
    this.annualRevenue,
    this.employeeCount,
    this.stage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || industry != null) {
      map['industry'] = Variable<String>(industry);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || annualRevenue != null) {
      map['annual_revenue'] = Variable<double>(annualRevenue);
    }
    if (!nullToAbsent || employeeCount != null) {
      map['employee_count'] = Variable<int>(employeeCount);
    }
    if (!nullToAbsent || stage != null) {
      map['stage'] = Variable<String>(stage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BusinessesTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessesTableCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      name: Value(name),
      industry: industry == null && nullToAbsent
          ? const Value.absent()
          : Value(industry),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      currency: Value(currency),
      annualRevenue: annualRevenue == null && nullToAbsent
          ? const Value.absent()
          : Value(annualRevenue),
      employeeCount: employeeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeCount),
      stage: stage == null && nullToAbsent
          ? const Value.absent()
          : Value(stage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BusinessesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessesTableData(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      industry: serializer.fromJson<String?>(json['industry']),
      country: serializer.fromJson<String?>(json['country']),
      currency: serializer.fromJson<String>(json['currency']),
      annualRevenue: serializer.fromJson<double?>(json['annualRevenue']),
      employeeCount: serializer.fromJson<int?>(json['employeeCount']),
      stage: serializer.fromJson<String?>(json['stage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'industry': serializer.toJson<String?>(industry),
      'country': serializer.toJson<String?>(country),
      'currency': serializer.toJson<String>(currency),
      'annualRevenue': serializer.toJson<double?>(annualRevenue),
      'employeeCount': serializer.toJson<int?>(employeeCount),
      'stage': serializer.toJson<String?>(stage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BusinessesTableData copyWith({
    String? id,
    String? ownerId,
    String? name,
    Value<String?> industry = const Value.absent(),
    Value<String?> country = const Value.absent(),
    String? currency,
    Value<double?> annualRevenue = const Value.absent(),
    Value<int?> employeeCount = const Value.absent(),
    Value<String?> stage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BusinessesTableData(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    industry: industry.present ? industry.value : this.industry,
    country: country.present ? country.value : this.country,
    currency: currency ?? this.currency,
    annualRevenue: annualRevenue.present
        ? annualRevenue.value
        : this.annualRevenue,
    employeeCount: employeeCount.present
        ? employeeCount.value
        : this.employeeCount,
    stage: stage.present ? stage.value : this.stage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BusinessesTableData copyWithCompanion(BusinessesTableCompanion data) {
    return BusinessesTableData(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      industry: data.industry.present ? data.industry.value : this.industry,
      country: data.country.present ? data.country.value : this.country,
      currency: data.currency.present ? data.currency.value : this.currency,
      annualRevenue: data.annualRevenue.present
          ? data.annualRevenue.value
          : this.annualRevenue,
      employeeCount: data.employeeCount.present
          ? data.employeeCount.value
          : this.employeeCount,
      stage: data.stage.present ? data.stage.value : this.stage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesTableData(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('industry: $industry, ')
          ..write('country: $country, ')
          ..write('currency: $currency, ')
          ..write('annualRevenue: $annualRevenue, ')
          ..write('employeeCount: $employeeCount, ')
          ..write('stage: $stage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    name,
    industry,
    country,
    currency,
    annualRevenue,
    employeeCount,
    stage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessesTableData &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.industry == this.industry &&
          other.country == this.country &&
          other.currency == this.currency &&
          other.annualRevenue == this.annualRevenue &&
          other.employeeCount == this.employeeCount &&
          other.stage == this.stage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BusinessesTableCompanion extends UpdateCompanion<BusinessesTableData> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> industry;
  final Value<String?> country;
  final Value<String> currency;
  final Value<double?> annualRevenue;
  final Value<int?> employeeCount;
  final Value<String?> stage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BusinessesTableCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.industry = const Value.absent(),
    this.country = const Value.absent(),
    this.currency = const Value.absent(),
    this.annualRevenue = const Value.absent(),
    this.employeeCount = const Value.absent(),
    this.stage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessesTableCompanion.insert({
    required String id,
    required String ownerId,
    required String name,
    this.industry = const Value.absent(),
    this.country = const Value.absent(),
    this.currency = const Value.absent(),
    this.annualRevenue = const Value.absent(),
    this.employeeCount = const Value.absent(),
    this.stage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       name = Value(name);
  static Insertable<BusinessesTableData> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? industry,
    Expression<String>? country,
    Expression<String>? currency,
    Expression<double>? annualRevenue,
    Expression<int>? employeeCount,
    Expression<String>? stage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (industry != null) 'industry': industry,
      if (country != null) 'country': country,
      if (currency != null) 'currency': currency,
      if (annualRevenue != null) 'annual_revenue': annualRevenue,
      if (employeeCount != null) 'employee_count': employeeCount,
      if (stage != null) 'stage': stage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? name,
    Value<String?>? industry,
    Value<String?>? country,
    Value<String>? currency,
    Value<double?>? annualRevenue,
    Value<int?>? employeeCount,
    Value<String?>? stage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BusinessesTableCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      employeeCount: employeeCount ?? this.employeeCount,
      stage: stage ?? this.stage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (industry.present) {
      map['industry'] = Variable<String>(industry.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (annualRevenue.present) {
      map['annual_revenue'] = Variable<double>(annualRevenue.value);
    }
    if (employeeCount.present) {
      map['employee_count'] = Variable<int>(employeeCount.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesTableCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('industry: $industry, ')
          ..write('country: $country, ')
          ..write('currency: $currency, ')
          ..write('annualRevenue: $annualRevenue, ')
          ..write('employeeCount: $employeeCount, ')
          ..write('stage: $stage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferencesMeta = const VerificationMeta(
    'preferences',
  );
  @override
  late final GeneratedColumn<String> preferences = GeneratedColumn<String>(
    'preferences',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    businessId,
    name,
    language,
    timezone,
    preferences,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('preferences')) {
      context.handle(
        _preferencesMeta,
        preferences.isAcceptableOrUnknown(
          data['preferences']!,
          _preferencesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      ),
      preferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferences'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UsersTableData extends DataClass implements Insertable<UsersTableData> {
  final String id;
  final String email;
  final String? businessId;
  final String name;
  final String? language;
  final String? timezone;
  final String? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UsersTableData({
    required this.id,
    required this.email,
    this.businessId,
    required this.name,
    this.language,
    this.timezone,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || timezone != null) {
      map['timezone'] = Variable<String>(timezone);
    }
    if (!nullToAbsent || preferences != null) {
      map['preferences'] = Variable<String>(preferences);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      email: Value(email),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      name: Value(name),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      timezone: timezone == null && nullToAbsent
          ? const Value.absent()
          : Value(timezone),
      preferences: preferences == null && nullToAbsent
          ? const Value.absent()
          : Value(preferences),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UsersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersTableData(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      language: serializer.fromJson<String?>(json['language']),
      timezone: serializer.fromJson<String?>(json['timezone']),
      preferences: serializer.fromJson<String?>(json['preferences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'businessId': serializer.toJson<String?>(businessId),
      'name': serializer.toJson<String>(name),
      'language': serializer.toJson<String?>(language),
      'timezone': serializer.toJson<String?>(timezone),
      'preferences': serializer.toJson<String?>(preferences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UsersTableData copyWith({
    String? id,
    String? email,
    Value<String?> businessId = const Value.absent(),
    String? name,
    Value<String?> language = const Value.absent(),
    Value<String?> timezone = const Value.absent(),
    Value<String?> preferences = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UsersTableData(
    id: id ?? this.id,
    email: email ?? this.email,
    businessId: businessId.present ? businessId.value : this.businessId,
    name: name ?? this.name,
    language: language.present ? language.value : this.language,
    timezone: timezone.present ? timezone.value : this.timezone,
    preferences: preferences.present ? preferences.value : this.preferences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UsersTableData copyWithCompanion(UsersTableCompanion data) {
    return UsersTableData(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      language: data.language.present ? data.language.value : this.language,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      preferences: data.preferences.present
          ? data.preferences.value
          : this.preferences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableData(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('language: $language, ')
          ..write('timezone: $timezone, ')
          ..write('preferences: $preferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    businessId,
    name,
    language,
    timezone,
    preferences,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersTableData &&
          other.id == this.id &&
          other.email == this.email &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.language == this.language &&
          other.timezone == this.timezone &&
          other.preferences == this.preferences &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersTableCompanion extends UpdateCompanion<UsersTableData> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> businessId;
  final Value<String> name;
  final Value<String?> language;
  final Value<String?> timezone;
  final Value<String?> preferences;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.language = const Value.absent(),
    this.timezone = const Value.absent(),
    this.preferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    required String email,
    this.businessId = const Value.absent(),
    required String name,
    this.language = const Value.absent(),
    this.timezone = const Value.absent(),
    this.preferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       name = Value(name);
  static Insertable<UsersTableData> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? language,
    Expression<String>? timezone,
    Expression<String>? preferences,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
      if (preferences != null) 'preferences': preferences,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String?>? businessId,
    Value<String>? name,
    Value<String?>? language,
    Value<String?>? timezone,
    Value<String?>? preferences,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (preferences.present) {
      map['preferences'] = Variable<String>(preferences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('language: $language, ')
          ..write('timezone: $timezone, ')
          ..write('preferences: $preferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProducersTableTable extends ProducersTable
    with TableInfo<$ProducersTableTable, ProducersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProducersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reliabilityScoreMeta = const VerificationMeta(
    'reliabilityScore',
  );
  @override
  late final GeneratedColumn<double> reliabilityScore = GeneratedColumn<double>(
    'reliability_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minOrderQtyMeta = const VerificationMeta(
    'minOrderQty',
  );
  @override
  late final GeneratedColumn<double> minOrderQty = GeneratedColumn<double>(
    'min_order_qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leadTimeDaysMeta = const VerificationMeta(
    'leadTimeDays',
  );
  @override
  late final GeneratedColumn<int> leadTimeDays = GeneratedColumn<int>(
    'lead_time_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationsMeta = const VerificationMeta(
    'certifications',
  );
  @override
  late final GeneratedColumn<String> certifications = GeneratedColumn<String>(
    'certifications',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactEmailMeta = const VerificationMeta(
    'contactEmail',
  );
  @override
  late final GeneratedColumn<String> contactEmail = GeneratedColumn<String>(
    'contact_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPhoneMeta = const VerificationMeta(
    'contactPhone',
  );
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
    'contact_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalSourceMeta = const VerificationMeta(
    'externalSource',
  );
  @override
  late final GeneratedColumn<String> externalSource = GeneratedColumn<String>(
    'external_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    category,
    country,
    rating,
    reliabilityScore,
    minOrderQty,
    leadTimeDays,
    certifications,
    contactEmail,
    contactPhone,
    externalId,
    externalSource,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'producers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProducersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('reliability_score')) {
      context.handle(
        _reliabilityScoreMeta,
        reliabilityScore.isAcceptableOrUnknown(
          data['reliability_score']!,
          _reliabilityScoreMeta,
        ),
      );
    }
    if (data.containsKey('min_order_qty')) {
      context.handle(
        _minOrderQtyMeta,
        minOrderQty.isAcceptableOrUnknown(
          data['min_order_qty']!,
          _minOrderQtyMeta,
        ),
      );
    }
    if (data.containsKey('lead_time_days')) {
      context.handle(
        _leadTimeDaysMeta,
        leadTimeDays.isAcceptableOrUnknown(
          data['lead_time_days']!,
          _leadTimeDaysMeta,
        ),
      );
    }
    if (data.containsKey('certifications')) {
      context.handle(
        _certificationsMeta,
        certifications.isAcceptableOrUnknown(
          data['certifications']!,
          _certificationsMeta,
        ),
      );
    }
    if (data.containsKey('contact_email')) {
      context.handle(
        _contactEmailMeta,
        contactEmail.isAcceptableOrUnknown(
          data['contact_email']!,
          _contactEmailMeta,
        ),
      );
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
        _contactPhoneMeta,
        contactPhone.isAcceptableOrUnknown(
          data['contact_phone']!,
          _contactPhoneMeta,
        ),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('external_source')) {
      context.handle(
        _externalSourceMeta,
        externalSource.isAcceptableOrUnknown(
          data['external_source']!,
          _externalSourceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProducersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProducersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      reliabilityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reliability_score'],
      ),
      minOrderQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_order_qty'],
      ),
      leadTimeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lead_time_days'],
      ),
      certifications: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certifications'],
      ),
      contactEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_email'],
      ),
      contactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_phone'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      externalSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_source'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProducersTableTable createAlias(String alias) {
    return $ProducersTableTable(attachedDatabase, alias);
  }
}

class ProducersTableData extends DataClass
    implements Insertable<ProducersTableData> {
  final String id;
  final String businessId;
  final String name;
  final String? category;
  final String? country;
  final double? rating;
  final double? reliabilityScore;
  final double? minOrderQty;
  final int? leadTimeDays;
  final String? certifications;
  final String? contactEmail;
  final String? contactPhone;
  final String? externalId;
  final String? externalSource;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProducersTableData({
    required this.id,
    required this.businessId,
    required this.name,
    this.category,
    this.country,
    this.rating,
    this.reliabilityScore,
    this.minOrderQty,
    this.leadTimeDays,
    this.certifications,
    this.contactEmail,
    this.contactPhone,
    this.externalId,
    this.externalSource,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || reliabilityScore != null) {
      map['reliability_score'] = Variable<double>(reliabilityScore);
    }
    if (!nullToAbsent || minOrderQty != null) {
      map['min_order_qty'] = Variable<double>(minOrderQty);
    }
    if (!nullToAbsent || leadTimeDays != null) {
      map['lead_time_days'] = Variable<int>(leadTimeDays);
    }
    if (!nullToAbsent || certifications != null) {
      map['certifications'] = Variable<String>(certifications);
    }
    if (!nullToAbsent || contactEmail != null) {
      map['contact_email'] = Variable<String>(contactEmail);
    }
    if (!nullToAbsent || contactPhone != null) {
      map['contact_phone'] = Variable<String>(contactPhone);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || externalSource != null) {
      map['external_source'] = Variable<String>(externalSource);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProducersTableCompanion toCompanion(bool nullToAbsent) {
    return ProducersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      reliabilityScore: reliabilityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(reliabilityScore),
      minOrderQty: minOrderQty == null && nullToAbsent
          ? const Value.absent()
          : Value(minOrderQty),
      leadTimeDays: leadTimeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(leadTimeDays),
      certifications: certifications == null && nullToAbsent
          ? const Value.absent()
          : Value(certifications),
      contactEmail: contactEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(contactEmail),
      contactPhone: contactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPhone),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      externalSource: externalSource == null && nullToAbsent
          ? const Value.absent()
          : Value(externalSource),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProducersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProducersTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      country: serializer.fromJson<String?>(json['country']),
      rating: serializer.fromJson<double?>(json['rating']),
      reliabilityScore: serializer.fromJson<double?>(json['reliabilityScore']),
      minOrderQty: serializer.fromJson<double?>(json['minOrderQty']),
      leadTimeDays: serializer.fromJson<int?>(json['leadTimeDays']),
      certifications: serializer.fromJson<String?>(json['certifications']),
      contactEmail: serializer.fromJson<String?>(json['contactEmail']),
      contactPhone: serializer.fromJson<String?>(json['contactPhone']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      externalSource: serializer.fromJson<String?>(json['externalSource']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'country': serializer.toJson<String?>(country),
      'rating': serializer.toJson<double?>(rating),
      'reliabilityScore': serializer.toJson<double?>(reliabilityScore),
      'minOrderQty': serializer.toJson<double?>(minOrderQty),
      'leadTimeDays': serializer.toJson<int?>(leadTimeDays),
      'certifications': serializer.toJson<String?>(certifications),
      'contactEmail': serializer.toJson<String?>(contactEmail),
      'contactPhone': serializer.toJson<String?>(contactPhone),
      'externalId': serializer.toJson<String?>(externalId),
      'externalSource': serializer.toJson<String?>(externalSource),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProducersTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<double?> reliabilityScore = const Value.absent(),
    Value<double?> minOrderQty = const Value.absent(),
    Value<int?> leadTimeDays = const Value.absent(),
    Value<String?> certifications = const Value.absent(),
    Value<String?> contactEmail = const Value.absent(),
    Value<String?> contactPhone = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<String?> externalSource = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProducersTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    country: country.present ? country.value : this.country,
    rating: rating.present ? rating.value : this.rating,
    reliabilityScore: reliabilityScore.present
        ? reliabilityScore.value
        : this.reliabilityScore,
    minOrderQty: minOrderQty.present ? minOrderQty.value : this.minOrderQty,
    leadTimeDays: leadTimeDays.present ? leadTimeDays.value : this.leadTimeDays,
    certifications: certifications.present
        ? certifications.value
        : this.certifications,
    contactEmail: contactEmail.present ? contactEmail.value : this.contactEmail,
    contactPhone: contactPhone.present ? contactPhone.value : this.contactPhone,
    externalId: externalId.present ? externalId.value : this.externalId,
    externalSource: externalSource.present
        ? externalSource.value
        : this.externalSource,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProducersTableData copyWithCompanion(ProducersTableCompanion data) {
    return ProducersTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      country: data.country.present ? data.country.value : this.country,
      rating: data.rating.present ? data.rating.value : this.rating,
      reliabilityScore: data.reliabilityScore.present
          ? data.reliabilityScore.value
          : this.reliabilityScore,
      minOrderQty: data.minOrderQty.present
          ? data.minOrderQty.value
          : this.minOrderQty,
      leadTimeDays: data.leadTimeDays.present
          ? data.leadTimeDays.value
          : this.leadTimeDays,
      certifications: data.certifications.present
          ? data.certifications.value
          : this.certifications,
      contactEmail: data.contactEmail.present
          ? data.contactEmail.value
          : this.contactEmail,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      externalSource: data.externalSource.present
          ? data.externalSource.value
          : this.externalSource,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProducersTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('country: $country, ')
          ..write('rating: $rating, ')
          ..write('reliabilityScore: $reliabilityScore, ')
          ..write('minOrderQty: $minOrderQty, ')
          ..write('leadTimeDays: $leadTimeDays, ')
          ..write('certifications: $certifications, ')
          ..write('contactEmail: $contactEmail, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('externalId: $externalId, ')
          ..write('externalSource: $externalSource, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    category,
    country,
    rating,
    reliabilityScore,
    minOrderQty,
    leadTimeDays,
    certifications,
    contactEmail,
    contactPhone,
    externalId,
    externalSource,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProducersTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.category == this.category &&
          other.country == this.country &&
          other.rating == this.rating &&
          other.reliabilityScore == this.reliabilityScore &&
          other.minOrderQty == this.minOrderQty &&
          other.leadTimeDays == this.leadTimeDays &&
          other.certifications == this.certifications &&
          other.contactEmail == this.contactEmail &&
          other.contactPhone == this.contactPhone &&
          other.externalId == this.externalId &&
          other.externalSource == this.externalSource &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProducersTableCompanion extends UpdateCompanion<ProducersTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> category;
  final Value<String?> country;
  final Value<double?> rating;
  final Value<double?> reliabilityScore;
  final Value<double?> minOrderQty;
  final Value<int?> leadTimeDays;
  final Value<String?> certifications;
  final Value<String?> contactEmail;
  final Value<String?> contactPhone;
  final Value<String?> externalId;
  final Value<String?> externalSource;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProducersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.country = const Value.absent(),
    this.rating = const Value.absent(),
    this.reliabilityScore = const Value.absent(),
    this.minOrderQty = const Value.absent(),
    this.leadTimeDays = const Value.absent(),
    this.certifications = const Value.absent(),
    this.contactEmail = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.externalId = const Value.absent(),
    this.externalSource = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProducersTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.category = const Value.absent(),
    this.country = const Value.absent(),
    this.rating = const Value.absent(),
    this.reliabilityScore = const Value.absent(),
    this.minOrderQty = const Value.absent(),
    this.leadTimeDays = const Value.absent(),
    this.certifications = const Value.absent(),
    this.contactEmail = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.externalId = const Value.absent(),
    this.externalSource = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<ProducersTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? country,
    Expression<double>? rating,
    Expression<double>? reliabilityScore,
    Expression<double>? minOrderQty,
    Expression<int>? leadTimeDays,
    Expression<String>? certifications,
    Expression<String>? contactEmail,
    Expression<String>? contactPhone,
    Expression<String>? externalId,
    Expression<String>? externalSource,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (country != null) 'country': country,
      if (rating != null) 'rating': rating,
      if (reliabilityScore != null) 'reliability_score': reliabilityScore,
      if (minOrderQty != null) 'min_order_qty': minOrderQty,
      if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
      if (certifications != null) 'certifications': certifications,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (externalId != null) 'external_id': externalId,
      if (externalSource != null) 'external_source': externalSource,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProducersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? category,
    Value<String?>? country,
    Value<double?>? rating,
    Value<double?>? reliabilityScore,
    Value<double?>? minOrderQty,
    Value<int?>? leadTimeDays,
    Value<String?>? certifications,
    Value<String?>? contactEmail,
    Value<String?>? contactPhone,
    Value<String?>? externalId,
    Value<String?>? externalSource,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProducersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      category: category ?? this.category,
      country: country ?? this.country,
      rating: rating ?? this.rating,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      certifications: certifications ?? this.certifications,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      externalId: externalId ?? this.externalId,
      externalSource: externalSource ?? this.externalSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reliabilityScore.present) {
      map['reliability_score'] = Variable<double>(reliabilityScore.value);
    }
    if (minOrderQty.present) {
      map['min_order_qty'] = Variable<double>(minOrderQty.value);
    }
    if (leadTimeDays.present) {
      map['lead_time_days'] = Variable<int>(leadTimeDays.value);
    }
    if (certifications.present) {
      map['certifications'] = Variable<String>(certifications.value);
    }
    if (contactEmail.present) {
      map['contact_email'] = Variable<String>(contactEmail.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (externalSource.present) {
      map['external_source'] = Variable<String>(externalSource.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProducersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('country: $country, ')
          ..write('rating: $rating, ')
          ..write('reliabilityScore: $reliabilityScore, ')
          ..write('minOrderQty: $minOrderQty, ')
          ..write('leadTimeDays: $leadTimeDays, ')
          ..write('certifications: $certifications, ')
          ..write('contactEmail: $contactEmail, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('externalId: $externalId, ')
          ..write('externalSource: $externalSource, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costPerUnitMeta = const VerificationMeta(
    'costPerUnit',
  );
  @override
  late final GeneratedColumn<double> costPerUnit = GeneratedColumn<double>(
    'cost_per_unit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listPriceMeta = const VerificationMeta(
    'listPrice',
  );
  @override
  late final GeneratedColumn<double> listPrice = GeneratedColumn<double>(
    'list_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<double> currentPrice = GeneratedColumn<double>(
    'current_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profitPerUnitMeta = const VerificationMeta(
    'profitPerUnit',
  );
  @override
  late final GeneratedColumn<double> profitPerUnit = GeneratedColumn<double>(
    'profit_per_unit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalStockMeta = const VerificationMeta(
    'totalStock',
  );
  @override
  late final GeneratedColumn<double> totalStock = GeneratedColumn<double>(
    'total_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockByWarehouseMeta = const VerificationMeta(
    'stockByWarehouse',
  );
  @override
  late final GeneratedColumn<String> stockByWarehouse = GeneratedColumn<String>(
    'stock_by_warehouse',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockAlertLevelMeta = const VerificationMeta(
    'stockAlertLevel',
  );
  @override
  late final GeneratedColumn<double> stockAlertLevel = GeneratedColumn<double>(
    'stock_alert_level',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES producers_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _salesChannelsMeta = const VerificationMeta(
    'salesChannels',
  );
  @override
  late final GeneratedColumn<String> salesChannels = GeneratedColumn<String>(
    'sales_channels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    sku,
    name,
    description,
    category,
    costPerUnit,
    listPrice,
    currentPrice,
    profitPerUnit,
    totalStock,
    stockByWarehouse,
    stockAlertLevel,
    supplierId,
    salesChannels,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('cost_per_unit')) {
      context.handle(
        _costPerUnitMeta,
        costPerUnit.isAcceptableOrUnknown(
          data['cost_per_unit']!,
          _costPerUnitMeta,
        ),
      );
    }
    if (data.containsKey('list_price')) {
      context.handle(
        _listPriceMeta,
        listPrice.isAcceptableOrUnknown(data['list_price']!, _listPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_listPriceMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    }
    if (data.containsKey('profit_per_unit')) {
      context.handle(
        _profitPerUnitMeta,
        profitPerUnit.isAcceptableOrUnknown(
          data['profit_per_unit']!,
          _profitPerUnitMeta,
        ),
      );
    }
    if (data.containsKey('total_stock')) {
      context.handle(
        _totalStockMeta,
        totalStock.isAcceptableOrUnknown(data['total_stock']!, _totalStockMeta),
      );
    }
    if (data.containsKey('stock_by_warehouse')) {
      context.handle(
        _stockByWarehouseMeta,
        stockByWarehouse.isAcceptableOrUnknown(
          data['stock_by_warehouse']!,
          _stockByWarehouseMeta,
        ),
      );
    }
    if (data.containsKey('stock_alert_level')) {
      context.handle(
        _stockAlertLevelMeta,
        stockAlertLevel.isAcceptableOrUnknown(
          data['stock_alert_level']!,
          _stockAlertLevelMeta,
        ),
      );
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('sales_channels')) {
      context.handle(
        _salesChannelsMeta,
        salesChannels.isAcceptableOrUnknown(
          data['sales_channels']!,
          _salesChannelsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      costPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_per_unit'],
      ),
      listPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}list_price'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_price'],
      ),
      profitPerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_per_unit'],
      ),
      totalStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_stock'],
      )!,
      stockByWarehouse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_by_warehouse'],
      ),
      stockAlertLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_alert_level'],
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      salesChannels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sales_channels'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String businessId;
  final String sku;
  final String name;
  final String? description;
  final String? category;
  final double? costPerUnit;
  final double listPrice;
  final double? currentPrice;
  final double? profitPerUnit;
  final double totalStock;
  final String? stockByWarehouse;
  final double? stockAlertLevel;
  final String? supplierId;
  final String? salesChannels;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductsTableData({
    required this.id,
    required this.businessId,
    required this.sku,
    required this.name,
    this.description,
    this.category,
    this.costPerUnit,
    required this.listPrice,
    this.currentPrice,
    this.profitPerUnit,
    required this.totalStock,
    this.stockByWarehouse,
    this.stockAlertLevel,
    this.supplierId,
    this.salesChannels,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || costPerUnit != null) {
      map['cost_per_unit'] = Variable<double>(costPerUnit);
    }
    map['list_price'] = Variable<double>(listPrice);
    if (!nullToAbsent || currentPrice != null) {
      map['current_price'] = Variable<double>(currentPrice);
    }
    if (!nullToAbsent || profitPerUnit != null) {
      map['profit_per_unit'] = Variable<double>(profitPerUnit);
    }
    map['total_stock'] = Variable<double>(totalStock);
    if (!nullToAbsent || stockByWarehouse != null) {
      map['stock_by_warehouse'] = Variable<String>(stockByWarehouse);
    }
    if (!nullToAbsent || stockAlertLevel != null) {
      map['stock_alert_level'] = Variable<double>(stockAlertLevel);
    }
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || salesChannels != null) {
      map['sales_channels'] = Variable<String>(salesChannels);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      sku: Value(sku),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      costPerUnit: costPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(costPerUnit),
      listPrice: Value(listPrice),
      currentPrice: currentPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPrice),
      profitPerUnit: profitPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(profitPerUnit),
      totalStock: Value(totalStock),
      stockByWarehouse: stockByWarehouse == null && nullToAbsent
          ? const Value.absent()
          : Value(stockByWarehouse),
      stockAlertLevel: stockAlertLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(stockAlertLevel),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      salesChannels: salesChannels == null && nullToAbsent
          ? const Value.absent()
          : Value(salesChannels),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      costPerUnit: serializer.fromJson<double?>(json['costPerUnit']),
      listPrice: serializer.fromJson<double>(json['listPrice']),
      currentPrice: serializer.fromJson<double?>(json['currentPrice']),
      profitPerUnit: serializer.fromJson<double?>(json['profitPerUnit']),
      totalStock: serializer.fromJson<double>(json['totalStock']),
      stockByWarehouse: serializer.fromJson<String?>(json['stockByWarehouse']),
      stockAlertLevel: serializer.fromJson<double?>(json['stockAlertLevel']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      salesChannels: serializer.fromJson<String?>(json['salesChannels']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'costPerUnit': serializer.toJson<double?>(costPerUnit),
      'listPrice': serializer.toJson<double>(listPrice),
      'currentPrice': serializer.toJson<double?>(currentPrice),
      'profitPerUnit': serializer.toJson<double?>(profitPerUnit),
      'totalStock': serializer.toJson<double>(totalStock),
      'stockByWarehouse': serializer.toJson<String?>(stockByWarehouse),
      'stockAlertLevel': serializer.toJson<double?>(stockAlertLevel),
      'supplierId': serializer.toJson<String?>(supplierId),
      'salesChannels': serializer.toJson<String?>(salesChannels),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductsTableData copyWith({
    String? id,
    String? businessId,
    String? sku,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<double?> costPerUnit = const Value.absent(),
    double? listPrice,
    Value<double?> currentPrice = const Value.absent(),
    Value<double?> profitPerUnit = const Value.absent(),
    double? totalStock,
    Value<String?> stockByWarehouse = const Value.absent(),
    Value<double?> stockAlertLevel = const Value.absent(),
    Value<String?> supplierId = const Value.absent(),
    Value<String?> salesChannels = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    costPerUnit: costPerUnit.present ? costPerUnit.value : this.costPerUnit,
    listPrice: listPrice ?? this.listPrice,
    currentPrice: currentPrice.present ? currentPrice.value : this.currentPrice,
    profitPerUnit: profitPerUnit.present
        ? profitPerUnit.value
        : this.profitPerUnit,
    totalStock: totalStock ?? this.totalStock,
    stockByWarehouse: stockByWarehouse.present
        ? stockByWarehouse.value
        : this.stockByWarehouse,
    stockAlertLevel: stockAlertLevel.present
        ? stockAlertLevel.value
        : this.stockAlertLevel,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    salesChannels: salesChannels.present
        ? salesChannels.value
        : this.salesChannels,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      costPerUnit: data.costPerUnit.present
          ? data.costPerUnit.value
          : this.costPerUnit,
      listPrice: data.listPrice.present ? data.listPrice.value : this.listPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      profitPerUnit: data.profitPerUnit.present
          ? data.profitPerUnit.value
          : this.profitPerUnit,
      totalStock: data.totalStock.present
          ? data.totalStock.value
          : this.totalStock,
      stockByWarehouse: data.stockByWarehouse.present
          ? data.stockByWarehouse.value
          : this.stockByWarehouse,
      stockAlertLevel: data.stockAlertLevel.present
          ? data.stockAlertLevel.value
          : this.stockAlertLevel,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      salesChannels: data.salesChannels.present
          ? data.salesChannels.value
          : this.salesChannels,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('costPerUnit: $costPerUnit, ')
          ..write('listPrice: $listPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('profitPerUnit: $profitPerUnit, ')
          ..write('totalStock: $totalStock, ')
          ..write('stockByWarehouse: $stockByWarehouse, ')
          ..write('stockAlertLevel: $stockAlertLevel, ')
          ..write('supplierId: $supplierId, ')
          ..write('salesChannels: $salesChannels, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    sku,
    name,
    description,
    category,
    costPerUnit,
    listPrice,
    currentPrice,
    profitPerUnit,
    totalStock,
    stockByWarehouse,
    stockAlertLevel,
    supplierId,
    salesChannels,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.costPerUnit == this.costPerUnit &&
          other.listPrice == this.listPrice &&
          other.currentPrice == this.currentPrice &&
          other.profitPerUnit == this.profitPerUnit &&
          other.totalStock == this.totalStock &&
          other.stockByWarehouse == this.stockByWarehouse &&
          other.stockAlertLevel == this.stockAlertLevel &&
          other.supplierId == this.supplierId &&
          other.salesChannels == this.salesChannels &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> sku;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> category;
  final Value<double?> costPerUnit;
  final Value<double> listPrice;
  final Value<double?> currentPrice;
  final Value<double?> profitPerUnit;
  final Value<double> totalStock;
  final Value<String?> stockByWarehouse;
  final Value<double?> stockAlertLevel;
  final Value<String?> supplierId;
  final Value<String?> salesChannels;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.costPerUnit = const Value.absent(),
    this.listPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.profitPerUnit = const Value.absent(),
    this.totalStock = const Value.absent(),
    this.stockByWarehouse = const Value.absent(),
    this.stockAlertLevel = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.salesChannels = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String businessId,
    required String sku,
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.costPerUnit = const Value.absent(),
    required double listPrice,
    this.currentPrice = const Value.absent(),
    this.profitPerUnit = const Value.absent(),
    this.totalStock = const Value.absent(),
    this.stockByWarehouse = const Value.absent(),
    this.stockAlertLevel = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.salesChannels = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       sku = Value(sku),
       name = Value(name),
       listPrice = Value(listPrice);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<double>? costPerUnit,
    Expression<double>? listPrice,
    Expression<double>? currentPrice,
    Expression<double>? profitPerUnit,
    Expression<double>? totalStock,
    Expression<String>? stockByWarehouse,
    Expression<double>? stockAlertLevel,
    Expression<String>? supplierId,
    Expression<String>? salesChannels,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (costPerUnit != null) 'cost_per_unit': costPerUnit,
      if (listPrice != null) 'list_price': listPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (profitPerUnit != null) 'profit_per_unit': profitPerUnit,
      if (totalStock != null) 'total_stock': totalStock,
      if (stockByWarehouse != null) 'stock_by_warehouse': stockByWarehouse,
      if (stockAlertLevel != null) 'stock_alert_level': stockAlertLevel,
      if (supplierId != null) 'supplier_id': supplierId,
      if (salesChannels != null) 'sales_channels': salesChannels,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? sku,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? category,
    Value<double?>? costPerUnit,
    Value<double>? listPrice,
    Value<double?>? currentPrice,
    Value<double?>? profitPerUnit,
    Value<double>? totalStock,
    Value<String?>? stockByWarehouse,
    Value<double?>? stockAlertLevel,
    Value<String?>? supplierId,
    Value<String?>? salesChannels,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      listPrice: listPrice ?? this.listPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      profitPerUnit: profitPerUnit ?? this.profitPerUnit,
      totalStock: totalStock ?? this.totalStock,
      stockByWarehouse: stockByWarehouse ?? this.stockByWarehouse,
      stockAlertLevel: stockAlertLevel ?? this.stockAlertLevel,
      supplierId: supplierId ?? this.supplierId,
      salesChannels: salesChannels ?? this.salesChannels,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (costPerUnit.present) {
      map['cost_per_unit'] = Variable<double>(costPerUnit.value);
    }
    if (listPrice.present) {
      map['list_price'] = Variable<double>(listPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<double>(currentPrice.value);
    }
    if (profitPerUnit.present) {
      map['profit_per_unit'] = Variable<double>(profitPerUnit.value);
    }
    if (totalStock.present) {
      map['total_stock'] = Variable<double>(totalStock.value);
    }
    if (stockByWarehouse.present) {
      map['stock_by_warehouse'] = Variable<String>(stockByWarehouse.value);
    }
    if (stockAlertLevel.present) {
      map['stock_alert_level'] = Variable<double>(stockAlertLevel.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (salesChannels.present) {
      map['sales_channels'] = Variable<String>(salesChannels.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('costPerUnit: $costPerUnit, ')
          ..write('listPrice: $listPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('profitPerUnit: $profitPerUnit, ')
          ..write('totalStock: $totalStock, ')
          ..write('stockByWarehouse: $stockByWarehouse, ')
          ..write('stockAlertLevel: $stockAlertLevel, ')
          ..write('supplierId: $supplierId, ')
          ..write('salesChannels: $salesChannels, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalSourceMeta = const VerificationMeta(
    'externalSource',
  );
  @override
  late final GeneratedColumn<String> externalSource = GeneratedColumn<String>(
    'external_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentsMeta = const VerificationMeta(
    'segments',
  );
  @override
  late final GeneratedColumn<String> segments = GeneratedColumn<String>(
    'segments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lifetimeValueMeta = const VerificationMeta(
    'lifetimeValue',
  );
  @override
  late final GeneratedColumn<double> lifetimeValue = GeneratedColumn<double>(
    'lifetime_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderCountMeta = const VerificationMeta(
    'orderCount',
  );
  @override
  late final GeneratedColumn<int> orderCount = GeneratedColumn<int>(
    'order_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalSpentMeta = const VerificationMeta(
    'totalSpent',
  );
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
    'total_spent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgOrderValueMeta = const VerificationMeta(
    'avgOrderValue',
  );
  @override
  late final GeneratedColumn<double> avgOrderValue = GeneratedColumn<double>(
    'avg_order_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOrderDateMeta = const VerificationMeta(
    'lastOrderDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastOrderDate =
      GeneratedColumn<DateTime>(
        'last_order_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _churnRiskMeta = const VerificationMeta(
    'churnRisk',
  );
  @override
  late final GeneratedColumn<double> churnRisk = GeneratedColumn<double>(
    'churn_risk',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    externalId,
    externalSource,
    name,
    email,
    phone,
    address,
    city,
    country,
    segments,
    lifetimeValue,
    orderCount,
    totalSpent,
    avgOrderValue,
    lastOrderDate,
    churnRisk,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('external_source')) {
      context.handle(
        _externalSourceMeta,
        externalSource.isAcceptableOrUnknown(
          data['external_source']!,
          _externalSourceMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('segments')) {
      context.handle(
        _segmentsMeta,
        segments.isAcceptableOrUnknown(data['segments']!, _segmentsMeta),
      );
    }
    if (data.containsKey('lifetime_value')) {
      context.handle(
        _lifetimeValueMeta,
        lifetimeValue.isAcceptableOrUnknown(
          data['lifetime_value']!,
          _lifetimeValueMeta,
        ),
      );
    }
    if (data.containsKey('order_count')) {
      context.handle(
        _orderCountMeta,
        orderCount.isAcceptableOrUnknown(data['order_count']!, _orderCountMeta),
      );
    }
    if (data.containsKey('total_spent')) {
      context.handle(
        _totalSpentMeta,
        totalSpent.isAcceptableOrUnknown(data['total_spent']!, _totalSpentMeta),
      );
    }
    if (data.containsKey('avg_order_value')) {
      context.handle(
        _avgOrderValueMeta,
        avgOrderValue.isAcceptableOrUnknown(
          data['avg_order_value']!,
          _avgOrderValueMeta,
        ),
      );
    }
    if (data.containsKey('last_order_date')) {
      context.handle(
        _lastOrderDateMeta,
        lastOrderDate.isAcceptableOrUnknown(
          data['last_order_date']!,
          _lastOrderDateMeta,
        ),
      );
    }
    if (data.containsKey('churn_risk')) {
      context.handle(
        _churnRiskMeta,
        churnRisk.isAcceptableOrUnknown(data['churn_risk']!, _churnRiskMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      externalSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_source'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      segments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments'],
      ),
      lifetimeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lifetime_value'],
      ),
      orderCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_count'],
      ),
      totalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_spent'],
      ),
      avgOrderValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_order_value'],
      ),
      lastOrderDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_order_date'],
      ),
      churnRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}churn_risk'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomersTableData extends DataClass
    implements Insertable<CustomersTableData> {
  final String id;
  final String businessId;
  final String? externalId;
  final String? externalSource;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? segments;
  final double? lifetimeValue;
  final int? orderCount;
  final double? totalSpent;
  final double? avgOrderValue;
  final DateTime? lastOrderDate;
  final double? churnRisk;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomersTableData({
    required this.id,
    required this.businessId,
    this.externalId,
    this.externalSource,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.segments,
    this.lifetimeValue,
    this.orderCount,
    this.totalSpent,
    this.avgOrderValue,
    this.lastOrderDate,
    this.churnRisk,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || externalSource != null) {
      map['external_source'] = Variable<String>(externalSource);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || segments != null) {
      map['segments'] = Variable<String>(segments);
    }
    if (!nullToAbsent || lifetimeValue != null) {
      map['lifetime_value'] = Variable<double>(lifetimeValue);
    }
    if (!nullToAbsent || orderCount != null) {
      map['order_count'] = Variable<int>(orderCount);
    }
    if (!nullToAbsent || totalSpent != null) {
      map['total_spent'] = Variable<double>(totalSpent);
    }
    if (!nullToAbsent || avgOrderValue != null) {
      map['avg_order_value'] = Variable<double>(avgOrderValue);
    }
    if (!nullToAbsent || lastOrderDate != null) {
      map['last_order_date'] = Variable<DateTime>(lastOrderDate);
    }
    if (!nullToAbsent || churnRisk != null) {
      map['churn_risk'] = Variable<double>(churnRisk);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      externalSource: externalSource == null && nullToAbsent
          ? const Value.absent()
          : Value(externalSource),
      name: Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      segments: segments == null && nullToAbsent
          ? const Value.absent()
          : Value(segments),
      lifetimeValue: lifetimeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(lifetimeValue),
      orderCount: orderCount == null && nullToAbsent
          ? const Value.absent()
          : Value(orderCount),
      totalSpent: totalSpent == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSpent),
      avgOrderValue: avgOrderValue == null && nullToAbsent
          ? const Value.absent()
          : Value(avgOrderValue),
      lastOrderDate: lastOrderDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOrderDate),
      churnRisk: churnRisk == null && nullToAbsent
          ? const Value.absent()
          : Value(churnRisk),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      externalSource: serializer.fromJson<String?>(json['externalSource']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      city: serializer.fromJson<String?>(json['city']),
      country: serializer.fromJson<String?>(json['country']),
      segments: serializer.fromJson<String?>(json['segments']),
      lifetimeValue: serializer.fromJson<double?>(json['lifetimeValue']),
      orderCount: serializer.fromJson<int?>(json['orderCount']),
      totalSpent: serializer.fromJson<double?>(json['totalSpent']),
      avgOrderValue: serializer.fromJson<double?>(json['avgOrderValue']),
      lastOrderDate: serializer.fromJson<DateTime?>(json['lastOrderDate']),
      churnRisk: serializer.fromJson<double?>(json['churnRisk']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'externalId': serializer.toJson<String?>(externalId),
      'externalSource': serializer.toJson<String?>(externalSource),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'city': serializer.toJson<String?>(city),
      'country': serializer.toJson<String?>(country),
      'segments': serializer.toJson<String?>(segments),
      'lifetimeValue': serializer.toJson<double?>(lifetimeValue),
      'orderCount': serializer.toJson<int?>(orderCount),
      'totalSpent': serializer.toJson<double?>(totalSpent),
      'avgOrderValue': serializer.toJson<double?>(avgOrderValue),
      'lastOrderDate': serializer.toJson<DateTime?>(lastOrderDate),
      'churnRisk': serializer.toJson<double?>(churnRisk),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomersTableData copyWith({
    String? id,
    String? businessId,
    Value<String?> externalId = const Value.absent(),
    Value<String?> externalSource = const Value.absent(),
    String? name,
    Value<String?> email = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> segments = const Value.absent(),
    Value<double?> lifetimeValue = const Value.absent(),
    Value<int?> orderCount = const Value.absent(),
    Value<double?> totalSpent = const Value.absent(),
    Value<double?> avgOrderValue = const Value.absent(),
    Value<DateTime?> lastOrderDate = const Value.absent(),
    Value<double?> churnRisk = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomersTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    externalId: externalId.present ? externalId.value : this.externalId,
    externalSource: externalSource.present
        ? externalSource.value
        : this.externalSource,
    name: name ?? this.name,
    email: email.present ? email.value : this.email,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    city: city.present ? city.value : this.city,
    country: country.present ? country.value : this.country,
    segments: segments.present ? segments.value : this.segments,
    lifetimeValue: lifetimeValue.present
        ? lifetimeValue.value
        : this.lifetimeValue,
    orderCount: orderCount.present ? orderCount.value : this.orderCount,
    totalSpent: totalSpent.present ? totalSpent.value : this.totalSpent,
    avgOrderValue: avgOrderValue.present
        ? avgOrderValue.value
        : this.avgOrderValue,
    lastOrderDate: lastOrderDate.present
        ? lastOrderDate.value
        : this.lastOrderDate,
    churnRisk: churnRisk.present ? churnRisk.value : this.churnRisk,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomersTableData copyWithCompanion(CustomersTableCompanion data) {
    return CustomersTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      externalSource: data.externalSource.present
          ? data.externalSource.value
          : this.externalSource,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      country: data.country.present ? data.country.value : this.country,
      segments: data.segments.present ? data.segments.value : this.segments,
      lifetimeValue: data.lifetimeValue.present
          ? data.lifetimeValue.value
          : this.lifetimeValue,
      orderCount: data.orderCount.present
          ? data.orderCount.value
          : this.orderCount,
      totalSpent: data.totalSpent.present
          ? data.totalSpent.value
          : this.totalSpent,
      avgOrderValue: data.avgOrderValue.present
          ? data.avgOrderValue.value
          : this.avgOrderValue,
      lastOrderDate: data.lastOrderDate.present
          ? data.lastOrderDate.value
          : this.lastOrderDate,
      churnRisk: data.churnRisk.present ? data.churnRisk.value : this.churnRisk,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('externalId: $externalId, ')
          ..write('externalSource: $externalSource, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('country: $country, ')
          ..write('segments: $segments, ')
          ..write('lifetimeValue: $lifetimeValue, ')
          ..write('orderCount: $orderCount, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('avgOrderValue: $avgOrderValue, ')
          ..write('lastOrderDate: $lastOrderDate, ')
          ..write('churnRisk: $churnRisk, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    externalId,
    externalSource,
    name,
    email,
    phone,
    address,
    city,
    country,
    segments,
    lifetimeValue,
    orderCount,
    totalSpent,
    avgOrderValue,
    lastOrderDate,
    churnRisk,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.externalId == this.externalId &&
          other.externalSource == this.externalSource &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.city == this.city &&
          other.country == this.country &&
          other.segments == this.segments &&
          other.lifetimeValue == this.lifetimeValue &&
          other.orderCount == this.orderCount &&
          other.totalSpent == this.totalSpent &&
          other.avgOrderValue == this.avgOrderValue &&
          other.lastOrderDate == this.lastOrderDate &&
          other.churnRisk == this.churnRisk &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersTableCompanion extends UpdateCompanion<CustomersTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> externalId;
  final Value<String?> externalSource;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> city;
  final Value<String?> country;
  final Value<String?> segments;
  final Value<double?> lifetimeValue;
  final Value<int?> orderCount;
  final Value<double?> totalSpent;
  final Value<double?> avgOrderValue;
  final Value<DateTime?> lastOrderDate;
  final Value<double?> churnRisk;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.externalSource = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.country = const Value.absent(),
    this.segments = const Value.absent(),
    this.lifetimeValue = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.avgOrderValue = const Value.absent(),
    this.lastOrderDate = const Value.absent(),
    this.churnRisk = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    required String id,
    required String businessId,
    this.externalId = const Value.absent(),
    this.externalSource = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.country = const Value.absent(),
    this.segments = const Value.absent(),
    this.lifetimeValue = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.avgOrderValue = const Value.absent(),
    this.lastOrderDate = const Value.absent(),
    this.churnRisk = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<CustomersTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? externalId,
    Expression<String>? externalSource,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? country,
    Expression<String>? segments,
    Expression<double>? lifetimeValue,
    Expression<int>? orderCount,
    Expression<double>? totalSpent,
    Expression<double>? avgOrderValue,
    Expression<DateTime>? lastOrderDate,
    Expression<double>? churnRisk,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (externalId != null) 'external_id': externalId,
      if (externalSource != null) 'external_source': externalSource,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (segments != null) 'segments': segments,
      if (lifetimeValue != null) 'lifetime_value': lifetimeValue,
      if (orderCount != null) 'order_count': orderCount,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (avgOrderValue != null) 'avg_order_value': avgOrderValue,
      if (lastOrderDate != null) 'last_order_date': lastOrderDate,
      if (churnRisk != null) 'churn_risk': churnRisk,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? externalId,
    Value<String?>? externalSource,
    Value<String>? name,
    Value<String?>? email,
    Value<String?>? phone,
    Value<String?>? address,
    Value<String?>? city,
    Value<String?>? country,
    Value<String?>? segments,
    Value<double?>? lifetimeValue,
    Value<int?>? orderCount,
    Value<double?>? totalSpent,
    Value<double?>? avgOrderValue,
    Value<DateTime?>? lastOrderDate,
    Value<double?>? churnRisk,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      externalId: externalId ?? this.externalId,
      externalSource: externalSource ?? this.externalSource,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      segments: segments ?? this.segments,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      avgOrderValue: avgOrderValue ?? this.avgOrderValue,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      churnRisk: churnRisk ?? this.churnRisk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (externalSource.present) {
      map['external_source'] = Variable<String>(externalSource.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (segments.present) {
      map['segments'] = Variable<String>(segments.value);
    }
    if (lifetimeValue.present) {
      map['lifetime_value'] = Variable<double>(lifetimeValue.value);
    }
    if (orderCount.present) {
      map['order_count'] = Variable<int>(orderCount.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (avgOrderValue.present) {
      map['avg_order_value'] = Variable<double>(avgOrderValue.value);
    }
    if (lastOrderDate.present) {
      map['last_order_date'] = Variable<DateTime>(lastOrderDate.value);
    }
    if (churnRisk.present) {
      map['churn_risk'] = Variable<double>(churnRisk.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('externalId: $externalId, ')
          ..write('externalSource: $externalSource, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('country: $country, ')
          ..write('segments: $segments, ')
          ..write('lifetimeValue: $lifetimeValue, ')
          ..write('orderCount: $orderCount, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('avgOrderValue: $avgOrderValue, ')
          ..write('lastOrderDate: $lastOrderDate, ')
          ..write('churnRisk: $churnRisk, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTableTable extends ChannelsTable
    with TableInfo<$ChannelsTableTable, ChannelsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformIdMeta = const VerificationMeta(
    'platformId',
  );
  @override
  late final GeneratedColumn<String> platformId = GeneratedColumn<String>(
    'platform_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isConnectedMeta = const VerificationMeta(
    'isConnected',
  );
  @override
  late final GeneratedColumn<bool> isConnected = GeneratedColumn<bool>(
    'is_connected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_connected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _credentialsEncryptedMeta =
      const VerificationMeta('credentialsEncrypted');
  @override
  late final GeneratedColumn<String> credentialsEncrypted =
      GeneratedColumn<String>(
        'credentials_encrypted',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _metricsMeta = const VerificationMeta(
    'metrics',
  );
  @override
  late final GeneratedColumn<String> metrics = GeneratedColumn<String>(
    'metrics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncDateMeta = const VerificationMeta(
    'lastSyncDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncDate = GeneratedColumn<DateTime>(
    'last_sync_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    type,
    platformId,
    status,
    isConnected,
    credentialsEncrypted,
    metrics,
    lastSyncDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('platform_id')) {
      context.handle(
        _platformIdMeta,
        platformId.isAcceptableOrUnknown(data['platform_id']!, _platformIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_connected')) {
      context.handle(
        _isConnectedMeta,
        isConnected.isAcceptableOrUnknown(
          data['is_connected']!,
          _isConnectedMeta,
        ),
      );
    }
    if (data.containsKey('credentials_encrypted')) {
      context.handle(
        _credentialsEncryptedMeta,
        credentialsEncrypted.isAcceptableOrUnknown(
          data['credentials_encrypted']!,
          _credentialsEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('metrics')) {
      context.handle(
        _metricsMeta,
        metrics.isAcceptableOrUnknown(data['metrics']!, _metricsMeta),
      );
    }
    if (data.containsKey('last_sync_date')) {
      context.handle(
        _lastSyncDateMeta,
        lastSyncDate.isAcceptableOrUnknown(
          data['last_sync_date']!,
          _lastSyncDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChannelsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      platformId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      isConnected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_connected'],
      )!,
      credentialsEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credentials_encrypted'],
      ),
      metrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metrics'],
      ),
      lastSyncDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChannelsTableTable createAlias(String alias) {
    return $ChannelsTableTable(attachedDatabase, alias);
  }
}

class ChannelsTableData extends DataClass
    implements Insertable<ChannelsTableData> {
  final String id;
  final String businessId;
  final String name;
  final String type;
  final String? platformId;
  final String? status;
  final bool isConnected;
  final String? credentialsEncrypted;
  final String? metrics;
  final DateTime? lastSyncDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChannelsTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    this.platformId,
    this.status,
    required this.isConnected,
    this.credentialsEncrypted,
    this.metrics,
    this.lastSyncDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || platformId != null) {
      map['platform_id'] = Variable<String>(platformId);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['is_connected'] = Variable<bool>(isConnected);
    if (!nullToAbsent || credentialsEncrypted != null) {
      map['credentials_encrypted'] = Variable<String>(credentialsEncrypted);
    }
    if (!nullToAbsent || metrics != null) {
      map['metrics'] = Variable<String>(metrics);
    }
    if (!nullToAbsent || lastSyncDate != null) {
      map['last_sync_date'] = Variable<DateTime>(lastSyncDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChannelsTableCompanion toCompanion(bool nullToAbsent) {
    return ChannelsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      type: Value(type),
      platformId: platformId == null && nullToAbsent
          ? const Value.absent()
          : Value(platformId),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      isConnected: Value(isConnected),
      credentialsEncrypted: credentialsEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialsEncrypted),
      metrics: metrics == null && nullToAbsent
          ? const Value.absent()
          : Value(metrics),
      lastSyncDate: lastSyncDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChannelsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      platformId: serializer.fromJson<String?>(json['platformId']),
      status: serializer.fromJson<String?>(json['status']),
      isConnected: serializer.fromJson<bool>(json['isConnected']),
      credentialsEncrypted: serializer.fromJson<String?>(
        json['credentialsEncrypted'],
      ),
      metrics: serializer.fromJson<String?>(json['metrics']),
      lastSyncDate: serializer.fromJson<DateTime?>(json['lastSyncDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'platformId': serializer.toJson<String?>(platformId),
      'status': serializer.toJson<String?>(status),
      'isConnected': serializer.toJson<bool>(isConnected),
      'credentialsEncrypted': serializer.toJson<String?>(credentialsEncrypted),
      'metrics': serializer.toJson<String?>(metrics),
      'lastSyncDate': serializer.toJson<DateTime?>(lastSyncDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChannelsTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? type,
    Value<String?> platformId = const Value.absent(),
    Value<String?> status = const Value.absent(),
    bool? isConnected,
    Value<String?> credentialsEncrypted = const Value.absent(),
    Value<String?> metrics = const Value.absent(),
    Value<DateTime?> lastSyncDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChannelsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    type: type ?? this.type,
    platformId: platformId.present ? platformId.value : this.platformId,
    status: status.present ? status.value : this.status,
    isConnected: isConnected ?? this.isConnected,
    credentialsEncrypted: credentialsEncrypted.present
        ? credentialsEncrypted.value
        : this.credentialsEncrypted,
    metrics: metrics.present ? metrics.value : this.metrics,
    lastSyncDate: lastSyncDate.present ? lastSyncDate.value : this.lastSyncDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChannelsTableData copyWithCompanion(ChannelsTableCompanion data) {
    return ChannelsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      platformId: data.platformId.present
          ? data.platformId.value
          : this.platformId,
      status: data.status.present ? data.status.value : this.status,
      isConnected: data.isConnected.present
          ? data.isConnected.value
          : this.isConnected,
      credentialsEncrypted: data.credentialsEncrypted.present
          ? data.credentialsEncrypted.value
          : this.credentialsEncrypted,
      metrics: data.metrics.present ? data.metrics.value : this.metrics,
      lastSyncDate: data.lastSyncDate.present
          ? data.lastSyncDate.value
          : this.lastSyncDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('platformId: $platformId, ')
          ..write('status: $status, ')
          ..write('isConnected: $isConnected, ')
          ..write('credentialsEncrypted: $credentialsEncrypted, ')
          ..write('metrics: $metrics, ')
          ..write('lastSyncDate: $lastSyncDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    type,
    platformId,
    status,
    isConnected,
    credentialsEncrypted,
    metrics,
    lastSyncDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.type == this.type &&
          other.platformId == this.platformId &&
          other.status == this.status &&
          other.isConnected == this.isConnected &&
          other.credentialsEncrypted == this.credentialsEncrypted &&
          other.metrics == this.metrics &&
          other.lastSyncDate == this.lastSyncDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChannelsTableCompanion extends UpdateCompanion<ChannelsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> platformId;
  final Value<String?> status;
  final Value<bool> isConnected;
  final Value<String?> credentialsEncrypted;
  final Value<String?> metrics;
  final Value<DateTime?> lastSyncDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChannelsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.platformId = const Value.absent(),
    this.status = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.credentialsEncrypted = const Value.absent(),
    this.metrics = const Value.absent(),
    this.lastSyncDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    required String type,
    this.platformId = const Value.absent(),
    this.status = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.credentialsEncrypted = const Value.absent(),
    this.metrics = const Value.absent(),
    this.lastSyncDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       type = Value(type);
  static Insertable<ChannelsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? platformId,
    Expression<String>? status,
    Expression<bool>? isConnected,
    Expression<String>? credentialsEncrypted,
    Expression<String>? metrics,
    Expression<DateTime>? lastSyncDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (platformId != null) 'platform_id': platformId,
      if (status != null) 'status': status,
      if (isConnected != null) 'is_connected': isConnected,
      if (credentialsEncrypted != null)
        'credentials_encrypted': credentialsEncrypted,
      if (metrics != null) 'metrics': metrics,
      if (lastSyncDate != null) 'last_sync_date': lastSyncDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? platformId,
    Value<String?>? status,
    Value<bool>? isConnected,
    Value<String?>? credentialsEncrypted,
    Value<String?>? metrics,
    Value<DateTime?>? lastSyncDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChannelsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      platformId: platformId ?? this.platformId,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      credentialsEncrypted: credentialsEncrypted ?? this.credentialsEncrypted,
      metrics: metrics ?? this.metrics,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (platformId.present) {
      map['platform_id'] = Variable<String>(platformId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isConnected.present) {
      map['is_connected'] = Variable<bool>(isConnected.value);
    }
    if (credentialsEncrypted.present) {
      map['credentials_encrypted'] = Variable<String>(
        credentialsEncrypted.value,
      );
    }
    if (metrics.present) {
      map['metrics'] = Variable<String>(metrics.value);
    }
    if (lastSyncDate.present) {
      map['last_sync_date'] = Variable<DateTime>(lastSyncDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('platformId: $platformId, ')
          ..write('status: $status, ')
          ..write('isConnected: $isConnected, ')
          ..write('credentialsEncrypted: $credentialsEncrypted, ')
          ..write('metrics: $metrics, ')
          ..write('lastSyncDate: $lastSyncDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTableTable extends OrdersTable
    with TableInfo<$OrdersTableTable, OrdersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers_table (id)',
    ),
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels_table (id)',
    ),
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderDateMeta = const VerificationMeta(
    'orderDate',
  );
  @override
  late final GeneratedColumn<DateTime> orderDate = GeneratedColumn<DateTime>(
    'order_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalQuantityMeta = const VerificationMeta(
    'totalQuantity',
  );
  @override
  late final GeneratedColumn<int> totalQuantity = GeneratedColumn<int>(
    'total_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shippingCostMeta = const VerificationMeta(
    'shippingCost',
  );
  @override
  late final GeneratedColumn<double> shippingCost = GeneratedColumn<double>(
    'shipping_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    customerId,
    channelId,
    orderNumber,
    orderDate,
    totalQuantity,
    subtotal,
    discount,
    shippingCost,
    totalAmount,
    status,
    paymentStatus,
    items,
    externalId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrdersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    }
    if (data.containsKey('order_date')) {
      context.handle(
        _orderDateMeta,
        orderDate.isAcceptableOrUnknown(data['order_date']!, _orderDateMeta),
      );
    } else if (isInserting) {
      context.missing(_orderDateMeta);
    }
    if (data.containsKey('total_quantity')) {
      context.handle(
        _totalQuantityMeta,
        totalQuantity.isAcceptableOrUnknown(
          data['total_quantity']!,
          _totalQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuantityMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('shipping_cost')) {
      context.handle(
        _shippingCostMeta,
        shippingCost.isAcceptableOrUnknown(
          data['shipping_cost']!,
          _shippingCostMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('items')) {
      context.handle(
        _itemsMeta,
        items.isAcceptableOrUnknown(data['items']!, _itemsMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrdersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrdersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      ),
      orderNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_number'],
      ),
      orderDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}order_date'],
      )!,
      totalQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_quantity'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount'],
      )!,
      shippingCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shipping_cost'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      ),
      items: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OrdersTableTable createAlias(String alias) {
    return $OrdersTableTable(attachedDatabase, alias);
  }
}

class OrdersTableData extends DataClass implements Insertable<OrdersTableData> {
  final String id;
  final String businessId;
  final String customerId;
  final String? channelId;
  final String? orderNumber;
  final DateTime orderDate;
  final int totalQuantity;
  final double subtotal;
  final double discount;
  final double? shippingCost;
  final double totalAmount;
  final String status;
  final String? paymentStatus;
  final String items;
  final String? externalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OrdersTableData({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.channelId,
    this.orderNumber,
    required this.orderDate,
    required this.totalQuantity,
    required this.subtotal,
    required this.discount,
    this.shippingCost,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    required this.items,
    this.externalId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<String>(channelId);
    }
    if (!nullToAbsent || orderNumber != null) {
      map['order_number'] = Variable<String>(orderNumber);
    }
    map['order_date'] = Variable<DateTime>(orderDate);
    map['total_quantity'] = Variable<int>(totalQuantity);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    if (!nullToAbsent || shippingCost != null) {
      map['shipping_cost'] = Variable<double>(shippingCost);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || paymentStatus != null) {
      map['payment_status'] = Variable<String>(paymentStatus);
    }
    map['items'] = Variable<String>(items);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OrdersTableCompanion toCompanion(bool nullToAbsent) {
    return OrdersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      customerId: Value(customerId),
      channelId: channelId == null && nullToAbsent
          ? const Value.absent()
          : Value(channelId),
      orderNumber: orderNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(orderNumber),
      orderDate: Value(orderDate),
      totalQuantity: Value(totalQuantity),
      subtotal: Value(subtotal),
      discount: Value(discount),
      shippingCost: shippingCost == null && nullToAbsent
          ? const Value.absent()
          : Value(shippingCost),
      totalAmount: Value(totalAmount),
      status: Value(status),
      paymentStatus: paymentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentStatus),
      items: Value(items),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OrdersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrdersTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      channelId: serializer.fromJson<String?>(json['channelId']),
      orderNumber: serializer.fromJson<String?>(json['orderNumber']),
      orderDate: serializer.fromJson<DateTime>(json['orderDate']),
      totalQuantity: serializer.fromJson<int>(json['totalQuantity']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      shippingCost: serializer.fromJson<double?>(json['shippingCost']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      status: serializer.fromJson<String>(json['status']),
      paymentStatus: serializer.fromJson<String?>(json['paymentStatus']),
      items: serializer.fromJson<String>(json['items']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'customerId': serializer.toJson<String>(customerId),
      'channelId': serializer.toJson<String?>(channelId),
      'orderNumber': serializer.toJson<String?>(orderNumber),
      'orderDate': serializer.toJson<DateTime>(orderDate),
      'totalQuantity': serializer.toJson<int>(totalQuantity),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'shippingCost': serializer.toJson<double?>(shippingCost),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'status': serializer.toJson<String>(status),
      'paymentStatus': serializer.toJson<String?>(paymentStatus),
      'items': serializer.toJson<String>(items),
      'externalId': serializer.toJson<String?>(externalId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OrdersTableData copyWith({
    String? id,
    String? businessId,
    String? customerId,
    Value<String?> channelId = const Value.absent(),
    Value<String?> orderNumber = const Value.absent(),
    DateTime? orderDate,
    int? totalQuantity,
    double? subtotal,
    double? discount,
    Value<double?> shippingCost = const Value.absent(),
    double? totalAmount,
    String? status,
    Value<String?> paymentStatus = const Value.absent(),
    String? items,
    Value<String?> externalId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrdersTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    customerId: customerId ?? this.customerId,
    channelId: channelId.present ? channelId.value : this.channelId,
    orderNumber: orderNumber.present ? orderNumber.value : this.orderNumber,
    orderDate: orderDate ?? this.orderDate,
    totalQuantity: totalQuantity ?? this.totalQuantity,
    subtotal: subtotal ?? this.subtotal,
    discount: discount ?? this.discount,
    shippingCost: shippingCost.present ? shippingCost.value : this.shippingCost,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    paymentStatus: paymentStatus.present
        ? paymentStatus.value
        : this.paymentStatus,
    items: items ?? this.items,
    externalId: externalId.present ? externalId.value : this.externalId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OrdersTableData copyWithCompanion(OrdersTableCompanion data) {
    return OrdersTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      orderNumber: data.orderNumber.present
          ? data.orderNumber.value
          : this.orderNumber,
      orderDate: data.orderDate.present ? data.orderDate.value : this.orderDate,
      totalQuantity: data.totalQuantity.present
          ? data.totalQuantity.value
          : this.totalQuantity,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      shippingCost: data.shippingCost.present
          ? data.shippingCost.value
          : this.shippingCost,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      status: data.status.present ? data.status.value : this.status,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      items: data.items.present ? data.items.value : this.items,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('channelId: $channelId, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderDate: $orderDate, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('items: $items, ')
          ..write('externalId: $externalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    customerId,
    channelId,
    orderNumber,
    orderDate,
    totalQuantity,
    subtotal,
    discount,
    shippingCost,
    totalAmount,
    status,
    paymentStatus,
    items,
    externalId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdersTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.customerId == this.customerId &&
          other.channelId == this.channelId &&
          other.orderNumber == this.orderNumber &&
          other.orderDate == this.orderDate &&
          other.totalQuantity == this.totalQuantity &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.shippingCost == this.shippingCost &&
          other.totalAmount == this.totalAmount &&
          other.status == this.status &&
          other.paymentStatus == this.paymentStatus &&
          other.items == this.items &&
          other.externalId == this.externalId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrdersTableCompanion extends UpdateCompanion<OrdersTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> customerId;
  final Value<String?> channelId;
  final Value<String?> orderNumber;
  final Value<DateTime> orderDate;
  final Value<int> totalQuantity;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double?> shippingCost;
  final Value<double> totalAmount;
  final Value<String> status;
  final Value<String?> paymentStatus;
  final Value<String> items;
  final Value<String?> externalId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OrdersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.orderDate = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.shippingCost = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.items = const Value.absent(),
    this.externalId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersTableCompanion.insert({
    required String id,
    required String businessId,
    required String customerId,
    this.channelId = const Value.absent(),
    this.orderNumber = const Value.absent(),
    required DateTime orderDate,
    required int totalQuantity,
    required double subtotal,
    this.discount = const Value.absent(),
    this.shippingCost = const Value.absent(),
    required double totalAmount,
    required String status,
    this.paymentStatus = const Value.absent(),
    required String items,
    this.externalId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       customerId = Value(customerId),
       orderDate = Value(orderDate),
       totalQuantity = Value(totalQuantity),
       subtotal = Value(subtotal),
       totalAmount = Value(totalAmount),
       status = Value(status),
       items = Value(items);
  static Insertable<OrdersTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? customerId,
    Expression<String>? channelId,
    Expression<String>? orderNumber,
    Expression<DateTime>? orderDate,
    Expression<int>? totalQuantity,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? shippingCost,
    Expression<double>? totalAmount,
    Expression<String>? status,
    Expression<String>? paymentStatus,
    Expression<String>? items,
    Expression<String>? externalId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (customerId != null) 'customer_id': customerId,
      if (channelId != null) 'channel_id': channelId,
      if (orderNumber != null) 'order_number': orderNumber,
      if (orderDate != null) 'order_date': orderDate,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (shippingCost != null) 'shipping_cost': shippingCost,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (status != null) 'status': status,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (items != null) 'items': items,
      if (externalId != null) 'external_id': externalId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? customerId,
    Value<String?>? channelId,
    Value<String?>? orderNumber,
    Value<DateTime>? orderDate,
    Value<int>? totalQuantity,
    Value<double>? subtotal,
    Value<double>? discount,
    Value<double?>? shippingCost,
    Value<double>? totalAmount,
    Value<String>? status,
    Value<String?>? paymentStatus,
    Value<String>? items,
    Value<String?>? externalId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrdersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      channelId: channelId ?? this.channelId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      items: items ?? this.items,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (orderDate.present) {
      map['order_date'] = Variable<DateTime>(orderDate.value);
    }
    if (totalQuantity.present) {
      map['total_quantity'] = Variable<int>(totalQuantity.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (shippingCost.present) {
      map['shipping_cost'] = Variable<double>(shippingCost.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('channelId: $channelId, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderDate: $orderDate, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('items: $items, ')
          ..write('externalId: $externalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OpportunitiesTableTable extends OpportunitiesTable
    with TableInfo<$OpportunitiesTableTable, OpportunitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpportunitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marketMeta = const VerificationMeta('market');
  @override
  late final GeneratedColumn<String> market = GeneratedColumn<String>(
    'market',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedRoiMeta = const VerificationMeta(
    'estimatedRoi',
  );
  @override
  late final GeneratedColumn<double> estimatedRoi = GeneratedColumn<double>(
    'estimated_roi',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedInvestmentMeta =
      const VerificationMeta('estimatedInvestment');
  @override
  late final GeneratedColumn<double> estimatedInvestment =
      GeneratedColumn<double>(
        'estimated_investment',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _riskScoreMeta = const VerificationMeta(
    'riskScore',
  );
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
    'risk_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feasibilityScoreMeta = const VerificationMeta(
    'feasibilityScore',
  );
  @override
  late final GeneratedColumn<double> feasibilityScore = GeneratedColumn<double>(
    'feasibility_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiScoreMeta = const VerificationMeta(
    'aiScore',
  );
  @override
  late final GeneratedColumn<double> aiScore = GeneratedColumn<double>(
    'ai_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedProductsMeta = const VerificationMeta(
    'relatedProducts',
  );
  @override
  late final GeneratedColumn<String> relatedProducts = GeneratedColumn<String>(
    'related_products',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedSuppliersMeta = const VerificationMeta(
    'relatedSuppliers',
  );
  @override
  late final GeneratedColumn<String> relatedSuppliers = GeneratedColumn<String>(
    'related_suppliers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discoveredAtMeta = const VerificationMeta(
    'discoveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> discoveredAt = GeneratedColumn<DateTime>(
    'discovered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    title,
    description,
    market,
    estimatedRoi,
    estimatedInvestment,
    riskScore,
    feasibilityScore,
    aiScore,
    status,
    relatedProducts,
    relatedSuppliers,
    discoveredAt,
    expiresAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'opportunities_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpportunitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('market')) {
      context.handle(
        _marketMeta,
        market.isAcceptableOrUnknown(data['market']!, _marketMeta),
      );
    }
    if (data.containsKey('estimated_roi')) {
      context.handle(
        _estimatedRoiMeta,
        estimatedRoi.isAcceptableOrUnknown(
          data['estimated_roi']!,
          _estimatedRoiMeta,
        ),
      );
    }
    if (data.containsKey('estimated_investment')) {
      context.handle(
        _estimatedInvestmentMeta,
        estimatedInvestment.isAcceptableOrUnknown(
          data['estimated_investment']!,
          _estimatedInvestmentMeta,
        ),
      );
    }
    if (data.containsKey('risk_score')) {
      context.handle(
        _riskScoreMeta,
        riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta),
      );
    }
    if (data.containsKey('feasibility_score')) {
      context.handle(
        _feasibilityScoreMeta,
        feasibilityScore.isAcceptableOrUnknown(
          data['feasibility_score']!,
          _feasibilityScoreMeta,
        ),
      );
    }
    if (data.containsKey('ai_score')) {
      context.handle(
        _aiScoreMeta,
        aiScore.isAcceptableOrUnknown(data['ai_score']!, _aiScoreMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('related_products')) {
      context.handle(
        _relatedProductsMeta,
        relatedProducts.isAcceptableOrUnknown(
          data['related_products']!,
          _relatedProductsMeta,
        ),
      );
    }
    if (data.containsKey('related_suppliers')) {
      context.handle(
        _relatedSuppliersMeta,
        relatedSuppliers.isAcceptableOrUnknown(
          data['related_suppliers']!,
          _relatedSuppliersMeta,
        ),
      );
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
        _discoveredAtMeta,
        discoveredAt.isAcceptableOrUnknown(
          data['discovered_at']!,
          _discoveredAtMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OpportunitiesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpportunitiesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      market: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market'],
      ),
      estimatedRoi: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_roi'],
      ),
      estimatedInvestment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_investment'],
      ),
      riskScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_score'],
      ),
      feasibilityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}feasibility_score'],
      ),
      aiScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ai_score'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      relatedProducts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_products'],
      ),
      relatedSuppliers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_suppliers'],
      ),
      discoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discovered_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OpportunitiesTableTable createAlias(String alias) {
    return $OpportunitiesTableTable(attachedDatabase, alias);
  }
}

class OpportunitiesTableData extends DataClass
    implements Insertable<OpportunitiesTableData> {
  final String id;
  final String businessId;
  final String type;
  final String title;
  final String? description;
  final String? market;
  final double? estimatedRoi;
  final double? estimatedInvestment;
  final double? riskScore;
  final double? feasibilityScore;
  final double? aiScore;
  final String? status;
  final String? relatedProducts;
  final String? relatedSuppliers;
  final DateTime discoveredAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OpportunitiesTableData({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    this.description,
    this.market,
    this.estimatedRoi,
    this.estimatedInvestment,
    this.riskScore,
    this.feasibilityScore,
    this.aiScore,
    this.status,
    this.relatedProducts,
    this.relatedSuppliers,
    required this.discoveredAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || market != null) {
      map['market'] = Variable<String>(market);
    }
    if (!nullToAbsent || estimatedRoi != null) {
      map['estimated_roi'] = Variable<double>(estimatedRoi);
    }
    if (!nullToAbsent || estimatedInvestment != null) {
      map['estimated_investment'] = Variable<double>(estimatedInvestment);
    }
    if (!nullToAbsent || riskScore != null) {
      map['risk_score'] = Variable<double>(riskScore);
    }
    if (!nullToAbsent || feasibilityScore != null) {
      map['feasibility_score'] = Variable<double>(feasibilityScore);
    }
    if (!nullToAbsent || aiScore != null) {
      map['ai_score'] = Variable<double>(aiScore);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || relatedProducts != null) {
      map['related_products'] = Variable<String>(relatedProducts);
    }
    if (!nullToAbsent || relatedSuppliers != null) {
      map['related_suppliers'] = Variable<String>(relatedSuppliers);
    }
    map['discovered_at'] = Variable<DateTime>(discoveredAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OpportunitiesTableCompanion toCompanion(bool nullToAbsent) {
    return OpportunitiesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      market: market == null && nullToAbsent
          ? const Value.absent()
          : Value(market),
      estimatedRoi: estimatedRoi == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedRoi),
      estimatedInvestment: estimatedInvestment == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedInvestment),
      riskScore: riskScore == null && nullToAbsent
          ? const Value.absent()
          : Value(riskScore),
      feasibilityScore: feasibilityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(feasibilityScore),
      aiScore: aiScore == null && nullToAbsent
          ? const Value.absent()
          : Value(aiScore),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      relatedProducts: relatedProducts == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedProducts),
      relatedSuppliers: relatedSuppliers == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedSuppliers),
      discoveredAt: Value(discoveredAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OpportunitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpportunitiesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      market: serializer.fromJson<String?>(json['market']),
      estimatedRoi: serializer.fromJson<double?>(json['estimatedRoi']),
      estimatedInvestment: serializer.fromJson<double?>(
        json['estimatedInvestment'],
      ),
      riskScore: serializer.fromJson<double?>(json['riskScore']),
      feasibilityScore: serializer.fromJson<double?>(json['feasibilityScore']),
      aiScore: serializer.fromJson<double?>(json['aiScore']),
      status: serializer.fromJson<String?>(json['status']),
      relatedProducts: serializer.fromJson<String?>(json['relatedProducts']),
      relatedSuppliers: serializer.fromJson<String?>(json['relatedSuppliers']),
      discoveredAt: serializer.fromJson<DateTime>(json['discoveredAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'market': serializer.toJson<String?>(market),
      'estimatedRoi': serializer.toJson<double?>(estimatedRoi),
      'estimatedInvestment': serializer.toJson<double?>(estimatedInvestment),
      'riskScore': serializer.toJson<double?>(riskScore),
      'feasibilityScore': serializer.toJson<double?>(feasibilityScore),
      'aiScore': serializer.toJson<double?>(aiScore),
      'status': serializer.toJson<String?>(status),
      'relatedProducts': serializer.toJson<String?>(relatedProducts),
      'relatedSuppliers': serializer.toJson<String?>(relatedSuppliers),
      'discoveredAt': serializer.toJson<DateTime>(discoveredAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OpportunitiesTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> market = const Value.absent(),
    Value<double?> estimatedRoi = const Value.absent(),
    Value<double?> estimatedInvestment = const Value.absent(),
    Value<double?> riskScore = const Value.absent(),
    Value<double?> feasibilityScore = const Value.absent(),
    Value<double?> aiScore = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> relatedProducts = const Value.absent(),
    Value<String?> relatedSuppliers = const Value.absent(),
    DateTime? discoveredAt,
    Value<DateTime?> expiresAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OpportunitiesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    market: market.present ? market.value : this.market,
    estimatedRoi: estimatedRoi.present ? estimatedRoi.value : this.estimatedRoi,
    estimatedInvestment: estimatedInvestment.present
        ? estimatedInvestment.value
        : this.estimatedInvestment,
    riskScore: riskScore.present ? riskScore.value : this.riskScore,
    feasibilityScore: feasibilityScore.present
        ? feasibilityScore.value
        : this.feasibilityScore,
    aiScore: aiScore.present ? aiScore.value : this.aiScore,
    status: status.present ? status.value : this.status,
    relatedProducts: relatedProducts.present
        ? relatedProducts.value
        : this.relatedProducts,
    relatedSuppliers: relatedSuppliers.present
        ? relatedSuppliers.value
        : this.relatedSuppliers,
    discoveredAt: discoveredAt ?? this.discoveredAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OpportunitiesTableData copyWithCompanion(OpportunitiesTableCompanion data) {
    return OpportunitiesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      market: data.market.present ? data.market.value : this.market,
      estimatedRoi: data.estimatedRoi.present
          ? data.estimatedRoi.value
          : this.estimatedRoi,
      estimatedInvestment: data.estimatedInvestment.present
          ? data.estimatedInvestment.value
          : this.estimatedInvestment,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      feasibilityScore: data.feasibilityScore.present
          ? data.feasibilityScore.value
          : this.feasibilityScore,
      aiScore: data.aiScore.present ? data.aiScore.value : this.aiScore,
      status: data.status.present ? data.status.value : this.status,
      relatedProducts: data.relatedProducts.present
          ? data.relatedProducts.value
          : this.relatedProducts,
      relatedSuppliers: data.relatedSuppliers.present
          ? data.relatedSuppliers.value
          : this.relatedSuppliers,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpportunitiesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('market: $market, ')
          ..write('estimatedRoi: $estimatedRoi, ')
          ..write('estimatedInvestment: $estimatedInvestment, ')
          ..write('riskScore: $riskScore, ')
          ..write('feasibilityScore: $feasibilityScore, ')
          ..write('aiScore: $aiScore, ')
          ..write('status: $status, ')
          ..write('relatedProducts: $relatedProducts, ')
          ..write('relatedSuppliers: $relatedSuppliers, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    title,
    description,
    market,
    estimatedRoi,
    estimatedInvestment,
    riskScore,
    feasibilityScore,
    aiScore,
    status,
    relatedProducts,
    relatedSuppliers,
    discoveredAt,
    expiresAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpportunitiesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.title == this.title &&
          other.description == this.description &&
          other.market == this.market &&
          other.estimatedRoi == this.estimatedRoi &&
          other.estimatedInvestment == this.estimatedInvestment &&
          other.riskScore == this.riskScore &&
          other.feasibilityScore == this.feasibilityScore &&
          other.aiScore == this.aiScore &&
          other.status == this.status &&
          other.relatedProducts == this.relatedProducts &&
          other.relatedSuppliers == this.relatedSuppliers &&
          other.discoveredAt == this.discoveredAt &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OpportunitiesTableCompanion
    extends UpdateCompanion<OpportunitiesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> market;
  final Value<double?> estimatedRoi;
  final Value<double?> estimatedInvestment;
  final Value<double?> riskScore;
  final Value<double?> feasibilityScore;
  final Value<double?> aiScore;
  final Value<String?> status;
  final Value<String?> relatedProducts;
  final Value<String?> relatedSuppliers;
  final Value<DateTime> discoveredAt;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OpportunitiesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.market = const Value.absent(),
    this.estimatedRoi = const Value.absent(),
    this.estimatedInvestment = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.feasibilityScore = const Value.absent(),
    this.aiScore = const Value.absent(),
    this.status = const Value.absent(),
    this.relatedProducts = const Value.absent(),
    this.relatedSuppliers = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpportunitiesTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    required String title,
    this.description = const Value.absent(),
    this.market = const Value.absent(),
    this.estimatedRoi = const Value.absent(),
    this.estimatedInvestment = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.feasibilityScore = const Value.absent(),
    this.aiScore = const Value.absent(),
    this.status = const Value.absent(),
    this.relatedProducts = const Value.absent(),
    this.relatedSuppliers = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       title = Value(title);
  static Insertable<OpportunitiesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? market,
    Expression<double>? estimatedRoi,
    Expression<double>? estimatedInvestment,
    Expression<double>? riskScore,
    Expression<double>? feasibilityScore,
    Expression<double>? aiScore,
    Expression<String>? status,
    Expression<String>? relatedProducts,
    Expression<String>? relatedSuppliers,
    Expression<DateTime>? discoveredAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (market != null) 'market': market,
      if (estimatedRoi != null) 'estimated_roi': estimatedRoi,
      if (estimatedInvestment != null)
        'estimated_investment': estimatedInvestment,
      if (riskScore != null) 'risk_score': riskScore,
      if (feasibilityScore != null) 'feasibility_score': feasibilityScore,
      if (aiScore != null) 'ai_score': aiScore,
      if (status != null) 'status': status,
      if (relatedProducts != null) 'related_products': relatedProducts,
      if (relatedSuppliers != null) 'related_suppliers': relatedSuppliers,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpportunitiesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? market,
    Value<double?>? estimatedRoi,
    Value<double?>? estimatedInvestment,
    Value<double?>? riskScore,
    Value<double?>? feasibilityScore,
    Value<double?>? aiScore,
    Value<String?>? status,
    Value<String?>? relatedProducts,
    Value<String?>? relatedSuppliers,
    Value<DateTime>? discoveredAt,
    Value<DateTime?>? expiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OpportunitiesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      market: market ?? this.market,
      estimatedRoi: estimatedRoi ?? this.estimatedRoi,
      estimatedInvestment: estimatedInvestment ?? this.estimatedInvestment,
      riskScore: riskScore ?? this.riskScore,
      feasibilityScore: feasibilityScore ?? this.feasibilityScore,
      aiScore: aiScore ?? this.aiScore,
      status: status ?? this.status,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      relatedSuppliers: relatedSuppliers ?? this.relatedSuppliers,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (market.present) {
      map['market'] = Variable<String>(market.value);
    }
    if (estimatedRoi.present) {
      map['estimated_roi'] = Variable<double>(estimatedRoi.value);
    }
    if (estimatedInvestment.present) {
      map['estimated_investment'] = Variable<double>(estimatedInvestment.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (feasibilityScore.present) {
      map['feasibility_score'] = Variable<double>(feasibilityScore.value);
    }
    if (aiScore.present) {
      map['ai_score'] = Variable<double>(aiScore.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (relatedProducts.present) {
      map['related_products'] = Variable<String>(relatedProducts.value);
    }
    if (relatedSuppliers.present) {
      map['related_suppliers'] = Variable<String>(relatedSuppliers.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<DateTime>(discoveredAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpportunitiesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('market: $market, ')
          ..write('estimatedRoi: $estimatedRoi, ')
          ..write('estimatedInvestment: $estimatedInvestment, ')
          ..write('riskScore: $riskScore, ')
          ..write('feasibilityScore: $feasibilityScore, ')
          ..write('aiScore: $aiScore, ')
          ..write('status: $status, ')
          ..write('relatedProducts: $relatedProducts, ')
          ..write('relatedSuppliers: $relatedSuppliers, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneysTableTable extends JourneysTable
    with TableInfo<$JourneysTableTable, JourneysTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<int> progressPercent = GeneratedColumn<int>(
    'progress_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalStepsMeta = const VerificationMeta(
    'totalSteps',
  );
  @override
  late final GeneratedColumn<int> totalSteps = GeneratedColumn<int>(
    'total_steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedStepsMeta = const VerificationMeta(
    'completedSteps',
  );
  @override
  late final GeneratedColumn<int> completedSteps = GeneratedColumn<int>(
    'completed_steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<double> budget = GeneratedColumn<double>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spentMeta = const VerificationMeta('spent');
  @override
  late final GeneratedColumn<double> spent = GeneratedColumn<double>(
    'spent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timelineDaysMeta = const VerificationMeta(
    'timelineDays',
  );
  @override
  late final GeneratedColumn<int> timelineDays = GeneratedColumn<int>(
    'timeline_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revenueImpactMeta = const VerificationMeta(
    'revenueImpact',
  );
  @override
  late final GeneratedColumn<double> revenueImpact = GeneratedColumn<double>(
    'revenue_impact',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    goal,
    status,
    progressPercent,
    totalSteps,
    completedSteps,
    budget,
    spent,
    timelineDays,
    revenueImpact,
    createdAt,
    startedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journeys_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneysTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('total_steps')) {
      context.handle(
        _totalStepsMeta,
        totalSteps.isAcceptableOrUnknown(data['total_steps']!, _totalStepsMeta),
      );
    }
    if (data.containsKey('completed_steps')) {
      context.handle(
        _completedStepsMeta,
        completedSteps.isAcceptableOrUnknown(
          data['completed_steps']!,
          _completedStepsMeta,
        ),
      );
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    }
    if (data.containsKey('spent')) {
      context.handle(
        _spentMeta,
        spent.isAcceptableOrUnknown(data['spent']!, _spentMeta),
      );
    }
    if (data.containsKey('timeline_days')) {
      context.handle(
        _timelineDaysMeta,
        timelineDays.isAcceptableOrUnknown(
          data['timeline_days']!,
          _timelineDaysMeta,
        ),
      );
    }
    if (data.containsKey('revenue_impact')) {
      context.handle(
        _revenueImpactMeta,
        revenueImpact.isAcceptableOrUnknown(
          data['revenue_impact']!,
          _revenueImpactMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JourneysTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneysTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_percent'],
      ),
      totalSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_steps'],
      ),
      completedSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_steps'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}budget'],
      ),
      spent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}spent'],
      )!,
      timelineDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeline_days'],
      ),
      revenueImpact: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}revenue_impact'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JourneysTableTable createAlias(String alias) {
    return $JourneysTableTable(attachedDatabase, alias);
  }
}

class JourneysTableData extends DataClass
    implements Insertable<JourneysTableData> {
  final String id;
  final String businessId;
  final String goal;
  final String status;
  final int? progressPercent;
  final int? totalSteps;
  final int completedSteps;
  final double? budget;
  final double spent;
  final int? timelineDays;
  final double? revenueImpact;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime updatedAt;
  const JourneysTableData({
    required this.id,
    required this.businessId,
    required this.goal,
    required this.status,
    this.progressPercent,
    this.totalSteps,
    required this.completedSteps,
    this.budget,
    required this.spent,
    this.timelineDays,
    this.revenueImpact,
    required this.createdAt,
    this.startedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['goal'] = Variable<String>(goal);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || progressPercent != null) {
      map['progress_percent'] = Variable<int>(progressPercent);
    }
    if (!nullToAbsent || totalSteps != null) {
      map['total_steps'] = Variable<int>(totalSteps);
    }
    map['completed_steps'] = Variable<int>(completedSteps);
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<double>(budget);
    }
    map['spent'] = Variable<double>(spent);
    if (!nullToAbsent || timelineDays != null) {
      map['timeline_days'] = Variable<int>(timelineDays);
    }
    if (!nullToAbsent || revenueImpact != null) {
      map['revenue_impact'] = Variable<double>(revenueImpact);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JourneysTableCompanion toCompanion(bool nullToAbsent) {
    return JourneysTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      goal: Value(goal),
      status: Value(status),
      progressPercent: progressPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(progressPercent),
      totalSteps: totalSteps == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSteps),
      completedSteps: Value(completedSteps),
      budget: budget == null && nullToAbsent
          ? const Value.absent()
          : Value(budget),
      spent: Value(spent),
      timelineDays: timelineDays == null && nullToAbsent
          ? const Value.absent()
          : Value(timelineDays),
      revenueImpact: revenueImpact == null && nullToAbsent
          ? const Value.absent()
          : Value(revenueImpact),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JourneysTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneysTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      goal: serializer.fromJson<String>(json['goal']),
      status: serializer.fromJson<String>(json['status']),
      progressPercent: serializer.fromJson<int?>(json['progressPercent']),
      totalSteps: serializer.fromJson<int?>(json['totalSteps']),
      completedSteps: serializer.fromJson<int>(json['completedSteps']),
      budget: serializer.fromJson<double?>(json['budget']),
      spent: serializer.fromJson<double>(json['spent']),
      timelineDays: serializer.fromJson<int?>(json['timelineDays']),
      revenueImpact: serializer.fromJson<double?>(json['revenueImpact']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'goal': serializer.toJson<String>(goal),
      'status': serializer.toJson<String>(status),
      'progressPercent': serializer.toJson<int?>(progressPercent),
      'totalSteps': serializer.toJson<int?>(totalSteps),
      'completedSteps': serializer.toJson<int>(completedSteps),
      'budget': serializer.toJson<double?>(budget),
      'spent': serializer.toJson<double>(spent),
      'timelineDays': serializer.toJson<int?>(timelineDays),
      'revenueImpact': serializer.toJson<double?>(revenueImpact),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JourneysTableData copyWith({
    String? id,
    String? businessId,
    String? goal,
    String? status,
    Value<int?> progressPercent = const Value.absent(),
    Value<int?> totalSteps = const Value.absent(),
    int? completedSteps,
    Value<double?> budget = const Value.absent(),
    double? spent,
    Value<int?> timelineDays = const Value.absent(),
    Value<double?> revenueImpact = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> startedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => JourneysTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    goal: goal ?? this.goal,
    status: status ?? this.status,
    progressPercent: progressPercent.present
        ? progressPercent.value
        : this.progressPercent,
    totalSteps: totalSteps.present ? totalSteps.value : this.totalSteps,
    completedSteps: completedSteps ?? this.completedSteps,
    budget: budget.present ? budget.value : this.budget,
    spent: spent ?? this.spent,
    timelineDays: timelineDays.present ? timelineDays.value : this.timelineDays,
    revenueImpact: revenueImpact.present
        ? revenueImpact.value
        : this.revenueImpact,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JourneysTableData copyWithCompanion(JourneysTableCompanion data) {
    return JourneysTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      goal: data.goal.present ? data.goal.value : this.goal,
      status: data.status.present ? data.status.value : this.status,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      totalSteps: data.totalSteps.present
          ? data.totalSteps.value
          : this.totalSteps,
      completedSteps: data.completedSteps.present
          ? data.completedSteps.value
          : this.completedSteps,
      budget: data.budget.present ? data.budget.value : this.budget,
      spent: data.spent.present ? data.spent.value : this.spent,
      timelineDays: data.timelineDays.present
          ? data.timelineDays.value
          : this.timelineDays,
      revenueImpact: data.revenueImpact.present
          ? data.revenueImpact.value
          : this.revenueImpact,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneysTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('goal: $goal, ')
          ..write('status: $status, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('totalSteps: $totalSteps, ')
          ..write('completedSteps: $completedSteps, ')
          ..write('budget: $budget, ')
          ..write('spent: $spent, ')
          ..write('timelineDays: $timelineDays, ')
          ..write('revenueImpact: $revenueImpact, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    goal,
    status,
    progressPercent,
    totalSteps,
    completedSteps,
    budget,
    spent,
    timelineDays,
    revenueImpact,
    createdAt,
    startedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneysTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.goal == this.goal &&
          other.status == this.status &&
          other.progressPercent == this.progressPercent &&
          other.totalSteps == this.totalSteps &&
          other.completedSteps == this.completedSteps &&
          other.budget == this.budget &&
          other.spent == this.spent &&
          other.timelineDays == this.timelineDays &&
          other.revenueImpact == this.revenueImpact &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt);
}

class JourneysTableCompanion extends UpdateCompanion<JourneysTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> goal;
  final Value<String> status;
  final Value<int?> progressPercent;
  final Value<int?> totalSteps;
  final Value<int> completedSteps;
  final Value<double?> budget;
  final Value<double> spent;
  final Value<int?> timelineDays;
  final Value<double?> revenueImpact;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const JourneysTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.goal = const Value.absent(),
    this.status = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.totalSteps = const Value.absent(),
    this.completedSteps = const Value.absent(),
    this.budget = const Value.absent(),
    this.spent = const Value.absent(),
    this.timelineDays = const Value.absent(),
    this.revenueImpact = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneysTableCompanion.insert({
    required String id,
    required String businessId,
    required String goal,
    required String status,
    this.progressPercent = const Value.absent(),
    this.totalSteps = const Value.absent(),
    this.completedSteps = const Value.absent(),
    this.budget = const Value.absent(),
    this.spent = const Value.absent(),
    this.timelineDays = const Value.absent(),
    this.revenueImpact = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       goal = Value(goal),
       status = Value(status);
  static Insertable<JourneysTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? goal,
    Expression<String>? status,
    Expression<int>? progressPercent,
    Expression<int>? totalSteps,
    Expression<int>? completedSteps,
    Expression<double>? budget,
    Expression<double>? spent,
    Expression<int>? timelineDays,
    Expression<double>? revenueImpact,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (goal != null) 'goal': goal,
      if (status != null) 'status': status,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (totalSteps != null) 'total_steps': totalSteps,
      if (completedSteps != null) 'completed_steps': completedSteps,
      if (budget != null) 'budget': budget,
      if (spent != null) 'spent': spent,
      if (timelineDays != null) 'timeline_days': timelineDays,
      if (revenueImpact != null) 'revenue_impact': revenueImpact,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneysTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? goal,
    Value<String>? status,
    Value<int?>? progressPercent,
    Value<int?>? totalSteps,
    Value<int>? completedSteps,
    Value<double?>? budget,
    Value<double>? spent,
    Value<int?>? timelineDays,
    Value<double?>? revenueImpact,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return JourneysTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      goal: goal ?? this.goal,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      timelineDays: timelineDays ?? this.timelineDays,
      revenueImpact: revenueImpact ?? this.revenueImpact,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<int>(progressPercent.value);
    }
    if (totalSteps.present) {
      map['total_steps'] = Variable<int>(totalSteps.value);
    }
    if (completedSteps.present) {
      map['completed_steps'] = Variable<int>(completedSteps.value);
    }
    if (budget.present) {
      map['budget'] = Variable<double>(budget.value);
    }
    if (spent.present) {
      map['spent'] = Variable<double>(spent.value);
    }
    if (timelineDays.present) {
      map['timeline_days'] = Variable<int>(timelineDays.value);
    }
    if (revenueImpact.present) {
      map['revenue_impact'] = Variable<double>(revenueImpact.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneysTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('goal: $goal, ')
          ..write('status: $status, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('totalSteps: $totalSteps, ')
          ..write('completedSteps: $completedSteps, ')
          ..write('budget: $budget, ')
          ..write('spent: $spent, ')
          ..write('timelineDays: $timelineDays, ')
          ..write('revenueImpact: $revenueImpact, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyStepsTableTable extends JourneyStepsTable
    with TableInfo<$JourneyStepsTableTable, JourneyStepsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyStepsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES journeys_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _stepNumberMeta = const VerificationMeta(
    'stepNumber',
  );
  @override
  late final GeneratedColumn<int> stepNumber = GeneratedColumn<int>(
    'step_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _milestoneMeta = const VerificationMeta(
    'milestone',
  );
  @override
  late final GeneratedColumn<bool> milestone = GeneratedColumn<bool>(
    'milestone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("milestone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forecastDaysMeta = const VerificationMeta(
    'forecastDays',
  );
  @override
  late final GeneratedColumn<int> forecastDays = GeneratedColumn<int>(
    'forecast_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guidanceMeta = const VerificationMeta(
    'guidance',
  );
  @override
  late final GeneratedColumn<String> guidance = GeneratedColumn<String>(
    'guidance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    journeyId,
    stepNumber,
    title,
    status,
    milestone,
    startDate,
    endDate,
    forecastDays,
    dependsOn,
    guidance,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_steps_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyStepsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('step_number')) {
      context.handle(
        _stepNumberMeta,
        stepNumber.isAcceptableOrUnknown(data['step_number']!, _stepNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('milestone')) {
      context.handle(
        _milestoneMeta,
        milestone.isAcceptableOrUnknown(data['milestone']!, _milestoneMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('forecast_days')) {
      context.handle(
        _forecastDaysMeta,
        forecastDays.isAcceptableOrUnknown(
          data['forecast_days']!,
          _forecastDaysMeta,
        ),
      );
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    }
    if (data.containsKey('guidance')) {
      context.handle(
        _guidanceMeta,
        guidance.isAcceptableOrUnknown(data['guidance']!, _guidanceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JourneyStepsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyStepsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      stepNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      milestone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}milestone'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      forecastDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}forecast_days'],
      ),
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      ),
      guidance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guidance'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JourneyStepsTableTable createAlias(String alias) {
    return $JourneyStepsTableTable(attachedDatabase, alias);
  }
}

class JourneyStepsTableData extends DataClass
    implements Insertable<JourneyStepsTableData> {
  final String id;
  final String journeyId;
  final int stepNumber;
  final String title;
  final String status;
  final bool milestone;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? forecastDays;
  final String? dependsOn;
  final String? guidance;
  final DateTime createdAt;
  final DateTime updatedAt;
  const JourneyStepsTableData({
    required this.id,
    required this.journeyId,
    required this.stepNumber,
    required this.title,
    required this.status,
    required this.milestone,
    this.startDate,
    this.endDate,
    this.forecastDays,
    this.dependsOn,
    this.guidance,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['journey_id'] = Variable<String>(journeyId);
    map['step_number'] = Variable<int>(stepNumber);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['milestone'] = Variable<bool>(milestone);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || forecastDays != null) {
      map['forecast_days'] = Variable<int>(forecastDays);
    }
    if (!nullToAbsent || dependsOn != null) {
      map['depends_on'] = Variable<String>(dependsOn);
    }
    if (!nullToAbsent || guidance != null) {
      map['guidance'] = Variable<String>(guidance);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JourneyStepsTableCompanion toCompanion(bool nullToAbsent) {
    return JourneyStepsTableCompanion(
      id: Value(id),
      journeyId: Value(journeyId),
      stepNumber: Value(stepNumber),
      title: Value(title),
      status: Value(status),
      milestone: Value(milestone),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      forecastDays: forecastDays == null && nullToAbsent
          ? const Value.absent()
          : Value(forecastDays),
      dependsOn: dependsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOn),
      guidance: guidance == null && nullToAbsent
          ? const Value.absent()
          : Value(guidance),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JourneyStepsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyStepsTableData(
      id: serializer.fromJson<String>(json['id']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      stepNumber: serializer.fromJson<int>(json['stepNumber']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      milestone: serializer.fromJson<bool>(json['milestone']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      forecastDays: serializer.fromJson<int?>(json['forecastDays']),
      dependsOn: serializer.fromJson<String?>(json['dependsOn']),
      guidance: serializer.fromJson<String?>(json['guidance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'journeyId': serializer.toJson<String>(journeyId),
      'stepNumber': serializer.toJson<int>(stepNumber),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'milestone': serializer.toJson<bool>(milestone),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'forecastDays': serializer.toJson<int?>(forecastDays),
      'dependsOn': serializer.toJson<String?>(dependsOn),
      'guidance': serializer.toJson<String?>(guidance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JourneyStepsTableData copyWith({
    String? id,
    String? journeyId,
    int? stepNumber,
    String? title,
    String? status,
    bool? milestone,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    Value<int?> forecastDays = const Value.absent(),
    Value<String?> dependsOn = const Value.absent(),
    Value<String?> guidance = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => JourneyStepsTableData(
    id: id ?? this.id,
    journeyId: journeyId ?? this.journeyId,
    stepNumber: stepNumber ?? this.stepNumber,
    title: title ?? this.title,
    status: status ?? this.status,
    milestone: milestone ?? this.milestone,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    forecastDays: forecastDays.present ? forecastDays.value : this.forecastDays,
    dependsOn: dependsOn.present ? dependsOn.value : this.dependsOn,
    guidance: guidance.present ? guidance.value : this.guidance,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JourneyStepsTableData copyWithCompanion(JourneyStepsTableCompanion data) {
    return JourneyStepsTableData(
      id: data.id.present ? data.id.value : this.id,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      stepNumber: data.stepNumber.present
          ? data.stepNumber.value
          : this.stepNumber,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      milestone: data.milestone.present ? data.milestone.value : this.milestone,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      forecastDays: data.forecastDays.present
          ? data.forecastDays.value
          : this.forecastDays,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      guidance: data.guidance.present ? data.guidance.value : this.guidance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyStepsTableData(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('milestone: $milestone, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('forecastDays: $forecastDays, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('guidance: $guidance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    journeyId,
    stepNumber,
    title,
    status,
    milestone,
    startDate,
    endDate,
    forecastDays,
    dependsOn,
    guidance,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyStepsTableData &&
          other.id == this.id &&
          other.journeyId == this.journeyId &&
          other.stepNumber == this.stepNumber &&
          other.title == this.title &&
          other.status == this.status &&
          other.milestone == this.milestone &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.forecastDays == this.forecastDays &&
          other.dependsOn == this.dependsOn &&
          other.guidance == this.guidance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JourneyStepsTableCompanion
    extends UpdateCompanion<JourneyStepsTableData> {
  final Value<String> id;
  final Value<String> journeyId;
  final Value<int> stepNumber;
  final Value<String> title;
  final Value<String> status;
  final Value<bool> milestone;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> forecastDays;
  final Value<String?> dependsOn;
  final Value<String?> guidance;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const JourneyStepsTableCompanion({
    this.id = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.stepNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.milestone = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.forecastDays = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.guidance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyStepsTableCompanion.insert({
    required String id,
    required String journeyId,
    required int stepNumber,
    required String title,
    required String status,
    this.milestone = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.forecastDays = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.guidance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       journeyId = Value(journeyId),
       stepNumber = Value(stepNumber),
       title = Value(title),
       status = Value(status);
  static Insertable<JourneyStepsTableData> custom({
    Expression<String>? id,
    Expression<String>? journeyId,
    Expression<int>? stepNumber,
    Expression<String>? title,
    Expression<String>? status,
    Expression<bool>? milestone,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? forecastDays,
    Expression<String>? dependsOn,
    Expression<String>? guidance,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (journeyId != null) 'journey_id': journeyId,
      if (stepNumber != null) 'step_number': stepNumber,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (milestone != null) 'milestone': milestone,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (forecastDays != null) 'forecast_days': forecastDays,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (guidance != null) 'guidance': guidance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyStepsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? journeyId,
    Value<int>? stepNumber,
    Value<String>? title,
    Value<String>? status,
    Value<bool>? milestone,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<int?>? forecastDays,
    Value<String?>? dependsOn,
    Value<String?>? guidance,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return JourneyStepsTableCompanion(
      id: id ?? this.id,
      journeyId: journeyId ?? this.journeyId,
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      status: status ?? this.status,
      milestone: milestone ?? this.milestone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      forecastDays: forecastDays ?? this.forecastDays,
      dependsOn: dependsOn ?? this.dependsOn,
      guidance: guidance ?? this.guidance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (stepNumber.present) {
      map['step_number'] = Variable<int>(stepNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (milestone.present) {
      map['milestone'] = Variable<bool>(milestone.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (forecastDays.present) {
      map['forecast_days'] = Variable<int>(forecastDays.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (guidance.present) {
      map['guidance'] = Variable<String>(guidance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyStepsTableCompanion(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('milestone: $milestone, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('forecastDays: $forecastDays, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('guidance: $guidance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders_table (id)',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReconciledMeta = const VerificationMeta(
    'isReconciled',
  );
  @override
  late final GeneratedColumn<bool> isReconciled = GeneratedColumn<bool>(
    'is_reconciled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reconciled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    category,
    amount,
    currency,
    date,
    account,
    orderId,
    description,
    paymentMethod,
    isReconciled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('is_reconciled')) {
      context.handle(
        _isReconciledMeta,
        isReconciled.isAcceptableOrUnknown(
          data['is_reconciled']!,
          _isReconciledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      isReconciled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reconciled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final String id;
  final String businessId;
  final String type;
  final String? category;
  final double amount;
  final String? currency;
  final DateTime date;
  final String? account;
  final String? orderId;
  final String? description;
  final String? paymentMethod;
  final bool isReconciled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionsTableData({
    required this.id,
    required this.businessId,
    required this.type,
    this.category,
    required this.amount,
    this.currency,
    required this.date,
    this.account,
    this.orderId,
    this.description,
    this.paymentMethod,
    required this.isReconciled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || account != null) {
      map['account'] = Variable<String>(account);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['is_reconciled'] = Variable<bool>(isReconciled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      amount: Value(amount),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      date: Value(date),
      account: account == null && nullToAbsent
          ? const Value.absent()
          : Value(account),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      isReconciled: Value(isReconciled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String?>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String?>(json['currency']),
      date: serializer.fromJson<DateTime>(json['date']),
      account: serializer.fromJson<String?>(json['account']),
      orderId: serializer.fromJson<String?>(json['orderId']),
      description: serializer.fromJson<String?>(json['description']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      isReconciled: serializer.fromJson<bool>(json['isReconciled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String?>(category),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String?>(currency),
      'date': serializer.toJson<DateTime>(date),
      'account': serializer.toJson<String?>(account),
      'orderId': serializer.toJson<String?>(orderId),
      'description': serializer.toJson<String?>(description),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'isReconciled': serializer.toJson<bool>(isReconciled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionsTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    Value<String?> category = const Value.absent(),
    double? amount,
    Value<String?> currency = const Value.absent(),
    DateTime? date,
    Value<String?> account = const Value.absent(),
    Value<String?> orderId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    bool? isReconciled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    category: category.present ? category.value : this.category,
    amount: amount ?? this.amount,
    currency: currency.present ? currency.value : this.currency,
    date: date ?? this.date,
    account: account.present ? account.value : this.account,
    orderId: orderId.present ? orderId.value : this.orderId,
    description: description.present ? description.value : this.description,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    isReconciled: isReconciled ?? this.isReconciled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      date: data.date.present ? data.date.value : this.date,
      account: data.account.present ? data.account.value : this.account,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      description: data.description.present
          ? data.description.value
          : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      isReconciled: data.isReconciled.present
          ? data.isReconciled.value
          : this.isReconciled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('account: $account, ')
          ..write('orderId: $orderId, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isReconciled: $isReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    category,
    amount,
    currency,
    date,
    account,
    orderId,
    description,
    paymentMethod,
    isReconciled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.date == this.date &&
          other.account == this.account &&
          other.orderId == this.orderId &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.isReconciled == this.isReconciled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String?> category;
  final Value<double> amount;
  final Value<String?> currency;
  final Value<DateTime> date;
  final Value<String?> account;
  final Value<String?> orderId;
  final Value<String?> description;
  final Value<String?> paymentMethod;
  final Value<bool> isReconciled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.date = const Value.absent(),
    this.account = const Value.absent(),
    this.orderId = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.isReconciled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    this.category = const Value.absent(),
    required double amount,
    this.currency = const Value.absent(),
    required DateTime date,
    this.account = const Value.absent(),
    this.orderId = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.isReconciled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date);
  static Insertable<TransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<DateTime>? date,
    Expression<String>? account,
    Expression<String>? orderId,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<bool>? isReconciled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (date != null) 'date': date,
      if (account != null) 'account': account,
      if (orderId != null) 'order_id': orderId,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (isReconciled != null) 'is_reconciled': isReconciled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String?>? category,
    Value<double>? amount,
    Value<String?>? currency,
    Value<DateTime>? date,
    Value<String?>? account,
    Value<String?>? orderId,
    Value<String?>? description,
    Value<String?>? paymentMethod,
    Value<bool>? isReconciled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      account: account ?? this.account,
      orderId: orderId ?? this.orderId,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isReconciled: isReconciled ?? this.isReconciled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (isReconciled.present) {
      map['is_reconciled'] = Variable<bool>(isReconciled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('account: $account, ')
          ..write('orderId: $orderId, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isReconciled: $isReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTableTable extends DocumentsTable
    with TableInfo<$DocumentsTableTable, DocumentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedDataMeta = const VerificationMeta(
    'extractedData',
  );
  @override
  late final GeneratedColumn<String> extractedData = GeneratedColumn<String>(
    'extracted_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedEntityTypeMeta = const VerificationMeta(
    'relatedEntityType',
  );
  @override
  late final GeneratedColumn<String> relatedEntityType =
      GeneratedColumn<String>(
        'related_entity_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _relatedEntityIdMeta = const VerificationMeta(
    'relatedEntityId',
  );
  @override
  late final GeneratedColumn<String> relatedEntityId = GeneratedColumn<String>(
    'related_entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    name,
    fileName,
    fileType,
    fileSize,
    localPath,
    extractedText,
    extractedData,
    relatedEntityType,
    relatedEntityId,
    isSynced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    }
    if (data.containsKey('extracted_data')) {
      context.handle(
        _extractedDataMeta,
        extractedData.isAcceptableOrUnknown(
          data['extracted_data']!,
          _extractedDataMeta,
        ),
      );
    }
    if (data.containsKey('related_entity_type')) {
      context.handle(
        _relatedEntityTypeMeta,
        relatedEntityType.isAcceptableOrUnknown(
          data['related_entity_type']!,
          _relatedEntityTypeMeta,
        ),
      );
    }
    if (data.containsKey('related_entity_id')) {
      context.handle(
        _relatedEntityIdMeta,
        relatedEntityId.isAcceptableOrUnknown(
          data['related_entity_id']!,
          _relatedEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      extractedData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_data'],
      ),
      relatedEntityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_entity_type'],
      ),
      relatedEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_entity_id'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DocumentsTableTable createAlias(String alias) {
    return $DocumentsTableTable(attachedDatabase, alias);
  }
}

class DocumentsTableData extends DataClass
    implements Insertable<DocumentsTableData> {
  final String id;
  final String businessId;
  final String type;
  final String name;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? localPath;
  final String? extractedText;
  final String? extractedData;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DocumentsTableData({
    required this.id,
    required this.businessId,
    required this.type,
    required this.name,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.localPath,
    this.extractedText,
    this.extractedData,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || fileType != null) {
      map['file_type'] = Variable<String>(fileType);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    if (!nullToAbsent || extractedData != null) {
      map['extracted_data'] = Variable<String>(extractedData);
    }
    if (!nullToAbsent || relatedEntityType != null) {
      map['related_entity_type'] = Variable<String>(relatedEntityType);
    }
    if (!nullToAbsent || relatedEntityId != null) {
      map['related_entity_id'] = Variable<String>(relatedEntityId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsTableCompanion toCompanion(bool nullToAbsent) {
    return DocumentsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      name: Value(name),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      fileType: fileType == null && nullToAbsent
          ? const Value.absent()
          : Value(fileType),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      extractedData: extractedData == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedData),
      relatedEntityType: relatedEntityType == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedEntityType),
      relatedEntityId: relatedEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedEntityId),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      fileType: serializer.fromJson<String?>(json['fileType']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      extractedData: serializer.fromJson<String?>(json['extractedData']),
      relatedEntityType: serializer.fromJson<String?>(
        json['relatedEntityType'],
      ),
      relatedEntityId: serializer.fromJson<String?>(json['relatedEntityId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'fileName': serializer.toJson<String?>(fileName),
      'fileType': serializer.toJson<String?>(fileType),
      'fileSize': serializer.toJson<int?>(fileSize),
      'localPath': serializer.toJson<String?>(localPath),
      'extractedText': serializer.toJson<String?>(extractedText),
      'extractedData': serializer.toJson<String?>(extractedData),
      'relatedEntityType': serializer.toJson<String?>(relatedEntityType),
      'relatedEntityId': serializer.toJson<String?>(relatedEntityId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentsTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    String? name,
    Value<String?> fileName = const Value.absent(),
    Value<String?> fileType = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> extractedText = const Value.absent(),
    Value<String?> extractedData = const Value.absent(),
    Value<String?> relatedEntityType = const Value.absent(),
    Value<String?> relatedEntityId = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DocumentsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    name: name ?? this.name,
    fileName: fileName.present ? fileName.value : this.fileName,
    fileType: fileType.present ? fileType.value : this.fileType,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    localPath: localPath.present ? localPath.value : this.localPath,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    extractedData: extractedData.present
        ? extractedData.value
        : this.extractedData,
    relatedEntityType: relatedEntityType.present
        ? relatedEntityType.value
        : this.relatedEntityType,
    relatedEntityId: relatedEntityId.present
        ? relatedEntityId.value
        : this.relatedEntityId,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentsTableData copyWithCompanion(DocumentsTableCompanion data) {
    return DocumentsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      extractedData: data.extractedData.present
          ? data.extractedData.value
          : this.extractedData,
      relatedEntityType: data.relatedEntityType.present
          ? data.relatedEntityType.value
          : this.relatedEntityType,
      relatedEntityId: data.relatedEntityId.present
          ? data.relatedEntityId.value
          : this.relatedEntityId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('extractedData: $extractedData, ')
          ..write('relatedEntityType: $relatedEntityType, ')
          ..write('relatedEntityId: $relatedEntityId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    name,
    fileName,
    fileType,
    fileSize,
    localPath,
    extractedText,
    extractedData,
    relatedEntityType,
    relatedEntityId,
    isSynced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.name == this.name &&
          other.fileName == this.fileName &&
          other.fileType == this.fileType &&
          other.fileSize == this.fileSize &&
          other.localPath == this.localPath &&
          other.extractedText == this.extractedText &&
          other.extractedData == this.extractedData &&
          other.relatedEntityType == this.relatedEntityType &&
          other.relatedEntityId == this.relatedEntityId &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsTableCompanion extends UpdateCompanion<DocumentsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> fileName;
  final Value<String?> fileType;
  final Value<int?> fileSize;
  final Value<String?> localPath;
  final Value<String?> extractedText;
  final Value<String?> extractedData;
  final Value<String?> relatedEntityType;
  final Value<String?> relatedEntityId;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.localPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.extractedData = const Value.absent(),
    this.relatedEntityType = const Value.absent(),
    this.relatedEntityId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    required String name,
    this.fileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.localPath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.extractedData = const Value.absent(),
    this.relatedEntityType = const Value.absent(),
    this.relatedEntityId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       name = Value(name);
  static Insertable<DocumentsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? fileName,
    Expression<String>? fileType,
    Expression<int>? fileSize,
    Expression<String>? localPath,
    Expression<String>? extractedText,
    Expression<String>? extractedData,
    Expression<String>? relatedEntityType,
    Expression<String>? relatedEntityId,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (fileName != null) 'file_name': fileName,
      if (fileType != null) 'file_type': fileType,
      if (fileSize != null) 'file_size': fileSize,
      if (localPath != null) 'local_path': localPath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (extractedData != null) 'extracted_data': extractedData,
      if (relatedEntityType != null) 'related_entity_type': relatedEntityType,
      if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String>? name,
    Value<String?>? fileName,
    Value<String?>? fileType,
    Value<int?>? fileSize,
    Value<String?>? localPath,
    Value<String?>? extractedText,
    Value<String?>? extractedData,
    Value<String?>? relatedEntityType,
    Value<String?>? relatedEntityId,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      localPath: localPath ?? this.localPath,
      extractedText: extractedText ?? this.extractedText,
      extractedData: extractedData ?? this.extractedData,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (extractedData.present) {
      map['extracted_data'] = Variable<String>(extractedData.value);
    }
    if (relatedEntityType.present) {
      map['related_entity_type'] = Variable<String>(relatedEntityType.value);
    }
    if (relatedEntityId.present) {
      map['related_entity_id'] = Variable<String>(relatedEntityId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('extractedText: $extractedText, ')
          ..write('extractedData: $extractedData, ')
          ..write('relatedEntityType: $relatedEntityType, ')
          ..write('relatedEntityId: $relatedEntityId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTableTable extends AlertsTable
    with TableInfo<$AlertsTableTable, AlertsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiRecommendationMeta = const VerificationMeta(
    'aiRecommendation',
  );
  @override
  late final GeneratedColumn<String> aiRecommendation = GeneratedColumn<String>(
    'ai_recommendation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    severity,
    title,
    description,
    aiRecommendation,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('ai_recommendation')) {
      context.handle(
        _aiRecommendationMeta,
        aiRecommendation.isAcceptableOrUnknown(
          data['ai_recommendation']!,
          _aiRecommendationMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      aiRecommendation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_recommendation'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AlertsTableTable createAlias(String alias) {
    return $AlertsTableTable(attachedDatabase, alias);
  }
}

class AlertsTableData extends DataClass implements Insertable<AlertsTableData> {
  final String id;
  final String businessId;
  final String type;
  final String severity;
  final String title;
  final String? description;
  final String? aiRecommendation;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AlertsTableData({
    required this.id,
    required this.businessId,
    required this.type,
    required this.severity,
    required this.title,
    this.description,
    this.aiRecommendation,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || aiRecommendation != null) {
      map['ai_recommendation'] = Variable<String>(aiRecommendation);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AlertsTableCompanion toCompanion(bool nullToAbsent) {
    return AlertsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      severity: Value(severity),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      aiRecommendation: aiRecommendation == null && nullToAbsent
          ? const Value.absent()
          : Value(aiRecommendation),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AlertsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      aiRecommendation: serializer.fromJson<String?>(json['aiRecommendation']),
      status: serializer.fromJson<String?>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'aiRecommendation': serializer.toJson<String?>(aiRecommendation),
      'status': serializer.toJson<String?>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AlertsTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    String? severity,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> aiRecommendation = const Value.absent(),
    Value<String?> status = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AlertsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    aiRecommendation: aiRecommendation.present
        ? aiRecommendation.value
        : this.aiRecommendation,
    status: status.present ? status.value : this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AlertsTableData copyWithCompanion(AlertsTableCompanion data) {
    return AlertsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      aiRecommendation: data.aiRecommendation.present
          ? data.aiRecommendation.value
          : this.aiRecommendation,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('aiRecommendation: $aiRecommendation, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    severity,
    title,
    description,
    aiRecommendation,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.description == this.description &&
          other.aiRecommendation == this.aiRecommendation &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AlertsTableCompanion extends UpdateCompanion<AlertsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String> severity;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> aiRecommendation;
  final Value<String?> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AlertsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.aiRecommendation = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    required String severity,
    required String title,
    this.description = const Value.absent(),
    this.aiRecommendation = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       severity = Value(severity),
       title = Value(title);
  static Insertable<AlertsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? aiRecommendation,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (aiRecommendation != null) 'ai_recommendation': aiRecommendation,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String>? severity,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? aiRecommendation,
    Value<String?>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AlertsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (aiRecommendation.present) {
      map['ai_recommendation'] = Variable<String>(aiRecommendation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('aiRecommendation: $aiRecommendation, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AIChatTableTable extends AIChatTable
    with TableInfo<$AIChatTableTable, AIChatTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIChatTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users_table (id)',
    ),
  );
  static const VerificationMeta _messagesMeta = const VerificationMeta(
    'messages',
  );
  @override
  late final GeneratedColumn<String> messages = GeneratedColumn<String>(
    'messages',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensUsedMeta = const VerificationMeta(
    'tokensUsed',
  );
  @override
  late final GeneratedColumn<int> tokensUsed = GeneratedColumn<int>(
    'tokens_used',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    userId,
    messages,
    context,
    summary,
    tokensUsed,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_chat_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AIChatTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('messages')) {
      context.handle(
        _messagesMeta,
        messages.isAcceptableOrUnknown(data['messages']!, _messagesMeta),
      );
    } else if (isInserting) {
      context.missing(_messagesMeta);
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('tokens_used')) {
      context.handle(
        _tokensUsedMeta,
        tokensUsed.isAcceptableOrUnknown(data['tokens_used']!, _tokensUsedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIChatTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIChatTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      messages: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}messages'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      tokensUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_used'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AIChatTableTable createAlias(String alias) {
    return $AIChatTableTable(attachedDatabase, alias);
  }
}

class AIChatTableData extends DataClass implements Insertable<AIChatTableData> {
  final String id;
  final String businessId;
  final String userId;
  final String messages;
  final String? context;
  final String? summary;
  final int? tokensUsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AIChatTableData({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.messages,
    this.context,
    this.summary,
    this.tokensUsed,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['user_id'] = Variable<String>(userId);
    map['messages'] = Variable<String>(messages);
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || tokensUsed != null) {
      map['tokens_used'] = Variable<int>(tokensUsed);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AIChatTableCompanion toCompanion(bool nullToAbsent) {
    return AIChatTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      userId: Value(userId),
      messages: Value(messages),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      tokensUsed: tokensUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensUsed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AIChatTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIChatTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      userId: serializer.fromJson<String>(json['userId']),
      messages: serializer.fromJson<String>(json['messages']),
      context: serializer.fromJson<String?>(json['context']),
      summary: serializer.fromJson<String?>(json['summary']),
      tokensUsed: serializer.fromJson<int?>(json['tokensUsed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'userId': serializer.toJson<String>(userId),
      'messages': serializer.toJson<String>(messages),
      'context': serializer.toJson<String?>(context),
      'summary': serializer.toJson<String?>(summary),
      'tokensUsed': serializer.toJson<int?>(tokensUsed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AIChatTableData copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? messages,
    Value<String?> context = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<int?> tokensUsed = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AIChatTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    userId: userId ?? this.userId,
    messages: messages ?? this.messages,
    context: context.present ? context.value : this.context,
    summary: summary.present ? summary.value : this.summary,
    tokensUsed: tokensUsed.present ? tokensUsed.value : this.tokensUsed,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AIChatTableData copyWithCompanion(AIChatTableCompanion data) {
    return AIChatTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      userId: data.userId.present ? data.userId.value : this.userId,
      messages: data.messages.present ? data.messages.value : this.messages,
      context: data.context.present ? data.context.value : this.context,
      summary: data.summary.present ? data.summary.value : this.summary,
      tokensUsed: data.tokensUsed.present
          ? data.tokensUsed.value
          : this.tokensUsed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIChatTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('messages: $messages, ')
          ..write('context: $context, ')
          ..write('summary: $summary, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    userId,
    messages,
    context,
    summary,
    tokensUsed,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIChatTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.userId == this.userId &&
          other.messages == this.messages &&
          other.context == this.context &&
          other.summary == this.summary &&
          other.tokensUsed == this.tokensUsed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AIChatTableCompanion extends UpdateCompanion<AIChatTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> userId;
  final Value<String> messages;
  final Value<String?> context;
  final Value<String?> summary;
  final Value<int?> tokensUsed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AIChatTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.userId = const Value.absent(),
    this.messages = const Value.absent(),
    this.context = const Value.absent(),
    this.summary = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AIChatTableCompanion.insert({
    required String id,
    required String businessId,
    required String userId,
    required String messages,
    this.context = const Value.absent(),
    this.summary = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       userId = Value(userId),
       messages = Value(messages);
  static Insertable<AIChatTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? userId,
    Expression<String>? messages,
    Expression<String>? context,
    Expression<String>? summary,
    Expression<int>? tokensUsed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (userId != null) 'user_id': userId,
      if (messages != null) 'messages': messages,
      if (context != null) 'context': context,
      if (summary != null) 'summary': summary,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AIChatTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? userId,
    Value<String>? messages,
    Value<String?>? context,
    Value<String?>? summary,
    Value<int?>? tokensUsed,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AIChatTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      summary: summary ?? this.summary,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (messages.present) {
      map['messages'] = Variable<String>(messages.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (tokensUsed.present) {
      map['tokens_used'] = Variable<int>(tokensUsed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIChatTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('messages: $messages, ')
          ..write('context: $context, ')
          ..write('summary: $summary, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntegrationsTableTable extends IntegrationsTable
    with TableInfo<$IntegrationsTableTable, IntegrationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntegrationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiKeyEncryptedMeta = const VerificationMeta(
    'apiKeyEncrypted',
  );
  @override
  late final GeneratedColumn<String> apiKeyEncrypted = GeneratedColumn<String>(
    'api_key_encrypted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiSecretEncryptedMeta =
      const VerificationMeta('apiSecretEncrypted');
  @override
  late final GeneratedColumn<String> apiSecretEncrypted =
      GeneratedColumn<String>(
        'api_secret_encrypted',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _accessTokenEncryptedMeta =
      const VerificationMeta('accessTokenEncrypted');
  @override
  late final GeneratedColumn<String> accessTokenEncrypted =
      GeneratedColumn<String>(
        'access_token_encrypted',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _refreshTokenEncryptedMeta =
      const VerificationMeta('refreshTokenEncrypted');
  @override
  late final GeneratedColumn<String> refreshTokenEncrypted =
      GeneratedColumn<String>(
        'refresh_token_encrypted',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    provider,
    status,
    apiKeyEncrypted,
    apiSecretEncrypted,
    accessTokenEncrypted,
    refreshTokenEncrypted,
    config,
    lastSyncAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'integrations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntegrationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('api_key_encrypted')) {
      context.handle(
        _apiKeyEncryptedMeta,
        apiKeyEncrypted.isAcceptableOrUnknown(
          data['api_key_encrypted']!,
          _apiKeyEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('api_secret_encrypted')) {
      context.handle(
        _apiSecretEncryptedMeta,
        apiSecretEncrypted.isAcceptableOrUnknown(
          data['api_secret_encrypted']!,
          _apiSecretEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('access_token_encrypted')) {
      context.handle(
        _accessTokenEncryptedMeta,
        accessTokenEncrypted.isAcceptableOrUnknown(
          data['access_token_encrypted']!,
          _accessTokenEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('refresh_token_encrypted')) {
      context.handle(
        _refreshTokenEncryptedMeta,
        refreshTokenEncrypted.isAcceptableOrUnknown(
          data['refresh_token_encrypted']!,
          _refreshTokenEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntegrationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntegrationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      apiKeyEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key_encrypted'],
      ),
      apiSecretEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_secret_encrypted'],
      ),
      accessTokenEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token_encrypted'],
      ),
      refreshTokenEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_token_encrypted'],
      ),
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IntegrationsTableTable createAlias(String alias) {
    return $IntegrationsTableTable(attachedDatabase, alias);
  }
}

class IntegrationsTableData extends DataClass
    implements Insertable<IntegrationsTableData> {
  final String id;
  final String businessId;
  final String provider;
  final String? status;
  final String? apiKeyEncrypted;
  final String? apiSecretEncrypted;
  final String? accessTokenEncrypted;
  final String? refreshTokenEncrypted;
  final String? config;
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const IntegrationsTableData({
    required this.id,
    required this.businessId,
    required this.provider,
    this.status,
    this.apiKeyEncrypted,
    this.apiSecretEncrypted,
    this.accessTokenEncrypted,
    this.refreshTokenEncrypted,
    this.config,
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || apiKeyEncrypted != null) {
      map['api_key_encrypted'] = Variable<String>(apiKeyEncrypted);
    }
    if (!nullToAbsent || apiSecretEncrypted != null) {
      map['api_secret_encrypted'] = Variable<String>(apiSecretEncrypted);
    }
    if (!nullToAbsent || accessTokenEncrypted != null) {
      map['access_token_encrypted'] = Variable<String>(accessTokenEncrypted);
    }
    if (!nullToAbsent || refreshTokenEncrypted != null) {
      map['refresh_token_encrypted'] = Variable<String>(refreshTokenEncrypted);
    }
    if (!nullToAbsent || config != null) {
      map['config'] = Variable<String>(config);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IntegrationsTableCompanion toCompanion(bool nullToAbsent) {
    return IntegrationsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      provider: Value(provider),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      apiKeyEncrypted: apiKeyEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(apiKeyEncrypted),
      apiSecretEncrypted: apiSecretEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(apiSecretEncrypted),
      accessTokenEncrypted: accessTokenEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(accessTokenEncrypted),
      refreshTokenEncrypted: refreshTokenEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshTokenEncrypted),
      config: config == null && nullToAbsent
          ? const Value.absent()
          : Value(config),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IntegrationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntegrationsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      provider: serializer.fromJson<String>(json['provider']),
      status: serializer.fromJson<String?>(json['status']),
      apiKeyEncrypted: serializer.fromJson<String?>(json['apiKeyEncrypted']),
      apiSecretEncrypted: serializer.fromJson<String?>(
        json['apiSecretEncrypted'],
      ),
      accessTokenEncrypted: serializer.fromJson<String?>(
        json['accessTokenEncrypted'],
      ),
      refreshTokenEncrypted: serializer.fromJson<String?>(
        json['refreshTokenEncrypted'],
      ),
      config: serializer.fromJson<String?>(json['config']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'provider': serializer.toJson<String>(provider),
      'status': serializer.toJson<String?>(status),
      'apiKeyEncrypted': serializer.toJson<String?>(apiKeyEncrypted),
      'apiSecretEncrypted': serializer.toJson<String?>(apiSecretEncrypted),
      'accessTokenEncrypted': serializer.toJson<String?>(accessTokenEncrypted),
      'refreshTokenEncrypted': serializer.toJson<String?>(
        refreshTokenEncrypted,
      ),
      'config': serializer.toJson<String?>(config),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  IntegrationsTableData copyWith({
    String? id,
    String? businessId,
    String? provider,
    Value<String?> status = const Value.absent(),
    Value<String?> apiKeyEncrypted = const Value.absent(),
    Value<String?> apiSecretEncrypted = const Value.absent(),
    Value<String?> accessTokenEncrypted = const Value.absent(),
    Value<String?> refreshTokenEncrypted = const Value.absent(),
    Value<String?> config = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IntegrationsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    provider: provider ?? this.provider,
    status: status.present ? status.value : this.status,
    apiKeyEncrypted: apiKeyEncrypted.present
        ? apiKeyEncrypted.value
        : this.apiKeyEncrypted,
    apiSecretEncrypted: apiSecretEncrypted.present
        ? apiSecretEncrypted.value
        : this.apiSecretEncrypted,
    accessTokenEncrypted: accessTokenEncrypted.present
        ? accessTokenEncrypted.value
        : this.accessTokenEncrypted,
    refreshTokenEncrypted: refreshTokenEncrypted.present
        ? refreshTokenEncrypted.value
        : this.refreshTokenEncrypted,
    config: config.present ? config.value : this.config,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IntegrationsTableData copyWithCompanion(IntegrationsTableCompanion data) {
    return IntegrationsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      provider: data.provider.present ? data.provider.value : this.provider,
      status: data.status.present ? data.status.value : this.status,
      apiKeyEncrypted: data.apiKeyEncrypted.present
          ? data.apiKeyEncrypted.value
          : this.apiKeyEncrypted,
      apiSecretEncrypted: data.apiSecretEncrypted.present
          ? data.apiSecretEncrypted.value
          : this.apiSecretEncrypted,
      accessTokenEncrypted: data.accessTokenEncrypted.present
          ? data.accessTokenEncrypted.value
          : this.accessTokenEncrypted,
      refreshTokenEncrypted: data.refreshTokenEncrypted.present
          ? data.refreshTokenEncrypted.value
          : this.refreshTokenEncrypted,
      config: data.config.present ? data.config.value : this.config,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntegrationsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('apiKeyEncrypted: $apiKeyEncrypted, ')
          ..write('apiSecretEncrypted: $apiSecretEncrypted, ')
          ..write('accessTokenEncrypted: $accessTokenEncrypted, ')
          ..write('refreshTokenEncrypted: $refreshTokenEncrypted, ')
          ..write('config: $config, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    provider,
    status,
    apiKeyEncrypted,
    apiSecretEncrypted,
    accessTokenEncrypted,
    refreshTokenEncrypted,
    config,
    lastSyncAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntegrationsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.provider == this.provider &&
          other.status == this.status &&
          other.apiKeyEncrypted == this.apiKeyEncrypted &&
          other.apiSecretEncrypted == this.apiSecretEncrypted &&
          other.accessTokenEncrypted == this.accessTokenEncrypted &&
          other.refreshTokenEncrypted == this.refreshTokenEncrypted &&
          other.config == this.config &&
          other.lastSyncAt == this.lastSyncAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IntegrationsTableCompanion
    extends UpdateCompanion<IntegrationsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> provider;
  final Value<String?> status;
  final Value<String?> apiKeyEncrypted;
  final Value<String?> apiSecretEncrypted;
  final Value<String?> accessTokenEncrypted;
  final Value<String?> refreshTokenEncrypted;
  final Value<String?> config;
  final Value<DateTime?> lastSyncAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const IntegrationsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.provider = const Value.absent(),
    this.status = const Value.absent(),
    this.apiKeyEncrypted = const Value.absent(),
    this.apiSecretEncrypted = const Value.absent(),
    this.accessTokenEncrypted = const Value.absent(),
    this.refreshTokenEncrypted = const Value.absent(),
    this.config = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntegrationsTableCompanion.insert({
    required String id,
    required String businessId,
    required String provider,
    this.status = const Value.absent(),
    this.apiKeyEncrypted = const Value.absent(),
    this.apiSecretEncrypted = const Value.absent(),
    this.accessTokenEncrypted = const Value.absent(),
    this.refreshTokenEncrypted = const Value.absent(),
    this.config = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       provider = Value(provider);
  static Insertable<IntegrationsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? provider,
    Expression<String>? status,
    Expression<String>? apiKeyEncrypted,
    Expression<String>? apiSecretEncrypted,
    Expression<String>? accessTokenEncrypted,
    Expression<String>? refreshTokenEncrypted,
    Expression<String>? config,
    Expression<DateTime>? lastSyncAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (provider != null) 'provider': provider,
      if (status != null) 'status': status,
      if (apiKeyEncrypted != null) 'api_key_encrypted': apiKeyEncrypted,
      if (apiSecretEncrypted != null)
        'api_secret_encrypted': apiSecretEncrypted,
      if (accessTokenEncrypted != null)
        'access_token_encrypted': accessTokenEncrypted,
      if (refreshTokenEncrypted != null)
        'refresh_token_encrypted': refreshTokenEncrypted,
      if (config != null) 'config': config,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntegrationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? provider,
    Value<String?>? status,
    Value<String?>? apiKeyEncrypted,
    Value<String?>? apiSecretEncrypted,
    Value<String?>? accessTokenEncrypted,
    Value<String?>? refreshTokenEncrypted,
    Value<String?>? config,
    Value<DateTime?>? lastSyncAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return IntegrationsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      apiKeyEncrypted: apiKeyEncrypted ?? this.apiKeyEncrypted,
      apiSecretEncrypted: apiSecretEncrypted ?? this.apiSecretEncrypted,
      accessTokenEncrypted: accessTokenEncrypted ?? this.accessTokenEncrypted,
      refreshTokenEncrypted:
          refreshTokenEncrypted ?? this.refreshTokenEncrypted,
      config: config ?? this.config,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (apiKeyEncrypted.present) {
      map['api_key_encrypted'] = Variable<String>(apiKeyEncrypted.value);
    }
    if (apiSecretEncrypted.present) {
      map['api_secret_encrypted'] = Variable<String>(apiSecretEncrypted.value);
    }
    if (accessTokenEncrypted.present) {
      map['access_token_encrypted'] = Variable<String>(
        accessTokenEncrypted.value,
      );
    }
    if (refreshTokenEncrypted.present) {
      map['refresh_token_encrypted'] = Variable<String>(
        refreshTokenEncrypted.value,
      );
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntegrationsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('apiKeyEncrypted: $apiKeyEncrypted, ')
          ..write('apiSecretEncrypted: $apiSecretEncrypted, ')
          ..write('accessTokenEncrypted: $accessTokenEncrypted, ')
          ..write('refreshTokenEncrypted: $refreshTokenEncrypted, ')
          ..write('config: $config, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTableTable extends SyncQueueItemsTable
    with TableInfo<$SyncQueueItemsTableTable, SyncQueueItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    entityType,
    entityId,
    timestamp,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItemsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
    );
  }

  @override
  $SyncQueueItemsTableTable createAlias(String alias) {
    return $SyncQueueItemsTableTable(attachedDatabase, alias);
  }
}

class SyncQueueItemsTableData extends DataClass
    implements Insertable<SyncQueueItemsTableData> {
  /// Monotonic sequence number / primary key. Also the FIFO ordering key.
  final int id;

  /// The kind of write: `create`, `update`, or `delete`.
  ///
  /// Stored as plain text (the [SyncOperationType] enum name) to match how the
  /// rest of the Tổng Tài schema persists enums as strings (see
  /// `tongtai_enums.dart`).
  final String operationType;

  /// Entity kind the operation targets, e.g. `product`, `order`, `customer`.
  final String entityType;

  /// Primary key of the affected row in its own table.
  final String entityId;

  /// Logical timestamp of the operation. Drives last-write-wins conflict
  /// resolution during replay; NOT used for ordering (that is [id]).
  final DateTime timestamp;

  /// JSON snapshot of the mutated entity (the fields to replay).
  ///
  /// Nullable because a DELETE needs no body — [entityType] + [entityId] fully
  /// describe it.
  final String? payload;
  const SyncQueueItemsTableData({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    return map;
  }

  SyncQueueItemsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsTableCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      timestamp: Value(timestamp),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
    );
  }

  factory SyncQueueItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      payload: serializer.fromJson<String?>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'payload': serializer.toJson<String?>(payload),
    };
  }

  SyncQueueItemsTableData copyWith({
    int? id,
    String? operationType,
    String? entityType,
    String? entityId,
    DateTime? timestamp,
    Value<String?> payload = const Value.absent(),
  }) => SyncQueueItemsTableData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    timestamp: timestamp ?? this.timestamp,
    payload: payload.present ? payload.value : this.payload,
  );
  SyncQueueItemsTableData copyWithCompanion(SyncQueueItemsTableCompanion data) {
    return SyncQueueItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsTableData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, operationType, entityType, entityId, timestamp, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItemsTableData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.timestamp == this.timestamp &&
          other.payload == this.payload);
}

class SyncQueueItemsTableCompanion
    extends UpdateCompanion<SyncQueueItemsTableData> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<DateTime> timestamp;
  final Value<String?> payload;
  const SyncQueueItemsTableCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.payload = const Value.absent(),
  });
  SyncQueueItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    required String entityType,
    required String entityId,
    this.timestamp = const Value.absent(),
    this.payload = const Value.absent(),
  }) : operationType = Value(operationType),
       entityType = Value(entityType),
       entityId = Value(entityId);
  static Insertable<SyncQueueItemsTableData> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<DateTime>? timestamp,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (timestamp != null) 'timestamp': timestamp,
      if (payload != null) 'payload': payload,
    });
  }

  SyncQueueItemsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<DateTime>? timestamp,
    Value<String?>? payload,
  }) {
    return SyncQueueItemsTableCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $SupplierFavoritesTableTable extends SupplierFavoritesTable
    with TableInfo<$SupplierFavoritesTableTable, SupplierFavoritesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplierFavoritesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  @override
  List<GeneratedColumn> get $columns => [supplierId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplier_favorites_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplierFavoritesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {supplierId};
  @override
  SupplierFavoritesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplierFavoritesTableData(
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $SupplierFavoritesTableTable createAlias(String alias) {
    return $SupplierFavoritesTableTable(attachedDatabase, alias);
  }
}

class SupplierFavoritesTableData extends DataClass
    implements Insertable<SupplierFavoritesTableData> {
  /// Id of the favorited supplier (matches `Supplier.id`). Primary key, so each
  /// supplier appears at most once.
  final String supplierId;

  /// When the supplier was added to favorites. Defaults to now on insert and
  /// drives the most-recently-added ordering of the Favorites list.
  final DateTime addedAt;
  const SupplierFavoritesTableData({
    required this.supplierId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['supplier_id'] = Variable<String>(supplierId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SupplierFavoritesTableCompanion toCompanion(bool nullToAbsent) {
    return SupplierFavoritesTableCompanion(
      supplierId: Value(supplierId),
      addedAt: Value(addedAt),
    );
  }

  factory SupplierFavoritesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplierFavoritesTableData(
      supplierId: serializer.fromJson<String>(json['supplierId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'supplierId': serializer.toJson<String>(supplierId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SupplierFavoritesTableData copyWith({
    String? supplierId,
    DateTime? addedAt,
  }) => SupplierFavoritesTableData(
    supplierId: supplierId ?? this.supplierId,
    addedAt: addedAt ?? this.addedAt,
  );
  SupplierFavoritesTableData copyWithCompanion(
    SupplierFavoritesTableCompanion data,
  ) {
    return SupplierFavoritesTableData(
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplierFavoritesTableData(')
          ..write('supplierId: $supplierId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(supplierId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierFavoritesTableData &&
          other.supplierId == this.supplierId &&
          other.addedAt == this.addedAt);
}

class SupplierFavoritesTableCompanion
    extends UpdateCompanion<SupplierFavoritesTableData> {
  final Value<String> supplierId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const SupplierFavoritesTableCompanion({
    this.supplierId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SupplierFavoritesTableCompanion.insert({
    required String supplierId,
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : supplierId = Value(supplierId);
  static Insertable<SupplierFavoritesTableData> custom({
    Expression<String>? supplierId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (supplierId != null) 'supplier_id': supplierId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SupplierFavoritesTableCompanion copyWith({
    Value<String>? supplierId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return SupplierFavoritesTableCompanion(
      supplierId: supplierId ?? this.supplierId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplierFavoritesTableCompanion(')
          ..write('supplierId: $supplierId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTableTable extends ChatMessagesTable
    with TableInfo<$ChatMessagesTableTable, ChatMessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentNameMeta = const VerificationMeta(
    'attachmentName',
  );
  @override
  late final GeneratedColumn<String> attachmentName = GeneratedColumn<String>(
    'attachment_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    sender,
    body,
    sentAt,
    status,
    attachmentPath,
    attachmentName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('attachment_name')) {
      context.handle(
        _attachmentNameMeta,
        attachmentName.isAcceptableOrUnknown(
          data['attachment_name']!,
          _attachmentNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      attachmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_name'],
      ),
    );
  }

  @override
  $ChatMessagesTableTable createAlias(String alias) {
    return $ChatMessagesTableTable(attachedDatabase, alias);
  }
}

class ChatMessagesTableData extends DataClass
    implements Insertable<ChatMessagesTableData> {
  final String id;

  /// Conversation the message belongs to. The MVP has a single Copilot
  /// conversation ('default'); threads (WTM-84) can partition on this later.
  final String conversationId;

  /// 'seller' or 'assistant' — `ChatSender.name`.
  final String sender;

  /// Message text (may be empty for attachment-only messages).
  final String body;

  /// When the message was composed.
  final DateTime sentAt;

  /// Local delivery state — `ChatMessageStatus.name` (AC2: read status).
  final String status;

  /// Local file path/name of an attachment, when present. Paths never leave
  /// the device (ADR-TON-004).
  final String? attachmentPath;
  final String? attachmentName;
  const ChatMessagesTableData({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.sentAt,
    required this.status,
    this.attachmentPath,
    this.attachmentName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender'] = Variable<String>(sender);
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    if (!nullToAbsent || attachmentName != null) {
      map['attachment_name'] = Variable<String>(attachmentName);
    }
    return map;
  }

  ChatMessagesTableCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesTableCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      sender: Value(sender),
      body: Value(body),
      sentAt: Value(sentAt),
      status: Value(status),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      attachmentName: attachmentName == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentName),
    );
  }

  factory ChatMessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      sender: serializer.fromJson<String>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      status: serializer.fromJson<String>(json['status']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      attachmentName: serializer.fromJson<String?>(json['attachmentName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'sender': serializer.toJson<String>(sender),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'status': serializer.toJson<String>(status),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'attachmentName': serializer.toJson<String?>(attachmentName),
    };
  }

  ChatMessagesTableData copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? body,
    DateTime? sentAt,
    String? status,
    Value<String?> attachmentPath = const Value.absent(),
    Value<String?> attachmentName = const Value.absent(),
  }) => ChatMessagesTableData(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    sentAt: sentAt ?? this.sentAt,
    status: status ?? this.status,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    attachmentName: attachmentName.present
        ? attachmentName.value
        : this.attachmentName,
  );
  ChatMessagesTableData copyWithCompanion(ChatMessagesTableCompanion data) {
    return ChatMessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      status: data.status.present ? data.status.value : this.status,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      attachmentName: data.attachmentName.present
          ? data.attachmentName.value
          : this.attachmentName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesTableData(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('attachmentName: $attachmentName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    sender,
    body,
    sentAt,
    status,
    attachmentPath,
    attachmentName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessagesTableData &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.status == this.status &&
          other.attachmentPath == this.attachmentPath &&
          other.attachmentName == this.attachmentName);
}

class ChatMessagesTableCompanion
    extends UpdateCompanion<ChatMessagesTableData> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> sender;
  final Value<String> body;
  final Value<DateTime> sentAt;
  final Value<String> status;
  final Value<String?> attachmentPath;
  final Value<String?> attachmentName;
  final Value<int> rowid;
  const ChatMessagesTableCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.attachmentName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesTableCompanion.insert({
    required String id,
    this.conversationId = const Value.absent(),
    required String sender,
    required String body,
    required DateTime sentAt,
    required String status,
    this.attachmentPath = const Value.absent(),
    this.attachmentName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sender = Value(sender),
       body = Value(body),
       sentAt = Value(sentAt),
       status = Value(status);
  static Insertable<ChatMessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<DateTime>? sentAt,
    Expression<String>? status,
    Expression<String>? attachmentPath,
    Expression<String>? attachmentName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (sender != null) 'sender': sender,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (status != null) 'status': status,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (attachmentName != null) 'attachment_name': attachmentName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? sender,
    Value<String>? body,
    Value<DateTime>? sentAt,
    Value<String>? status,
    Value<String?>? attachmentPath,
    Value<String?>? attachmentName,
    Value<int>? rowid,
  }) {
    return ChatMessagesTableCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (attachmentName.present) {
      map['attachment_name'] = Variable<String>(attachmentName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('attachmentName: $attachmentName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BusinessesTableTable businessesTable = $BusinessesTableTable(
    this,
  );
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $ProducersTableTable producersTable = $ProducersTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $ChannelsTableTable channelsTable = $ChannelsTableTable(this);
  late final $OrdersTableTable ordersTable = $OrdersTableTable(this);
  late final $OpportunitiesTableTable opportunitiesTable =
      $OpportunitiesTableTable(this);
  late final $JourneysTableTable journeysTable = $JourneysTableTable(this);
  late final $JourneyStepsTableTable journeyStepsTable =
      $JourneyStepsTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $DocumentsTableTable documentsTable = $DocumentsTableTable(this);
  late final $AlertsTableTable alertsTable = $AlertsTableTable(this);
  late final $AIChatTableTable aIChatTable = $AIChatTableTable(this);
  late final $IntegrationsTableTable integrationsTable =
      $IntegrationsTableTable(this);
  late final $SyncQueueItemsTableTable syncQueueItemsTable =
      $SyncQueueItemsTableTable(this);
  late final $SupplierFavoritesTableTable supplierFavoritesTable =
      $SupplierFavoritesTableTable(this);
  late final $ChatMessagesTableTable chatMessagesTable =
      $ChatMessagesTableTable(this);
  late final Index producersBusinessId = Index(
    'producers_business_id',
    'CREATE INDEX producers_business_id ON producers_table (business_id)',
  );
  late final Index productsBusinessId = Index(
    'products_business_id',
    'CREATE INDEX products_business_id ON products_table (business_id)',
  );
  late final Index productsSku = Index(
    'products_sku',
    'CREATE INDEX products_sku ON products_table (sku)',
  );
  late final Index productsCategory = Index(
    'products_category',
    'CREATE INDEX products_category ON products_table (category)',
  );
  late final Index productsSupplierId = Index(
    'products_supplier_id',
    'CREATE INDEX products_supplier_id ON products_table (supplier_id)',
  );
  late final Index customersBusinessId = Index(
    'customers_business_id',
    'CREATE INDEX customers_business_id ON customers_table (business_id)',
  );
  late final Index ordersBusinessId = Index(
    'orders_business_id',
    'CREATE INDEX orders_business_id ON orders_table (business_id)',
  );
  late final Index ordersCustomerId = Index(
    'orders_customer_id',
    'CREATE INDEX orders_customer_id ON orders_table (customer_id)',
  );
  late final Index ordersOrderDate = Index(
    'orders_order_date',
    'CREATE INDEX orders_order_date ON orders_table (order_date)',
  );
  late final Index opportunitiesBusinessId = Index(
    'opportunities_business_id',
    'CREATE INDEX opportunities_business_id ON opportunities_table (business_id)',
  );
  late final Index journeysBusinessId = Index(
    'journeys_business_id',
    'CREATE INDEX journeys_business_id ON journeys_table (business_id)',
  );
  late final Index transactionsBusinessId = Index(
    'transactions_business_id',
    'CREATE INDEX transactions_business_id ON transactions_table (business_id)',
  );
  late final Index transactionsDate = Index(
    'transactions_date',
    'CREATE INDEX transactions_date ON transactions_table (date)',
  );
  late final Index chatMessagesConversation = Index(
    'chat_messages_conversation',
    'CREATE INDEX chat_messages_conversation ON chat_messages_table (conversation_id)',
  );
  late final Index chatMessagesSentAt = Index(
    'chat_messages_sent_at',
    'CREATE INDEX chat_messages_sent_at ON chat_messages_table (sent_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    businessesTable,
    usersTable,
    producersTable,
    productsTable,
    customersTable,
    channelsTable,
    ordersTable,
    opportunitiesTable,
    journeysTable,
    journeyStepsTable,
    transactionsTable,
    documentsTable,
    alertsTable,
    aIChatTable,
    integrationsTable,
    syncQueueItemsTable,
    supplierFavoritesTable,
    chatMessagesTable,
    producersBusinessId,
    productsBusinessId,
    productsSku,
    productsCategory,
    productsSupplierId,
    customersBusinessId,
    ordersBusinessId,
    ordersCustomerId,
    ordersOrderDate,
    opportunitiesBusinessId,
    journeysBusinessId,
    transactionsBusinessId,
    transactionsDate,
    chatMessagesConversation,
    chatMessagesSentAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('producers_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('products_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'producers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('products_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customers_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('orders_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('opportunities_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journeys_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'journeys_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journey_steps_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('documents_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('alerts_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('a_i_chat_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'businesses_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('integrations_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BusinessesTableTableCreateCompanionBuilder =
    BusinessesTableCompanion Function({
      required String id,
      required String ownerId,
      required String name,
      Value<String?> industry,
      Value<String?> country,
      Value<String> currency,
      Value<double?> annualRevenue,
      Value<int?> employeeCount,
      Value<String?> stage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BusinessesTableTableUpdateCompanionBuilder =
    BusinessesTableCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> name,
      Value<String?> industry,
      Value<String?> country,
      Value<String> currency,
      Value<double?> annualRevenue,
      Value<int?> employeeCount,
      Value<String?> stage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BusinessesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BusinessesTableTable,
          BusinessesTableData
        > {
  $$BusinessesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _ownerIdTable(_$AppDatabase db) =>
      db.usersTable.createAlias('businesses_table__owner_id__users_table__id');

  $$UsersTableTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$UsersTableTable, List<UsersTableData>>
  _usersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.usersTable,
    aliasName: 'businesses_table__id__users_table__business_id',
  );

  $$UsersTableTableProcessedTableManager get usersTableRefs {
    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProducersTableTable, List<ProducersTableData>>
  _producersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.producersTable,
    aliasName: 'businesses_table__id__producers_table__business_id',
  );

  $$ProducersTableTableProcessedTableManager get producersTableRefs {
    final manager = $$ProducersTableTableTableManager(
      $_db,
      $_db.producersTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_producersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProductsTableTable, List<ProductsTableData>>
  _productsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productsTable,
    aliasName: 'businesses_table__id__products_table__business_id',
  );

  $$ProductsTableTableProcessedTableManager get productsTableRefs {
    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CustomersTableTable, List<CustomersTableData>>
  _customersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customersTable,
    aliasName: 'businesses_table__id__customers_table__business_id',
  );

  $$CustomersTableTableProcessedTableManager get customersTableRefs {
    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_customersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChannelsTableTable, List<ChannelsTableData>>
  _channelsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.channelsTable,
    aliasName: 'businesses_table__id__channels_table__business_id',
  );

  $$ChannelsTableTableProcessedTableManager get channelsTableRefs {
    final manager = $$ChannelsTableTableTableManager(
      $_db,
      $_db.channelsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OrdersTableTable, List<OrdersTableData>>
  _ordersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordersTable,
    aliasName: 'businesses_table__id__orders_table__business_id',
  );

  $$OrdersTableTableProcessedTableManager get ordersTableRefs {
    final manager = $$OrdersTableTableTableManager(
      $_db,
      $_db.ordersTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $OpportunitiesTableTable,
    List<OpportunitiesTableData>
  >
  _opportunitiesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.opportunitiesTable,
        aliasName: 'businesses_table__id__opportunities_table__business_id',
      );

  $$OpportunitiesTableTableProcessedTableManager get opportunitiesTableRefs {
    final manager = $$OpportunitiesTableTableTableManager(
      $_db,
      $_db.opportunitiesTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _opportunitiesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JourneysTableTable, List<JourneysTableData>>
  _journeysTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.journeysTable,
    aliasName: 'businesses_table__id__journeys_table__business_id',
  );

  $$JourneysTableTableProcessedTableManager get journeysTableRefs {
    final manager = $$JourneysTableTableTableManager(
      $_db,
      $_db.journeysTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journeysTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransactionsTableTable,
    List<TransactionsTableData>
  >
  _transactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsTable,
        aliasName: 'businesses_table__id__transactions_table__business_id',
      );

  $$TransactionsTableTableProcessedTableManager get transactionsTableRefs {
    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DocumentsTableTable, List<DocumentsTableData>>
  _documentsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documentsTable,
    aliasName: 'businesses_table__id__documents_table__business_id',
  );

  $$DocumentsTableTableProcessedTableManager get documentsTableRefs {
    final manager = $$DocumentsTableTableTableManager(
      $_db,
      $_db.documentsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlertsTableTable, List<AlertsTableData>>
  _alertsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.alertsTable,
    aliasName: 'businesses_table__id__alerts_table__business_id',
  );

  $$AlertsTableTableProcessedTableManager get alertsTableRefs {
    final manager = $$AlertsTableTableTableManager(
      $_db,
      $_db.alertsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AIChatTableTable, List<AIChatTableData>>
  _aIChatTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.aIChatTable,
    aliasName: 'businesses_table__id__a_i_chat_table__business_id',
  );

  $$AIChatTableTableProcessedTableManager get aIChatTableRefs {
    final manager = $$AIChatTableTableTableManager(
      $_db,
      $_db.aIChatTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aIChatTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IntegrationsTableTable,
    List<IntegrationsTableData>
  >
  _integrationsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.integrationsTable,
        aliasName: 'businesses_table__id__integrations_table__business_id',
      );

  $$IntegrationsTableTableProcessedTableManager get integrationsTableRefs {
    final manager = $$IntegrationsTableTableTableManager(
      $_db,
      $_db.integrationsTable,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _integrationsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BusinessesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualRevenue => $composableBuilder(
    column: $table.annualRevenue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get employeeCount => $composableBuilder(
    column: $table.employeeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get ownerId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> usersTableRefs(
    Expression<bool> Function($$UsersTableTableFilterComposer f) f,
  ) {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> producersTableRefs(
    Expression<bool> Function($$ProducersTableTableFilterComposer f) f,
  ) {
    final $$ProducersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.producersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProducersTableTableFilterComposer(
            $db: $db,
            $table: $db.producersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productsTableRefs(
    Expression<bool> Function($$ProductsTableTableFilterComposer f) f,
  ) {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customersTableRefs(
    Expression<bool> Function($$CustomersTableTableFilterComposer f) f,
  ) {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> channelsTableRefs(
    Expression<bool> Function($$ChannelsTableTableFilterComposer f) f,
  ) {
    final $$ChannelsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableTableFilterComposer(
            $db: $db,
            $table: $db.channelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ordersTableRefs(
    Expression<bool> Function($$OrdersTableTableFilterComposer f) f,
  ) {
    final $$OrdersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableFilterComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> opportunitiesTableRefs(
    Expression<bool> Function($$OpportunitiesTableTableFilterComposer f) f,
  ) {
    final $$OpportunitiesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.opportunitiesTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OpportunitiesTableTableFilterComposer(
            $db: $db,
            $table: $db.opportunitiesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> journeysTableRefs(
    Expression<bool> Function($$JourneysTableTableFilterComposer f) f,
  ) {
    final $$JourneysTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeysTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableTableFilterComposer(
            $db: $db,
            $table: $db.journeysTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsTableRefs(
    Expression<bool> Function($$TransactionsTableTableFilterComposer f) f,
  ) {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> documentsTableRefs(
    Expression<bool> Function($$DocumentsTableTableFilterComposer f) f,
  ) {
    final $$DocumentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableTableFilterComposer(
            $db: $db,
            $table: $db.documentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> alertsTableRefs(
    Expression<bool> Function($$AlertsTableTableFilterComposer f) f,
  ) {
    final $$AlertsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableTableFilterComposer(
            $db: $db,
            $table: $db.alertsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> aIChatTableRefs(
    Expression<bool> Function($$AIChatTableTableFilterComposer f) f,
  ) {
    final $$AIChatTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aIChatTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AIChatTableTableFilterComposer(
            $db: $db,
            $table: $db.aIChatTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> integrationsTableRefs(
    Expression<bool> Function($$IntegrationsTableTableFilterComposer f) f,
  ) {
    final $$IntegrationsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.integrationsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntegrationsTableTableFilterComposer(
            $db: $db,
            $table: $db.integrationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BusinessesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRevenue => $composableBuilder(
    column: $table.annualRevenue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get employeeCount => $composableBuilder(
    column: $table.employeeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get ownerId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BusinessesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get industry =>
      $composableBuilder(column: $table.industry, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get annualRevenue => $composableBuilder(
    column: $table.annualRevenue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get employeeCount => $composableBuilder(
    column: $table.employeeCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get ownerId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> usersTableRefs<T extends Object>(
    Expression<T> Function($$UsersTableTableAnnotationComposer a) f,
  ) {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> producersTableRefs<T extends Object>(
    Expression<T> Function($$ProducersTableTableAnnotationComposer a) f,
  ) {
    final $$ProducersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.producersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProducersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.producersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> productsTableRefs<T extends Object>(
    Expression<T> Function($$ProductsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customersTableRefs<T extends Object>(
    Expression<T> Function($$CustomersTableTableAnnotationComposer a) f,
  ) {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> channelsTableRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.channelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ordersTableRefs<T extends Object>(
    Expression<T> Function($$OrdersTableTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> opportunitiesTableRefs<T extends Object>(
    Expression<T> Function($$OpportunitiesTableTableAnnotationComposer a) f,
  ) {
    final $$OpportunitiesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.opportunitiesTable,
          getReferencedColumn: (t) => t.businessId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OpportunitiesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.opportunitiesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> journeysTableRefs<T extends Object>(
    Expression<T> Function($$JourneysTableTableAnnotationComposer a) f,
  ) {
    final $$JourneysTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeysTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableTableAnnotationComposer(
            $db: $db,
            $table: $db.journeysTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.businessId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> documentsTableRefs<T extends Object>(
    Expression<T> Function($$DocumentsTableTableAnnotationComposer a) f,
  ) {
    final $$DocumentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.documentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> alertsTableRefs<T extends Object>(
    Expression<T> Function($$AlertsTableTableAnnotationComposer a) f,
  ) {
    final $$AlertsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertsTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.alertsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> aIChatTableRefs<T extends Object>(
    Expression<T> Function($$AIChatTableTableAnnotationComposer a) f,
  ) {
    final $$AIChatTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aIChatTable,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AIChatTableTableAnnotationComposer(
            $db: $db,
            $table: $db.aIChatTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> integrationsTableRefs<T extends Object>(
    Expression<T> Function($$IntegrationsTableTableAnnotationComposer a) f,
  ) {
    final $$IntegrationsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.integrationsTable,
          getReferencedColumn: (t) => t.businessId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntegrationsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.integrationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BusinessesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessesTableTable,
          BusinessesTableData,
          $$BusinessesTableTableFilterComposer,
          $$BusinessesTableTableOrderingComposer,
          $$BusinessesTableTableAnnotationComposer,
          $$BusinessesTableTableCreateCompanionBuilder,
          $$BusinessesTableTableUpdateCompanionBuilder,
          (BusinessesTableData, $$BusinessesTableTableReferences),
          BusinessesTableData,
          PrefetchHooks Function({
            bool ownerId,
            bool usersTableRefs,
            bool producersTableRefs,
            bool productsTableRefs,
            bool customersTableRefs,
            bool channelsTableRefs,
            bool ordersTableRefs,
            bool opportunitiesTableRefs,
            bool journeysTableRefs,
            bool transactionsTableRefs,
            bool documentsTableRefs,
            bool alertsTableRefs,
            bool aIChatTableRefs,
            bool integrationsTableRefs,
          })
        > {
  $$BusinessesTableTableTableManager(
    _$AppDatabase db,
    $BusinessesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> industry = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double?> annualRevenue = const Value.absent(),
                Value<int?> employeeCount = const Value.absent(),
                Value<String?> stage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesTableCompanion(
                id: id,
                ownerId: ownerId,
                name: name,
                industry: industry,
                country: country,
                currency: currency,
                annualRevenue: annualRevenue,
                employeeCount: employeeCount,
                stage: stage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String name,
                Value<String?> industry = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double?> annualRevenue = const Value.absent(),
                Value<int?> employeeCount = const Value.absent(),
                Value<String?> stage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesTableCompanion.insert(
                id: id,
                ownerId: ownerId,
                name: name,
                industry: industry,
                country: country,
                currency: currency,
                annualRevenue: annualRevenue,
                employeeCount: employeeCount,
                stage: stage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BusinessesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerId = false,
                usersTableRefs = false,
                producersTableRefs = false,
                productsTableRefs = false,
                customersTableRefs = false,
                channelsTableRefs = false,
                ordersTableRefs = false,
                opportunitiesTableRefs = false,
                journeysTableRefs = false,
                transactionsTableRefs = false,
                documentsTableRefs = false,
                alertsTableRefs = false,
                aIChatTableRefs = false,
                integrationsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (usersTableRefs) db.usersTable,
                    if (producersTableRefs) db.producersTable,
                    if (productsTableRefs) db.productsTable,
                    if (customersTableRefs) db.customersTable,
                    if (channelsTableRefs) db.channelsTable,
                    if (ordersTableRefs) db.ordersTable,
                    if (opportunitiesTableRefs) db.opportunitiesTable,
                    if (journeysTableRefs) db.journeysTable,
                    if (transactionsTableRefs) db.transactionsTable,
                    if (documentsTableRefs) db.documentsTable,
                    if (alertsTableRefs) db.alertsTable,
                    if (aIChatTableRefs) db.aIChatTable,
                    if (integrationsTableRefs) db.integrationsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerId,
                                    referencedTable:
                                        $$BusinessesTableTableReferences
                                            ._ownerIdTable(db),
                                    referencedColumn:
                                        $$BusinessesTableTableReferences
                                            ._ownerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (usersTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          UsersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._usersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).usersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (producersTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          ProducersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._producersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).producersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (productsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          ProductsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._productsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customersTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          CustomersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._customersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (channelsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          ChannelsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._channelsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).channelsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ordersTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          OrdersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._ordersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).ordersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (opportunitiesTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          OpportunitiesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._opportunitiesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).opportunitiesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (journeysTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          JourneysTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._journeysTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).journeysTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          TransactionsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._transactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (documentsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          DocumentsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._documentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).documentsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (alertsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          AlertsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._alertsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).alertsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (aIChatTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          AIChatTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._aIChatTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).aIChatTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (integrationsTableRefs)
                        await $_getPrefetchedData<
                          BusinessesTableData,
                          $BusinessesTableTable,
                          IntegrationsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BusinessesTableTableReferences
                              ._integrationsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BusinessesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).integrationsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BusinessesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessesTableTable,
      BusinessesTableData,
      $$BusinessesTableTableFilterComposer,
      $$BusinessesTableTableOrderingComposer,
      $$BusinessesTableTableAnnotationComposer,
      $$BusinessesTableTableCreateCompanionBuilder,
      $$BusinessesTableTableUpdateCompanionBuilder,
      (BusinessesTableData, $$BusinessesTableTableReferences),
      BusinessesTableData,
      PrefetchHooks Function({
        bool ownerId,
        bool usersTableRefs,
        bool producersTableRefs,
        bool productsTableRefs,
        bool customersTableRefs,
        bool channelsTableRefs,
        bool ordersTableRefs,
        bool opportunitiesTableRefs,
        bool journeysTableRefs,
        bool transactionsTableRefs,
        bool documentsTableRefs,
        bool alertsTableRefs,
        bool aIChatTableRefs,
        bool integrationsTableRefs,
      })
    >;
typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      required String id,
      required String email,
      Value<String?> businessId,
      required String name,
      Value<String?> language,
      Value<String?> timezone,
      Value<String?> preferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String?> businessId,
      Value<String> name,
      Value<String?> language,
      Value<String?> timezone,
      Value<String?> preferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UsersTableTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTableTable, UsersTableData> {
  $$UsersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('users_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager? get businessId {
    final $_column = $_itemColumn<String>('business_id');
    if ($_column == null) return null;
    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BusinessesTableTable, List<BusinessesTableData>>
  _businessesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.businessesTable,
    aliasName: 'users_table__id__businesses_table__owner_id',
  );

  $$BusinessesTableTableProcessedTableManager get businessesTableRefs {
    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _businessesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AIChatTableTable, List<AIChatTableData>>
  _aIChatTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.aIChatTable,
    aliasName: 'users_table__id__a_i_chat_table__user_id',
  );

  $$AIChatTableTableProcessedTableManager get aIChatTableRefs {
    final manager = $$AIChatTableTableTableManager(
      $_db,
      $_db.aIChatTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aIChatTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferences => $composableBuilder(
    column: $table.preferences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> businessesTableRefs(
    Expression<bool> Function($$BusinessesTableTableFilterComposer f) f,
  ) {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> aIChatTableRefs(
    Expression<bool> Function($$AIChatTableTableFilterComposer f) f,
  ) {
    final $$AIChatTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aIChatTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AIChatTableTableFilterComposer(
            $db: $db,
            $table: $db.aIChatTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferences => $composableBuilder(
    column: $table.preferences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get preferences => $composableBuilder(
    column: $table.preferences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> businessesTableRefs<T extends Object>(
    Expression<T> Function($$BusinessesTableTableAnnotationComposer a) f,
  ) {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> aIChatTableRefs<T extends Object>(
    Expression<T> Function($$AIChatTableTableAnnotationComposer a) f,
  ) {
    final $$AIChatTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aIChatTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AIChatTableTableAnnotationComposer(
            $db: $db,
            $table: $db.aIChatTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTableTable,
          UsersTableData,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UsersTableData, $$UsersTableTableReferences),
          UsersTableData,
          PrefetchHooks Function({
            bool businessId,
            bool businessesTableRefs,
            bool aIChatTableRefs,
          })
        > {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<String?> preferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                email: email,
                businessId: businessId,
                name: name,
                language: language,
                timezone: timezone,
                preferences: preferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                Value<String?> businessId = const Value.absent(),
                required String name,
                Value<String?> language = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<String?> preferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                email: email,
                businessId: businessId,
                name: name,
                language: language,
                timezone: timezone,
                preferences: preferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UsersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                businessesTableRefs = false,
                aIChatTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (businessesTableRefs) db.businessesTable,
                    if (aIChatTableRefs) db.aIChatTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable: $$UsersTableTableReferences
                                        ._businessIdTable(db),
                                    referencedColumn:
                                        $$UsersTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (businessesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          BusinessesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._businessesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).businessesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (aIChatTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          AIChatTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._aIChatTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).aIChatTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTableTable,
      UsersTableData,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UsersTableData, $$UsersTableTableReferences),
      UsersTableData,
      PrefetchHooks Function({
        bool businessId,
        bool businessesTableRefs,
        bool aIChatTableRefs,
      })
    >;
typedef $$ProducersTableTableCreateCompanionBuilder =
    ProducersTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String?> category,
      Value<String?> country,
      Value<double?> rating,
      Value<double?> reliabilityScore,
      Value<double?> minOrderQty,
      Value<int?> leadTimeDays,
      Value<String?> certifications,
      Value<String?> contactEmail,
      Value<String?> contactPhone,
      Value<String?> externalId,
      Value<String?> externalSource,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ProducersTableTableUpdateCompanionBuilder =
    ProducersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String?> category,
      Value<String?> country,
      Value<double?> rating,
      Value<double?> reliabilityScore,
      Value<double?> minOrderQty,
      Value<int?> leadTimeDays,
      Value<String?> certifications,
      Value<String?> contactEmail,
      Value<String?> contactPhone,
      Value<String?> externalId,
      Value<String?> externalSource,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProducersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProducersTableTable,
          ProducersTableData
        > {
  $$ProducersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('producers_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProductsTableTable, List<ProductsTableData>>
  _productsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productsTable,
    aliasName: 'producers_table__id__products_table__supplier_id',
  );

  $$ProductsTableTableProcessedTableManager get productsTableRefs {
    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProducersTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProducersTableTable> {
  $$ProducersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reliabilityScore => $composableBuilder(
    column: $table.reliabilityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minOrderQty => $composableBuilder(
    column: $table.minOrderQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactEmail => $composableBuilder(
    column: $table.contactEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productsTableRefs(
    Expression<bool> Function($$ProductsTableTableFilterComposer f) f,
  ) {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProducersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProducersTableTable> {
  $$ProducersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reliabilityScore => $composableBuilder(
    column: $table.reliabilityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minOrderQty => $composableBuilder(
    column: $table.minOrderQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactEmail => $composableBuilder(
    column: $table.contactEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProducersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProducersTableTable> {
  $$ProducersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get reliabilityScore => $composableBuilder(
    column: $table.reliabilityScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minOrderQty => $composableBuilder(
    column: $table.minOrderQty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leadTimeDays => $composableBuilder(
    column: $table.leadTimeDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certifications => $composableBuilder(
    column: $table.certifications,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactEmail => $composableBuilder(
    column: $table.contactEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productsTableRefs<T extends Object>(
    Expression<T> Function($$ProductsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProducersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProducersTableTable,
          ProducersTableData,
          $$ProducersTableTableFilterComposer,
          $$ProducersTableTableOrderingComposer,
          $$ProducersTableTableAnnotationComposer,
          $$ProducersTableTableCreateCompanionBuilder,
          $$ProducersTableTableUpdateCompanionBuilder,
          (ProducersTableData, $$ProducersTableTableReferences),
          ProducersTableData,
          PrefetchHooks Function({bool businessId, bool productsTableRefs})
        > {
  $$ProducersTableTableTableManager(
    _$AppDatabase db,
    $ProducersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProducersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProducersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProducersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<double?> reliabilityScore = const Value.absent(),
                Value<double?> minOrderQty = const Value.absent(),
                Value<int?> leadTimeDays = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> contactEmail = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalSource = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProducersTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                category: category,
                country: country,
                rating: rating,
                reliabilityScore: reliabilityScore,
                minOrderQty: minOrderQty,
                leadTimeDays: leadTimeDays,
                certifications: certifications,
                contactEmail: contactEmail,
                contactPhone: contactPhone,
                externalId: externalId,
                externalSource: externalSource,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<double?> reliabilityScore = const Value.absent(),
                Value<double?> minOrderQty = const Value.absent(),
                Value<int?> leadTimeDays = const Value.absent(),
                Value<String?> certifications = const Value.absent(),
                Value<String?> contactEmail = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalSource = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProducersTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                category: category,
                country: country,
                rating: rating,
                reliabilityScore: reliabilityScore,
                minOrderQty: minOrderQty,
                leadTimeDays: leadTimeDays,
                certifications: certifications,
                contactEmail: contactEmail,
                contactPhone: contactPhone,
                externalId: externalId,
                externalSource: externalSource,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProducersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({businessId = false, productsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productsTableRefs) db.productsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable:
                                        $$ProducersTableTableReferences
                                            ._businessIdTable(db),
                                    referencedColumn:
                                        $$ProducersTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productsTableRefs)
                        await $_getPrefetchedData<
                          ProducersTableData,
                          $ProducersTableTable,
                          ProductsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProducersTableTableReferences
                              ._productsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProducersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProducersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProducersTableTable,
      ProducersTableData,
      $$ProducersTableTableFilterComposer,
      $$ProducersTableTableOrderingComposer,
      $$ProducersTableTableAnnotationComposer,
      $$ProducersTableTableCreateCompanionBuilder,
      $$ProducersTableTableUpdateCompanionBuilder,
      (ProducersTableData, $$ProducersTableTableReferences),
      ProducersTableData,
      PrefetchHooks Function({bool businessId, bool productsTableRefs})
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String businessId,
      required String sku,
      required String name,
      Value<String?> description,
      Value<String?> category,
      Value<double?> costPerUnit,
      required double listPrice,
      Value<double?> currentPrice,
      Value<double?> profitPerUnit,
      Value<double> totalStock,
      Value<String?> stockByWarehouse,
      Value<double?> stockAlertLevel,
      Value<String?> supplierId,
      Value<String?> salesChannels,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> sku,
      Value<String> name,
      Value<String?> description,
      Value<String?> category,
      Value<double?> costPerUnit,
      Value<double> listPrice,
      Value<double?> currentPrice,
      Value<double?> profitPerUnit,
      Value<double> totalStock,
      Value<String?> stockByWarehouse,
      Value<double?> stockAlertLevel,
      Value<String?> supplierId,
      Value<String?> salesChannels,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProductsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData> {
  $$ProductsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('products_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProducersTableTable _supplierIdTable(_$AppDatabase db) => db
      .producersTable
      .createAlias('products_table__supplier_id__producers_table__id');

  $$ProducersTableTableProcessedTableManager? get supplierId {
    final $_column = $_itemColumn<String>('supplier_id');
    if ($_column == null) return null;
    final manager = $$ProducersTableTableTableManager(
      $_db,
      $_db.producersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPerUnit => $composableBuilder(
    column: $table.costPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get listPrice => $composableBuilder(
    column: $table.listPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitPerUnit => $composableBuilder(
    column: $table.profitPerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalStock => $composableBuilder(
    column: $table.totalStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockByWarehouse => $composableBuilder(
    column: $table.stockByWarehouse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockAlertLevel => $composableBuilder(
    column: $table.stockAlertLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salesChannels => $composableBuilder(
    column: $table.salesChannels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProducersTableTableFilterComposer get supplierId {
    final $$ProducersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.producersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProducersTableTableFilterComposer(
            $db: $db,
            $table: $db.producersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPerUnit => $composableBuilder(
    column: $table.costPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get listPrice => $composableBuilder(
    column: $table.listPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitPerUnit => $composableBuilder(
    column: $table.profitPerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalStock => $composableBuilder(
    column: $table.totalStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockByWarehouse => $composableBuilder(
    column: $table.stockByWarehouse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockAlertLevel => $composableBuilder(
    column: $table.stockAlertLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salesChannels => $composableBuilder(
    column: $table.salesChannels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProducersTableTableOrderingComposer get supplierId {
    final $$ProducersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.producersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProducersTableTableOrderingComposer(
            $db: $db,
            $table: $db.producersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get costPerUnit => $composableBuilder(
    column: $table.costPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get listPrice =>
      $composableBuilder(column: $table.listPrice, builder: (column) => column);

  GeneratedColumn<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitPerUnit => $composableBuilder(
    column: $table.profitPerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalStock => $composableBuilder(
    column: $table.totalStock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stockByWarehouse => $composableBuilder(
    column: $table.stockByWarehouse,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockAlertLevel => $composableBuilder(
    column: $table.stockAlertLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salesChannels => $composableBuilder(
    column: $table.salesChannels,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProducersTableTableAnnotationComposer get supplierId {
    final $$ProducersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.producersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProducersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.producersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (ProductsTableData, $$ProductsTableTableReferences),
          ProductsTableData,
          PrefetchHooks Function({bool businessId, bool supplierId})
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> costPerUnit = const Value.absent(),
                Value<double> listPrice = const Value.absent(),
                Value<double?> currentPrice = const Value.absent(),
                Value<double?> profitPerUnit = const Value.absent(),
                Value<double> totalStock = const Value.absent(),
                Value<String?> stockByWarehouse = const Value.absent(),
                Value<double?> stockAlertLevel = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> salesChannels = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                businessId: businessId,
                sku: sku,
                name: name,
                description: description,
                category: category,
                costPerUnit: costPerUnit,
                listPrice: listPrice,
                currentPrice: currentPrice,
                profitPerUnit: profitPerUnit,
                totalStock: totalStock,
                stockByWarehouse: stockByWarehouse,
                stockAlertLevel: stockAlertLevel,
                supplierId: supplierId,
                salesChannels: salesChannels,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String sku,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double?> costPerUnit = const Value.absent(),
                required double listPrice,
                Value<double?> currentPrice = const Value.absent(),
                Value<double?> profitPerUnit = const Value.absent(),
                Value<double> totalStock = const Value.absent(),
                Value<String?> stockByWarehouse = const Value.absent(),
                Value<double?> stockAlertLevel = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> salesChannels = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                businessId: businessId,
                sku: sku,
                name: name,
                description: description,
                category: category,
                costPerUnit: costPerUnit,
                listPrice: listPrice,
                currentPrice: currentPrice,
                profitPerUnit: profitPerUnit,
                totalStock: totalStock,
                stockByWarehouse: stockByWarehouse,
                stockAlertLevel: stockAlertLevel,
                supplierId: supplierId,
                salesChannels: salesChannels,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false, supplierId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable: $$ProductsTableTableReferences
                                    ._businessIdTable(db),
                                referencedColumn: $$ProductsTableTableReferences
                                    ._businessIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (supplierId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.supplierId,
                                referencedTable: $$ProductsTableTableReferences
                                    ._supplierIdTable(db),
                                referencedColumn: $$ProductsTableTableReferences
                                    ._supplierIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (ProductsTableData, $$ProductsTableTableReferences),
      ProductsTableData,
      PrefetchHooks Function({bool businessId, bool supplierId})
    >;
typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> externalId,
      Value<String?> externalSource,
      required String name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> city,
      Value<String?> country,
      Value<String?> segments,
      Value<double?> lifetimeValue,
      Value<int?> orderCount,
      Value<double?> totalSpent,
      Value<double?> avgOrderValue,
      Value<DateTime?> lastOrderDate,
      Value<double?> churnRisk,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> externalId,
      Value<String?> externalSource,
      Value<String> name,
      Value<String?> email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> city,
      Value<String?> country,
      Value<String?> segments,
      Value<double?> lifetimeValue,
      Value<int?> orderCount,
      Value<double?> totalSpent,
      Value<double?> avgOrderValue,
      Value<DateTime?> lastOrderDate,
      Value<double?> churnRisk,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CustomersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData
        > {
  $$CustomersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('customers_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OrdersTableTable, List<OrdersTableData>>
  _ordersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordersTable,
    aliasName: 'customers_table__id__orders_table__customer_id',
  );

  $$OrdersTableTableProcessedTableManager get ordersTableRefs {
    final manager = $$OrdersTableTableTableManager(
      $_db,
      $_db.ordersTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segments => $composableBuilder(
    column: $table.segments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lifetimeValue => $composableBuilder(
    column: $table.lifetimeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderCount => $composableBuilder(
    column: $table.orderCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgOrderValue => $composableBuilder(
    column: $table.avgOrderValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOrderDate => $composableBuilder(
    column: $table.lastOrderDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get churnRisk => $composableBuilder(
    column: $table.churnRisk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ordersTableRefs(
    Expression<bool> Function($$OrdersTableTableFilterComposer f) f,
  ) {
    final $$OrdersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableFilterComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segments => $composableBuilder(
    column: $table.segments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lifetimeValue => $composableBuilder(
    column: $table.lifetimeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderCount => $composableBuilder(
    column: $table.orderCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgOrderValue => $composableBuilder(
    column: $table.avgOrderValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOrderDate => $composableBuilder(
    column: $table.lastOrderDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get churnRisk => $composableBuilder(
    column: $table.churnRisk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalSource => $composableBuilder(
    column: $table.externalSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get segments =>
      $composableBuilder(column: $table.segments, builder: (column) => column);

  GeneratedColumn<double> get lifetimeValue => $composableBuilder(
    column: $table.lifetimeValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderCount => $composableBuilder(
    column: $table.orderCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgOrderValue => $composableBuilder(
    column: $table.avgOrderValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOrderDate => $composableBuilder(
    column: $table.lastOrderDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get churnRisk =>
      $composableBuilder(column: $table.churnRisk, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ordersTableRefs<T extends Object>(
    Expression<T> Function($$OrdersTableTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (CustomersTableData, $$CustomersTableTableReferences),
          CustomersTableData,
          PrefetchHooks Function({bool businessId, bool ordersTableRefs})
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalSource = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> segments = const Value.absent(),
                Value<double?> lifetimeValue = const Value.absent(),
                Value<int?> orderCount = const Value.absent(),
                Value<double?> totalSpent = const Value.absent(),
                Value<double?> avgOrderValue = const Value.absent(),
                Value<DateTime?> lastOrderDate = const Value.absent(),
                Value<double?> churnRisk = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                businessId: businessId,
                externalId: externalId,
                externalSource: externalSource,
                name: name,
                email: email,
                phone: phone,
                address: address,
                city: city,
                country: country,
                segments: segments,
                lifetimeValue: lifetimeValue,
                orderCount: orderCount,
                totalSpent: totalSpent,
                avgOrderValue: avgOrderValue,
                lastOrderDate: lastOrderDate,
                churnRisk: churnRisk,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> externalId = const Value.absent(),
                Value<String?> externalSource = const Value.absent(),
                required String name,
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> segments = const Value.absent(),
                Value<double?> lifetimeValue = const Value.absent(),
                Value<int?> orderCount = const Value.absent(),
                Value<double?> totalSpent = const Value.absent(),
                Value<double?> avgOrderValue = const Value.absent(),
                Value<DateTime?> lastOrderDate = const Value.absent(),
                Value<double?> churnRisk = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                businessId: businessId,
                externalId: externalId,
                externalSource: externalSource,
                name: name,
                email: email,
                phone: phone,
                address: address,
                city: city,
                country: country,
                segments: segments,
                lifetimeValue: lifetimeValue,
                orderCount: orderCount,
                totalSpent: totalSpent,
                avgOrderValue: avgOrderValue,
                lastOrderDate: lastOrderDate,
                churnRisk: churnRisk,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({businessId = false, ordersTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ordersTableRefs) db.ordersTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable:
                                        $$CustomersTableTableReferences
                                            ._businessIdTable(db),
                                    referencedColumn:
                                        $$CustomersTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ordersTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          OrdersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._ordersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).ordersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomersTableData,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (CustomersTableData, $$CustomersTableTableReferences),
      CustomersTableData,
      PrefetchHooks Function({bool businessId, bool ordersTableRefs})
    >;
typedef $$ChannelsTableTableCreateCompanionBuilder =
    ChannelsTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      required String type,
      Value<String?> platformId,
      Value<String?> status,
      Value<bool> isConnected,
      Value<String?> credentialsEncrypted,
      Value<String?> metrics,
      Value<DateTime?> lastSyncDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ChannelsTableTableUpdateCompanionBuilder =
    ChannelsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> type,
      Value<String?> platformId,
      Value<String?> status,
      Value<bool> isConnected,
      Value<String?> credentialsEncrypted,
      Value<String?> metrics,
      Value<DateTime?> lastSyncDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChannelsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChannelsTableTable, ChannelsTableData> {
  $$ChannelsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('channels_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OrdersTableTable, List<OrdersTableData>>
  _ordersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordersTable,
    aliasName: 'channels_table__id__orders_table__channel_id',
  );

  $$OrdersTableTableProcessedTableManager get ordersTableRefs {
    final manager = $$OrdersTableTableTableManager(
      $_db,
      $_db.ordersTable,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTableTable> {
  $$ChannelsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platformId => $composableBuilder(
    column: $table.platformId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialsEncrypted => $composableBuilder(
    column: $table.credentialsEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metrics => $composableBuilder(
    column: $table.metrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncDate => $composableBuilder(
    column: $table.lastSyncDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ordersTableRefs(
    Expression<bool> Function($$OrdersTableTableFilterComposer f) f,
  ) {
    final $$OrdersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableFilterComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTableTable> {
  $$ChannelsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platformId => $composableBuilder(
    column: $table.platformId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialsEncrypted => $composableBuilder(
    column: $table.credentialsEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metrics => $composableBuilder(
    column: $table.metrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncDate => $composableBuilder(
    column: $table.lastSyncDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTableTable> {
  $$ChannelsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get platformId => $composableBuilder(
    column: $table.platformId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credentialsEncrypted => $composableBuilder(
    column: $table.credentialsEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metrics =>
      $composableBuilder(column: $table.metrics, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncDate => $composableBuilder(
    column: $table.lastSyncDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ordersTableRefs<T extends Object>(
    Expression<T> Function($$OrdersTableTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTableTable,
          ChannelsTableData,
          $$ChannelsTableTableFilterComposer,
          $$ChannelsTableTableOrderingComposer,
          $$ChannelsTableTableAnnotationComposer,
          $$ChannelsTableTableCreateCompanionBuilder,
          $$ChannelsTableTableUpdateCompanionBuilder,
          (ChannelsTableData, $$ChannelsTableTableReferences),
          ChannelsTableData,
          PrefetchHooks Function({bool businessId, bool ordersTableRefs})
        > {
  $$ChannelsTableTableTableManager(_$AppDatabase db, $ChannelsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> platformId = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<bool> isConnected = const Value.absent(),
                Value<String?> credentialsEncrypted = const Value.absent(),
                Value<String?> metrics = const Value.absent(),
                Value<DateTime?> lastSyncDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                type: type,
                platformId: platformId,
                status: status,
                isConnected: isConnected,
                credentialsEncrypted: credentialsEncrypted,
                metrics: metrics,
                lastSyncDate: lastSyncDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                required String type,
                Value<String?> platformId = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<bool> isConnected = const Value.absent(),
                Value<String?> credentialsEncrypted = const Value.absent(),
                Value<String?> metrics = const Value.absent(),
                Value<DateTime?> lastSyncDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                type: type,
                platformId: platformId,
                status: status,
                isConnected: isConnected,
                credentialsEncrypted: credentialsEncrypted,
                metrics: metrics,
                lastSyncDate: lastSyncDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({businessId = false, ordersTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ordersTableRefs) db.ordersTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable:
                                        $$ChannelsTableTableReferences
                                            ._businessIdTable(db),
                                    referencedColumn:
                                        $$ChannelsTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ordersTableRefs)
                        await $_getPrefetchedData<
                          ChannelsTableData,
                          $ChannelsTableTable,
                          OrdersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableTableReferences
                              ._ordersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).ordersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChannelsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTableTable,
      ChannelsTableData,
      $$ChannelsTableTableFilterComposer,
      $$ChannelsTableTableOrderingComposer,
      $$ChannelsTableTableAnnotationComposer,
      $$ChannelsTableTableCreateCompanionBuilder,
      $$ChannelsTableTableUpdateCompanionBuilder,
      (ChannelsTableData, $$ChannelsTableTableReferences),
      ChannelsTableData,
      PrefetchHooks Function({bool businessId, bool ordersTableRefs})
    >;
typedef $$OrdersTableTableCreateCompanionBuilder =
    OrdersTableCompanion Function({
      required String id,
      required String businessId,
      required String customerId,
      Value<String?> channelId,
      Value<String?> orderNumber,
      required DateTime orderDate,
      required int totalQuantity,
      required double subtotal,
      Value<double> discount,
      Value<double?> shippingCost,
      required double totalAmount,
      required String status,
      Value<String?> paymentStatus,
      required String items,
      Value<String?> externalId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$OrdersTableTableUpdateCompanionBuilder =
    OrdersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> customerId,
      Value<String?> channelId,
      Value<String?> orderNumber,
      Value<DateTime> orderDate,
      Value<int> totalQuantity,
      Value<double> subtotal,
      Value<double> discount,
      Value<double?> shippingCost,
      Value<double> totalAmount,
      Value<String> status,
      Value<String?> paymentStatus,
      Value<String> items,
      Value<String?> externalId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$OrdersTableTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTableTable, OrdersTableData> {
  $$OrdersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('orders_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('orders_table__customer_id__customers_table__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChannelsTableTable _channelIdTable(_$AppDatabase db) => db
      .channelsTable
      .createAlias('orders_table__channel_id__channels_table__id');

  $$ChannelsTableTableProcessedTableManager? get channelId {
    final $_column = $_itemColumn<String>('channel_id');
    if ($_column == null) return null;
    final manager = $$ChannelsTableTableTableManager(
      $_db,
      $_db.channelsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionsTableTable,
    List<TransactionsTableData>
  >
  _transactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsTable,
        aliasName: 'orders_table__id__transactions_table__order_id',
      );

  $$TransactionsTableTableProcessedTableManager get transactionsTableRefs {
    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableTableFilterComposer get channelId {
    final $$ChannelsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channelsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableTableFilterComposer(
            $db: $db,
            $table: $db.channelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsTableRefs(
    Expression<bool> Function($$TransactionsTableTableFilterComposer f) f,
  ) {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get orderDate => $composableBuilder(
    column: $table.orderDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableTableOrderingComposer get channelId {
    final $$ChannelsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channelsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableTableOrderingComposer(
            $db: $db,
            $table: $db.channelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get orderDate =>
      $composableBuilder(column: $table.orderDate, builder: (column) => column);

  GeneratedColumn<int> get totalQuantity => $composableBuilder(
    column: $table.totalQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableTableAnnotationComposer get channelId {
    final $$ChannelsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channelsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.channelsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.orderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTableTable,
          OrdersTableData,
          $$OrdersTableTableFilterComposer,
          $$OrdersTableTableOrderingComposer,
          $$OrdersTableTableAnnotationComposer,
          $$OrdersTableTableCreateCompanionBuilder,
          $$OrdersTableTableUpdateCompanionBuilder,
          (OrdersTableData, $$OrdersTableTableReferences),
          OrdersTableData,
          PrefetchHooks Function({
            bool businessId,
            bool customerId,
            bool channelId,
            bool transactionsTableRefs,
          })
        > {
  $$OrdersTableTableTableManager(_$AppDatabase db, $OrdersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> orderNumber = const Value.absent(),
                Value<DateTime> orderDate = const Value.absent(),
                Value<int> totalQuantity = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discount = const Value.absent(),
                Value<double?> shippingCost = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> paymentStatus = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion(
                id: id,
                businessId: businessId,
                customerId: customerId,
                channelId: channelId,
                orderNumber: orderNumber,
                orderDate: orderDate,
                totalQuantity: totalQuantity,
                subtotal: subtotal,
                discount: discount,
                shippingCost: shippingCost,
                totalAmount: totalAmount,
                status: status,
                paymentStatus: paymentStatus,
                items: items,
                externalId: externalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String customerId,
                Value<String?> channelId = const Value.absent(),
                Value<String?> orderNumber = const Value.absent(),
                required DateTime orderDate,
                required int totalQuantity,
                required double subtotal,
                Value<double> discount = const Value.absent(),
                Value<double?> shippingCost = const Value.absent(),
                required double totalAmount,
                required String status,
                Value<String?> paymentStatus = const Value.absent(),
                required String items,
                Value<String?> externalId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion.insert(
                id: id,
                businessId: businessId,
                customerId: customerId,
                channelId: channelId,
                orderNumber: orderNumber,
                orderDate: orderDate,
                totalQuantity: totalQuantity,
                subtotal: subtotal,
                discount: discount,
                shippingCost: shippingCost,
                totalAmount: totalAmount,
                status: status,
                paymentStatus: paymentStatus,
                items: items,
                externalId: externalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OrdersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                customerId = false,
                channelId = false,
                transactionsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsTableRefs) db.transactionsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable:
                                        $$OrdersTableTableReferences
                                            ._businessIdTable(db),
                                    referencedColumn:
                                        $$OrdersTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$OrdersTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$OrdersTableTableReferences
                                            ._customerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (channelId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.channelId,
                                    referencedTable:
                                        $$OrdersTableTableReferences
                                            ._channelIdTable(db),
                                    referencedColumn:
                                        $$OrdersTableTableReferences
                                            ._channelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsTableRefs)
                        await $_getPrefetchedData<
                          OrdersTableData,
                          $OrdersTableTable,
                          TransactionsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$OrdersTableTableReferences
                              ._transactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrdersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.orderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTableTable,
      OrdersTableData,
      $$OrdersTableTableFilterComposer,
      $$OrdersTableTableOrderingComposer,
      $$OrdersTableTableAnnotationComposer,
      $$OrdersTableTableCreateCompanionBuilder,
      $$OrdersTableTableUpdateCompanionBuilder,
      (OrdersTableData, $$OrdersTableTableReferences),
      OrdersTableData,
      PrefetchHooks Function({
        bool businessId,
        bool customerId,
        bool channelId,
        bool transactionsTableRefs,
      })
    >;
typedef $$OpportunitiesTableTableCreateCompanionBuilder =
    OpportunitiesTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      required String title,
      Value<String?> description,
      Value<String?> market,
      Value<double?> estimatedRoi,
      Value<double?> estimatedInvestment,
      Value<double?> riskScore,
      Value<double?> feasibilityScore,
      Value<double?> aiScore,
      Value<String?> status,
      Value<String?> relatedProducts,
      Value<String?> relatedSuppliers,
      Value<DateTime> discoveredAt,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$OpportunitiesTableTableUpdateCompanionBuilder =
    OpportunitiesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String> title,
      Value<String?> description,
      Value<String?> market,
      Value<double?> estimatedRoi,
      Value<double?> estimatedInvestment,
      Value<double?> riskScore,
      Value<double?> feasibilityScore,
      Value<double?> aiScore,
      Value<String?> status,
      Value<String?> relatedProducts,
      Value<String?> relatedSuppliers,
      Value<DateTime> discoveredAt,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$OpportunitiesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OpportunitiesTableTable,
          OpportunitiesTableData
        > {
  $$OpportunitiesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('opportunities_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OpportunitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $OpportunitiesTableTable> {
  $$OpportunitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedRoi => $composableBuilder(
    column: $table.estimatedRoi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedInvestment => $composableBuilder(
    column: $table.estimatedInvestment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get feasibilityScore => $composableBuilder(
    column: $table.feasibilityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aiScore => $composableBuilder(
    column: $table.aiScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedProducts => $composableBuilder(
    column: $table.relatedProducts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedSuppliers => $composableBuilder(
    column: $table.relatedSuppliers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OpportunitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OpportunitiesTableTable> {
  $$OpportunitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedRoi => $composableBuilder(
    column: $table.estimatedRoi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedInvestment => $composableBuilder(
    column: $table.estimatedInvestment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get feasibilityScore => $composableBuilder(
    column: $table.feasibilityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aiScore => $composableBuilder(
    column: $table.aiScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedProducts => $composableBuilder(
    column: $table.relatedProducts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedSuppliers => $composableBuilder(
    column: $table.relatedSuppliers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OpportunitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OpportunitiesTableTable> {
  $$OpportunitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get market =>
      $composableBuilder(column: $table.market, builder: (column) => column);

  GeneratedColumn<double> get estimatedRoi => $composableBuilder(
    column: $table.estimatedRoi,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimatedInvestment => $composableBuilder(
    column: $table.estimatedInvestment,
    builder: (column) => column,
  );

  GeneratedColumn<double> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<double> get feasibilityScore => $composableBuilder(
    column: $table.feasibilityScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get aiScore =>
      $composableBuilder(column: $table.aiScore, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get relatedProducts => $composableBuilder(
    column: $table.relatedProducts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedSuppliers => $composableBuilder(
    column: $table.relatedSuppliers,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OpportunitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpportunitiesTableTable,
          OpportunitiesTableData,
          $$OpportunitiesTableTableFilterComposer,
          $$OpportunitiesTableTableOrderingComposer,
          $$OpportunitiesTableTableAnnotationComposer,
          $$OpportunitiesTableTableCreateCompanionBuilder,
          $$OpportunitiesTableTableUpdateCompanionBuilder,
          (OpportunitiesTableData, $$OpportunitiesTableTableReferences),
          OpportunitiesTableData,
          PrefetchHooks Function({bool businessId})
        > {
  $$OpportunitiesTableTableTableManager(
    _$AppDatabase db,
    $OpportunitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpportunitiesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpportunitiesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpportunitiesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> market = const Value.absent(),
                Value<double?> estimatedRoi = const Value.absent(),
                Value<double?> estimatedInvestment = const Value.absent(),
                Value<double?> riskScore = const Value.absent(),
                Value<double?> feasibilityScore = const Value.absent(),
                Value<double?> aiScore = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> relatedProducts = const Value.absent(),
                Value<String?> relatedSuppliers = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpportunitiesTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                title: title,
                description: description,
                market: market,
                estimatedRoi: estimatedRoi,
                estimatedInvestment: estimatedInvestment,
                riskScore: riskScore,
                feasibilityScore: feasibilityScore,
                aiScore: aiScore,
                status: status,
                relatedProducts: relatedProducts,
                relatedSuppliers: relatedSuppliers,
                discoveredAt: discoveredAt,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> market = const Value.absent(),
                Value<double?> estimatedRoi = const Value.absent(),
                Value<double?> estimatedInvestment = const Value.absent(),
                Value<double?> riskScore = const Value.absent(),
                Value<double?> feasibilityScore = const Value.absent(),
                Value<double?> aiScore = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> relatedProducts = const Value.absent(),
                Value<String?> relatedSuppliers = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpportunitiesTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                title: title,
                description: description,
                market: market,
                estimatedRoi: estimatedRoi,
                estimatedInvestment: estimatedInvestment,
                riskScore: riskScore,
                feasibilityScore: feasibilityScore,
                aiScore: aiScore,
                status: status,
                relatedProducts: relatedProducts,
                relatedSuppliers: relatedSuppliers,
                discoveredAt: discoveredAt,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OpportunitiesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable:
                                    $$OpportunitiesTableTableReferences
                                        ._businessIdTable(db),
                                referencedColumn:
                                    $$OpportunitiesTableTableReferences
                                        ._businessIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OpportunitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpportunitiesTableTable,
      OpportunitiesTableData,
      $$OpportunitiesTableTableFilterComposer,
      $$OpportunitiesTableTableOrderingComposer,
      $$OpportunitiesTableTableAnnotationComposer,
      $$OpportunitiesTableTableCreateCompanionBuilder,
      $$OpportunitiesTableTableUpdateCompanionBuilder,
      (OpportunitiesTableData, $$OpportunitiesTableTableReferences),
      OpportunitiesTableData,
      PrefetchHooks Function({bool businessId})
    >;
typedef $$JourneysTableTableCreateCompanionBuilder =
    JourneysTableCompanion Function({
      required String id,
      required String businessId,
      required String goal,
      required String status,
      Value<int?> progressPercent,
      Value<int?> totalSteps,
      Value<int> completedSteps,
      Value<double?> budget,
      Value<double> spent,
      Value<int?> timelineDays,
      Value<double?> revenueImpact,
      Value<DateTime> createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$JourneysTableTableUpdateCompanionBuilder =
    JourneysTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> goal,
      Value<String> status,
      Value<int?> progressPercent,
      Value<int?> totalSteps,
      Value<int> completedSteps,
      Value<double?> budget,
      Value<double> spent,
      Value<int?> timelineDays,
      Value<double?> revenueImpact,
      Value<DateTime> createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$JourneysTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $JourneysTableTable, JourneysTableData> {
  $$JourneysTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('journeys_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $JourneyStepsTableTable,
    List<JourneyStepsTableData>
  >
  _journeyStepsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journeyStepsTable,
        aliasName: 'journeys_table__id__journey_steps_table__journey_id',
      );

  $$JourneyStepsTableTableProcessedTableManager get journeyStepsTableRefs {
    final manager = $$JourneyStepsTableTableTableManager(
      $_db,
      $_db.journeyStepsTable,
    ).filter((f) => f.journeyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journeyStepsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JourneysTableTableFilterComposer
    extends Composer<_$AppDatabase, $JourneysTableTable> {
  $$JourneysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSteps => $composableBuilder(
    column: $table.totalSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedSteps => $composableBuilder(
    column: $table.completedSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timelineDays => $composableBuilder(
    column: $table.timelineDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get revenueImpact => $composableBuilder(
    column: $table.revenueImpact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> journeyStepsTableRefs(
    Expression<bool> Function($$JourneyStepsTableTableFilterComposer f) f,
  ) {
    final $$JourneyStepsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeyStepsTable,
      getReferencedColumn: (t) => t.journeyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneyStepsTableTableFilterComposer(
            $db: $db,
            $table: $db.journeyStepsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JourneysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneysTableTable> {
  $$JourneysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSteps => $composableBuilder(
    column: $table.totalSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedSteps => $composableBuilder(
    column: $table.completedSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timelineDays => $composableBuilder(
    column: $table.timelineDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get revenueImpact => $composableBuilder(
    column: $table.revenueImpact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneysTableTable> {
  $$JourneysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSteps => $composableBuilder(
    column: $table.totalSteps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedSteps => $composableBuilder(
    column: $table.completedSteps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<double> get spent =>
      $composableBuilder(column: $table.spent, builder: (column) => column);

  GeneratedColumn<int> get timelineDays => $composableBuilder(
    column: $table.timelineDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get revenueImpact => $composableBuilder(
    column: $table.revenueImpact,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> journeyStepsTableRefs<T extends Object>(
    Expression<T> Function($$JourneyStepsTableTableAnnotationComposer a) f,
  ) {
    final $$JourneyStepsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journeyStepsTable,
          getReferencedColumn: (t) => t.journeyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JourneyStepsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journeyStepsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$JourneysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneysTableTable,
          JourneysTableData,
          $$JourneysTableTableFilterComposer,
          $$JourneysTableTableOrderingComposer,
          $$JourneysTableTableAnnotationComposer,
          $$JourneysTableTableCreateCompanionBuilder,
          $$JourneysTableTableUpdateCompanionBuilder,
          (JourneysTableData, $$JourneysTableTableReferences),
          JourneysTableData,
          PrefetchHooks Function({bool businessId, bool journeyStepsTableRefs})
        > {
  $$JourneysTableTableTableManager(_$AppDatabase db, $JourneysTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> progressPercent = const Value.absent(),
                Value<int?> totalSteps = const Value.absent(),
                Value<int> completedSteps = const Value.absent(),
                Value<double?> budget = const Value.absent(),
                Value<double> spent = const Value.absent(),
                Value<int?> timelineDays = const Value.absent(),
                Value<double?> revenueImpact = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysTableCompanion(
                id: id,
                businessId: businessId,
                goal: goal,
                status: status,
                progressPercent: progressPercent,
                totalSteps: totalSteps,
                completedSteps: completedSteps,
                budget: budget,
                spent: spent,
                timelineDays: timelineDays,
                revenueImpact: revenueImpact,
                createdAt: createdAt,
                startedAt: startedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String goal,
                required String status,
                Value<int?> progressPercent = const Value.absent(),
                Value<int?> totalSteps = const Value.absent(),
                Value<int> completedSteps = const Value.absent(),
                Value<double?> budget = const Value.absent(),
                Value<double> spent = const Value.absent(),
                Value<int?> timelineDays = const Value.absent(),
                Value<double?> revenueImpact = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysTableCompanion.insert(
                id: id,
                businessId: businessId,
                goal: goal,
                status: status,
                progressPercent: progressPercent,
                totalSteps: totalSteps,
                completedSteps: completedSteps,
                budget: budget,
                spent: spent,
                timelineDays: timelineDays,
                revenueImpact: revenueImpact,
                createdAt: createdAt,
                startedAt: startedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JourneysTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({businessId = false, journeyStepsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (journeyStepsTableRefs) db.journeyStepsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable:
                                        $$JourneysTableTableReferences
                                            ._businessIdTable(db),
                                    referencedColumn:
                                        $$JourneysTableTableReferences
                                            ._businessIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (journeyStepsTableRefs)
                        await $_getPrefetchedData<
                          JourneysTableData,
                          $JourneysTableTable,
                          JourneyStepsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$JourneysTableTableReferences
                              ._journeyStepsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JourneysTableTableReferences(
                                db,
                                table,
                                p0,
                              ).journeyStepsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.journeyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$JourneysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneysTableTable,
      JourneysTableData,
      $$JourneysTableTableFilterComposer,
      $$JourneysTableTableOrderingComposer,
      $$JourneysTableTableAnnotationComposer,
      $$JourneysTableTableCreateCompanionBuilder,
      $$JourneysTableTableUpdateCompanionBuilder,
      (JourneysTableData, $$JourneysTableTableReferences),
      JourneysTableData,
      PrefetchHooks Function({bool businessId, bool journeyStepsTableRefs})
    >;
typedef $$JourneyStepsTableTableCreateCompanionBuilder =
    JourneyStepsTableCompanion Function({
      required String id,
      required String journeyId,
      required int stepNumber,
      required String title,
      required String status,
      Value<bool> milestone,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int?> forecastDays,
      Value<String?> dependsOn,
      Value<String?> guidance,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$JourneyStepsTableTableUpdateCompanionBuilder =
    JourneyStepsTableCompanion Function({
      Value<String> id,
      Value<String> journeyId,
      Value<int> stepNumber,
      Value<String> title,
      Value<String> status,
      Value<bool> milestone,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int?> forecastDays,
      Value<String?> dependsOn,
      Value<String?> guidance,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$JourneyStepsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $JourneyStepsTableTable,
          JourneyStepsTableData
        > {
  $$JourneyStepsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $JourneysTableTable _journeyIdTable(_$AppDatabase db) => db
      .journeysTable
      .createAlias('journey_steps_table__journey_id__journeys_table__id');

  $$JourneysTableTableProcessedTableManager get journeyId {
    final $_column = $_itemColumn<String>('journey_id')!;

    final manager = $$JourneysTableTableTableManager(
      $_db,
      $_db.journeysTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_journeyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JourneyStepsTableTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyStepsTableTable> {
  $$JourneyStepsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get forecastDays => $composableBuilder(
    column: $table.forecastDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guidance => $composableBuilder(
    column: $table.guidance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$JourneysTableTableFilterComposer get journeyId {
    final $$JourneysTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeysTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableTableFilterComposer(
            $db: $db,
            $table: $db.journeysTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyStepsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyStepsTableTable> {
  $$JourneyStepsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get forecastDays => $composableBuilder(
    column: $table.forecastDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guidance => $composableBuilder(
    column: $table.guidance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$JourneysTableTableOrderingComposer get journeyId {
    final $$JourneysTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeysTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableTableOrderingComposer(
            $db: $db,
            $table: $db.journeysTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyStepsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyStepsTableTable> {
  $$JourneyStepsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get milestone =>
      $composableBuilder(column: $table.milestone, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get forecastDays => $composableBuilder(
    column: $table.forecastDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<String> get guidance =>
      $composableBuilder(column: $table.guidance, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$JourneysTableTableAnnotationComposer get journeyId {
    final $$JourneysTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journeyId,
      referencedTable: $db.journeysTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableTableAnnotationComposer(
            $db: $db,
            $table: $db.journeysTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneyStepsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyStepsTableTable,
          JourneyStepsTableData,
          $$JourneyStepsTableTableFilterComposer,
          $$JourneyStepsTableTableOrderingComposer,
          $$JourneyStepsTableTableAnnotationComposer,
          $$JourneyStepsTableTableCreateCompanionBuilder,
          $$JourneyStepsTableTableUpdateCompanionBuilder,
          (JourneyStepsTableData, $$JourneyStepsTableTableReferences),
          JourneyStepsTableData,
          PrefetchHooks Function({bool journeyId})
        > {
  $$JourneyStepsTableTableTableManager(
    _$AppDatabase db,
    $JourneyStepsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyStepsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyStepsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyStepsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<int> stepNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> milestone = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> forecastDays = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<String?> guidance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyStepsTableCompanion(
                id: id,
                journeyId: journeyId,
                stepNumber: stepNumber,
                title: title,
                status: status,
                milestone: milestone,
                startDate: startDate,
                endDate: endDate,
                forecastDays: forecastDays,
                dependsOn: dependsOn,
                guidance: guidance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String journeyId,
                required int stepNumber,
                required String title,
                required String status,
                Value<bool> milestone = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> forecastDays = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<String?> guidance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyStepsTableCompanion.insert(
                id: id,
                journeyId: journeyId,
                stepNumber: stepNumber,
                title: title,
                status: status,
                milestone: milestone,
                startDate: startDate,
                endDate: endDate,
                forecastDays: forecastDays,
                dependsOn: dependsOn,
                guidance: guidance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JourneyStepsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journeyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (journeyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.journeyId,
                                referencedTable:
                                    $$JourneyStepsTableTableReferences
                                        ._journeyIdTable(db),
                                referencedColumn:
                                    $$JourneyStepsTableTableReferences
                                        ._journeyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JourneyStepsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyStepsTableTable,
      JourneyStepsTableData,
      $$JourneyStepsTableTableFilterComposer,
      $$JourneyStepsTableTableOrderingComposer,
      $$JourneyStepsTableTableAnnotationComposer,
      $$JourneyStepsTableTableCreateCompanionBuilder,
      $$JourneyStepsTableTableUpdateCompanionBuilder,
      (JourneyStepsTableData, $$JourneyStepsTableTableReferences),
      JourneyStepsTableData,
      PrefetchHooks Function({bool journeyId})
    >;
typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      Value<String?> category,
      required double amount,
      Value<String?> currency,
      required DateTime date,
      Value<String?> account,
      Value<String?> orderId,
      Value<String?> description,
      Value<String?> paymentMethod,
      Value<bool> isReconciled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String?> category,
      Value<double> amount,
      Value<String?> currency,
      Value<DateTime> date,
      Value<String?> account,
      Value<String?> orderId,
      Value<String?> description,
      Value<String?> paymentMethod,
      Value<bool> isReconciled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData
        > {
  $$TransactionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('transactions_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OrdersTableTable _orderIdTable(_$AppDatabase db) => db.ordersTable
      .createAlias('transactions_table__order_id__orders_table__id');

  $$OrdersTableTableProcessedTableManager? get orderId {
    final $_column = $_itemColumn<String>('order_id');
    if ($_column == null) return null;
    final manager = $$OrdersTableTableTableManager(
      $_db,
      $_db.ordersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrdersTableTableFilterComposer get orderId {
    final $$OrdersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableFilterComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrdersTableTableOrderingComposer get orderId {
    final $$OrdersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableOrderingComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrdersTableTableAnnotationComposer get orderId {
    final $$OrdersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.ordersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.ordersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (TransactionsTableData, $$TransactionsTableTableReferences),
          TransactionsTableData,
          PrefetchHooks Function({bool businessId, bool orderId})
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<String?> orderId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<bool> isReconciled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                category: category,
                amount: amount,
                currency: currency,
                date: date,
                account: account,
                orderId: orderId,
                description: description,
                paymentMethod: paymentMethod,
                isReconciled: isReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                Value<String?> category = const Value.absent(),
                required double amount,
                Value<String?> currency = const Value.absent(),
                required DateTime date,
                Value<String?> account = const Value.absent(),
                Value<String?> orderId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<bool> isReconciled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                category: category,
                amount: amount,
                currency: currency,
                date: date,
                account: account,
                orderId: orderId,
                description: description,
                paymentMethod: paymentMethod,
                isReconciled: isReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false, orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable:
                                    $$TransactionsTableTableReferences
                                        ._businessIdTable(db),
                                referencedColumn:
                                    $$TransactionsTableTableReferences
                                        ._businessIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (orderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.orderId,
                                referencedTable:
                                    $$TransactionsTableTableReferences
                                        ._orderIdTable(db),
                                referencedColumn:
                                    $$TransactionsTableTableReferences
                                        ._orderIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionsTableData,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (TransactionsTableData, $$TransactionsTableTableReferences),
      TransactionsTableData,
      PrefetchHooks Function({bool businessId, bool orderId})
    >;
typedef $$DocumentsTableTableCreateCompanionBuilder =
    DocumentsTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      required String name,
      Value<String?> fileName,
      Value<String?> fileType,
      Value<int?> fileSize,
      Value<String?> localPath,
      Value<String?> extractedText,
      Value<String?> extractedData,
      Value<String?> relatedEntityType,
      Value<String?> relatedEntityId,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableTableUpdateCompanionBuilder =
    DocumentsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String> name,
      Value<String?> fileName,
      Value<String?> fileType,
      Value<int?> fileSize,
      Value<String?> localPath,
      Value<String?> extractedText,
      Value<String?> extractedData,
      Value<String?> relatedEntityType,
      Value<String?> relatedEntityId,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DocumentsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DocumentsTableTable,
          DocumentsTableData
        > {
  $$DocumentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('documents_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DocumentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTableTable> {
  $$DocumentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedData => $composableBuilder(
    column: $table.extractedData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedEntityType => $composableBuilder(
    column: $table.relatedEntityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedEntityId => $composableBuilder(
    column: $table.relatedEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTableTable> {
  $$DocumentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedData => $composableBuilder(
    column: $table.extractedData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedEntityType => $composableBuilder(
    column: $table.relatedEntityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedEntityId => $composableBuilder(
    column: $table.relatedEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTableTable> {
  $$DocumentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractedData => $composableBuilder(
    column: $table.extractedData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedEntityType => $composableBuilder(
    column: $table.relatedEntityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedEntityId => $composableBuilder(
    column: $table.relatedEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTableTable,
          DocumentsTableData,
          $$DocumentsTableTableFilterComposer,
          $$DocumentsTableTableOrderingComposer,
          $$DocumentsTableTableAnnotationComposer,
          $$DocumentsTableTableCreateCompanionBuilder,
          $$DocumentsTableTableUpdateCompanionBuilder,
          (DocumentsTableData, $$DocumentsTableTableReferences),
          DocumentsTableData,
          PrefetchHooks Function({bool businessId})
        > {
  $$DocumentsTableTableTableManager(
    _$AppDatabase db,
    $DocumentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<String?> fileType = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String?> extractedData = const Value.absent(),
                Value<String?> relatedEntityType = const Value.absent(),
                Value<String?> relatedEntityId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                name: name,
                fileName: fileName,
                fileType: fileType,
                fileSize: fileSize,
                localPath: localPath,
                extractedText: extractedText,
                extractedData: extractedData,
                relatedEntityType: relatedEntityType,
                relatedEntityId: relatedEntityId,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                required String name,
                Value<String?> fileName = const Value.absent(),
                Value<String?> fileType = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String?> extractedData = const Value.absent(),
                Value<String?> relatedEntityType = const Value.absent(),
                Value<String?> relatedEntityId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                name: name,
                fileName: fileName,
                fileType: fileType,
                fileSize: fileSize,
                localPath: localPath,
                extractedText: extractedText,
                extractedData: extractedData,
                relatedEntityType: relatedEntityType,
                relatedEntityId: relatedEntityId,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DocumentsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable: $$DocumentsTableTableReferences
                                    ._businessIdTable(db),
                                referencedColumn:
                                    $$DocumentsTableTableReferences
                                        ._businessIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DocumentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTableTable,
      DocumentsTableData,
      $$DocumentsTableTableFilterComposer,
      $$DocumentsTableTableOrderingComposer,
      $$DocumentsTableTableAnnotationComposer,
      $$DocumentsTableTableCreateCompanionBuilder,
      $$DocumentsTableTableUpdateCompanionBuilder,
      (DocumentsTableData, $$DocumentsTableTableReferences),
      DocumentsTableData,
      PrefetchHooks Function({bool businessId})
    >;
typedef $$AlertsTableTableCreateCompanionBuilder =
    AlertsTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      required String severity,
      required String title,
      Value<String?> description,
      Value<String?> aiRecommendation,
      Value<String?> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AlertsTableTableUpdateCompanionBuilder =
    AlertsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String> severity,
      Value<String> title,
      Value<String?> description,
      Value<String?> aiRecommendation,
      Value<String?> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AlertsTableTableReferences
    extends BaseReferences<_$AppDatabase, $AlertsTableTable, AlertsTableData> {
  $$AlertsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('alerts_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiRecommendation => $composableBuilder(
    column: $table.aiRecommendation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiRecommendation => $composableBuilder(
    column: $table.aiRecommendation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiRecommendation => $composableBuilder(
    column: $table.aiRecommendation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTableTable,
          AlertsTableData,
          $$AlertsTableTableFilterComposer,
          $$AlertsTableTableOrderingComposer,
          $$AlertsTableTableAnnotationComposer,
          $$AlertsTableTableCreateCompanionBuilder,
          $$AlertsTableTableUpdateCompanionBuilder,
          (AlertsTableData, $$AlertsTableTableReferences),
          AlertsTableData,
          PrefetchHooks Function({bool businessId})
        > {
  $$AlertsTableTableTableManager(_$AppDatabase db, $AlertsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> aiRecommendation = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                severity: severity,
                title: title,
                description: description,
                aiRecommendation: aiRecommendation,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                required String severity,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> aiRecommendation = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                severity: severity,
                title: title,
                description: description,
                aiRecommendation: aiRecommendation,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlertsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable: $$AlertsTableTableReferences
                                    ._businessIdTable(db),
                                referencedColumn: $$AlertsTableTableReferences
                                    ._businessIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlertsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTableTable,
      AlertsTableData,
      $$AlertsTableTableFilterComposer,
      $$AlertsTableTableOrderingComposer,
      $$AlertsTableTableAnnotationComposer,
      $$AlertsTableTableCreateCompanionBuilder,
      $$AlertsTableTableUpdateCompanionBuilder,
      (AlertsTableData, $$AlertsTableTableReferences),
      AlertsTableData,
      PrefetchHooks Function({bool businessId})
    >;
typedef $$AIChatTableTableCreateCompanionBuilder =
    AIChatTableCompanion Function({
      required String id,
      required String businessId,
      required String userId,
      required String messages,
      Value<String?> context,
      Value<String?> summary,
      Value<int?> tokensUsed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AIChatTableTableUpdateCompanionBuilder =
    AIChatTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> userId,
      Value<String> messages,
      Value<String?> context,
      Value<String?> summary,
      Value<int?> tokensUsed,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AIChatTableTableReferences
    extends BaseReferences<_$AppDatabase, $AIChatTableTable, AIChatTableData> {
  $$AIChatTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('a_i_chat_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTableTable _userIdTable(_$AppDatabase db) =>
      db.usersTable.createAlias('a_i_chat_table__user_id__users_table__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AIChatTableTableFilterComposer
    extends Composer<_$AppDatabase, $AIChatTableTable> {
  $$AIChatTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensUsed => $composableBuilder(
    column: $table.tokensUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AIChatTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AIChatTableTable> {
  $$AIChatTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensUsed => $composableBuilder(
    column: $table.tokensUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AIChatTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIChatTableTable> {
  $$AIChatTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messages =>
      $composableBuilder(column: $table.messages, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get tokensUsed => $composableBuilder(
    column: $table.tokensUsed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AIChatTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AIChatTableTable,
          AIChatTableData,
          $$AIChatTableTableFilterComposer,
          $$AIChatTableTableOrderingComposer,
          $$AIChatTableTableAnnotationComposer,
          $$AIChatTableTableCreateCompanionBuilder,
          $$AIChatTableTableUpdateCompanionBuilder,
          (AIChatTableData, $$AIChatTableTableReferences),
          AIChatTableData,
          PrefetchHooks Function({bool businessId, bool userId})
        > {
  $$AIChatTableTableTableManager(_$AppDatabase db, $AIChatTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIChatTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AIChatTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIChatTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> messages = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<int?> tokensUsed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AIChatTableCompanion(
                id: id,
                businessId: businessId,
                userId: userId,
                messages: messages,
                context: context,
                summary: summary,
                tokensUsed: tokensUsed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String userId,
                required String messages,
                Value<String?> context = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<int?> tokensUsed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AIChatTableCompanion.insert(
                id: id,
                businessId: businessId,
                userId: userId,
                messages: messages,
                context: context,
                summary: summary,
                tokensUsed: tokensUsed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AIChatTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false, userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable: $$AIChatTableTableReferences
                                    ._businessIdTable(db),
                                referencedColumn: $$AIChatTableTableReferences
                                    ._businessIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$AIChatTableTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$AIChatTableTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AIChatTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AIChatTableTable,
      AIChatTableData,
      $$AIChatTableTableFilterComposer,
      $$AIChatTableTableOrderingComposer,
      $$AIChatTableTableAnnotationComposer,
      $$AIChatTableTableCreateCompanionBuilder,
      $$AIChatTableTableUpdateCompanionBuilder,
      (AIChatTableData, $$AIChatTableTableReferences),
      AIChatTableData,
      PrefetchHooks Function({bool businessId, bool userId})
    >;
typedef $$IntegrationsTableTableCreateCompanionBuilder =
    IntegrationsTableCompanion Function({
      required String id,
      required String businessId,
      required String provider,
      Value<String?> status,
      Value<String?> apiKeyEncrypted,
      Value<String?> apiSecretEncrypted,
      Value<String?> accessTokenEncrypted,
      Value<String?> refreshTokenEncrypted,
      Value<String?> config,
      Value<DateTime?> lastSyncAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$IntegrationsTableTableUpdateCompanionBuilder =
    IntegrationsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> provider,
      Value<String?> status,
      Value<String?> apiKeyEncrypted,
      Value<String?> apiSecretEncrypted,
      Value<String?> accessTokenEncrypted,
      Value<String?> refreshTokenEncrypted,
      Value<String?> config,
      Value<DateTime?> lastSyncAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$IntegrationsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IntegrationsTableTable,
          IntegrationsTableData
        > {
  $$IntegrationsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BusinessesTableTable _businessIdTable(_$AppDatabase db) => db
      .businessesTable
      .createAlias('integrations_table__business_id__businesses_table__id');

  $$BusinessesTableTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableTableManager(
      $_db,
      $_db.businessesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntegrationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $IntegrationsTableTable> {
  $$IntegrationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKeyEncrypted => $composableBuilder(
    column: $table.apiKeyEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiSecretEncrypted => $composableBuilder(
    column: $table.apiSecretEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessTokenEncrypted => $composableBuilder(
    column: $table.accessTokenEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshTokenEncrypted => $composableBuilder(
    column: $table.refreshTokenEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableTableFilterComposer get businessId {
    final $$BusinessesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableFilterComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $IntegrationsTableTable> {
  $$IntegrationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKeyEncrypted => $composableBuilder(
    column: $table.apiKeyEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiSecretEncrypted => $composableBuilder(
    column: $table.apiSecretEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessTokenEncrypted => $composableBuilder(
    column: $table.accessTokenEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshTokenEncrypted => $composableBuilder(
    column: $table.refreshTokenEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableTableOrderingComposer get businessId {
    final $$BusinessesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableOrderingComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntegrationsTableTable> {
  $$IntegrationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get apiKeyEncrypted => $composableBuilder(
    column: $table.apiKeyEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiSecretEncrypted => $composableBuilder(
    column: $table.apiSecretEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessTokenEncrypted => $composableBuilder(
    column: $table.accessTokenEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshTokenEncrypted => $composableBuilder(
    column: $table.refreshTokenEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BusinessesTableTableAnnotationComposer get businessId {
    final $$BusinessesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businessesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.businessesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntegrationsTableTable,
          IntegrationsTableData,
          $$IntegrationsTableTableFilterComposer,
          $$IntegrationsTableTableOrderingComposer,
          $$IntegrationsTableTableAnnotationComposer,
          $$IntegrationsTableTableCreateCompanionBuilder,
          $$IntegrationsTableTableUpdateCompanionBuilder,
          (IntegrationsTableData, $$IntegrationsTableTableReferences),
          IntegrationsTableData,
          PrefetchHooks Function({bool businessId})
        > {
  $$IntegrationsTableTableTableManager(
    _$AppDatabase db,
    $IntegrationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntegrationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntegrationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntegrationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> apiKeyEncrypted = const Value.absent(),
                Value<String?> apiSecretEncrypted = const Value.absent(),
                Value<String?> accessTokenEncrypted = const Value.absent(),
                Value<String?> refreshTokenEncrypted = const Value.absent(),
                Value<String?> config = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntegrationsTableCompanion(
                id: id,
                businessId: businessId,
                provider: provider,
                status: status,
                apiKeyEncrypted: apiKeyEncrypted,
                apiSecretEncrypted: apiSecretEncrypted,
                accessTokenEncrypted: accessTokenEncrypted,
                refreshTokenEncrypted: refreshTokenEncrypted,
                config: config,
                lastSyncAt: lastSyncAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String provider,
                Value<String?> status = const Value.absent(),
                Value<String?> apiKeyEncrypted = const Value.absent(),
                Value<String?> apiSecretEncrypted = const Value.absent(),
                Value<String?> accessTokenEncrypted = const Value.absent(),
                Value<String?> refreshTokenEncrypted = const Value.absent(),
                Value<String?> config = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntegrationsTableCompanion.insert(
                id: id,
                businessId: businessId,
                provider: provider,
                status: status,
                apiKeyEncrypted: apiKeyEncrypted,
                apiSecretEncrypted: apiSecretEncrypted,
                accessTokenEncrypted: accessTokenEncrypted,
                refreshTokenEncrypted: refreshTokenEncrypted,
                config: config,
                lastSyncAt: lastSyncAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntegrationsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({businessId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (businessId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.businessId,
                                referencedTable:
                                    $$IntegrationsTableTableReferences
                                        ._businessIdTable(db),
                                referencedColumn:
                                    $$IntegrationsTableTableReferences
                                        ._businessIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntegrationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntegrationsTableTable,
      IntegrationsTableData,
      $$IntegrationsTableTableFilterComposer,
      $$IntegrationsTableTableOrderingComposer,
      $$IntegrationsTableTableAnnotationComposer,
      $$IntegrationsTableTableCreateCompanionBuilder,
      $$IntegrationsTableTableUpdateCompanionBuilder,
      (IntegrationsTableData, $$IntegrationsTableTableReferences),
      IntegrationsTableData,
      PrefetchHooks Function({bool businessId})
    >;
typedef $$SyncQueueItemsTableTableCreateCompanionBuilder =
    SyncQueueItemsTableCompanion Function({
      Value<int> id,
      required String operationType,
      required String entityType,
      required String entityId,
      Value<DateTime> timestamp,
      Value<String?> payload,
    });
typedef $$SyncQueueItemsTableTableUpdateCompanionBuilder =
    SyncQueueItemsTableCompanion Function({
      Value<int> id,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityId,
      Value<DateTime> timestamp,
      Value<String?> payload,
    });

class $$SyncQueueItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTableTable> {
  $$SyncQueueItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTableTable> {
  $$SyncQueueItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTableTable> {
  $$SyncQueueItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$SyncQueueItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTableTable,
          SyncQueueItemsTableData,
          $$SyncQueueItemsTableTableFilterComposer,
          $$SyncQueueItemsTableTableOrderingComposer,
          $$SyncQueueItemsTableTableAnnotationComposer,
          $$SyncQueueItemsTableTableCreateCompanionBuilder,
          $$SyncQueueItemsTableTableUpdateCompanionBuilder,
          (
            SyncQueueItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueItemsTableTable,
              SyncQueueItemsTableData
            >,
          ),
          SyncQueueItemsTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> payload = const Value.absent(),
              }) => SyncQueueItemsTableCompanion(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                timestamp: timestamp,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationType,
                required String entityType,
                required String entityId,
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> payload = const Value.absent(),
              }) => SyncQueueItemsTableCompanion.insert(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                timestamp: timestamp,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTableTable,
      SyncQueueItemsTableData,
      $$SyncQueueItemsTableTableFilterComposer,
      $$SyncQueueItemsTableTableOrderingComposer,
      $$SyncQueueItemsTableTableAnnotationComposer,
      $$SyncQueueItemsTableTableCreateCompanionBuilder,
      $$SyncQueueItemsTableTableUpdateCompanionBuilder,
      (
        SyncQueueItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncQueueItemsTableTable,
          SyncQueueItemsTableData
        >,
      ),
      SyncQueueItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$SupplierFavoritesTableTableCreateCompanionBuilder =
    SupplierFavoritesTableCompanion Function({
      required String supplierId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$SupplierFavoritesTableTableUpdateCompanionBuilder =
    SupplierFavoritesTableCompanion Function({
      Value<String> supplierId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$SupplierFavoritesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SupplierFavoritesTableTable> {
  $$SupplierFavoritesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SupplierFavoritesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplierFavoritesTableTable> {
  $$SupplierFavoritesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SupplierFavoritesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplierFavoritesTableTable> {
  $$SupplierFavoritesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SupplierFavoritesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SupplierFavoritesTableTable,
          SupplierFavoritesTableData,
          $$SupplierFavoritesTableTableFilterComposer,
          $$SupplierFavoritesTableTableOrderingComposer,
          $$SupplierFavoritesTableTableAnnotationComposer,
          $$SupplierFavoritesTableTableCreateCompanionBuilder,
          $$SupplierFavoritesTableTableUpdateCompanionBuilder,
          (
            SupplierFavoritesTableData,
            BaseReferences<
              _$AppDatabase,
              $SupplierFavoritesTableTable,
              SupplierFavoritesTableData
            >,
          ),
          SupplierFavoritesTableData,
          PrefetchHooks Function()
        > {
  $$SupplierFavoritesTableTableTableManager(
    _$AppDatabase db,
    $SupplierFavoritesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplierFavoritesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SupplierFavoritesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SupplierFavoritesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> supplierId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SupplierFavoritesTableCompanion(
                supplierId: supplierId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String supplierId,
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SupplierFavoritesTableCompanion.insert(
                supplierId: supplierId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SupplierFavoritesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SupplierFavoritesTableTable,
      SupplierFavoritesTableData,
      $$SupplierFavoritesTableTableFilterComposer,
      $$SupplierFavoritesTableTableOrderingComposer,
      $$SupplierFavoritesTableTableAnnotationComposer,
      $$SupplierFavoritesTableTableCreateCompanionBuilder,
      $$SupplierFavoritesTableTableUpdateCompanionBuilder,
      (
        SupplierFavoritesTableData,
        BaseReferences<
          _$AppDatabase,
          $SupplierFavoritesTableTable,
          SupplierFavoritesTableData
        >,
      ),
      SupplierFavoritesTableData,
      PrefetchHooks Function()
    >;
typedef $$ChatMessagesTableTableCreateCompanionBuilder =
    ChatMessagesTableCompanion Function({
      required String id,
      Value<String> conversationId,
      required String sender,
      required String body,
      required DateTime sentAt,
      required String status,
      Value<String?> attachmentPath,
      Value<String?> attachmentName,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableTableUpdateCompanionBuilder =
    ChatMessagesTableCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> sender,
      Value<String> body,
      Value<DateTime> sentAt,
      Value<String> status,
      Value<String?> attachmentPath,
      Value<String?> attachmentName,
      Value<int> rowid,
    });

class $$ChatMessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTableTable> {
  $$ChatMessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentName => $composableBuilder(
    column: $table.attachmentName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTableTable> {
  $$ChatMessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentName => $composableBuilder(
    column: $table.attachmentName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTableTable> {
  $$ChatMessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentName => $composableBuilder(
    column: $table.attachmentName,
    builder: (column) => column,
  );
}

class $$ChatMessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTableTable,
          ChatMessagesTableData,
          $$ChatMessagesTableTableFilterComposer,
          $$ChatMessagesTableTableOrderingComposer,
          $$ChatMessagesTableTableAnnotationComposer,
          $$ChatMessagesTableTableCreateCompanionBuilder,
          $$ChatMessagesTableTableUpdateCompanionBuilder,
          (
            ChatMessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $ChatMessagesTableTable,
              ChatMessagesTableData
            >,
          ),
          ChatMessagesTableData,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableTableManager(
    _$AppDatabase db,
    $ChatMessagesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<String?> attachmentName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesTableCompanion(
                id: id,
                conversationId: conversationId,
                sender: sender,
                body: body,
                sentAt: sentAt,
                status: status,
                attachmentPath: attachmentPath,
                attachmentName: attachmentName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> conversationId = const Value.absent(),
                required String sender,
                required String body,
                required DateTime sentAt,
                required String status,
                Value<String?> attachmentPath = const Value.absent(),
                Value<String?> attachmentName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesTableCompanion.insert(
                id: id,
                conversationId: conversationId,
                sender: sender,
                body: body,
                sentAt: sentAt,
                status: status,
                attachmentPath: attachmentPath,
                attachmentName: attachmentName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTableTable,
      ChatMessagesTableData,
      $$ChatMessagesTableTableFilterComposer,
      $$ChatMessagesTableTableOrderingComposer,
      $$ChatMessagesTableTableAnnotationComposer,
      $$ChatMessagesTableTableCreateCompanionBuilder,
      $$ChatMessagesTableTableUpdateCompanionBuilder,
      (
        ChatMessagesTableData,
        BaseReferences<
          _$AppDatabase,
          $ChatMessagesTableTable,
          ChatMessagesTableData
        >,
      ),
      ChatMessagesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BusinessesTableTableTableManager get businessesTable =>
      $$BusinessesTableTableTableManager(_db, _db.businessesTable);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$ProducersTableTableTableManager get producersTable =>
      $$ProducersTableTableTableManager(_db, _db.producersTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db, _db.channelsTable);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db, _db.ordersTable);
  $$OpportunitiesTableTableTableManager get opportunitiesTable =>
      $$OpportunitiesTableTableTableManager(_db, _db.opportunitiesTable);
  $$JourneysTableTableTableManager get journeysTable =>
      $$JourneysTableTableTableManager(_db, _db.journeysTable);
  $$JourneyStepsTableTableTableManager get journeyStepsTable =>
      $$JourneyStepsTableTableTableManager(_db, _db.journeyStepsTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$DocumentsTableTableTableManager get documentsTable =>
      $$DocumentsTableTableTableManager(_db, _db.documentsTable);
  $$AlertsTableTableTableManager get alertsTable =>
      $$AlertsTableTableTableManager(_db, _db.alertsTable);
  $$AIChatTableTableTableManager get aIChatTable =>
      $$AIChatTableTableTableManager(_db, _db.aIChatTable);
  $$IntegrationsTableTableTableManager get integrationsTable =>
      $$IntegrationsTableTableTableManager(_db, _db.integrationsTable);
  $$SyncQueueItemsTableTableTableManager get syncQueueItemsTable =>
      $$SyncQueueItemsTableTableTableManager(_db, _db.syncQueueItemsTable);
  $$SupplierFavoritesTableTableTableManager get supplierFavoritesTable =>
      $$SupplierFavoritesTableTableTableManager(
        _db,
        _db.supplierFavoritesTable,
      );
  $$ChatMessagesTableTableTableManager get chatMessagesTable =>
      $$ChatMessagesTableTableTableManager(_db, _db.chatMessagesTable);
}
