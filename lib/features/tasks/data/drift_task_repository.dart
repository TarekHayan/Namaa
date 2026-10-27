import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Encrypted Drift implementation of the canonical account-scoped Task store.
final class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository({
    required FoundationDatabase database,
    required TaskPayloadCodec codec,
  }) : _database = database,
       _codec = codec;

  final FoundationDatabase _database;
  final TaskPayloadCodec _codec;

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) async {
    try {
      return await _database.transaction(() async {
        final result = await action();
        final failure = result.failureOrNull;
        if (failure != null) {
          throw _TaskTransactionFailure(failure);
        }
        return result;
      });
    } on _TaskTransactionFailure catch (error) {
      return AppResult<T>.failure(error.failure);
    } catch (error) {
      return AppResult<T>.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async {
    try {
      final row =
          await (_database.select(_database.taskRecords)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.taskId.equals(taskId),
              ))
              .getSingleOrNull();
      return AppResult<Task?>.success(row == null ? null : _fromRow(row));
    } catch (error) {
      return AppResult<Task?>.failure(_failure(error));
    }
  }

  @override
  Stream<List<Task>> watchTasks(String accountId) {
    final query = _database.select(_database.taskRecords)
      ..where(
        (table) => table.accountId.equals(accountId) & table.deletedAt.isNull(),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.scheduledDate),
        (table) => OrderingTerm.asc(table.createdAt),
        (table) => OrderingTerm.asc(table.taskId),
      ]);
    return query.watch().map(
      (rows) => List<Task>.unmodifiable(rows.map(_fromRow)),
    );
  }

  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) {
    final query = _database.select(_database.conflictRecords)
      ..where(
        (table) =>
            table.accountId.equals(accountId) &
            table.entityType.equals(kTaskEntityType),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.detectedAt)]);
    return query.watch().map(
      (rows) => List<TaskConflictRecord>.unmodifiable(
        rows.map(
          (row) => TaskConflictRecord(
            id: row.conflictId,
            taskId: row.entityId,
            activeTitle: _conflictTitle(row.activePayload),
            retainedTitle: _conflictTitle(row.retainedPayload),
          ),
        ),
      ),
    );
  }

  String _conflictTitle(String payload) {
    try {
      return _codec.decode(payload).title;
    } catch (_) {
      return '';
    }
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    try {
      final task = request.task;
      final payload = _codec.encode(task);
      await _database.transaction(() async {
        final existingOperation =
            await (_database.select(_database.pendingChanges)..where(
                  (table) => table.operationId.equals(request.operationId),
                ))
                .getSingleOrNull();
        if (existingOperation != null) {
          final isSameLogicalWrite =
              existingOperation.accountId == task.accountId &&
              existingOperation.entityType == kTaskEntityType &&
              existingOperation.entityId == task.id &&
              existingOperation.kind == request.kind &&
              existingOperation.serializedChange == payload &&
              existingOperation.versionTimestamp == task.updatedAt;
          if (!isSameLogicalWrite) {
            throw StateError(
              'operation ${request.operationId} already identifies another write',
            );
          }
          return;
        }

        final existingTask =
            await (_database.select(_database.taskRecords)..where(
                  (table) =>
                      table.accountId.equals(task.accountId) &
                      table.taskId.equals(task.id),
                ))
                .getSingleOrNull();
        await _database
            .into(_database.taskRecords)
            .insertOnConflictUpdate(_toCompanion(task));
        await _database
            .into(_database.pendingChanges)
            .insert(
              PendingChangesCompanion.insert(
                operationId: request.operationId,
                accountId: task.accountId,
                entityType: kTaskEntityType,
                entityId: task.id,
                kind: request.kind,
                state: PendingChangeState.pending,
                serializedChange: payload,
                createdAt: request.queuedAt,
                versionTimestamp: task.updatedAt,
                baseUpdatedAt: Value(existingTask?.updatedAt),
              ),
            );
      });
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async {
    try {
      final row =
          await (_database.select(_database.pendingChanges)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.entityType.equals(kTaskEntityType) &
                    table.entityId.equals(taskId) &
                    table.state.equals(PendingChangeState.pending.index),
              ))
              .get();
      return AppResult<bool>.success(row.isNotEmpty);
    } catch (error) {
      return AppResult<bool>.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    try {
      await _database
          .into(_database.taskRecords)
          .insertOnConflictUpdate(_toCompanion(task));
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_failure(error));
    }
  }

  TaskRecordsCompanion _toCompanion(Task task) {
    final payload = jsonDecode(_codec.encode(task)) as Map<String, dynamic>;
    return TaskRecordsCompanion.insert(
      accountId: task.accountId,
      taskId: task.id,
      title: task.title,
      description: Value(task.description),
      scheduledDate: payload['scheduledDate']! as String,
      scheduledTime: Value(payload['scheduledTime'] as String?),
      targetDeadline: Value(task.targetDeadline),
      targetDeadlineUtcOffsetMinutes: Value(
        task.targetDeadlineUtcOffsetMinutes,
      ),
      category: task.category.name,
      quadrant: payload['quadrant']! as String,
      estimatedDurationMinutes: Value(task.estimatedDurationMinutes),
      checklistJson: Value(jsonEncode(payload['checklistItems'])),
      completedAt: Value(task.completedAt),
      completionChangedAt: Value(task.completionChangedAt),
      completionXp: task.completionXp,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      deletedAt: Value(task.deletedAt),
    );
  }

  Task _fromRow(TaskRecord row) => _codec.decode(
    jsonEncode(<String, Object?>{
      'id': row.taskId,
      'accountId': row.accountId,
      'title': row.title,
      'description': row.description,
      'scheduledDate': row.scheduledDate,
      'scheduledTime': row.scheduledTime,
      'targetDeadline': row.targetDeadline?.toUtc().toIso8601String(),
      'targetDeadlineUtcOffsetMinutes': row.targetDeadlineUtcOffsetMinutes,
      'category': row.category,
      'quadrant': row.quadrant,
      'estimatedDurationMinutes': row.estimatedDurationMinutes,
      'checklistItems': jsonDecode(row.checklistJson),
      'completedAt': row.completedAt?.toUtc().toIso8601String(),
      'completionChangedAt': row.completionChangedAt?.toUtc().toIso8601String(),
      'completionXp': row.completionXp,
      'createdAt': row.createdAt.toUtc().toIso8601String(),
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: kDatabaseUnreadableMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _TaskTransactionFailure {
  const _TaskTransactionFailure(this.failure);
  final AppFailure failure;
}
