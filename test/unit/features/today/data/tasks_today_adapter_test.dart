import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';

import '../../../../support/today_fixtures.dart';

class _Repository implements TaskRepository {
  _Repository(this.values);
  final List<Task> values;
  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async => AppResult.success(
    values
        .where((task) => task.accountId == accountId && task.id == taskId)
        .firstOrNull,
  );
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(values);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CompletionUnit implements TaskCompletionUnitOfWork {
  _CompletionUnit(this.repository);
  final _Repository repository;
  int writes = 0;
  @override
  Future<AppResult<void>> commit(TaskCompletionCommit request) async {
    writes++;
    repository.values[0] = request.task;
    return const AppResult.success(null);
  }
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

  test(
    'write bridge forwards the displayed day to the guarded Task owner',
    () async {
      final task = Task.create(
        id: TodayOwnerFixture.taskId(1),
        accountId: kTasksPreviewAccountId,
        title: 'Today bridge',
        scheduledDate: DateTime(2026, 10, 12),
        createdAt: DateTime.utc(2026, 10, 11),
      );
      final repository = _Repository([task]);
      final unit = _CompletionUnit(repository);
      final adapter = TasksTodayAdapter(
        repository,
        completionService: TaskCompletionService(
          repository: repository,
          unitOfWork: unit,
          session: const TasksPreviewSession(),
          nowUtc: () => DateTime.utc(2026, 10, 12, 12),
          currentLocalDate: () => DateTime(2026, 10, 12),
          nextOperationId: () => 'bridge-task-operation',
        ),
      );
      final rejected = await adapter.setCompleted(
        ownerId: kTasksPreviewAccountId,
        taskId: task.id,
        expectedLocalDate: TodayLocalDate(2026, 10, 11),
        completed: true,
      );
      expect(rejected.failureOrNull?.messageKey, 'tasks.validation.stale_day');
      expect(unit.writes, 0);
      final accepted = await adapter.setCompleted(
        ownerId: kTasksPreviewAccountId,
        taskId: task.id,
        expectedLocalDate: TodayLocalDate(2026, 10, 12),
        completed: true,
      );
      expect(accepted.failureOrNull, isNull);
      expect(unit.writes, 1);
      expect(repository.values.single.isCompleted, isTrue);
    },
  );
}
