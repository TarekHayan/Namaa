import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

class PrayerHeader extends StatelessWidget {
  const PrayerHeader({
    super.key,
    required this.city,
    required this.details,
    required this.completedCount,
    required this.actions,
  });

  final String city;
  final String details;
  final int? completedCount;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Container(
      key: const Key('prayer_header'),
      padding: EdgeInsets.all(wide ? 32 : 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.prayerTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            copy.prayerSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(city, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            details,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${completedCount?.toString() ?? '—'}/5',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                copy.prayerStreakSoon,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              ...actions,
            ],
          ),
        ],
      ),
    );
  }
}
