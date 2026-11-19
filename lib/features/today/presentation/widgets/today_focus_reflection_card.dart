library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_pill.dart';

import '../../domain/today_adhkar_qiyam_reference.dart';
import '../../domain/today_section.dart';
import '../today_adhkar_qiyam_display.dart';

/// The focus session and daily spiritual routine card. The Pomodoro block and
/// the reflection quote are samples and keep their own provenance label; the
/// Adhkar and Qiyam rows are live values from the independent Adhkar/Qiyam
/// source (the same numbers the screens show) and open the real screens.
class TodayFocusReflectionCard extends StatelessWidget {
  const TodayFocusReflectionCard({
    super.key,
    required this.colors,
    this.adhkarQiyam,
    this.onAdhkar,
    this.onQiyam,
  });

  final AppColors colors;

  /// The Adhkar/Qiyam source; null when none is wired.
  final TodaySection<TodayAdhkarQiyamReference>? adhkarQiyam;

  /// Opens the real Adhkar and Qiyam screens.
  final VoidCallback? onAdhkar;
  final VoidCallback? onQiyam;

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

  Widget _sampleBadge(BuildContext context, FoundationLocalizations copy) =>
      AppPill(
        label: copy.dashboardSampleBadge,
        fontSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      );

  /// The three live rows. While the source loads or when it is not wired, a
  /// row shows its label alone; a failed read shows "!" instead of progress.
  List<({String label, IconData icon, bool done, VoidCallback? onTap})> _chips(
    FoundationLocalizations copy,
  ) {
    final live = adhkarQiyam?.value;
    String withValue(String label, String? value) =>
        value == null ? label : '$label $value';
    final morning = live == null
        ? null
        : live.adhkarLoadFailed
        ? '!'
        : todayAdhkarReadable(live)
        ? todayRatio(live.morningCompleted, live.morningTotal)
        : null;
    final evening = live == null
        ? null
        : live.adhkarLoadFailed
        ? '!'
        : todayAdhkarReadable(live)
        ? todayRatio(live.eveningCompleted, live.eveningTotal)
        : null;
    final morningDone =
        live != null &&
        todayAdhkarReadable(live) &&
        live.morningTotal > 0 &&
        live.morningCompleted >= live.morningTotal;
    final eveningDone =
        live != null &&
        todayAdhkarReadable(live) &&
        live.eveningTotal > 0 &&
        live.eveningCompleted >= live.eveningTotal;
    final qiyamValue = live == null
        ? null
        : live.qiyamLoadFailed
        ? '!'
        : switch (live.tonight) {
            TodayQiyamTonight.yes => '✓',
            TodayQiyamTonight.no => '✗',
            _ => null,
          };
    return [
      (
        label: withValue(copy.dashboardAdhkarMorning, morning),
        icon: morningDone
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        done: morningDone,
        onTap: onAdhkar,
      ),
      (
        label: withValue(copy.dashboardAdhkarEvening, evening),
        icon: eveningDone
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        done: eveningDone,
        onTap: onAdhkar,
      ),
      (
        label: withValue(copy.dashboardAdhkarQiyam, qiyamValue),
        icon: Icons.bedtime_outlined,
        done: live?.tonight == TodayQiyamTonight.yes,
        onTap: onQiyam,
      ),
    ];
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _sampleBadge(context, copy),
                    ),
                    const SizedBox(height: 6),
                    isCompact
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
              for (final chip in _chips(copy))
                _AdhkarChip(
                  label: chip.label,
                  icon: chip.icon,
                  isDone: chip.done,
                  colors: colors,
                  onTap: chip.onTap,
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
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _sampleBadge(context, copy),
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
  final VoidCallback? onTap;

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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                color: isDone ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
