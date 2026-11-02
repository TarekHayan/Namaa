import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';

abstract interface class PrayerRepository {
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
  Future<AppResult<PrayerReport?>> readFresh({
    required String accountId,
    required PrayerLocalDate date,
    required PrayerName prayerName,
  });
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  });
  Future<AppResult<void>> writeLocal(
    PrayerReport report, {
    required String operationId,
    required DateTime? acknowledgedBase,
    required DateTime? expectedCurrentVersion,
    bool queueForSync = true,
  });
  Future<AppResult<void>> applyInbound(PrayerReport report);
}
