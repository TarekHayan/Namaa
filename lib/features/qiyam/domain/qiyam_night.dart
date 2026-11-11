/// Pure resolution of the Qiyam night (research.md R4).
///
/// Night D starts at Maghrib on date D (from the location's Prayer schedule)
/// and runs until Maghrib on D+1; a record belongs to the most recent night
/// that has started, and only that night is editable (FR-011, FR-011a).
/// Recording last night therefore stays possible until the next Maghrib, so
/// the night window extends past its Fajr. The caller asks for the
/// boundaries of the night in progress — the previous city day before the
/// running Maghrib, the city day from the Maghrib on (the composition
/// adapter owns that choice, T043).
///
/// Without a saved location the night follows the device's 12:00 rule:
/// before 12:00 local time the record belongs to the previous date's night,
/// from 12:00 on to the current date's night. When a saved schedule cannot
/// produce its instants the state is unavailable: the screen stays visible
/// but recording is locked, and there is never a fallback to calendar or
/// noon rules (owner decision, 2026-11-10).
library;

/// Availability of the Prayer schedule behind the Qiyam night.
enum QiyamScheduleState { available, setupRequired, unavailable }

/// The boundaries of one Qiyam night, prepared by the composition adapter:
/// [maghribUtc] opens night [nightDay] and [nextFajrUtc] is the night's last
/// Fajr; [lastThirdUtc] is the night's last third as computed by the shared
/// Prayer projection (SC-005).
final class QiyamNightBoundaries {
  QiyamNightBoundaries({
    required this.maghribUtc,
    required this.nextFajrUtc,
    required this.lastThirdUtc,
    required this.nightDay,
    required this.zoneId,
  }) {
    if (!maghribUtc.isUtc ||
        !nextFajrUtc.isUtc ||
        (lastThirdUtc != null && !lastThirdUtc!.isUtc) ||
        !maghribUtc.isBefore(nextFajrUtc) ||
        lastThirdUtc != null &&
            (!maghribUtc.isBefore(lastThirdUtc!) ||
                !lastThirdUtc!.isBefore(nextFajrUtc))) {
      throw ArgumentError('Invalid Qiyam night boundaries');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(nightDay) ||
        zoneId.trim().isEmpty) {
      throw ArgumentError('Invalid Qiyam night boundaries');
    }
  }

  /// The instant that opens night [nightDay].
  final DateTime maghribUtc;

  /// The night's last Fajr (the next date's Fajr in the location's zone).
  final DateTime nextFajrUtc;

  /// The start of the night's last third; null only when the caller could
  /// not compute it (which the adapter reports as unavailable instead).
  final DateTime? lastThirdUtc;

  /// The night's civil date `YYYY-MM-DD`: night D starts at Maghrib on D.
  final String nightDay;

  /// The location's IANA zone (for the last-third display).
  final String zoneId;
}

/// The schedule input for one resolution: the boundaries of the night in
/// progress, the no-schedule case with the device's local wall clock, or an
/// unavailable schedule.
sealed class QiyamNightInput {
  const QiyamNightInput();
}

final class QiyamScheduledNight extends QiyamNightInput {
  const QiyamScheduledNight({
    required this.boundaries,
    required this.zoneOffsetMinutes,
    this.nextMaghribUtc,
  });

  final QiyamNightBoundaries boundaries;

  /// The location zone's offset at the sampled instant, captured for the
  /// record's provenance fields.
  final int zoneOffsetMinutes;

  /// Maghrib(D+1) when the caller knows it: the night's end and the next
  /// refresh instant. Null when the next day's schedule is unavailable; the
  /// upper bound is then unchecked and the refresh falls back to resume.
  final DateTime? nextMaghribUtc;
}

final class QiyamNoSchedule extends QiyamNightInput {
  QiyamNoSchedule({
    required this.deviceLocal,
    required this.zoneId,
    required this.zoneOffsetMinutes,
  }) {
    if (deviceLocal.isUtc) {
      throw ArgumentError.value(deviceLocal, 'deviceLocal');
    }
    if (zoneId.trim().isEmpty || zoneOffsetMinutes.abs() > 1080) {
      throw ArgumentError('Invalid Qiyam no-schedule context');
    }
  }

  /// The device's local wall clock (`isUtc == false`) at the sampled instant.
  final DateTime deviceLocal;

  /// The device zone context captured for the record's provenance fields.
  final String zoneId;
  final int zoneOffsetMinutes;
}

final class QiyamScheduleUnavailable extends QiyamNightInput {
  const QiyamScheduleUnavailable();
}

/// The resolved Qiyam night (data-model.md): the night date, the last-third
/// instant, whether the night is editable, the next refresh instant, and the
/// zone context captured at resolution.
///
/// [nightDate] is null only in the unavailable state, where no record may be
/// attributed to any night and recording is locked.
final class QiyamNightState {
  const QiyamNightState({
    required this.scheduleState,
    required this.nightDate,
    required this.lastThirdUtc,
    required this.editable,
    required this.nextBoundaryUtc,
    required this.zoneId,
    required this.zoneOffsetMinutes,
  });

  final QiyamScheduleState scheduleState;

  /// The current night (civil `YYYY-MM-DD`); null only when unavailable.
  final String? nightDate;

  /// The start of the night's last third; null when the schedule cannot
  /// produce it (setupRequired or unavailable).
  final DateTime? lastThirdUtc;

  /// Only the current night is editable; unavailable locks recording.
  final bool editable;

  /// The next instant that changes the night (the next Maghrib, or the next
  /// local 12:00 without a schedule); null when unknown.
  final DateTime? nextBoundaryUtc;

  /// The zone context captured with the resolution (the location's zone with
  /// a schedule, the device zone without one); null when unavailable.
  final String? zoneId;
  final int? zoneOffsetMinutes;

  /// Whether the screen can show a computed last-third time (FR-008).
  bool get lastThirdAvailable => lastThirdUtc != null;
}

final class QiyamNight {
  const QiyamNight();

  static const int _noonMinutes = 12 * 60;

  static QiyamNightState resolve({
    required DateTime nowUtc,
    required QiyamNightInput input,
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc');
    }
    final scheduleInput = input;
    if (scheduleInput is QiyamNoSchedule) {
      return _noSchedule(scheduleInput);
    }
    if (scheduleInput is QiyamScheduleUnavailable) {
      return const QiyamNightState(
        scheduleState: QiyamScheduleState.unavailable,
        nightDate: null,
        lastThirdUtc: null,
        editable: false,
        nextBoundaryUtc: null,
        zoneId: null,
        zoneOffsetMinutes: null,
      );
    }
    final scheduled = scheduleInput as QiyamScheduledNight;
    final boundaries = scheduled.boundaries;
    // The night must have started (the adapter guarantees the most recent
    // started night) and must not have ended when the next Maghrib is known;
    // a violation is a composition bug, not a clock decision.
    if (nowUtc.isBefore(boundaries.maghribUtc) ||
        (scheduled.nextMaghribUtc != null &&
            !nowUtc.isBefore(scheduled.nextMaghribUtc!))) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'outside the requested Qiyam night window',
      );
    }
    return QiyamNightState(
      scheduleState: QiyamScheduleState.available,
      nightDate: boundaries.nightDay,
      lastThirdUtc: boundaries.lastThirdUtc,
      editable: true,
      nextBoundaryUtc: scheduled.nextMaghribUtc,
      zoneId: boundaries.zoneId,
      zoneOffsetMinutes: scheduled.zoneOffsetMinutes,
    );
  }

  static QiyamNightState _noSchedule(QiyamNoSchedule input) {
    final local = input.deviceLocal;
    final minutesOfDay = local.hour * 60 + local.minute;
    // Calendar arithmetic, not a 24-hour subtraction: the day before a
    // daylight-saving change can be 23 or 25 hours long.
    final nightCarrier = minutesOfDay < _noonMinutes
        ? DateTime(local.year, local.month, local.day - 1)
        : DateTime(local.year, local.month, local.day);
    return QiyamNightState(
      scheduleState: QiyamScheduleState.setupRequired,
      nightDate: _dayKey(nightCarrier),
      lastThirdUtc: null,
      editable: true,
      nextBoundaryUtc: minutesOfDay < _noonMinutes
          ? DateTime(local.year, local.month, local.day, 12).toUtc()
          : DateTime(local.year, local.month, local.day + 1, 12).toUtc(),
      zoneId: input.zoneId,
      zoneOffsetMinutes: input.zoneOffsetMinutes,
    );
  }

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
