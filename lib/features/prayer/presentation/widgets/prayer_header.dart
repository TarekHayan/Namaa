import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Prototype heading: title, subtitle with the location, and the streak and
/// progress badges. Namaa additionally names the date, zone and method and
/// offers the location/city actions (prototype-reference adaptation 3).
class PrayerHeader extends StatelessWidget {
  const PrayerHeader({
    super.key,
    required this.city,
    required this.details,
    required this.completedCount,
    required this.actions,
    this.source,
  });

  final String city;
  final String details;
  final String? source;
  final int? completedCount;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final muted = text.bodySmall?.copyWith(color: colors.textMuted);
    final done = completedCount;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                copy.prayerTitle,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            // Phones keep the settings icon beside the title; wide layouts
            // place it at the far end, after the badges.
            if (!wide) ...actions,
          ],
        ),
        const SizedBox(height: 2),
        Text(copy.prayerSubtitle, style: muted),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 14, color: colors.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                city,
                style: text.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(details, style: muted),
        if (source != null) ...[
          const SizedBox(height: 2),
          Text(source!, style: muted),
        ],
      ],
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: wide ? WrapAlignment.end : WrapAlignment.start,
      children: [
        _Badge(
          color: colors.warning,
          icon: Icons.local_fire_department_rounded,
          // The global streak is not implemented yet (adaptation 5).
          label: copy.prayerStreakSoon,
        ),
        _Badge(
          color: colors.success,
          icon: Icons.auto_awesome_rounded,
          label: done == null
              ? '—/5'
              : copy.prayerProgressBadge(done, (done * 100 / 5).round()),
        ),
      ],
    );

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
          // Prototype `sm:flex-row sm:items-center justify-between`: the
          // heading at the start, the badges (and the settings icon) at the
          // far end, vertically centred.
          if (wide)
            LayoutBuilder(
              builder: (context, constraints) => Row(
                key: const Key('prayer_header_wide'),
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.45,
                    ),
                    child: badges,
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ...actions,
                  ],
                ],
              ),
            )
          else ...[
            heading,
            const SizedBox(height: 12),
            badges,
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      border: Border.all(color: color.withValues(alpha: 0.20)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
