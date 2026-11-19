import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/adhkar_preview_adapters.dart';
import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

final class _RecordingTimes implements AdhkarTimesPort {
  final owners = <String>[];

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async {
    owners.add(ownerId);
    return AppResult.success(
      AdhkarClock.resolve(
        nowUtc: nowUtc,
        input: AdhkarNoSchedule(deviceDay: '2026-11-17'),
      ),
    );
  }
}

/// T034: the debug preview owner of Adhkar (local only, own partition).
void main() {
  test('the preview session is signed in as its own closed owner', () async {
    const session = AdhkarPreviewSession();
    final snapshot = await session.observeSession().first;
    expect(snapshot.status, CloudSessionStatus.signedIn);
    expect(snapshot.accountId, kAdhkarPreviewAccountId);
    expect(
      (await session.obtainSyncContext()).valueOrNull?.accountId,
      kAdhkarPreviewAccountId,
    );
    expect(
      kAdhkarPreviewAccountId,
      isNot(kPrayerPreviewAccountId),
      reason: 'a distinct preview partition',
    );
  });

  test('the preview Adhkar day follows the preview Prayer location', () async {
    final prayerTimes = _RecordingTimes();
    final times = AdhkarPreviewTimes(prayerTimes);
    final result = await times.resolve(
      kAdhkarPreviewAccountId,
      DateTime.utc(2026, 11, 17, 9),
    );
    expect(result.failureOrNull, isNull);
    expect(prayerTimes.owners, [kPrayerPreviewAccountId]);
  });
}
