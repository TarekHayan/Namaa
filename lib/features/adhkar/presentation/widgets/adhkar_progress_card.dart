import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// The progress card (the prototype's second group): "{list} (x / N)", a
/// progress bar and the percentage. When the list is outside its time the
/// "its time starts at {time}" notice shows; an unavailable schedule shows
/// the counting-locked notice instead.
final class AdhkarProgressCard extends StatelessWidget {
  const AdhkarProgressCard({
    super.key,
    required this.copy,
    required this.locale,
    required this.listLabel,
    required this.completed,
    required this.total,
    required this.countable,
    required this.startsAtUtc,
    required this.zoneId,
    required this.countingLocked,
  });

  final AdhkarStrings copy;
  final String locale;
  final String listLabel;
  final int completed;
  final int total;
  final bool countable;
  final DateTime? startsAtUtc;
  final String? zoneId;
  final bool countingLocked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();
    return Card(
      key: const Key('adhkar_progress_card'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.progress(listLabel, completed, total),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  copy.percent(percent),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const Key('adhkar_progress_bar'),
                value: total == 0 ? 0 : completed / total,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              copy.completedSummary(completed),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (!countable && startsAtUtc != null && zoneId != null) ...[
              const SizedBox(height: 8),
              Text(
                copy.startsAt(_formatTime(startsAtUtc!, zoneId!, locale)),
                key: const Key('adhkar_starts_at_notice'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            if (countingLocked) ...[
              const SizedBox(height: 8),
              Text(
                copy.countingLocked,
                key: const Key('adhkar_locked_notice'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formats the notice instant in the location's zone (HH:mm). Composition
  /// initializes the IANA database at startup; this helper loads it itself
  /// when rendered without composition (widget tests), like the Prayer
  /// adapter does.
  static String _formatTime(DateTime instantUtc, String zoneId, String locale) {
    if (tz.timeZoneDatabase.locations.isEmpty) {
      timezone_data.initializeTimeZones();
    }
    try {
      final cityTime = tz.TZDateTime.from(instantUtc, tz.getLocation(zoneId));
      return DateFormat.Hm(locale).format(cityTime);
    } catch (_) {
      return DateFormat.Hm(locale).format(instantUtc.toUtc());
    }
  }
}
