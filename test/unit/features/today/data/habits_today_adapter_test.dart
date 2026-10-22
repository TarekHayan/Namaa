import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../../../../support/today_fixtures.dart';

class _Repository implements HabitRepository {
  final habits = StreamController<List<Habit>>.broadcast(sync: true);
  final days = StreamController<List<HabitDay>>.broadcast(sync: true);
  @override
  Stream<List<Habit>> watchHabits(String ownerId) => habits.stream;
  @override
  Stream<List<HabitDay>> watchDays(String ownerId) => days.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
}
