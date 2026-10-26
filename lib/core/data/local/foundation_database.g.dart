// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foundation_database.dart';

// ignore_for_file: type=lint
class $FoundationPreferencesTable extends FoundationPreferences
    with TableInfo<$FoundationPreferencesTable, FoundationPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoundationPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foundation_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoundationPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FoundationPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoundationPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FoundationPreferencesTable createAlias(String alias) {
    return $FoundationPreferencesTable(attachedDatabase, alias);
  }
}

class FoundationPreference extends DataClass
    implements Insertable<FoundationPreference> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const FoundationPreference({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FoundationPreferencesCompanion toCompanion(bool nullToAbsent) {
    return FoundationPreferencesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory FoundationPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoundationPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FoundationPreference copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => FoundationPreference(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FoundationPreference copyWithCompanion(FoundationPreferencesCompanion data) {
    return FoundationPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoundationPreference(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoundationPreference &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class FoundationPreferencesCompanion
    extends UpdateCompanion<FoundationPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FoundationPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoundationPreferencesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<FoundationPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoundationPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FoundationPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('FoundationPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRecordsTable extends LocalRecords
    with TableInfo<$LocalRecordsTable, LocalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionTimestampMeta = const VerificationMeta(
    'versionTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> versionTimestamp =
      GeneratedColumn<DateTime>(
        'version_timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<FoundationSyncState, int>
  syncState = GeneratedColumn<int>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<FoundationSyncState>($LocalRecordsTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    accountId,
    payload,
    versionTimestamp,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('version_timestamp')) {
      context.handle(
        _versionTimestampMeta,
        versionTimestamp.isAcceptableOrUnknown(
          data['version_timestamp']!,
          _versionTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionTimestampMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  LocalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecord(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      versionTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}version_timestamp'],
      )!,
      syncState: $LocalRecordsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalRecordsTable createAlias(String alias) {
    return $LocalRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FoundationSyncState, int, int> $convertersyncState =
      const EnumIndexConverter<FoundationSyncState>(FoundationSyncState.values);
}

class LocalRecord extends DataClass implements Insertable<LocalRecord> {
  final String recordId;
  final String? accountId;
  final String payload;
  final DateTime versionTimestamp;
  final FoundationSyncState syncState;
  final DateTime updatedAt;
  const LocalRecord({
    required this.recordId,
    this.accountId,
    required this.payload,
    required this.versionTimestamp,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['payload'] = Variable<String>(payload);
    map['version_timestamp'] = Variable<DateTime>(versionTimestamp);
    {
      map['sync_state'] = Variable<int>(
        $LocalRecordsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecordsCompanion(
      recordId: Value(recordId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      payload: Value(payload),
      versionTimestamp: Value(versionTimestamp),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecord(
      recordId: serializer.fromJson<String>(json['recordId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      payload: serializer.fromJson<String>(json['payload']),
      versionTimestamp: serializer.fromJson<DateTime>(json['versionTimestamp']),
      syncState: $LocalRecordsTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'accountId': serializer.toJson<String?>(accountId),
      'payload': serializer.toJson<String>(payload),
      'versionTimestamp': serializer.toJson<DateTime>(versionTimestamp),
      'syncState': serializer.toJson<int>(
        $LocalRecordsTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalRecord copyWith({
    String? recordId,
    Value<String?> accountId = const Value.absent(),
    String? payload,
    DateTime? versionTimestamp,
    FoundationSyncState? syncState,
    DateTime? updatedAt,
  }) => LocalRecord(
    recordId: recordId ?? this.recordId,
    accountId: accountId.present ? accountId.value : this.accountId,
    payload: payload ?? this.payload,
    versionTimestamp: versionTimestamp ?? this.versionTimestamp,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalRecord copyWithCompanion(LocalRecordsCompanion data) {
    return LocalRecord(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      payload: data.payload.present ? data.payload.value : this.payload,
      versionTimestamp: data.versionTimestamp.present
          ? data.versionTimestamp.value
          : this.versionTimestamp,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecord(')
          ..write('recordId: $recordId, ')
          ..write('accountId: $accountId, ')
          ..write('payload: $payload, ')
          ..write('versionTimestamp: $versionTimestamp, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    accountId,
    payload,
    versionTimestamp,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecord &&
          other.recordId == this.recordId &&
          other.accountId == this.accountId &&
          other.payload == this.payload &&
          other.versionTimestamp == this.versionTimestamp &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalRecordsCompanion extends UpdateCompanion<LocalRecord> {
  final Value<String> recordId;
  final Value<String?> accountId;
  final Value<String> payload;
  final Value<DateTime> versionTimestamp;
  final Value<FoundationSyncState> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalRecordsCompanion({
    this.recordId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.payload = const Value.absent(),
    this.versionTimestamp = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecordsCompanion.insert({
    required String recordId,
    this.accountId = const Value.absent(),
    required String payload,
    required DateTime versionTimestamp,
    required FoundationSyncState syncState,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       payload = Value(payload),
       versionTimestamp = Value(versionTimestamp),
       syncState = Value(syncState),
       updatedAt = Value(updatedAt);
  static Insertable<LocalRecord> custom({
    Expression<String>? recordId,
    Expression<String>? accountId,
    Expression<String>? payload,
    Expression<DateTime>? versionTimestamp,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (accountId != null) 'account_id': accountId,
      if (payload != null) 'payload': payload,
      if (versionTimestamp != null) 'version_timestamp': versionTimestamp,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecordsCompanion copyWith({
    Value<String>? recordId,
    Value<String?>? accountId,
    Value<String>? payload,
    Value<DateTime>? versionTimestamp,
    Value<FoundationSyncState>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalRecordsCompanion(
      recordId: recordId ?? this.recordId,
      accountId: accountId ?? this.accountId,
      payload: payload ?? this.payload,
      versionTimestamp: versionTimestamp ?? this.versionTimestamp,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (versionTimestamp.present) {
      map['version_timestamp'] = Variable<DateTime>(versionTimestamp.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalRecordsTable.$convertersyncState.toSql(syncState.value),
      );
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
    return (StringBuffer('LocalRecordsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('accountId: $accountId, ')
          ..write('payload: $payload, ')
          ..write('versionTimestamp: $versionTimestamp, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingChangesTable extends PendingChanges
    with TableInfo<$PendingChangesTable, PendingChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<ChangeKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ChangeKind>($PendingChangesTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<PendingChangeState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<PendingChangeState>($PendingChangesTable.$converterstate);
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFailureSummaryMeta =
      const VerificationMeta('lastFailureSummary');
  @override
  late final GeneratedColumn<String> lastFailureSummary =
      GeneratedColumn<String>(
        'last_failure_summary',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serializedChangeMeta = const VerificationMeta(
    'serializedChange',
  );
  @override
  late final GeneratedColumn<String> serializedChange = GeneratedColumn<String>(
    'serialized_change',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgementIdMeta = const VerificationMeta(
    'acknowledgementId',
  );
  @override
  late final GeneratedColumn<String> acknowledgementId =
      GeneratedColumn<String>(
        'acknowledgement_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionTimestampMeta = const VerificationMeta(
    'versionTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> versionTimestamp =
      GeneratedColumn<DateTime>(
        'version_timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    accountId,
    entityType,
    entityId,
    kind,
    state,
    attemptCount,
    lastFailureSummary,
    serializedChange,
    acknowledgementId,
    createdAt,
    versionTimestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_failure_summary')) {
      context.handle(
        _lastFailureSummaryMeta,
        lastFailureSummary.isAcceptableOrUnknown(
          data['last_failure_summary']!,
          _lastFailureSummaryMeta,
        ),
      );
    }
    if (data.containsKey('serialized_change')) {
      context.handle(
        _serializedChangeMeta,
        serializedChange.isAcceptableOrUnknown(
          data['serialized_change']!,
          _serializedChangeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serializedChangeMeta);
    }
    if (data.containsKey('acknowledgement_id')) {
      context.handle(
        _acknowledgementIdMeta,
        acknowledgementId.isAcceptableOrUnknown(
          data['acknowledgement_id']!,
          _acknowledgementIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('version_timestamp')) {
      context.handle(
        _versionTimestampMeta,
        versionTimestamp.isAcceptableOrUnknown(
          data['version_timestamp']!,
          _versionTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionTimestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  PendingChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingChange(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      kind: $PendingChangesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      state: $PendingChangesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastFailureSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure_summary'],
      ),
      serializedChange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serialized_change'],
      )!,
      acknowledgementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acknowledgement_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      versionTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}version_timestamp'],
      )!,
    );
  }

  @override
  $PendingChangesTable createAlias(String alias) {
    return $PendingChangesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChangeKind, int, int> $converterkind =
      const EnumIndexConverter<ChangeKind>(ChangeKind.values);
  static JsonTypeConverter2<PendingChangeState, int, int> $converterstate =
      const EnumIndexConverter<PendingChangeState>(PendingChangeState.values);
}

class PendingChange extends DataClass implements Insertable<PendingChange> {
  final String operationId;
  final String accountId;
  final String entityType;
  final String entityId;
  final ChangeKind kind;
  final PendingChangeState state;
  final int attemptCount;
  final String? lastFailureSummary;
  final String serializedChange;
  final String? acknowledgementId;
  final DateTime createdAt;
  final DateTime versionTimestamp;
  const PendingChange({
    required this.operationId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.state,
    required this.attemptCount,
    this.lastFailureSummary,
    required this.serializedChange,
    this.acknowledgementId,
    required this.createdAt,
    required this.versionTimestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['account_id'] = Variable<String>(accountId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['kind'] = Variable<int>(
        $PendingChangesTable.$converterkind.toSql(kind),
      );
    }
    {
      map['state'] = Variable<int>(
        $PendingChangesTable.$converterstate.toSql(state),
      );
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastFailureSummary != null) {
      map['last_failure_summary'] = Variable<String>(lastFailureSummary);
    }
    map['serialized_change'] = Variable<String>(serializedChange);
    if (!nullToAbsent || acknowledgementId != null) {
      map['acknowledgement_id'] = Variable<String>(acknowledgementId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['version_timestamp'] = Variable<DateTime>(versionTimestamp);
    return map;
  }

  PendingChangesCompanion toCompanion(bool nullToAbsent) {
    return PendingChangesCompanion(
      operationId: Value(operationId),
      accountId: Value(accountId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      kind: Value(kind),
      state: Value(state),
      attemptCount: Value(attemptCount),
      lastFailureSummary: lastFailureSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureSummary),
      serializedChange: Value(serializedChange),
      acknowledgementId: acknowledgementId == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgementId),
      createdAt: Value(createdAt),
      versionTimestamp: Value(versionTimestamp),
    );
  }

  factory PendingChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingChange(
      operationId: serializer.fromJson<String>(json['operationId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      kind: $PendingChangesTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      state: $PendingChangesTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastFailureSummary: serializer.fromJson<String?>(
        json['lastFailureSummary'],
      ),
      serializedChange: serializer.fromJson<String>(json['serializedChange']),
      acknowledgementId: serializer.fromJson<String?>(
        json['acknowledgementId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      versionTimestamp: serializer.fromJson<DateTime>(json['versionTimestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'accountId': serializer.toJson<String>(accountId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'kind': serializer.toJson<int>(
        $PendingChangesTable.$converterkind.toJson(kind),
      ),
      'state': serializer.toJson<int>(
        $PendingChangesTable.$converterstate.toJson(state),
      ),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastFailureSummary': serializer.toJson<String?>(lastFailureSummary),
      'serializedChange': serializer.toJson<String>(serializedChange),
      'acknowledgementId': serializer.toJson<String?>(acknowledgementId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'versionTimestamp': serializer.toJson<DateTime>(versionTimestamp),
    };
  }

  PendingChange copyWith({
    String? operationId,
    String? accountId,
    String? entityType,
    String? entityId,
    ChangeKind? kind,
    PendingChangeState? state,
    int? attemptCount,
    Value<String?> lastFailureSummary = const Value.absent(),
    String? serializedChange,
    Value<String?> acknowledgementId = const Value.absent(),
    DateTime? createdAt,
    DateTime? versionTimestamp,
  }) => PendingChange(
    operationId: operationId ?? this.operationId,
    accountId: accountId ?? this.accountId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    kind: kind ?? this.kind,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    lastFailureSummary: lastFailureSummary.present
        ? lastFailureSummary.value
        : this.lastFailureSummary,
    serializedChange: serializedChange ?? this.serializedChange,
    acknowledgementId: acknowledgementId.present
        ? acknowledgementId.value
        : this.acknowledgementId,
    createdAt: createdAt ?? this.createdAt,
    versionTimestamp: versionTimestamp ?? this.versionTimestamp,
  );
  PendingChange copyWithCompanion(PendingChangesCompanion data) {
    return PendingChange(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      state: data.state.present ? data.state.value : this.state,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastFailureSummary: data.lastFailureSummary.present
          ? data.lastFailureSummary.value
          : this.lastFailureSummary,
      serializedChange: data.serializedChange.present
          ? data.serializedChange.value
          : this.serializedChange,
      acknowledgementId: data.acknowledgementId.present
          ? data.acknowledgementId.value
          : this.acknowledgementId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      versionTimestamp: data.versionTimestamp.present
          ? data.versionTimestamp.value
          : this.versionTimestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingChange(')
          ..write('operationId: $operationId, ')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastFailureSummary: $lastFailureSummary, ')
          ..write('serializedChange: $serializedChange, ')
          ..write('acknowledgementId: $acknowledgementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('versionTimestamp: $versionTimestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    accountId,
    entityType,
    entityId,
    kind,
    state,
    attemptCount,
    lastFailureSummary,
    serializedChange,
    acknowledgementId,
    createdAt,
    versionTimestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingChange &&
          other.operationId == this.operationId &&
          other.accountId == this.accountId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.kind == this.kind &&
          other.state == this.state &&
          other.attemptCount == this.attemptCount &&
          other.lastFailureSummary == this.lastFailureSummary &&
          other.serializedChange == this.serializedChange &&
          other.acknowledgementId == this.acknowledgementId &&
          other.createdAt == this.createdAt &&
          other.versionTimestamp == this.versionTimestamp);
}

class PendingChangesCompanion extends UpdateCompanion<PendingChange> {
  final Value<String> operationId;
  final Value<String> accountId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<ChangeKind> kind;
  final Value<PendingChangeState> state;
  final Value<int> attemptCount;
  final Value<String?> lastFailureSummary;
  final Value<String> serializedChange;
  final Value<String?> acknowledgementId;
  final Value<DateTime> createdAt;
  final Value<DateTime> versionTimestamp;
  final Value<int> rowid;
  const PendingChangesCompanion({
    this.operationId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastFailureSummary = const Value.absent(),
    this.serializedChange = const Value.absent(),
    this.acknowledgementId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.versionTimestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingChangesCompanion.insert({
    required String operationId,
    required String accountId,
    required String entityType,
    required String entityId,
    required ChangeKind kind,
    required PendingChangeState state,
    this.attemptCount = const Value.absent(),
    this.lastFailureSummary = const Value.absent(),
    required String serializedChange,
    this.acknowledgementId = const Value.absent(),
    required DateTime createdAt,
    required DateTime versionTimestamp,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       accountId = Value(accountId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       kind = Value(kind),
       state = Value(state),
       serializedChange = Value(serializedChange),
       createdAt = Value(createdAt),
       versionTimestamp = Value(versionTimestamp);
  static Insertable<PendingChange> custom({
    Expression<String>? operationId,
    Expression<String>? accountId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? kind,
    Expression<int>? state,
    Expression<int>? attemptCount,
    Expression<String>? lastFailureSummary,
    Expression<String>? serializedChange,
    Expression<String>? acknowledgementId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? versionTimestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (accountId != null) 'account_id': accountId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (kind != null) 'kind': kind,
      if (state != null) 'state': state,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastFailureSummary != null)
        'last_failure_summary': lastFailureSummary,
      if (serializedChange != null) 'serialized_change': serializedChange,
      if (acknowledgementId != null) 'acknowledgement_id': acknowledgementId,
      if (createdAt != null) 'created_at': createdAt,
      if (versionTimestamp != null) 'version_timestamp': versionTimestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingChangesCompanion copyWith({
    Value<String>? operationId,
    Value<String>? accountId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<ChangeKind>? kind,
    Value<PendingChangeState>? state,
    Value<int>? attemptCount,
    Value<String?>? lastFailureSummary,
    Value<String>? serializedChange,
    Value<String?>? acknowledgementId,
    Value<DateTime>? createdAt,
    Value<DateTime>? versionTimestamp,
    Value<int>? rowid,
  }) {
    return PendingChangesCompanion(
      operationId: operationId ?? this.operationId,
      accountId: accountId ?? this.accountId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastFailureSummary: lastFailureSummary ?? this.lastFailureSummary,
      serializedChange: serializedChange ?? this.serializedChange,
      acknowledgementId: acknowledgementId ?? this.acknowledgementId,
      createdAt: createdAt ?? this.createdAt,
      versionTimestamp: versionTimestamp ?? this.versionTimestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $PendingChangesTable.$converterkind.toSql(kind.value),
      );
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $PendingChangesTable.$converterstate.toSql(state.value),
      );
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastFailureSummary.present) {
      map['last_failure_summary'] = Variable<String>(lastFailureSummary.value);
    }
    if (serializedChange.present) {
      map['serialized_change'] = Variable<String>(serializedChange.value);
    }
    if (acknowledgementId.present) {
      map['acknowledgement_id'] = Variable<String>(acknowledgementId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (versionTimestamp.present) {
      map['version_timestamp'] = Variable<DateTime>(versionTimestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastFailureSummary: $lastFailureSummary, ')
          ..write('serializedChange: $serializedChange, ')
          ..write('acknowledgementId: $acknowledgementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('versionTimestamp: $versionTimestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictRecordsTable extends ConflictRecords
    with TableInfo<$ConflictRecordsTable, ConflictRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conflictIdMeta = const VerificationMeta(
    'conflictId',
  );
  @override
  late final GeneratedColumn<String> conflictId = GeneratedColumn<String>(
    'conflict_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<VersionSource, int> activeSource =
      GeneratedColumn<int>(
        'active_source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<VersionSource>(
        $ConflictRecordsTable.$converteractiveSource,
      );
  static const VerificationMeta _activeTimestampMeta = const VerificationMeta(
    'activeTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> activeTimestamp =
      GeneratedColumn<DateTime>(
        'active_timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activePayloadMeta = const VerificationMeta(
    'activePayload',
  );
  @override
  late final GeneratedColumn<String> activePayload = GeneratedColumn<String>(
    'active_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VersionSource, int>
  retainedSource =
      GeneratedColumn<int>(
        'retained_source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<VersionSource>(
        $ConflictRecordsTable.$converterretainedSource,
      );
  static const VerificationMeta _retainedTimestampMeta = const VerificationMeta(
    'retainedTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> retainedTimestamp =
      GeneratedColumn<DateTime>(
        'retained_timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _retainedPayloadMeta = const VerificationMeta(
    'retainedPayload',
  );
  @override
  late final GeneratedColumn<String> retainedPayload = GeneratedColumn<String>(
    'retained_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    conflictId,
    accountId,
    entityType,
    entityId,
    activeSource,
    activeTimestamp,
    activePayload,
    retainedSource,
    retainedTimestamp,
    retainedPayload,
    detectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conflict_id')) {
      context.handle(
        _conflictIdMeta,
        conflictId.isAcceptableOrUnknown(data['conflict_id']!, _conflictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conflictIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
    if (data.containsKey('active_timestamp')) {
      context.handle(
        _activeTimestampMeta,
        activeTimestamp.isAcceptableOrUnknown(
          data['active_timestamp']!,
          _activeTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeTimestampMeta);
    }
    if (data.containsKey('active_payload')) {
      context.handle(
        _activePayloadMeta,
        activePayload.isAcceptableOrUnknown(
          data['active_payload']!,
          _activePayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activePayloadMeta);
    }
    if (data.containsKey('retained_timestamp')) {
      context.handle(
        _retainedTimestampMeta,
        retainedTimestamp.isAcceptableOrUnknown(
          data['retained_timestamp']!,
          _retainedTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retainedTimestampMeta);
    }
    if (data.containsKey('retained_payload')) {
      context.handle(
        _retainedPayloadMeta,
        retainedPayload.isAcceptableOrUnknown(
          data['retained_payload']!,
          _retainedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retainedPayloadMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conflictId};
  @override
  ConflictRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictRecord(
      conflictId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      activeSource: $ConflictRecordsTable.$converteractiveSource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}active_source'],
        )!,
      ),
      activeTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}active_timestamp'],
      )!,
      activePayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_payload'],
      )!,
      retainedSource: $ConflictRecordsTable.$converterretainedSource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}retained_source'],
        )!,
      ),
      retainedTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retained_timestamp'],
      )!,
      retainedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retained_payload'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
    );
  }

  @override
  $ConflictRecordsTable createAlias(String alias) {
    return $ConflictRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VersionSource, int, int> $converteractiveSource =
      const EnumIndexConverter<VersionSource>(VersionSource.values);
  static JsonTypeConverter2<VersionSource, int, int> $converterretainedSource =
      const EnumIndexConverter<VersionSource>(VersionSource.values);
}

class ConflictRecord extends DataClass implements Insertable<ConflictRecord> {
  final String conflictId;
  final String accountId;
  final String entityType;
  final String entityId;
  final VersionSource activeSource;
  final DateTime activeTimestamp;
  final String activePayload;
  final VersionSource retainedSource;
  final DateTime retainedTimestamp;
  final String retainedPayload;
  final DateTime detectedAt;
  const ConflictRecord({
    required this.conflictId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.activeSource,
    required this.activeTimestamp,
    required this.activePayload,
    required this.retainedSource,
    required this.retainedTimestamp,
    required this.retainedPayload,
    required this.detectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conflict_id'] = Variable<String>(conflictId);
    map['account_id'] = Variable<String>(accountId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['active_source'] = Variable<int>(
        $ConflictRecordsTable.$converteractiveSource.toSql(activeSource),
      );
    }
    map['active_timestamp'] = Variable<DateTime>(activeTimestamp);
    map['active_payload'] = Variable<String>(activePayload);
    {
      map['retained_source'] = Variable<int>(
        $ConflictRecordsTable.$converterretainedSource.toSql(retainedSource),
      );
    }
    map['retained_timestamp'] = Variable<DateTime>(retainedTimestamp);
    map['retained_payload'] = Variable<String>(retainedPayload);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    return map;
  }

  ConflictRecordsCompanion toCompanion(bool nullToAbsent) {
    return ConflictRecordsCompanion(
      conflictId: Value(conflictId),
      accountId: Value(accountId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      activeSource: Value(activeSource),
      activeTimestamp: Value(activeTimestamp),
      activePayload: Value(activePayload),
      retainedSource: Value(retainedSource),
      retainedTimestamp: Value(retainedTimestamp),
      retainedPayload: Value(retainedPayload),
      detectedAt: Value(detectedAt),
    );
  }

  factory ConflictRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictRecord(
      conflictId: serializer.fromJson<String>(json['conflictId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      activeSource: $ConflictRecordsTable.$converteractiveSource.fromJson(
        serializer.fromJson<int>(json['activeSource']),
      ),
      activeTimestamp: serializer.fromJson<DateTime>(json['activeTimestamp']),
      activePayload: serializer.fromJson<String>(json['activePayload']),
      retainedSource: $ConflictRecordsTable.$converterretainedSource.fromJson(
        serializer.fromJson<int>(json['retainedSource']),
      ),
      retainedTimestamp: serializer.fromJson<DateTime>(
        json['retainedTimestamp'],
      ),
      retainedPayload: serializer.fromJson<String>(json['retainedPayload']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conflictId': serializer.toJson<String>(conflictId),
      'accountId': serializer.toJson<String>(accountId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'activeSource': serializer.toJson<int>(
        $ConflictRecordsTable.$converteractiveSource.toJson(activeSource),
      ),
      'activeTimestamp': serializer.toJson<DateTime>(activeTimestamp),
      'activePayload': serializer.toJson<String>(activePayload),
      'retainedSource': serializer.toJson<int>(
        $ConflictRecordsTable.$converterretainedSource.toJson(retainedSource),
      ),
      'retainedTimestamp': serializer.toJson<DateTime>(retainedTimestamp),
      'retainedPayload': serializer.toJson<String>(retainedPayload),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
    };
  }

  ConflictRecord copyWith({
    String? conflictId,
    String? accountId,
    String? entityType,
    String? entityId,
    VersionSource? activeSource,
    DateTime? activeTimestamp,
    String? activePayload,
    VersionSource? retainedSource,
    DateTime? retainedTimestamp,
    String? retainedPayload,
    DateTime? detectedAt,
  }) => ConflictRecord(
    conflictId: conflictId ?? this.conflictId,
    accountId: accountId ?? this.accountId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    activeSource: activeSource ?? this.activeSource,
    activeTimestamp: activeTimestamp ?? this.activeTimestamp,
    activePayload: activePayload ?? this.activePayload,
    retainedSource: retainedSource ?? this.retainedSource,
    retainedTimestamp: retainedTimestamp ?? this.retainedTimestamp,
    retainedPayload: retainedPayload ?? this.retainedPayload,
    detectedAt: detectedAt ?? this.detectedAt,
  );
  ConflictRecord copyWithCompanion(ConflictRecordsCompanion data) {
    return ConflictRecord(
      conflictId: data.conflictId.present
          ? data.conflictId.value
          : this.conflictId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      activeSource: data.activeSource.present
          ? data.activeSource.value
          : this.activeSource,
      activeTimestamp: data.activeTimestamp.present
          ? data.activeTimestamp.value
          : this.activeTimestamp,
      activePayload: data.activePayload.present
          ? data.activePayload.value
          : this.activePayload,
      retainedSource: data.retainedSource.present
          ? data.retainedSource.value
          : this.retainedSource,
      retainedTimestamp: data.retainedTimestamp.present
          ? data.retainedTimestamp.value
          : this.retainedTimestamp,
      retainedPayload: data.retainedPayload.present
          ? data.retainedPayload.value
          : this.retainedPayload,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRecord(')
          ..write('conflictId: $conflictId, ')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('activeSource: $activeSource, ')
          ..write('activeTimestamp: $activeTimestamp, ')
          ..write('activePayload: $activePayload, ')
          ..write('retainedSource: $retainedSource, ')
          ..write('retainedTimestamp: $retainedTimestamp, ')
          ..write('retainedPayload: $retainedPayload, ')
          ..write('detectedAt: $detectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conflictId,
    accountId,
    entityType,
    entityId,
    activeSource,
    activeTimestamp,
    activePayload,
    retainedSource,
    retainedTimestamp,
    retainedPayload,
    detectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictRecord &&
          other.conflictId == this.conflictId &&
          other.accountId == this.accountId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.activeSource == this.activeSource &&
          other.activeTimestamp == this.activeTimestamp &&
          other.activePayload == this.activePayload &&
          other.retainedSource == this.retainedSource &&
          other.retainedTimestamp == this.retainedTimestamp &&
          other.retainedPayload == this.retainedPayload &&
          other.detectedAt == this.detectedAt);
}

class ConflictRecordsCompanion extends UpdateCompanion<ConflictRecord> {
  final Value<String> conflictId;
  final Value<String> accountId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<VersionSource> activeSource;
  final Value<DateTime> activeTimestamp;
  final Value<String> activePayload;
  final Value<VersionSource> retainedSource;
  final Value<DateTime> retainedTimestamp;
  final Value<String> retainedPayload;
  final Value<DateTime> detectedAt;
  final Value<int> rowid;
  const ConflictRecordsCompanion({
    this.conflictId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.activeSource = const Value.absent(),
    this.activeTimestamp = const Value.absent(),
    this.activePayload = const Value.absent(),
    this.retainedSource = const Value.absent(),
    this.retainedTimestamp = const Value.absent(),
    this.retainedPayload = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictRecordsCompanion.insert({
    required String conflictId,
    required String accountId,
    required String entityType,
    required String entityId,
    required VersionSource activeSource,
    required DateTime activeTimestamp,
    required String activePayload,
    required VersionSource retainedSource,
    required DateTime retainedTimestamp,
    required String retainedPayload,
    required DateTime detectedAt,
    this.rowid = const Value.absent(),
  }) : conflictId = Value(conflictId),
       accountId = Value(accountId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       activeSource = Value(activeSource),
       activeTimestamp = Value(activeTimestamp),
       activePayload = Value(activePayload),
       retainedSource = Value(retainedSource),
       retainedTimestamp = Value(retainedTimestamp),
       retainedPayload = Value(retainedPayload),
       detectedAt = Value(detectedAt);
  static Insertable<ConflictRecord> custom({
    Expression<String>? conflictId,
    Expression<String>? accountId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? activeSource,
    Expression<DateTime>? activeTimestamp,
    Expression<String>? activePayload,
    Expression<int>? retainedSource,
    Expression<DateTime>? retainedTimestamp,
    Expression<String>? retainedPayload,
    Expression<DateTime>? detectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conflictId != null) 'conflict_id': conflictId,
      if (accountId != null) 'account_id': accountId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (activeSource != null) 'active_source': activeSource,
      if (activeTimestamp != null) 'active_timestamp': activeTimestamp,
      if (activePayload != null) 'active_payload': activePayload,
      if (retainedSource != null) 'retained_source': retainedSource,
      if (retainedTimestamp != null) 'retained_timestamp': retainedTimestamp,
      if (retainedPayload != null) 'retained_payload': retainedPayload,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictRecordsCompanion copyWith({
    Value<String>? conflictId,
    Value<String>? accountId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<VersionSource>? activeSource,
    Value<DateTime>? activeTimestamp,
    Value<String>? activePayload,
    Value<VersionSource>? retainedSource,
    Value<DateTime>? retainedTimestamp,
    Value<String>? retainedPayload,
    Value<DateTime>? detectedAt,
    Value<int>? rowid,
  }) {
    return ConflictRecordsCompanion(
      conflictId: conflictId ?? this.conflictId,
      accountId: accountId ?? this.accountId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      activeSource: activeSource ?? this.activeSource,
      activeTimestamp: activeTimestamp ?? this.activeTimestamp,
      activePayload: activePayload ?? this.activePayload,
      retainedSource: retainedSource ?? this.retainedSource,
      retainedTimestamp: retainedTimestamp ?? this.retainedTimestamp,
      retainedPayload: retainedPayload ?? this.retainedPayload,
      detectedAt: detectedAt ?? this.detectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conflictId.present) {
      map['conflict_id'] = Variable<String>(conflictId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (activeSource.present) {
      map['active_source'] = Variable<int>(
        $ConflictRecordsTable.$converteractiveSource.toSql(activeSource.value),
      );
    }
    if (activeTimestamp.present) {
      map['active_timestamp'] = Variable<DateTime>(activeTimestamp.value);
    }
    if (activePayload.present) {
      map['active_payload'] = Variable<String>(activePayload.value);
    }
    if (retainedSource.present) {
      map['retained_source'] = Variable<int>(
        $ConflictRecordsTable.$converterretainedSource.toSql(
          retainedSource.value,
        ),
      );
    }
    if (retainedTimestamp.present) {
      map['retained_timestamp'] = Variable<DateTime>(retainedTimestamp.value);
    }
    if (retainedPayload.present) {
      map['retained_payload'] = Variable<String>(retainedPayload.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRecordsCompanion(')
          ..write('conflictId: $conflictId, ')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('activeSource: $activeSource, ')
          ..write('activeTimestamp: $activeTimestamp, ')
          ..write('activePayload: $activePayload, ')
          ..write('retainedSource: $retainedSource, ')
          ..write('retainedTimestamp: $retainedTimestamp, ')
          ..write('retainedPayload: $retainedPayload, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationJournalTable extends MigrationJournal
    with TableInfo<$MigrationJournalTable, MigrationJournalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationJournalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryDetailMeta = const VerificationMeta(
    'recoveryDetail',
  );
  @override
  late final GeneratedColumn<String> recoveryDetail = GeneratedColumn<String>(
    'recovery_detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    status,
    startedAt,
    endedAt,
    recoveryDetail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_journal';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationJournalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('recovery_detail')) {
      context.handle(
        _recoveryDetailMeta,
        recoveryDetail.isAcceptableOrUnknown(
          data['recovery_detail']!,
          _recoveryDetailMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationJournalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationJournalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      recoveryDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_detail'],
      ),
    );
  }

  @override
  $MigrationJournalTable createAlias(String alias) {
    return $MigrationJournalTable(attachedDatabase, alias);
  }
}

class MigrationJournalData extends DataClass
    implements Insertable<MigrationJournalData> {
  final int id;
  final int version;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? recoveryDetail;
  const MigrationJournalData({
    required this.id,
    required this.version,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.recoveryDetail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<int>(version);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || recoveryDetail != null) {
      map['recovery_detail'] = Variable<String>(recoveryDetail);
    }
    return map;
  }

  MigrationJournalCompanion toCompanion(bool nullToAbsent) {
    return MigrationJournalCompanion(
      id: Value(id),
      version: Value(version),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      recoveryDetail: recoveryDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryDetail),
    );
  }

  factory MigrationJournalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationJournalData(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      recoveryDetail: serializer.fromJson<String?>(json['recoveryDetail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<int>(version),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'recoveryDetail': serializer.toJson<String?>(recoveryDetail),
    };
  }

  MigrationJournalData copyWith({
    int? id,
    int? version,
    String? status,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> recoveryDetail = const Value.absent(),
  }) => MigrationJournalData(
    id: id ?? this.id,
    version: version ?? this.version,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    recoveryDetail: recoveryDetail.present
        ? recoveryDetail.value
        : this.recoveryDetail,
  );
  MigrationJournalData copyWithCompanion(MigrationJournalCompanion data) {
    return MigrationJournalData(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      recoveryDetail: data.recoveryDetail.present
          ? data.recoveryDetail.value
          : this.recoveryDetail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationJournalData(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('recoveryDetail: $recoveryDetail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, version, status, startedAt, endedAt, recoveryDetail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationJournalData &&
          other.id == this.id &&
          other.version == this.version &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.recoveryDetail == this.recoveryDetail);
}

class MigrationJournalCompanion extends UpdateCompanion<MigrationJournalData> {
  final Value<int> id;
  final Value<int> version;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> recoveryDetail;
  const MigrationJournalCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.recoveryDetail = const Value.absent(),
  });
  MigrationJournalCompanion.insert({
    this.id = const Value.absent(),
    required int version,
    required String status,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.recoveryDetail = const Value.absent(),
  }) : version = Value(version),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<MigrationJournalData> custom({
    Expression<int>? id,
    Expression<int>? version,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? recoveryDetail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (recoveryDetail != null) 'recovery_detail': recoveryDetail,
    });
  }

  MigrationJournalCompanion copyWith({
    Value<int>? id,
    Value<int>? version,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? recoveryDetail,
  }) {
    return MigrationJournalCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      recoveryDetail: recoveryDetail ?? this.recoveryDetail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (recoveryDetail.present) {
      map['recovery_detail'] = Variable<String>(recoveryDetail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationJournalCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('recoveryDetail: $recoveryDetail')
          ..write(')'))
        .toString();
  }
}

class $FoundationAuditLogTable extends FoundationAuditLog
    with TableInfo<$FoundationAuditLogTable, FoundationAuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoundationAuditLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, note, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foundation_audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoundationAuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoundationAuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoundationAuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $FoundationAuditLogTable createAlias(String alias) {
    return $FoundationAuditLogTable(attachedDatabase, alias);
  }
}

class FoundationAuditLogData extends DataClass
    implements Insertable<FoundationAuditLogData> {
  final int id;
  final String note;
  final DateTime at;
  const FoundationAuditLogData({
    required this.id,
    required this.note,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['note'] = Variable<String>(note);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  FoundationAuditLogCompanion toCompanion(bool nullToAbsent) {
    return FoundationAuditLogCompanion(
      id: Value(id),
      note: Value(note),
      at: Value(at),
    );
  }

  factory FoundationAuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoundationAuditLogData(
      id: serializer.fromJson<int>(json['id']),
      note: serializer.fromJson<String>(json['note']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'note': serializer.toJson<String>(note),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  FoundationAuditLogData copyWith({int? id, String? note, DateTime? at}) =>
      FoundationAuditLogData(
        id: id ?? this.id,
        note: note ?? this.note,
        at: at ?? this.at,
      );
  FoundationAuditLogData copyWithCompanion(FoundationAuditLogCompanion data) {
    return FoundationAuditLogData(
      id: data.id.present ? data.id.value : this.id,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoundationAuditLogData(')
          ..write('id: $id, ')
          ..write('note: $note, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, note, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoundationAuditLogData &&
          other.id == this.id &&
          other.note == this.note &&
          other.at == this.at);
}

class FoundationAuditLogCompanion
    extends UpdateCompanion<FoundationAuditLogData> {
  final Value<int> id;
  final Value<String> note;
  final Value<DateTime> at;
  const FoundationAuditLogCompanion({
    this.id = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
  });
  FoundationAuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String note,
    required DateTime at,
  }) : note = Value(note),
       at = Value(at);
  static Insertable<FoundationAuditLogData> custom({
    Expression<int>? id,
    Expression<String>? note,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
    });
  }

  FoundationAuditLogCompanion copyWith({
    Value<int>? id,
    Value<String>? note,
    Value<DateTime>? at,
  }) {
    return FoundationAuditLogCompanion(
      id: id ?? this.id,
      note: note ?? this.note,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoundationAuditLogCompanion(')
          ..write('id: $id, ')
          ..write('note: $note, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $TaskRecordsTable extends TaskRecords
    with TableInfo<$TaskRecordsTable, TaskRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
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
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
    'scheduled_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDeadlineMeta = const VerificationMeta(
    'targetDeadline',
  );
  @override
  late final GeneratedColumn<DateTime> targetDeadline =
      GeneratedColumn<DateTime>(
        'target_deadline',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetDeadlineUtcOffsetMinutesMeta =
      const VerificationMeta('targetDeadlineUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> targetDeadlineUtcOffsetMinutes =
      GeneratedColumn<int>(
        'target_deadline_utc_offset_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quadrantMeta = const VerificationMeta(
    'quadrant',
  );
  @override
  late final GeneratedColumn<String> quadrant = GeneratedColumn<String>(
    'quadrant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedDurationMinutesMeta =
      const VerificationMeta('estimatedDurationMinutes');
  @override
  late final GeneratedColumn<int> estimatedDurationMinutes =
      GeneratedColumn<int>(
        'estimated_duration_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _checklistJsonMeta = const VerificationMeta(
    'checklistJson',
  );
  @override
  late final GeneratedColumn<String> checklistJson = GeneratedColumn<String>(
    'checklist_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('[]'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionChangedAtMeta =
      const VerificationMeta('completionChangedAt');
  @override
  late final GeneratedColumn<DateTime> completionChangedAt =
      GeneratedColumn<DateTime>(
        'completion_changed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _completionXpMeta = const VerificationMeta(
    'completionXp',
  );
  @override
  late final GeneratedColumn<int> completionXp = GeneratedColumn<int>(
    'completion_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    taskId,
    title,
    description,
    scheduledDate,
    scheduledTime,
    targetDeadline,
    targetDeadlineUtcOffsetMinutes,
    category,
    quadrant,
    estimatedDurationMinutes,
    checklistJson,
    completedAt,
    completionChangedAt,
    completionXp,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
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
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    }
    if (data.containsKey('target_deadline')) {
      context.handle(
        _targetDeadlineMeta,
        targetDeadline.isAcceptableOrUnknown(
          data['target_deadline']!,
          _targetDeadlineMeta,
        ),
      );
    }
    if (data.containsKey('target_deadline_utc_offset_minutes')) {
      context.handle(
        _targetDeadlineUtcOffsetMinutesMeta,
        targetDeadlineUtcOffsetMinutes.isAcceptableOrUnknown(
          data['target_deadline_utc_offset_minutes']!,
          _targetDeadlineUtcOffsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('quadrant')) {
      context.handle(
        _quadrantMeta,
        quadrant.isAcceptableOrUnknown(data['quadrant']!, _quadrantMeta),
      );
    } else if (isInserting) {
      context.missing(_quadrantMeta);
    }
    if (data.containsKey('estimated_duration_minutes')) {
      context.handle(
        _estimatedDurationMinutesMeta,
        estimatedDurationMinutes.isAcceptableOrUnknown(
          data['estimated_duration_minutes']!,
          _estimatedDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('checklist_json')) {
      context.handle(
        _checklistJsonMeta,
        checklistJson.isAcceptableOrUnknown(
          data['checklist_json']!,
          _checklistJsonMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_changed_at')) {
      context.handle(
        _completionChangedAtMeta,
        completionChangedAt.isAcceptableOrUnknown(
          data['completion_changed_at']!,
          _completionChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_xp')) {
      context.handle(
        _completionXpMeta,
        completionXp.isAcceptableOrUnknown(
          data['completion_xp']!,
          _completionXpMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionXpMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, taskId};
  @override
  TaskRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRecord(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_time'],
      ),
      targetDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_deadline'],
      ),
      targetDeadlineUtcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_deadline_utc_offset_minutes'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      quadrant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quadrant'],
      )!,
      estimatedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_duration_minutes'],
      ),
      checklistJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_json'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completionChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completion_changed_at'],
      ),
      completionXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_xp'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TaskRecordsTable createAlias(String alias) {
    return $TaskRecordsTable(attachedDatabase, alias);
  }
}

class TaskRecord extends DataClass implements Insertable<TaskRecord> {
  final String accountId;
  final String taskId;
  final String title;
  final String? description;
  final String scheduledDate;
  final String? scheduledTime;
  final DateTime? targetDeadline;
  final int? targetDeadlineUtcOffsetMinutes;
  final String category;
  final String quadrant;
  final int? estimatedDurationMinutes;
  final String checklistJson;
  final DateTime? completedAt;

  /// Tasks owns this transition revision; map status projections only read it.
  final DateTime? completionChangedAt;
  final int completionXp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const TaskRecord({
    required this.accountId,
    required this.taskId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.scheduledTime,
    this.targetDeadline,
    this.targetDeadlineUtcOffsetMinutes,
    required this.category,
    required this.quadrant,
    this.estimatedDurationMinutes,
    required this.checklistJson,
    this.completedAt,
    this.completionChangedAt,
    required this.completionXp,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['scheduled_date'] = Variable<String>(scheduledDate);
    if (!nullToAbsent || scheduledTime != null) {
      map['scheduled_time'] = Variable<String>(scheduledTime);
    }
    if (!nullToAbsent || targetDeadline != null) {
      map['target_deadline'] = Variable<DateTime>(targetDeadline);
    }
    if (!nullToAbsent || targetDeadlineUtcOffsetMinutes != null) {
      map['target_deadline_utc_offset_minutes'] = Variable<int>(
        targetDeadlineUtcOffsetMinutes,
      );
    }
    map['category'] = Variable<String>(category);
    map['quadrant'] = Variable<String>(quadrant);
    if (!nullToAbsent || estimatedDurationMinutes != null) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes,
      );
    }
    map['checklist_json'] = Variable<String>(checklistJson);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completionChangedAt != null) {
      map['completion_changed_at'] = Variable<DateTime>(completionChangedAt);
    }
    map['completion_xp'] = Variable<int>(completionXp);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TaskRecordsCompanion toCompanion(bool nullToAbsent) {
    return TaskRecordsCompanion(
      accountId: Value(accountId),
      taskId: Value(taskId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      scheduledDate: Value(scheduledDate),
      scheduledTime: scheduledTime == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledTime),
      targetDeadline: targetDeadline == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDeadline),
      targetDeadlineUtcOffsetMinutes:
          targetDeadlineUtcOffsetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDeadlineUtcOffsetMinutes),
      category: Value(category),
      quadrant: Value(quadrant),
      estimatedDurationMinutes: estimatedDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDurationMinutes),
      checklistJson: Value(checklistJson),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completionChangedAt: completionChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completionChangedAt),
      completionXp: Value(completionXp),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRecord(
      accountId: serializer.fromJson<String>(json['accountId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      scheduledDate: serializer.fromJson<String>(json['scheduledDate']),
      scheduledTime: serializer.fromJson<String?>(json['scheduledTime']),
      targetDeadline: serializer.fromJson<DateTime?>(json['targetDeadline']),
      targetDeadlineUtcOffsetMinutes: serializer.fromJson<int?>(
        json['targetDeadlineUtcOffsetMinutes'],
      ),
      category: serializer.fromJson<String>(json['category']),
      quadrant: serializer.fromJson<String>(json['quadrant']),
      estimatedDurationMinutes: serializer.fromJson<int?>(
        json['estimatedDurationMinutes'],
      ),
      checklistJson: serializer.fromJson<String>(json['checklistJson']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completionChangedAt: serializer.fromJson<DateTime?>(
        json['completionChangedAt'],
      ),
      completionXp: serializer.fromJson<int>(json['completionXp']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'scheduledDate': serializer.toJson<String>(scheduledDate),
      'scheduledTime': serializer.toJson<String?>(scheduledTime),
      'targetDeadline': serializer.toJson<DateTime?>(targetDeadline),
      'targetDeadlineUtcOffsetMinutes': serializer.toJson<int?>(
        targetDeadlineUtcOffsetMinutes,
      ),
      'category': serializer.toJson<String>(category),
      'quadrant': serializer.toJson<String>(quadrant),
      'estimatedDurationMinutes': serializer.toJson<int?>(
        estimatedDurationMinutes,
      ),
      'checklistJson': serializer.toJson<String>(checklistJson),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completionChangedAt': serializer.toJson<DateTime?>(completionChangedAt),
      'completionXp': serializer.toJson<int>(completionXp),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TaskRecord copyWith({
    String? accountId,
    String? taskId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? scheduledDate,
    Value<String?> scheduledTime = const Value.absent(),
    Value<DateTime?> targetDeadline = const Value.absent(),
    Value<int?> targetDeadlineUtcOffsetMinutes = const Value.absent(),
    String? category,
    String? quadrant,
    Value<int?> estimatedDurationMinutes = const Value.absent(),
    String? checklistJson,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> completionChangedAt = const Value.absent(),
    int? completionXp,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TaskRecord(
    accountId: accountId ?? this.accountId,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    scheduledTime: scheduledTime.present
        ? scheduledTime.value
        : this.scheduledTime,
    targetDeadline: targetDeadline.present
        ? targetDeadline.value
        : this.targetDeadline,
    targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes.present
        ? targetDeadlineUtcOffsetMinutes.value
        : this.targetDeadlineUtcOffsetMinutes,
    category: category ?? this.category,
    quadrant: quadrant ?? this.quadrant,
    estimatedDurationMinutes: estimatedDurationMinutes.present
        ? estimatedDurationMinutes.value
        : this.estimatedDurationMinutes,
    checklistJson: checklistJson ?? this.checklistJson,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completionChangedAt: completionChangedAt.present
        ? completionChangedAt.value
        : this.completionChangedAt,
    completionXp: completionXp ?? this.completionXp,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskRecord copyWithCompanion(TaskRecordsCompanion data) {
    return TaskRecord(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      targetDeadline: data.targetDeadline.present
          ? data.targetDeadline.value
          : this.targetDeadline,
      targetDeadlineUtcOffsetMinutes:
          data.targetDeadlineUtcOffsetMinutes.present
          ? data.targetDeadlineUtcOffsetMinutes.value
          : this.targetDeadlineUtcOffsetMinutes,
      category: data.category.present ? data.category.value : this.category,
      quadrant: data.quadrant.present ? data.quadrant.value : this.quadrant,
      estimatedDurationMinutes: data.estimatedDurationMinutes.present
          ? data.estimatedDurationMinutes.value
          : this.estimatedDurationMinutes,
      checklistJson: data.checklistJson.present
          ? data.checklistJson.value
          : this.checklistJson,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completionChangedAt: data.completionChangedAt.present
          ? data.completionChangedAt.value
          : this.completionChangedAt,
      completionXp: data.completionXp.present
          ? data.completionXp.value
          : this.completionXp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecord(')
          ..write('accountId: $accountId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('targetDeadline: $targetDeadline, ')
          ..write(
            'targetDeadlineUtcOffsetMinutes: $targetDeadlineUtcOffsetMinutes, ',
          )
          ..write('category: $category, ')
          ..write('quadrant: $quadrant, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionChangedAt: $completionChangedAt, ')
          ..write('completionXp: $completionXp, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    taskId,
    title,
    description,
    scheduledDate,
    scheduledTime,
    targetDeadline,
    targetDeadlineUtcOffsetMinutes,
    category,
    quadrant,
    estimatedDurationMinutes,
    checklistJson,
    completedAt,
    completionChangedAt,
    completionXp,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRecord &&
          other.accountId == this.accountId &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.description == this.description &&
          other.scheduledDate == this.scheduledDate &&
          other.scheduledTime == this.scheduledTime &&
          other.targetDeadline == this.targetDeadline &&
          other.targetDeadlineUtcOffsetMinutes ==
              this.targetDeadlineUtcOffsetMinutes &&
          other.category == this.category &&
          other.quadrant == this.quadrant &&
          other.estimatedDurationMinutes == this.estimatedDurationMinutes &&
          other.checklistJson == this.checklistJson &&
          other.completedAt == this.completedAt &&
          other.completionChangedAt == this.completionChangedAt &&
          other.completionXp == this.completionXp &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TaskRecordsCompanion extends UpdateCompanion<TaskRecord> {
  final Value<String> accountId;
  final Value<String> taskId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> scheduledDate;
  final Value<String?> scheduledTime;
  final Value<DateTime?> targetDeadline;
  final Value<int?> targetDeadlineUtcOffsetMinutes;
  final Value<String> category;
  final Value<String> quadrant;
  final Value<int?> estimatedDurationMinutes;
  final Value<String> checklistJson;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> completionChangedAt;
  final Value<int> completionXp;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TaskRecordsCompanion({
    this.accountId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.targetDeadline = const Value.absent(),
    this.targetDeadlineUtcOffsetMinutes = const Value.absent(),
    this.category = const Value.absent(),
    this.quadrant = const Value.absent(),
    this.estimatedDurationMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionChangedAt = const Value.absent(),
    this.completionXp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRecordsCompanion.insert({
    required String accountId,
    required String taskId,
    required String title,
    this.description = const Value.absent(),
    required String scheduledDate,
    this.scheduledTime = const Value.absent(),
    this.targetDeadline = const Value.absent(),
    this.targetDeadlineUtcOffsetMinutes = const Value.absent(),
    required String category,
    required String quadrant,
    this.estimatedDurationMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionChangedAt = const Value.absent(),
    required int completionXp,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       taskId = Value(taskId),
       title = Value(title),
       scheduledDate = Value(scheduledDate),
       category = Value(category),
       quadrant = Value(quadrant),
       completionXp = Value(completionXp),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskRecord> custom({
    Expression<String>? accountId,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? scheduledDate,
    Expression<String>? scheduledTime,
    Expression<DateTime>? targetDeadline,
    Expression<int>? targetDeadlineUtcOffsetMinutes,
    Expression<String>? category,
    Expression<String>? quadrant,
    Expression<int>? estimatedDurationMinutes,
    Expression<String>? checklistJson,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? completionChangedAt,
    Expression<int>? completionXp,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (targetDeadline != null) 'target_deadline': targetDeadline,
      if (targetDeadlineUtcOffsetMinutes != null)
        'target_deadline_utc_offset_minutes': targetDeadlineUtcOffsetMinutes,
      if (category != null) 'category': category,
      if (quadrant != null) 'quadrant': quadrant,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (checklistJson != null) 'checklist_json': checklistJson,
      if (completedAt != null) 'completed_at': completedAt,
      if (completionChangedAt != null)
        'completion_changed_at': completionChangedAt,
      if (completionXp != null) 'completion_xp': completionXp,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? taskId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? scheduledDate,
    Value<String?>? scheduledTime,
    Value<DateTime?>? targetDeadline,
    Value<int?>? targetDeadlineUtcOffsetMinutes,
    Value<String>? category,
    Value<String>? quadrant,
    Value<int?>? estimatedDurationMinutes,
    Value<String>? checklistJson,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? completionChangedAt,
    Value<int>? completionXp,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaskRecordsCompanion(
      accountId: accountId ?? this.accountId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      targetDeadline: targetDeadline ?? this.targetDeadline,
      targetDeadlineUtcOffsetMinutes:
          targetDeadlineUtcOffsetMinutes ?? this.targetDeadlineUtcOffsetMinutes,
      category: category ?? this.category,
      quadrant: quadrant ?? this.quadrant,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      checklistJson: checklistJson ?? this.checklistJson,
      completedAt: completedAt ?? this.completedAt,
      completionChangedAt: completionChangedAt ?? this.completionChangedAt,
      completionXp: completionXp ?? this.completionXp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (targetDeadline.present) {
      map['target_deadline'] = Variable<DateTime>(targetDeadline.value);
    }
    if (targetDeadlineUtcOffsetMinutes.present) {
      map['target_deadline_utc_offset_minutes'] = Variable<int>(
        targetDeadlineUtcOffsetMinutes.value,
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quadrant.present) {
      map['quadrant'] = Variable<String>(quadrant.value);
    }
    if (estimatedDurationMinutes.present) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes.value,
      );
    }
    if (checklistJson.present) {
      map['checklist_json'] = Variable<String>(checklistJson.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completionChangedAt.present) {
      map['completion_changed_at'] = Variable<DateTime>(
        completionChangedAt.value,
      );
    }
    if (completionXp.present) {
      map['completion_xp'] = Variable<int>(completionXp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('targetDeadline: $targetDeadline, ')
          ..write(
            'targetDeadlineUtcOffsetMinutes: $targetDeadlineUtcOffsetMinutes, ',
          )
          ..write('category: $category, ')
          ..write('quadrant: $quadrant, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionChangedAt: $completionChangedAt, ')
          ..write('completionXp: $completionXp, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $XpAwardsTable extends XpAwards with TableInfo<$XpAwardsTable, XpAward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XpAwardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awardedAtMeta = const VerificationMeta(
    'awardedAt',
  );
  @override
  late final GeneratedColumn<DateTime> awardedAt = GeneratedColumn<DateTime>(
    'awarded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    source,
    sourceId,
    amount,
    awardedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xp_awards';
  @override
  VerificationContext validateIntegrity(
    Insertable<XpAward> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('awarded_at')) {
      context.handle(
        _awardedAtMeta,
        awardedAt.isAcceptableOrUnknown(data['awarded_at']!, _awardedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_awardedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, source, sourceId};
  @override
  XpAward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XpAward(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      awardedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}awarded_at'],
      )!,
    );
  }

  @override
  $XpAwardsTable createAlias(String alias) {
    return $XpAwardsTable(attachedDatabase, alias);
  }
}

class XpAward extends DataClass implements Insertable<XpAward> {
  final String accountId;
  final String source;
  final String sourceId;
  final int amount;
  final DateTime awardedAt;
  const XpAward({
    required this.accountId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.awardedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['amount'] = Variable<int>(amount);
    map['awarded_at'] = Variable<DateTime>(awardedAt);
    return map;
  }

  XpAwardsCompanion toCompanion(bool nullToAbsent) {
    return XpAwardsCompanion(
      accountId: Value(accountId),
      source: Value(source),
      sourceId: Value(sourceId),
      amount: Value(amount),
      awardedAt: Value(awardedAt),
    );
  }

  factory XpAward.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XpAward(
      accountId: serializer.fromJson<String>(json['accountId']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      amount: serializer.fromJson<int>(json['amount']),
      awardedAt: serializer.fromJson<DateTime>(json['awardedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'amount': serializer.toJson<int>(amount),
      'awardedAt': serializer.toJson<DateTime>(awardedAt),
    };
  }

  XpAward copyWith({
    String? accountId,
    String? source,
    String? sourceId,
    int? amount,
    DateTime? awardedAt,
  }) => XpAward(
    accountId: accountId ?? this.accountId,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    amount: amount ?? this.amount,
    awardedAt: awardedAt ?? this.awardedAt,
  );
  XpAward copyWithCompanion(XpAwardsCompanion data) {
    return XpAward(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      amount: data.amount.present ? data.amount.value : this.amount,
      awardedAt: data.awardedAt.present ? data.awardedAt.value : this.awardedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XpAward(')
          ..write('accountId: $accountId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('amount: $amount, ')
          ..write('awardedAt: $awardedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, source, sourceId, amount, awardedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XpAward &&
          other.accountId == this.accountId &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.amount == this.amount &&
          other.awardedAt == this.awardedAt);
}

class XpAwardsCompanion extends UpdateCompanion<XpAward> {
  final Value<String> accountId;
  final Value<String> source;
  final Value<String> sourceId;
  final Value<int> amount;
  final Value<DateTime> awardedAt;
  final Value<int> rowid;
  const XpAwardsCompanion({
    this.accountId = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.amount = const Value.absent(),
    this.awardedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  XpAwardsCompanion.insert({
    required String accountId,
    required String source,
    required String sourceId,
    required int amount,
    required DateTime awardedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       source = Value(source),
       sourceId = Value(sourceId),
       amount = Value(amount),
       awardedAt = Value(awardedAt);
  static Insertable<XpAward> custom({
    Expression<String>? accountId,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<int>? amount,
    Expression<DateTime>? awardedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (amount != null) 'amount': amount,
      if (awardedAt != null) 'awarded_at': awardedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  XpAwardsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? source,
    Value<String>? sourceId,
    Value<int>? amount,
    Value<DateTime>? awardedAt,
    Value<int>? rowid,
  }) {
    return XpAwardsCompanion(
      accountId: accountId ?? this.accountId,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      amount: amount ?? this.amount,
      awardedAt: awardedAt ?? this.awardedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (awardedAt.present) {
      map['awarded_at'] = Variable<DateTime>(awardedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XpAwardsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('amount: $amount, ')
          ..write('awardedAt: $awardedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitRecordsTable extends HabitRecords
    with TableInfo<$HabitRecordsTable, HabitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
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
  static const VerificationMeta _scheduleRevisionsJsonMeta =
      const VerificationMeta('scheduleRevisionsJson');
  @override
  late final GeneratedColumn<String> scheduleRevisionsJson =
      GeneratedColumn<String>(
        'schedule_revisions_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reminderMinuteOfDayMeta =
      const VerificationMeta('reminderMinuteOfDay');
  @override
  late final GeneratedColumn<int> reminderMinuteOfDay = GeneratedColumn<int>(
    'reminder_minute_of_day',
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    habitId,
    name,
    scheduleRevisionsJson,
    reminderMinuteOfDay,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('schedule_revisions_json')) {
      context.handle(
        _scheduleRevisionsJsonMeta,
        scheduleRevisionsJson.isAcceptableOrUnknown(
          data['schedule_revisions_json']!,
          _scheduleRevisionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleRevisionsJsonMeta);
    }
    if (data.containsKey('reminder_minute_of_day')) {
      context.handle(
        _reminderMinuteOfDayMeta,
        reminderMinuteOfDay.isAcceptableOrUnknown(
          data['reminder_minute_of_day']!,
          _reminderMinuteOfDayMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, habitId};
  @override
  HabitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRecord(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scheduleRevisionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_revisions_json'],
      )!,
      reminderMinuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute_of_day'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $HabitRecordsTable createAlias(String alias) {
    return $HabitRecordsTable(attachedDatabase, alias);
  }
}

class HabitRecord extends DataClass implements Insertable<HabitRecord> {
  final String accountId;
  final String habitId;
  final String name;
  final String scheduleRevisionsJson;
  final int? reminderMinuteOfDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const HabitRecord({
    required this.accountId,
    required this.habitId,
    required this.name,
    required this.scheduleRevisionsJson,
    this.reminderMinuteOfDay,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['habit_id'] = Variable<String>(habitId);
    map['name'] = Variable<String>(name);
    map['schedule_revisions_json'] = Variable<String>(scheduleRevisionsJson);
    if (!nullToAbsent || reminderMinuteOfDay != null) {
      map['reminder_minute_of_day'] = Variable<int>(reminderMinuteOfDay);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  HabitRecordsCompanion toCompanion(bool nullToAbsent) {
    return HabitRecordsCompanion(
      accountId: Value(accountId),
      habitId: Value(habitId),
      name: Value(name),
      scheduleRevisionsJson: Value(scheduleRevisionsJson),
      reminderMinuteOfDay: reminderMinuteOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinuteOfDay),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory HabitRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRecord(
      accountId: serializer.fromJson<String>(json['accountId']),
      habitId: serializer.fromJson<String>(json['habitId']),
      name: serializer.fromJson<String>(json['name']),
      scheduleRevisionsJson: serializer.fromJson<String>(
        json['scheduleRevisionsJson'],
      ),
      reminderMinuteOfDay: serializer.fromJson<int?>(
        json['reminderMinuteOfDay'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'habitId': serializer.toJson<String>(habitId),
      'name': serializer.toJson<String>(name),
      'scheduleRevisionsJson': serializer.toJson<String>(scheduleRevisionsJson),
      'reminderMinuteOfDay': serializer.toJson<int?>(reminderMinuteOfDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  HabitRecord copyWith({
    String? accountId,
    String? habitId,
    String? name,
    String? scheduleRevisionsJson,
    Value<int?> reminderMinuteOfDay = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => HabitRecord(
    accountId: accountId ?? this.accountId,
    habitId: habitId ?? this.habitId,
    name: name ?? this.name,
    scheduleRevisionsJson: scheduleRevisionsJson ?? this.scheduleRevisionsJson,
    reminderMinuteOfDay: reminderMinuteOfDay.present
        ? reminderMinuteOfDay.value
        : this.reminderMinuteOfDay,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  HabitRecord copyWithCompanion(HabitRecordsCompanion data) {
    return HabitRecord(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      name: data.name.present ? data.name.value : this.name,
      scheduleRevisionsJson: data.scheduleRevisionsJson.present
          ? data.scheduleRevisionsJson.value
          : this.scheduleRevisionsJson,
      reminderMinuteOfDay: data.reminderMinuteOfDay.present
          ? data.reminderMinuteOfDay.value
          : this.reminderMinuteOfDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRecord(')
          ..write('accountId: $accountId, ')
          ..write('habitId: $habitId, ')
          ..write('name: $name, ')
          ..write('scheduleRevisionsJson: $scheduleRevisionsJson, ')
          ..write('reminderMinuteOfDay: $reminderMinuteOfDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    habitId,
    name,
    scheduleRevisionsJson,
    reminderMinuteOfDay,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRecord &&
          other.accountId == this.accountId &&
          other.habitId == this.habitId &&
          other.name == this.name &&
          other.scheduleRevisionsJson == this.scheduleRevisionsJson &&
          other.reminderMinuteOfDay == this.reminderMinuteOfDay &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class HabitRecordsCompanion extends UpdateCompanion<HabitRecord> {
  final Value<String> accountId;
  final Value<String> habitId;
  final Value<String> name;
  final Value<String> scheduleRevisionsJson;
  final Value<int?> reminderMinuteOfDay;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const HabitRecordsCompanion({
    this.accountId = const Value.absent(),
    this.habitId = const Value.absent(),
    this.name = const Value.absent(),
    this.scheduleRevisionsJson = const Value.absent(),
    this.reminderMinuteOfDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitRecordsCompanion.insert({
    required String accountId,
    required String habitId,
    required String name,
    required String scheduleRevisionsJson,
    this.reminderMinuteOfDay = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       habitId = Value(habitId),
       name = Value(name),
       scheduleRevisionsJson = Value(scheduleRevisionsJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitRecord> custom({
    Expression<String>? accountId,
    Expression<String>? habitId,
    Expression<String>? name,
    Expression<String>? scheduleRevisionsJson,
    Expression<int>? reminderMinuteOfDay,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (habitId != null) 'habit_id': habitId,
      if (name != null) 'name': name,
      if (scheduleRevisionsJson != null)
        'schedule_revisions_json': scheduleRevisionsJson,
      if (reminderMinuteOfDay != null)
        'reminder_minute_of_day': reminderMinuteOfDay,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? habitId,
    Value<String>? name,
    Value<String>? scheduleRevisionsJson,
    Value<int?>? reminderMinuteOfDay,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return HabitRecordsCompanion(
      accountId: accountId ?? this.accountId,
      habitId: habitId ?? this.habitId,
      name: name ?? this.name,
      scheduleRevisionsJson:
          scheduleRevisionsJson ?? this.scheduleRevisionsJson,
      reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scheduleRevisionsJson.present) {
      map['schedule_revisions_json'] = Variable<String>(
        scheduleRevisionsJson.value,
      );
    }
    if (reminderMinuteOfDay.present) {
      map['reminder_minute_of_day'] = Variable<int>(reminderMinuteOfDay.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('habitId: $habitId, ')
          ..write('name: $name, ')
          ..write('scheduleRevisionsJson: $scheduleRevisionsJson, ')
          ..write('reminderMinuteOfDay: $reminderMinuteOfDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitDayRecordsTable extends HabitDayRecords
    with TableInfo<$HabitDayRecordsTable, HabitDayRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitDayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyCountMeta = const VerificationMeta(
    'dailyCount',
  );
  @override
  late final GeneratedColumn<int> dailyCount = GeneratedColumn<int>(
    'daily_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _earnedWhileDueMeta = const VerificationMeta(
    'earnedWhileDue',
  );
  @override
  late final GeneratedColumn<bool> earnedWhileDue = GeneratedColumn<bool>(
    'earned_while_due',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("earned_while_due" IN (0, 1))',
    ),
  );
  static const VerificationMeta _earnedAgainstRevisionIdMeta =
      const VerificationMeta('earnedAgainstRevisionId');
  @override
  late final GeneratedColumn<String> earnedAgainstRevisionId =
      GeneratedColumn<String>(
        'earned_against_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recordedUtcOffsetMinutesMeta =
      const VerificationMeta('recordedUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> recordedUtcOffsetMinutes =
      GeneratedColumn<int>(
        'recorded_utc_offset_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    habitId,
    localDate,
    completedAt,
    dailyCount,
    earnedWhileDue,
    earnedAgainstRevisionId,
    recordedUtcOffsetMinutes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_day_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitDayRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('daily_count')) {
      context.handle(
        _dailyCountMeta,
        dailyCount.isAcceptableOrUnknown(data['daily_count']!, _dailyCountMeta),
      );
    }
    if (data.containsKey('earned_while_due')) {
      context.handle(
        _earnedWhileDueMeta,
        earnedWhileDue.isAcceptableOrUnknown(
          data['earned_while_due']!,
          _earnedWhileDueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_earnedWhileDueMeta);
    }
    if (data.containsKey('earned_against_revision_id')) {
      context.handle(
        _earnedAgainstRevisionIdMeta,
        earnedAgainstRevisionId.isAcceptableOrUnknown(
          data['earned_against_revision_id']!,
          _earnedAgainstRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('recorded_utc_offset_minutes')) {
      context.handle(
        _recordedUtcOffsetMinutesMeta,
        recordedUtcOffsetMinutes.isAcceptableOrUnknown(
          data['recorded_utc_offset_minutes']!,
          _recordedUtcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedUtcOffsetMinutesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, habitId, localDate};
  @override
  HabitDayRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitDayRecord(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      dailyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_count'],
      )!,
      earnedWhileDue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}earned_while_due'],
      )!,
      earnedAgainstRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_against_revision_id'],
      ),
      recordedUtcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_utc_offset_minutes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitDayRecordsTable createAlias(String alias) {
    return $HabitDayRecordsTable(attachedDatabase, alias);
  }
}

class HabitDayRecord extends DataClass implements Insertable<HabitDayRecord> {
  final String accountId;
  final String habitId;
  final String localDate;
  final DateTime? completedAt;
  final int dailyCount;
  final bool earnedWhileDue;
  final String? earnedAgainstRevisionId;
  final int recordedUtcOffsetMinutes;
  final DateTime updatedAt;
  const HabitDayRecord({
    required this.accountId,
    required this.habitId,
    required this.localDate,
    this.completedAt,
    required this.dailyCount,
    required this.earnedWhileDue,
    this.earnedAgainstRevisionId,
    required this.recordedUtcOffsetMinutes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['habit_id'] = Variable<String>(habitId);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['daily_count'] = Variable<int>(dailyCount);
    map['earned_while_due'] = Variable<bool>(earnedWhileDue);
    if (!nullToAbsent || earnedAgainstRevisionId != null) {
      map['earned_against_revision_id'] = Variable<String>(
        earnedAgainstRevisionId,
      );
    }
    map['recorded_utc_offset_minutes'] = Variable<int>(
      recordedUtcOffsetMinutes,
    );
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitDayRecordsCompanion toCompanion(bool nullToAbsent) {
    return HabitDayRecordsCompanion(
      accountId: Value(accountId),
      habitId: Value(habitId),
      localDate: Value(localDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      dailyCount: Value(dailyCount),
      earnedWhileDue: Value(earnedWhileDue),
      earnedAgainstRevisionId: earnedAgainstRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(earnedAgainstRevisionId),
      recordedUtcOffsetMinutes: Value(recordedUtcOffsetMinutes),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitDayRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitDayRecord(
      accountId: serializer.fromJson<String>(json['accountId']),
      habitId: serializer.fromJson<String>(json['habitId']),
      localDate: serializer.fromJson<String>(json['localDate']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      dailyCount: serializer.fromJson<int>(json['dailyCount']),
      earnedWhileDue: serializer.fromJson<bool>(json['earnedWhileDue']),
      earnedAgainstRevisionId: serializer.fromJson<String?>(
        json['earnedAgainstRevisionId'],
      ),
      recordedUtcOffsetMinutes: serializer.fromJson<int>(
        json['recordedUtcOffsetMinutes'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'habitId': serializer.toJson<String>(habitId),
      'localDate': serializer.toJson<String>(localDate),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'dailyCount': serializer.toJson<int>(dailyCount),
      'earnedWhileDue': serializer.toJson<bool>(earnedWhileDue),
      'earnedAgainstRevisionId': serializer.toJson<String?>(
        earnedAgainstRevisionId,
      ),
      'recordedUtcOffsetMinutes': serializer.toJson<int>(
        recordedUtcOffsetMinutes,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitDayRecord copyWith({
    String? accountId,
    String? habitId,
    String? localDate,
    Value<DateTime?> completedAt = const Value.absent(),
    int? dailyCount,
    bool? earnedWhileDue,
    Value<String?> earnedAgainstRevisionId = const Value.absent(),
    int? recordedUtcOffsetMinutes,
    DateTime? updatedAt,
  }) => HabitDayRecord(
    accountId: accountId ?? this.accountId,
    habitId: habitId ?? this.habitId,
    localDate: localDate ?? this.localDate,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    dailyCount: dailyCount ?? this.dailyCount,
    earnedWhileDue: earnedWhileDue ?? this.earnedWhileDue,
    earnedAgainstRevisionId: earnedAgainstRevisionId.present
        ? earnedAgainstRevisionId.value
        : this.earnedAgainstRevisionId,
    recordedUtcOffsetMinutes:
        recordedUtcOffsetMinutes ?? this.recordedUtcOffsetMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitDayRecord copyWithCompanion(HabitDayRecordsCompanion data) {
    return HabitDayRecord(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      dailyCount: data.dailyCount.present
          ? data.dailyCount.value
          : this.dailyCount,
      earnedWhileDue: data.earnedWhileDue.present
          ? data.earnedWhileDue.value
          : this.earnedWhileDue,
      earnedAgainstRevisionId: data.earnedAgainstRevisionId.present
          ? data.earnedAgainstRevisionId.value
          : this.earnedAgainstRevisionId,
      recordedUtcOffsetMinutes: data.recordedUtcOffsetMinutes.present
          ? data.recordedUtcOffsetMinutes.value
          : this.recordedUtcOffsetMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitDayRecord(')
          ..write('accountId: $accountId, ')
          ..write('habitId: $habitId, ')
          ..write('localDate: $localDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('earnedWhileDue: $earnedWhileDue, ')
          ..write('earnedAgainstRevisionId: $earnedAgainstRevisionId, ')
          ..write('recordedUtcOffsetMinutes: $recordedUtcOffsetMinutes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    habitId,
    localDate,
    completedAt,
    dailyCount,
    earnedWhileDue,
    earnedAgainstRevisionId,
    recordedUtcOffsetMinutes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitDayRecord &&
          other.accountId == this.accountId &&
          other.habitId == this.habitId &&
          other.localDate == this.localDate &&
          other.completedAt == this.completedAt &&
          other.dailyCount == this.dailyCount &&
          other.earnedWhileDue == this.earnedWhileDue &&
          other.earnedAgainstRevisionId == this.earnedAgainstRevisionId &&
          other.recordedUtcOffsetMinutes == this.recordedUtcOffsetMinutes &&
          other.updatedAt == this.updatedAt);
}

class HabitDayRecordsCompanion extends UpdateCompanion<HabitDayRecord> {
  final Value<String> accountId;
  final Value<String> habitId;
  final Value<String> localDate;
  final Value<DateTime?> completedAt;
  final Value<int> dailyCount;
  final Value<bool> earnedWhileDue;
  final Value<String?> earnedAgainstRevisionId;
  final Value<int> recordedUtcOffsetMinutes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitDayRecordsCompanion({
    this.accountId = const Value.absent(),
    this.habitId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.dailyCount = const Value.absent(),
    this.earnedWhileDue = const Value.absent(),
    this.earnedAgainstRevisionId = const Value.absent(),
    this.recordedUtcOffsetMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitDayRecordsCompanion.insert({
    required String accountId,
    required String habitId,
    required String localDate,
    this.completedAt = const Value.absent(),
    this.dailyCount = const Value.absent(),
    required bool earnedWhileDue,
    this.earnedAgainstRevisionId = const Value.absent(),
    required int recordedUtcOffsetMinutes,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       habitId = Value(habitId),
       localDate = Value(localDate),
       earnedWhileDue = Value(earnedWhileDue),
       recordedUtcOffsetMinutes = Value(recordedUtcOffsetMinutes),
       updatedAt = Value(updatedAt);
  static Insertable<HabitDayRecord> custom({
    Expression<String>? accountId,
    Expression<String>? habitId,
    Expression<String>? localDate,
    Expression<DateTime>? completedAt,
    Expression<int>? dailyCount,
    Expression<bool>? earnedWhileDue,
    Expression<String>? earnedAgainstRevisionId,
    Expression<int>? recordedUtcOffsetMinutes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (habitId != null) 'habit_id': habitId,
      if (localDate != null) 'local_date': localDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (dailyCount != null) 'daily_count': dailyCount,
      if (earnedWhileDue != null) 'earned_while_due': earnedWhileDue,
      if (earnedAgainstRevisionId != null)
        'earned_against_revision_id': earnedAgainstRevisionId,
      if (recordedUtcOffsetMinutes != null)
        'recorded_utc_offset_minutes': recordedUtcOffsetMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitDayRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? habitId,
    Value<String>? localDate,
    Value<DateTime?>? completedAt,
    Value<int>? dailyCount,
    Value<bool>? earnedWhileDue,
    Value<String?>? earnedAgainstRevisionId,
    Value<int>? recordedUtcOffsetMinutes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitDayRecordsCompanion(
      accountId: accountId ?? this.accountId,
      habitId: habitId ?? this.habitId,
      localDate: localDate ?? this.localDate,
      completedAt: completedAt ?? this.completedAt,
      dailyCount: dailyCount ?? this.dailyCount,
      earnedWhileDue: earnedWhileDue ?? this.earnedWhileDue,
      earnedAgainstRevisionId:
          earnedAgainstRevisionId ?? this.earnedAgainstRevisionId,
      recordedUtcOffsetMinutes:
          recordedUtcOffsetMinutes ?? this.recordedUtcOffsetMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (dailyCount.present) {
      map['daily_count'] = Variable<int>(dailyCount.value);
    }
    if (earnedWhileDue.present) {
      map['earned_while_due'] = Variable<bool>(earnedWhileDue.value);
    }
    if (earnedAgainstRevisionId.present) {
      map['earned_against_revision_id'] = Variable<String>(
        earnedAgainstRevisionId.value,
      );
    }
    if (recordedUtcOffsetMinutes.present) {
      map['recorded_utc_offset_minutes'] = Variable<int>(
        recordedUtcOffsetMinutes.value,
      );
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
    return (StringBuffer('HabitDayRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('habitId: $habitId, ')
          ..write('localDate: $localDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('dailyCount: $dailyCount, ')
          ..write('earnedWhileDue: $earnedWhileDue, ')
          ..write('earnedAgainstRevisionId: $earnedAgainstRevisionId, ')
          ..write('recordedUtcOffsetMinutes: $recordedUtcOffsetMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MindMapRecordsTable extends MindMapRecords
    with TableInfo<$MindMapRecordsTable, MindMapRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MindMapRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
  @override
  late final GeneratedColumn<String> mapId = GeneratedColumn<String>(
    'map_id',
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
  static const VerificationMeta _centralNodeIdMeta = const VerificationMeta(
    'centralNodeId',
  );
  @override
  late final GeneratedColumn<String> centralNodeId = GeneratedColumn<String>(
    'central_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    mapId,
    title,
    description,
    centralNodeId,
    settingsJson,
    revisionId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mind_map_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MindMapRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('map_id')) {
      context.handle(
        _mapIdMeta,
        mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mapIdMeta);
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
    if (data.containsKey('central_node_id')) {
      context.handle(
        _centralNodeIdMeta,
        centralNodeId.isAcceptableOrUnknown(
          data['central_node_id']!,
          _centralNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centralNodeIdMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingsJsonMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, mapId};
  @override
  MindMapRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MindMapRecord(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      centralNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}central_node_id'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MindMapRecordsTable createAlias(String alias) {
    return $MindMapRecordsTable(attachedDatabase, alias);
  }
}

class MindMapRecord extends DataClass implements Insertable<MindMapRecord> {
  final String accountId;
  final String mapId;
  final String title;
  final String? description;
  final String centralNodeId;
  final String settingsJson;
  final String revisionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MindMapRecord({
    required this.accountId,
    required this.mapId,
    required this.title,
    this.description,
    required this.centralNodeId,
    required this.settingsJson,
    required this.revisionId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['map_id'] = Variable<String>(mapId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['central_node_id'] = Variable<String>(centralNodeId);
    map['settings_json'] = Variable<String>(settingsJson);
    map['revision_id'] = Variable<String>(revisionId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MindMapRecordsCompanion toCompanion(bool nullToAbsent) {
    return MindMapRecordsCompanion(
      accountId: Value(accountId),
      mapId: Value(mapId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      centralNodeId: Value(centralNodeId),
      settingsJson: Value(settingsJson),
      revisionId: Value(revisionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MindMapRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MindMapRecord(
      accountId: serializer.fromJson<String>(json['accountId']),
      mapId: serializer.fromJson<String>(json['mapId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      centralNodeId: serializer.fromJson<String>(json['centralNodeId']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'mapId': serializer.toJson<String>(mapId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'centralNodeId': serializer.toJson<String>(centralNodeId),
      'settingsJson': serializer.toJson<String>(settingsJson),
      'revisionId': serializer.toJson<String>(revisionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MindMapRecord copyWith({
    String? accountId,
    String? mapId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? centralNodeId,
    String? settingsJson,
    String? revisionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MindMapRecord(
    accountId: accountId ?? this.accountId,
    mapId: mapId ?? this.mapId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    centralNodeId: centralNodeId ?? this.centralNodeId,
    settingsJson: settingsJson ?? this.settingsJson,
    revisionId: revisionId ?? this.revisionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MindMapRecord copyWithCompanion(MindMapRecordsCompanion data) {
    return MindMapRecord(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mapId: data.mapId.present ? data.mapId.value : this.mapId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      centralNodeId: data.centralNodeId.present
          ? data.centralNodeId.value
          : this.centralNodeId,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MindMapRecord(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('centralNodeId: $centralNodeId, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    mapId,
    title,
    description,
    centralNodeId,
    settingsJson,
    revisionId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MindMapRecord &&
          other.accountId == this.accountId &&
          other.mapId == this.mapId &&
          other.title == this.title &&
          other.description == this.description &&
          other.centralNodeId == this.centralNodeId &&
          other.settingsJson == this.settingsJson &&
          other.revisionId == this.revisionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MindMapRecordsCompanion extends UpdateCompanion<MindMapRecord> {
  final Value<String> accountId;
  final Value<String> mapId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> centralNodeId;
  final Value<String> settingsJson;
  final Value<String> revisionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MindMapRecordsCompanion({
    this.accountId = const Value.absent(),
    this.mapId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.centralNodeId = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MindMapRecordsCompanion.insert({
    required String accountId,
    required String mapId,
    required String title,
    this.description = const Value.absent(),
    required String centralNodeId,
    required String settingsJson,
    required String revisionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       mapId = Value(mapId),
       title = Value(title),
       centralNodeId = Value(centralNodeId),
       settingsJson = Value(settingsJson),
       revisionId = Value(revisionId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MindMapRecord> custom({
    Expression<String>? accountId,
    Expression<String>? mapId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? centralNodeId,
    Expression<String>? settingsJson,
    Expression<String>? revisionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (mapId != null) 'map_id': mapId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (centralNodeId != null) 'central_node_id': centralNodeId,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (revisionId != null) 'revision_id': revisionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MindMapRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? mapId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? centralNodeId,
    Value<String>? settingsJson,
    Value<String>? revisionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MindMapRecordsCompanion(
      accountId: accountId ?? this.accountId,
      mapId: mapId ?? this.mapId,
      title: title ?? this.title,
      description: description ?? this.description,
      centralNodeId: centralNodeId ?? this.centralNodeId,
      settingsJson: settingsJson ?? this.settingsJson,
      revisionId: revisionId ?? this.revisionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mapId.present) {
      map['map_id'] = Variable<String>(mapId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (centralNodeId.present) {
      map['central_node_id'] = Variable<String>(centralNodeId.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MindMapRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('centralNodeId: $centralNodeId, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MindMapNodeRecordsTable extends MindMapNodeRecords
    with TableInfo<$MindMapNodeRecordsTable, MindMapNodeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MindMapNodeRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
  @override
  late final GeneratedColumn<String> mapId = GeneratedColumn<String>(
    'map_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
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
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
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
  static const VerificationMeta _statusChangedAtMeta = const VerificationMeta(
    'statusChangedAt',
  );
  @override
  late final GeneratedColumn<DateTime> statusChangedAt =
      GeneratedColumn<DateTime>(
        'status_changed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearanceJsonMeta = const VerificationMeta(
    'appearanceJson',
  );
  @override
  late final GeneratedColumn<String> appearanceJson = GeneratedColumn<String>(
    'appearance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    mapId,
    nodeId,
    kind,
    title,
    description,
    x,
    y,
    status,
    statusChangedAt,
    priority,
    appearanceJson,
    taskId,
    revisionId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mind_map_node_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MindMapNodeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('map_id')) {
      context.handle(
        _mapIdMeta,
        mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mapIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('status_changed_at')) {
      context.handle(
        _statusChangedAtMeta,
        statusChangedAt.isAcceptableOrUnknown(
          data['status_changed_at']!,
          _statusChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('appearance_json')) {
      context.handle(
        _appearanceJsonMeta,
        appearanceJson.isAcceptableOrUnknown(
          data['appearance_json']!,
          _appearanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appearanceJsonMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, mapId, nodeId};
  @override
  MindMapNodeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MindMapNodeRecord(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statusChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}status_changed_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      appearanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_json'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MindMapNodeRecordsTable createAlias(String alias) {
    return $MindMapNodeRecordsTable(attachedDatabase, alias);
  }
}

class MindMapNodeRecord extends DataClass
    implements Insertable<MindMapNodeRecord> {
  final String accountId;
  final String mapId;
  final String nodeId;
  final String kind;
  final String title;
  final String? description;
  final double x;
  final double y;
  final String status;
  final DateTime? statusChangedAt;
  final String priority;
  final String appearanceJson;
  final String? taskId;
  final String revisionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MindMapNodeRecord({
    required this.accountId,
    required this.mapId,
    required this.nodeId,
    required this.kind,
    required this.title,
    this.description,
    required this.x,
    required this.y,
    required this.status,
    this.statusChangedAt,
    required this.priority,
    required this.appearanceJson,
    this.taskId,
    required this.revisionId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['map_id'] = Variable<String>(mapId);
    map['node_id'] = Variable<String>(nodeId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || statusChangedAt != null) {
      map['status_changed_at'] = Variable<DateTime>(statusChangedAt);
    }
    map['priority'] = Variable<String>(priority);
    map['appearance_json'] = Variable<String>(appearanceJson);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['revision_id'] = Variable<String>(revisionId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MindMapNodeRecordsCompanion toCompanion(bool nullToAbsent) {
    return MindMapNodeRecordsCompanion(
      accountId: Value(accountId),
      mapId: Value(mapId),
      nodeId: Value(nodeId),
      kind: Value(kind),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      x: Value(x),
      y: Value(y),
      status: Value(status),
      statusChangedAt: statusChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(statusChangedAt),
      priority: Value(priority),
      appearanceJson: Value(appearanceJson),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      revisionId: Value(revisionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MindMapNodeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MindMapNodeRecord(
      accountId: serializer.fromJson<String>(json['accountId']),
      mapId: serializer.fromJson<String>(json['mapId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      status: serializer.fromJson<String>(json['status']),
      statusChangedAt: serializer.fromJson<DateTime?>(json['statusChangedAt']),
      priority: serializer.fromJson<String>(json['priority']),
      appearanceJson: serializer.fromJson<String>(json['appearanceJson']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'mapId': serializer.toJson<String>(mapId),
      'nodeId': serializer.toJson<String>(nodeId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'status': serializer.toJson<String>(status),
      'statusChangedAt': serializer.toJson<DateTime?>(statusChangedAt),
      'priority': serializer.toJson<String>(priority),
      'appearanceJson': serializer.toJson<String>(appearanceJson),
      'taskId': serializer.toJson<String?>(taskId),
      'revisionId': serializer.toJson<String>(revisionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MindMapNodeRecord copyWith({
    String? accountId,
    String? mapId,
    String? nodeId,
    String? kind,
    String? title,
    Value<String?> description = const Value.absent(),
    double? x,
    double? y,
    String? status,
    Value<DateTime?> statusChangedAt = const Value.absent(),
    String? priority,
    String? appearanceJson,
    Value<String?> taskId = const Value.absent(),
    String? revisionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MindMapNodeRecord(
    accountId: accountId ?? this.accountId,
    mapId: mapId ?? this.mapId,
    nodeId: nodeId ?? this.nodeId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    x: x ?? this.x,
    y: y ?? this.y,
    status: status ?? this.status,
    statusChangedAt: statusChangedAt.present
        ? statusChangedAt.value
        : this.statusChangedAt,
    priority: priority ?? this.priority,
    appearanceJson: appearanceJson ?? this.appearanceJson,
    taskId: taskId.present ? taskId.value : this.taskId,
    revisionId: revisionId ?? this.revisionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MindMapNodeRecord copyWithCompanion(MindMapNodeRecordsCompanion data) {
    return MindMapNodeRecord(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mapId: data.mapId.present ? data.mapId.value : this.mapId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      status: data.status.present ? data.status.value : this.status,
      statusChangedAt: data.statusChangedAt.present
          ? data.statusChangedAt.value
          : this.statusChangedAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      appearanceJson: data.appearanceJson.present
          ? data.appearanceJson.value
          : this.appearanceJson,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MindMapNodeRecord(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('nodeId: $nodeId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('statusChangedAt: $statusChangedAt, ')
          ..write('priority: $priority, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('taskId: $taskId, ')
          ..write('revisionId: $revisionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    mapId,
    nodeId,
    kind,
    title,
    description,
    x,
    y,
    status,
    statusChangedAt,
    priority,
    appearanceJson,
    taskId,
    revisionId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MindMapNodeRecord &&
          other.accountId == this.accountId &&
          other.mapId == this.mapId &&
          other.nodeId == this.nodeId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.description == this.description &&
          other.x == this.x &&
          other.y == this.y &&
          other.status == this.status &&
          other.statusChangedAt == this.statusChangedAt &&
          other.priority == this.priority &&
          other.appearanceJson == this.appearanceJson &&
          other.taskId == this.taskId &&
          other.revisionId == this.revisionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MindMapNodeRecordsCompanion extends UpdateCompanion<MindMapNodeRecord> {
  final Value<String> accountId;
  final Value<String> mapId;
  final Value<String> nodeId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> description;
  final Value<double> x;
  final Value<double> y;
  final Value<String> status;
  final Value<DateTime?> statusChangedAt;
  final Value<String> priority;
  final Value<String> appearanceJson;
  final Value<String?> taskId;
  final Value<String> revisionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MindMapNodeRecordsCompanion({
    this.accountId = const Value.absent(),
    this.mapId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.status = const Value.absent(),
    this.statusChangedAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.appearanceJson = const Value.absent(),
    this.taskId = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MindMapNodeRecordsCompanion.insert({
    required String accountId,
    required String mapId,
    required String nodeId,
    required String kind,
    required String title,
    this.description = const Value.absent(),
    required double x,
    required double y,
    required String status,
    this.statusChangedAt = const Value.absent(),
    required String priority,
    required String appearanceJson,
    this.taskId = const Value.absent(),
    required String revisionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       mapId = Value(mapId),
       nodeId = Value(nodeId),
       kind = Value(kind),
       title = Value(title),
       x = Value(x),
       y = Value(y),
       status = Value(status),
       priority = Value(priority),
       appearanceJson = Value(appearanceJson),
       revisionId = Value(revisionId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MindMapNodeRecord> custom({
    Expression<String>? accountId,
    Expression<String>? mapId,
    Expression<String>? nodeId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? x,
    Expression<double>? y,
    Expression<String>? status,
    Expression<DateTime>? statusChangedAt,
    Expression<String>? priority,
    Expression<String>? appearanceJson,
    Expression<String>? taskId,
    Expression<String>? revisionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (mapId != null) 'map_id': mapId,
      if (nodeId != null) 'node_id': nodeId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (status != null) 'status': status,
      if (statusChangedAt != null) 'status_changed_at': statusChangedAt,
      if (priority != null) 'priority': priority,
      if (appearanceJson != null) 'appearance_json': appearanceJson,
      if (taskId != null) 'task_id': taskId,
      if (revisionId != null) 'revision_id': revisionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MindMapNodeRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? mapId,
    Value<String>? nodeId,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? description,
    Value<double>? x,
    Value<double>? y,
    Value<String>? status,
    Value<DateTime?>? statusChangedAt,
    Value<String>? priority,
    Value<String>? appearanceJson,
    Value<String?>? taskId,
    Value<String>? revisionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MindMapNodeRecordsCompanion(
      accountId: accountId ?? this.accountId,
      mapId: mapId ?? this.mapId,
      nodeId: nodeId ?? this.nodeId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      description: description ?? this.description,
      x: x ?? this.x,
      y: y ?? this.y,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      priority: priority ?? this.priority,
      appearanceJson: appearanceJson ?? this.appearanceJson,
      taskId: taskId ?? this.taskId,
      revisionId: revisionId ?? this.revisionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mapId.present) {
      map['map_id'] = Variable<String>(mapId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statusChangedAt.present) {
      map['status_changed_at'] = Variable<DateTime>(statusChangedAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (appearanceJson.present) {
      map['appearance_json'] = Variable<String>(appearanceJson.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MindMapNodeRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('nodeId: $nodeId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('statusChangedAt: $statusChangedAt, ')
          ..write('priority: $priority, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('taskId: $taskId, ')
          ..write('revisionId: $revisionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MindMapParentSlotsTable extends MindMapParentSlots
    with TableInfo<$MindMapParentSlotsTable, MindMapParentSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MindMapParentSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
  @override
  late final GeneratedColumn<String> mapId = GeneratedColumn<String>(
    'map_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childNodeIdMeta = const VerificationMeta(
    'childNodeId',
  );
  @override
  late final GeneratedColumn<String> childNodeId = GeneratedColumn<String>(
    'child_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentNodeIdMeta = const VerificationMeta(
    'parentNodeId',
  );
  @override
  late final GeneratedColumn<String> parentNodeId = GeneratedColumn<String>(
    'parent_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearanceJsonMeta = const VerificationMeta(
    'appearanceJson',
  );
  @override
  late final GeneratedColumn<String> appearanceJson = GeneratedColumn<String>(
    'appearance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    mapId,
    childNodeId,
    parentNodeId,
    appearanceJson,
    revisionId,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mind_map_parent_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<MindMapParentSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('map_id')) {
      context.handle(
        _mapIdMeta,
        mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mapIdMeta);
    }
    if (data.containsKey('child_node_id')) {
      context.handle(
        _childNodeIdMeta,
        childNodeId.isAcceptableOrUnknown(
          data['child_node_id']!,
          _childNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childNodeIdMeta);
    }
    if (data.containsKey('parent_node_id')) {
      context.handle(
        _parentNodeIdMeta,
        parentNodeId.isAcceptableOrUnknown(
          data['parent_node_id']!,
          _parentNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parentNodeIdMeta);
    }
    if (data.containsKey('appearance_json')) {
      context.handle(
        _appearanceJsonMeta,
        appearanceJson.isAcceptableOrUnknown(
          data['appearance_json']!,
          _appearanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appearanceJsonMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, mapId, childNodeId};
  @override
  MindMapParentSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MindMapParentSlot(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_id'],
      )!,
      childNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_node_id'],
      )!,
      parentNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_node_id'],
      )!,
      appearanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_json'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MindMapParentSlotsTable createAlias(String alias) {
    return $MindMapParentSlotsTable(attachedDatabase, alias);
  }
}

class MindMapParentSlot extends DataClass
    implements Insertable<MindMapParentSlot> {
  final String accountId;
  final String mapId;
  final String childNodeId;
  final String parentNodeId;
  final String appearanceJson;
  final String revisionId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MindMapParentSlot({
    required this.accountId,
    required this.mapId,
    required this.childNodeId,
    required this.parentNodeId,
    required this.appearanceJson,
    required this.revisionId,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['map_id'] = Variable<String>(mapId);
    map['child_node_id'] = Variable<String>(childNodeId);
    map['parent_node_id'] = Variable<String>(parentNodeId);
    map['appearance_json'] = Variable<String>(appearanceJson);
    map['revision_id'] = Variable<String>(revisionId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MindMapParentSlotsCompanion toCompanion(bool nullToAbsent) {
    return MindMapParentSlotsCompanion(
      accountId: Value(accountId),
      mapId: Value(mapId),
      childNodeId: Value(childNodeId),
      parentNodeId: Value(parentNodeId),
      appearanceJson: Value(appearanceJson),
      revisionId: Value(revisionId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MindMapParentSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MindMapParentSlot(
      accountId: serializer.fromJson<String>(json['accountId']),
      mapId: serializer.fromJson<String>(json['mapId']),
      childNodeId: serializer.fromJson<String>(json['childNodeId']),
      parentNodeId: serializer.fromJson<String>(json['parentNodeId']),
      appearanceJson: serializer.fromJson<String>(json['appearanceJson']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'mapId': serializer.toJson<String>(mapId),
      'childNodeId': serializer.toJson<String>(childNodeId),
      'parentNodeId': serializer.toJson<String>(parentNodeId),
      'appearanceJson': serializer.toJson<String>(appearanceJson),
      'revisionId': serializer.toJson<String>(revisionId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MindMapParentSlot copyWith({
    String? accountId,
    String? mapId,
    String? childNodeId,
    String? parentNodeId,
    String? appearanceJson,
    String? revisionId,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MindMapParentSlot(
    accountId: accountId ?? this.accountId,
    mapId: mapId ?? this.mapId,
    childNodeId: childNodeId ?? this.childNodeId,
    parentNodeId: parentNodeId ?? this.parentNodeId,
    appearanceJson: appearanceJson ?? this.appearanceJson,
    revisionId: revisionId ?? this.revisionId,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MindMapParentSlot copyWithCompanion(MindMapParentSlotsCompanion data) {
    return MindMapParentSlot(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mapId: data.mapId.present ? data.mapId.value : this.mapId,
      childNodeId: data.childNodeId.present
          ? data.childNodeId.value
          : this.childNodeId,
      parentNodeId: data.parentNodeId.present
          ? data.parentNodeId.value
          : this.parentNodeId,
      appearanceJson: data.appearanceJson.present
          ? data.appearanceJson.value
          : this.appearanceJson,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MindMapParentSlot(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('childNodeId: $childNodeId, ')
          ..write('parentNodeId: $parentNodeId, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    mapId,
    childNodeId,
    parentNodeId,
    appearanceJson,
    revisionId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MindMapParentSlot &&
          other.accountId == this.accountId &&
          other.mapId == this.mapId &&
          other.childNodeId == this.childNodeId &&
          other.parentNodeId == this.parentNodeId &&
          other.appearanceJson == this.appearanceJson &&
          other.revisionId == this.revisionId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MindMapParentSlotsCompanion extends UpdateCompanion<MindMapParentSlot> {
  final Value<String> accountId;
  final Value<String> mapId;
  final Value<String> childNodeId;
  final Value<String> parentNodeId;
  final Value<String> appearanceJson;
  final Value<String> revisionId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MindMapParentSlotsCompanion({
    this.accountId = const Value.absent(),
    this.mapId = const Value.absent(),
    this.childNodeId = const Value.absent(),
    this.parentNodeId = const Value.absent(),
    this.appearanceJson = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MindMapParentSlotsCompanion.insert({
    required String accountId,
    required String mapId,
    required String childNodeId,
    required String parentNodeId,
    required String appearanceJson,
    required String revisionId,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       mapId = Value(mapId),
       childNodeId = Value(childNodeId),
       parentNodeId = Value(parentNodeId),
       appearanceJson = Value(appearanceJson),
       revisionId = Value(revisionId),
       updatedAt = Value(updatedAt);
  static Insertable<MindMapParentSlot> custom({
    Expression<String>? accountId,
    Expression<String>? mapId,
    Expression<String>? childNodeId,
    Expression<String>? parentNodeId,
    Expression<String>? appearanceJson,
    Expression<String>? revisionId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (mapId != null) 'map_id': mapId,
      if (childNodeId != null) 'child_node_id': childNodeId,
      if (parentNodeId != null) 'parent_node_id': parentNodeId,
      if (appearanceJson != null) 'appearance_json': appearanceJson,
      if (revisionId != null) 'revision_id': revisionId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MindMapParentSlotsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? mapId,
    Value<String>? childNodeId,
    Value<String>? parentNodeId,
    Value<String>? appearanceJson,
    Value<String>? revisionId,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MindMapParentSlotsCompanion(
      accountId: accountId ?? this.accountId,
      mapId: mapId ?? this.mapId,
      childNodeId: childNodeId ?? this.childNodeId,
      parentNodeId: parentNodeId ?? this.parentNodeId,
      appearanceJson: appearanceJson ?? this.appearanceJson,
      revisionId: revisionId ?? this.revisionId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mapId.present) {
      map['map_id'] = Variable<String>(mapId.value);
    }
    if (childNodeId.present) {
      map['child_node_id'] = Variable<String>(childNodeId.value);
    }
    if (parentNodeId.present) {
      map['parent_node_id'] = Variable<String>(parentNodeId.value);
    }
    if (appearanceJson.present) {
      map['appearance_json'] = Variable<String>(appearanceJson.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MindMapParentSlotsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('childNodeId: $childNodeId, ')
          ..write('parentNodeId: $parentNodeId, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MindMapSideLinksTable extends MindMapSideLinks
    with TableInfo<$MindMapSideLinksTable, MindMapSideLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MindMapSideLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
  @override
  late final GeneratedColumn<String> mapId = GeneratedColumn<String>(
    'map_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNodeIdMeta = const VerificationMeta(
    'firstNodeId',
  );
  @override
  late final GeneratedColumn<String> firstNodeId = GeneratedColumn<String>(
    'first_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondNodeIdMeta = const VerificationMeta(
    'secondNodeId',
  );
  @override
  late final GeneratedColumn<String> secondNodeId = GeneratedColumn<String>(
    'second_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearanceJsonMeta = const VerificationMeta(
    'appearanceJson',
  );
  @override
  late final GeneratedColumn<String> appearanceJson = GeneratedColumn<String>(
    'appearance_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    mapId,
    firstNodeId,
    secondNodeId,
    appearanceJson,
    revisionId,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mind_map_side_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<MindMapSideLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('map_id')) {
      context.handle(
        _mapIdMeta,
        mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mapIdMeta);
    }
    if (data.containsKey('first_node_id')) {
      context.handle(
        _firstNodeIdMeta,
        firstNodeId.isAcceptableOrUnknown(
          data['first_node_id']!,
          _firstNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstNodeIdMeta);
    }
    if (data.containsKey('second_node_id')) {
      context.handle(
        _secondNodeIdMeta,
        secondNodeId.isAcceptableOrUnknown(
          data['second_node_id']!,
          _secondNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secondNodeIdMeta);
    }
    if (data.containsKey('appearance_json')) {
      context.handle(
        _appearanceJsonMeta,
        appearanceJson.isAcceptableOrUnknown(
          data['appearance_json']!,
          _appearanceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appearanceJsonMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    accountId,
    mapId,
    firstNodeId,
    secondNodeId,
  };
  @override
  MindMapSideLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MindMapSideLink(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      mapId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_id'],
      )!,
      firstNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_node_id'],
      )!,
      secondNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}second_node_id'],
      )!,
      appearanceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_json'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MindMapSideLinksTable createAlias(String alias) {
    return $MindMapSideLinksTable(attachedDatabase, alias);
  }
}

class MindMapSideLink extends DataClass implements Insertable<MindMapSideLink> {
  final String accountId;
  final String mapId;
  final String firstNodeId;
  final String secondNodeId;
  final String appearanceJson;
  final String revisionId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MindMapSideLink({
    required this.accountId,
    required this.mapId,
    required this.firstNodeId,
    required this.secondNodeId,
    required this.appearanceJson,
    required this.revisionId,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['map_id'] = Variable<String>(mapId);
    map['first_node_id'] = Variable<String>(firstNodeId);
    map['second_node_id'] = Variable<String>(secondNodeId);
    map['appearance_json'] = Variable<String>(appearanceJson);
    map['revision_id'] = Variable<String>(revisionId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MindMapSideLinksCompanion toCompanion(bool nullToAbsent) {
    return MindMapSideLinksCompanion(
      accountId: Value(accountId),
      mapId: Value(mapId),
      firstNodeId: Value(firstNodeId),
      secondNodeId: Value(secondNodeId),
      appearanceJson: Value(appearanceJson),
      revisionId: Value(revisionId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MindMapSideLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MindMapSideLink(
      accountId: serializer.fromJson<String>(json['accountId']),
      mapId: serializer.fromJson<String>(json['mapId']),
      firstNodeId: serializer.fromJson<String>(json['firstNodeId']),
      secondNodeId: serializer.fromJson<String>(json['secondNodeId']),
      appearanceJson: serializer.fromJson<String>(json['appearanceJson']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'mapId': serializer.toJson<String>(mapId),
      'firstNodeId': serializer.toJson<String>(firstNodeId),
      'secondNodeId': serializer.toJson<String>(secondNodeId),
      'appearanceJson': serializer.toJson<String>(appearanceJson),
      'revisionId': serializer.toJson<String>(revisionId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MindMapSideLink copyWith({
    String? accountId,
    String? mapId,
    String? firstNodeId,
    String? secondNodeId,
    String? appearanceJson,
    String? revisionId,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MindMapSideLink(
    accountId: accountId ?? this.accountId,
    mapId: mapId ?? this.mapId,
    firstNodeId: firstNodeId ?? this.firstNodeId,
    secondNodeId: secondNodeId ?? this.secondNodeId,
    appearanceJson: appearanceJson ?? this.appearanceJson,
    revisionId: revisionId ?? this.revisionId,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MindMapSideLink copyWithCompanion(MindMapSideLinksCompanion data) {
    return MindMapSideLink(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      mapId: data.mapId.present ? data.mapId.value : this.mapId,
      firstNodeId: data.firstNodeId.present
          ? data.firstNodeId.value
          : this.firstNodeId,
      secondNodeId: data.secondNodeId.present
          ? data.secondNodeId.value
          : this.secondNodeId,
      appearanceJson: data.appearanceJson.present
          ? data.appearanceJson.value
          : this.appearanceJson,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MindMapSideLink(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('firstNodeId: $firstNodeId, ')
          ..write('secondNodeId: $secondNodeId, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    mapId,
    firstNodeId,
    secondNodeId,
    appearanceJson,
    revisionId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MindMapSideLink &&
          other.accountId == this.accountId &&
          other.mapId == this.mapId &&
          other.firstNodeId == this.firstNodeId &&
          other.secondNodeId == this.secondNodeId &&
          other.appearanceJson == this.appearanceJson &&
          other.revisionId == this.revisionId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MindMapSideLinksCompanion extends UpdateCompanion<MindMapSideLink> {
  final Value<String> accountId;
  final Value<String> mapId;
  final Value<String> firstNodeId;
  final Value<String> secondNodeId;
  final Value<String> appearanceJson;
  final Value<String> revisionId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MindMapSideLinksCompanion({
    this.accountId = const Value.absent(),
    this.mapId = const Value.absent(),
    this.firstNodeId = const Value.absent(),
    this.secondNodeId = const Value.absent(),
    this.appearanceJson = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MindMapSideLinksCompanion.insert({
    required String accountId,
    required String mapId,
    required String firstNodeId,
    required String secondNodeId,
    required String appearanceJson,
    required String revisionId,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       mapId = Value(mapId),
       firstNodeId = Value(firstNodeId),
       secondNodeId = Value(secondNodeId),
       appearanceJson = Value(appearanceJson),
       revisionId = Value(revisionId),
       updatedAt = Value(updatedAt);
  static Insertable<MindMapSideLink> custom({
    Expression<String>? accountId,
    Expression<String>? mapId,
    Expression<String>? firstNodeId,
    Expression<String>? secondNodeId,
    Expression<String>? appearanceJson,
    Expression<String>? revisionId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (mapId != null) 'map_id': mapId,
      if (firstNodeId != null) 'first_node_id': firstNodeId,
      if (secondNodeId != null) 'second_node_id': secondNodeId,
      if (appearanceJson != null) 'appearance_json': appearanceJson,
      if (revisionId != null) 'revision_id': revisionId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MindMapSideLinksCompanion copyWith({
    Value<String>? accountId,
    Value<String>? mapId,
    Value<String>? firstNodeId,
    Value<String>? secondNodeId,
    Value<String>? appearanceJson,
    Value<String>? revisionId,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MindMapSideLinksCompanion(
      accountId: accountId ?? this.accountId,
      mapId: mapId ?? this.mapId,
      firstNodeId: firstNodeId ?? this.firstNodeId,
      secondNodeId: secondNodeId ?? this.secondNodeId,
      appearanceJson: appearanceJson ?? this.appearanceJson,
      revisionId: revisionId ?? this.revisionId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (mapId.present) {
      map['map_id'] = Variable<String>(mapId.value);
    }
    if (firstNodeId.present) {
      map['first_node_id'] = Variable<String>(firstNodeId.value);
    }
    if (secondNodeId.present) {
      map['second_node_id'] = Variable<String>(secondNodeId.value);
    }
    if (appearanceJson.present) {
      map['appearance_json'] = Variable<String>(appearanceJson.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MindMapSideLinksCompanion(')
          ..write('accountId: $accountId, ')
          ..write('mapId: $mapId, ')
          ..write('firstNodeId: $firstNodeId, ')
          ..write('secondNodeId: $secondNodeId, ')
          ..write('appearanceJson: $appearanceJson, ')
          ..write('revisionId: $revisionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FoundationDatabase extends GeneratedDatabase {
  _$FoundationDatabase(QueryExecutor e) : super(e);
  $FoundationDatabaseManager get managers => $FoundationDatabaseManager(this);
  late final $FoundationPreferencesTable foundationPreferences =
      $FoundationPreferencesTable(this);
  late final $LocalRecordsTable localRecords = $LocalRecordsTable(this);
  late final $PendingChangesTable pendingChanges = $PendingChangesTable(this);
  late final $ConflictRecordsTable conflictRecords = $ConflictRecordsTable(
    this,
  );
  late final $MigrationJournalTable migrationJournal = $MigrationJournalTable(
    this,
  );
  late final $FoundationAuditLogTable foundationAuditLog =
      $FoundationAuditLogTable(this);
  late final $TaskRecordsTable taskRecords = $TaskRecordsTable(this);
  late final $XpAwardsTable xpAwards = $XpAwardsTable(this);
  late final $HabitRecordsTable habitRecords = $HabitRecordsTable(this);
  late final $HabitDayRecordsTable habitDayRecords = $HabitDayRecordsTable(
    this,
  );
  late final $MindMapRecordsTable mindMapRecords = $MindMapRecordsTable(this);
  late final $MindMapNodeRecordsTable mindMapNodeRecords =
      $MindMapNodeRecordsTable(this);
  late final $MindMapParentSlotsTable mindMapParentSlots =
      $MindMapParentSlotsTable(this);
  late final $MindMapSideLinksTable mindMapSideLinks = $MindMapSideLinksTable(
    this,
  );
  late final Index taskRecordsAccountDate = Index(
    'task_records_account_date',
    'CREATE INDEX task_records_account_date ON task_records (account_id, scheduled_date)',
  );
  late final Index taskRecordsAccountCategory = Index(
    'task_records_account_category',
    'CREATE INDEX task_records_account_category ON task_records (account_id, category)',
  );
  late final Index taskRecordsAccountQuadrant = Index(
    'task_records_account_quadrant',
    'CREATE INDEX task_records_account_quadrant ON task_records (account_id, quadrant)',
  );
  late final Index taskRecordsAccountCompletion = Index(
    'task_records_account_completion',
    'CREATE INDEX task_records_account_completion ON task_records (account_id, completed_at)',
  );
  late final Index taskRecordsAccountUpdated = Index(
    'task_records_account_updated',
    'CREATE INDEX task_records_account_updated ON task_records (account_id, updated_at)',
  );
  late final Index taskRecordsAccountDeleted = Index(
    'task_records_account_deleted',
    'CREATE INDEX task_records_account_deleted ON task_records (account_id, deleted_at)',
  );
  late final Index habitRecordsAccountDeleted = Index(
    'habit_records_account_deleted',
    'CREATE INDEX habit_records_account_deleted ON habit_records (account_id, deleted_at)',
  );
  late final Index habitRecordsAccountUpdated = Index(
    'habit_records_account_updated',
    'CREATE INDEX habit_records_account_updated ON habit_records (account_id, updated_at)',
  );
  late final Index habitDayRecordsAccountHabitDate = Index(
    'habit_day_records_account_habit_date',
    'CREATE INDEX habit_day_records_account_habit_date ON habit_day_records (account_id, habit_id, local_date)',
  );
  late final Index habitDayRecordsAccountUpdated = Index(
    'habit_day_records_account_updated',
    'CREATE INDEX habit_day_records_account_updated ON habit_day_records (account_id, updated_at)',
  );
  late final Index mindMapRecordsOwnerDeleted = Index(
    'mind_map_records_owner_deleted',
    'CREATE INDEX mind_map_records_owner_deleted ON mind_map_records (account_id, deleted_at)',
  );
  late final Index mindMapRecordsOwnerUpdated = Index(
    'mind_map_records_owner_updated',
    'CREATE INDEX mind_map_records_owner_updated ON mind_map_records (account_id, updated_at)',
  );
  late final Index mindMapNodeRecordsOwnerMapDeleted = Index(
    'mind_map_node_records_owner_map_deleted',
    'CREATE INDEX mind_map_node_records_owner_map_deleted ON mind_map_node_records (account_id, map_id, deleted_at)',
  );
  late final Index mindMapNodeRecordsOwnerUpdated = Index(
    'mind_map_node_records_owner_updated',
    'CREATE INDEX mind_map_node_records_owner_updated ON mind_map_node_records (account_id, updated_at)',
  );
  late final Index mindMapNodeRecordsOwnerTask = Index(
    'mind_map_node_records_owner_task',
    'CREATE INDEX mind_map_node_records_owner_task ON mind_map_node_records (account_id, task_id)',
  );
  late final Index mindMapParentSlotsOwnerParent = Index(
    'mind_map_parent_slots_owner_parent',
    'CREATE INDEX mind_map_parent_slots_owner_parent ON mind_map_parent_slots (account_id, map_id, parent_node_id)',
  );
  late final Index mindMapParentSlotsOwnerUpdated = Index(
    'mind_map_parent_slots_owner_updated',
    'CREATE INDEX mind_map_parent_slots_owner_updated ON mind_map_parent_slots (account_id, updated_at)',
  );
  late final Index mindMapSideLinksOwnerFirst = Index(
    'mind_map_side_links_owner_first',
    'CREATE INDEX mind_map_side_links_owner_first ON mind_map_side_links (account_id, map_id, first_node_id)',
  );
  late final Index mindMapSideLinksOwnerSecond = Index(
    'mind_map_side_links_owner_second',
    'CREATE INDEX mind_map_side_links_owner_second ON mind_map_side_links (account_id, map_id, second_node_id)',
  );
  late final Index mindMapSideLinksOwnerUpdated = Index(
    'mind_map_side_links_owner_updated',
    'CREATE INDEX mind_map_side_links_owner_updated ON mind_map_side_links (account_id, updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foundationPreferences,
    localRecords,
    pendingChanges,
    conflictRecords,
    migrationJournal,
    foundationAuditLog,
    taskRecords,
    xpAwards,
    habitRecords,
    habitDayRecords,
    mindMapRecords,
    mindMapNodeRecords,
    mindMapParentSlots,
    mindMapSideLinks,
    taskRecordsAccountDate,
    taskRecordsAccountCategory,
    taskRecordsAccountQuadrant,
    taskRecordsAccountCompletion,
    taskRecordsAccountUpdated,
    taskRecordsAccountDeleted,
    habitRecordsAccountDeleted,
    habitRecordsAccountUpdated,
    habitDayRecordsAccountHabitDate,
    habitDayRecordsAccountUpdated,
    mindMapRecordsOwnerDeleted,
    mindMapRecordsOwnerUpdated,
    mindMapNodeRecordsOwnerMapDeleted,
    mindMapNodeRecordsOwnerUpdated,
    mindMapNodeRecordsOwnerTask,
    mindMapParentSlotsOwnerParent,
    mindMapParentSlotsOwnerUpdated,
    mindMapSideLinksOwnerFirst,
    mindMapSideLinksOwnerSecond,
    mindMapSideLinksOwnerUpdated,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$FoundationPreferencesTableCreateCompanionBuilder =
    FoundationPreferencesCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FoundationPreferencesTableUpdateCompanionBuilder =
    FoundationPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FoundationPreferencesTableFilterComposer
    extends Composer<_$FoundationDatabase, $FoundationPreferencesTable> {
  $$FoundationPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoundationPreferencesTableOrderingComposer
    extends Composer<_$FoundationDatabase, $FoundationPreferencesTable> {
  $$FoundationPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoundationPreferencesTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $FoundationPreferencesTable> {
  $$FoundationPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FoundationPreferencesTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $FoundationPreferencesTable,
          FoundationPreference,
          $$FoundationPreferencesTableFilterComposer,
          $$FoundationPreferencesTableOrderingComposer,
          $$FoundationPreferencesTableAnnotationComposer,
          $$FoundationPreferencesTableCreateCompanionBuilder,
          $$FoundationPreferencesTableUpdateCompanionBuilder,
          (
            FoundationPreference,
            BaseReferences<
              _$FoundationDatabase,
              $FoundationPreferencesTable,
              FoundationPreference
            >,
          ),
          FoundationPreference,
          PrefetchHooks Function()
        > {
  $$FoundationPreferencesTableTableManager(
    _$FoundationDatabase db,
    $FoundationPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoundationPreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FoundationPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FoundationPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoundationPreferencesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FoundationPreferencesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoundationPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $FoundationPreferencesTable,
      FoundationPreference,
      $$FoundationPreferencesTableFilterComposer,
      $$FoundationPreferencesTableOrderingComposer,
      $$FoundationPreferencesTableAnnotationComposer,
      $$FoundationPreferencesTableCreateCompanionBuilder,
      $$FoundationPreferencesTableUpdateCompanionBuilder,
      (
        FoundationPreference,
        BaseReferences<
          _$FoundationDatabase,
          $FoundationPreferencesTable,
          FoundationPreference
        >,
      ),
      FoundationPreference,
      PrefetchHooks Function()
    >;
typedef $$LocalRecordsTableCreateCompanionBuilder =
    LocalRecordsCompanion Function({
      required String recordId,
      Value<String?> accountId,
      required String payload,
      required DateTime versionTimestamp,
      required FoundationSyncState syncState,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalRecordsTableUpdateCompanionBuilder =
    LocalRecordsCompanion Function({
      Value<String> recordId,
      Value<String?> accountId,
      Value<String> payload,
      Value<DateTime> versionTimestamp,
      Value<FoundationSyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $LocalRecordsTable> {
  $$LocalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FoundationSyncState, FoundationSyncState, int>
  get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $LocalRecordsTable> {
  $$LocalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $LocalRecordsTable> {
  $$LocalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FoundationSyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $LocalRecordsTable,
          LocalRecord,
          $$LocalRecordsTableFilterComposer,
          $$LocalRecordsTableOrderingComposer,
          $$LocalRecordsTableAnnotationComposer,
          $$LocalRecordsTableCreateCompanionBuilder,
          $$LocalRecordsTableUpdateCompanionBuilder,
          (
            LocalRecord,
            BaseReferences<
              _$FoundationDatabase,
              $LocalRecordsTable,
              LocalRecord
            >,
          ),
          LocalRecord,
          PrefetchHooks Function()
        > {
  $$LocalRecordsTableTableManager(
    _$FoundationDatabase db,
    $LocalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> versionTimestamp = const Value.absent(),
                Value<FoundationSyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordsCompanion(
                recordId: recordId,
                accountId: accountId,
                payload: payload,
                versionTimestamp: versionTimestamp,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                Value<String?> accountId = const Value.absent(),
                required String payload,
                required DateTime versionTimestamp,
                required FoundationSyncState syncState,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordsCompanion.insert(
                recordId: recordId,
                accountId: accountId,
                payload: payload,
                versionTimestamp: versionTimestamp,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $LocalRecordsTable,
      LocalRecord,
      $$LocalRecordsTableFilterComposer,
      $$LocalRecordsTableOrderingComposer,
      $$LocalRecordsTableAnnotationComposer,
      $$LocalRecordsTableCreateCompanionBuilder,
      $$LocalRecordsTableUpdateCompanionBuilder,
      (
        LocalRecord,
        BaseReferences<_$FoundationDatabase, $LocalRecordsTable, LocalRecord>,
      ),
      LocalRecord,
      PrefetchHooks Function()
    >;
typedef $$PendingChangesTableCreateCompanionBuilder =
    PendingChangesCompanion Function({
      required String operationId,
      required String accountId,
      required String entityType,
      required String entityId,
      required ChangeKind kind,
      required PendingChangeState state,
      Value<int> attemptCount,
      Value<String?> lastFailureSummary,
      required String serializedChange,
      Value<String?> acknowledgementId,
      required DateTime createdAt,
      required DateTime versionTimestamp,
      Value<int> rowid,
    });
typedef $$PendingChangesTableUpdateCompanionBuilder =
    PendingChangesCompanion Function({
      Value<String> operationId,
      Value<String> accountId,
      Value<String> entityType,
      Value<String> entityId,
      Value<ChangeKind> kind,
      Value<PendingChangeState> state,
      Value<int> attemptCount,
      Value<String?> lastFailureSummary,
      Value<String> serializedChange,
      Value<String?> acknowledgementId,
      Value<DateTime> createdAt,
      Value<DateTime> versionTimestamp,
      Value<int> rowid,
    });

class $$PendingChangesTableFilterComposer
    extends Composer<_$FoundationDatabase, $PendingChangesTable> {
  $$PendingChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
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

  ColumnWithTypeConverterFilters<ChangeKind, ChangeKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PendingChangeState, PendingChangeState, int>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailureSummary => $composableBuilder(
    column: $table.lastFailureSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serializedChange => $composableBuilder(
    column: $table.serializedChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingChangesTableOrderingComposer
    extends Composer<_$FoundationDatabase, $PendingChangesTable> {
  $$PendingChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailureSummary => $composableBuilder(
    column: $table.lastFailureSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serializedChange => $composableBuilder(
    column: $table.serializedChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingChangesTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $PendingChangesTable> {
  $$PendingChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChangeKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PendingChangeState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFailureSummary => $composableBuilder(
    column: $table.lastFailureSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serializedChange => $composableBuilder(
    column: $table.serializedChange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acknowledgementId => $composableBuilder(
    column: $table.acknowledgementId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get versionTimestamp => $composableBuilder(
    column: $table.versionTimestamp,
    builder: (column) => column,
  );
}

class $$PendingChangesTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $PendingChangesTable,
          PendingChange,
          $$PendingChangesTableFilterComposer,
          $$PendingChangesTableOrderingComposer,
          $$PendingChangesTableAnnotationComposer,
          $$PendingChangesTableCreateCompanionBuilder,
          $$PendingChangesTableUpdateCompanionBuilder,
          (
            PendingChange,
            BaseReferences<
              _$FoundationDatabase,
              $PendingChangesTable,
              PendingChange
            >,
          ),
          PendingChange,
          PrefetchHooks Function()
        > {
  $$PendingChangesTableTableManager(
    _$FoundationDatabase db,
    $PendingChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<ChangeKind> kind = const Value.absent(),
                Value<PendingChangeState> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastFailureSummary = const Value.absent(),
                Value<String> serializedChange = const Value.absent(),
                Value<String?> acknowledgementId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> versionTimestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingChangesCompanion(
                operationId: operationId,
                accountId: accountId,
                entityType: entityType,
                entityId: entityId,
                kind: kind,
                state: state,
                attemptCount: attemptCount,
                lastFailureSummary: lastFailureSummary,
                serializedChange: serializedChange,
                acknowledgementId: acknowledgementId,
                createdAt: createdAt,
                versionTimestamp: versionTimestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String accountId,
                required String entityType,
                required String entityId,
                required ChangeKind kind,
                required PendingChangeState state,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastFailureSummary = const Value.absent(),
                required String serializedChange,
                Value<String?> acknowledgementId = const Value.absent(),
                required DateTime createdAt,
                required DateTime versionTimestamp,
                Value<int> rowid = const Value.absent(),
              }) => PendingChangesCompanion.insert(
                operationId: operationId,
                accountId: accountId,
                entityType: entityType,
                entityId: entityId,
                kind: kind,
                state: state,
                attemptCount: attemptCount,
                lastFailureSummary: lastFailureSummary,
                serializedChange: serializedChange,
                acknowledgementId: acknowledgementId,
                createdAt: createdAt,
                versionTimestamp: versionTimestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $PendingChangesTable,
      PendingChange,
      $$PendingChangesTableFilterComposer,
      $$PendingChangesTableOrderingComposer,
      $$PendingChangesTableAnnotationComposer,
      $$PendingChangesTableCreateCompanionBuilder,
      $$PendingChangesTableUpdateCompanionBuilder,
      (
        PendingChange,
        BaseReferences<
          _$FoundationDatabase,
          $PendingChangesTable,
          PendingChange
        >,
      ),
      PendingChange,
      PrefetchHooks Function()
    >;
typedef $$ConflictRecordsTableCreateCompanionBuilder =
    ConflictRecordsCompanion Function({
      required String conflictId,
      required String accountId,
      required String entityType,
      required String entityId,
      required VersionSource activeSource,
      required DateTime activeTimestamp,
      required String activePayload,
      required VersionSource retainedSource,
      required DateTime retainedTimestamp,
      required String retainedPayload,
      required DateTime detectedAt,
      Value<int> rowid,
    });
typedef $$ConflictRecordsTableUpdateCompanionBuilder =
    ConflictRecordsCompanion Function({
      Value<String> conflictId,
      Value<String> accountId,
      Value<String> entityType,
      Value<String> entityId,
      Value<VersionSource> activeSource,
      Value<DateTime> activeTimestamp,
      Value<String> activePayload,
      Value<VersionSource> retainedSource,
      Value<DateTime> retainedTimestamp,
      Value<String> retainedPayload,
      Value<DateTime> detectedAt,
      Value<int> rowid,
    });

class $$ConflictRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conflictId => $composableBuilder(
    column: $table.conflictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
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

  ColumnWithTypeConverterFilters<VersionSource, VersionSource, int>
  get activeSource => $composableBuilder(
    column: $table.activeSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get activeTimestamp => $composableBuilder(
    column: $table.activeTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activePayload => $composableBuilder(
    column: $table.activePayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VersionSource, VersionSource, int>
  get retainedSource => $composableBuilder(
    column: $table.retainedSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get retainedTimestamp => $composableBuilder(
    column: $table.retainedTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retainedPayload => $composableBuilder(
    column: $table.retainedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conflictId => $composableBuilder(
    column: $table.conflictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
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

  ColumnOrderings<int> get activeSource => $composableBuilder(
    column: $table.activeSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activeTimestamp => $composableBuilder(
    column: $table.activeTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activePayload => $composableBuilder(
    column: $table.activePayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retainedSource => $composableBuilder(
    column: $table.retainedSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retainedTimestamp => $composableBuilder(
    column: $table.retainedTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retainedPayload => $composableBuilder(
    column: $table.retainedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conflictId => $composableBuilder(
    column: $table.conflictId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VersionSource, int> get activeSource =>
      $composableBuilder(
        column: $table.activeSource,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get activeTimestamp => $composableBuilder(
    column: $table.activeTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activePayload => $composableBuilder(
    column: $table.activePayload,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<VersionSource, int> get retainedSource =>
      $composableBuilder(
        column: $table.retainedSource,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get retainedTimestamp => $composableBuilder(
    column: $table.retainedTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get retainedPayload => $composableBuilder(
    column: $table.retainedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );
}

class $$ConflictRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $ConflictRecordsTable,
          ConflictRecord,
          $$ConflictRecordsTableFilterComposer,
          $$ConflictRecordsTableOrderingComposer,
          $$ConflictRecordsTableAnnotationComposer,
          $$ConflictRecordsTableCreateCompanionBuilder,
          $$ConflictRecordsTableUpdateCompanionBuilder,
          (
            ConflictRecord,
            BaseReferences<
              _$FoundationDatabase,
              $ConflictRecordsTable,
              ConflictRecord
            >,
          ),
          ConflictRecord,
          PrefetchHooks Function()
        > {
  $$ConflictRecordsTableTableManager(
    _$FoundationDatabase db,
    $ConflictRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conflictId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<VersionSource> activeSource = const Value.absent(),
                Value<DateTime> activeTimestamp = const Value.absent(),
                Value<String> activePayload = const Value.absent(),
                Value<VersionSource> retainedSource = const Value.absent(),
                Value<DateTime> retainedTimestamp = const Value.absent(),
                Value<String> retainedPayload = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictRecordsCompanion(
                conflictId: conflictId,
                accountId: accountId,
                entityType: entityType,
                entityId: entityId,
                activeSource: activeSource,
                activeTimestamp: activeTimestamp,
                activePayload: activePayload,
                retainedSource: retainedSource,
                retainedTimestamp: retainedTimestamp,
                retainedPayload: retainedPayload,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conflictId,
                required String accountId,
                required String entityType,
                required String entityId,
                required VersionSource activeSource,
                required DateTime activeTimestamp,
                required String activePayload,
                required VersionSource retainedSource,
                required DateTime retainedTimestamp,
                required String retainedPayload,
                required DateTime detectedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConflictRecordsCompanion.insert(
                conflictId: conflictId,
                accountId: accountId,
                entityType: entityType,
                entityId: entityId,
                activeSource: activeSource,
                activeTimestamp: activeTimestamp,
                activePayload: activePayload,
                retainedSource: retainedSource,
                retainedTimestamp: retainedTimestamp,
                retainedPayload: retainedPayload,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $ConflictRecordsTable,
      ConflictRecord,
      $$ConflictRecordsTableFilterComposer,
      $$ConflictRecordsTableOrderingComposer,
      $$ConflictRecordsTableAnnotationComposer,
      $$ConflictRecordsTableCreateCompanionBuilder,
      $$ConflictRecordsTableUpdateCompanionBuilder,
      (
        ConflictRecord,
        BaseReferences<
          _$FoundationDatabase,
          $ConflictRecordsTable,
          ConflictRecord
        >,
      ),
      ConflictRecord,
      PrefetchHooks Function()
    >;
typedef $$MigrationJournalTableCreateCompanionBuilder =
    MigrationJournalCompanion Function({
      Value<int> id,
      required int version,
      required String status,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> recoveryDetail,
    });
typedef $$MigrationJournalTableUpdateCompanionBuilder =
    MigrationJournalCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> recoveryDetail,
    });

class $$MigrationJournalTableFilterComposer
    extends Composer<_$FoundationDatabase, $MigrationJournalTable> {
  $$MigrationJournalTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryDetail => $composableBuilder(
    column: $table.recoveryDetail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationJournalTableOrderingComposer
    extends Composer<_$FoundationDatabase, $MigrationJournalTable> {
  $$MigrationJournalTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryDetail => $composableBuilder(
    column: $table.recoveryDetail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationJournalTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $MigrationJournalTable> {
  $$MigrationJournalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get recoveryDetail => $composableBuilder(
    column: $table.recoveryDetail,
    builder: (column) => column,
  );
}

class $$MigrationJournalTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $MigrationJournalTable,
          MigrationJournalData,
          $$MigrationJournalTableFilterComposer,
          $$MigrationJournalTableOrderingComposer,
          $$MigrationJournalTableAnnotationComposer,
          $$MigrationJournalTableCreateCompanionBuilder,
          $$MigrationJournalTableUpdateCompanionBuilder,
          (
            MigrationJournalData,
            BaseReferences<
              _$FoundationDatabase,
              $MigrationJournalTable,
              MigrationJournalData
            >,
          ),
          MigrationJournalData,
          PrefetchHooks Function()
        > {
  $$MigrationJournalTableTableManager(
    _$FoundationDatabase db,
    $MigrationJournalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationJournalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationJournalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationJournalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> recoveryDetail = const Value.absent(),
              }) => MigrationJournalCompanion(
                id: id,
                version: version,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                recoveryDetail: recoveryDetail,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int version,
                required String status,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> recoveryDetail = const Value.absent(),
              }) => MigrationJournalCompanion.insert(
                id: id,
                version: version,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                recoveryDetail: recoveryDetail,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationJournalTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $MigrationJournalTable,
      MigrationJournalData,
      $$MigrationJournalTableFilterComposer,
      $$MigrationJournalTableOrderingComposer,
      $$MigrationJournalTableAnnotationComposer,
      $$MigrationJournalTableCreateCompanionBuilder,
      $$MigrationJournalTableUpdateCompanionBuilder,
      (
        MigrationJournalData,
        BaseReferences<
          _$FoundationDatabase,
          $MigrationJournalTable,
          MigrationJournalData
        >,
      ),
      MigrationJournalData,
      PrefetchHooks Function()
    >;
typedef $$FoundationAuditLogTableCreateCompanionBuilder =
    FoundationAuditLogCompanion Function({
      Value<int> id,
      required String note,
      required DateTime at,
    });
typedef $$FoundationAuditLogTableUpdateCompanionBuilder =
    FoundationAuditLogCompanion Function({
      Value<int> id,
      Value<String> note,
      Value<DateTime> at,
    });

class $$FoundationAuditLogTableFilterComposer
    extends Composer<_$FoundationDatabase, $FoundationAuditLogTable> {
  $$FoundationAuditLogTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoundationAuditLogTableOrderingComposer
    extends Composer<_$FoundationDatabase, $FoundationAuditLogTable> {
  $$FoundationAuditLogTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoundationAuditLogTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $FoundationAuditLogTable> {
  $$FoundationAuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$FoundationAuditLogTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $FoundationAuditLogTable,
          FoundationAuditLogData,
          $$FoundationAuditLogTableFilterComposer,
          $$FoundationAuditLogTableOrderingComposer,
          $$FoundationAuditLogTableAnnotationComposer,
          $$FoundationAuditLogTableCreateCompanionBuilder,
          $$FoundationAuditLogTableUpdateCompanionBuilder,
          (
            FoundationAuditLogData,
            BaseReferences<
              _$FoundationDatabase,
              $FoundationAuditLogTable,
              FoundationAuditLogData
            >,
          ),
          FoundationAuditLogData,
          PrefetchHooks Function()
        > {
  $$FoundationAuditLogTableTableManager(
    _$FoundationDatabase db,
    $FoundationAuditLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoundationAuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoundationAuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoundationAuditLogTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => FoundationAuditLogCompanion(id: id, note: note, at: at),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String note,
                required DateTime at,
              }) => FoundationAuditLogCompanion.insert(
                id: id,
                note: note,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoundationAuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $FoundationAuditLogTable,
      FoundationAuditLogData,
      $$FoundationAuditLogTableFilterComposer,
      $$FoundationAuditLogTableOrderingComposer,
      $$FoundationAuditLogTableAnnotationComposer,
      $$FoundationAuditLogTableCreateCompanionBuilder,
      $$FoundationAuditLogTableUpdateCompanionBuilder,
      (
        FoundationAuditLogData,
        BaseReferences<
          _$FoundationDatabase,
          $FoundationAuditLogTable,
          FoundationAuditLogData
        >,
      ),
      FoundationAuditLogData,
      PrefetchHooks Function()
    >;
typedef $$TaskRecordsTableCreateCompanionBuilder =
    TaskRecordsCompanion Function({
      required String accountId,
      required String taskId,
      required String title,
      Value<String?> description,
      required String scheduledDate,
      Value<String?> scheduledTime,
      Value<DateTime?> targetDeadline,
      Value<int?> targetDeadlineUtcOffsetMinutes,
      required String category,
      required String quadrant,
      Value<int?> estimatedDurationMinutes,
      Value<String> checklistJson,
      Value<DateTime?> completedAt,
      Value<DateTime?> completionChangedAt,
      required int completionXp,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaskRecordsTableUpdateCompanionBuilder =
    TaskRecordsCompanion Function({
      Value<String> accountId,
      Value<String> taskId,
      Value<String> title,
      Value<String?> description,
      Value<String> scheduledDate,
      Value<String?> scheduledTime,
      Value<DateTime?> targetDeadline,
      Value<int?> targetDeadlineUtcOffsetMinutes,
      Value<String> category,
      Value<String> quadrant,
      Value<int?> estimatedDurationMinutes,
      Value<String> checklistJson,
      Value<DateTime?> completedAt,
      Value<DateTime?> completionChangedAt,
      Value<int> completionXp,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$TaskRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
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

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDeadline => $composableBuilder(
    column: $table.targetDeadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDeadlineUtcOffsetMinutes => $composableBuilder(
    column: $table.targetDeadlineUtcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completionChangedAt => $composableBuilder(
    column: $table.completionChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionXp => $composableBuilder(
    column: $table.completionXp,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
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

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDeadline => $composableBuilder(
    column: $table.targetDeadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDeadlineUtcOffsetMinutes => $composableBuilder(
    column: $table.targetDeadlineUtcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quadrant => $composableBuilder(
    column: $table.quadrant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completionChangedAt => $composableBuilder(
    column: $table.completionChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionXp => $composableBuilder(
    column: $table.completionXp,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDeadline => $composableBuilder(
    column: $table.targetDeadline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDeadlineUtcOffsetMinutes => $composableBuilder(
    column: $table.targetDeadlineUtcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get quadrant =>
      $composableBuilder(column: $table.quadrant, builder: (column) => column);

  GeneratedColumn<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completionChangedAt => $composableBuilder(
    column: $table.completionChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionXp => $composableBuilder(
    column: $table.completionXp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TaskRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $TaskRecordsTable,
          TaskRecord,
          $$TaskRecordsTableFilterComposer,
          $$TaskRecordsTableOrderingComposer,
          $$TaskRecordsTableAnnotationComposer,
          $$TaskRecordsTableCreateCompanionBuilder,
          $$TaskRecordsTableUpdateCompanionBuilder,
          (
            TaskRecord,
            BaseReferences<_$FoundationDatabase, $TaskRecordsTable, TaskRecord>,
          ),
          TaskRecord,
          PrefetchHooks Function()
        > {
  $$TaskRecordsTableTableManager(
    _$FoundationDatabase db,
    $TaskRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> scheduledDate = const Value.absent(),
                Value<String?> scheduledTime = const Value.absent(),
                Value<DateTime?> targetDeadline = const Value.absent(),
                Value<int?> targetDeadlineUtcOffsetMinutes =
                    const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> quadrant = const Value.absent(),
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> completionChangedAt = const Value.absent(),
                Value<int> completionXp = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecordsCompanion(
                accountId: accountId,
                taskId: taskId,
                title: title,
                description: description,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                targetDeadline: targetDeadline,
                targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
                category: category,
                quadrant: quadrant,
                estimatedDurationMinutes: estimatedDurationMinutes,
                checklistJson: checklistJson,
                completedAt: completedAt,
                completionChangedAt: completionChangedAt,
                completionXp: completionXp,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String taskId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String scheduledDate,
                Value<String?> scheduledTime = const Value.absent(),
                Value<DateTime?> targetDeadline = const Value.absent(),
                Value<int?> targetDeadlineUtcOffsetMinutes =
                    const Value.absent(),
                required String category,
                required String quadrant,
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> completionChangedAt = const Value.absent(),
                required int completionXp,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecordsCompanion.insert(
                accountId: accountId,
                taskId: taskId,
                title: title,
                description: description,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                targetDeadline: targetDeadline,
                targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
                category: category,
                quadrant: quadrant,
                estimatedDurationMinutes: estimatedDurationMinutes,
                checklistJson: checklistJson,
                completedAt: completedAt,
                completionChangedAt: completionChangedAt,
                completionXp: completionXp,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $TaskRecordsTable,
      TaskRecord,
      $$TaskRecordsTableFilterComposer,
      $$TaskRecordsTableOrderingComposer,
      $$TaskRecordsTableAnnotationComposer,
      $$TaskRecordsTableCreateCompanionBuilder,
      $$TaskRecordsTableUpdateCompanionBuilder,
      (
        TaskRecord,
        BaseReferences<_$FoundationDatabase, $TaskRecordsTable, TaskRecord>,
      ),
      TaskRecord,
      PrefetchHooks Function()
    >;
typedef $$XpAwardsTableCreateCompanionBuilder =
    XpAwardsCompanion Function({
      required String accountId,
      required String source,
      required String sourceId,
      required int amount,
      required DateTime awardedAt,
      Value<int> rowid,
    });
typedef $$XpAwardsTableUpdateCompanionBuilder =
    XpAwardsCompanion Function({
      Value<String> accountId,
      Value<String> source,
      Value<String> sourceId,
      Value<int> amount,
      Value<DateTime> awardedAt,
      Value<int> rowid,
    });

class $$XpAwardsTableFilterComposer
    extends Composer<_$FoundationDatabase, $XpAwardsTable> {
  $$XpAwardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get awardedAt => $composableBuilder(
    column: $table.awardedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$XpAwardsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $XpAwardsTable> {
  $$XpAwardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get awardedAt => $composableBuilder(
    column: $table.awardedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$XpAwardsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $XpAwardsTable> {
  $$XpAwardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get awardedAt =>
      $composableBuilder(column: $table.awardedAt, builder: (column) => column);
}

class $$XpAwardsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $XpAwardsTable,
          XpAward,
          $$XpAwardsTableFilterComposer,
          $$XpAwardsTableOrderingComposer,
          $$XpAwardsTableAnnotationComposer,
          $$XpAwardsTableCreateCompanionBuilder,
          $$XpAwardsTableUpdateCompanionBuilder,
          (
            XpAward,
            BaseReferences<_$FoundationDatabase, $XpAwardsTable, XpAward>,
          ),
          XpAward,
          PrefetchHooks Function()
        > {
  $$XpAwardsTableTableManager(_$FoundationDatabase db, $XpAwardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XpAwardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XpAwardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XpAwardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<DateTime> awardedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => XpAwardsCompanion(
                accountId: accountId,
                source: source,
                sourceId: sourceId,
                amount: amount,
                awardedAt: awardedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String source,
                required String sourceId,
                required int amount,
                required DateTime awardedAt,
                Value<int> rowid = const Value.absent(),
              }) => XpAwardsCompanion.insert(
                accountId: accountId,
                source: source,
                sourceId: sourceId,
                amount: amount,
                awardedAt: awardedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$XpAwardsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $XpAwardsTable,
      XpAward,
      $$XpAwardsTableFilterComposer,
      $$XpAwardsTableOrderingComposer,
      $$XpAwardsTableAnnotationComposer,
      $$XpAwardsTableCreateCompanionBuilder,
      $$XpAwardsTableUpdateCompanionBuilder,
      (XpAward, BaseReferences<_$FoundationDatabase, $XpAwardsTable, XpAward>),
      XpAward,
      PrefetchHooks Function()
    >;
typedef $$HabitRecordsTableCreateCompanionBuilder =
    HabitRecordsCompanion Function({
      required String accountId,
      required String habitId,
      required String name,
      required String scheduleRevisionsJson,
      Value<int?> reminderMinuteOfDay,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$HabitRecordsTableUpdateCompanionBuilder =
    HabitRecordsCompanion Function({
      Value<String> accountId,
      Value<String> habitId,
      Value<String> name,
      Value<String> scheduleRevisionsJson,
      Value<int?> reminderMinuteOfDay,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$HabitRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleRevisionsJson => $composableBuilder(
    column: $table.scheduleRevisionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinuteOfDay => $composableBuilder(
    column: $table.reminderMinuteOfDay,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleRevisionsJson => $composableBuilder(
    column: $table.scheduleRevisionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinuteOfDay => $composableBuilder(
    column: $table.reminderMinuteOfDay,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scheduleRevisionsJson => $composableBuilder(
    column: $table.scheduleRevisionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinuteOfDay => $composableBuilder(
    column: $table.reminderMinuteOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$HabitRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $HabitRecordsTable,
          HabitRecord,
          $$HabitRecordsTableFilterComposer,
          $$HabitRecordsTableOrderingComposer,
          $$HabitRecordsTableAnnotationComposer,
          $$HabitRecordsTableCreateCompanionBuilder,
          $$HabitRecordsTableUpdateCompanionBuilder,
          (
            HabitRecord,
            BaseReferences<
              _$FoundationDatabase,
              $HabitRecordsTable,
              HabitRecord
            >,
          ),
          HabitRecord,
          PrefetchHooks Function()
        > {
  $$HabitRecordsTableTableManager(
    _$FoundationDatabase db,
    $HabitRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scheduleRevisionsJson = const Value.absent(),
                Value<int?> reminderMinuteOfDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitRecordsCompanion(
                accountId: accountId,
                habitId: habitId,
                name: name,
                scheduleRevisionsJson: scheduleRevisionsJson,
                reminderMinuteOfDay: reminderMinuteOfDay,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String habitId,
                required String name,
                required String scheduleRevisionsJson,
                Value<int?> reminderMinuteOfDay = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitRecordsCompanion.insert(
                accountId: accountId,
                habitId: habitId,
                name: name,
                scheduleRevisionsJson: scheduleRevisionsJson,
                reminderMinuteOfDay: reminderMinuteOfDay,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $HabitRecordsTable,
      HabitRecord,
      $$HabitRecordsTableFilterComposer,
      $$HabitRecordsTableOrderingComposer,
      $$HabitRecordsTableAnnotationComposer,
      $$HabitRecordsTableCreateCompanionBuilder,
      $$HabitRecordsTableUpdateCompanionBuilder,
      (
        HabitRecord,
        BaseReferences<_$FoundationDatabase, $HabitRecordsTable, HabitRecord>,
      ),
      HabitRecord,
      PrefetchHooks Function()
    >;
typedef $$HabitDayRecordsTableCreateCompanionBuilder =
    HabitDayRecordsCompanion Function({
      required String accountId,
      required String habitId,
      required String localDate,
      Value<DateTime?> completedAt,
      Value<int> dailyCount,
      required bool earnedWhileDue,
      Value<String?> earnedAgainstRevisionId,
      required int recordedUtcOffsetMinutes,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HabitDayRecordsTableUpdateCompanionBuilder =
    HabitDayRecordsCompanion Function({
      Value<String> accountId,
      Value<String> habitId,
      Value<String> localDate,
      Value<DateTime?> completedAt,
      Value<int> dailyCount,
      Value<bool> earnedWhileDue,
      Value<String?> earnedAgainstRevisionId,
      Value<int> recordedUtcOffsetMinutes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HabitDayRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $HabitDayRecordsTable> {
  $$HabitDayRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get earnedWhileDue => $composableBuilder(
    column: $table.earnedWhileDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedAgainstRevisionId => $composableBuilder(
    column: $table.earnedAgainstRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedUtcOffsetMinutes => $composableBuilder(
    column: $table.recordedUtcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitDayRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $HabitDayRecordsTable> {
  $$HabitDayRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get earnedWhileDue => $composableBuilder(
    column: $table.earnedWhileDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedAgainstRevisionId => $composableBuilder(
    column: $table.earnedAgainstRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedUtcOffsetMinutes => $composableBuilder(
    column: $table.recordedUtcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitDayRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $HabitDayRecordsTable> {
  $$HabitDayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyCount => $composableBuilder(
    column: $table.dailyCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get earnedWhileDue => $composableBuilder(
    column: $table.earnedWhileDue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnedAgainstRevisionId => $composableBuilder(
    column: $table.earnedAgainstRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedUtcOffsetMinutes => $composableBuilder(
    column: $table.recordedUtcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HabitDayRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $HabitDayRecordsTable,
          HabitDayRecord,
          $$HabitDayRecordsTableFilterComposer,
          $$HabitDayRecordsTableOrderingComposer,
          $$HabitDayRecordsTableAnnotationComposer,
          $$HabitDayRecordsTableCreateCompanionBuilder,
          $$HabitDayRecordsTableUpdateCompanionBuilder,
          (
            HabitDayRecord,
            BaseReferences<
              _$FoundationDatabase,
              $HabitDayRecordsTable,
              HabitDayRecord
            >,
          ),
          HabitDayRecord,
          PrefetchHooks Function()
        > {
  $$HabitDayRecordsTableTableManager(
    _$FoundationDatabase db,
    $HabitDayRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitDayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitDayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitDayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> dailyCount = const Value.absent(),
                Value<bool> earnedWhileDue = const Value.absent(),
                Value<String?> earnedAgainstRevisionId = const Value.absent(),
                Value<int> recordedUtcOffsetMinutes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitDayRecordsCompanion(
                accountId: accountId,
                habitId: habitId,
                localDate: localDate,
                completedAt: completedAt,
                dailyCount: dailyCount,
                earnedWhileDue: earnedWhileDue,
                earnedAgainstRevisionId: earnedAgainstRevisionId,
                recordedUtcOffsetMinutes: recordedUtcOffsetMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String habitId,
                required String localDate,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> dailyCount = const Value.absent(),
                required bool earnedWhileDue,
                Value<String?> earnedAgainstRevisionId = const Value.absent(),
                required int recordedUtcOffsetMinutes,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitDayRecordsCompanion.insert(
                accountId: accountId,
                habitId: habitId,
                localDate: localDate,
                completedAt: completedAt,
                dailyCount: dailyCount,
                earnedWhileDue: earnedWhileDue,
                earnedAgainstRevisionId: earnedAgainstRevisionId,
                recordedUtcOffsetMinutes: recordedUtcOffsetMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitDayRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $HabitDayRecordsTable,
      HabitDayRecord,
      $$HabitDayRecordsTableFilterComposer,
      $$HabitDayRecordsTableOrderingComposer,
      $$HabitDayRecordsTableAnnotationComposer,
      $$HabitDayRecordsTableCreateCompanionBuilder,
      $$HabitDayRecordsTableUpdateCompanionBuilder,
      (
        HabitDayRecord,
        BaseReferences<
          _$FoundationDatabase,
          $HabitDayRecordsTable,
          HabitDayRecord
        >,
      ),
      HabitDayRecord,
      PrefetchHooks Function()
    >;
typedef $$MindMapRecordsTableCreateCompanionBuilder =
    MindMapRecordsCompanion Function({
      required String accountId,
      required String mapId,
      required String title,
      Value<String?> description,
      required String centralNodeId,
      required String settingsJson,
      required String revisionId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MindMapRecordsTableUpdateCompanionBuilder =
    MindMapRecordsCompanion Function({
      Value<String> accountId,
      Value<String> mapId,
      Value<String> title,
      Value<String?> description,
      Value<String> centralNodeId,
      Value<String> settingsJson,
      Value<String> revisionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MindMapRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $MindMapRecordsTable> {
  $$MindMapRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapId => $composableBuilder(
    column: $table.mapId,
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

  ColumnFilters<String> get centralNodeId => $composableBuilder(
    column: $table.centralNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MindMapRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $MindMapRecordsTable> {
  $$MindMapRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapId => $composableBuilder(
    column: $table.mapId,
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

  ColumnOrderings<String> get centralNodeId => $composableBuilder(
    column: $table.centralNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MindMapRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $MindMapRecordsTable> {
  $$MindMapRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mapId =>
      $composableBuilder(column: $table.mapId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get centralNodeId => $composableBuilder(
    column: $table.centralNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MindMapRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $MindMapRecordsTable,
          MindMapRecord,
          $$MindMapRecordsTableFilterComposer,
          $$MindMapRecordsTableOrderingComposer,
          $$MindMapRecordsTableAnnotationComposer,
          $$MindMapRecordsTableCreateCompanionBuilder,
          $$MindMapRecordsTableUpdateCompanionBuilder,
          (
            MindMapRecord,
            BaseReferences<
              _$FoundationDatabase,
              $MindMapRecordsTable,
              MindMapRecord
            >,
          ),
          MindMapRecord,
          PrefetchHooks Function()
        > {
  $$MindMapRecordsTableTableManager(
    _$FoundationDatabase db,
    $MindMapRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MindMapRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MindMapRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MindMapRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> mapId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> centralNodeId = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapRecordsCompanion(
                accountId: accountId,
                mapId: mapId,
                title: title,
                description: description,
                centralNodeId: centralNodeId,
                settingsJson: settingsJson,
                revisionId: revisionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String mapId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String centralNodeId,
                required String settingsJson,
                required String revisionId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapRecordsCompanion.insert(
                accountId: accountId,
                mapId: mapId,
                title: title,
                description: description,
                centralNodeId: centralNodeId,
                settingsJson: settingsJson,
                revisionId: revisionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MindMapRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $MindMapRecordsTable,
      MindMapRecord,
      $$MindMapRecordsTableFilterComposer,
      $$MindMapRecordsTableOrderingComposer,
      $$MindMapRecordsTableAnnotationComposer,
      $$MindMapRecordsTableCreateCompanionBuilder,
      $$MindMapRecordsTableUpdateCompanionBuilder,
      (
        MindMapRecord,
        BaseReferences<
          _$FoundationDatabase,
          $MindMapRecordsTable,
          MindMapRecord
        >,
      ),
      MindMapRecord,
      PrefetchHooks Function()
    >;
typedef $$MindMapNodeRecordsTableCreateCompanionBuilder =
    MindMapNodeRecordsCompanion Function({
      required String accountId,
      required String mapId,
      required String nodeId,
      required String kind,
      required String title,
      Value<String?> description,
      required double x,
      required double y,
      required String status,
      Value<DateTime?> statusChangedAt,
      required String priority,
      required String appearanceJson,
      Value<String?> taskId,
      required String revisionId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MindMapNodeRecordsTableUpdateCompanionBuilder =
    MindMapNodeRecordsCompanion Function({
      Value<String> accountId,
      Value<String> mapId,
      Value<String> nodeId,
      Value<String> kind,
      Value<String> title,
      Value<String?> description,
      Value<double> x,
      Value<double> y,
      Value<String> status,
      Value<DateTime?> statusChangedAt,
      Value<String> priority,
      Value<String> appearanceJson,
      Value<String?> taskId,
      Value<String> revisionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MindMapNodeRecordsTableFilterComposer
    extends Composer<_$FoundationDatabase, $MindMapNodeRecordsTable> {
  $$MindMapNodeRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
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

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get statusChangedAt => $composableBuilder(
    column: $table.statusChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MindMapNodeRecordsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $MindMapNodeRecordsTable> {
  $$MindMapNodeRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
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

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get statusChangedAt => $composableBuilder(
    column: $table.statusChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MindMapNodeRecordsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $MindMapNodeRecordsTable> {
  $$MindMapNodeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mapId =>
      $composableBuilder(column: $table.mapId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get statusChangedAt => $composableBuilder(
    column: $table.statusChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MindMapNodeRecordsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $MindMapNodeRecordsTable,
          MindMapNodeRecord,
          $$MindMapNodeRecordsTableFilterComposer,
          $$MindMapNodeRecordsTableOrderingComposer,
          $$MindMapNodeRecordsTableAnnotationComposer,
          $$MindMapNodeRecordsTableCreateCompanionBuilder,
          $$MindMapNodeRecordsTableUpdateCompanionBuilder,
          (
            MindMapNodeRecord,
            BaseReferences<
              _$FoundationDatabase,
              $MindMapNodeRecordsTable,
              MindMapNodeRecord
            >,
          ),
          MindMapNodeRecord,
          PrefetchHooks Function()
        > {
  $$MindMapNodeRecordsTableTableManager(
    _$FoundationDatabase db,
    $MindMapNodeRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MindMapNodeRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MindMapNodeRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MindMapNodeRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> mapId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> statusChangedAt = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> appearanceJson = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapNodeRecordsCompanion(
                accountId: accountId,
                mapId: mapId,
                nodeId: nodeId,
                kind: kind,
                title: title,
                description: description,
                x: x,
                y: y,
                status: status,
                statusChangedAt: statusChangedAt,
                priority: priority,
                appearanceJson: appearanceJson,
                taskId: taskId,
                revisionId: revisionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String mapId,
                required String nodeId,
                required String kind,
                required String title,
                Value<String?> description = const Value.absent(),
                required double x,
                required double y,
                required String status,
                Value<DateTime?> statusChangedAt = const Value.absent(),
                required String priority,
                required String appearanceJson,
                Value<String?> taskId = const Value.absent(),
                required String revisionId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapNodeRecordsCompanion.insert(
                accountId: accountId,
                mapId: mapId,
                nodeId: nodeId,
                kind: kind,
                title: title,
                description: description,
                x: x,
                y: y,
                status: status,
                statusChangedAt: statusChangedAt,
                priority: priority,
                appearanceJson: appearanceJson,
                taskId: taskId,
                revisionId: revisionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MindMapNodeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $MindMapNodeRecordsTable,
      MindMapNodeRecord,
      $$MindMapNodeRecordsTableFilterComposer,
      $$MindMapNodeRecordsTableOrderingComposer,
      $$MindMapNodeRecordsTableAnnotationComposer,
      $$MindMapNodeRecordsTableCreateCompanionBuilder,
      $$MindMapNodeRecordsTableUpdateCompanionBuilder,
      (
        MindMapNodeRecord,
        BaseReferences<
          _$FoundationDatabase,
          $MindMapNodeRecordsTable,
          MindMapNodeRecord
        >,
      ),
      MindMapNodeRecord,
      PrefetchHooks Function()
    >;
typedef $$MindMapParentSlotsTableCreateCompanionBuilder =
    MindMapParentSlotsCompanion Function({
      required String accountId,
      required String mapId,
      required String childNodeId,
      required String parentNodeId,
      required String appearanceJson,
      required String revisionId,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MindMapParentSlotsTableUpdateCompanionBuilder =
    MindMapParentSlotsCompanion Function({
      Value<String> accountId,
      Value<String> mapId,
      Value<String> childNodeId,
      Value<String> parentNodeId,
      Value<String> appearanceJson,
      Value<String> revisionId,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MindMapParentSlotsTableFilterComposer
    extends Composer<_$FoundationDatabase, $MindMapParentSlotsTable> {
  $$MindMapParentSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childNodeId => $composableBuilder(
    column: $table.childNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentNodeId => $composableBuilder(
    column: $table.parentNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MindMapParentSlotsTableOrderingComposer
    extends Composer<_$FoundationDatabase, $MindMapParentSlotsTable> {
  $$MindMapParentSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childNodeId => $composableBuilder(
    column: $table.childNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentNodeId => $composableBuilder(
    column: $table.parentNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MindMapParentSlotsTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $MindMapParentSlotsTable> {
  $$MindMapParentSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mapId =>
      $composableBuilder(column: $table.mapId, builder: (column) => column);

  GeneratedColumn<String> get childNodeId => $composableBuilder(
    column: $table.childNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentNodeId => $composableBuilder(
    column: $table.parentNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MindMapParentSlotsTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $MindMapParentSlotsTable,
          MindMapParentSlot,
          $$MindMapParentSlotsTableFilterComposer,
          $$MindMapParentSlotsTableOrderingComposer,
          $$MindMapParentSlotsTableAnnotationComposer,
          $$MindMapParentSlotsTableCreateCompanionBuilder,
          $$MindMapParentSlotsTableUpdateCompanionBuilder,
          (
            MindMapParentSlot,
            BaseReferences<
              _$FoundationDatabase,
              $MindMapParentSlotsTable,
              MindMapParentSlot
            >,
          ),
          MindMapParentSlot,
          PrefetchHooks Function()
        > {
  $$MindMapParentSlotsTableTableManager(
    _$FoundationDatabase db,
    $MindMapParentSlotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MindMapParentSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MindMapParentSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MindMapParentSlotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> mapId = const Value.absent(),
                Value<String> childNodeId = const Value.absent(),
                Value<String> parentNodeId = const Value.absent(),
                Value<String> appearanceJson = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapParentSlotsCompanion(
                accountId: accountId,
                mapId: mapId,
                childNodeId: childNodeId,
                parentNodeId: parentNodeId,
                appearanceJson: appearanceJson,
                revisionId: revisionId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String mapId,
                required String childNodeId,
                required String parentNodeId,
                required String appearanceJson,
                required String revisionId,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapParentSlotsCompanion.insert(
                accountId: accountId,
                mapId: mapId,
                childNodeId: childNodeId,
                parentNodeId: parentNodeId,
                appearanceJson: appearanceJson,
                revisionId: revisionId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MindMapParentSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $MindMapParentSlotsTable,
      MindMapParentSlot,
      $$MindMapParentSlotsTableFilterComposer,
      $$MindMapParentSlotsTableOrderingComposer,
      $$MindMapParentSlotsTableAnnotationComposer,
      $$MindMapParentSlotsTableCreateCompanionBuilder,
      $$MindMapParentSlotsTableUpdateCompanionBuilder,
      (
        MindMapParentSlot,
        BaseReferences<
          _$FoundationDatabase,
          $MindMapParentSlotsTable,
          MindMapParentSlot
        >,
      ),
      MindMapParentSlot,
      PrefetchHooks Function()
    >;
typedef $$MindMapSideLinksTableCreateCompanionBuilder =
    MindMapSideLinksCompanion Function({
      required String accountId,
      required String mapId,
      required String firstNodeId,
      required String secondNodeId,
      required String appearanceJson,
      required String revisionId,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MindMapSideLinksTableUpdateCompanionBuilder =
    MindMapSideLinksCompanion Function({
      Value<String> accountId,
      Value<String> mapId,
      Value<String> firstNodeId,
      Value<String> secondNodeId,
      Value<String> appearanceJson,
      Value<String> revisionId,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MindMapSideLinksTableFilterComposer
    extends Composer<_$FoundationDatabase, $MindMapSideLinksTable> {
  $$MindMapSideLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstNodeId => $composableBuilder(
    column: $table.firstNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondNodeId => $composableBuilder(
    column: $table.secondNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MindMapSideLinksTableOrderingComposer
    extends Composer<_$FoundationDatabase, $MindMapSideLinksTable> {
  $$MindMapSideLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapId => $composableBuilder(
    column: $table.mapId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstNodeId => $composableBuilder(
    column: $table.firstNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondNodeId => $composableBuilder(
    column: $table.secondNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MindMapSideLinksTableAnnotationComposer
    extends Composer<_$FoundationDatabase, $MindMapSideLinksTable> {
  $$MindMapSideLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get mapId =>
      $composableBuilder(column: $table.mapId, builder: (column) => column);

  GeneratedColumn<String> get firstNodeId => $composableBuilder(
    column: $table.firstNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondNodeId => $composableBuilder(
    column: $table.secondNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appearanceJson => $composableBuilder(
    column: $table.appearanceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MindMapSideLinksTableTableManager
    extends
        RootTableManager<
          _$FoundationDatabase,
          $MindMapSideLinksTable,
          MindMapSideLink,
          $$MindMapSideLinksTableFilterComposer,
          $$MindMapSideLinksTableOrderingComposer,
          $$MindMapSideLinksTableAnnotationComposer,
          $$MindMapSideLinksTableCreateCompanionBuilder,
          $$MindMapSideLinksTableUpdateCompanionBuilder,
          (
            MindMapSideLink,
            BaseReferences<
              _$FoundationDatabase,
              $MindMapSideLinksTable,
              MindMapSideLink
            >,
          ),
          MindMapSideLink,
          PrefetchHooks Function()
        > {
  $$MindMapSideLinksTableTableManager(
    _$FoundationDatabase db,
    $MindMapSideLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MindMapSideLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MindMapSideLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MindMapSideLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> mapId = const Value.absent(),
                Value<String> firstNodeId = const Value.absent(),
                Value<String> secondNodeId = const Value.absent(),
                Value<String> appearanceJson = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapSideLinksCompanion(
                accountId: accountId,
                mapId: mapId,
                firstNodeId: firstNodeId,
                secondNodeId: secondNodeId,
                appearanceJson: appearanceJson,
                revisionId: revisionId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String mapId,
                required String firstNodeId,
                required String secondNodeId,
                required String appearanceJson,
                required String revisionId,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MindMapSideLinksCompanion.insert(
                accountId: accountId,
                mapId: mapId,
                firstNodeId: firstNodeId,
                secondNodeId: secondNodeId,
                appearanceJson: appearanceJson,
                revisionId: revisionId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MindMapSideLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$FoundationDatabase,
      $MindMapSideLinksTable,
      MindMapSideLink,
      $$MindMapSideLinksTableFilterComposer,
      $$MindMapSideLinksTableOrderingComposer,
      $$MindMapSideLinksTableAnnotationComposer,
      $$MindMapSideLinksTableCreateCompanionBuilder,
      $$MindMapSideLinksTableUpdateCompanionBuilder,
      (
        MindMapSideLink,
        BaseReferences<
          _$FoundationDatabase,
          $MindMapSideLinksTable,
          MindMapSideLink
        >,
      ),
      MindMapSideLink,
      PrefetchHooks Function()
    >;

class $FoundationDatabaseManager {
  final _$FoundationDatabase _db;
  $FoundationDatabaseManager(this._db);
  $$FoundationPreferencesTableTableManager get foundationPreferences =>
      $$FoundationPreferencesTableTableManager(_db, _db.foundationPreferences);
  $$LocalRecordsTableTableManager get localRecords =>
      $$LocalRecordsTableTableManager(_db, _db.localRecords);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(_db, _db.pendingChanges);
  $$ConflictRecordsTableTableManager get conflictRecords =>
      $$ConflictRecordsTableTableManager(_db, _db.conflictRecords);
  $$MigrationJournalTableTableManager get migrationJournal =>
      $$MigrationJournalTableTableManager(_db, _db.migrationJournal);
  $$FoundationAuditLogTableTableManager get foundationAuditLog =>
      $$FoundationAuditLogTableTableManager(_db, _db.foundationAuditLog);
  $$TaskRecordsTableTableManager get taskRecords =>
      $$TaskRecordsTableTableManager(_db, _db.taskRecords);
  $$XpAwardsTableTableManager get xpAwards =>
      $$XpAwardsTableTableManager(_db, _db.xpAwards);
  $$HabitRecordsTableTableManager get habitRecords =>
      $$HabitRecordsTableTableManager(_db, _db.habitRecords);
  $$HabitDayRecordsTableTableManager get habitDayRecords =>
      $$HabitDayRecordsTableTableManager(_db, _db.habitDayRecords);
  $$MindMapRecordsTableTableManager get mindMapRecords =>
      $$MindMapRecordsTableTableManager(_db, _db.mindMapRecords);
  $$MindMapNodeRecordsTableTableManager get mindMapNodeRecords =>
      $$MindMapNodeRecordsTableTableManager(_db, _db.mindMapNodeRecords);
  $$MindMapParentSlotsTableTableManager get mindMapParentSlots =>
      $$MindMapParentSlotsTableTableManager(_db, _db.mindMapParentSlots);
  $$MindMapSideLinksTableTableManager get mindMapSideLinks =>
      $$MindMapSideLinksTableTableManager(_db, _db.mindMapSideLinks);
}
