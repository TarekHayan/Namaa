import 'package:namma_project/features/prayer/domain/prayer_name.dart';

/// A small, owner-scoped projection; Today never reads Prayer storage.
final class TodayPrayerReference {
  const TodayPrayerReference({
    required this.ownerId,
    required this.city,
    required this.timeZoneId,
    required this.localDate,
    required this.nextName,
    required this.nextUtc,
    required this.followingName,
    required this.followingUtc,
    required this.nowUtc,
    this.sourceUnavailable = false,
    this.localFallback = false,
    this.isDeviceLocation = false,
    this.calculationMethod,
    this.contextRevision,
    this.completedCount,
    this.reportsAvailable = false,
  });

  final String ownerId;
  final String? city;
  final String? timeZoneId;
  final String? localDate;
  final PrayerName? nextName;
  final DateTime? nextUtc;
  final PrayerName? followingName;
  final DateTime? followingUtc;
  final DateTime nowUtc;
  final bool sourceUnavailable;
  final bool localFallback;
  final bool isDeviceLocation;
  final String? calculationMethod;
  final int? contextRevision;
  final int? completedCount;
  final bool reportsAvailable;

  bool get needsSetup => city == null && !sourceUnavailable;
  bool get scheduleAvailable => nextName != null && nextUtc != null;
}
