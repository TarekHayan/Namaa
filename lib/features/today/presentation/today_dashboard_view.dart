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
import 'widgets/today_bottom_navigation.dart';
import 'widgets/today_coming_soon_page.dart';
import 'widgets/today_dashboard_header.dart';
import 'widgets/today_navigation_sidebar.dart';
import 'widgets/today_overdue_section.dart';
import 'widgets/today_priority_section.dart';
import 'widgets/today_task_list.dart';

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

/// A glanceable daily overview. Detailed work stays in its owning section.
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
                          final contentWidth = width > 1072
                              ? 1024.0
                              : (width > 48 ? width - 32 : width);

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
                                          const SizedBox(height: 16),
                                          KeyedSubtree(
                                            key: kDashboardProgressGroup,
                                            child: _progressHero(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardPrayerGroup,
                                            child: _prayerPreview(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardQuranGroup,
                                            child: _quranPreview(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardHubsGroup,
                                            child: _quickHubs(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardTimelineGroup,
                                            child: _tasks(context, colors),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardPriorityGroup,
                                            child: _priority(context, colors),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardFinanceGroup,
                                            child: _financePreview(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          KeyedSubtree(
                                            key: kDashboardCountersGroup,
                                            child: _counterPreview(
                                              context,
                                              copy,
                                              colors,
                                            ),
                                          ),
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

  Widget _progressHero(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) {
    final taskSummary = state.tasks.value;
    final taskPercent = taskSummary?.percent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              colors.primary.withValues(alpha: isDark ? 0.13 : 0.09),
              colors.surface,
            ),
            colors.surface,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ring = SizedBox(
            width: 136,
            height: 136,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 124,
                  height: 124,
                  child: CircularProgressIndicator(
                    value: (taskPercent ?? 0) / 100,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colors.surfaceSecondary,
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      taskPercent == null
                          ? '—'
                          : strings.formatPercent(taskPercent),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      strings.tasks,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.dashboardOverview,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                copy.dashboardSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _liveSummary(
                    context,
                    copy.dashboardTasksProgress,
                    _sourceValue(
                      context,
                      state.tasks,
                      onRetryTasks,
                      (TodayTaskSummary value) =>
                          '${strings.formatCount(value.completedCount)}/${strings.formatCount(value.totalCount)}',
                    ),
                    colors,
                  ),
                  _liveSummary(
                    context,
                    copy.dashboardHabitsProgress,
                    _sourceValue(
                      context,
                      state.habits,
                      onRetryHabits,
                      (TodayHabitSummary value) =>
                          '${strings.formatCount(value.completedCount)}/${strings.formatCount(value.totalCount)}',
                    ),
                    colors,
                  ),
                  _liveSummary(
                    context,
                    copy.dashboardXpEarned,
                    _sourceValue(
                      context,
                      state.xp,
                      onRetryXp,
                      (TodayXpSummary value) => strings.formatXp(value.amount),
                    ),
                    colors,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, grid) {
                  final columns = grid.maxWidth >= 600 ? 3 : 2;
                  const gap = 8.0;
                  final tileWidth =
                      (grid.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _heroMetric(
                        context,
                        strings.tasks,
                        Text('3/5', style: _metricTextStyle(context)),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardSampleBadge} · ${copy.dashboardComingSoon}',
                      ),
                      _heroMetric(
                        context,
                        copy.dashboardPrayerShort,
                        Text('3/5', style: _metricTextStyle(context)),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardComingSoon} · ${copy.dashboardSampleBadge}',
                      ),
                      _heroMetric(
                        context,
                        copy.dashboardQuran,
                        Text('7/20', style: _metricTextStyle(context)),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardComingSoon} · ${copy.dashboardSampleBadge}',
                      ),
                      _heroMetric(
                        context,
                        copy.dashboardAdhkarTitle,
                        Text('12/33', style: _metricTextStyle(context)),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardSampleBadge} · ${copy.dashboardComingSoon}',
                      ),
                      _heroMetric(
                        context,
                        copy.dashboardFocus,
                        Text(
                          strings.formatDurationMinutes(50),
                          style: _metricTextStyle(context),
                        ),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardComingSoon} · ${copy.dashboardSampleBadge}',
                      ),
                      _heroMetric(
                        context,
                        copy.dashboardAdhkarQiyam,
                        Text('1/1', style: _metricTextStyle(context)),
                        colors,
                        tileWidth,
                        sample:
                            '${copy.dashboardSampleBadge} · ${copy.dashboardComingSoon}',
                      ),
                    ],
                  );
                },
              ),
            ],
          );
          if (constraints.maxWidth < 620) {
            return Column(
              children: [ring, const SizedBox(height: 18), details],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 28),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  TextStyle? _metricTextStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

  Widget _liveSummary(
    BuildContext context,
    String label,
    Widget value,
    AppColors colors,
  ) => Container(
    constraints: const BoxConstraints(minWidth: 96, maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: colors.accentSoft.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        value,
      ],
    ),
  );

  Widget _sourceValue<T>(
    BuildContext context,
    TodaySection<T> section,
    VoidCallback retry,
    String Function(T) label,
  ) {
    if (section.status == TodaySectionStatus.loading) {
      return Semantics(liveRegion: true, child: Text(strings.loading));
    }
    if (section.value == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(liveRegion: true, child: Text(strings.unavailable)),
          TextButton(onPressed: retry, child: Text(strings.retry)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label(section.value as T), style: _metricTextStyle(context)),
        if (section.status == TodaySectionStatus.stale) ...[
          Semantics(liveRegion: true, child: Text(strings.outdated)),
          TextButton(onPressed: retry, child: Text(strings.retry)),
        ],
      ],
    );
  }

  Widget _heroMetric(
    BuildContext context,
    String title,
    Widget value,
    AppColors colors,
    double width, {
    String? sample,
  }) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          value,
          if (sample != null)
            Text(
              sample,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
                fontSize: 10,
              ),
            ),
        ],
      ),
    ),
  );
  Widget _tasks(BuildContext context, AppColors colors) => _Surface(
    colors: colors,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader(
          context,
          colors,
          Icons.calendar_today_outlined,
          strings.agenda,
          TextButton.icon(
            key: kTodayTasksNavigationKey,
            onPressed: onTasks,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(strings.tasks),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.formatDate(state.calendar.localDate),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        if (state.tasks.value case final summary?) ...[
          const SizedBox(height: 12),
          if (summary.items.isEmpty)
            Text(strings.noTasks)
          else ...[
            if (TodayAgenda.project(
                  state.calendar.localDate,
                  summary.items,
                  ownerId: state.scope.taskOwnerId,
                ).timed
                case final timed when timed.isNotEmpty) ...[
              Text(
                strings.timed,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              TodayTaskList(
                tasks: timed,
                strings: strings,
                onOpenTasks: onTasks,
                actions: state.taskActions,
                allowActions:
                    state.tasks.status == TodaySectionStatus.available,
                onSetCompleted:
                    state.tasks.status == TodaySectionStatus.available
                    ? onSetTaskCompleted
                    : null,
              ),
            ],
            if (TodayAgenda.project(
                  state.calendar.localDate,
                  summary.items,
                  ownerId: state.scope.taskOwnerId,
                ).untimed
                case final untimed when untimed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                strings.untimed,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              TodayTaskList(
                tasks: untimed,
                strings: strings,
                onOpenTasks: onTasks,
                actions: state.taskActions,
                allowActions:
                    state.tasks.status == TodaySectionStatus.available,
                onSetCompleted:
                    state.tasks.status == TodaySectionStatus.available
                    ? onSetTaskCompleted
                    : null,
              ),
            ],
          ],
          if (summary.overdueCount > 0) ...[
            const SizedBox(height: 12),
            Divider(color: colors.border),
            TodayOverdueSection(
              count: summary.overdueCount,
              strings: strings,
              onOpenOverdue: onTaskOverdue ?? onTasks,
            ),
          ],
        ],
        const SizedBox(height: 12),
        Divider(color: colors.border),
        const SizedBox(height: 8),
        _timelineSample(
          context,
          colors,
          Icons.schedule_rounded,
          FoundationLocalizations.of(context).dashboardPrayerAsr,
          '03:29',
        ),
        _timelineSample(
          context,
          colors,
          Icons.menu_book_outlined,
          FoundationLocalizations.of(context).dashboardQuran,
          '07:20',
        ),
      ],
    ),
  );

  Widget _priority(BuildContext context, AppColors colors) => _Surface(
    colors: colors,
    child: TodayPrioritySection(
      tasks: state.tasks.value?.doFirst ?? const [],
      strings: strings,
      onOpenTasks: onTasks,
      onOpenMatrix: onTaskMatrix ?? onTasks,
    ),
  );

  Widget _timelineSample(
    BuildContext context,
    AppColors colors,
    IconData icon,
    String title,
    String time,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(
                '${FoundationLocalizations.of(context).dashboardComingSoon} · ${FoundationLocalizations.of(context).dashboardSampleBadge}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );

  Widget _prayerPreview(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () => showTodayComingSoonPage(
      context,
      title: copy.dashboardPrayer,
      icon: Icons.schedule_outlined,
    ),
    child: _Surface(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sampleHeader(
            context,
            copy,
            colors,
            copy.dashboardPrayerNext,
            Icons.schedule_outlined,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final prayer = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.dashboardPrayerAsr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    copy.dashboardPrayerCity,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
              final time = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '03:29',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    copy.dashboardPrayerRemaining,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [prayer, const SizedBox(height: 10), time],
                );
              }
              return Row(
                children: [
                  Expanded(child: prayer),
                  time,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Divider(color: colors.border),
          Text(
            '${copy.dashboardPrayerMaghrib} · 06:09',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    ),
  );

  Widget _quranPreview(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () => showTodayComingSoonPage(
      context,
      title: copy.dashboardQuran,
      icon: Icons.menu_book_outlined,
    ),
    child: _Surface(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sampleHeader(
            context,
            copy,
            colors,
            copy.dashboardQuranSectionTitle,
            Icons.menu_book_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            copy.dashboardQuranWirdTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.dashboardQuranDetail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              Text(
                '7/20',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: 0.35,
              minHeight: 7,
              backgroundColor: colors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quickHubs(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copy.dashboardExplore,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 6 : 3;
          const gap = 8.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardPrayerShort,
                Icons.schedule_outlined,
                width,
              ),
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardFocus,
                Icons.play_circle_outline_rounded,
                width,
              ),
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardQuran,
                Icons.menu_book_outlined,
                width,
              ),
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardAdhkarTitle,
                Icons.wb_sunny_outlined,
                width,
              ),
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardAdhkarQiyam,
                Icons.nightlight_outlined,
                width,
              ),
              _hubTile(
                context,
                copy,
                colors,
                copy.dashboardCounters,
                Icons.exposure_plus_1_outlined,
                width,
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _hubTile(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
    String title,
    IconData icon,
    double width,
  ) => SizedBox(
    width: width,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showTodayComingSoonPage(context, title: title, icon: icon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 24),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              copy.dashboardComingSoon,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _financePreview(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () => showTodayComingSoonPage(
      context,
      title: copy.dashboardFinance,
      icon: Icons.account_balance_wallet_outlined,
    ),
    child: _Surface(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sampleHeader(
            context,
            copy,
            colors,
            copy.dashboardFinanceSectionTitle,
            Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 480 ? 2 : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _financeTile(
                    context,
                    colors,
                    copy.dashboardFinanceAvailable,
                    '4,250 ${copy.dashboardFinanceCurrency}',
                    width,
                    0.52,
                  ),
                  _financeTile(
                    context,
                    colors,
                    copy.dashboardFinanceSavings,
                    '8,200 ${copy.dashboardFinanceCurrency}',
                    width,
                    0.68,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _financeTile(
    BuildContext context,
    AppColors colors,
    String title,
    String value,
    double width,
    double progress,
  ) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: colors.background,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _counterPreview(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
  ) => InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () => showTodayComingSoonPage(
      context,
      title: copy.dashboardCounters,
      icon: Icons.exposure_plus_1_outlined,
    ),
    child: _Surface(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sampleHeader(
            context,
            copy,
            colors,
            copy.dashboardCountersSection,
            Icons.exposure_plus_1_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _counterTile(
                  context,
                  colors,
                  copy.dashboardAdhkarMorning,
                  '12/33',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _counterTile(
                  context,
                  colors,
                  copy.dashboardAdhkarEvening,
                  '7/10',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _counterTile(
                  context,
                  colors,
                  copy.dashboardAdhkarQiyam,
                  '1/1',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _counterTile(
    BuildContext context,
    AppColors colors,
    String title,
    String value,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.surfaceSecondary,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _sampleHeader(
    BuildContext context,
    FoundationLocalizations copy,
    AppColors colors,
    String title,
    IconData icon,
  ) => Row(
    children: [
      Icon(icon, size: 20, color: colors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            copy.dashboardComingSoon,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            copy.dashboardSampleBadge,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    ],
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
