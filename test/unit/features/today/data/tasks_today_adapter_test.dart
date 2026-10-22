import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';

import '../../../../support/today_fixtures.dart';

class _Repository implements TaskRepository {
  _Repository(this.values);
  final List<Task> values;
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(values);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'full owner snapshot retains completed records and canonical order without foreign/deleted rows',
    () async {
      final fixture = TodayOwnerFixture.mixedDates();
      final adapter = TasksTodayAdapter(_Repository(fixture.tasks));
      final snapshot = await adapter
          .watchTasks(TodayFixtureAccounts.accountA)
          .first;
      final calendar = TodayCalendar(
        localDate: TodayLocalDate(2026, 10, 12),
        nowUtc: TodayFixtureTime.nowUtc,
        utcOffsetMinutes: 0,
        dayStartUtc: DateTime.utc(2026, 10, 12),
        nextDayStartUtc: DateTime.utc(2026, 10, 13),
        projectionRevision: 0,
      );
      final rows = snapshot.project(calendar);
      expect(rows.length, 13);
      expect(rows.take(10).where((r) => r.isCompleted).length, 4);
      expect(rows.first.taskId, TodayOwnerFixture.taskId(1));
      expect(rows.first.scheduledMinuteOfDay, 9 * 60);
      expect(rows.where((r) => r.isOverdue).map((r) => r.taskId), [
        TodayOwnerFixture.taskId(11),
        TodayOwnerFixture.taskId(13),
      ]);
      expect(
        rows.any(
          (r) =>
              r.taskId == TodayOwnerFixture.taskId(14) ||
              r.taskId == TodayOwnerFixture.taskId(15),
        ),
        false,
      );
    },
  );
}
