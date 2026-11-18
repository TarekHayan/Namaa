import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/adhkar_preview_adapters.dart';
import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/app/composition/qiyam_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

final class _RecordingNights implements QiyamNightPort {
  final owners = <String>[];

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async {
    owners.add(ownerId);
    return AppResult.success(
      QiyamNight.resolve(
        nowUtc: nowUtc,
        input: const QiyamScheduleUnavailable(),
      ),
    );
  }
}

/// T049: the debug preview owner of Qiyam (local only, own partition).
void main() {
  test('the preview session is signed in as its own closed owner', () async {
    const session = QiyamPreviewSession();
    final snapshot = await session.observeSession().first;
    expect(snapshot.status, CloudSessionStatus.signedIn);
    expect(snapshot.accountId, kQiyamPreviewAccountId);
    expect(
      (await session.obtainSyncContext()).valueOrNull?.accountId,
      kQiyamPreviewAccountId,
    );
    expect(kQiyamPreviewAccountId, isNot(kPrayerPreviewAccountId));
    expect(kQiyamPreviewAccountId, isNot(kAdhkarPreviewAccountId));
  });

  test('the preview night follows the preview Prayer location', () async {
    final prayerNights = _RecordingNights();
    final nights = QiyamPreviewNightPort(prayerNights);
    final result = await nights.resolve(
      ownerId: kQiyamPreviewAccountId,
      nowUtc: DateTime.utc(2026, 11, 17, 9),
    );
    expect(result.failureOrNull, isNull);
    expect(prayerNights.owners, [kPrayerPreviewAccountId]);
  });
}
