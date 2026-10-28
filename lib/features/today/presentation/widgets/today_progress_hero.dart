library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_presentation.dart';
import '../today_dashboard_view.dart';
import '../today_state.dart';
import '../today_strings.dart';

/// Prototype-aligned Progress Hero card with circular gauge, XP progress,
/// level pill, and six compact daily metric positions.
class TodayProgressHero extends StatelessWidget {
  const TodayProgressHero({
    super.key,
    required this.state,
    required this.strings,
    required this.colors,
    this.presentation,
    this.onOpenHabits,
    this.onOpenTasks,
    this.onRetryTasks,
    this.onRetryHabits,
    this.onRetryXp,
  });

  final TodayState state;
  final TodayStrings strings;
  final AppColors colors;
  final DashboardPresentation? presentation;
  final VoidCallback? onOpenHabits;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onRetryTasks;
  final VoidCallback? onRetryHabits;
  final VoidCallback? onRetryXp;

  @override
  Widget build(BuildContext context) {
    final pres = presentation ?? DashboardPresentation.fromState(state);
    final copy = FoundationLocalizations.of(context);
    final preview = pres.preview;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Overall progress sample percentage
    final progressPercent = ((preview.overallProgress.value ?? 0.68) * 100)
        .round();

    return Container(
      key: kDashboardProgressGroup,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
                  const Color(0x33064E3B),
                  const Color(0xFF0D120F),
                  colors.surface,
                ]
              : [const Color(0xFFECFDF5), colors.background, colors.surface],
        ),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardGlow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final gauge = _buildGauge(context, copy, progressPercent);
          final details = _buildProgressDetails(context, copy, pres);

          if (isWide) {
            final rightWidth = constraints.maxWidth - 110 - 24;
            final badges = _buildBadges(
              context: context,
              copy: copy,
              pres: pres,
              maxWidth: rightWidth,
            );

            return Row(
              children: [
                gauge,
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [details, const SizedBox(height: 12), badges],
                  ),
                ),
              ],
            );
          }

          final badges = _buildBadges(
            context: context,
            copy: copy,
            pres: pres,
            maxWidth: constraints.maxWidth,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              gauge,
              const SizedBox(height: 16),
              details,
              const SizedBox(height: 14),
              badges,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadges({
    required BuildContext context,
    required FoundationLocalizations copy,
    required DashboardPresentation pres,
    required double maxWidth,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final columns = maxWidth >= 640
        ? 6
        : (maxWidth < 320 || textScale >= 1.3 ? 2 : 3);
    final gap = 8.0;
    final width = (maxWidth - (columns - 1) * gap) / columns;
    final preview = pres.preview;

    final taskVal = pres.isTasksLoading
        ? '--/--'
        : (pres.isTasksUnavailable
              ? '!'
              : '${pres.tasksCompleted}/${pres.tasksTotal}');

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        // 1. Tasks (Real)
        _metricTile(
          width: width,
          title: copy.dashboardTasksProgress,
          value: taskVal,
          isHighlight: false,
          semanticsLabel: '${copy.dashboardTasksProgress}: $taskVal',
          onTap: onOpenTasks,
        ),
        // 2. Prayer (Sample)
        _metricTile(
          width: width,
          title: copy.dashboardPrayerShort,
          value: '4/5',
          isHighlight: true,
          semanticsLabel:
              '${copy.dashboardSampleValue}: ${copy.dashboardPrayerShort} 4/5',
          sampleLabel: copy.dashboardSampleBadge,
        ),
        // 3. Quran (Sample)
        _metricTile(
          width: width,
          title: copy.dashboardQuran,
          value: '75%',
          isHighlight: false,
          semanticsLabel:
              '${copy.dashboardSampleValue}: ${copy.dashboardQuran} 75%',
          sampleLabel: copy.dashboardSampleBadge,
        ),
        // 4. Adhkar (Sample)
        _metricTile(
          width: width,
          title: copy.dashboardAdhkarTitle,
          value: '${preview.adhkarCompleted.value ?? 19}',
          isHighlight: false,
          semanticsLabel:
              '${copy.dashboardSampleValue}: ${copy.dashboardAdhkarTitle} ${preview.adhkarCompleted.value ?? 19}',
          sampleLabel: copy.dashboardSampleBadge,
        ),
        // 5. Focus (Sample)
        _metricTile(
          width: width,
          title: copy.dashboardFocus,
          value: '${preview.focusMinutes.value ?? 50}m',
          isHighlight: false,
          semanticsLabel:
              '${copy.dashboardSampleValue}: ${copy.dashboardFocus} ${preview.focusMinutes.value ?? 50}m',
          sampleLabel: copy.dashboardSampleBadge,
        ),
        // 6. Qiyam (Sample)
        _metricTile(
          width: width,
          title: copy.dashboardAdhkarQiyam,
          value: '✓',
          isHighlight: true,
          semanticsLabel:
              '${copy.dashboardSampleValue}: ${copy.dashboardAdhkarQiyam} ✓',
          sampleLabel: copy.dashboardSampleBadge,
        ),
      ],
    );
  }

  Widget _buildGauge(
    BuildContext context,
    FoundationLocalizations copy,
    int percent,
  ) {
    return Semantics(
      label:
          '${copy.dashboardSampleValue}: ${copy.dashboardOverallProgress} $percent%',
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(110, 110),
              painter: _RingGaugePainter(
                progress: percent / 100.0,
                trackColor: colors.primary.withValues(alpha: 0.12),
                progressColor: colors.primary,
                strokeWidth: 9,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  strings.completed.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colors.primary,
                  ),
                ),
                Text(
                  copy.dashboardSampleBadge,
                  style: TextStyle(fontSize: 8, color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDetails(
    BuildContext context,
    FoundationLocalizations copy,
    DashboardPresentation pres,
  ) {
    final preview = pres.preview;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          copy.dashboardTodayProgress.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            copy.dashboardSampleBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _xpLabel(copy, pres),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                // Level Pill with Habits navigation key for backwards-compatible test access
                Semantics(
                  label:
                      '${copy.dashboardSampleValue}: ${copy.dashboardLevel} ${preview.level.value}',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: InkWell(
                      key: kTodayHabitsNavigationKey,
                      onTap: onOpenHabits,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.military_tech_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${copy.dashboardLevel} ${preview.level.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              copy.dashboardSampleBadge,
                              style: TextStyle(
                                fontSize: 8,
                                color: colors.primary,
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
            const SizedBox(height: 8),

            // Live Tasks & Habits breakdown readouts
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: InkWell(
                    key: kTodayTasksNavigationKey,
                    onTap: onOpenTasks,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _tasksLabel(copy, pres),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: InkWell(
                    onTap: onOpenHabits,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.autorenew_rounded,
                          size: 14,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _habitsLabel(copy, pres),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if ((pres.isTasksStale || pres.isTasksUnavailable) &&
                onRetryTasks != null)
              TextButton(
                onPressed: onRetryTasks,
                child: Text('${strings.retry} ${copy.tasksTitle}'),
              ),
            if ((pres.isHabitsStale || pres.isHabitsUnavailable) &&
                onRetryHabits != null)
              TextButton(
                onPressed: onRetryHabits,
                child: Text('${strings.retry} ${copy.habitsTitle}'),
              ),
            if ((pres.isXpStale || pres.isXpUnavailable) && onRetryXp != null)
              TextButton(
                onPressed: onRetryXp,
                child: Text('${strings.retry} XP'),
              ),
          ],
        );
      },
    );
  }

  String _tasksLabel(FoundationLocalizations copy, DashboardPresentation pres) {
    if (pres.isTasksLoading) {
      return '${copy.tasksTitle}: ${strings.loading}';
    }
    if (pres.isTasksUnavailable) {
      return '${copy.tasksTitle}: ${strings.unavailable}';
    }
    final pct = pres.tasksPercent != null ? ' · ${pres.tasksPercent}%' : '';
    final stale = pres.isTasksStale ? ' · ${strings.outdated}' : '';
    return '${copy.tasksTitle}: ${pres.tasksCompleted}/${pres.tasksTotal}$pct$stale';
  }

  String _habitsLabel(
    FoundationLocalizations copy,
    DashboardPresentation pres,
  ) {
    if (pres.isHabitsLoading) {
      return '${copy.habitsTitle}: ${strings.loading}';
    }
    if (pres.isHabitsUnavailable) {
      return '${copy.habitsTitle}: ${strings.unavailable}';
    }
    final pct = pres.habitsPercent != null ? ' · ${pres.habitsPercent}%' : '';
    final stale = pres.isHabitsStale ? ' · ${strings.outdated}' : '';
    return '${copy.habitsTitle}: ${pres.habitsCompleted}/${pres.habitsTotal}$pct$stale';
  }

  String _xpLabel(FoundationLocalizations copy, DashboardPresentation pres) {
    if (pres.isXpLoading) {
      return strings.loading;
    }
    if (pres.isXpUnavailable) {
      return strings.unavailable;
    }
    final stale = pres.isXpStale ? ' · ${strings.outdated}' : '';
    return '${pres.xpAmount} XP$stale';
  }

  Widget _metricTile({
    required double width,
    required String title,
    required String value,
    required bool isHighlight,
    String? semanticsLabel,
    String? sampleLabel,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sampleLabel != null)
                Text(
                  sampleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, color: colors.textMuted),
                ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isHighlight ? colors.primary : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  const _RingGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
