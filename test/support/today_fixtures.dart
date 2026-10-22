/// In-memory owner records and controllable sources for Today 006 tests.
///
/// These fixtures do not read the wall clock, open a store, or seed preview
/// records. Tests must explicitly pass the values to their fake/owner ports.
library;

import 'dart:async';

import 'package:namma_project/app/composition/habits_preview_adapters.dart'
    show kHabitsPreviewAccountId;
import 'package:namma_project/app/composition/tasks_preview_adapters.dart'
    show kTasksPreviewAccountId;
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import 'tasks_test_support.dart' show kTasksTestAccountA, kTasksTestAccountB;

abstract final class TodayFixtureAccounts {
  static const String accountA = kTasksTestAccountA;
  static const String accountB = kTasksTestAccountB;
  static const String tasksMapsXpPreview = kTasksPreviewAccountId;
  static const String habitsPreview = kHabitsPreviewAccountId;
}

/// Monday, 12 October 2026, at noon UTC; local dates are explicit values.
abstract final class TodayFixtureTime {
  static DateTime get nowUtc => DateTime.utc(2026, 10, 12, 12);
  static DateTime get yesterday => DateTime(2026, 10, 11);
  static DateTime get today => DateTime(2026, 10, 12);
  static DateTime get tomorrow => DateTime(2026, 10, 13);
  static const String todayKey = '2026-10-12';
  static const int utcOffsetMinutes = 120;
}

/// A small, repeatable mixed-date fixture using the actual owner aggregates.
///
/// Account A has 10 nondeleted Tasks scheduled today, four completed; five
/// eligible Habits, two completed. The fifth Habit retains a completion earned
/// before Monday was removed from its schedule. Exclusions and account B are
/// present to exercise filtering, not to alter those denominators.
final class TodayOwnerFixture {
  TodayOwnerFixture._(this.tasks, this.habits, this.days, this.awards);

  final List<Task> tasks;
  final List<Habit> habits;
  final List<HabitDay> days;
  final List<TaskCompletionAward> awards;

  static String taskId(int sequence) =>
      '00000000-0000-4006-8001-${sequence.toString().padLeft(12, '0')}';

  static String habitId(int sequence) =>
      '00000000-0000-4006-8002-${sequence.toString().padLeft(12, '0')}';

  static TodayOwnerFixture mixedDates() {
    final tasks = <Task>[
      for (var index = 0; index < 10; index++)
        _task(
          index + 1,
          scheduledDate: TodayFixtureTime.today,
          completed: index < 4,
          repeatedCompletion: index == 0,
          quadrant: index.isEven
              ? EisenhowerQuadrant.urgentImportant
              : EisenhowerQuadrant.notUrgentImportant,
          scheduledTime: index == 0 || index == 1
              ? DateTime(2026, 10, 12, 9)
              : index == 2
              ? DateTime(2026, 10, 12, 8)
              : null,
        ),
      _task(11, scheduledDate: TodayFixtureTime.yesterday),
      _task(12, scheduledDate: TodayFixtureTime.tomorrow),
      _task(
        13,
        scheduledDate: TodayFixtureTime.tomorrow,
        targetDeadline: DateTime.utc(2026, 10, 11, 18),
      ),
      _task(14, scheduledDate: TodayFixtureTime.today, deleted: true),
      _task(
        15,
        accountId: TodayFixtureAccounts.accountB,
        scheduledDate: TodayFixtureTime.today,
        completed: true,
      ),
    ];

    final habits = <Habit>[
      for (var index = 0; index < 5; index++)
        _habit(index + 1, completedThenUnscheduled: index == 4),
      _habit(6, weekdays: const {DateTime.tuesday}),
      _habit(7, deleted: true),
      _habit(8, accountId: TodayFixtureAccounts.accountB),
    ];
    final days = <HabitDay>[_day(habits[0]), _day(habits[4]), _day(habits[7])];
    final awards = <TaskCompletionAward>[
      // Original award remains yesterday despite reopening/recompletion today.
      _award(tasks[0], DateTime.utc(2026, 10, 11, 10)),
      _award(tasks[1], DateTime.utc(2026, 10, 12, 8)),
      // Deleting a Task does not erase its recorded award.
      _award(tasks[13], DateTime.utc(2026, 10, 12, 9)),
      _award(tasks[14], DateTime.utc(2026, 10, 12, 8)),
    ];

    return TodayOwnerFixture._(
      List<Task>.unmodifiable(tasks),
      List<Habit>.unmodifiable(habits),
      List<HabitDay>.unmodifiable(days),
      List<TaskCompletionAward>.unmodifiable(awards),
    );
  }

  static Task _task(
    int sequence, {
    String accountId = TodayFixtureAccounts.accountA,
    required DateTime scheduledDate,
    bool completed = false,
    bool repeatedCompletion = false,
    bool deleted = false,
    EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
    DateTime? scheduledTime,
    DateTime? targetDeadline,
  }) {
    var task = Task.create(
      id: taskId(sequence),
      accountId: accountId,
      title: 'Fixture task $sequence',
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      targetDeadline: targetDeadline,
      quadrant: quadrant,
      createdAt: DateTime.utc(2026, 10, 10, 8),
    );
    if (repeatedCompletion) {
      task = task
          .complete(DateTime.utc(2026, 10, 11, 10))
          .reopen(DateTime.utc(2026, 10, 12, 7))
          .complete(DateTime.utc(2026, 10, 12, 8));
    } else if (completed || deleted) {
      task = task.complete(DateTime.utc(2026, 10, 12, 8));
    }
    if (deleted) task = task.markDeleted(DateTime.utc(2026, 10, 12, 10));
    return task;
  }

  static Habit _habit(
    int sequence, {
    String accountId = TodayFixtureAccounts.accountA,
    Set<int> weekdays = const {DateTime.monday},
    bool completedThenUnscheduled = false,
    bool deleted = false,
  }) {
    var habit = Habit.create(
      id: habitId(sequence),
      accountId: accountId,
      name: 'Fixture habit $sequence',
      weekdays: weekdays,
      revisionId: 'fixture-revision-$sequence-1',
      createdAt: DateTime.utc(2026, 10, 10, 8),
      effectiveLocalDate: '2026-10-10',
      utcOffsetMinutes: TodayFixtureTime.utcOffsetMinutes,
    );
    if (completedThenUnscheduled) {
      habit = habit.edit(
        name: habit.name,
        weekdays: const {DateTime.tuesday},
        reminderMinuteOfDay: null,
        revisionId: 'fixture-revision-$sequence-2',
        editedAt: DateTime.utc(2026, 10, 12, 9),
        effectiveLocalDate: TodayFixtureTime.todayKey,
        utcOffsetMinutes: TodayFixtureTime.utcOffsetMinutes,
      );
    }
    if (deleted) habit = habit.delete(DateTime.utc(2026, 10, 12, 10));
    return habit;
  }

  static HabitDay _day(Habit habit) => HabitDay.completed(
    accountId: habit.accountId,
    habitId: habit.id,
    localDate: TodayFixtureTime.todayKey,
    completedAt: DateTime.utc(2026, 10, 12, 7),
    earnedAgainstRevisionId: habit.scheduleRevisions.first.revisionId,
    recordedUtcOffsetMinutes: TodayFixtureTime.utcOffsetMinutes,
  );

  static TaskCompletionAward _award(Task task, DateTime at) =>
      TaskCompletionAward(
        accountId: task.accountId,
        source: kTaskDoneAwardSource,
        sourceId: task.id,
        amount: task.completionXp,
        awardedAt: at,
      );
}

/// An owner stream that stays silent until a test emits a value or error.
final class TodayControlledStream<T> {
  final StreamController<T> _controller = StreamController<T>.broadcast(
    sync: true,
  );

  Stream<T> get stream => _controller.stream;

  void emit(T value) => _controller.add(value);

  void fail(Object error) => _controller.addError(error);

  Future<void> close() => _controller.close();
}

/// Session fake with explicit switching and one manually held context lookup.
///
/// A test can start an A lookup, switch to B, then release A's old result to
/// prove that the consumer ignores late identity resolutions.
final class TodayControlledSession implements CloudSessionPort {
  TodayControlledSession({String? initialAccountId})
    : _snapshot = initialAccountId == null
          ? const CloudSessionSnapshot(status: CloudSessionStatus.unknown)
          : CloudSessionSnapshot(
              status: CloudSessionStatus.signedIn,
              accountId: initialAccountId,
            );

  final StreamController<CloudSessionSnapshot> _updates =
      StreamController<CloudSessionSnapshot>.broadcast(sync: true);
  CloudSessionSnapshot _snapshot;
  Completer<AppResult<CloudSyncContext>>? _heldContext;

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.multi((listener) {
    listener.addSync(_snapshot);
    final subscription = _updates.stream.listen(
      listener.addSync,
      onError: listener.addErrorSync,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() {
    final held = _heldContext;
    if (held != null) return held.future;
    final accountId = _snapshot.accountId;
    if (_snapshot.status != CloudSessionStatus.signedIn || accountId == null) {
      return Future.value(
        AppResult.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.authorization,
            messageKey: 'foundation.sessionUnavailable',
            occurredAt: TodayFixtureTime.nowUtc,
          ),
        ),
      );
    }
    return Future.value(
      AppResult.success(CloudSyncContext(accountId: accountId)),
    );
  }

  void holdContext() {
    if (_heldContext != null) throw StateError('A context is already held');
    _heldContext = Completer<AppResult<CloudSyncContext>>();
  }

  void releaseContextFor(String accountId) {
    final held = _heldContext;
    if (held == null) throw StateError('No context is held');
    _heldContext = null;
    held.complete(AppResult.success(CloudSyncContext(accountId: accountId)));
  }

  void signIn(String accountId) => _set(
    CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: accountId,
    ),
  );

  void signOut() =>
      _set(const CloudSessionSnapshot(status: CloudSessionStatus.signedOut));

  void setUnknown() =>
      _set(const CloudSessionSnapshot(status: CloudSessionStatus.unknown));

  void _set(CloudSessionSnapshot snapshot) {
    _snapshot = snapshot;
    _updates.add(snapshot);
  }

  Future<void> close() => _updates.close();
}
