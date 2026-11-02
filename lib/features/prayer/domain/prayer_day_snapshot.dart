import 'prayer_local_date.dart';
import 'prayer_preferences.dart';
import 'prayer_report.dart';
import 'prayer_schedule.dart';
import 'prayer_schedule_projection.dart';
import 'prayer_status.dart';

enum PrayerSnapshotHealth { setupRequired, available, partial, unavailable }

final class PrayerDaySnapshot {
  PrayerDaySnapshot({
    required this.ownerId,
    required this.health,
    required this.nowUtc,
    this.preferences,
    this.localDate,
    this.schedule,
    this.tomorrow,
    this.projection,
    this.reports = const [],
    this.reportsAvailable = false,
  });

  final String ownerId;
  final PrayerSnapshotHealth health;
  final DateTime nowUtc;
  final PrayerPreferences? preferences;
  final PrayerLocalDate? localDate;
  final PrayerSchedule? schedule;
  final PrayerSchedule? tomorrow;
  final PrayerScheduleProjection? projection;
  final List<PrayerReport> reports;
  final bool reportsAvailable;
  int? get completedCount => reportsAvailable
      ? reports.where((report) => report.status.isCompleted).length
      : null;
}
