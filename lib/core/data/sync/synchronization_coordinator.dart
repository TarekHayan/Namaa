/// The durable outbox retry coordinator.
///
/// One pass reads pending operations, dispatches each with its stable
/// operation ID, durably records the outcome before completion
/// (contracts/synchronization.md): acknowledgements are terminal, recoverable
/// failures return the operation to pending with retry metadata, and version
/// conflicts persist retained evidence and mark the operation conflicted so
/// it is never re-dispatched. Equal timestamps stay open and recoverable.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';

export 'package:namma_project/core/application/synchronization_engine.dart'
    show SyncSummary;

/// Drives the durable outbox through the Local Store and Cloud Sync ports.
class SynchronizationCoordinator implements PendingSynchronizationEngine {
  SynchronizationCoordinator({
    required LocalStorePort localStore,
    required CloudSessionPort cloudSession,
    required CloudSyncPort cloudSync,
    DateTime Function()? now,
  }) : _localStore = localStore,
       _cloudSession = cloudSession,
       _cloudSync = cloudSync,
       _now = now ?? _defaultNow;

  final LocalStorePort _localStore;
  final CloudSessionPort _cloudSession;
  final CloudSyncPort _cloudSync;
  final DateTime Function() _now;

  static DateTime _defaultNow() => DateTime.now().toUtc();

  @override
  Future<AppResult<SyncSummary>> synchronize() async {
    final context = await _cloudSession.obtainSyncContext();
    final contextFailure = context.failureOrNull;
    if (contextFailure != null) {
      return AppResult<SyncSummary>.failure(contextFailure);
    }
    final accountId = context.valueOrNull!.accountId;

    final pendingResult = await _localStore.readPendingChanges(accountId);
    final pendingFailure = pendingResult.failureOrNull;
    if (pendingFailure != null) {
      return AppResult<SyncSummary>.failure(pendingFailure);
    }

    var acknowledged = 0;
    var conflictsRecorded = 0;
    var equalTimestampConflicts = 0;
    var recoverableFailures = 0;

    for (final record in pendingResult.valueOrNull!) {
      if (record.state != PendingChangeState.pending) {
        continue;
      }
      final dispatch = await _cloudSync.dispatchChange(
        OutboundChange(
          operationId: record.operationId,
          accountId: record.accountId,
          entityType: record.entityType,
          entityId: record.entityId,
          kind: record.kind,
          payload: record.serializedChange,
          versionTimestamp: record.versionTimestamp,
        ),
      );

      final dispatchFailure = dispatch.failureOrNull;
      if (dispatchFailure != null) {
        if (!dispatchFailure.recoverable) {
          return AppResult<SyncSummary>.failure(dispatchFailure);
        }
        final recorded = await _localStore.recordRecoverableFailure(
          record.operationId,
          kDispatchRecoverableMessageKey,
        );
        if (recorded.failureOrNull != null) {
          return AppResult<SyncSummary>.failure(recorded.failureOrNull!);
        }
        recoverableFailures++;
        continue;
      }

      final outcome = dispatch.valueOrNull!;
      switch (outcome) {
        case DispatchAcknowledged(:final acknowledgementId):
          final ack = await _localStore.acknowledgeChange(
            record.operationId,
            acknowledgementId,
          );
          final ackFailure = ack.failureOrNull;
          if (ackFailure != null) {
            if (!ackFailure.recoverable) {
              return AppResult<SyncSummary>.failure(ackFailure);
            }
            recoverableFailures++;
            continue;
          }
          acknowledged++;

        case DispatchVersionConflict(
          :final remoteVersionTimestamp,
          :final remotePayload,
        ):
          final resolution = resolveVersionConflict(
            local: RecordVersion(
              source: VersionSource.local,
              versionTimestamp: record.versionTimestamp,
              payload: record.serializedChange,
            ),
            remote: RecordVersion(
              source: VersionSource.remote,
              versionTimestamp: remoteVersionTimestamp,
              payload: remotePayload ?? '',
            ),
          );
          if (resolution is! NewerVersionSelected) {
            // Equal timestamps: open recoverable conflict until a separate
            // tie-breaker is approved; nothing is overwritten.
            await _localStore.recordRecoverableFailure(
              record.operationId,
              kEqualTimestampConflictMessageKey,
            );
            equalTimestampConflicts++;
            continue;
          }
          final finalized = await _localStore.recordConflictAndFinalize(
            conflict: ConflictRecordInput(
              conflictId: 'conflict-${record.operationId}',
              accountId: record.accountId,
              entityType: record.entityType,
              entityId: record.entityId,
              activeVersion: _versionInput(resolution.active),
              retainedVersion: _versionInput(resolution.retained),
              detectedAt: _now(),
            ),
            operationId: record.operationId,
          );
          if (finalized.failureOrNull != null) {
            return AppResult<SyncSummary>.failure(finalized.failureOrNull!);
          }
          conflictsRecorded++;
      }
    }

    return AppResult<SyncSummary>.success(
      SyncSummary(
        acknowledged: acknowledged,
        conflictsRecorded: conflictsRecorded,
        equalTimestampConflicts: equalTimestampConflicts,
        recoverableFailures: recoverableFailures,
      ),
    );
  }

  RecordVersionInput _versionInput(RecordVersion version) => RecordVersionInput(
    source: version.source,
    versionTimestamp: version.versionTimestamp,
    payload: version.payload,
  );
}
