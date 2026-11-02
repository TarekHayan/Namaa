import 'dart:async';

import '../domain/prayer_day_snapshot.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_preferences.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_schedule_projection.dart';
import 'prayer_annual_schedule_port.dart';
import 'prayer_clock_port.dart';
import 'prayer_preferences_port.dart';
import 'prayer_repository.dart';
import 'prayer_schedule_calculator_port.dart';

/// One owner-scoped read model shared by Prayer and Today consumers.
final class PrayerContextService {
  PrayerContextService({
    required PrayerPreferencesPort preferences,
    required PrayerRepository reports,
    required PrayerScheduleCalculatorPort calculator,
    required PrayerClockPort clock,
    PrayerAnnualSchedulePort? annualSchedules,
    Duration tick = const Duration(seconds: 1),
  }) : _preferences = preferences,
       _reports = reports,
       _calculator = calculator,
       _annualSchedules = annualSchedules,
       _clock = clock,
       _tick = tick;

  final PrayerPreferencesPort _preferences;
  final PrayerRepository _reports;
  final PrayerScheduleCalculatorPort _calculator;
  final PrayerAnnualSchedulePort? _annualSchedules;
  final PrayerClockPort _clock;
  final Duration _tick;

  Stream<PrayerDaySnapshot> watch(String ownerId) {
    late StreamController<PrayerDaySnapshot> controller;
    StreamSubscription<PrayerPreferences?>? preferenceSub;
    StreamSubscription<List<PrayerReport>>? reportSub;
    Timer? timer;
    PrayerPreferences? active;
    PrayerLocalDate? date;
    PrayerSchedule? today;
    PrayerSchedule? tomorrow;
    List<PrayerReport> reports = const [];
    var reportsAvailable = false;
    var preferencesFailed = false;
    var generation = 0;
    DateTime? lastAnnualAttemptUtc;

    void emit() {
      if (controller.isClosed) return;
      final now = _clock.nowUtc();
      final health = preferencesFailed
          ? PrayerSnapshotHealth.unavailable
          : active == null
          ? PrayerSnapshotHealth.setupRequired
          : today == null || tomorrow == null
          ? PrayerSnapshotHealth.unavailable
          : today!.times.values.any((time) => time.instantUtc == null)
          ? PrayerSnapshotHealth.partial
          : PrayerSnapshotHealth.available;
      controller.add(
        PrayerDaySnapshot(
          ownerId: ownerId,
          health: health,
          nowUtc: now,
          preferences: active,
          localDate: date,
          schedule: today,
          tomorrow: tomorrow,
          reports: reports,
          reportsAvailable: reportsAvailable,
          projection: today != null && tomorrow != null
              ? PrayerScheduleProjection.from(
                  today: today!,
                  tomorrow: tomorrow!,
                  nowUtc: now,
                )
              : null,
        ),
      );
    }

    Future<void> recalculate(
      PrayerPreferences pref,
      PrayerLocalDate nextDate,
      int expectedGeneration,
    ) async {
      final carrier = DateTime.parse('${nextDate.value}T00:00:00Z');
      final next = carrier.add(const Duration(days: 1));
      final nextDay = PrayerLocalDate.parse(
        '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}',
      );
      PrayerSchedule? forLocal(PrayerLocalDate day) => _calculator
          .calculate(preferences: pref, date: day)
          .valueOrNull
          ?.copyWith(
            provenance: 'Local calculation · ${pref.calculationMethod}',
          );
      PrayerSchedule? resolvedToday = forLocal(nextDate);
      PrayerSchedule? resolvedTomorrow = forLocal(nextDay);
      if (expectedGeneration == generation && !controller.isClosed) {
        today = resolvedToday;
        tomorrow = resolvedTomorrow;
        emit();
      }
      final annual = _annualSchedules;
      if (annual == null) return;
      lastAnnualAttemptUtc = _clock.nowUtc();
      try {
        final fetched = await Future.wait([
          annual.forDate(preferences: pref, date: nextDate),
          annual.forDate(preferences: pref, date: nextDay),
        ]);
        resolvedToday = fetched[0] ?? resolvedToday;
        resolvedTomorrow = fetched[1] ?? resolvedTomorrow;
      } catch (_) {
        // Keep the already emitted local schedule if the provider fails.
      }
      if (expectedGeneration != generation || controller.isClosed) return;
      today = resolvedToday;
      tomorrow = resolvedTomorrow;
      emit();
    }

    void updatePreference(PrayerPreferences? pref) {
      if (controller.isClosed) return;
      ++generation;
      reportSub?.cancel();
      reportSub = null;
      active = pref;
      reports = const [];
      reportsAvailable = false;
      today = null;
      tomorrow = null;
      date = null;
      if (pref != null) {
        date = _clock.cityDate(_clock.nowUtc(), pref.city.timeZoneId);
        unawaited(recalculate(pref, date!, generation));
        final expected = generation;
        reportSub = _reports
            .watchDay(accountId: ownerId, date: date!)
            .listen(
              (rows) {
                if (expected != generation || controller.isClosed) return;
                if (rows.any(
                  (row) => row.accountId != ownerId || row.date != date,
                )) {
                  reports = const [];
                  reportsAvailable = false;
                  emit();
                  return;
                }
                reports = List.unmodifiable(rows);
                reportsAvailable = true;
                emit();
              },
              onError: (_, _) {
                if (expected != generation || controller.isClosed) return;
                reportsAvailable = false;
                emit();
              },
            );
      }
      emit();
    }

    controller = StreamController<PrayerDaySnapshot>(
      onListen: () {
        preferenceSub = _preferences
            .watch(ownerId)
            .listen(
              (pref) {
                if (pref != null && pref.accountId != ownerId) {
                  preferencesFailed = true;
                  updatePreference(null);
                  return;
                }
                try {
                  preferencesFailed = false;
                  updatePreference(pref);
                } catch (_) {
                  preferencesFailed = true;
                  updatePreference(null);
                }
              },
              onError: (_, _) {
                preferencesFailed = true;
                updatePreference(null);
              },
            );
        timer = Timer.periodic(_tick, (_) {
          final pref = active;
          if (pref != null) {
            try {
              final fresh = _clock.cityDate(
                _clock.nowUtc(),
                pref.city.timeZoneId,
              );
              if (fresh != date) {
                updatePreference(pref);
                return;
              }
              final attempted = lastAnnualAttemptUtc;
              if (_annualSchedules != null &&
                  today?.provenance.startsWith('Local calculation') == true &&
                  attempted != null &&
                  _clock.nowUtc().difference(attempted) >=
                      const Duration(minutes: 1)) {
                unawaited(recalculate(pref, fresh, generation));
              }
            } catch (_) {
              preferencesFailed = true;
              updatePreference(null);
              return;
            }
          }
          emit();
        });
      },
      onCancel: () async {
        timer?.cancel();
        ++generation;
        await preferenceSub?.cancel();
        await reportSub?.cancel();
      },
    );
    return controller.stream;
  }
}
