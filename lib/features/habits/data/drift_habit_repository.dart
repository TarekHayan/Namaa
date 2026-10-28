import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_reconciliation.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

/// One encrypted account partition. Every mutation and its outbox entry commit
/// in the same Drift transaction.
final class DriftHabitRepository
    implements
        HabitRepository,
        HabitReconciliationStorePort,
        HabitConflictReaderPort {
  DriftHabitRepository({
    required FoundationDatabase database,
    required HabitPayloadCodec codec,
  }) : _database = database,
       _codec = codec;

  final FoundationDatabase _database;
  final HabitPayloadCodec _codec;

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) async {
    try {
      return await _database.transaction(() async {
        final result = await action();
        if (result.failureOrNull case final failure?) {
          throw _HabitTransactionFailure(failure);
        }
        return result;
      });
    } on _HabitTransactionFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String entityType,
    required String entityId,
  }) async {
    try {
      final rows =
          await (_database.select(_database.pendingChanges)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.entityType.equals(entityType) &
                    table.entityId.equals(entityId) &
                    table.state.equals(PendingChangeState.pending.index),
              ))
              .get();
      return AppResult.success(rows.isNotEmpty);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> applyInboundHabit(Habit habit) async {
    try {
      await _database
          .into(_database.habitRecords)
          .insertOnConflictUpdate(
            HabitRecordsCompanion.insert(
              accountId: habit.accountId,
              habitId: habit.id,
              name: habit.name,
              scheduleRevisionsJson: _codec.encodeRevisions(
                habit.scheduleRevisions,
              ),
              reminderMinuteOfDay: Value(habit.reminderMinuteOfDay),
              createdAt: habit.createdAt,
              updatedAt: habit.updatedAt,
              deletedAt: Value(habit.deletedAt),
            ),
          );
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> applyInboundDay(HabitDay day) async {
    try {
      await _database
          .into(_database.habitDayRecords)
          .insertOnConflictUpdate(
            HabitDayRecordsCompanion.insert(
              accountId: day.accountId,
              habitId: day.habitId,
              localDate: day.localDate,
              completedAt: Value(day.completedAt),
              dailyCount: Value(day.count),
              earnedWhileDue: day.earnedWhileDue,
              earnedAgainstRevisionId: Value(day.earnedAgainstRevisionId),
              recordedUtcOffsetMinutes: day.recordedUtcOffsetMinutes,
              updatedAt: day.updatedAt,
            ),
          );
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<List<HabitConflictView>> watchConflicts(String accountId) =>
      (_database.select(_database.conflictRecords)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  (table.entityType.equals(kHabitEntityType) |
                      table.entityType.equals(kHabitDayEntityType)),
            )
            ..orderBy([(table) => OrderingTerm.desc(table.detectedAt)]))
          .watch()
          .map(
            (rows) => List.unmodifiable(
              rows.map(
                (row) => HabitConflictView(
                  id: row.conflictId,
                  entityType: row.entityType,
                  entityId: row.entityId,
                  activeLabel: _conflictLabel(
                    row.entityType,
                    row.activePayload,
                  ),
                  retainedLabel: _conflictLabel(
                    row.entityType,
                    row.retainedPayload,
                  ),
                  unresolved: row.activeTimestamp == row.retainedTimestamp,
                ),
              ),
            ),
          );

  String _conflictLabel(String entityType, String payload) {
    try {
      return entityType == kHabitEntityType
          ? _codec.decodeHabit(payload).name
          : _codec.decodeDay(payload).localDate;
    } catch (_) {
      if (entityType == kHabitDayEntityType) {
        try {
          return _codec.decodeHabit(payload).name;
        } catch (_) {
          // A malformed retained version remains visible as a conflict.
        }
      }
      return '';
    }
  }

  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async {
    try {
      final row =
          await (_database.select(_database.habitRecords)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.habitId.equals(habitId),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _fromHabitRow(row));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async {
    try {
      final row =
          await (_database.select(_database.habitDayRecords)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.habitId.equals(habitId) &
                    table.localDate.equals(localDate),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _fromDayRow(row));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<List<Habit>> watchHabits(String accountId) =>
      (_database.select(_database.habitRecords)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) & table.deletedAt.isNull(),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
          .watch()
          .map((rows) => List<Habit>.unmodifiable(rows.map(_fromHabitRow)));

  @override
  Stream<List<HabitDay>> watchDays(String accountId) =>
      (_database.select(_database.habitDayRecords)
            ..where((table) => table.accountId.equals(accountId)))
          .watch()
          .map((rows) => List<HabitDay>.unmodifiable(rows.map(_fromDayRow)));

  @override
  Future<AppResult<void>> commitHabit(HabitWriteRequest request) async {
    try {
      final habit = request.habit;
      final payload = _codec.encodeHabit(habit);
      await _database.transaction(() async {
        if (await _operationAlreadyStored(
          id: request.operationId,
          accountId: habit.accountId,
          entityType: kHabitEntityType,
          entityId: habit.id,
          kind: request.kind,
          payload: payload,
          version: habit.updatedAt,
        )) {
          return;
        }
        final existing =
            await (_database.select(_database.habitRecords)..where(
                  (table) =>
                      table.accountId.equals(habit.accountId) &
                      table.habitId.equals(habit.id),
                ))
                .getSingleOrNull();
        if (request.kind == ChangeKind.create && existing != null ||
            request.kind != ChangeKind.create && existing == null ||
            existing != null && !habit.updatedAt.isAfter(existing.updatedAt) ||
            existing?.deletedAt != null ||
            request.kind == ChangeKind.delete && !habit.isDeleted ||
            request.kind != ChangeKind.delete && habit.isDeleted) {
          throw StateError('Invalid habit version or change kind');
        }
        await _database
            .into(_database.habitRecords)
            .insertOnConflictUpdate(
              HabitRecordsCompanion.insert(
                accountId: habit.accountId,
                habitId: habit.id,
                name: habit.name,
                scheduleRevisionsJson: _codec.encodeRevisions(
                  habit.scheduleRevisions,
                ),
                reminderMinuteOfDay: Value(habit.reminderMinuteOfDay),
                createdAt: habit.createdAt,
                updatedAt: habit.updatedAt,
                deletedAt: Value(habit.deletedAt),
              ),
            );
        await _queue(
          id: request.operationId,
          accountId: habit.accountId,
          entityType: kHabitEntityType,
          entityId: habit.id,
          kind: request.kind,
          payload: payload,
          queuedAt: request.queuedAt,
          version: habit.updatedAt,
          baseUpdatedAt: existing?.updatedAt,
        );
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async {
    try {
      final day = request.day;
      final payload = _codec.encodeDay(day);
      await _database.transaction(() async {
        if (await _operationAlreadyStored(
          id: request.operationId,
          accountId: day.accountId,
          entityType: kHabitDayEntityType,
          entityId: '${day.habitId}:${day.localDate}',
          kind: request.kind,
          payload: payload,
          version: day.updatedAt,
        )) {
          return;
        }
        final existing =
            await (_database.select(_database.habitDayRecords)..where(
                  (table) =>
                      table.accountId.equals(day.accountId) &
                      table.habitId.equals(day.habitId) &
                      table.localDate.equals(day.localDate),
                ))
                .getSingleOrNull();
        if (existing != null && !day.updatedAt.isAfter(existing.updatedAt)) {
          return;
        }
        await _database
            .into(_database.habitDayRecords)
            .insertOnConflictUpdate(
              HabitDayRecordsCompanion.insert(
                accountId: day.accountId,
                habitId: day.habitId,
                localDate: day.localDate,
                completedAt: Value(day.completedAt),
                dailyCount: Value(day.count),
                earnedWhileDue: day.earnedWhileDue,
                earnedAgainstRevisionId: Value(day.earnedAgainstRevisionId),
                recordedUtcOffsetMinutes: day.recordedUtcOffsetMinutes,
                updatedAt: day.updatedAt,
              ),
            );
        await _queue(
          id: request.operationId,
          accountId: day.accountId,
          entityType: kHabitDayEntityType,
          entityId: '${day.habitId}:${day.localDate}',
          kind: request.kind,
          payload: payload,
          queuedAt: request.queuedAt,
          version: day.updatedAt,
          baseUpdatedAt: existing?.updatedAt,
        );
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  Future<bool> _operationAlreadyStored({
    required String id,
    required String accountId,
    required String entityType,
    required String entityId,
    required ChangeKind kind,
    required String payload,
    required DateTime version,
  }) async {
    final existing = await (_database.select(
      _database.pendingChanges,
    )..where((table) => table.operationId.equals(id))).getSingleOrNull();
    if (existing == null) return false;
    if (existing.accountId != accountId ||
        existing.entityType != entityType ||
        existing.entityId != entityId ||
        existing.kind != kind ||
        existing.serializedChange != payload ||
        existing.versionTimestamp != version) {
      throw StateError('Operation identity collision');
    }
    return true;
  }

  Future<void> _queue({
    required String id,
    required String accountId,
    required String entityType,
    required String entityId,
    required ChangeKind kind,
    required String payload,
    required DateTime queuedAt,
    required DateTime version,
    DateTime? baseUpdatedAt,
  }) => _database
      .into(_database.pendingChanges)
      .insert(
        PendingChangesCompanion.insert(
          operationId: id,
          accountId: accountId,
          entityType: entityType,
          entityId: entityId,
          kind: kind,
          state: PendingChangeState.pending,
          serializedChange: payload,
          createdAt: queuedAt,
          versionTimestamp: version,
          baseUpdatedAt: Value(baseUpdatedAt),
        ),
      );

  Habit _fromHabitRow(HabitRecord row) => _codec.decodeHabit(
    jsonEncode({
      'id': row.habitId,
      'accountId': row.accountId,
      'name': row.name,
      'scheduleRevisions': jsonDecode(row.scheduleRevisionsJson),
      'reminderMinuteOfDay': row.reminderMinuteOfDay,
      'createdAt': row.createdAt.toUtc().toIso8601String(),
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  HabitDay _fromDayRow(HabitDayRecord row) => _codec.decodeDay(
    jsonEncode({
      'accountId': row.accountId,
      'habitId': row.habitId,
      'localDate': row.localDate,
      'completedAt': row.completedAt?.toUtc().toIso8601String(),
      'count': row.dailyCount,
      'earnedWhileDue': row.earnedWhileDue,
      'earnedAgainstRevisionId': row.earnedAgainstRevisionId,
      'recordedUtcOffsetMinutes': row.recordedUtcOffsetMinutes,
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    }),
  );

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'habits.error.save',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _HabitTransactionFailure implements Exception {
  const _HabitTransactionFailure(this.failure);
  final AppFailure failure;
}
