library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../../domain/today_models.dart';
import '../../domain/today_section.dart';
import '../today_dashboard_view.dart';
import '../today_state.dart';
import '../today_strings.dart';

/// Prototype-aligned Do First card for Quadrant 1 (Urgent & Important) tasks,
/// preserving existing TodayPriority projections, task keys, and matrix actions.
class TodayPrioritySection extends StatelessWidget {
  const TodayPrioritySection({
    super.key,
    required this.tasks,
    required this.strings,
    this.colors,
    this.status = TodaySectionStatus.available,
    required this.onOpenTasks,
    required this.onOpenMatrix,
    this.onSetTaskCompleted,
    this.actions = const {},
  });

  final List<TodayTaskReference> tasks;
  final TodayStrings strings;
  final AppColors? colors;
  final TodaySectionStatus status;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenMatrix;
  final void Function(String, bool)? onSetTaskCompleted;
  final Map<String, TodayActionFeedback> actions;

  @override
  Widget build(BuildContext context) {
    final themeColors =
        colors ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);

    return Container(
      key: kDashboardPriorityGroup,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: themeColors.border),
        boxShadow: [
          BoxShadow(
            color: themeColors.cardGlow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Green indicator + Title + Matrix View button
          LayoutBuilder(
            builder: (context, headerConstraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: headerConstraints.maxWidth,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: themeColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.doFirst,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: headerConstraints.maxWidth,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: InkWell(
                        key: const Key('today_open_matrix'),
                        onTap: onOpenMatrix,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                strings.openMatrix,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: themeColors.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_back_ios_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: themeColors.primary,
                              ),
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
          const SizedBox(height: 14),

          // Tasks List (up to 3) or Empty/Status state
          if (status == TodaySectionStatus.loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: themeColors.surfaceSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  strings.loading,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeColors.textSecondary,
                  ),
                ),
              ),
            )
          else if (status == TodaySectionStatus.unavailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: themeColors.surfaceSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  strings.unavailable,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeColors.textSecondary,
                  ),
                ),
              ),
            )
          else if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: themeColors.surfaceSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${strings.noPriorityTasks} 🎉',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                if (status == TodaySectionStatus.stale)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      strings.outdated,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                for (final task in tasks.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: KeyedSubtree(
                      key: ValueKey('today_priority_task_${task.taskId}'),
                      child: InkWell(
                        onTap: onOpenTasks,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: themeColors.surfaceSecondary.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    key: onSetTaskCompleted == null
                                        ? null
                                        : ValueKey(
                                            'today_task_action_${task.taskId}',
                                          ),
                                    tooltip: strings.completeTask,
                                    onPressed:
                                        onSetTaskCompleted == null ||
                                            actions[task.taskId]
                                                    ?.blocksAction ==
                                                true
                                        ? null
                                        : () => onSetTaskCompleted!(
                                            task.taskId,
                                            true,
                                          ),
                                    icon: Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: themeColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: themeColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            strings.formatDate(
                                              task.scheduledLocalDate,
                                            ),
                                            if (task.isOverdue) strings.overdue,
                                          ].join(' · '),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: task.isOverdue
                                                ? themeColors.error
                                                : themeColors.textSecondary,
                                            fontWeight: task.isOverdue
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (actions[task.taskId] case final feedback?)
                                Text(
                                  switch (feedback.phase) {
                                    TodayActionPhase.pending => strings.saving,
                                    TodayActionPhase.uncertain =>
                                      strings.uncertain,
                                    TodayActionPhase.failed =>
                                      feedback.failure?.messageKey ==
                                              'tasks.validation.stale_day'
                                          ? strings.staleDay
                                          : strings.saveFailed,
                                    TodayActionPhase.saved => strings.completed,
                                  },
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        feedback.phase ==
                                            TodayActionPhase.failed
                                        ? themeColors.error
                                        : themeColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
