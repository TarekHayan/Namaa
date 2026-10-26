library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../../domain/today_agenda.dart';
import '../../domain/today_section.dart';
import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import '../today_state.dart';
import '../today_strings.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned Smart Daily Timeline featuring a continuous vertical rail,
/// status-indicated nodes, real task integration, and sample spiritual/focus events.
class TodayTimelineSection extends StatelessWidget {
  const TodayTimelineSection({
    super.key,
    required this.agenda,
    required this.strings,
    required this.colors,
    this.status = TodaySectionStatus.available,
    required this.onOpenTasks,
    this.onSetTaskCompleted,
    this.actions = const {},
    this.currentMinuteOfDay,
  });

  final TodayAgenda? agenda;
  final TodayStrings strings;
  final AppColors colors;
  final TodaySectionStatus status;
  final VoidCallback onOpenTasks;
  final void Function(String, bool)? onSetTaskCompleted;
  final Map<String, TodayActionFeedback> actions;
  final int? currentMinuteOfDay;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build timeline items: Real tasks + Sample timeline checkpoints
    final items = _buildTimelineItems(copy);

    return Container(
      key: kDashboardTimelineGroup,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.cardGlow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Icon + Title + Active Now badge
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            copy.dashboardDailyTimeline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          copy.dashboardPrayerTitle.contains('الصلاة')
                              ? 'النشاط الحالي'
                              : 'Active Now',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          if (status == TodaySectionStatus.loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                strings.loading,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (status == TodaySectionStatus.unavailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                strings.unavailable,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (status == TodaySectionStatus.stale)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                strings.outdated,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Continuous vertical rail layout
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Stack(
              children: [
                // The vertical line rail
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: 6,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 2,
                    color: colors.primary.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                  ),
                ),

                // Event rows with nodes
                Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _buildTimelineRow(
                        context,
                        copy,
                        items[i],
                        isLast: i == items.length - 1,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if ((agenda?.untimed.length ?? 0) > 2)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onOpenTasks,
                child: Text(strings.showMore),
              ),
            ),
        ],
      ),
    );
  }

  List<_TimelineItemModel> _buildTimelineItems(FoundationLocalizations copy) {
    final list = <_TimelineItemModel>[];

    // 1. Fajr (Sample, completed)
    list.add(
      _TimelineItemModel(
        title: copy.dashboardPrayerFajr,
        time: '04:42',
        detail:
            '4 ${copy.dashboardFocusCompletedToday.contains('ركعات') ? 'ركعات' : 'rakahs'}',
        status: _TimelineStatus.completed,
        sortMinute: 4 * 60 + 42,
        isSample: true,
        feature: DashboardPreviewFeature.prayer,
      ),
    );

    // 2. Morning Adhkar (Sample, completed)
    list.add(
      _TimelineItemModel(
        title: copy.dashboardAdhkarMorning,
        time: '06:15',
        detail: '19 / 43',
        status: _TimelineStatus.completed,
        sortMinute: 6 * 60 + 15,
        isSample: true,
        feature: DashboardPreviewFeature.adhkar,
      ),
    );

    // 3. Real timed tasks from agenda (if any)
    if (agenda != null) {
      for (final timed in agenda!.timed) {
        list.add(
          _TimelineItemModel(
            title: timed.title,
            time: strings.formatTime(timed.scheduledMinuteOfDay ?? 0),
            detail: strings.tasks,
            status: timed.isCompleted
                ? _TimelineStatus.completed
                : currentMinuteOfDay != null &&
                      timed.scheduledMinuteOfDay! > currentMinuteOfDay!
                ? _TimelineStatus.upcoming
                : _TimelineStatus.current,
            sortMinute: timed.scheduledMinuteOfDay,
            isSample: false,
            taskId: timed.taskId,
            isCompleted: timed.isCompleted,
          ),
        );
      }
    }

    // 4. Focus Block (Sample, current)
    list.add(
      _TimelineItemModel(
        title: copy.dashboardFocusPomodoroTitle,
        time: '10:00',
        detail: '${DashboardPreviewData.standard.focusMinutes.value ?? 50} min',
        status: _TimelineStatus.current,
        sortMinute: 10 * 60,
        isSample: true,
        feature: DashboardPreviewFeature.focus,
      ),
    );

    // 5. Real untimed tasks (if any)
    if (agenda != null) {
      for (final task in agenda!.untimed.take(2)) {
        list.add(
          _TimelineItemModel(
            title: task.title,
            time: strings.untimed,
            detail: strings.tasks,
            status: task.isCompleted
                ? _TimelineStatus.completed
                : _TimelineStatus.upcoming,
            isSample: false,
            taskId: task.taskId,
            isCompleted: task.isCompleted,
          ),
        );
      }
    }

    // 6. Dhuhr Prayer (Sample, upcoming)
    list.add(
      _TimelineItemModel(
        title: copy.dashboardPrayerDhuhr,
        time: '12:03',
        detail:
            '4 ${copy.dashboardFocusCompletedToday.contains('ركعات') ? 'ركعات' : 'rakahs'}',
        status: _TimelineStatus.upcoming,
        sortMinute: 12 * 60 + 3,
        isSample: true,
        feature: DashboardPreviewFeature.prayer,
      ),
    );

    // 7. Quran Wird (Sample, upcoming)
    list.add(
      _TimelineItemModel(
        title: copy.dashboardQuranWirdTitle,
        time: '16:00',
        detail: copy.dashboardQuranSectionTitle,
        status: _TimelineStatus.upcoming,
        sortMinute: 16 * 60,
        isSample: true,
        feature: DashboardPreviewFeature.quran,
      ),
    );

    list.sort((a, b) {
      final aMinute = a.sortMinute;
      final bMinute = b.sortMinute;
      if (aMinute == null) return bMinute == null ? 0 : 1;
      if (bMinute == null) return -1;
      return aMinute.compareTo(bMinute);
    });
    return list;
  }

  Widget _buildTimelineRow(
    BuildContext context,
    FoundationLocalizations copy,
    _TimelineItemModel item, {
    required bool isLast,
  }) {
    final isCurrent = item.status == _TimelineStatus.current;
    final isCompleted = item.status == _TimelineStatus.completed;
    final feedback = item.taskId == null ? null : actions[item.taskId];

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          // Timeline Node Dot
          InkWell(
            key: item.taskId != null
                ? ValueKey('today_timeline_action_${item.taskId}')
                : null,
            canRequestFocus: item.taskId != null,
            onTap:
                (!item.isSample &&
                        item.taskId != null &&
                        onSetTaskCompleted != null) &&
                    feedback?.blocksAction != true
                ? () => onSetTaskCompleted!(item.taskId!, !item.isCompleted)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? colors.primary
                        : isCompleted
                        ? colors.primary
                        : colors.surfaceSecondary,
                    border: Border.all(
                      color: isCurrent
                          ? colors.background
                          : colors.primary.withValues(
                              alpha: isCompleted ? 1.0 : 0.4,
                            ),
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Event Card
          Expanded(
            child: InkWell(
              key: item.taskId != null
                  ? ValueKey('today_timeline_task_${item.taskId}')
                  : null,
              onTap: () {
                if (!item.isSample) {
                  onOpenTasks();
                } else if (item.feature != null) {
                  TodayNavigationShell.openPreview(
                    context,
                    title: item.title,
                    feature: item.feature!,
                    colors: colors,
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? colors.primary.withValues(alpha: 0.35)
                        : colors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isCompleted
                                      ? colors.textMuted
                                      : colors.textPrimary,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.isSample)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.border.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    copy.dashboardSampleBadge,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.time} • ${item.detail}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (feedback != null)
                            Text(
                              switch (feedback.phase) {
                                TodayActionPhase.pending => strings.saving,
                                TodayActionPhase.uncertain => strings.uncertain,
                                TodayActionPhase.failed =>
                                  feedback.failure?.messageKey ==
                                          'tasks.validation.stale_day'
                                      ? strings.staleDay
                                      : strings.saveFailed,
                                TodayActionPhase.saved => strings.completed,
                              },
                              style: TextStyle(
                                fontSize: 11,
                                color: feedback.phase == TodayActionPhase.failed
                                    ? colors.error
                                    : colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Status pill or Chevron
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          strings.timed.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineStatus { completed, current, upcoming }

class _TimelineItemModel {
  const _TimelineItemModel({
    required this.title,
    required this.time,
    required this.detail,
    required this.status,
    required this.isSample,
    this.sortMinute,
    this.taskId,
    this.isCompleted = false,
    this.feature,
  });

  final String title;
  final String time;
  final String detail;
  final _TimelineStatus status;
  final bool isSample;
  final int? sortMinute;
  final String? taskId;
  final bool isCompleted;
  final DashboardPreviewFeature? feature;
}
