import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../../../../support/today_fixtures.dart';

class _Repository implements HabitRepository {
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  final habits = StreamController<List<Habit>>.broadcast(sync: true);
  final days = StreamController<List<HabitDay>>.broadcast(sync: true);
  Habit? currentHabit;
  HabitDay? currentDay;
  int dayWrites = 0;
  bool throwOnDays = false;
  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async => AppResult.success(
    currentHabit?.accountId == accountId && currentHabit?.id == habitId
        ? currentHabit
        : null,
  );
  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async => AppResult.success(
    currentDay?.accountId == accountId &&
            currentDay?.habitId == habitId &&
            currentDay?.localDate == localDate
        ? currentDay
        : null,
  );
  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async {
    dayWrites++;
    currentDay = request.day;
    return const AppResult.success(null);
  }

  @override
  Stream<List<Habit>> watchHabits(String ownerId) => habits.stream;
  @override
  Stream<List<HabitDay>> watchDays(String ownerId) {
    if (throwOnDays) throw StateError('day listener unavailable');
    return days.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'paired source error ends its subscription and a new pair can recover',
    () async {
      final repo = _Repository();
      final errors = <Object>[];
      var oldCount = 0;
      final old = HabitsTodayAdapter(repo)
          .watchHabits('owner')
          .listen(
            (_) => oldCount++,
            onError: (Object error) => errors.add(error),
          );
      repo.habits.add([]);
      repo.days.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(oldCount, 1);
      repo.days.addError(StateError('day read failed'));
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
      repo.habits.add([]);
      repo.days.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(oldCount, 1);

      var freshCount = 0;
      final fresh = HabitsTodayAdapter(
        repo,
      ).watchHabits('owner').listen((_) => freshCount++);
      repo.habits.add([]);
      expect(freshCount, 0);
      repo.days.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(freshCount, 1);
      await old.cancel();
      await fresh.cancel();
      await repo.habits.close();
      await repo.days.close();
    },
  );

  test('synchronous second listener failure is exposed and disposed', () async {
    final repo = _Repository()..throwOnDays = true;
    final errors = <Object>[];
    final sub = HabitsTodayAdapter(repo)
        .watchHabits('owner')
        .listen(
          (_) => fail('unexpected snapshot'),
          onError: (Object error) => errors.add(error),
        );
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(1));
    expect(repo.habits.hasListener, isFalse);
    await sub.cancel();
    await repo.habits.close();
    await repo.days.close();
  });
  test(
    'waits for both constituent emissions and retains owner streak/earned completion',
    () async {
      final fixture = TodayOwnerFixture.mixedDates();
      final repo = _Repository();
      final received = <List<TodayHabitReference>>[];
      final sub = HabitsTodayAdapter(repo)
          .watchHabits(TodayFixtureAccounts.accountA)
          .listen((snapshot) {
            final calendar = TodayCalendar(
              localDate: TodayLocalDate(2026, 10, 12),
              nowUtc: TodayFixtureTime.nowUtc,
              utcOffsetMinutes: 120,
              dayStartUtc: DateTime.utc(2026, 10, 11, 22),
              nextDayStartUtc: DateTime.utc(2026, 10, 12, 22),
              projectionRevision: 0,
            );
            received.add(
              snapshot.project(calendar).where((h) => h.isEligible).toList(),
            );
          });
      repo.habits.add(fixture.habits);
      expect(received, isEmpty);
      repo.days.add(fixture.days);
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      expect(received.single, hasLength(5));
      expect(
        received.single.map((h) => h.habitId),
        contains(TodayOwnerFixture.habitId(5)),
      );
      expect(
        received.single.map((h) => h.habitId),
        isNot(contains(TodayOwnerFixture.habitId(6))),
      );
      expect(received.single.where((h) => h.isCompleted).length, 2);
      expect(received.single.first.currentStreak, 1);
      expect(received.single.last.earnedWhileDue, isTrue);
      await sub.cancel();
      await repo.habits.close();
      await repo.days.close();
    },
  );

  test(
    'write bridge forwards displayed day and owner to Habit commands',
    () async {
      final repository = _Repository();
      repository.currentHabit = Habit.create(
        id: TodayOwnerFixture.habitId(1),
        accountId: kHabitsPreviewAccountId,
        name: 'Read',
        weekdays: {DateTime.monday},
        revisionId: 'bridge-revision',
        createdAt: DateTime.utc(2026, 10, 11),
        effectiveLocalDate: '2026-10-11',
        utcOffsetMinutes: 0,
      );
      final adapter = HabitsTodayAdapter(
        repository,
        commands: HabitCommands(
          repository: repository,
          session: const HabitsPreviewSession(),
          nowUtc: () => DateTime.utc(2026, 10, 12, 12),
          localCalendar: () => (localDate: '2026-10-12', utcOffsetMinutes: 0),
          nextOperationId: () => 'bridge-habit-operation',
        ),
      );
      final rejected = await adapter.setCompleted(
        ownerId: kTasksPreviewAccountId,
        habitId: repository.currentHabit!.id,
        expectedLocalDate: TodayLocalDate(2026, 10, 12),
        completed: true,
      );
      expect(rejected.failureOrNull, isNotNull);
      expect(repository.dayWrites, 0);
      final accepted = await adapter.setCompleted(
        ownerId: kHabitsPreviewAccountId,
        habitId: repository.currentHabit!.id,
        expectedLocalDate: TodayLocalDate(2026, 10, 12),
        completed: true,
      );
      expect(accepted.failureOrNull, isNull);
      expect(repository.currentDay?.isCompleted, isTrue);
      final undone = await adapter.setCompleted(
        ownerId: kHabitsPreviewAccountId,
        habitId: repository.currentHabit!.id,
        expectedLocalDate: TodayLocalDate(2026, 10, 12),
        completed: false,
      );
      expect(undone.failureOrNull, isNull);
      expect(repository.currentDay?.isCompleted, isFalse);
      expect(repository.dayWrites, 2);
      await repository.habits.close();
      await repository.days.close();
    },
  );
}
