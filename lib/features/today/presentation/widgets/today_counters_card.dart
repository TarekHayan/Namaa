library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import '../today_strings.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned Habit Counters snippet card presenting at most four sample counters
/// with increment affordance and non-mutating preview behavior.
class TodayCountersCard extends StatelessWidget {
  const TodayCountersCard({
    super.key,
    required this.colors,
    required this.strings,
    this.onTap,
  });

  final AppColors colors;
  final TodayStrings strings;
  final VoidCallback? onTap;

  void _openCounters(BuildContext context, FoundationLocalizations copy) {
    if (onTap != null) {
      onTap!();
      return;
    }
    TodayNavigationShell.openPreview(
      context,
      title: copy.dashboardComingSoonCountersTitle,
      feature: DashboardPreviewFeature.counters,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final preview = DashboardPreviewData.standard;
    final counters = preview.counters.take(4).toList();

    return Container(
      key: kDashboardCountersGroup,
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
          // Section Header: Title + View All
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Icon(Icons.repeat_rounded, size: 18, color: colors.primary),
                  Text(
                    copy.dashboardCounters,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      copy.dashboardSampleBadge,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openCounters(context, copy),
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
                        strings.showMore,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_ios_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 columns on narrow, 4 columns on wide
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final columns = constraints.maxWidth >= 600
                  ? 4
                  : (constraints.maxWidth < 240 || textScale >= 1.4 ? 1 : 2);
              final gap = 10.0;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final cnt in counters)
                    SizedBox(
                      width: width,
                      child: Semantics(
                        label:
                            '${copy.dashboardSampleValue}: ${_counterTitle(copy, cnt.id)} ${cnt.count.value}',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceSecondary.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        _counterTitle(copy, cnt.id),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    key: ValueKey(
                                      'counter_increment_${counters.indexOf(cnt)}',
                                    ),
                                    onTap: () => _openCounters(context, copy),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${cnt.count.value ?? 0}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: colors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/ 100',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: ((cnt.count.value ?? 0) / 100.0).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 4,
                                  backgroundColor: colors.surface,
                                  valueColor: AlwaysStoppedAnimation(
                                    colors.primary,
                                  ),
                                ),
                              ),
                            ],
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

  String _counterTitle(FoundationLocalizations copy, String id) => switch (id) {
    'morning' => copy.dashboardAdhkarMorning,
    'evening' => copy.dashboardAdhkarEvening,
    'istighfar' =>
      copy.dashboardPrayerTitle.contains('الصلاة') ? 'الاستغفار' : 'Istighfar',
    'salawat' =>
      copy.dashboardPrayerTitle.contains('الصلاة')
          ? 'الصلاة على النبي'
          : 'Salawat',
    _ => id,
  };
}
