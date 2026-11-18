library;

import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../domain/today_adhkar_qiyam_reference.dart';
import '../domain/today_calendar.dart';
import '../domain/today_prayer_reference.dart';
import '../domain/today_projection.dart';
import '../domain/today_scope.dart';
import '../domain/today_section.dart';

enum TodayActionPhase { pending, saved, failed, uncertain }

final class TodayActionFeedback {
  const TodayActionFeedback(this.phase, this.desiredCompleted, [this.failure]);
  final TodayActionPhase phase;
  final bool desiredCompleted;
  final AppFailure? failure;
  bool get blocksAction =>
      phase == TodayActionPhase.pending ||
      phase == TodayActionPhase.saved ||
      phase == TodayActionPhase.uncertain;
}

final class TodayState {
  const TodayState({
    required this.scope,
    required this.calendar,
    required this.tasks,
    required this.habits,
    required this.xp,
    this.prayer,
    this.adhkarQiyam,
    this.taskActions = const {},
    this.habitActions = const {},
  });

  factory TodayState.loading(
    TodayScope scope,
    TodayCalendar calendar, {
    bool prayerEnabled = false,
    bool adhkarQiyamEnabled = false,
  }) => TodayState(
    scope: scope,
    calendar: calendar,
    tasks: TodaySection.loading(),
    habits: TodaySection.loading(),
    xp: TodaySection.loading(),
    prayer: prayerEnabled ? TodaySection.loading() : null,
    adhkarQiyam: adhkarQiyamEnabled ? TodaySection.loading() : null,
  );

  final TodayScope scope;
  final TodayCalendar calendar;
  final TodaySection<TodayTaskSummary> tasks;
  final TodaySection<TodayHabitSummary> habits;
  final TodaySection<TodayXpSummary> xp;
  final TodaySection<TodayPrayerReference>? prayer;

  /// Adhkar and Qiyam progress, an independent source like Prayer; null when
  /// no source is wired (the Home shows no value for it then).
  final TodaySection<TodayAdhkarQiyamReference>? adhkarQiyam;
  final Map<String, TodayActionFeedback> taskActions;
  final Map<String, TodayActionFeedback> habitActions;

  TodayState copyWith({
    TodayCalendar? calendar,
    TodaySection<TodayTaskSummary>? tasks,
    TodaySection<TodayHabitSummary>? habits,
    TodaySection<TodayXpSummary>? xp,
    TodaySection<TodayPrayerReference>? prayer,
    TodaySection<TodayAdhkarQiyamReference>? adhkarQiyam,
    Map<String, TodayActionFeedback>? taskActions,
    Map<String, TodayActionFeedback>? habitActions,
  }) => TodayState(
    scope: scope,
    calendar: calendar ?? this.calendar,
    tasks: tasks ?? this.tasks,
    habits: habits ?? this.habits,
    xp: xp ?? this.xp,
    prayer: prayer ?? this.prayer,
    adhkarQiyam: adhkarQiyam ?? this.adhkarQiyam,
    taskActions: taskActions ?? this.taskActions,
    habitActions: habitActions ?? this.habitActions,
  );
}
