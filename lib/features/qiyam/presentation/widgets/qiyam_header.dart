import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_pill.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// The heading (approved design, 2026-11-18): the title and subtitle, then
/// the chip with the last third of the night — or the unavailable reason with
/// the Prayer-setup button — and the Qiyam streak chip. A failed streak read
/// shows the failure chip instead of the streak, never a streak of 0.
final class QiyamHeader extends StatelessWidget {
  const QiyamHeader({
    super.key,
    required this.copy,
    required this.night,
    required this.locale,
    this.streak,
    this.streakFailed = false,
    this.onOpenPrayerSetup,
  });

  final QiyamStrings copy;

  /// The resolved night; null while the first load runs (only the title
  /// shows then).
  final QiyamNightState? night;
  final String locale;

  /// The derived streak; the chip is hidden until the first successful read.
  final int? streak;
  final bool streakFailed;

  /// Opens the Prayer location setup; null hides the setup button.
  final VoidCallback? onOpenPrayerSetup;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final resolved = night;
    final lastThird = resolved?.lastThirdUtc;
    final zoneId = resolved?.zoneId;
    final available = lastThird != null && zoneId != null;
    return Column(
      key: const Key('qiyam_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            copy.title,
            style: AppTypography.fixed(
              24,
              FontWeight.w700,
              colors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.subtitle,
          style: AppTypography.fixed(
            14,
            FontWeight.w400,
            colors.textSecondary,
            height: 1.6,
          ),
        ),
        if (resolved != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (available)
                AppPill(
                  key: const Key('qiyam_last_third_chip'),
                  label: copy.lastThird(
                    formatQiyamTime(lastThird, zoneId, locale),
                  ),
                  icon: Icons.dark_mode_outlined,
                  fontSize: 14,
                  hairline: true,
                  minHeight: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                )
              else
                AppPill(
                  key: const Key('qiyam_last_third_chip'),
                  label: copy.lastThirdUnavailable,
                  tone: AppPillTone.warning,
                  icon: Icons.error_outline,
                  fontSize: 14,
                  radius: 16,
                  minHeight: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              if (streakFailed)
                AppPill(
                  key: const Key('qiyam_streak_failed'),
                  label: copy.streakFailed,
                  tone: AppPillTone.error,
                  icon: Icons.error_outline,
                  fontSize: 14,
                  radius: 16,
                  minHeight: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                )
              else if (streak != null)
                AppPill(
                  key: const Key('qiyam_streak_chip'),
                  label: copy.streak(streak!),
                  tone: AppPillTone.neutral,
                  icon: Icons.local_fire_department_outlined,
                  iconColor: colors.warning,
                  fontSize: 14,
                  minHeight: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
            ],
          ),
          if (!available && onOpenPrayerSetup != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                key: const Key('qiyam_open_prayer_setup'),
                label: copy.openPrayerSetup,
                onPressed: onOpenPrayerSetup,
                look: AppButtonLook.refined,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                color: colors.warning,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Formats [instantUtc] in the location's zone as `HH:mm`. Composition
/// initializes the IANA database at startup; this helper loads it itself when
/// rendered without composition (widget tests), like the Prayer adapter does.
String formatQiyamTime(DateTime instantUtc, String zoneId, String locale) {
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
