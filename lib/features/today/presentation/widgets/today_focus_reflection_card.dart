library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Illustrative focus session and daily spiritual routine card presenting sample data.
class TodayFocusReflectionCard extends StatelessWidget {
  const TodayFocusReflectionCard({super.key, required this.colors});

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
                  Icons.timer_outlined,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.dashboardFocusSectionTitle,
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
          // Pomodoro Block
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 320;
              final timerCircle = Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '25',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              );

              final textInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.dashboardFocusPomodoroTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${copy.dashboardFocusPomodoroDuration} · ${copy.dashboardFocusCompletedToday}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );

              final startButton = FilledButton.icon(
                onPressed: () => _showNotice(context, copy),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: isDark ? colors.background : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(
                  copy.dashboardFocusStart,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              timerCircle,
                              const SizedBox(width: 10),
                              Expanded(child: textInfo),
                            ],
                          ),
                          const SizedBox(height: 10),
                          startButton,
                        ],
                      )
                    : Row(
                        children: [
                          timerCircle,
                          const SizedBox(width: 12),
                          Expanded(child: textInfo),
                          const SizedBox(width: 8),
                          startButton,
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Daily Adhkar Section
          Text(
            copy.dashboardAdhkarTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdhkarChip(
                label: copy.dashboardAdhkarMorning,
                icon: Icons.check_circle_rounded,
                isDone: true,
                colors: colors,
                onTap: () => _showNotice(context, copy),
              ),
              _AdhkarChip(
                label: copy.dashboardAdhkarEvening,
                icon: Icons.radio_button_unchecked_rounded,
                isDone: false,
                colors: colors,
                onTap: () => _showNotice(context, copy),
              ),
              _AdhkarChip(
                label: copy.dashboardAdhkarQiyam,
                icon: Icons.bedtime_outlined,
                isDone: false,
                colors: colors,
                onTap: () => _showNotice(context, copy),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.border),
          const SizedBox(height: 10),
          // Reflection Quote Box
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            copy.dashboardReflectionTitle,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showNotice(context, copy),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                copy.dashboardReflectionAction,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  copy.dashboardReflectionQuote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdhkarChip extends StatelessWidget {
  const _AdhkarChip({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isDone;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? colors.accentSoft : colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isDone ? colors.primary.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDone ? colors.primary : colors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
              color: isDone ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
