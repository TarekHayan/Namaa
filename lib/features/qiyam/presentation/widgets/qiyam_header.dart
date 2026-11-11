import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// The heading (the prototype's first group): the title and subtitle, and
/// the chip with the last third of the night — or the unavailable reason
/// with the Prayer-setup link.
final class QiyamHeader extends StatelessWidget {
  const QiyamHeader({
    super.key,
    required this.copy,
    required this.night,
    required this.locale,
    required this.locked,
  });

  final QiyamStrings copy;
  final QiyamNightState? night;
  final String locale;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastThird = night?.lastThirdUtc;
    final zoneId = night?.zoneId;
    return Column(
      key: const Key('qiyam_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nightlight_round, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                copy.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          copy.subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _LastThirdChip(
          copy: copy,
          lastThirdUtc: lastThird,
          zoneId: zoneId,
          locale: locale,
          locked: locked,
        ),
      ],
    );
  }
}

final class _LastThirdChip extends StatelessWidget {
  const _LastThirdChip({
    required this.copy,
    required this.lastThirdUtc,
    required this.zoneId,
    required this.locale,
    required this.locked,
  });

  final QiyamStrings copy;
  final DateTime? lastThirdUtc;
  final String? zoneId;
  final String locale;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = lastThirdUtc != null && zoneId != null;
    return Container(
      key: const Key('qiyam_last_third_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              available
                  ? copy.lastThird(_formatTime(lastThirdUtc!, zoneId!, locale))
                  : copy.lastThirdUnavailable,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the chip instant in the location's zone (HH:mm). Composition
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
