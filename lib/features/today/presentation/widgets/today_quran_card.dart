library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Illustrative Quran reading progress and memorization card presenting sample data.
class TodayQuranCard extends StatelessWidget {
  const TodayQuranCard({super.key, required this.colors});

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
                  Icons.menu_book_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.dashboardQuranSectionTitle,
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
              const Spacer(),
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
          // Wird Header & Progress
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.dashboardQuranWirdTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    copy.dashboardQuranProgressInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '302 / 304',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 6,
              backgroundColor: colors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 14),
          // Ayah Quote Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_outline_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        copy.dashboardQuranAyahRef,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  copy.dashboardQuranAyahQuote,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                copy.dashboardQuranRemainingPages,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              FilledButton.icon(
                onPressed: () => _showNotice(context, copy),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: isDark ? colors.background : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                label: Text(
                  copy.dashboardQuranContinueReading,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.border),
          const SizedBox(height: 10),
          // Memorization snippet
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 290;
              final snippetHeader = Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: colors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.dashboardQuranMemorizationTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          copy.dashboardQuranMemorizationDetail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final reciteButton = OutlinedButton.icon(
                onPressed: () => _showNotice(context, copy),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: const Icon(Icons.mic_none_rounded, size: 14),
                label: Text(
                  copy.dashboardQuranStartRecite,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    snippetHeader,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: reciteButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: snippetHeader),
                  const SizedBox(width: 6),
                  reciteButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
