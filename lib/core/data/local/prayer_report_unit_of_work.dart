import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_report_unit_of_work.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';

final class DriftPrayerReportUnitOfWork implements PrayerReportUnitOfWork {
  DriftPrayerReportUnitOfWork({
    required FoundationDatabase database,
    required PrayerRepository reports,
    required SharedAwardLedgerPort awards,
  }) : _database = database,
       _reports = reports,
       _awards = awards;

  final FoundationDatabase _database;
  final PrayerRepository _reports;
  final SharedAwardLedgerPort _awards;

  @override
  Future<AppResult<void>> commit(PrayerReportCommit request) async {
    try {
      await _database.transaction(() async {
        final award = request.firstAward;
        if (award != null) {
          final result = await _awards.insertSharedOnce(award);
          if (result.failureOrNull case final failure?) {
            throw _PrayerCommitFailure(failure);
          }
        }
        final result = await _reports.writeLocal(
          request.report,
          operationId: request.operationId,
          acknowledgedBase: request.acknowledgedBase,
          expectedCurrentVersion: request.expectedCurrentVersion,
          queueForSync: request.queueForSync,
        );
        if (result.failureOrNull case final failure?) {
          throw _PrayerCommitFailure(failure);
        }
      });
      return const AppResult.success(null);
    } on _PrayerCommitFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'prayer.report.save_failed',
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }
}

final class _PrayerCommitFailure implements Exception {
  const _PrayerCommitFailure(this.failure);
  final AppFailure failure;
}
