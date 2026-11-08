import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

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
