library;

import 'package:flutter/foundation.dart';

import '../domain/today_models.dart';
import '../domain/today_projection.dart';
import '../domain/today_section.dart';
import 'dashboard_display_value.dart';
import 'dashboard_preview_data.dart';
import 'today_state.dart';

/// Presentation projection for the Dashboard view.
///
/// Maps owner sections (Tasks, Habits, XP) to explicit [DashboardDisplayValue]
/// provenances (live, loading, empty, stale, unavailable) without blending
/// Task and Habit scores or generating fake numbers.
@immutable
final class DashboardPresentation {
  const DashboardPresentation({
    required this.tasks,
    required this.habits,
    required this.xp,
    required this.doFirstTasks,
    required this.timelineTasks,
    this.preview = DashboardPreviewData.standard,
  });

  /// Derives presentation projection directly from [TodayState].
  factory DashboardPresentation.fromState(
    TodayState state, {
    DashboardPreviewData preview = DashboardPreviewData.standard,
  }) {
    final tasksVal = _mapSection(state.tasks);
    final habitsVal = _mapSection(state.habits);
    final xpVal = _mapSection(state.xp);

    final doFirstVal = switch (state.tasks.status) {
      TodaySectionStatus.available =>
        DashboardDisplayValue<List<TodayTaskReference>>.live(
          state.tasks.value?.doFirst ?? const [],
        ),
      TodaySectionStatus.empty =>
        DashboardDisplayValue<List<TodayTaskReference>>.empty(const []),
      TodaySectionStatus.loading =>
        const DashboardDisplayValue<List<TodayTaskReference>>.loading(),
      TodaySectionStatus.stale =>
        DashboardDisplayValue<List<TodayTaskReference>>.stale(
          state.tasks.value?.doFirst ?? const [],
        ),
      TodaySectionStatus.unavailable =>
        const DashboardDisplayValue<List<TodayTaskReference>>.unavailable(),
    };

    final timelineVal = switch (state.tasks.status) {
      TodaySectionStatus.available =>
        DashboardDisplayValue<List<TodayTaskReference>>.live(
          state.tasks.value?.items ?? const [],
        ),
      TodaySectionStatus.empty =>
        DashboardDisplayValue<List<TodayTaskReference>>.empty(const []),
      TodaySectionStatus.loading =>
        const DashboardDisplayValue<List<TodayTaskReference>>.loading(),
      TodaySectionStatus.stale =>
        DashboardDisplayValue<List<TodayTaskReference>>.stale(
          state.tasks.value?.items ?? const [],
        ),
      TodaySectionStatus.unavailable =>
        const DashboardDisplayValue<List<TodayTaskReference>>.unavailable(),
    };

    return DashboardPresentation(
      tasks: tasksVal,
      habits: habitsVal,
      xp: xpVal,
      doFirstTasks: doFirstVal,
      timelineTasks: timelineVal,
      preview: preview,
    );
  }

  /// Live or status-indicated Task summary.
  final DashboardDisplayValue<TodayTaskSummary> tasks;

  /// Live or status-indicated Habit summary.
  final DashboardDisplayValue<TodayHabitSummary> habits;

  /// Live or status-indicated XP summary.
  final DashboardDisplayValue<TodayXpSummary> xp;

  /// Live or status-indicated Eisenhower Q1 tasks for Do First.
  final DashboardDisplayValue<List<TodayTaskReference>> doFirstTasks;

  /// Live or status-indicated timeline tasks.
  final DashboardDisplayValue<List<TodayTaskReference>> timelineTasks;

  /// Central fixture for sample values (prayer, quran, finance, counters, etc.).
  final DashboardPreviewData preview;

  // Task metrics
  int get tasksCompleted => tasks.value?.completedCount ?? 0;
  int get tasksTotal => tasks.value?.totalCount ?? 0;
  int? get tasksPercent => tasks.value?.percent;

  // Habit metrics (completely independent of tasks)
  int get habitsCompleted => habits.value?.completedCount ?? 0;
  int get habitsTotal => habits.value?.totalCount ?? 0;
  int? get habitsPercent => habits.value?.percent;

  // XP
  int get xpAmount => xp.value?.amount ?? 0;

  // Helper flags
  bool get isTasksLoading => tasks.isLoading;
  bool get isTasksUnavailable => tasks.isUnavailable;
  bool get isTasksStale => tasks.isStale;
  bool get isTasksEmpty => tasks.isEmpty;

  bool get isHabitsLoading => habits.isLoading;
  bool get isHabitsUnavailable => habits.isUnavailable;
  bool get isHabitsStale => habits.isStale;
  bool get isHabitsEmpty => habits.isEmpty;

  bool get isXpLoading => xp.isLoading;
  bool get isXpUnavailable => xp.isUnavailable;
  bool get isXpStale => xp.isStale;

  static DashboardDisplayValue<T> _mapSection<T>(TodaySection<T> section) {
    return switch (section.status) {
      TodaySectionStatus.available => DashboardDisplayValue.live(
        section.value as T,
      ),
      TodaySectionStatus.empty => DashboardDisplayValue.empty(section.value),
      TodaySectionStatus.loading => const DashboardDisplayValue.loading(),
      TodaySectionStatus.stale => DashboardDisplayValue.stale(
        section.value as T,
      ),
      TodaySectionStatus.unavailable =>
        const DashboardDisplayValue.unavailable(),
    };
  }
}
