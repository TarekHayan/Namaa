library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';

import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned Quick Action Hubs presenting exactly six hubs in order:
/// 1. Prayer, 2. Focus, 3. Quran, 4. Adhkar, 5. Qiyam, 6. Counters.
class TodayQuickHubs extends StatelessWidget {
  const TodayQuickHubs({super.key, required this.colors, this.onOpenHub});

  final AppColors colors;
  final void Function(DashboardPreviewFeature feature)? onOpenHub;

  void _navigateToHub(
    BuildContext context,
    DashboardPreviewFeature feature,
    String title,
  ) {
    if (onOpenHub != null) {
      onOpenHub!(feature);
      return;
    }
    TodayNavigationShell.openPreview(
      context,
      title: title,
      feature: feature,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hubs = [
      (
        feature: DashboardPreviewFeature.prayer,
        title: copy.dashboardComingSoonPrayerTitle,
        comingSoonTitle: copy.dashboardComingSoonPrayerTitle,
        icon: Icons.schedule_rounded,
        iconBg: colors.primary.withValues(alpha: 0.14),
        iconColor: colors.primary,
      ),
      (
        feature: DashboardPreviewFeature.focus,
        title: copy.dashboardComingSoonFocusTitle,
        comingSoonTitle: copy.dashboardComingSoonFocusTitle,
        icon: Icons.play_arrow_rounded,
        iconBg: isDark ? const Color(0x33B45309) : const Color(0xFFFEF3C7),
        iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      ),
      (
        feature: DashboardPreviewFeature.quran,
        title: copy.dashboardComingSoonQuranTitle,
        comingSoonTitle: copy.dashboardComingSoonQuranTitle,
        icon: Icons.menu_book_rounded,
        iconBg: isDark ? const Color(0x330D9488) : const Color(0xFFCCFBF1),
        iconColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
      ),
      (
        feature: DashboardPreviewFeature.adhkar,
        title: copy.dashboardComingSoonAdhkarTitle,
        comingSoonTitle: copy.dashboardComingSoonAdhkarTitle,
        icon: Icons.wb_sunny_rounded,
        iconBg: isDark ? const Color(0x33EAB308) : const Color(0xFFFEF9C3),
        iconColor: isDark ? const Color(0xFFFACC15) : const Color(0xFFCA8A04),
      ),
      (
        feature: DashboardPreviewFeature.qiyam,
        title: copy.dashboardComingSoonQiyamTitle,
        comingSoonTitle: copy.dashboardComingSoonQiyamTitle,
        icon: Icons.nightlight_round,
        iconBg: isDark ? const Color(0x334F46E5) : const Color(0xFFE0E7FF),
        iconColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
      ),
      (
        feature: DashboardPreviewFeature.counters,
        title: copy.dashboardComingSoonCountersTitle,
        comingSoonTitle: copy.dashboardComingSoonCountersTitle,
        icon: Icons.repeat_rounded,
        iconBg: isDark ? const Color(0x339333EA) : const Color(0xFFF3E8FF),
        iconColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
      ),
    ];

    return Container(
      key: kDashboardHubsGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  copy.dashboardQuickAccess.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    copy.dashboardComingSoon,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final columns = constraints.maxWidth >= 640
                  ? 6
                  : (constraints.maxWidth < 280 || textScale >= 1.3 ? 2 : 3);
              final gap = 10.0;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final hub in hubs)
                    SizedBox(
                      width: width,
                      child: AppHoverSurface(
                        clickable: true,
                        child: InkWell(
                          onTap: () => _navigateToHub(
                            context,
                            hub.feature,
                            hub.comingSoonTitle,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: hub.iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    hub.icon,
                                    color: hub.iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    hub.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
