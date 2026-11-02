import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';

/// Informational times do not represent additional prayers or report actions.
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
    final locale = Localizations.localeOf(context).languageCode;
    final entries = [
      (copy.prayerSunrise, sunriseUtc),
      (copy.prayerMiddleNight, middleOfNightUtc),
      (copy.prayerLastThird, lastThirdUtc),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 640 && scale <= 1.3 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < entries.length; i++)
              SizedBox(
                width: width,
                child: Card(
                  key: Key('prayer_supplementary_$i'),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].$1,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entries[i].$2 == null
                              ? copy.prayerUnavailable
                              : prayerLocalTime(
                                  entries[i].$2!,
                                  timeZoneId,
                                  locale,
                                ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
