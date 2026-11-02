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
final _context = PrayerReportCommandContext(
  localDate: _day,
  timeZoneId: 'Africa/Cairo',
  preferenceRevision: 3,
  scopeGeneration: 7,
);

PrayerReport _prior(PrayerStatus status) => PrayerReport(
  accountId: 'owner',
  reportId: 'report-id',
  date: _day,
  name: PrayerName.fajr,
  status: status,
  reportedCompletionAt: status.isCompleted ? DateTime.utc(2026, 11, 1, 5) : null,
  recordedZoneId: 'Africa/Cairo',
  recordedOffsetMinutes: 120,
  createdAt: DateTime.utc(2026, 11, 1, 4),
  updatedAt: DateTime.utc(2026, 11, 1, 4, 30),
);

class _Repo extends Fake implements PrayerRepository {
  PrayerReport? current;
  @override
  Future<AppResult<PrayerReport?>> readFresh({
    required String accountId,
    required PrayerLocalDate date,
    required PrayerName prayerName,
  }) async => AppResult.success(current);
}

class _Unit extends Fake implements PrayerReportUnitOfWork {
  final commits = <PrayerReportCommit>[];
  @override
  Future<AppResult<void>> commit(PrayerReportCommit request) async {
    commits.add(request);
    return const AppResult.success(null);
  }
}

class _Identity extends Fake implements PrayerReportIdentityPort {
  @override
  String reportId(PrayerLocalDate date, PrayerName name) => 'report-id';
}

class _Clock extends Fake implements PrayerClockPort {
  DateTime value = DateTime.utc(2026, 11, 1, 6);
  @override
  DateTime nowUtc() => value;
  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) => _day;
  @override
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId) => 120;
}

void main() {
  test('all sixteen existing-state transitions are explicit and idempotent', () async {
    for (final from in PrayerStatus.values) {
      for (final to in PrayerStatus.values) {
        final repo = _Repo()..current = _prior(from);
        final unit = _Unit();
        final command = PrayerReportCommands(
          ownerId: 'owner',
          repository: repo,
          unitOfWork: unit,
          identity: _Identity(),
          clock: _Clock(),
          isCurrentScope: (value) => value == _context,
          queueForSync: true,
          nextOperationId: () => 'operation-id',
        );
        final result = await command.setStatus(
          name: PrayerName.fajr,
          status: to,
          capturedContext: _context,
        );
        expect(result.failureOrNull, isNull, reason: '$from -> $to');
        if (from == to) {
          expect(unit.commits, isEmpty, reason: '$from -> $to');
          expect(result.valueOrNull?.status, from);
        } else {
          expect(unit.commits, hasLength(1), reason: '$from -> $to');
          expect(unit.commits.single.report.status, to);
          expect(
            unit.commits.single.report.updatedAt.isAfter(repo.current!.updatedAt),
            isTrue,
          );
        }
      }
    }
  });

  test('missing to pending is a no-op and completion XP is policy-owned', () async {
    final repo = _Repo();
    final unit = _Unit();
    final clock = _Clock();
    final command = PrayerReportCommands(
      ownerId: 'owner',
      repository: repo,
      unitOfWork: unit,
      identity: _Identity(),
      clock: clock,
      isCurrentScope: (_) => true,
      queueForSync: true,
      nextOperationId: () => 'operation-id',
    );
    expect(
      (await command.setStatus(
        name: PrayerName.fajr,
        status: PrayerStatus.pending,
        capturedContext: _context,
      )).failureOrNull,
      isNull,
    );
    expect(unit.commits, isEmpty);

    await command.setStatus(
      name: PrayerName.fajr,
      status: PrayerStatus.completedLate,
      capturedContext: _context,
    );
    expect(unit.commits.single.firstAward?.amount, 5);
    expect(unit.commits.single.firstAward?.source, 'prayer_done');
  });

  test('stale day and stale scope are rejected before persistence', () async {
    final repo = _Repo();
    final unit = _Unit();
    final clock = _Clock();
    final command = PrayerReportCommands(
      ownerId: 'owner',
      repository: repo,
      unitOfWork: unit,
      identity: _Identity(),
      clock: clock,
      isCurrentScope: (_) => false,
      queueForSync: true,
    );
    final result = await command.setStatus(
      name: PrayerName.fajr,
      status: PrayerStatus.completedOnTime,
      capturedContext: _context,
    );
    expect(result.failureOrNull?.messageKey, 'prayer.report.stale_context');
    expect(unit.commits, isEmpty);
  });
}
