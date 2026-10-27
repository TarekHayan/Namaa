import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/habits/application/habit_reconciliation.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';

/// Applies a complete owner snapshot in one encrypted transaction. An inbound
/// winner and its retained loser are committed together; pending writes stay.
final class HabitReconciler implements HabitReconciliationPort {
  HabitReconciler({
    required HabitReconciliationStorePort store,
    required LocalStorePort localStore,
    HabitPayloadCodec codec = const HabitPayloadCodec(),
    DateTime Function()? detectedAt,
  }) : _store = store,
       _localStore = localStore,
       _codec = codec,
       _detectedAt = detectedAt ?? (() => DateTime.now().toUtc());
  final HabitReconciliationStorePort _store;
  final LocalStorePort _localStore;
  final HabitPayloadCodec _codec;
  final DateTime Function() _detectedAt;

  @override
  Future<AppResult<HabitReconciliationSummary>> reconcile({
    required String accountId,
    required HabitRemoteSnapshot remote,
  }) async {
    if (remote.habits.any((habit) => habit.accountId != accountId) ||
        remote.days.any((day) => day.accountId != accountId)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    return _store.runInTransaction(() async {
      var imported = 0;
      var conflicts = 0;
      var equal = 0;
      final parents = <String, Habit>{};
      for (final habit in remote.habits) {
        final result = await _store.readHabit(
          accountId: accountId,
          habitId: habit.id,
        );
        if (result.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        final local = result.valueOrNull;
        final remotePayload = _codec.encodeHabit(habit);
        if (local == null) {
          final applied = await _store.applyInboundHabit(habit);
          if (applied.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          imported++;
          parents[habit.id] = habit;
          continue;
        }
        final localPayload = _codec.encodeHabit(local);
        if (localPayload != remotePayload) {
          final comparison = habit.updatedAt.compareTo(local.updatedAt);
          final pending = await _store.hasPendingChange(
            accountId: accountId,
            entityType: kHabitEntityType,
            entityId: habit.id,
          );
          if (pending.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          if (pending.valueOrNull != true) {
            if (comparison > 0) {
              final applied = await _store.applyInboundHabit(habit);
              if (applied.failureOrNull case final failure?) {
                return AppResult.failure(failure);
              }
              imported++;
            }
            parents[habit.id] = comparison > 0 ? habit : local;
            continue;
          }
          final recorded = await _recordConflict(
            accountId: accountId,
            entityType: kHabitEntityType,
            entityId: habit.id,
            localPayload: localPayload,
            localAt: local.updatedAt,
            remotePayload: remotePayload,
            remoteAt: habit.updatedAt,
            comparison: comparison,
          );
          if (recorded.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          conflicts++;
          if (comparison == 0) equal++;
          if (comparison > 0) {
            final applied = await _store.applyInboundHabit(habit);
            if (applied.failureOrNull case final failure?) {
              return AppResult.failure(failure);
            }
          }
        }
        parents[habit.id] = habit.updatedAt.isAfter(local.updatedAt)
            ? habit
            : local;
      }
      for (final day in remote.days) {
        var parent = parents[day.habitId];
        if (parent == null) {
          final parentResult = await _store.readHabit(
            accountId: accountId,
            habitId: day.habitId,
          );
          if (parentResult.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          parent = parentResult.valueOrNull;
        }
        if (parent == null) {
          return AppResult.failure(_failure(AppFailureCategory.persistence));
        }
        final result = await _store.readDay(
          accountId: accountId,
          habitId: day.habitId,
          localDate: day.localDate,
        );
        if (result.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        final local = result.valueOrNull;
        final remotePayload = _codec.encodeDay(day);
        if (local == null) {
          final applied = await _store.applyInboundDay(day);
          if (applied.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          imported++;
        } else {
          final localPayload = _codec.encodeDay(local);
          if (localPayload != remotePayload) {
            final comparison = day.updatedAt.compareTo(local.updatedAt);
            final pending = await _store.hasPendingChange(
              accountId: accountId,
              entityType: kHabitDayEntityType,
              entityId: '${day.habitId}:${day.localDate}',
            );
            if (pending.failureOrNull case final failure?) {
              return AppResult.failure(failure);
            }
            if (pending.valueOrNull != true && !parent.isDeleted) {
              if (comparison > 0) {
                final applied = await _store.applyInboundDay(day);
                if (applied.failureOrNull case final failure?) {
                  return AppResult.failure(failure);
                }
                imported++;
              }
              continue;
            }
            final recorded = await _recordConflict(
              accountId: accountId,
              entityType: kHabitDayEntityType,
              entityId: '${day.habitId}:${day.localDate}',
              localPayload: localPayload,
              localAt: local.updatedAt,
              remotePayload: remotePayload,
              remoteAt: day.updatedAt,
              comparison: comparison,
            );
            if (recorded.failureOrNull case final failure?) {
              return AppResult.failure(failure);
            }
            conflicts++;
            if (comparison == 0) equal++;
            if (comparison > 0) {
              final applied = await _store.applyInboundDay(day);
              if (applied.failureOrNull case final failure?) {
                return AppResult.failure(failure);
              }
            }
          }
        }
        if (parent.isDeleted && day.updatedAt.isAfter(parent.deletedAt!)) {
          final recorded = await _localStore.recordConflict(
            ConflictRecordInput(
              conflictId: _conflictId(
                accountId,
                kHabitDayEntityType,
                '${day.habitId}:${day.localDate}:parent',
                remotePayload,
                _codec.encodeHabit(parent),
              ),
              accountId: accountId,
              entityType: kHabitDayEntityType,
              entityId: '${day.habitId}:${day.localDate}',
              activeVersion: RecordVersionInput(
                source: VersionSource.remote,
                versionTimestamp: day.updatedAt,
                payload: remotePayload,
              ),
              retainedVersion: RecordVersionInput(
                source: VersionSource.local,
                versionTimestamp: parent.deletedAt!,
                payload: _codec.encodeHabit(parent),
              ),
              detectedAt: _detectedAt(),
            ),
          );
          if (recorded.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          conflicts++;
        }
      }
      return AppResult.success(
        HabitReconciliationSummary(
          imported: imported,
          conflictsRecorded: conflicts,
          equalTimestampConflicts: equal,
        ),
      );
    });
  }

  Future<AppResult<void>> _recordConflict({
    required String accountId,
    required String entityType,
    required String entityId,
    required String localPayload,
    required DateTime localAt,
    required String remotePayload,
    required DateTime remoteAt,
    required int comparison,
  }) => _localStore.recordConflict(
    ConflictRecordInput(
      conflictId: _conflictId(
        accountId,
        entityType,
        entityId,
        localPayload,
        remotePayload,
      ),
      accountId: accountId,
      entityType: entityType,
      entityId: entityId,
      activeVersion: RecordVersionInput(
        source: comparison > 0 ? VersionSource.remote : VersionSource.local,
        versionTimestamp: comparison > 0 ? remoteAt : localAt,
        payload: comparison > 0 ? remotePayload : localPayload,
      ),
      retainedVersion: RecordVersionInput(
        source: comparison > 0 ? VersionSource.local : VersionSource.remote,
        versionTimestamp: comparison > 0 ? localAt : remoteAt,
        payload: comparison > 0 ? localPayload : remotePayload,
      ),
      detectedAt: _detectedAt(),
    ),
  );

  static String _conflictId(
    String owner,
    String type,
    String id,
    String first,
    String second,
  ) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode('$owner|$type|$id|$first|$second')) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return 'habit-inbound-$owner-$type-$id-${hash.toRadixString(16)}';
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'habits.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
