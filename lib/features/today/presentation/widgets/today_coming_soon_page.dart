import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';

/// Destination widget for prototype sections whose owning feature is still planned.
class TodayComingSoonPage extends StatelessWidget {
  const TodayComingSoonPage({
    super.key,
    required this.title,
    this.icon,
    this.feature,
    this.colors,
  });

  final String title;
  final IconData? icon;
  final DashboardPreviewFeature? feature;
  final AppColors? colors;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final themeColors =
        colors ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);

    final resolvedIcon = icon ?? _featureIcon(feature);

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(title),
        backgroundColor: themeColors.background,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(resolvedIcon, size: 48, color: themeColors.primary),
              const SizedBox(height: 16),
              Text(
                copy.dashboardComingSoon,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                copy.dashboardComingSoonDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: themeColors.primary,
                ),
                child: Text(copy.dashboardBackToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _featureIcon(DashboardPreviewFeature? feature) => switch (feature) {
    DashboardPreviewFeature.prayer => Icons.schedule_rounded,
    DashboardPreviewFeature.quran => Icons.menu_book_rounded,
    DashboardPreviewFeature.focus => Icons.play_arrow_rounded,
    DashboardPreviewFeature.qiyam => Icons.nightlight_round,
    DashboardPreviewFeature.adhkar => Icons.wb_sunny_rounded,
    DashboardPreviewFeature.finance => Icons.account_balance_wallet_outlined,
    DashboardPreviewFeature.counters => Icons.repeat_rounded,
    _ => Icons.lock_clock_outlined,
  };
}

/// Helper to navigate to [TodayComingSoonPage].
void showTodayComingSoonPage(
  BuildContext context, {
  required String title,
  required IconData icon,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => TodayComingSoonPage(title: title, icon: icon),
    ),
  );
}
