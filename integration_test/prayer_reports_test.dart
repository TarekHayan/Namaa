import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport, XpAward;
import 'package:namma_project/core/data/local/prayer_report_unit_of_work.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_report_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_report_unit_of_work.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../test/support/foundation_test_support.dart';

const _owner = '00000000-0000-4000-8000-000000000008';
final _day = PrayerLocalDate.parse('2026-11-01');

final class _FailingRepository extends Fake implements PrayerRepository {
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
      messageKey: 'injected-local-write-loss',
      occurredAt: report.updatedAt,
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'manual reports, first reward, replay and offline restart stay durable',
    (tester) async {
      final path = TemporaryDatabasePath();
      final file = path.allocate();
      final key = List<int>.generate(32, (index) => index + 31);
      var database = await FoundationDatabase.openEncrypted(
        path: file,
        key: key,
      );
      addTearDown(() async {
        await database.close();
        path.dispose();
      });
      var now = DateTime.utc(2026, 11, 1, 5);
      final clock = ZonedPrayerClock(now: () => now);
      final identity = UuidPrayerReportIdentity();

      PrayerReportCommands commands({bool preview = true}) {
        final reports = DriftPrayerRepository(database);
        return PrayerReportCommands(
          ownerId: _owner,
          repository: reports,
          unitOfWork: DriftPrayerReportUnitOfWork(
            database: database,
            reports: reports,
            awards: DriftAwardLedger(database),
          ),
          identity: identity,
          clock: clock,
          isCurrentScope: (_) => true,
          isCurrentOwnerContext: (_) => true,
          queueForSync: !preview,
          nextOperationId: () =>
              '00000000-0000-4000-8000-${now.microsecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}',
        );
      }

      final context = PrayerReportCommandContext(
        localDate: PrayerLocalDate.parse('2026-11-01'),
        timeZoneId: 'Africa/Cairo',
        preferenceRevision: 1,
        scopeGeneration: 1,
      );
      final command = commands();

      final late = await command.setStatus(
        name: PrayerName.fajr,
        status: PrayerStatus.completedLate,
        capturedContext: context,
      );
      expect(late.failureOrNull, isNull);
      expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);
      expect(await database.rawScalar('SELECT amount FROM xp_awards'), 5);
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        0,
      );

      now = now.add(const Duration(microseconds: 1));
      final corrected = await command.setStatus(
        name: PrayerName.fajr,
        status: PrayerStatus.completedOnTime,
        capturedContext: context,
      );
      expect(corrected.failureOrNull, isNull);
      expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);
      expect(await database.rawScalar('SELECT amount FROM xp_awards'), 5);

      for (var replay = 0; replay < 10; replay++) {
        now = now.add(const Duration(microseconds: 1));
        final result = await command.setStatus(
          name: PrayerName.fajr,
          status: PrayerStatus.completedOnTime,
          capturedContext: context,
        );
        expect(result.failureOrNull, isNull);
      }
      expect(
        await database.rawScalar('SELECT count(*) FROM prayer_reports'),
        1,
      );
      expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);

      now = now.add(const Duration(microseconds: 1));
      await command.setStatus(
        name: PrayerName.fajr,
        status: PrayerStatus.pending,
        capturedContext: context,
      );
      expect(
        (await DriftPrayerRepository(database).readFresh(
          accountId: _owner,
          date: _day,
          prayerName: PrayerName.fajr,
        )).valueOrNull?.status,
        PrayerStatus.pending,
      );
      expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);

      await database.close();
      database = await FoundationDatabase.openEncrypted(path: file, key: key);
      final restored = await DriftPrayerRepository(
        database,
      ).readFresh(accountId: _owner, date: _day, prayerName: PrayerName.fajr);
      expect(restored.valueOrNull?.status, PrayerStatus.pending);
      expect(await database.rawScalar('SELECT amount FROM xp_awards'), 5);
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        0,
      );

      final beforeReports = await database.rawScalar(
        'SELECT count(*) FROM prayer_reports',
      );
      final beforeAwards = await database.rawScalar(
        'SELECT count(*) FROM xp_awards',
      );
      final failedAt = DateTime.utc(2026, 11, 1, 18);
      final failedReport = PrayerReport(
        accountId: _owner,
        reportId: 'failed-report',
        date: _day,
        name: PrayerName.maghrib,
        status: PrayerStatus.completedOnTime,
        reportedCompletionAt: failedAt,
        recordedZoneId: 'Africa/Cairo',
        recordedOffsetMinutes: 120,
        createdAt: failedAt,
        updatedAt: failedAt,
      );
      final failed =
          await DriftPrayerReportUnitOfWork(
            database: database,
            reports: _FailingRepository(),
            awards: DriftAwardLedger(database),
          ).commit(
            PrayerReportCommit(
              report: failedReport,
              firstAward: XpAward(
                accountId: _owner,
                source: kPrayerDoneAwardSource,
                sourceId: failedReport.reportId,
                amount: 10,
                awardedAt: failedAt,
              ),
              operationId: 'failed-operation',
              expectedCurrentVersion: null,
              acknowledgedBase: null,
              queueForSync: true,
            ),
          );
      expect(failed.failureOrNull, isNotNull);
      expect(
        await database.rawScalar('SELECT count(*) FROM prayer_reports'),
        beforeReports,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM xp_awards'),
        beforeAwards,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        0,
      );

      // Passing midnight never writes an inferred missed state.
      now = DateTime.utc(2026, 11, 2, 12);
      await tester.pump(const Duration(milliseconds: 10));
      expect(
        await database.rawScalar('SELECT count(*) FROM prayer_reports'),
        1,
      );
      expect(
        await database.rawScalar(
          "SELECT count(*) FROM prayer_reports WHERE status = 'missed'",
        ),
        0,
      );
    },
  );
}
