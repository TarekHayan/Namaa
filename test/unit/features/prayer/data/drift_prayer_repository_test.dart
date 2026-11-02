import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart'
    as domain;
import 'package:namma_project/features/prayer/domain/prayer_status.dart';

import '../../../../support/foundation_test_support.dart';

domain.PrayerReport _report(String owner, String date, PrayerName name) =>
    domain.PrayerReport(
      accountId: owner,
      reportId: '$owner/$date/${name.name}',
      date: PrayerLocalDate.parse(date),
      name: name,
      status: PrayerStatus.completedOnTime,
      reportedCompletionAt: DateTime.utc(2026, 10, 29, 10, 20, 30, 123, 456),
      recordedZoneId: 'Africa/Cairo',
      recordedOffsetMinutes: 120,
      createdAt: DateTime.utc(2026, 10, 29, 10, 20, 30, 123, 456),
      updatedAt: DateTime.utc(2026, 10, 29, 10, 20, 30, 123, 457),
    );

void main() {
  test('owner/day reads preserve UTC microseconds and outbox base', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 90),
    );
    try {
      final store = DriftPrayerRepository(db);
      final day = PrayerLocalDate.parse('2026-10-29');
      expect(
        (await store.readFresh(
          accountId: 'a',
          date: day,
          prayerName: PrayerName.fajr,
        )).valueOrNull,
        isNull,
      );
      final first = _report('a', day.value, PrayerName.fajr);
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
        (await store.readFresh(
          accountId: 'a',
          date: day,
          prayerName: PrayerName.fajr,
        )).valueOrNull,
        first,
      );
      expect(
        (await store.readFresh(
          accountId: 'b',
          date: day,
          prayerName: PrayerName.fajr,
        )).valueOrNull,
        isNull,
      );
      expect(
        (await store.readFresh(
          accountId: 'a',
          date: PrayerLocalDate.parse('2026-10-30'),
          prayerName: PrayerName.fajr,
        )).valueOrNull,
        isNull,
      );
      expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 1);
      expect(
        await db.rawScalar('SELECT base_updated_at FROM pending_changes'),
        isNull,
      );
      expect(await store.watchDay(accountId: 'a', date: day).first, [first]);
      expect(await store.watchDay(accountId: 'b', date: day).first, isEmpty);
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  test('failed composed transaction rolls back report and outbox', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 90),
    );
    try {
      final store = DriftPrayerRepository(db);
      final report = _report('a', '2026-10-29', PrayerName.asr);
      final outcome = await store.runInTransaction<void>(() async {
        final saved = await store.writeLocal(
          report,
          operationId: 'rollback-op',
          acknowledgedBase: null,
          expectedCurrentVersion: null,
        );
        expect(saved.failureOrNull, isNull);
        return AppResult.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.validation,
            messageKey: 'test.rollback',
            occurredAt: DateTime.utc(2026, 10, 29),
          ),
        );
      });
      expect(outcome.failureOrNull?.category, AppFailureCategory.validation);
      expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 0);
      expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
    } finally {
      await db.close();
      temp.dispose();
    }
  });
}
