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
}
