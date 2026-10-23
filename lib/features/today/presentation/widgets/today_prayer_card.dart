library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Illustrative prayer timeline card presenting sample daily prayer schedule.
class TodayPrayerCard extends StatelessWidget {
  const TodayPrayerCard({super.key, required this.colors});

  final AppColors colors;

  void _showNotice(BuildContext context, FoundationLocalizations copy) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${copy.dashboardSampleBadge}: ${copy.dashboardSampleNotice}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final prayers = [
      (
        name: copy.dashboardPrayerFajr,
        time: '04:42',
        isDone: true,
        isNext: false,
      ),
      (
        name: copy.dashboardPrayerDhuhr,
        time: '12:03',
        isDone: true,
        isNext: false,
      ),
      (
        name: copy.dashboardPrayerAsr,
        time: '03:29',
        isDone: true,
        isNext: false,
      ),
      (
        name: copy.dashboardPrayerMaghrib,
        time: '06:09',
        isDone: false,
        isNext: true,
      ),
      (
        name: copy.dashboardPrayerIsha,
        time: '07:39',
        isDone: false,
        isNext: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.035),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.dashboardPrayerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  copy.dashboardPrayerCity,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  copy.dashboardSampleBadge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 4 * 8) / 5;
              final compact = itemWidth < 58;
              final isNarrow = constraints.maxWidth < 280;

              final slots = [
                for (var i = 0; i < prayers.length; i++)
                  SizedBox(
                    width: isNarrow ? 60 : null,
                    child: _PrayerSlot(
                      name: prayers[i].name,
                      time: prayers[i].time,
                      isDone: prayers[i].isDone,
                      isNext: prayers[i].isNext,
                      colors: colors,
                      compact: compact,
                      onTap: () => _showNotice(context, copy),
                    ),
                  ),
              ];

              if (isNarrow) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (var i = 0; i < slots.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        slots[i],
                      ],
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < slots.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: slots[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showNotice(context, copy),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${copy.dashboardPrayerNext}: ${copy.dashboardPrayerMaghrib} (06:09) · ${copy.dashboardPrayerRemaining}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerSlot extends StatelessWidget {
  const _PrayerSlot({
    required this.name,
    required this.time,
    required this.isDone,
    required this.isNext,
    required this.colors,
    required this.compact,
    required this.onTap,
  });

  final String name;
  final String time;
  final bool isDone;
  final bool isNext;
  final AppColors colors;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isNext ? colors.primary : colors.surfaceSecondary;
    final fg = isNext
        ? (Theme.of(context).brightness == Brightness.dark
              ? colors.background
              : Colors.white)
        : colors.textPrimary;
    final subFg = isNext
        ? (Theme.of(context).brightness == Brightness.dark
              ? colors.background.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.85))
        : colors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isNext ? 10 : 8,
          horizontal: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: isNext
              ? null
              : Border.all(color: colors.border.withValues(alpha: 0.5)),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: colors.cardGlow,
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            if (isDone)
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: isNext ? fg : colors.primary,
              )
            else if (isNext)
              Icon(Icons.hourglass_top_rounded, size: 14, color: fg)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                size: 14,
                color: subFg,
              ),
          ],
        ),
      ),
    );
  }
}
