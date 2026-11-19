import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

/// A closed local-only Qiyam identity, distinct from every other preview
/// partition and from real authenticated accounts.
const String kQiyamPreviewAccountId = '00000000-0000-4000-8000-00000000000a';

/// The debug preview session behind `/qiyam`: the app runs with no account,
/// and the preview owner records locally. The preview command queues nothing
/// for sync, so nothing is ever uploaded (as Prayer's and Adhkar's preview).
final class QiyamPreviewSession implements CloudSessionPort {
  const QiyamPreviewSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: kQiyamPreviewAccountId,
    ),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(
        CloudSyncContext(accountId: kQiyamPreviewAccountId),
      );
}

/// Resolves the preview Qiyam night from the preview Prayer location.
///
/// The preview Prayer screen saves its location under the Prayer preview
/// owner, so the Qiyam preview owner asks for that owner's schedule and the
/// night and its last third follow the same Maghrib, Fajr and location the
/// owner sees on the Prayer screen. Only the schedule read is redirected;
/// the night records stay under [kQiyamPreviewAccountId].
final class QiyamPreviewNightPort implements QiyamNightPort {
  const QiyamPreviewNightPort(this._prayerNights);

  final QiyamNightPort _prayerNights;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) => _prayerNights.resolve(ownerId: kPrayerPreviewAccountId, nowUtc: nowUtc);
}
