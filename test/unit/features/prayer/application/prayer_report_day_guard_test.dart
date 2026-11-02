import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_report_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_report_identity_port.dart';
import 'package:namma_project/features/prayer/application/prayer_report_unit_of_work.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';

final _day = PrayerLocalDate.parse('2026-11-01');

class _Clock extends Fake implements PrayerClockPort {
  DateTime value = DateTime.utc(2026, 11, 1, 20);
  @override
  DateTime nowUtc() => value;
  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) =>
      PrayerLocalDate.parse(
        '${nowUtc.year.toString().padLeft(4, '0')}-'
        '${nowUtc.month.toString().padLeft(2, '0')}-'
        '${nowUtc.day.toString().padLeft(2, '0')}',
      );
  @override
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId) => 0;
}

class _Repo extends Fake implements PrayerRepository {
  _Repo(this.onRead);
  final void Function() onRead;
  @override
  Future<AppResult<PrayerReport?>> readFresh({
    required String accountId,
    required PrayerLocalDate date,
    required PrayerName prayerName,
  }) async {
    onRead();
    return const AppResult.success(null);
  }
}

class _Unit extends Fake implements PrayerReportUnitOfWork {
  PrayerReportCommit? value;
  @override
  Future<AppResult<void>> commit(PrayerReportCommit request) async {
    value = request;
    return const AppResult.success(null);
  }
}

class _Identity extends Fake implements PrayerReportIdentityPort {
  @override
  String reportId(PrayerLocalDate date, PrayerName name) => 'stable-report';
}

PrayerReportCommandContext _context(PrayerLocalDate date) =>
    PrayerReportCommandContext(
      localDate: date,
      timeZoneId: 'UTC',
      preferenceRevision: 1,
      scopeGeneration: 1,
    );

void main() {
  test('prior and future day submissions are rejected', () async {
    final clock = _Clock();
    for (final date in ['2026-10-31', '2026-11-02']) {
      final unit = _Unit();
      final command = PrayerReportCommands(
        ownerId: 'owner',
        repository: _Repo(() {}),
        unitOfWork: unit,
        identity: _Identity(),
        clock: clock,
        isCurrentScope: (_) => true,
        queueForSync: true,
      );
      final result = await command.setStatus(
        name: PrayerName.asr,
        status: PrayerStatus.completedOnTime,
        capturedContext: _context(PrayerLocalDate.parse(date)),
      );
      expect(result.failureOrNull?.messageKey, 'prayer.report.stale_context');
      expect(unit.value, isNull);
    }
  });

  test('an accepted action crossing midnight retains its captured identity', () async {
    final clock = _Clock();
    final unit = _Unit();
    final command = PrayerReportCommands(
      ownerId: 'owner',
      repository: _Repo(() => clock.value = DateTime.utc(2026, 11, 2)),
      unitOfWork: unit,
      identity: _Identity(),
      clock: clock,
      isCurrentScope: (_) => true,
      isCurrentOwnerContext: (_) => true,
      queueForSync: true,
    );
    final result = await command.setStatus(
      name: PrayerName.isha,
      status: PrayerStatus.missed,
      capturedContext: _context(_day),
    );
    expect(result.failureOrNull, isNull);
    expect(unit.value?.report.date, _day);
    expect(unit.value?.report.reportId, 'stable-report');
  });

  test('owner or preference replacement rejects before commit', () async {
    var current = true;
    final unit = _Unit();
    final command = PrayerReportCommands(
      ownerId: 'owner',
      repository: _Repo(() => current = false),
      unitOfWork: unit,
      identity: _Identity(),
      clock: _Clock(),
      isCurrentScope: (_) => true,
      isCurrentOwnerContext: (_) => current,
      queueForSync: true,
    );
    final result = await command.setStatus(
      name: PrayerName.fajr,
      status: PrayerStatus.completedLate,
      capturedContext: _context(_day),
    );
    expect(result.failureOrNull?.messageKey, 'prayer.report.stale_context');
    expect(unit.value, isNull);
  });
}
