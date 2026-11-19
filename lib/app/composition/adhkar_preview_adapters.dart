import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// A closed local-only Adhkar and My Adhkar identity, distinct from every
/// other preview partition and from real authenticated accounts.
const String kAdhkarPreviewAccountId = '00000000-0000-4000-8000-000000000009';

/// The debug preview session behind `/adhkar`: the app runs with no account,
/// and the preview owner counts locally. The preview commands queue nothing
/// for sync, so nothing is ever uploaded (as Prayer's preview).
final class AdhkarPreviewSession implements CloudSessionPort {
  const AdhkarPreviewSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: kAdhkarPreviewAccountId,
    ),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(
        CloudSyncContext(accountId: kAdhkarPreviewAccountId),
      );
}

/// Resolves the preview Adhkar day from the preview Prayer location.
///
/// The preview Prayer screen saves its location under the Prayer preview
/// owner, so the Adhkar preview owner asks for that owner's schedule and the
/// Morning and Evening windows follow the same Fajr and Maghrib the owner
/// sees on the Prayer screen. Only the schedule read is redirected; the
/// counts stay under [kAdhkarPreviewAccountId].
final class AdhkarPreviewTimes implements AdhkarTimesPort {
  const AdhkarPreviewTimes(this._prayerTimes);

  final AdhkarTimesPort _prayerTimes;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) => _prayerTimes.resolve(kPrayerPreviewAccountId, nowUtc);
}
