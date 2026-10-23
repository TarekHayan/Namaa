import 'dart:convert';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/supabase_habit_sync_adapter.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

/// Validates every owner page before publishing a complete snapshot.
final class SupabaseHabitReader implements HabitRemoteReaderPort {
  SupabaseHabitReader({
    required SupabaseHabitGateway gateway,
    HabitPayloadCodec codec = const HabitPayloadCodec(),
    this.pageSize = kHabitRemotePageSize,
  }) : _gateway = gateway,
       _codec = codec;
  final SupabaseHabitGateway _gateway;
  final HabitPayloadCodec _codec;
  final int pageSize;

  @override
  Future<AppResult<HabitRemoteSnapshot>> readAll(String accountId) async {
    try {
      if (pageSize < 1) throw ArgumentError.value(pageSize, 'pageSize');
      final habits = <Habit>[];
      final days = <HabitDay>[];
      final habitRowsById = <String, String>{};
      final dayRowsById = <String, String>{};
      final habitCursors = <String>{};
      String? cursor;
      do {
        final page = await _gateway.fetchHabitPage(
          expectedAccountId: accountId,
          pageSize: pageSize,
          cursor: cursor,
        );
        if (page.rows.length > pageSize) {
          throw StateError('Oversized Habit page');
        }
        for (final row in page.rows) {
          if (row['owner'] != accountId) {
            throw StateError('Foreign Habit owner');
          }
          final payload = Map<String, dynamic>.from(row['payload'] as Map);
          if (payload['accountId'] != accountId ||
              payload['id'] != row['id'] ||
              !_sameInstant(payload['updatedAt'], row['updated_at']) ||
              !_sameInstant(payload['deletedAt'], row['deleted_at'])) {
            throw StateError('Habit page identity or version mismatch');
          }
          payload['accountId'] = row['owner'];
          payload['id'] = row['id'];
          payload['updatedAt'] = row['updated_at'];
          payload['deletedAt'] = row['deleted_at'];
          final id = row['id'] as String;
          final fingerprint = jsonEncode(row);
          final previous = habitRowsById[id];
          if (previous != null) {
            if (previous != fingerprint) {
              throw StateError('Inconsistent repeated Habit page row');
            }
            continue;
          }
          habitRowsById[id] = fingerprint;
          habits.add(_codec.decodeHabit(jsonEncode(payload)));
        }
        cursor = page.nextCursor;
        if (page.rows.isEmpty && cursor != null) {
          throw StateError('Empty Habit page has another cursor');
        }
        if (cursor != null && !habitCursors.add(cursor)) {
          throw StateError('Repeated Habit cursor');
        }
      } while (cursor != null);

      final dayCursors = <String>{};
      cursor = null;
      do {
        final page = await _gateway.fetchDayPage(
          expectedAccountId: accountId,
          pageSize: pageSize,
          cursor: cursor,
        );
        if (page.rows.length > pageSize) {
          throw StateError('Oversized HabitDay page');
        }
        for (final row in page.rows) {
          if (row['owner'] != accountId) {
            throw StateError('Foreign HabitDay owner');
          }
          final payload = Map<String, dynamic>.from(row['payload'] as Map);
          if (payload['accountId'] != accountId ||
              payload['habitId'] != row['habit_id'] ||
              payload['localDate'] != row['local_date'] ||
              !_sameInstant(payload['updatedAt'], row['updated_at'])) {
            throw StateError('HabitDay page identity or version mismatch');
          }
          payload['accountId'] = row['owner'];
          payload['habitId'] = row['habit_id'];
          payload['localDate'] = row['local_date'];
          payload['updatedAt'] = row['updated_at'];
          final id = '${row['habit_id']}:${row['local_date']}';
          final fingerprint = jsonEncode(row);
          final previous = dayRowsById[id];
          if (previous != null) {
            if (previous != fingerprint) {
              throw StateError('Inconsistent repeated HabitDay page row');
            }
            continue;
          }
          dayRowsById[id] = fingerprint;
          days.add(_codec.decodeDay(jsonEncode(payload)));
        }
        cursor = page.nextCursor;
        if (page.rows.isEmpty && cursor != null) {
          throw StateError('Empty HabitDay page has another cursor');
        }
        if (cursor != null && !dayCursors.add(cursor)) {
          throw StateError('Repeated HabitDay cursor');
        }
      } while (cursor != null);
      return AppResult.success(HabitRemoteSnapshot(habits: habits, days: days));
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: 'habits.sync.failed',
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }

  static bool _sameInstant(Object? first, Object? second) {
    if (first == null || second == null) return first == null && second == null;
    if (first is! String || second is! String) return false;
    final left = DateTime.tryParse(first);
    final right = DateTime.tryParse(second);
    return left != null && right != null && left.toUtc() == right.toUtc();
  }
}
