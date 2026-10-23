library;

import 'dart:async';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/application/habit_sync_service.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../application/today_habits_port.dart';
import '../domain/today_calendar.dart';
import '../domain/today_models.dart';

final class HabitsTodayAdapter implements TodayHabitsPort {
  const HabitsTodayAdapter(
    this._repository, {
    HabitCommands? commands,
    HabitSyncService? syncService,
  }) : _commands = commands,
       _syncService = syncService;
  final HabitRepository _repository;
  final HabitCommands? _commands;
  final HabitSyncService? _syncService;

  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    final commands = _commands;
    if (commands == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'today.action.unavailable',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
    final result = completed
        ? await commands.completeHabitToday(
            habitId,
            expectedAccountId: ownerId,
            expectedLocalDate: expectedLocalDate.key,
          )
        : await commands.undoHabitToday(
            habitId,
            expectedAccountId: ownerId,
            expectedLocalDate: expectedLocalDate.key,
          );
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    if (_syncService != null) unawaited(_syncService.synchronize());
    return const AppResult.success(null);
  }

  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) {
    late StreamController<TodayHabitReadSnapshot> controller;
    StreamSubscription<List<Habit>>? habitSub;
    StreamSubscription<List<HabitDay>>? daySub;
    List<Habit>? habits;
    List<HabitDay>? days;
    var stopped = false;
    void emitPair() {
      if (!stopped && habits != null && days != null) {
        controller.add(_Snapshot(ownerId, habits!, days!));
      }
    }

    void fail(Object error, StackTrace stack) {
      if (stopped) return;
      stopped = true;
      controller.addError(error, stack);
      unawaited(habitSub?.cancel());
      unawaited(daySub?.cancel());
      unawaited(controller.close());
    }

    controller = StreamController<TodayHabitReadSnapshot>(
      onListen: () {
        try {
          habitSub = _repository
              .watchHabits(ownerId)
              .listen(
                (value) {
                  habits = value;
                  emitPair();
                },
                onError: fail,
                onDone: () =>
                    fail(StateError('Habit stream closed'), StackTrace.current),
              );
          if (stopped) {
            unawaited(habitSub?.cancel());
            return;
          }
          daySub = _repository
              .watchDays(ownerId)
              .listen(
                (value) {
                  days = value;
                  emitPair();
                },
                onError: fail,
                onDone: () => fail(
                  StateError('Habit day stream closed'),
                  StackTrace.current,
                ),
              );
          if (stopped) unawaited(daySub?.cancel());
        } catch (error, stack) {
          fail(error, stack);
        }
      },
      onCancel: () async {
        stopped = true;
        await habitSub?.cancel();
        await daySub?.cancel();
      },
    );
    return controller.stream;
  }
}

final class _Snapshot implements TodayHabitReadSnapshot {
  _Snapshot(this.ownerId, Iterable<Habit> habits, Iterable<HabitDay> days)
    : _habits = List.unmodifiable(
        habits.where((habit) => habit.accountId == ownerId && !habit.isDeleted),
      ),
      _days = List.unmodifiable(days.where((day) => day.accountId == ownerId));

  @override
  final String ownerId;
  final List<Habit> _habits;
  final List<HabitDay> _days;

  @override
  List<TodayHabitReference> project(TodayCalendar calendar) {
    final values = HabitQueries.today(
      accountId: ownerId,
      localDate: calendar.localDate.key,
      habits: _habits,
      days: _days,
    );
    return List.unmodifiable([
      for (var index = 0; index < values.length; index++)
        TodayHabitReference(
          habitId: values[index].habit.id,
          ownerId: ownerId,
          name: values[index].habit.name,
          localDate: calendar.localDate,
          isDue: values[index].isDue,
          isCompleted: values[index].isCompleted,
          earnedWhileDue: values[index].day?.earnedWhileDue ?? false,
          currentStreak: values[index].currentStreak,
          ownerOrder: index,
        ),
    ]);
  }
}
