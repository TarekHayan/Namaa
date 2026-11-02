library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';

import '../../domain/today_prayer_reference.dart';
import '../../domain/today_section.dart';
import '../today_dashboard_view.dart';

/// Home uses the same owner-scoped Prayer projection as the Prayer screen.
class TodayPrayerCard extends StatelessWidget {
  const TodayPrayerCard({
    super.key,
    required this.colors,
    this.prayer,
    this.onTap,
    this.onRetry,
  });

  final AppColors colors;
  final TodaySection<TodayPrayerReference>? prayer;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  String _name(FoundationLocalizations copy, PrayerName name) => switch (name) {
    PrayerName.fajr => copy.prayerFajr,
    PrayerName.dhuhr => copy.prayerDhuhr,
    PrayerName.asr => copy.prayerAsr,
    PrayerName.maghrib => copy.prayerMaghrib,
    PrayerName.isha => copy.prayerIsha,
  };

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final source = prayer;
    final value = source?.value;
    final isReady =
        value != null &&
        !value.needsSetup &&
        value.scheduleAvailable &&
        source?.status == TodaySectionStatus.available;
    final now = value?.nowUtc;
    final next = value?.nextUtc;
    final remaining = isReady && now != null && next != null
        ? next.difference(now)
        : null;
    final countdown = remaining == null
        ? null
        : '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    final locale = Localizations.localeOf(context).languageCode;
    final deviceDate = now?.toLocal();
    final deviceDateKey = deviceDate == null
        ? null
        : '${deviceDate.year.toString().padLeft(4, '0')}-${deviceDate.month.toString().padLeft(2, '0')}-${deviceDate.day.toString().padLeft(2, '0')}';
    final cityDateDiffers =
        value?.localDate != null && value!.localDate != deviceDateKey;
    return Card(
      key: kDashboardPrayerGroup,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      copy.prayerTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (value?.city != null)
                    Flexible(
                      child: Text(
                        value!.isDeviceLocation
                            ? copy.prayerCurrentLocation
                            : value.city!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (cityDateDiffers && value.timeZoneId != null) ...[
                Text(
                  '${copy.prayerDateZone}: ${prayerLocalDateLabel(PrayerLocalDate.parse(value.localDate!), locale)} · ${value.timeZoneId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              if (isReady) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.dashboardNextPrayer,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        Text(
                          _name(copy, value.nextName!),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          prayerLocalTime(next!, value.timeZoneId!, locale),
                          style: TextStyle(color: colors.primary),
                        ),
                      ],
                    ),
                    if (countdown != null)
                      Text(
                        countdown,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: colors.primary),
                      ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  value.followingName == null || value.followingUtc == null
                      ? copy.prayerUnavailable
                      : '${copy.dashboardPrayerUpcoming}: ${_name(copy, value.followingName!)} (${prayerLocalTime(value.followingUtc!, value.timeZoneId!, locale)})',
                ),
                if (value.localFallback) ...[
                  const SizedBox(height: 8),
                  Text(
                    copy.prayerSourceLocal,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ] else if (source?.status == TodaySectionStatus.loading ||
                  source == null)
                Text(copy.todayLoading)
              else if (value?.needsSetup == true)
                Text(copy.prayerSetupBody)
              else
                Text(copy.prayerScheduleUnavailable),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: source?.needsRetry == true ? onRetry : onTap,
                  child: Text(
                    source?.needsRetry == true ? copy.retry : copy.prayerTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
