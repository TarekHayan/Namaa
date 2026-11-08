import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/application/prayer_schedule_calculator_port.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/today/data/prayer_today_adapter.dart';

final class _Preferences extends Fake implements PrayerPreferencesPort {
  _Preferences(this.value);
  final PrayerPreferences value;

  @override
  Stream<PrayerPreferences?> watch(String accountId) => Stream.value(value);
}

final class _Reports extends Fake implements PrayerRepository {
  _Reports(this.value);
  final PrayerReport value;

  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) => Stream.value(
    accountId == value.accountId && date == value.date ? [value] : const [],
  );
}

final class _Calculator extends Fake implements PrayerScheduleCalculatorPort {
  @override
  AppResult<PrayerSchedule> calculate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) {
    final utc = DateTime.parse('${date.value}T00:00:00Z');
    return AppResult.success(
      PrayerSchedule(
        date: date,
        contextRevision: preferences.revision,
        times: {
          for (final name in PrayerName.values)
            name: PrayerTime(
              name: name,
              instantUtc: utc.add(Duration(hours: 2 + name.index * 4)),
            ),
        },
        provenance: 'fixture',
      ),
    );
  }
}

void main() {
  test(
    'Home keeps report count while each device retains its own city',
    () async {
      const owner = 'owner-a';
      final now = DateTime.utc(2026, 10, 29, 9);
      final date = PrayerLocalDate.parse('2026-10-29');
      final report = PrayerReport(
        accountId: owner,
        reportId: 'report-fajr',
        date: date,
        name: PrayerName.fajr,
        status: PrayerStatus.completedOnTime,
        reportedCompletionAt: now,
        recordedZoneId: 'Africa/Cairo',
        recordedOffsetMinutes: 180,
        createdAt: now,
        updatedAt: now,
        lastAcknowledgedUpdatedAt: now,
        canonicalRewardConfirmedAt: now,
      );
      Future<({String? city, String? date, int? count, bool pending})> home(
        String cityName,
        String zone, {
        bool confirmed = true,
      }) async {
        final preference = PrayerPreferences(
          accountId: owner,
          city: PrayerCity(
            provider: 'fixture',
            providerCityId: cityName,
            name: cityName,
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30,
            longitude: 31,
            timeZoneId: zone,
          ),
          calculationMethod: 'egyptian',
          revision: 1,
          updatedAt: now,
        );
        final context = PrayerContextService(
          preferences: _Preferences(preference),
          reports: _Reports(
            confirmed
                ? report
                : PrayerReport(
                    accountId: report.accountId,
                    reportId: report.reportId,
                    date: report.date,
                    name: report.name,
                    status: report.status,
                    reportedCompletionAt: report.reportedCompletionAt,
                    recordedZoneId: report.recordedZoneId,
                    recordedOffsetMinutes: report.recordedOffsetMinutes,
                    createdAt: report.createdAt,
                    updatedAt: report.updatedAt,
                  ),
          ),
          calculator: _Calculator(),
          clock: ZonedPrayerClock(now: () => now),
        );
        final value = await PrayerTodayAdapter(
          context,
        ).watchPrayer(owner).firstWhere((row) => row.reportsAvailable);
        return (
          city: value.city,
          date: value.localDate,
          count: value.completedCount,
          pending: value.unconfirmedReportIds.contains(report.reportId),
        );
      }

      final cairo = await home('Cairo', 'Africa/Cairo', confirmed: false);
      final london = await home('London', 'Europe/London');
      expect(cairo, (city: 'Cairo', date: date.value, count: 1, pending: true));
      expect(london, (
        city: 'London',
        date: date.value,
        count: 1,
        pending: false,
      ));
    },
  );
}
