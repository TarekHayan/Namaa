import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Destination for prototype sections whose owning feature is still planned.
void showTodayComingSoonPage(
  BuildContext context, {
  required String title,
  required IconData icon,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (pageContext) {
        final copy = FoundationLocalizations.of(pageContext);
        final colors = Theme.of(pageContext).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            leading: IconButton(
              tooltip: copy.dashboardBackToHome,
              icon: const BackButtonIcon(),
              onPressed: () => Navigator.of(pageContext).pop(),
            ),
            title: Text(title),
            backgroundColor: colors.background,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: colors.primary),
                  const SizedBox(height: 16),
                  Text(
                    copy.dashboardComingSoon,
                    style: Theme.of(pageContext).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.dashboardComingSoonDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(pageContext).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
