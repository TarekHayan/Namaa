import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/sync_versions.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/tasks/application/task_reconciliation.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Merges a complete remote snapshot into one local account partition while
/// retaining every losing version as visible conflict evidence.
final class TaskReconciler implements TaskReconciliationPort {
  TaskReconciler({
    required TaskRepository repository,
    required LocalStorePort localStore,
    required TaskPayloadCodec codec,
    DateTime Function()? detectedAt,
  }) : _repository = repository,
       _localStore = localStore,
       _codec = codec,
       _detectedAt = detectedAt ?? _utcNow;

  final TaskRepository _repository;
  final LocalStorePort _localStore;
  final TaskPayloadCodec _codec;
  final DateTime Function() _detectedAt;

  @override
  Future<AppResult<TaskReconciliationSummary>> reconcile({
    required String accountId,
    required List<Task> remoteTasks,
  }) async {
    if (remoteTasks.any((task) => task.accountId != accountId)) {
      return AppResult<TaskReconciliationSummary>.failure(
        _failure(AppFailureCategory.authorization, 'tasks.sync.owner_mismatch'),
      );
    }

    return _repository.runInTransaction(
      () => _reconcileAtomically(accountId, remoteTasks),
    );
  }

  Future<AppResult<TaskReconciliationSummary>> _reconcileAtomically(
    String accountId,
    List<Task> remoteTasks,
  ) async {
    var imported = 0;
    var conflictsRecorded = 0;
    var equalTimestampConflicts = 0;

    final pendingRead = await _localStore.readPendingChanges(accountId);
    if (pendingRead.failureOrNull case final failure?) {
      return AppResult<TaskReconciliationSummary>.failure(failure);
    }
    final pendingVersions = PendingSyncVersions.index(pendingRead.valueOrNull!);

    for (final remote in remoteTasks) {
      final localResult = await _repository.readTask(
        accountId: accountId,
        taskId: remote.id,
      );
      final localFailure = localResult.failureOrNull;
      if (localFailure != null) {
        return AppResult<TaskReconciliationSummary>.failure(localFailure);
      }
      final local = localResult.valueOrNull;
      if (local == null) {
        final applied = await _repository.applyInboundTask(remote);
        if (applied.failureOrNull != null) {
          return AppResult<TaskReconciliationSummary>.failure(
            applied.failureOrNull!,
          );
        }
        imported++;
        continue;
      }

      final pending = await _repository.hasPendingChange(
        accountId: accountId,
        taskId: remote.id,
      );
      if (pending.failureOrNull != null) {
        return AppResult<TaskReconciliationSummary>.failure(
          pending.failureOrNull!,
        );
      }
      final localPayload = _codec.encode(local);
      final remotePayload = _codec.encode(remote);
      if (localPayload == remotePayload) {
        continue;
      }

      // A remote snapshot is an ordinary update unless this device still has
      // an unacknowledged edit to the same Task. Preserve that edit for upload.
      if (pending.valueOrNull != true) {
        if (remote.updatedAt.isAfter(local.updatedAt)) {
          final applied = await _repository.applyInboundTask(remote);
          if (applied.failureOrNull != null) {
            return AppResult<TaskReconciliationSummary>.failure(
              applied.failureOrNull!,
            );
          }
          imported++;
          continue;
        }
      } else if (!remote.updatedAt.isAtSameMomentAs(local.updatedAt) &&
          (pendingVersions[(kTaskEntityType, remote.id)]?.knows(
                remote.updatedAt,
              ) ??
              false)) {
        // Remote is the version the queued edit started from (or that edit's
        // own upload). Nothing clashed: keep local and let the outbox send it.
        continue;
      }

      final detectedAt = _detectedAt();
      if (!detectedAt.isUtc) {
        return AppResult<TaskReconciliationSummary>.failure(
          _failure(
            AppFailureCategory.configuration,
            'tasks.sync.invalid_clock',
          ),
        );
      }

      late final RecordVersionInput active;
      late final RecordVersionInput retained;
      Task? inboundWinner;
      if (remote.updatedAt.isAfter(local.updatedAt)) {
        active = _version(VersionSource.remote, remote, remotePayload);
        retained = _version(VersionSource.local, local, localPayload);
        inboundWinner = remote;
      } else if (local.updatedAt.isAfter(remote.updatedAt)) {
        active = _version(VersionSource.local, local, localPayload);
        retained = _version(VersionSource.remote, remote, remotePayload);
      } else {
        active = _version(VersionSource.local, local, localPayload);
        retained = _version(VersionSource.remote, remote, remotePayload);
        equalTimestampConflicts++;
      }

      final conflict = await _localStore.recordConflict(
        ConflictRecordInput(
          conflictId: syncConflictId(
            accountId: accountId,
            entityType: kTaskEntityType,
            entityId: remote.id,
            activeAt: active.versionTimestamp,
            retainedAt: retained.versionTimestamp,
            activePayload: active.payload,
            retainedPayload: retained.payload,
          ),
          accountId: accountId,
          entityType: kTaskEntityType,
          entityId: remote.id,
          activeVersion: active,
          retainedVersion: retained,
          detectedAt: detectedAt,
        ),
      );
      if (conflict.failureOrNull != null) {
        return AppResult<TaskReconciliationSummary>.failure(
          conflict.failureOrNull!,
        );
      }
      conflictsRecorded++;

      if (inboundWinner != null) {
        final applied = await _repository.applyInboundTask(inboundWinner);
        if (applied.failureOrNull != null) {
          return AppResult<TaskReconciliationSummary>.failure(
            applied.failureOrNull!,
          );
        }
      }
    }

    return AppResult<TaskReconciliationSummary>.success(
      TaskReconciliationSummary(
        imported: imported,
        conflictsRecorded: conflictsRecorded,
        equalTimestampConflicts: equalTimestampConflicts,
      ),
    );
  }

  RecordVersionInput _version(
    VersionSource source,
    Task task,
    String payload,
  ) => RecordVersionInput(
    source: source,
    versionTimestamp: task.updatedAt,
    payload: payload,
  );

  static DateTime _utcNow() => DateTime.now().toUtc();

  static AppFailure _failure(AppFailureCategory category, String messageKey) =>
      AppFailure.blocking(
        category: category,
        messageKey: messageKey,
        occurredAt: DateTime.now().toUtc(),
      );
}
