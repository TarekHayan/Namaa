import 'package:flutter/material.dart';

import '../../domain/prayer_name.dart';
import '../../domain/prayer_report.dart';
import '../../domain/prayer_schedule.dart';
import '../../domain/prayer_status.dart';
import '../prayer_state.dart';
import 'prayer_card.dart';

/// Keeps the canonical five-prayer order independent of report order.
class PrayerScheduleList extends StatelessWidget {
  const PrayerScheduleList({
    super.key,
    required this.schedule,
    required this.timeZoneId,
    required this.reports,
    required this.actions,
    required this.onStatusChanged,
  });

  final PrayerSchedule? schedule;
  final String timeZoneId;
  final List<PrayerReport> reports;
  final Map<PrayerName, PrayerActionPhase> actions;
  final void Function(PrayerName name, PrayerStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final name in PrayerName.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PrayerCard(
            name: name,
            timeZoneId: timeZoneId,
            scheduledUtc: schedule?.times[name]?.instantUtc,
            status:
                reports
                    .where((report) => report.name == name)
                    .map((report) => report.status)
                    .firstOrNull ??
                PrayerStatus.pending,
            phase: actions[name] ?? PrayerActionPhase.idle,
            onStatusChanged: (status) => onStatusChanged(name, status),
          ),
        ),
    ],
  );
}
