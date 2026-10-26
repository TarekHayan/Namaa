library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned next-prayer card with prominent next prayer, location context,
/// countdown timer, sample provenance, and following prayer snippet.
class TodayPrayerCard extends StatelessWidget {
  const TodayPrayerCard({super.key, required this.colors, this.onTap});

  final AppColors colors;
  final VoidCallback? onTap;

  void _handleTap(BuildContext context, FoundationLocalizations copy) {
    if (onTap != null) {
      onTap!();
      return;
    }
    TodayNavigationShell.openPreview(
      context,
      title: copy.dashboardComingSoonPrayerTitle,
      feature: DashboardPreviewFeature.prayer,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final preview = DashboardPreviewData.standard.prayer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextName = _prayerName(
      copy,
      preview.nextPrayer.value ?? DashboardPrayerName.asr,
    );
    final nextTime = _formatTime(
      preview.nextPrayerTime.value ??
          const DashboardClockTime(hour: 15, minute: 25),
    );
    final followingName = _prayerName(
      copy,
      preview.followingPrayer.value ?? DashboardPrayerName.maghrib,
    );
    final followingTime = _formatTime(
      preview.followingPrayerTime.value ??
          const DashboardClockTime(hour: 18, minute: 9),
    );

    final remainingMins = preview.remainingMinutes.value ?? 204;
    final hours = remainingMins ~/ 60;
    final mins = remainingMins % 60;
    final countdownText =
        '-${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';

    return Container(
      key: kDashboardPrayerGroup,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardGlow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context, copy),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Next Prayer Pill & Location & Sample Badge
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            copy.dashboardNextPrayer.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '📍 ${copy.dashboardPrayerCity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    // Sample tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        copy.dashboardSampleBadge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Middle: Large Prayer Name + Countdown Box
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isStacked = constraints.maxWidth < 260;

                    final countdownPill = Semantics(
                      label:
                          '${copy.dashboardSampleValue}: ${copy.dashboardPrayerRemaining} $countdownText',
                      child: Column(
                        crossAxisAlignment: isStacked
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F1714)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                countdownText,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            copy.dashboardPrayerRemaining.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );

                    final prayerInfo = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              nextTime,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                            Text(
                              '• 4 ${copy.dashboardFocusCompletedToday.contains('ركعات') ? 'ركعات' : 'rakahs'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    if (isStacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          prayerInfo,
                          const SizedBox(height: 12),
                          countdownPill,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: prayerInfo),
                        const SizedBox(width: 8),
                        countdownPill,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Bottom divider and Following prayer row
                Divider(color: colors.border.withValues(alpha: 0.6)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${copy.dashboardPrayerUpcoming}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: '$followingName ($followingTime)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            copy.dashboardPrayerTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _prayerName(FoundationLocalizations copy, DashboardPrayerName name) =>
      switch (name) {
        DashboardPrayerName.fajr => copy.dashboardPrayerFajr,
        DashboardPrayerName.dhuhr => copy.dashboardPrayerDhuhr,
        DashboardPrayerName.asr => copy.dashboardPrayerAsr,
        DashboardPrayerName.maghrib => copy.dashboardPrayerMaghrib,
        DashboardPrayerName.isha => copy.dashboardPrayerIsha,
      };

  String _formatTime(DashboardClockTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
