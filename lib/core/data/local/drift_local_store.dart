/// Local Store adapter over the encrypted Drift database.
///
/// Contract guarantees enforced here (contracts/local-persistence.md): the
/// local change and its pending operation commit in one transaction; a
/// failed transaction changes neither visible state nor the outbox; an
/// acknowledged operation cannot return to pending; a retry preserves the
/// operation ID.
library;

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/sync_versions.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/foundation_sync_state.dart';
import 'package:namma_project/core/domain/values/version_source.dart';

AppFailure _persistenceFailure(String summary) {
  final occurredAt = DateTime.now().toUtc();
  return AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: kDatabaseUnreadableMessageKey,
    occurredAt: occurredAt,
    technicalCause: summary,
  );
}

/// Local Store implementation over [FoundationDatabase].
class DriftLocalStore implements LocalStorePort {
  DriftLocalStore(this.database);

  final FoundationDatabase database;

  @override
  Future<AppResult<String?>> readPreference(String key) async {
    try {
      final row = await (database.select(
        database.foundationPreferences,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      return AppResult<String?>.success(row?.value);
    } catch (error) {
      return AppResult<String?>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    try {
      await database
          .into(database.foundationPreferences)
          .insertOnConflictUpdate(
            FoundationPreferencesCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async {
    try {
      await database.transaction(() async {
        switch (pending.kind) {
          case ChangeKind.create:
            await database
                .into(database.localRecords)
                .insert(
                  LocalRecordsCompanion.insert(
                    recordId: change.recordId,
                    accountId: Value(change.accountId),
                    payload: change.payload,
                    versionTimestamp: change.versionTimestamp,
                    syncState: FoundationSyncState.pending,
                    updatedAt: DateTime.now().toUtc(),
                  ),
                );
          case ChangeKind.update:
            final existing =
                await (database.select(database.localRecords)
                      ..where((t) => t.recordId.equals(change.recordId)))
                    .getSingleOrNull();
            if (existing == null) {
              throw StateError(
                'cannot update non-existent record ${change.recordId}',
              );
            }
            await (database.update(
              database.localRecords,
            )..where((t) => t.recordId.equals(change.recordId))).write(
              LocalRecordsCompanion(
                accountId: Value(change.accountId),
                payload: Value(change.payload),
                versionTimestamp: Value(change.versionTimestamp),
                syncState: const Value(FoundationSyncState.pending),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
          case ChangeKind.delete:
            await (database.delete(
              database.localRecords,
            )..where((t) => t.recordId.equals(change.recordId))).go();
        }

        await database
            .into(database.pendingChanges)
            .insert(
              PendingChangesCompanion.insert(
                operationId: pending.operationId,
                accountId: pending.accountId,
                entityType: pending.entityType,
                entityId: pending.entityId,
                kind: pending.kind,
                state: PendingChangeState.pending,
                serializedChange: pending.serializedChange,
                createdAt: pending.createdAt,
                versionTimestamp: pending.versionTimestamp,
              ),
            );
      });
      return AppResult<void>.success(null);
    } catch (error) {
      // The transaction rolled back: neither visible state nor the outbox
      // changed.
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async {
    try {
      final query = database.select(database.pendingChanges)
        ..where(
          (t) =>
              t.accountId.equals(accountId) &
              t.state.equals(PendingChangeState.pending.index),
        )
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
      final rows = await query.get();
      return AppResult<List<PendingChangeRecord>>.success(
        rows.map(_recordFromRow).toList(growable: false),
      );
    } catch (error) {
      return AppResult<List<PendingChangeRecord>>.failure(
        _persistenceFailure('$error'),
      );
    }
  }

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
    DateTime acknowledgedVersion,
  ) async {
    try {
      await database.transaction(() async {
        final row = await (database.select(
          database.pendingChanges,
        )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
        if (row == null || row.state == PendingChangeState.acknowledged) {
          // Missing or already acknowledged (terminal): never re-acknowledge.
          throw StateError('operation $operationId is not acknowledgeable');
        }
        await (database.update(
          database.pendingChanges,
        )..where((t) => t.operationId.equals(operationId))).write(
          PendingChangesCompanion(
            state: const Value(PendingChangeState.acknowledged),
            acknowledgementId: Value(acknowledgementId),
          ),
        );
        await _rebaseNextPending(row, acknowledgedVersion);
        if (row.entityType == 'foundation_record') {
          await (database.update(
            database.localRecords,
          )..where((t) => t.recordId.equals(row.entityId))).write(
            LocalRecordsCompanion(
              syncState: const Value(FoundationSyncState.acknowledged),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      });
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> recordRecoverableFailure(
    String operationId,
    String summary,
  ) async {
    try {
      final row = await (database.select(
        database.pendingChanges,
      )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
      if (row == null || row.state != PendingChangeState.pending) {
        return AppResult<void>.failure(
          _persistenceFailure('operation $operationId is not pending'),
        );
      }
      await (database.update(
        database.pendingChanges,
      )..where((t) => t.operationId.equals(operationId))).write(
        PendingChangesCompanion(
          attemptCount: Value(row.attemptCount + 1),
          lastFailureSummary: Value(summary),
        ),
      );
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> markChangeConflicted(String operationId) async {
    try {
      final updated =
          await (database.update(
            database.pendingChanges,
          )..where((t) => t.operationId.equals(operationId))).write(
            PendingChangesCompanion(
              state: const Value(PendingChangeState.conflict),
            ),
          );
      if (updated == 0) {
        return AppResult<void>.failure(
          _persistenceFailure('operation $operationId is missing'),
        );
      }
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async {
    try {
      final existing =
          await (database.select(
                database.conflictRecords,
              )..where((table) => table.conflictId.equals(conflict.conflictId)))
              .getSingleOrNull();
      if (existing != null) {
        _requireSameClash(existing, conflict);
        return AppResult<void>.success(null);
      }
      await database
          .into(database.conflictRecords)
          .insert(
            ConflictRecordsCompanion.insert(
              conflictId: conflict.conflictId,
              accountId: conflict.accountId,
              entityType: conflict.entityType,
              entityId: conflict.entityId,
              activeSource: conflict.activeVersion.source,
              activeTimestamp: conflict.activeVersion.versionTimestamp,
              activePayload: conflict.activeVersion.payload,
              retainedSource: conflict.retainedVersion.source,
              retainedTimestamp: conflict.retainedVersion.versionTimestamp,
              retainedPayload: conflict.retainedVersion.payload,
              detectedAt: conflict.detectedAt,
            ),
          );
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async {
    try {
      await database.transaction(() async {
        final pending = await (database.select(
          database.pendingChanges,
        )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
        if (pending == null) {
          throw StateError(
            'operation $operationId is missing to finalize conflict',
          );
        }
        final existingConflict =
            await (database.select(database.conflictRecords)
                  ..where((t) => t.conflictId.equals(conflict.conflictId)))
                .getSingleOrNull();
        if (existingConflict != null) {
          // Inbound reconciliation already recorded this same clash.
          _requireSameClash(existingConflict, conflict);
        } else {
          await database
              .into(database.conflictRecords)
              .insert(
                ConflictRecordsCompanion.insert(
                  conflictId: conflict.conflictId,
                  accountId: conflict.accountId,
                  entityType: conflict.entityType,
                  entityId: conflict.entityId,
                  activeSource: conflict.activeVersion.source,
                  activeTimestamp: conflict.activeVersion.versionTimestamp,
                  activePayload: conflict.activeVersion.payload,
                  retainedSource: conflict.retainedVersion.source,
                  retainedTimestamp: conflict.retainedVersion.versionTimestamp,
                  retainedPayload: conflict.retainedVersion.payload,
                  detectedAt: conflict.detectedAt,
                ),
              );
        }

        // The conflict record and the active local state must change together.
        // A remote winner replaces (or restores) the local record; a local
        // deletion remains deleted. Both outcomes are terminal for this
        // pending operation and preserve the non-winning version above.
        if (pending.entityType == 'foundation_record') {
          final activeIsLocalDelete =
              pending.kind == ChangeKind.delete &&
              conflict.activeVersion.source == VersionSource.local;
          if (activeIsLocalDelete) {
            await (database.delete(
              database.localRecords,
            )..where((t) => t.recordId.equals(pending.entityId))).go();
          } else {
            final existing =
                await (database.select(database.localRecords)
                      ..where((t) => t.recordId.equals(pending.entityId)))
                    .getSingleOrNull();
            final activeRecord = LocalRecordsCompanion(
              accountId: Value(pending.accountId),
              payload: Value(conflict.activeVersion.payload),
              versionTimestamp: Value(conflict.activeVersion.versionTimestamp),
              syncState: const Value(FoundationSyncState.acknowledged),
              updatedAt: Value(DateTime.now().toUtc()),
            );
            if (existing == null) {
              await database
                  .into(database.localRecords)
                  .insert(
                    activeRecord.copyWith(recordId: Value(pending.entityId)),
                  );
            } else {
              await (database.update(database.localRecords)
                    ..where((t) => t.recordId.equals(pending.entityId)))
                  .write(activeRecord);
            }
          }
        }
        final updated =
            await (database.update(
              database.pendingChanges,
            )..where((t) => t.operationId.equals(operationId))).write(
              PendingChangesCompanion(
                state: const Value(PendingChangeState.conflict),
              ),
            );
        if (updated != 1) {
          throw StateError('operation $operationId was not finalized');
        }
        // The server now holds the active version, whichever side won. The
        // next queued edit must be compared against that, not the loser.
        await _rebaseNextPending(
          pending,
          conflict.activeVersion.versionTimestamp,
        );
      });
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_persistenceFailure('$error'));
    }
  }

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async {
    // Schema upgrades run automatically during open (T030); this reports the
    // completed outcome for the database as opened.
    if (targetSchemaVersion != database.schemaVersion) {
      return AppResult<MigrationOutcome>.failure(
        _persistenceFailure(
          'target schema version $targetSchemaVersion does not match the '
          'opened schema version ${database.schemaVersion}',
        ),
      );
    }
    return AppResult<MigrationOutcome>.success(
      MigrationOutcome(
        completedVersion: database.schemaVersion,
        recovered: false,
      ),
    );
  }

  PendingChangeRecord _recordFromRow(PendingChange row) => PendingChangeRecord(
    operationId: row.operationId,
    accountId: row.accountId,
    entityType: row.entityType,
    entityId: row.entityId,
    kind: row.kind,
    state: row.state,
    attemptCount: row.attemptCount,
    lastFailureSummary: row.lastFailureSummary,
    serializedChange: row.serializedChange,
    createdAt: row.createdAt,
    versionTimestamp: row.versionTimestamp,
    baseUpdatedAt: row.baseUpdatedAt,
  );

  /// Points the next queued edit to [row]'s entity at [serverVersion], the
  /// version the server holds once [row] has been resolved.
  Future<void> _rebaseNextPending(
    PendingChange row,
    DateTime serverVersion,
  ) async {
    final next =
        await (database.select(database.pendingChanges)
              ..where(
                (t) =>
                    t.accountId.equals(row.accountId) &
                    t.entityType.equals(row.entityType) &
                    t.entityId.equals(row.entityId) &
                    t.state.equals(PendingChangeState.pending.index) &
                    t.operationId.equals(row.operationId).not() &
                    t.createdAt.isBiggerOrEqualValue(row.createdAt),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (next == null) return;
    await (database.update(database.pendingChanges)
          ..where((t) => t.operationId.equals(next.operationId)))
        .write(PendingChangesCompanion(baseUpdatedAt: Value(serverVersion)));
  }

  /// A conflict ID names one clash: one record and two version timestamps.
  /// The same clash can be detected by inbound and outbound sync with
  /// differently formatted payloads, so payloads are not compared.
  static void _requireSameClash(
    ConflictRecord existing,
    ConflictRecordInput conflict,
  ) {
    final same =
        existing.accountId == conflict.accountId &&
        existing.entityType == conflict.entityType &&
        existing.entityId == conflict.entityId &&
        existing.activeSource == conflict.activeVersion.source &&
        existing.retainedSource == conflict.retainedVersion.source &&
        _sameInstant(
          existing.activeTimestamp,
          conflict.activeVersion.versionTimestamp,
        ) &&
        _sameInstant(
          existing.retainedTimestamp,
          conflict.retainedVersion.versionTimestamp,
        ) &&
        canonicalSyncPayload(existing.activePayload) ==
            canonicalSyncPayload(conflict.activeVersion.payload) &&
        canonicalSyncPayload(existing.retainedPayload) ==
            canonicalSyncPayload(conflict.retainedVersion.payload);
    if (!same) {
      throw StateError('conflict id identifies different versions');
    }
  }

  static bool _sameInstant(DateTime left, DateTime right) =>
      left.toUtc().microsecondsSinceEpoch ==
      right.toUtc().microsecondsSinceEpoch;
}
