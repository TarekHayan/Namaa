import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/city_search_port.dart';
import 'package:namma_project/features/prayer/data/dio_city_search.dart';
import 'package:namma_project/features/prayer/data/prayer_search_configuration.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';

/// A closed local-only Prayer identity, distinct from every other preview
/// partition and from real authenticated accounts.
const String kPrayerPreviewAccountId = '00000000-0000-4000-8000-000000000008';

final class PrayerPreviewSession implements CloudSessionPort {
  const PrayerPreviewSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: kPrayerPreviewAccountId,
    ),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(
        CloudSyncContext(accountId: kPrayerPreviewAccountId),
      );
}

/// Search is an evaluation-only service; a release build requires a licensed
/// gateway.
CitySearchPort createPrayerCitySearch() {
  final config = PrayerSearchConfiguration.resolve();
  final value = config.valueOrNull;
  return value == null
      ? const UnavailablePrayerCitySearch()
      : DioCitySearch(configuration: value);
}

final class UnavailablePrayerCitySearch implements CitySearchPort {
  const UnavailablePrayerCitySearch();

  @override
  void cancel({required String ownerId, required int generation}) {}

  @override
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  }) async => AppResult.failure(
    AppFailure.recoverable(
      category: AppFailureCategory.configuration,
      messageKey: 'prayerSearchUnavailable',
      occurredAt: DateTime.now().toUtc(),
    ),
  );
}
