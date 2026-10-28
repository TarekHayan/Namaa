library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned Daily Quran Wird card presenting portion title, reading progress,
/// sample status, and read/mushaf actions.
class TodayQuranCard extends StatelessWidget {
  const TodayQuranCard({super.key, required this.colors, this.onTap});

  final AppColors colors;
  final VoidCallback? onTap;

  void _openComingSoon(BuildContext context, FoundationLocalizations copy) {
    if (onTap != null) {
      onTap!();
      return;
    }
    TodayNavigationShell.openPreview(
      context,
      title: copy.dashboardComingSoonQuranTitle,
      feature: DashboardPreviewFeature.quran,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final preview = DashboardPreviewData.standard.quran;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final startPage = preview.startPage.value ?? 302;
    final endPage = preview.endPage.value ?? 304;
    final progress = preview.progress.value ?? 0.75;

    return Container(
      key: kDashboardQuranGroup,
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
          // Top metadata row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                  ),
                  Text(
                    copy.dashboardQuranWirdTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: colors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x33451A03)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x66F59E0B)
                            : const Color(0xFFFFEDD5),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '7 ${copy.dashboardStreak}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sample badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          const SizedBox(height: 12),

          // Portion title
          Semantics(
            label:
                '${copy.dashboardSampleValue}: ${copy.dashboardQuranWirdTitle} ${copy.dashboardQuranSectionTitle} $startPage / $endPage',
            child: Text(
              copy.dashboardQuranSectionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text: X / Y pages
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                copy.dashboardQuranProgressInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$startPage / $endPage',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Continue Reading & Mushaf
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _openComingSoon(context, copy),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: isDark ? colors.background : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  copy.dashboardQuranContinueReading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openComingSoon(context, copy),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                label: Text(
                  copy.dashboardQuran,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
