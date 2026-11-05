import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/domain/prayer_day_snapshot.dart';

import '../application/today_prayer_port.dart';
import '../domain/today_prayer_reference.dart';

final class PrayerTodayAdapter implements TodayPrayerPort {
  const PrayerTodayAdapter(this._context);
  final PrayerContextService _context;

  @override
  Stream<TodayPrayerReference> watchPrayer(String ownerId) => _context
      .watch(ownerId)
      .map(
        (snapshot) => TodayPrayerReference(
          ownerId: snapshot.ownerId,
          city: snapshot.preferences?.city.name,
          isDeviceLocation: snapshot.preferences?.city.provider == 'device',
          timeZoneId: snapshot.preferences?.city.timeZoneId,
          localDate: snapshot.localDate?.value,
          nextName: snapshot.projection?.next?.name,
          nextUtc: snapshot.projection?.next?.instantUtc,
          followingName: snapshot.projection?.following?.name,
          followingUtc: snapshot.projection?.following?.instantUtc,
          nowUtc: snapshot.nowUtc,
          sourceUnavailable:
              snapshot.health == PrayerSnapshotHealth.unavailable,
          localFallback:
              snapshot.schedule?.provenance.startsWith('Local calculation') ??
              false,
          calculationMethod: snapshot.preferences?.calculationMethod,
          contextRevision: snapshot.preferences?.revision,
          completedCount: snapshot.completedCount,
          reportsAvailable: snapshot.reportsAvailable,
          unconfirmedReportIds: List.unmodifiable([
            for (final report in snapshot.reports)
              if (report.canonicalRewardConfirmedAt == null) report.reportId,
          ]),
        ),
      );
}
