library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Illustrative personal finance snapshot presenting sample ledger & budget tracking.
class TodayFinanceCard extends StatelessWidget {
  const TodayFinanceCard({super.key, required this.colors});

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
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.dashboardFinanceSectionTitle,
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
                  copy.dashboardFinanceMonth,
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
          // 3 Metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        copy.dashboardFinanceTotalBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '12,450 ${copy.dashboardFinanceCurrency}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: colors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        copy.dashboardFinanceAvailable,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '4,250 ${copy.dashboardFinanceCurrency}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: colors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        copy.dashboardFinanceSavings,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '8,200 ${copy.dashboardFinanceCurrency}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.info,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 7-day flow header & chart
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                copy.dashboardFinanceFlowTitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    copy.dashboardFinanceIncome,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    copy.dashboardFinanceExpense,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniFlowChart(colors: colors),
          const SizedBox(height: 14),
          // Budget consumption
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                copy.dashboardFinanceBudgetConsumption,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                copy.dashboardFinanceBudgetConsumed,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: 0.52,
              minHeight: 6,
              backgroundColor: colors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(colors.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${copy.dashboardFinanceSpent}: 3,640 ${copy.dashboardFinanceCurrency}',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
              Text(
                '${copy.dashboardFinanceRemaining}: 3,360 ${copy.dashboardFinanceCurrency}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                copy.dashboardFinanceDaysLeft,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 280;
              final buttons = [
                FilledButton.tonal(
                  onPressed: () => _showNotice(context, copy),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentSoft,
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    copy.dashboardFinanceAddIncome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showNotice(context, copy),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(
                      color: colors.error.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    copy.dashboardFinanceAddExpense,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _showNotice(context, copy),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.info.withValues(alpha: 0.12),
                    foregroundColor: colors.info,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    copy.dashboardFinanceAddSaving,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ];

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      buttons[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: buttons[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniFlowChart extends StatelessWidget {
  const _MiniFlowChart({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final data = [
      (income: 0.20, expense: 0.35),
      (income: 0.00, expense: 0.50),
      (income: 0.60, expense: 0.25),
      (income: 0.00, expense: 0.40),
      (income: 0.85, expense: 0.20),
      (income: 0.15, expense: 0.15),
      (income: 0.10, expense: 0.10),
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in data)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 5,
                  height: (40 * day.expense).clamp(4.0, 40.0),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 5,
                  height: (40 * day.income).clamp(2.0, 40.0),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
