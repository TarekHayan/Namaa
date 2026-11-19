/// Pure resolution of the Adhkar day and period (research.md R3).
///
/// The Adhkar day is the civil date of the Fajr that opened it, in the
/// location's zone. Morning runs Fajr->Maghrib and Evening runs
/// Maghrib->next Fajr. Without a usable schedule the period is unrestricted
/// and the day is the device's calendar day (FR-006a); when a saved schedule
/// cannot produce its instants the state is unavailable: the lists stay
/// visible but counting is locked, and there is never a fallback to calendar
/// days (owner decision, 2026-11-10).
///
/// The caller asks for the boundaries of the day whose Fajr opened the
/// current period — the previous day before Fajr, the city's day otherwise
/// (the composition adapter owns that choice, T028).
library;

/// The two fixed lists; `unrestricted` is the no-schedule period.
enum AdhkarPeriod { morning, evening, unrestricted }

/// Availability of the Prayer schedule behind the Adhkar times.
enum AdhkarScheduleState { available, setupRequired, unavailable }

/// The boundaries of one Adhkar day, prepared by the composition adapter:
/// [fajrDay] is the civil date of [fajrUtc] in the location's zone and is
/// the Adhkar day the counts belong to.
final class AdhkarDayBoundaries {
  AdhkarDayBoundaries({
    required this.fajrUtc,
    required this.maghribUtc,
    required this.nextFajrUtc,
    required this.fajrDay,
    required this.zoneId,
  }) {
    if (!fajrUtc.isUtc ||
        !maghribUtc.isUtc ||
        !nextFajrUtc.isUtc ||
        !fajrUtc.isBefore(maghribUtc) ||
        !maghribUtc.isBefore(nextFajrUtc)) {
      throw ArgumentError('Invalid Adhkar day boundaries');
    }
  }

  final DateTime fajrUtc;
  final DateTime maghribUtc;
  final DateTime nextFajrUtc;
  final String fajrDay;

  /// The location's IANA zone (for the notice time formatting).
  final String zoneId;
}

/// The schedule input for one resolution: the boundaries of the day whose
/// Fajr opened the current period, the no-schedule case with the device's
/// calendar day, or an unavailable schedule.
sealed class AdhkarScheduleInput {
  const AdhkarScheduleInput();
}

final class AdhkarScheduledDay extends AdhkarScheduleInput {
  const AdhkarScheduledDay({required this.boundaries});

  final AdhkarDayBoundaries boundaries;
}

final class AdhkarNoSchedule extends AdhkarScheduleInput {
  const AdhkarNoSchedule({required this.deviceDay});

  final String deviceDay;
}

final class AdhkarScheduleUnavailable extends AdhkarScheduleInput {
  const AdhkarScheduleUnavailable();
}

/// The resolved Adhkar clock (data-model.md): the Adhkar day, the period,
/// the next boundary instant, and whether the schedule is available.
///
/// [day] and [period] are null only in the unavailable state, where no
/// counts may be attributed to any day.
final class AdhkarClockState {
  const AdhkarClockState({
    required this.scheduleState,
    required this.day,
    required this.period,
    required this.nextBoundaryUtc,
    required this.morningCountable,
    required this.eveningCountable,
    required this.fajrUtc,
    required this.maghribUtc,
    required this.zoneId,
  });

  final AdhkarScheduleState scheduleState;

  /// The Adhkar day (civil `YYYY-MM-DD` of the opening Fajr), or the device
  /// calendar day when unrestricted; null only when unavailable.
  final String? day;
  final AdhkarPeriod? period;
  final DateTime? nextBoundaryUtc;

  /// Countability per list: with a schedule only the current period counts;
  /// unrestricted counts both; unavailable counts neither.
  final bool morningCountable;
  final bool eveningCountable;

  /// The instants behind the read-only notices ("its time starts at ...");
  /// null when unavailable.
  final DateTime? fajrUtc;
  final DateTime? maghribUtc;

  /// The location's IANA zone; null when unavailable.
  final String? zoneId;
}

final class AdhkarClock {
  const AdhkarClock();

  static AdhkarClockState resolve({
    required DateTime nowUtc,
    required AdhkarScheduleInput input,
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc');
    }
    final scheduleInput = input;
    if (scheduleInput is AdhkarNoSchedule) {
      return AdhkarClockState(
        scheduleState: AdhkarScheduleState.setupRequired,
        day: scheduleInput.deviceDay,
        period: AdhkarPeriod.unrestricted,
        nextBoundaryUtc: null,
        morningCountable: true,
        eveningCountable: true,
        fajrUtc: null,
        maghribUtc: null,
        zoneId: null,
      );
    }
    if (scheduleInput is AdhkarScheduleUnavailable) {
      return const AdhkarClockState(
        scheduleState: AdhkarScheduleState.unavailable,
        day: null,
        period: null,
        nextBoundaryUtc: null,
        morningCountable: false,
        eveningCountable: false,
        fajrUtc: null,
        maghribUtc: null,
        zoneId: null,
      );
    }
    final scheduled = scheduleInput as AdhkarScheduledDay;
    final boundaries = scheduled.boundaries;
    if (!nowUtc.isBefore(boundaries.nextFajrUtc)) {
      // The caller must ask for the day whose Fajr opened the running
      // period; a lapsed day is a composition bug, not a clock decision.
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'outside the requested Adhkar day window',
      );
    }
    final isMorning = nowUtc.isBefore(boundaries.maghribUtc);
    return AdhkarClockState(
      scheduleState: AdhkarScheduleState.available,
      day: boundaries.fajrDay,
      period: isMorning ? AdhkarPeriod.morning : AdhkarPeriod.evening,
      nextBoundaryUtc: isMorning
          ? boundaries.maghribUtc
          : boundaries.nextFajrUtc,
      morningCountable: isMorning,
      eveningCountable: !isMorning,
      fajrUtc: boundaries.fajrUtc,
      maghribUtc: boundaries.maghribUtc,
      zoneId: boundaries.zoneId,
    );
  }
}
