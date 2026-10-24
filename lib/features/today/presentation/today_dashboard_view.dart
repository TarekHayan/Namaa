library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_theme.dart';

import '../domain/today_agenda.dart';
import '../domain/today_projection.dart';
import '../domain/today_section.dart';
import 'today_state.dart';
import 'today_strings.dart';
import 'widgets/today_agenda_section.dart';
import 'widgets/today_bottom_navigation.dart';
import 'widgets/today_dashboard_header.dart';
import 'widgets/today_finance_card.dart';
import 'widgets/today_focus_reflection_card.dart';
import 'widgets/today_habit_list.dart';
import 'widgets/today_navigation_sidebar.dart';
import 'widgets/today_overdue_section.dart';
import 'widgets/today_prayer_card.dart';
import 'widgets/today_priority_section.dart';
import 'widgets/today_quran_card.dart';
import 'widgets/today_summary_section.dart';

const Key kTodayScreenKey = Key('today_screen');
const Key kTodayTasksNavigationKey = Key('today_tasks_navigation');
const Key kTodayHabitsNavigationKey = Key('today_habits_navigation');
const Key kTodayMindMapsNavigationKey = Key('today_mind_maps_navigation');
const Key kTodayPreferencesKey = Key('today_preferences');

/// Today dashboard screen presenting real task/habit projections and comprehensive
/// domain modules with brand emerald styling and responsive multi-device layouts.
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
    final copy = FoundationLocalizations.of(context);
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

    return Theme(
      data: baseTheme.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: colors.background,
        cardTheme: CardThemeData(
          color: colors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
          final showSidebar = viewport.maxWidth >= 1100;
          return Row(
            children: [
              if (showSidebar)
                SizedBox(
                  width: 252,
                  child: TodayNavigationSidebar(
                    colors: colors,
                    xpAmount: state.xp.value?.amount,
                    onTasks: onTasks,
                    onHabits: onHabits,
                    onMindMaps: onMindMaps,
                    onPreferences: onPreferences,
                  ),
                ),
              Expanded(
                child: Scaffold(
                  key: kTodayScreenKey,
                  bottomNavigationBar: showSidebar
                      ? null
                      : TodayBottomNavigation(
                          colors: colors,
                          onTasks: onTasks,
                          onHabits: onHabits,
                          onMindMaps: onMindMaps,
                          onPreferences: onPreferences,
                        ),
                  appBar: TodayDashboardHeader(
                    state: state,
                    strings: strings,
                    colors: colors,
                    onPreferences: onPreferences,
                    onNewTask: onNewTask,
                    onNewHabit: onNewHabit,
                  ),
                  body: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: () async => onRefresh(),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final contentWidth = width > 1328
                              ? 1280.0
                              : (width > 48 ? width - 32 : width);
                          final isDesktop = contentWidth >= 1100;
                          final isTablet = contentWidth >= 768 && !isDesktop;

                          return CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Center(
                                  child: SizedBox(
                                    width: contentWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 18),
                                          _hero(context, copy, colors),
                                          const SizedBox(height: 24),
                                          _heading(
                                            context,
                                            copy.dashboardOverview,
                                          ),
                                          const SizedBox(height: 12),
                                          _overview(context, copy, colors),
                                          const SizedBox(height: 24),
                                          if (isDesktop)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Column 1: Daily Execution (Tasks & Habits)
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      _tasks(context, colors),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _habits(context, colors),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                // Column 2: Spiritual Routine (Prayer & Quran)
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      TodayPrayerCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      TodayQuranCard(
                                                        colors: colors,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                // Column 3: Life & Focus (Finance, Focus, Explore)
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      TodayFinanceCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      TodayFocusReflectionCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _explore(
                                                        context,
                                                        copy,
                                                        colors,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          else if (isTablet)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Column 1: Execution & Explore
                                                Expanded(
                                                  flex: 6,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      _tasks(context, colors),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _habits(context, colors),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _explore(
                                                        context,
                                                        copy,
                                                        colors,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                // Column 2: Spiritual & Lifestyle
                                                Expanded(
                                                  flex: 6,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      TodayPrayerCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      TodayQuranCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      TodayFinanceCard(
                                                        colors: colors,
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      TodayFocusReflectionCard(
                                                        colors: colors,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          else ...[
                                            // Mobile single column
                                            _tasks(context, colors),
                                            const SizedBox(height: 20),
                                            _habits(context, colors),
                                            const SizedBox(height: 20),
                                            TodayPrayerCard(colors: colors),
                                            const SizedBox(height: 20),
                                            TodayQuranCard(colors: colors),
                                            const SizedBox(height: 20),
                                            TodayFinanceCard(colors: colors),
                                            const SizedBox(height: 20),
                                            TodayFocusReflectionCard(
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 20),
                                            _explore(context, copy, colors),
                                          ],
                                          const SizedBox(height: 36),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) {
    final hour = state.calendar.nowUtc
        .add(Duration(minutes: state.calendar.utcOffsetMinutes))
        .hour;
    final xp = state.xp.value?.amount ?? 0;
    final level = (xp ~/ 200) + 1;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.secondary, colors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardGlow,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top metadata row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      strings.formatDate(state.calendar.localDate),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        copy.dashboardEncryptedBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Greeting & Level XP row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hour < 12
                          ? copy.dashboardGreetingMorning
                          : copy.dashboardGreetingLater,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.dashboardSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            copy.dashboardLevelBadge(level, xp),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.dashboardProductiveDay,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Action Buttons
          if (onNewTask != null || onNewHabit != null) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (onNewTask != null)
                  FilledButton.icon(
                    key: const Key('today_new_task'),
                    onPressed: onNewTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: Text(
                      strings.newTask,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (onNewHabit != null)
                  OutlinedButton.icon(
                    key: const Key('today_new_habit'),
                    onPressed: onNewHabit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      strings.newHabit,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _overview(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 740
          ? 3
          : constraints.maxWidth >= 480
          ? 2
          : 1;
      final gap = 12.0;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: width,
            child: TodaySummarySection<TodayTaskSummary>(
              title: copy.dashboardTasksProgress,
              icon: Icons.check_circle_outline_rounded,
              section: state.tasks,
              strings: strings,
              onRetry: onRetryTasks,
              content: (summary) => _progress(
                context,
                colors,
                summary.completedCount,
                summary.totalCount,
                summary.percent,
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TodaySummarySection<TodayHabitSummary>(
              title: copy.dashboardHabitsProgress,
              icon: Icons.autorenew_rounded,
              section: state.habits,
              strings: strings,
              onRetry: onRetryHabits,
              content: (summary) => _progress(
                context,
                colors,
                summary.completedCount,
                summary.totalCount,
                summary.percent,
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: TodaySummarySection<TodayXpSummary>(
              title: copy.dashboardXpEarned,
              icon: Icons.auto_awesome_outlined,
              section: state.xp,
              strings: strings,
              onRetry: onRetryXp,
              content: (summary) => Text(
                strings.formatXp(summary.amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _progress(
    BuildContext context,
    AppColors colors,
    int completed,
    int total,
    int? percent,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        total == 0
            ? '${strings.formatCount(completed)}/${strings.formatCount(total)}'
            : '${strings.formatCount(completed)}/${strings.formatCount(total)} · ${strings.formatPercent(percent!)}',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : completed / total,
          minHeight: 7,
          backgroundColor: colors.surfaceSecondary,
          valueColor: AlwaysStoppedAnimation(colors.primary),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${strings.open}: ${strings.formatCount(total - completed)} · ${strings.completed}: ${strings.formatCount(completed)}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      ),
    ],
  );

  Widget _tasks(BuildContext context, AppColors colors) => _Surface(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader(
          context,
          colors,
          Icons.checklist_rtl_rounded,
          strings.tasks,
          TextButton.icon(
            key: kTodayTasksNavigationKey,
            onPressed: onTasks,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(strings.tasks),
          ),
        ),
        if (state.tasks.value case final summary?) ...[
          const SizedBox(height: 12),
          TodayPrioritySection(
            tasks: summary.doFirst,
            strings: strings,
            onOpenTasks: onTasks,
            onOpenMatrix: onTaskMatrix ?? onTasks,
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border),
          const SizedBox(height: 12),
          TodayAgendaSection(
            agenda: TodayAgenda.project(
              state.calendar.localDate,
              summary.items,
              ownerId: state.scope.taskOwnerId,
            ),
            strings: strings,
            onOpenTasks: onTasks,
            actions: state.taskActions,
            allowActions: state.tasks.status == TodaySectionStatus.available,
            onSetCompleted: state.tasks.status == TodaySectionStatus.available
                ? onSetTaskCompleted
                : null,
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border),
          TodayOverdueSection(
            count: summary.overdueCount,
            strings: strings,
            onOpenOverdue: onTaskOverdue ?? onTasks,
          ),
        ],
      ],
    ),
  );

  Widget _habits(BuildContext context, AppColors colors) => _Surface(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader(
          context,
          colors,
          Icons.autorenew_rounded,
          strings.habits,
          TextButton.icon(
            key: kTodayHabitsNavigationKey,
            onPressed: onHabits,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(strings.habits),
          ),
        ),
        if (state.habits.value case final summary?) ...[
          const SizedBox(height: 12),
          if (summary.totalCount == 0)
            Text(strings.noHabits)
          else
            TodayHabitList(
              habits: summary.items,
              strings: strings,
              actions: state.habitActions,
              onSetCompleted:
                  state.habits.status == TodaySectionStatus.available
                  ? onSetHabitCompleted
                  : null,
            ),
        ],
      ],
    ),
  );

  Widget _explore(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => _Surface(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, copy.dashboardExplore),
        const SizedBox(height: 12),
        ListTile(
          key: kTodayMindMapsNavigationKey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: colors.surfaceSecondary,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.hub_outlined, color: colors.primary, size: 20),
          ),
          title: Text(
            strings.mindMaps,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(copy.dashboardMindMapsHint),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
          onTap: onMindMaps,
        ),
      ],
    ),
  );

  Widget _heading(BuildContext context, String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  Widget _panelHeader(
    BuildContext context,
    AppColors colors,
    IconData icon,
    String title,
    Widget action,
  ) => Row(
    children: [
      Icon(icon, color: colors.primary, size: 22),
      const SizedBox(width: 8),
      Expanded(child: _heading(context, title)),
      action,
    ],
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.colors, required this.child});
  final AppColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(22),
      boxShadow: Theme.of(context).brightness == Brightness.light
          ? [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.035),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    ),
    child: child,
  );
}
