import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport, XpAward;
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/prayer_remote_models.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

void main() {
  final date = PrayerLocalDate.parse('2026-10-29');
  final id = UuidPrayerReportIdentity().reportId(date, PrayerName.fajr);
  final start = DateTime.utc(2026, 10, 29, 5);
  PrayerReport report(PrayerStatus status, int seconds) => PrayerReport(
    accountId: 'owner-a',
    reportId: id,
    date: date,
    name: PrayerName.fajr,
    status: status,
    reportedCompletionAt: status.isCompleted
        ? start.add(Duration(seconds: seconds))
        : null,
    recordedZoneId: 'Africa/Cairo',
    recordedOffsetMinutes: 120,
    createdAt: start,
    updatedAt: start.add(Duration(seconds: seconds)),
  );

  test(
    'receipt settles award and report before outbox ACK, replay is safe',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 90),
      );
      try {
        final store = DriftPrayerRepository(db);
        final ledger = DriftAwardLedger(db);
        final first = report(PrayerStatus.completedOnTime, 1);
        final active = report(PrayerStatus.completedLate, 2);
        expect(
          (await store.writeLocal(
            first,
            operationId: 'op-1',
            acknowledgedBase: null,
            expectedCurrentVersion: null,
          )).failureOrNull,
          isNull,
        );
        expect(
          (await ledger.insertSharedOnce(
            XpAward(
              accountId: 'owner-a',
              source: kPrayerDoneAwardSource,
              sourceId: id,
              amount: 10,
              awardedAt: first.reportedCompletionAt!,
            ),
          )).failureOrNull,
          isNull,
        );
        final receipt = PrayerDispatchReceipt(
          operationId: 'op-1',
          active: active,
          conflict: PrayerRemoteConflict(
            id: 'conflict-1',
            active: active,
            retained: first,
            detectedAt: start.add(const Duration(seconds: 3)),
          ),
          award: XpAward(
            accountId: 'owner-a',
            source: kPrayerDoneAwardSource,
            sourceId: id,
            amount: 5,
            awardedAt: active.reportedCompletionAt!,
          ),
        );
        for (var i = 0; i < 2; i++) {
          expect(
            (await store.finalizeReceipt(
              accountId: 'owner-a',
              reportId: id,
              outboundVersion: first.updatedAt,
              receipt: receipt,
            )).failureOrNull,
            isNull,
          );
        }
        expect(
          (await store.readFresh(
            accountId: 'owner-a',
            date: date,
            prayerName: PrayerName.fajr,
          )).valueOrNull!.status,
          PrayerStatus.completedLate,
        );
        expect(
          (await ledger.readSharedAward(
            accountId: 'owner-a',
            source: kPrayerDoneAwardSource,
            sourceId: id,
          )).valueOrNull!.amount,
          5,
        );
        expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);
        expect(
          await db.rawScalar(
            'SELECT count(*) FROM pending_changes WHERE state = 0',
          ),
          1,
        );
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test('old receipt cannot replace a newer local descendant', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 40),
    );
    try {
      final store = DriftPrayerRepository(db);
      final first = report(PrayerStatus.completedLate, 1);
      final second = report(PrayerStatus.missed, 3);
      expect(
        (await store.writeLocal(
          first,
          operationId: 'op-1',
          acknowledgedBase: null,
          expectedCurrentVersion: null,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await store.writeLocal(
          second,
          operationId: 'op-2',
          acknowledgedBase: null,
          expectedCurrentVersion: first.updatedAt,
        )).failureOrNull,
        isNull,
      );
      final receipt = PrayerDispatchReceipt(
        operationId: 'op-1',
        active: first,
        conflict: null,
        award: null,
      );
      expect(
        (await store.finalizeReceipt(
          accountId: 'owner-a',
          reportId: id,
          outboundVersion: first.updatedAt,
          receipt: receipt,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await store.readFresh(
          accountId: 'owner-a',
          date: date,
          prayerName: PrayerName.fajr,
        )).valueOrNull!.status,
        PrayerStatus.missed,
      );
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  test('failed receipt rolls back canonical award and settlement', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 120),
    );
    try {
      final store = DriftPrayerRepository(db);
      final first = report(PrayerStatus.completedLate, 1);
      expect(
        (await store.writeLocal(
          first,
          operationId: 'rollback-op',
          acknowledgedBase: null,
          expectedCurrentVersion: null,
        )).failureOrNull,
        isNull,
      );
      final remote = report(PrayerStatus.completedOnTime, 2);
      final invalidRetained = PrayerReport(
        accountId: 'other-owner',
        reportId: id,
        date: date,
        name: PrayerName.fajr,
        status: first.status,
        reportedCompletionAt: first.reportedCompletionAt,
        recordedZoneId: first.recordedZoneId,
        recordedOffsetMinutes: first.recordedOffsetMinutes,
        createdAt: first.createdAt,
        updatedAt: first.updatedAt,
      );
      final outcome = await store.finalizeReceipt(
        accountId: 'owner-a',
        reportId: id,
        outboundVersion: first.updatedAt,
        receipt: PrayerDispatchReceipt(
          operationId: 'rollback-op',
          active: remote,
          conflict: PrayerRemoteConflict(
            id: 'bad-conflict',
            active: remote,
            retained: invalidRetained,
            detectedAt: start,
          ),
          award: XpAward(
            accountId: 'owner-a',
            source: kPrayerDoneAwardSource,
            sourceId: id,
            amount: 5,
            awardedAt: start,
          ),
        ),
      );
      expect(outcome.failureOrNull, isNotNull);
      expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 0);
      expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 0);
      expect(
        (await store.readFresh(
          accountId: 'owner-a',
          date: date,
          prayerName: PrayerName.fajr,
        )).valueOrNull!.status,
        PrayerStatus.completedLate,
      );
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM pending_changes WHERE state = 0',
        ),
        1,
      );
    } finally {
      await db.close();
      temp.dispose();
    }
  });
}
