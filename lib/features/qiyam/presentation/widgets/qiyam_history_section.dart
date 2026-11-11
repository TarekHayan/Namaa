import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';

/// The history section (the prototype's style): past nights, newest first,
/// 30 nights per page with "Load more" for the next one — pages are fetched
/// on demand, never the full history. Read-only, and the word "missed"
/// never appears: an explicit "No" is "Did not pray" and an unrecorded
/// night is "Not recorded". A failed page fetch shows a failure, never an
/// empty history.
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
  });

  final QiyamStrings copy;
  final String locale;
  final List<QiyamHistoryEntry> entries;
  final bool loading;
  final bool failed;
  final bool complete;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('qiyam_history_section'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.historyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (failed) ...[
              Text(
                copy.historyFailed,
                key: const Key('qiyam_history_failed'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
              const SizedBox(height: 8),
            ],
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      DateFormat.MMMEd(
                        locale,
                      ).format(_nightDate(entry.nightDate)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _stateOf(entry),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!complete) ...[
              const SizedBox(height: 8),
              TextButton(
                key: const Key('qiyam_load_more'),
                onPressed: onLoadMore,
                child: Text(copy.historyLoadMore),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The read-only state text of one night: "Prayed · n rak'ahs · Witr"
  /// (or without the Witr part), "Did not pray" for the explicit "No", and
  /// "Not recorded" for a night with no row.
  String _stateOf(QiyamHistoryEntry entry) {
    final record = entry.record;
    if (record == null) return copy.historyNotRecorded;
    if (!record.performed) return copy.historyNotPerformed;
    final rakahs = record.rakahs!;
    return record.witr
        ? copy.historyPrayedWithWitr(rakahs)
        : copy.historyPrayed(rakahs);
  }

  static DateTime _nightDate(String nightDate) => DateTime.utc(
    int.parse(nightDate.substring(0, 4)),
    int.parse(nightDate.substring(5, 7)),
    int.parse(nightDate.substring(8, 10)),
  );
}
