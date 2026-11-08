import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Informational times do not represent additional prayers or report actions.
/// Prototype: three centered tiles (one column on phones).
class PrayerSupplementaryTimes extends StatelessWidget {
  const PrayerSupplementaryTimes({
    super.key,
    required this.timeZoneId,
    this.sunriseUtc,
    this.middleOfNightUtc,
    this.lastThirdUtc,
  });

  final String timeZoneId;
  final DateTime? sunriseUtc;
  final DateTime? middleOfNightUtc;
  final DateTime? lastThirdUtc;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark ? AppColors.dark : AppColors.light;
    final entries = [
      (
        copy.prayerSunrise,
        sunriseUtc,
        dark ? colors.warning : colors.textSecondary,
      ),
      (copy.prayerMiddleNight, middleOfNightUtc, colors.textPrimary),
      (
        copy.prayerLastThird,
        lastThirdUtc,
        dark ? colors.info : colors.textSecondary,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 600 && scale <= 1.3 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < entries.length; i++)
              Container(
                key: Key('prayer_supplementary_$i'),
                width: width,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      entries[i].$1,
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entries[i].$2 == null
                          ? copy.prayerUnavailable
                          : prayerLocalTime(entries[i].$2!, timeZoneId, locale),
                      textAlign: TextAlign.center,
                      style: entries[i].$2 == null
                          ? text.bodySmall?.copyWith(color: colors.textMuted)
                          : text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: entries[i].$3,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
