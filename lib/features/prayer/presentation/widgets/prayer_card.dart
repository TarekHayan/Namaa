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

/// One prototype prayer card (`PrayerView.tsx`): icon, name with rak'ahs
/// pill, time • recitation, sunnah note, and the status actions inline on
/// wide layouts or under a separator on phones.
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
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark ? AppColors.dark : AppColors.light;
    final stateColor = switch (status) {
      PrayerStatus.completedOnTime => colors.success,
      PrayerStatus.completedLate => colors.warning,
      PrayerStatus.missed => colors.error,
      PrayerStatus.pending => null,
    };
    // The prototype tints the icon only for completed states.
    final iconTint = switch (status) {
      PrayerStatus.completedOnTime => colors.success,
      PrayerStatus.completedLate => colors.warning,
      _ => null,
    };
    final muted = colors.textMuted;

    final icon = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconTint?.withValues(alpha: 0.20) ?? colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.access_time_rounded,
        size: 20,
        color: iconTint ?? colors.textPrimary,
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(prayerNameLabel(copy, name), style: text.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                copy.prayerResidentRakahs(residentObligatoryRakahs(name)),
                style: text.labelSmall?.copyWith(
                  color: dark ? muted : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // A Row keeps "time •" together; only the recitation wraps, inside
        // its own column, so the separator never dangles at a line end.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // A short time keeps its width; the long "unavailable" message
            // shares the row and wraps instead of overflowing.
            Flexible(
              flex: scheduledUtc == null ? 1 : 0,
              child: Text(
                scheduledUtc == null
                    ? copy.prayerUnavailable
                    : prayerLocalTime(scheduledUtc!, timeZoneId, locale),
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheduledUtc == null ? muted : colors.success,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: text.bodySmall?.copyWith(
                  color: colors.textPrimary.withValues(alpha: 0.4),
                ),
              ),
            ),
            Flexible(
              child: Text(
                switch (name) {
                  PrayerName.fajr => copy.prayerRecitationFajr,
                  PrayerName.dhuhr ||
                  PrayerName.asr => copy.prayerRecitationQuiet,
                  PrayerName.maghrib => copy.prayerRecitationMaghrib,
                  PrayerName.isha => copy.prayerRecitationIsha,
                },
                style: text.bodySmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          switch (name) {
            PrayerName.fajr => copy.prayerOptionalFajr,
            PrayerName.dhuhr => copy.prayerOptionalDhuhr,
            PrayerName.asr => copy.prayerOptionalAsr,
            PrayerName.maghrib => copy.prayerOptionalMaghrib,
            PrayerName.isha => copy.prayerOptionalIsha,
          },
          style: text.labelSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
      ],
    );

    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 14),
        Expanded(child: details),
      ],
    );

    final actions = PrayerStatusActions(
      name: name,
      status: status,
      phase: phase,
      onChanged: onStatusChanged,
    );

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
                constraints.maxWidth >= 600 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.2;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: actions,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
