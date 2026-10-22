library;

import '../domain/today_calendar.dart';
import '../domain/today_projection.dart';
import '../domain/today_scope.dart';
import '../domain/today_section.dart';

final class TodayState {
  const TodayState({
    required this.scope,
    required this.calendar,
    required this.tasks,
    required this.habits,
    required this.xp,
  });

  factory TodayState.loading(TodayScope scope, TodayCalendar calendar) =>
      TodayState(
        scope: scope,
        calendar: calendar,
        tasks: TodaySection.loading(),
        habits: TodaySection.loading(),
        xp: TodaySection.loading(),
      );

  final TodayScope scope;
  final TodayCalendar calendar;
  final TodaySection<TodayTaskSummary> tasks;
  final TodaySection<TodayHabitSummary> habits;
  final TodaySection<TodayXpSummary> xp;

  TodayState copyWith({
    TodayCalendar? calendar,
    TodaySection<TodayTaskSummary>? tasks,
    TodaySection<TodayHabitSummary>? habits,
    TodaySection<TodayXpSummary>? xp,
  }) => TodayState(
    scope: scope,
    calendar: calendar ?? this.calendar,
    tasks: tasks ?? this.tasks,
    habits: habits ?? this.habits,
    xp: xp ?? this.xp,
  );
}
