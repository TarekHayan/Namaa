import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/supabase_habit_reader.dart';
import 'package:namma_project/features/habits/data/supabase_habit_sync_adapter.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  final at = DateTime.utc(2026, 10, 12, 9);
  final habit = Habit.create(
    id: kHabitsTestHabitId,
    accountId: kHabitsTestAccountA,
    name: 'Read',
    weekdays: {1},
    revisionId: kHabitsTestRevisionId,
    createdAt: at,
    effectiveLocalDate: '2026-10-12',
    utcOffsetMinutes: 120,
  );
  final day = HabitDay.completed(
    accountId: habit.accountId,
    habitId: habit.id,
    localDate: '2026-10-12',
    completedAt: at,
    earnedAgainstRevisionId: kHabitsTestRevisionId,
    recordedUtcOffsetMinutes: 120,
  );
  const codec = HabitPayloadCodec();

  test(
    'outbound Habit and day use receipt ID, retry and acknowledge only after commit',
    () async {
      final gateway = _Gateway(account: habit.accountId);
      final adapter = SupabaseHabitSyncAdapter(gateway: gateway);
      final habitChange = OutboundChange(
        operationId: 'op-habit',
        accountId: habit.accountId,
        entityType: kHabitEntityType,
        entityId: habit.id,
        kind: ChangeKind.create,
        payload: codec.encodeHabit(habit),
        versionTimestamp: at,
      );
      final dayChange = OutboundChange(
        operationId: 'op-day',
        accountId: day.accountId,
        entityType: kHabitDayEntityType,
        entityId: '${day.habitId}:${day.localDate}',
        kind: ChangeKind.create,
        payload: codec.encodeDay(day),
        versionTimestamp: at,
      );
      gateway.fail = true;
      expect(
        (await adapter.dispatchChange(habitChange)).failureOrNull,
        isNotNull,
      );
      gateway.fail = false;
      expect(
        (await adapter.dispatchChange(habitChange)).valueOrNull,
        isA<DispatchAcknowledged>(),
      );
      expect(
        (await adapter.dispatchChange(dayChange)).valueOrNull,
        isA<DispatchAcknowledged>(),
      );
      expect(gateway.operations, ['op-habit', 'op-habit', 'op-day']);
      gateway.wrongOwner = true;
      expect(
        (await adapter.dispatchChange(habitChange)).failureOrNull,
        isNotNull,
      );
      expect(
        (await adapter.dispatchChange(
          OutboundChange(
            operationId: 'bad',
            accountId: habit.accountId,
            entityType: 'unknown',
            entityId: habit.id,
            kind: ChangeKind.create,
            payload: codec.encodeHabit(habit),
            versionTimestamp: at,
          ),
        )).failureOrNull,
        isNotNull,
      );
    },
  );

  test('reader completes final pages, tombstones and day identity', () async {
    final gateway = _Gateway(account: habit.accountId);
    final tombstone = Habit.create(
      id: kHabitsTestOtherHabitId,
      accountId: habit.accountId,
      name: 'Other',
      weekdays: {1},
      revisionId: 'other-revision',
      createdAt: at,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    ).delete(at.add(const Duration(minutes: 1)));
    gateway.habitRows = [_habitRow(habit), _habitRow(tombstone)];
    gateway.dayRows = [_dayRow(day)];
    final result = await SupabaseHabitReader(
      gateway: gateway,
      pageSize: 1,
    ).readAll(habit.accountId);
    expect(result.failureOrNull, isNull);
    expect(result.valueOrNull!.habits, hasLength(2));
    expect(result.valueOrNull!.habits.last.isDeleted, isTrue);
    expect(result.valueOrNull!.days.single.localDate, '2026-10-12');
    gateway.failDayPage = true;
    expect(
      (await SupabaseHabitReader(
        gateway: gateway,
        pageSize: 1,
      ).readAll(habit.accountId)).failureOrNull,
      isNotNull,
    );
    gateway.failDayPage = false;
    gateway.habitRows = [_habitRow(habit)..['owner'] = kHabitsTestAccountB];
    expect(
      (await SupabaseHabitReader(
        gateway: gateway,
      ).readAll(habit.accountId)).failureOrNull,
      isNotNull,
    );
  });
}

Map<String, dynamic> _habitRow(Habit habit) => {
  'owner': habit.accountId,
  'id': habit.id,
  'payload': jsonDecode(const HabitPayloadCodec().encodeHabit(habit)),
  'updated_at': habit.updatedAt.toIso8601String(),
  'deleted_at': habit.deletedAt?.toIso8601String(),
};
Map<String, dynamic> _dayRow(HabitDay day) => {
  'owner': day.accountId,
  'habit_id': day.habitId,
  'local_date': day.localDate,
  'payload': jsonDecode(const HabitPayloadCodec().encodeDay(day)),
  'updated_at': day.updatedAt.toIso8601String(),
};

final class _Gateway implements SupabaseHabitGateway {
  _Gateway({required this.account});
  final String account;
  @override
  String? get currentAccountId => account;
  final List<String> operations = [];
  bool fail = false;
  bool wrongOwner = false;
  bool failDayPage = false;
  List<Map<String, dynamic>> habitRows = [];
  List<Map<String, dynamic>> dayRows = [];
  @override
  Future<Map<String, dynamic>> applyChange({
    required String expectedAccountId,
    required String entityType,
    required String habitId,
    String? localDate,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    operations.add(operationId);
    if (fail) throw StateError('offline');
    return {
      'owner': wrongOwner ? kHabitsTestAccountB : expectedAccountId,
      'id': habitId,
      'entity_type': entityType,
      'local_date': localDate,
      'payload': payload,
      'operation_id': operationId,
      'updated_at': updatedAt.toIso8601String(),
      'conflict_detected': false,
    };
  }

  @override
  Future<HabitRemotePage> fetchHabitPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  }) async {
    final start = cursor == null ? 0 : int.parse(cursor);
    final rows = habitRows.skip(start).take(pageSize).toList();
    return HabitRemotePage(
      rows: rows,
      nextCursor: start + rows.length < habitRows.length
          ? '${start + rows.length}'
          : null,
    );
  }

  @override
  Future<HabitRemotePage> fetchDayPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  }) async {
    if (failDayPage) throw StateError('page failed');
    final start = cursor == null ? 0 : int.parse(cursor);
    final rows = dayRows.skip(start).take(pageSize).toList();
    return HabitRemotePage(
      rows: rows,
      nextCursor: start + rows.length < dayRows.length
          ? '${start + rows.length}'
          : null,
    );
  }
}
