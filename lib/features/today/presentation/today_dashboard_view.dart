library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_theme.dart';

import '../domain/today_agenda.dart';
import '../domain/today_section.dart';
import 'dashboard_presentation.dart';
import 'today_state.dart';
import 'today_strings.dart';
import 'widgets/today_counters_card.dart';
import 'widgets/today_dashboard_header.dart';
import 'widgets/today_finance_card.dart';
import 'widgets/today_navigation_shell.dart';
import 'widgets/today_navigation_sidebar.dart';
import 'widgets/today_prayer_card.dart';
import 'widgets/today_priority_section.dart';
import 'widgets/today_progress_hero.dart';
import 'widgets/today_quick_hubs.dart';
import 'widgets/today_quran_card.dart';
import 'widgets/today_timeline_section.dart';

const Key kTodayScreenKey = Key('today_screen');
const Key kTodayTasksNavigationKey = Key('today_tasks_navigation');
const Key kTodayHabitsNavigationKey = Key('today_habits_navigation');
const Key kTodayMindMapsNavigationKey = Key('today_mind_maps_navigation');
const Key kTodayPreferencesKey = Key('today_preferences');

const Key kDashboardProgressGroup = Key('dashboard_group_progress');
const Key kDashboardPrayerGroup = Key('dashboard_group_prayer');
const Key kDashboardQuranGroup = Key('dashboard_group_quran');
const Key kDashboardHubsGroup = Key('dashboard_group_hubs');
const Key kDashboardTimelineGroup = Key('dashboard_group_timeline');
const Key kDashboardPriorityGroup = Key('dashboard_group_priority');
const Key kDashboardFinanceGroup = Key('dashboard_group_finance');
const Key kDashboardCountersGroup = Key('dashboard_group_counters');

/// Today dashboard screen presenting exactly eight ordered prototype groups:
/// 1. Today's Progress Hero
/// 2. Next Prayer Card
/// 3. Daily Quran Wird Card
/// 4. Quick Hubs (Prayer, Focus, Quran, Adhkar, Qiyam, Counters)
/// 5. Daily Smart Timeline
/// 6. Do First (Quadrant 1 Urgent & Important tasks)
/// 7. Financial & Savings Summary
/// 8. Habit Counters Snippet
///
/// Habits and Mind Maps are reached via More, preserving owner navigation.
class TodayDashboardView extends StatelessWidget {
  const TodayDashboardView({
    super.key,
    required this.state,
    required this.strings,
    required this.onRefresh,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
    required this.onRetryTasks,
    required this.onRetryHabits,
    required this.onRetryXp,
    required this.onSetTaskCompleted,
    required this.onSetHabitCompleted,
    this.onNewTask,
    this.onNewHabit,
    this.onTaskMatrix,
    this.onTaskOverdue,
  });

  final TodayState state;
  final TodayStrings strings;
  final VoidCallback onRefresh;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;
  final VoidCallback onRetryTasks;
  final VoidCallback onRetryHabits;
  final VoidCallback onRetryXp;
  final void Function(String, bool) onSetTaskCompleted;
  final void Function(String, bool) onSetHabitCompleted;
  final VoidCallback? onNewTask;
  final VoidCallback? onNewHabit;
  final VoidCallback? onTaskMatrix;
  final VoidCallback? onTaskOverdue;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final colors = baseTheme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: baseTheme.brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: baseTheme.brightness == Brightness.dark
              ? colors.background
              : Colors.white,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: colors.error,
        );

    final presentation = DashboardPresentation.fromState(state);
    final taskItems = state.tasks.value?.items ?? const [];
    final agenda = TodayAgenda.project(
      state.calendar.localDate,
      taskItems,
      ownerId: state.scope.taskOwnerId,
    );
    final doFirstTasks = state.tasks.value?.doFirst ?? const [];
    final localNow = state.calendar.nowUtc.add(
      Duration(minutes: state.calendar.utcOffsetMinutes),
    );

    return Theme(
      data: baseTheme.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: colors.background,
        cardTheme: CardThemeData(
          color: colors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.border),
          ),
        ),
        textTheme: baseTheme.textTheme.apply(
          fontFamily: kProjectFontFamily,
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        ),
        dividerColor: colors.border,
      ),
      child: LayoutBuilder(
        builder: (context, viewport) {
          final showSidebar = viewport.maxWidth >= kTodaySidebarBreakpoint;
          final mainWidth =
              viewport.maxWidth - (showSidebar ? kTodaySidebarWidth : 0);
          final dateRowHeight = TodayDashboardHeader.dateRowHeightFor(
            mainWidth,
            MediaQuery.textScalerOf(context).scale(1.0),
          );
          final headerInset = mainWidth > 1024
              ? (mainWidth - 1024) / 2 + 24
              : mainWidth >= 640
              ? 24.0
              : mainWidth < 360
              ? 8.0
              : 16.0;

          return TodayNavigationShell(
            colors: colors,
            section: TodayNavigationSection.home,
            onTasks: onTasks,
            onHabits: onHabits,
            onMindMaps: onMindMaps,
            onPreferences: onPreferences,
            xpAmount: state.xp.value?.amount,
            child: Scaffold(
              key: kTodayScreenKey,
              extendBodyBehindAppBar: true,
              appBar: TodayDashboardHeader(
                state: state,
                strings: strings,
                colors: colors,
                onPreferences: onPreferences,
                dateRowHeight: dateRowHeight,
                horizontalInset: headerInset,
                onNewTask: onNewTask,
                onNewHabit: onNewHabit,
              ),
              body: SafeArea(
                top: false,
                child: RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final horizontalPadding = width < 360
                          ? 8.0
                          : width >= 640
                          ? 24.0
                          : 16.0;
                      final maxContentWidth = width >= 1024 ? 1024.0 : width;
                      final bottomClearance =
                          32.0 + MediaQuery.paddingOf(context).bottom;

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxContentWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.paddingOf(context).top +
                                            16,
                                      ),

                                      // 1. TODAY'S PROGRESS HERO
                                      TodayProgressHero(
                                        state: state,
                                        presentation: presentation,
                                        strings: strings,
                                        colors: colors,
                                        onOpenHabits: onHabits,
                                        onOpenTasks: onTasks,
                                        onRetryTasks: onRetryTasks,
                                        onRetryHabits: onRetryHabits,
                                        onRetryXp: onRetryXp,
                                      ),
                                      const SizedBox(height: 20),

                                      // 2. NEXT PRAYER CARD
                                      TodayPrayerCard(colors: colors),
                                      const SizedBox(height: 20),

                                      // 3. DAILY QURAN WIRD CARD
                                      TodayQuranCard(colors: colors),
                                      const SizedBox(height: 20),

                                      // 4. QUICK ACTION HUBS
                                      TodayQuickHubs(colors: colors),
                                      const SizedBox(height: 20),

                                      // 5. SMART DAILY TIMELINE
                                      TodayTimelineSection(
                                        agenda: agenda,
                                        status: state.tasks.status,
                                        actions: state.taskActions,
                                        currentMinuteOfDay:
                                            localNow.hour * 60 +
                                            localNow.minute,
                                        strings: strings,
                                        colors: colors,
                                        onOpenTasks: onTasks,
                                        onSetTaskCompleted:
                                            state.tasks.status ==
                                                TodaySectionStatus.available
                                            ? onSetTaskCompleted
                                            : null,
                                      ),
                                      const SizedBox(height: 20),

                                      // 6. DO FIRST (Quadrant 1 Urgent & Important)
                                      TodayPrioritySection(
                                        tasks: doFirstTasks,
                                        status: state.tasks.status,
                                        actions: state.taskActions,
                                        strings: strings,
                                        colors: colors,
                                        onOpenTasks: onTasks,
                                        onOpenMatrix: onTaskMatrix ?? onTasks,
                                        onSetTaskCompleted:
                                            state.tasks.status ==
                                                TodaySectionStatus.available
                                            ? onSetTaskCompleted
                                            : null,
                                      ),
                                      const SizedBox(height: 20),

                                      // 7. FINANCIAL & SAVINGS SUMMARY
                                      TodayFinanceCard(colors: colors),
                                      const SizedBox(height: 20),

                                      // 8. HABIT COUNTERS SNIPPET
                                      TodayCountersCard(
                                        colors: colors,
                                        strings: strings,
                                      ),
                                      SizedBox(height: bottomClearance),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
