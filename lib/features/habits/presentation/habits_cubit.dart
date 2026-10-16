import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habits_state.dart';

final class HabitsCubit extends Cubit<HabitsState> {
  HabitsCubit({
    required HabitRepository repository,
    required HabitCommands commands,
    required HabitCalendar localCalendar,
  }) : _repository = repository,
       _commands = commands,
       _localCalendar = localCalendar,
       super(const HabitsInitial());

  final HabitRepository _repository;
  final HabitCommands _commands;
  final HabitCalendar _localCalendar;
  StreamSubscription<List<Habit>>? _habitSubscription;
  StreamSubscription<List<HabitDay>>? _daySubscription;
  Timer? _dayTimer;
  List<Habit>? _habits;
  List<HabitDay>? _days;
  String? _accountId;
  AppFailure? _lastFailure;

  Future<void> load(String accountId) async {
    if (_accountId == accountId && _habitSubscription != null) return;
    await _habitSubscription?.cancel();
    await _daySubscription?.cancel();
    _dayTimer?.cancel();
    _accountId = accountId;
    _habits = null;
    _days = null;
    _lastFailure = null;
    emit(const HabitsLoading());
    _habitSubscription = _repository.watchHabits(accountId).listen((rows) {
      _habits = rows;
      _emitProjection();
    }, onError: _observedError);
    _daySubscription = _repository.watchDays(accountId).listen((rows) {
      _days = rows;
      _emitProjection();
    }, onError: _observedError);
    _scheduleDayChange();
  }

  Future<AppResult<Habit>> createHabit(CreateHabitInput input) =>
      _capture(_commands.createHabit(input, expectedAccountId: _accountId));

  Future<AppResult<HabitDay>> completeToday(String habitId) => _capture(
    _commands.completeHabitToday(habitId, expectedAccountId: _accountId),
  );

  Future<AppResult<HabitDay>> undoToday(String habitId) => _capture(
    _commands.undoHabitToday(habitId, expectedAccountId: _accountId),
  );

  Future<AppResult<T>> _capture<T>(Future<AppResult<T>> action) async {
    final result = await action;
    _lastFailure = result.failureOrNull;
    _emitProjection();
    return result;
  }

  void clearFailure() {
    _lastFailure = null;
    _emitProjection();
  }

  void _observedError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    final failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'habits.error.load',
      occurredAt: DateTime.now().toUtc(),
    );
    if (state is HabitsReady) {
      _lastFailure = failure;
      _emitProjection();
    } else {
      emit(HabitsFailure(failure));
    }
  }

  void _emitProjection() {
    if (isClosed || _accountId == null || _habits == null || _days == null) {
      return;
    }
    final localDate = _localCalendar().localDate;
    emit(
      HabitsReady(
        accountId: _accountId!,
        today: HabitQueries.today(
          accountId: _accountId!,
          localDate: localDate,
          habits: _habits!,
          days: _days!,
        ),
        lastFailure: _lastFailure,
      ),
    );
  }

  void resume() {
    _emitProjection();
    _scheduleDayChange();
  }

  void pause() {
    _dayTimer?.cancel();
    _dayTimer = null;
  }

  void _scheduleDayChange() {
    _dayTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(next.difference(now), () {
      _emitProjection();
      if (!isClosed) _scheduleDayChange();
    });
  }

  @override
  Future<void> close() async {
    pause();
    await _habitSubscription?.cancel();
    await _daySubscription?.cancel();
    await super.close();
  }
}
