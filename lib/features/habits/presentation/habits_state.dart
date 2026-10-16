import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';

sealed class HabitsState {
  const HabitsState();
}

final class HabitsInitial extends HabitsState {
  const HabitsInitial();
}

final class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

final class HabitsFailure extends HabitsState {
  const HabitsFailure(this.failure);
  final AppFailure failure;
}

final class HabitsReady extends HabitsState {
  HabitsReady({
    required this.accountId,
    required Iterable<HabitToday> today,
    this.lastFailure,
  }) : today = List.unmodifiable(today);

  final String accountId;
  final List<HabitToday> today;
  final AppFailure? lastFailure;
}
