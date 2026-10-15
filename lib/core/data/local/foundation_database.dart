/// Encrypted Drift database for Foundation-owned data.
///
/// The database is the local source of truth; it is opened with a key
/// obtained from the Credential Vault (never from preferences, tables, logs,
/// or failure records). SQLite3MultipleCiphers encryption is bundled through
/// the `sqlite3` build hooks (`source: sqlite3mc`) and enabled with the
/// SQLCipher-compatible `PRAGMA key`.
///
/// Migration guarantees (contracts/local-persistence.md): migrations run
/// automatically before account data is served; a failed migration retains
/// prior data and writes a non-secret Migration Journal outcome; a later
/// clean upgrade marks the failed attempt recovered.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/values/foundation_sync_state.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

part 'foundation_database.g.dart';

/// Current schema version of the Foundation database.
const int kFoundationSchemaVersion = 3;

/// Vault key under which the database key material is protected.
const String kDatabaseKeyVaultName = 'foundation.db.key';

/// Message keys for database outcomes (Arabic and English resources exist).
const String kDatabaseUnreadableMessageKey = 'foundation.database.unreadable';
const String kMigrationRecoverableMessageKey =
    'foundation.migration.recoverable';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

/// Foundation application preferences (locale, appearance); non-secret only.
class FoundationPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Foundation verification records; payloads are encrypted at rest.
class LocalRecords extends Table {
  TextColumn get recordId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get versionTimestamp => dateTime()();
  IntColumn get syncState => intEnum<FoundationSyncState>()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {recordId};
}

/// The durable outbox of pending synchronization operations.
class PendingChanges extends Table {
  TextColumn get operationId => text()();
  TextColumn get accountId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get kind => intEnum<ChangeKind>()();
  IntColumn get state => intEnum<PendingChangeState>()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastFailureSummary => text().nullable()();
  TextColumn get serializedChange => text()();
  TextColumn get acknowledgementId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get versionTimestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Retained conflict records; the non-winning version stays visible.
class ConflictRecords extends Table {
  TextColumn get conflictId => text()();
  TextColumn get accountId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get activeSource => intEnum<VersionSource>()();
  DateTimeColumn get activeTimestamp => dateTime()();
  TextColumn get activePayload => text()();
  IntColumn get retainedSource => intEnum<VersionSource>()();
  DateTimeColumn get retainedTimestamp => dateTime()();
  TextColumn get retainedPayload => text()();
  DateTimeColumn get detectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {conflictId};
}

/// The automatic migration journal (non-secret outcomes only).
class MigrationJournal extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get version => integer()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get recoveryDetail => text().nullable()();
}

/// Added in schema version 2; proves a data-preserving upgrade path.
class FoundationAuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get note => text()();
  DateTimeColumn get at => dateTime()();
}

/// Account-scoped canonical Task aggregates added in schema version 3.
///
/// Checklist items stay embedded in [checklistJson], while the fields needed
/// by list, matrix, history, overdue, and synchronization queries remain
/// ordinary columns. Dates and local wall-clock times are stored separately
/// so no device silently changes their calendar meaning.
@TableIndex(
  name: 'task_records_account_date',
  columns: {#accountId, #scheduledDate},
)
@TableIndex(
  name: 'task_records_account_category',
  columns: {#accountId, #category},
)
@TableIndex(
  name: 'task_records_account_quadrant',
  columns: {#accountId, #quadrant},
)
@TableIndex(
  name: 'task_records_account_completion',
  columns: {#accountId, #completedAt},
)
@TableIndex(
  name: 'task_records_account_updated',
  columns: {#accountId, #updatedAt},
)
@TableIndex(
  name: 'task_records_account_deleted',
  columns: {#accountId, #deletedAt},
)
class TaskRecords extends Table {
  TextColumn get accountId => text()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get scheduledDate => text()();
  TextColumn get scheduledTime => text().nullable()();
  DateTimeColumn get targetDeadline => dateTime().nullable()();
  IntColumn get targetDeadlineUtcOffsetMinutes => integer().nullable()();
  TextColumn get category => text()();
  TextColumn get quadrant => text()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  TextColumn get checklistJson =>
      text().withDefault(const Constant<String>('[]'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get completionXp => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {accountId, taskId};
}

/// Immutable shared XP ledger rows introduced with the Task schema.
///
/// The composite key is the integrity boundary: a source entity can award XP
/// at most once for one account. Later phases add the first-insert behavior;
/// this table deliberately exposes no mutable XP balance.
class XpAwards extends Table {
  TextColumn get accountId => text()();
  TextColumn get source => text()();
  TextColumn get sourceId => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get awardedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountId, source, sourceId};
}

@DriftDatabase(
  tables: [
    FoundationPreferences,
    LocalRecords,
    PendingChanges,
    ConflictRecords,
    MigrationJournal,
    FoundationAuditLog,
    TaskRecords,
    XpAwards,
  ],
)
class FoundationDatabase extends _$FoundationDatabase {
  FoundationDatabase._(
    super.e, {
    required this.resolvedPath,
    required int targetSchemaVersion,
    this.testMigrationHook,
  }) : _targetSchemaVersion = targetSchemaVersion;

  final String resolvedPath;
  final int _targetSchemaVersion;

  /// Test-only injection point for a failing migration step.
  final Future<void> Function(Migrator migrator, int from, int to)?
  testMigrationHook;

  int? _migrationAttemptedFor;

  @override
  int get schemaVersion => _targetSchemaVersion;

  /// Opens the encrypted database at [path] with [key].
  ///
  /// Throws a recoverable [AppFailure] on an unreadable file (for example a
  /// wrong key) or on a migration failure; prior data is never reset.
  static Future<FoundationDatabase> openEncrypted({
    required String path,
    required List<int> key,
    int schemaVersion = kFoundationSchemaVersion,
    Future<void> Function(Migrator migrator, int from, int to)?
    testMigrationHook,
  }) async {
    final keyPragma = _keyPragma(key);
    final executor = NativeDatabase.createInBackground(
      File(path),
      setup: (raw) => raw.execute(keyPragma),
    );
    final db = FoundationDatabase._(
      executor,
      resolvedPath: path,
      targetSchemaVersion: schemaVersion,
      testMigrationHook: testMigrationHook,
    );
    try {
      // Forces the connection open, runs migrations, and validates the key.
      await db.customSelect('SELECT count(*) FROM sqlite_master').getSingle();
    } catch (_) {
      final attempted = db._migrationAttemptedFor;
      if (attempted != null) {
        await _recordFailedMigration(path, key, attempted);
      }
      await db.close();
      throw attempted == null
          ? AppFailure.recoverable(
              category: AppFailureCategory.persistence,
              messageKey: kDatabaseUnreadableMessageKey,
              occurredAt: DateTime.now().toUtc(),
            )
          : AppFailure.recoverable(
              category: AppFailureCategory.migration,
              messageKey: kMigrationRecoverableMessageKey,
              occurredAt: DateTime.now().toUtc(),
              technicalCause:
                  'prior data retained; recovery visible in journal',
            );
    }
    return db;
  }

  /// Builds the SQLCipher-compatible raw-key pragma for sqlite3mc.
  static String _keyPragma(List<int> key) {
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return "PRAGMA key = \"x'$hex'\"";
  }

  /// Writes a `failed` journal row through a raw connection. The in-database
  /// transaction rolled back, so the row is written after the fact; failure
  /// to write it is swallowed (the open error is the primary outcome).
  static Future<void> _recordFailedMigration(
    String path,
    List<int> key,
    int version,
  ) async {
    sqlite3.Database? raw;
    try {
      raw = sqlite3.sqlite3.open(path);
      raw.execute(_keyPragma(key));
      final startedAt = DateTime.now().toUtc().toIso8601String();
      raw.execute(
        'INSERT INTO migration_journal (version, status, started_at, '
        "recovery_detail) VALUES ($version, 'failed', '$startedAt', "
        "'migration failed; prior data retained')",
      );
    } catch (_) {
      // Best effort only; the open failure is reported regardless.
    } finally {
      raw?.close();
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      // A fresh create is recorded as a completed journal entry.
      await _recordJournalStep(schemaVersion);
    },
    onUpgrade: (migrator, from, to) async {
      _migrationAttemptedFor = to;
      await _recordJournalStart(to);
      if ((to >= 2 && from < 2) || (to >= 3 && from < 3)) {
        await testMigrationHook?.call(migrator, from, to);
      }
      if (to >= 2 && from < 2) {
        await migrator.createTable(foundationAuditLog);
      }
      if (to >= 3 && from < 3) {
        await migrator.createTable(taskRecords);
        await migrator.createTable(xpAwards);
        for (final index in <Index>[
          taskRecordsAccountDate,
          taskRecordsAccountCategory,
          taskRecordsAccountQuadrant,
          taskRecordsAccountCompletion,
          taskRecordsAccountUpdated,
          taskRecordsAccountDeleted,
        ]) {
          await _createIndexIfMissing(migrator, index);
        }
      }
      await _recordJournalComplete(to);
    },
    beforeOpen: (details) async {
      // A prior failed attempt at this version is now recovered.
      await customUpdate(
        'UPDATE migration_journal SET status = ?, recovery_detail = ? '
        'WHERE version = ? AND status = ?',
        variables: [
          const Variable('recovered'),
          const Variable('subsequent open succeeded'),
          Variable.withInt(schemaVersion),
          const Variable('failed'),
        ],
      );
    },
  );

  Future<void> _createIndexIfMissing(Migrator migrator, Index index) async {
    final existing = await customSelect(
      'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      variables: [
        const Variable('index'),
        Variable.withString(index.entityName),
      ],
    ).getSingleOrNull();
    if (existing == null) {
      await migrator.createIndex(index);
    }
  }

  Future<void> _recordJournalStart(int version) {
    final startedAt = DateTime.now().toUtc();
    return into(migrationJournal).insert(
      MigrationJournalCompanion.insert(
        version: version,
        status: 'started',
        startedAt: startedAt,
      ),
    );
  }

  Future<void> _recordJournalComplete(int version) {
    final endedAt = DateTime.now().toUtc();
    return customUpdate(
      'UPDATE migration_journal SET status = ?, ended_at = ? '
      'WHERE version = ? AND status = ?',
      variables: [
        const Variable('completed'),
        Variable.withDateTime(endedAt),
        Variable.withInt(version),
        const Variable('started'),
      ],
    );
  }

  /// A fresh create is recorded as a completed journal entry.
  Future<void> _recordJournalStep(int version) {
    final startedAt = DateTime.now().toUtc();
    return into(migrationJournal).insert(
      MigrationJournalCompanion.insert(
        version: version,
        status: 'completed',
        startedAt: startedAt,
        endedAt: Value(startedAt),
      ),
    );
  }

  // -- Test/verification helpers -------------------------------------------

  /// Runs a raw statement outside the typed API (verification helpers).
  Future<void> rawExecute(String statement) => customStatement(statement);

  /// Reads a single scalar value (verification helper).
  Future<Object?> rawScalar(String statement) async =>
      (await customSelect(statement).getSingle()).data.values.first;

  /// Journal status recorded for [version].
  ///
  /// A `recovered` row wins: it proves a prior failed attempt at this
  /// version was followed by a clean open. Otherwise the most recent row
  /// wins.
  Future<String?> journalStatusFor(int version) async {
    final row = await customSelect(
      'SELECT status FROM migration_journal WHERE version = ? '
      "ORDER BY (status = 'recovered') DESC, started_at DESC, id DESC "
      'LIMIT 1',
      variables: [Variable.withInt(version)],
    ).getSingleOrNull();
    return row?.data['status'] as String?;
  }

  /// Count of local records with [recordId].
  Future<int> localRecordCount(String recordId) async {
    final row = await customSelect(
      'SELECT count(*) AS c FROM local_records WHERE record_id = ?',
      variables: [Variable.withString(recordId)],
    ).getSingle();
    return row.data['c'] as int;
  }
}

/// Resolves or creates the database key through the Credential Vault.
///
/// The key is generated once from a secure random source, stored only in
/// OS-protected storage, and never logged or persisted elsewhere.
Future<List<int>> resolveDatabaseKey(CredentialVaultPort vault) async {
  final stored = await vault.readSecret(kDatabaseKeyVaultName);
  final existing = stored.valueOrNull;
  if (existing != null && existing.isNotEmpty) {
    return _hexToBytes(existing);
  }
  if (stored.failureOrNull != null) {
    // Key access failure must not produce an unencrypted replacement
    // database (local-persistence contract, rule 3).
    throw stored.failureOrNull!;
  }
  final key = List<int>.generate(32, (i) => Random.secure().nextInt(256));
  final written = await vault.writeSecret(
    kDatabaseKeyVaultName,
    _bytesToHex(key),
  );
  final writeFailure = written.failureOrNull;
  if (writeFailure != null) {
    throw writeFailure;
  }
  return key;
}

String _bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _hexToBytes(String hex) {
  final normalized = hex.trim();
  final result = <int>[];
  for (var i = 0; i + 1 < normalized.length; i += 2) {
    result.add(int.parse(normalized.substring(i, i + 2), radix: 16));
  }
  return result;
}
