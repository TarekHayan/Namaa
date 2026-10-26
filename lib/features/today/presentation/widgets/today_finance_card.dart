library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import 'today_navigation_shell.dart';

/// Prototype-aligned Finance summary featuring two structured tiles:
/// 1. Spending Summary tile, and 2. Savings Milestone tile, with clear sample provenance.
class TodayFinanceCard extends StatelessWidget {
  const TodayFinanceCard({super.key, required this.colors, this.onTap});

  final AppColors colors;
  final VoidCallback? onTap;

  void _openFinance(BuildContext context, FoundationLocalizations copy) {
    if (onTap != null) {
      onTap!();
      return;
    }
    TodayNavigationShell.openPreview(
      context,
      title: copy.dashboardComingSoonFinanceTitle,
      feature: DashboardPreviewFeature.finance,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final preview = DashboardPreviewData.standard.finance;

    final spent = preview.spent.value ?? 3640;
    final saved = preview.saved.value ?? 8200;
    final budgetProgress = preview.budgetProgress.value ?? 0.52;

    return Container(
      key: kDashboardFinanceGroup,
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
          // Section Header: Green dot + Title + Open Finance button
          LayoutBuilder(
            builder: (context, headerConstraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: headerConstraints.maxWidth,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            copy.dashboardFinance,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openFinance(context, copy),
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
                            copy.dashboardComingSoonFinanceTitle,
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
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Two-tile layout: 1 column on narrow, 2 columns on wide
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;
              final gap = 12.0;
              final tileWidth = isWide
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  // Tile 1: Spending Summary
                  SizedBox(
                    width: tileWidth,
                    child: Semantics(
                      label:
                          '${copy.dashboardSampleValue}: ${copy.dashboardFinanceSpent} $spent ${copy.dashboardFinanceCurrency}',
                      child: InkWell(
                        onTap: () => _openFinance(context, copy),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceSecondary.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    copy.dashboardFinanceSpent,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.border.withValues(
                                        alpha: 0.4,
                                      ),
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
                              const SizedBox(height: 8),
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
                                      '$spent',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      copy.dashboardFinanceCurrency,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${copy.dashboardFinanceMonth}: 12,450 ${copy.dashboardFinanceCurrency}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tile 2: Savings Milestone
                  SizedBox(
                    width: tileWidth,
                    child: Semantics(
                      label:
                          '${copy.dashboardSampleValue}: ${copy.dashboardFinanceSavings} $saved ${copy.dashboardFinanceCurrency}',
                      child: InkWell(
                        onTap: () => _openFinance(context, copy),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceSecondary.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.savings_outlined,
                                        size: 14,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        copy.dashboardFinanceSavings,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(budgetProgress * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primary,
                                    ),
                                  ),
                                  Text(
                                    copy.dashboardSampleBadge,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                                      '$saved',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      copy.dashboardFinanceCurrency,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${copy.dashboardFinanceSavings}: 10,000 ${copy.dashboardFinanceCurrency}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textMuted,
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
