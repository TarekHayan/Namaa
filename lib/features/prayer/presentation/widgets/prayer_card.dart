import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';

import '../../domain/prayer_guidance.dart';
import '../../domain/prayer_name.dart';
import '../../domain/prayer_status.dart';
import '../prayer_state.dart';
import 'prayer_status_actions.dart';

/// A single content-sized prayer card; state and actions remain explicit.
class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.name,
    required this.timeZoneId,
    required this.scheduledUtc,
    required this.status,
    required this.phase,
    required this.onStatusChanged,
  });

  final PrayerName name;
  final String timeZoneId;
  final DateTime? scheduledUtc;
  final PrayerStatus status;
  final PrayerActionPhase phase;
  final ValueChanged<PrayerStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final stateColor = switch (status) {
      PrayerStatus.completedOnTime => colors.success,
      PrayerStatus.completedLate => colors.warning,
      PrayerStatus.missed => colors.error,
      PrayerStatus.pending => null,
    };
    return AppHoverSurface(
      radius: 32,
      child: Container(
        key: Key('prayer_time_${name.wireName}'),
        decoration: BoxDecoration(
          color: stateColor == null
              ? colors.surface
              : Color.alphaBlend(
                  stateColor.withValues(alpha: 0.10),
                  colors.surface,
                ),
          border: Border.all(
            color: stateColor?.withValues(alpha: 0.40) ?? colors.border,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width >= 640 ? 24 : 20,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 820 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.2;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        prayerNameLabel(copy, name),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        scheduledUtc == null
                            ? copy.prayerUnavailable
                            : prayerLocalTime(
                                scheduledUtc!,
                                timeZoneId,
                                locale,
                              ),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      copy.prayerResidentRakahs(residentObligatoryRakahs(name)),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(switch (name) {
                  PrayerName.fajr => copy.prayerRecitationFajr,
                  PrayerName.dhuhr ||
                  PrayerName.asr => copy.prayerRecitationQuiet,
                  PrayerName.maghrib => copy.prayerRecitationMaghrib,
                  PrayerName.isha => copy.prayerRecitationIsha,
                }),
                const SizedBox(height: 6),
                Text(switch (name) {
                  PrayerName.fajr => copy.prayerOptionalFajr,
                  PrayerName.dhuhr => copy.prayerOptionalDhuhr,
                  PrayerName.asr => copy.prayerOptionalAsr,
                  PrayerName.maghrib => copy.prayerOptionalMaghrib,
                  PrayerName.isha => copy.prayerOptionalIsha,
                }, style: Theme.of(context).textTheme.bodySmall),
              ],
            );
            final controls = PrayerStatusActions(
              name: name,
              status: status,
              phase: phase,
              onChanged: onStatusChanged,
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 24),
                      SizedBox(width: 410, child: controls),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      details,
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      controls,
                    ],
                  );
          },
        ),
      ),
    );
  }
}
