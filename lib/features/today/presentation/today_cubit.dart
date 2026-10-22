library;

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../application/today_calendar_port.dart';
import '../application/today_habits_port.dart';
import '../application/today_tasks_port.dart';
import '../application/today_xp_port.dart';
import '../domain/today_models.dart';
import '../domain/today_projection.dart';
import '../domain/today_scope.dart';
import '../domain/today_section.dart';
import 'today_state.dart';

class TodayCubit extends Cubit<TodayState> {
  TodayCubit({
    required TodayScope scope,
    required TodayCalendarPort calendar,
    required TodayTasksPort tasks,
    required TodayHabitsPort habits,
    required TodayXpPort xp,
    Duration initialDeadline = const Duration(seconds: 10),
  }) : _calendar = calendar,
       _tasks = tasks,
       _habits = habits,
       _xp = xp,
       _deadline = initialDeadline,
       super(
         TodayState.loading(scope, calendar.sample(projectionRevision: 0)),
       ) {
    _subscribeAll();
  }

  final TodayCalendarPort _calendar;
  final TodayTasksPort _tasks;
  final TodayHabitsPort _habits;
  final TodayXpPort _xp;
  final Duration _deadline;
  StreamSubscription<TodayTaskReadSnapshot>? _taskSub;
  StreamSubscription<TodayHabitReadSnapshot>? _habitSub;
  StreamSubscription<List<TodayAwardReference>>? _xpSub;
  Timer? _taskTimer;
  Timer? _habitTimer;
  Timer? _xpTimer;
  TodayTaskReadSnapshot? _taskSnapshot;
  TodayHabitReadSnapshot? _habitSnapshot;
  List<TodayAwardReference>? _awards;
  int _epoch = 0;

  void _subscribeAll() {
    _subscribeTasks();
    _subscribeHabits();
    _subscribeXp();
  }

  AppFailure _failure() => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'todaySourceUnavailable',
    occurredAt: DateTime.now().toUtc(),
  );

  TodaySection<T> _failed<T>(TodaySection<T> previous) => previous.value == null
      ? TodaySection.unavailable(_failure())
      : TodaySection.stale(previous.value as T, _failure());

  void _subscribeTasks() {
    final epoch = _epoch;
    _taskTimer?.cancel();
    unawaited(_taskSub?.cancel());
    _taskTimer = Timer(_deadline, () {
      if (isClosed ||
          epoch != _epoch ||
          state.tasks.status != TodaySectionStatus.loading) {
        return;
      }
      emit(state.copyWith(tasks: _failed(state.tasks)));
    });
    try {
      _taskSub = _tasks
          .watchTasks(state.scope.taskOwnerId)
          .listen(
            (snapshot) {
              if (isClosed ||
                  epoch != _epoch ||
                  snapshot.ownerId != state.scope.taskOwnerId) {
                return;
              }
              _taskTimer?.cancel();
              _taskSnapshot = snapshot;
              _projectTasks();
            },
            onError: (_, _) {
              if (isClosed || epoch != _epoch) return;
              _taskTimer?.cancel();
              emit(state.copyWith(tasks: _failed(state.tasks)));
            },
            onDone: () {
              if (isClosed || epoch != _epoch) return;
              _taskTimer?.cancel();
              emit(state.copyWith(tasks: _failed(state.tasks)));
            },
          );
    } catch (_) {
      _taskTimer?.cancel();
      emit(state.copyWith(tasks: _failed(state.tasks)));
    }
  }

  void _subscribeHabits() {
    final epoch = _epoch;
    _habitTimer?.cancel();
    unawaited(_habitSub?.cancel());
    _habitTimer = Timer(_deadline, () {
      if (isClosed ||
          epoch != _epoch ||
          state.habits.status != TodaySectionStatus.loading) {
        return;
      }
      emit(state.copyWith(habits: _failed(state.habits)));
    });
    try {
      _habitSub = _habits
          .watchHabits(state.scope.habitOwnerId)
          .listen(
            (snapshot) {
              if (isClosed ||
                  epoch != _epoch ||
                  snapshot.ownerId != state.scope.habitOwnerId) {
                return;
              }
              _habitTimer?.cancel();
              _habitSnapshot = snapshot;
              _projectHabits();
            },
            onError: (_, _) {
              if (isClosed || epoch != _epoch) return;
              _habitTimer?.cancel();
              emit(state.copyWith(habits: _failed(state.habits)));
            },
            onDone: () {
              if (isClosed || epoch != _epoch) return;
              _habitTimer?.cancel();
              emit(state.copyWith(habits: _failed(state.habits)));
            },
          );
    } catch (_) {
      _habitTimer?.cancel();
      emit(state.copyWith(habits: _failed(state.habits)));
    }
  }

  void _subscribeXp() {
    final epoch = _epoch;
    _xpTimer?.cancel();
    unawaited(_xpSub?.cancel());
    _xpTimer = Timer(_deadline, () {
      if (isClosed ||
          epoch != _epoch ||
          state.xp.status != TodaySectionStatus.loading) {
        return;
      }
      emit(state.copyWith(xp: _failed(state.xp)));
    });
    try {
      _xpSub = _xp
          .watchAwards(state.scope.xpOwnerId)
          .listen(
            (awards) {
              if (isClosed || epoch != _epoch) return;
              _xpTimer?.cancel();
              _awards = List.unmodifiable(awards);
              _projectXp();
            },
            onError: (_, _) {
              if (isClosed || epoch != _epoch) return;
              _xpTimer?.cancel();
              emit(state.copyWith(xp: _failed(state.xp)));
            },
            onDone: () {
              if (isClosed || epoch != _epoch) return;
              _xpTimer?.cancel();
              emit(state.copyWith(xp: _failed(state.xp)));
            },
          );
    } catch (_) {
      _xpTimer?.cancel();
      emit(state.copyWith(xp: _failed(state.xp)));
    }
  }

  void _projectTasks() {
    try {
      final value = TodayProjection.tasks(
        state.scope,
        state.calendar,
        _taskSnapshot!.project(state.calendar),
      );
      emit(
        state.copyWith(
          tasks: value.totalCount == 0
              ? TodaySection.empty(value)
              : TodaySection.available(value),
        ),
      );
    } catch (_) {
      emit(state.copyWith(tasks: _failed(state.tasks)));
    }
  }

  void _projectHabits() {
    try {
      final value = TodayProjection.habits(
        state.scope,
        state.calendar,
        _habitSnapshot!.project(state.calendar),
      );
      emit(
        state.copyWith(
          habits: value.totalCount == 0
              ? TodaySection.empty(value)
              : TodaySection.available(value),
        ),
      );
    } catch (_) {
      emit(state.copyWith(habits: _failed(state.habits)));
    }
  }

  void _projectXp() {
    try {
      final value = TodayProjection.xp(state.scope, state.calendar, _awards!);
      emit(
        state.copyWith(
          xp: value.awards.isEmpty
              ? TodaySection.empty(value)
              : TodaySection.available(value),
        ),
      );
    } catch (_) {
      emit(state.copyWith(xp: _failed(state.xp)));
    }
  }

  /// Re-sample the device calendar and reproject confirmed owner records.
  void refresh() {
    if (isClosed) return;
    final next = _calendar.sample(
      projectionRevision: state.calendar.projectionRevision + 1,
    );
    emit(state.copyWith(calendar: next));
    if (_taskSnapshot != null) _projectTasks();
    if (_habitSnapshot != null) _projectHabits();
    if (_awards != null) _projectXp();
  }

  /// A new identity clears every source before subscribing to the next owner.
  void changeScope(TodayScope scope) {
    if (isClosed ||
        (scope.scopeKey == state.scope.scopeKey &&
            scope.generation == state.scope.generation)) {
      return;
    }
    _epoch++;
    _taskTimer?.cancel();
    _habitTimer?.cancel();
    _xpTimer?.cancel();
    unawaited(_taskSub?.cancel());
    unawaited(_habitSub?.cancel());
    unawaited(_xpSub?.cancel());
    _taskSnapshot = null;
    _habitSnapshot = null;
    _awards = null;
    emit(TodayState.loading(scope, _calendar.sample(projectionRevision: 0)));
    _subscribeAll();
  }

  void retryTasks() {
    if (!isClosed) {
      emit(state.copyWith(tasks: TodaySection.loading()));
      _subscribeTasks();
    }
  }

  void retryHabits() {
    if (!isClosed) {
      emit(state.copyWith(habits: TodaySection.loading()));
      _subscribeHabits();
    }
  }

  void retryXp() {
    if (!isClosed) {
      emit(state.copyWith(xp: TodaySection.loading()));
      _subscribeXp();
    }
  }

  @override
  Future<void> close() async {
    _epoch++;
    _taskTimer?.cancel();
    _habitTimer?.cancel();
    _xpTimer?.cancel();
    await Future.wait([
      _taskSub?.cancel() ?? Future<void>.value(),
      _habitSub?.cancel() ?? Future<void>.value(),
      _xpSub?.cancel() ?? Future<void>.value(),
    ]);
    await super.close();
  }
}
