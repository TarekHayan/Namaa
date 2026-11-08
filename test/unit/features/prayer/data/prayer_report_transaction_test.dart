import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport, XpAward;
import 'package:namma_project/core/data/local/prayer_report_unit_of_work.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_report_unit_of_work.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

final _day = PrayerLocalDate.parse('2026-11-01');

PrayerReport _report(
  PrayerStatus status,
  DateTime updatedAt, {
  DateTime? createdAt,
  DateTime? acknowledgedAt,
  PrayerName name = PrayerName.fajr,
  String reportId = 'report-id',
}) => PrayerReport(
  accountId: 'owner',
  reportId: reportId,
  date: _day,
  name: name,
  status: status,
  reportedCompletionAt: status.isCompleted
      ? DateTime.utc(2026, 11, 1, 5)
      : null,
  recordedZoneId: 'Africa/Cairo',
  recordedOffsetMinutes: 120,
  createdAt: createdAt ?? updatedAt,
  updatedAt: updatedAt,
  lastAcknowledgedUpdatedAt: acknowledgedAt,
);

XpAward _award(int amount, {String sourceId = 'report-id'}) => XpAward(
  accountId: 'owner',
  source: kPrayerDoneAwardSource,
  sourceId: sourceId,
  amount: amount,
  awardedAt: DateTime.utc(2026, 11, 1, 5),
);

class _FailingReports extends Fake implements PrayerRepository {
  @override
  Future<AppResult<void>> writeLocal(
    PrayerReport report, {
    required String operationId,
    required DateTime? acknowledgedBase,
    required DateTime? expectedCurrentVersion,
    bool queueForSync = true,
  }) async => AppResult.failure(
    AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'injected',
      occurredAt: report.updatedAt,
    ),
  );
}

void main() {
  test(
    'report, first reward and immutable operations commit atomically',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 11),
      );
      try {
        final reports = DriftPrayerRepository(db);
        final awards = DriftAwardLedger(db);
        final unit = DriftPrayerReportUnitOfWork(
          database: db,
          reports: reports,
          awards: awards,
        );
        final firstAt = DateTime.utc(2026, 11, 1, 5);
        final first = _report(PrayerStatus.completedLate, firstAt);
        expect(
          (await unit.commit(
            PrayerReportCommit(
              report: first,
              firstAward: _award(5),
              operationId: 'op-late',
              expectedCurrentVersion: null,
              acknowledgedBase: null,
              queueForSync: true,
            ),
          )).failureOrNull,
          isNull,
        );

        final correction = _report(
          PrayerStatus.completedOnTime,
          firstAt.add(const Duration(microseconds: 1)),
          createdAt: firstAt,
        );
        expect(
          (await unit.commit(
            PrayerReportCommit(
              report: correction,
              firstAward: _award(10),
              operationId: 'op-correct',
              expectedCurrentVersion: first.updatedAt,
              acknowledgedBase: null,
              queueForSync: true,
            ),
          )).failureOrNull,
          isNull,
        );

        final reset = _report(
          PrayerStatus.pending,
          correction.updatedAt.add(const Duration(microseconds: 1)),
          createdAt: firstAt,
        );
        expect(
          (await unit.commit(
            PrayerReportCommit(
              report: reset,
              operationId: 'op-reset',
              expectedCurrentVersion: correction.updatedAt,
              acknowledgedBase: null,
              queueForSync: true,
            ),
          )).failureOrNull,
          isNull,
        );

        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 3);
        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 1);
        expect(await db.rawScalar('SELECT amount FROM xp_awards'), 5);
        expect(
          (await reports.readFresh(
            accountId: 'owner',
            date: _day,
            prayerName: PrayerName.fajr,
          )).valueOrNull?.status,
          PrayerStatus.pending,
        );
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test(
    'a report failure rolls back an award inserted earlier in the unit',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 22),
      );
      try {
        final unit = DriftPrayerReportUnitOfWork(
          database: db,
          reports: _FailingReports(),
          awards: DriftAwardLedger(db),
        );
        final report = _report(
          PrayerStatus.completedOnTime,
          DateTime.utc(2026, 11, 1, 5),
        );
        final result = await unit.commit(
          PrayerReportCommit(
            report: report,
            firstAward: _award(10),
            operationId: 'failure',
            expectedCurrentVersion: null,
            acknowledgedBase: null,
            queueForSync: true,
          ),
        );
        expect(result.failureOrNull, isNotNull);
        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 0);
        expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 0);
        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test(
    'preview persists report and reward without adding cloud outbox work',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 33),
      );
      try {
        final reports = DriftPrayerRepository(db);
        final unit = DriftPrayerReportUnitOfWork(
          database: db,
          reports: reports,
          awards: DriftAwardLedger(db),
        );
        final report = _report(
          PrayerStatus.completedOnTime,
          DateTime.utc(2026, 11, 1, 5),
        );
        await unit.commit(
          PrayerReportCommit(
            report: report,
            firstAward: _award(10),
            operationId: 'preview',
            expectedCurrentVersion: null,
            acknowledgedBase: null,
            queueForSync: false,
          ),
        );
        expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 1);
        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 1);
        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test(
    'an on-time first reward stays ten after late correction and reset',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 44),
      );
      try {
        final reports = DriftPrayerRepository(db);
        final unit = DriftPrayerReportUnitOfWork(
          database: db,
          reports: reports,
          awards: DriftAwardLedger(db),
        );
        final firstAt = DateTime.utc(2026, 11, 1, 12);
        final first = _report(
          PrayerStatus.completedOnTime,
          firstAt,
          name: PrayerName.dhuhr,
          reportId: 'report-dhuhr',
        );
        await unit.commit(
          PrayerReportCommit(
            report: first,
            firstAward: _award(10, sourceId: 'report-dhuhr'),
            operationId: 'on-time',
            expectedCurrentVersion: null,
            acknowledgedBase: null,
            queueForSync: true,
          ),
        );
        final late = _report(
          PrayerStatus.completedLate,
          firstAt.add(const Duration(microseconds: 1)),
          createdAt: firstAt,
          name: PrayerName.dhuhr,
          reportId: 'report-dhuhr',
        );
        await unit.commit(
          PrayerReportCommit(
            report: late,
            firstAward: _award(5, sourceId: 'report-dhuhr'),
            operationId: 'late',
            expectedCurrentVersion: first.updatedAt,
            acknowledgedBase: null,
            queueForSync: true,
          ),
        );
        final reset = _report(
          PrayerStatus.pending,
          late.updatedAt.add(const Duration(microseconds: 1)),
          createdAt: firstAt,
          name: PrayerName.dhuhr,
          reportId: 'report-dhuhr',
        );
        await unit.commit(
          PrayerReportCommit(
            report: reset,
            operationId: 'reset-dhuhr',
            expectedCurrentVersion: late.updatedAt,
            acknowledgedBase: null,
            queueForSync: true,
          ),
        );

        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 1);
        expect(await db.rawScalar('SELECT amount FROM xp_awards'), 10);
        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 3);
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test(
    'stale concurrent write cannot replace fresh state or its sync base',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 55),
      );
      try {
        final reports = DriftPrayerRepository(db);
        final remoteAt = DateTime.utc(2026, 11, 1, 12);
        final remote = _report(
          PrayerStatus.missed,
          remoteAt,
          acknowledgedAt: remoteAt,
          name: PrayerName.asr,
          reportId: 'report-asr',
        );
        expect((await reports.applyInbound(remote)).failureOrNull, isNull);

        final firstLocal = _report(
          PrayerStatus.completedLate,
          remoteAt.add(const Duration(microseconds: 1)),
          createdAt: remote.createdAt,
          acknowledgedAt: remoteAt,
          name: PrayerName.asr,
          reportId: 'report-asr',
        );
        expect(
          (await reports.writeLocal(
            firstLocal,
            operationId: 'local-1',
            acknowledgedBase: remoteAt,
            expectedCurrentVersion: remoteAt,
          )).failureOrNull,
          isNull,
        );
        final secondLocal = _report(
          PrayerStatus.completedOnTime,
          firstLocal.updatedAt.add(const Duration(microseconds: 1)),
          createdAt: remote.createdAt,
          acknowledgedAt: remoteAt,
          name: PrayerName.asr,
          reportId: 'report-asr',
        );
        expect(
          (await reports.writeLocal(
            secondLocal,
            operationId: 'local-2',
            acknowledgedBase: remoteAt,
            expectedCurrentVersion: firstLocal.updatedAt,
          )).failureOrNull,
          isNull,
        );

        final stale = _report(
          PrayerStatus.pending,
          secondLocal.updatedAt.add(const Duration(microseconds: 1)),
          createdAt: remote.createdAt,
          acknowledgedAt: remoteAt,
          name: PrayerName.asr,
          reportId: 'report-asr',
        );
        expect(
          (await reports.writeLocal(
            stale,
            operationId: 'stale',
            acknowledgedBase: remoteAt,
            expectedCurrentVersion: remoteAt,
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await reports.readFresh(
            accountId: 'owner',
            date: _day,
            prayerName: PrayerName.asr,
          )).valueOrNull,
          secondLocal,
        );
        final pending = await db.select(db.pendingChanges).get();
        expect(pending, hasLength(2));
        expect(pending.map((row) => row.baseUpdatedAt).toSet(), {remoteAt});
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );
}
