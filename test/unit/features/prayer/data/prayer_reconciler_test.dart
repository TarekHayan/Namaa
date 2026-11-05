import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport, XpAward;
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/prayer_reconciler.dart';
import 'package:namma_project/features/prayer/data/supabase_prayer_reader.dart';
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
  PrayerReport report(PrayerStatus status, int second) => PrayerReport(
    accountId: 'owner-a',
    reportId: id,
    date: date,
    name: PrayerName.fajr,
    status: status,
    reportedCompletionAt: status.isCompleted
        ? start.add(Duration(seconds: second))
        : null,
    recordedZoneId: 'Africa/Cairo',
    recordedOffsetMinutes: 120,
    createdAt: start,
    updatedAt: start.add(Duration(seconds: second)),
  );

  test(
    'uncontested remote update and canonical award import without conflict',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 50),
      );
      try {
        final store = DriftPrayerRepository(db);
        final reconciler = PrayerReconciler(
          repository: store,
          localStore: DriftLocalStore(db),
          awards: DriftAwardLedger(db),
        );
        final remote = report(PrayerStatus.completedLate, 2);
        final snapshot = PrayerRemoteSnapshot(
          reports: [remote],
          awards: [
            XpAward(
              accountId: 'owner-a',
              source: kPrayerDoneAwardSource,
              sourceId: id,
              amount: 5,
              awardedAt: remote.reportedCompletionAt!,
            ),
          ],
          conflicts: const [],
        );
        for (var i = 0; i < 2; i++) {
          expect(
            (await reconciler.reconcile(
              accountId: 'owner-a',
              remote: snapshot,
            )).failureOrNull,
            isNull,
          );
        }
        expect(
          (await store.readFresh(
            accountId: 'owner-a',
            date: date,
            prayerName: PrayerName.fajr,
          )).valueOrNull!.lastAcknowledgedUpdatedAt,
          remote.updatedAt,
        );
        expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 0);
        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 1);
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test('pending local edit survives older remote snapshot', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 70),
    );
    try {
      final store = DriftPrayerRepository(db);
      final base = report(PrayerStatus.pending, 1);
      final local = report(PrayerStatus.completedOnTime, 3);
      expect(
        (await store.applyInbound(
          PrayerReport(
            accountId: base.accountId,
            reportId: base.reportId,
            date: base.date,
            name: base.name,
            status: base.status,
            recordedZoneId: base.recordedZoneId,
            recordedOffsetMinutes: base.recordedOffsetMinutes,
            createdAt: base.createdAt,
            updatedAt: base.updatedAt,
            lastAcknowledgedUpdatedAt: base.updatedAt,
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await store.writeLocal(
          local,
          operationId: 'pending-op',
          acknowledgedBase: base.updatedAt,
          expectedCurrentVersion: base.updatedAt,
        )).failureOrNull,
        isNull,
      );
      final reconciler = PrayerReconciler(
        repository: store,
        localStore: DriftLocalStore(db),
        awards: DriftAwardLedger(db),
      );
      expect(
        (await reconciler.reconcile(
          accountId: 'owner-a',
          remote: PrayerRemoteSnapshot(
            reports: [base],
            awards: const [],
            conflicts: const [],
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await store.readFresh(
          accountId: 'owner-a',
          date: date,
          prayerName: PrayerName.fajr,
        )).valueOrNull!.status,
        PrayerStatus.completedOnTime,
      );
      expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 0);
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  test('stale page cannot roll back a newer acknowledged receipt', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 110),
    );
    try {
      final store = DriftPrayerRepository(db);
      final newer = report(PrayerStatus.completedOnTime, 3);
      final older = report(PrayerStatus.pending, 1);
      expect(
        (await store.applyInbound(
          PrayerReport(
            accountId: newer.accountId,
            reportId: newer.reportId,
            date: newer.date,
            name: newer.name,
            status: newer.status,
            reportedCompletionAt: newer.reportedCompletionAt,
            recordedZoneId: newer.recordedZoneId,
            recordedOffsetMinutes: newer.recordedOffsetMinutes,
            createdAt: newer.createdAt,
            updatedAt: newer.updatedAt,
            lastAcknowledgedUpdatedAt: newer.updatedAt,
          ),
        )).failureOrNull,
        isNull,
      );
      final reconciler = PrayerReconciler(
        repository: store,
        localStore: DriftLocalStore(db),
        awards: DriftAwardLedger(db),
      );
      expect(
        (await reconciler.reconcile(
          accountId: 'owner-a',
          remote: PrayerRemoteSnapshot(
            reports: [older],
            awards: const [],
            conflicts: const [],
          ),
        )).failureOrNull,
        isNull,
      );
      final retained = (await store.readFresh(
        accountId: 'owner-a',
        date: date,
        prayerName: PrayerName.fajr,
      )).valueOrNull!;
      expect(retained.status, PrayerStatus.completedOnTime);
      expect(retained.lastAcknowledgedUpdatedAt, newer.updatedAt);
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  test(
    'foreign data and obsolete account scope cannot enter the store',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 130),
      );
      try {
        final reconciler = PrayerReconciler(
          repository: DriftPrayerRepository(db),
          localStore: DriftLocalStore(db),
          awards: DriftAwardLedger(db),
        );
        final remote = report(PrayerStatus.completedOnTime, 2);
        final snapshot = PrayerRemoteSnapshot(
          reports: [remote],
          awards: const [],
          conflicts: const [],
        );
        expect(
          (await reconciler.reconcile(
            accountId: 'owner-b',
            remote: snapshot,
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await reconciler.reconcile(
            accountId: 'owner-a',
            remote: snapshot,
            isCurrentScope: () => false,
          )).failureOrNull,
          isNotNull,
        );
        var checks = 0;
        expect(
          (await reconciler.reconcile(
            accountId: 'owner-a',
            remote: PrayerRemoteSnapshot(
              reports: [remote],
              awards: [
                XpAward(
                  accountId: 'owner-a',
                  source: kPrayerDoneAwardSource,
                  sourceId: id,
                  amount: 10,
                  awardedAt: remote.reportedCompletionAt!,
                ),
              ],
              conflicts: const [],
            ),
            isCurrentScope: () => ++checks < 4,
          )).failureOrNull,
          isNotNull,
        );
        expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 0);
        expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 0);
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );
}
