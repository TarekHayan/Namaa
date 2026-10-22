import 'package:flutter_test/flutter_test.dart';

import '../../../support/today_fixtures.dart';

void main() {
  test('mixed fixture has exact owner counts and recorded award evidence', () {
    final fixture = TodayOwnerFixture.mixedDates();
    final taskIds = fixture.tasks
        .where(
          (task) =>
              task.accountId == TodayFixtureAccounts.accountA &&
              !task.isDeleted &&
              task.scheduledDate.isAtSameMomentAs(TodayFixtureTime.today),
        )
        .toList();
    expect(taskIds.length, 10);
    expect(taskIds.where((task) => task.isCompleted), hasLength(4));

    final eligibleHabits = fixture.habits.where((habit) {
      if (habit.accountId != TodayFixtureAccounts.accountA || habit.isDeleted) {
        return false;
      }
      return habit.isDueOn(TodayFixtureTime.todayKey) ||
          fixture.days.any(
            (day) =>
                day.habitId == habit.id &&
                day.accountId == habit.accountId &&
                day.isCompleted,
          );
    }).toList();
    expect(eligibleHabits, hasLength(5));
    expect(
      eligibleHabits.where(
        (habit) => fixture.days.any(
          (day) => day.habitId == habit.id && day.isCompleted,
        ),
      ),
      hasLength(2),
    );
    expect(eligibleHabits.last.isDueOn(TodayFixtureTime.todayKey), isFalse);

    expect(fixture.tasks.first.isCompleted, isTrue);
    expect(fixture.awards.first.awardedAt.day, 11);
    expect(fixture.tasks[13].isDeleted, isTrue);
    expect(fixture.awards[2].sourceId, fixture.tasks[13].id);
    expect(
      fixture.awards.where(
        (award) => award.accountId == TodayFixtureAccounts.accountB,
      ),
      hasLength(1),
    );
    expect(
      TodayFixtureAccounts.tasksMapsXpPreview,
      isNot(TodayFixtureAccounts.habitsPreview),
    );
  });

  test(
    'held session lookup can return the previous account after a switch',
    () async {
      final session = TodayControlledSession(
        initialAccountId: TodayFixtureAccounts.accountA,
      );
      final seen = <String?>[];
      final subscription = session.observeSession().listen(
        (snapshot) => seen.add(snapshot.accountId),
      );
      session.holdContext();
      final oldLookup = session.obtainSyncContext();
      session.signIn(TodayFixtureAccounts.accountB);
      session.releaseContextFor(TodayFixtureAccounts.accountA);
      expect(
        (await oldLookup).valueOrNull?.accountId,
        TodayFixtureAccounts.accountA,
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        TodayFixtureAccounts.accountA,
        TodayFixtureAccounts.accountB,
      ]);
      await subscription.cancel();
      await session.close();
    },
  );

  test(
    'controlled source stays silent, then emits data and an error',
    () async {
      final source = TodayControlledStream<int>();
      final values = <int>[];
      final errors = <Object>[];
      final subscription = source.stream.listen(
        values.add,
        onError: errors.add,
      );
      expect(values, isEmpty);
      source.emit(3);
      source.fail(StateError('fixture failure'));
      expect(values, [3]);
      expect(errors, hasLength(1));
      await subscription.cancel();
      await source.close();
    },
  );
}
