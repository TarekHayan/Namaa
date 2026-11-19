import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_ink_surface.dart';
import 'package:namma_project/app/widgets/app_notice.dart';

import '../qiyam_state.dart';

/// The history section (approved design, 2026-11-18): past nights, newest
/// first, 30 nights per page with "Load more" appending the next page under
/// the list. Each row shows the night and its state — "Prayed · n rak'ahs ·
/// with Witr", "Prayed · 2 rak'ahs", "Did not pray" or "Not recorded", never
/// "missed" — and opens the night's read-only details. A failed page fetch
/// shows a failure with a retry button, never an empty history. With nothing
/// recorded yet the section stays out of the way.
final class QiyamHistorySection extends StatelessWidget {
  const QiyamHistorySection({
    super.key,
    required this.copy,
    required this.locale,
    required this.entries,
    required this.loading,
    required this.failed,
    required this.complete,
    required this.onLoadMore,
    required this.onOpenNight,
  });

  final QiyamStrings copy;
  final String locale;
  final List<QiyamHistoryEntry> entries;
  final bool loading;
  final bool failed;
  final bool complete;

  /// Loads the next page; also the retry after a failed page.
  final VoidCallback onLoadMore;
  final ValueChanged<QiyamHistoryEntry> onOpenNight;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (entries.isEmpty && complete && !failed && !loading) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('qiyam_history_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            copy.historyTitle,
            style: AppTypography.fixed(
              20,
              FontWeight.w600,
              colors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isNotEmpty)
          AppCard(
            radius: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _NightRow(
                      copy: copy,
                      locale: locale,
                      entry: entries[i],
                      last: i == entries.length - 1,
                      onTap: () => onOpenNight(entries[i]),
                    ),
                ],
              ),
            ),
          ),
        if (failed) ...[
          if (entries.isNotEmpty) const SizedBox(height: 12),
          _HistoryError(copy: copy, onRetry: onLoadMore),
        ] else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (!complete) ...[
          const SizedBox(height: 12),
          AppButton(
            key: const Key('qiyam_load_more'),
            label: copy.historyLoadMore,
            onPressed: onLoadMore,
            look: AppButtonLook.refined,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            expanded: true,
          ),
        ],
      ],
    );
  }
}

/// The read-only state text of one night: "Prayed · n rak'ahs · with Witr"
/// (or without the Witr part), "Did not pray" for the explicit "No", and
/// "Not recorded" for a night with no row.
String qiyamNightStateText(QiyamStrings copy, QiyamHistoryEntry entry) {
  final record = entry.record;
  if (record == null) return copy.historyNotRecorded;
  if (!record.performed) return copy.historyNotPerformed;
  final rakahs = record.rakahs!;
  return record.witr
      ? copy.historyPrayedWithWitr(rakahs)
      : copy.historyPrayed(rakahs);
}

/// The night's civil date as a [DateTime] for formatting.
DateTime qiyamNightDay(String nightDate) => DateTime.utc(
  int.parse(nightDate.substring(0, 4)),
  int.parse(nightDate.substring(5, 7)),
  int.parse(nightDate.substring(8, 10)),
);

final class _NightRow extends StatelessWidget {
  const _NightRow({
    required this.copy,
    required this.locale,
    required this.entry,
    required this.last,
    required this.onTap,
  });

  final QiyamStrings copy;
  final String locale;
  final QiyamHistoryEntry entry;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final record = entry.record;
    final (IconData icon, Color iconColor) = record == null
        ? (Icons.radio_button_unchecked, colors.textSecondary)
        : record.performed
        ? (Icons.check_circle_outline, colors.accentStrong)
        : (Icons.remove_circle_outline, colors.textSecondary);
    final date = DateFormat.MMMMEEEEd(
      locale,
    ).format(qiyamNightDay(entry.nightDate));
    final state = qiyamNightStateText(copy, entry);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$date, $state',
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: colors.border)),
        ),
        child: AppInkSurface(
          key: Key('qiyam_history_row_${entry.nightDate}'),
          color: Colors.transparent,
          radius: 0,
          minHeight: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: onTap,
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: AppTypography.fixed(
                        16,
                        FontWeight.w600,
                        colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state,
                      style: AppTypography.fixed(
                        14,
                        FontWeight.w400,
                        colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.copy, required this.onRetry});

  final QiyamStrings copy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    key: const Key('qiyam_history_failed'),
    tone: AppCardTone.error,
    radius: 16,
    padding: const EdgeInsets.all(16),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInlineNote(text: copy.historyFailed, tone: AppNoticeTone.error),
          const SizedBox(height: 12),
          AppButton(
            key: const Key('qiyam_history_retry'),
            label: copy.retry,
            onPressed: onRetry,
            look: AppButtonLook.refined,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
          ),
        ],
      ),
    ),
  );
}
