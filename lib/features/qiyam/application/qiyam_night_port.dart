import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/qiyam_night.dart';

/// The Qiyam night port: resolves the night in progress for the sampled
/// instant (contracts/adhkar-qiyam-application.md). Composition implements
/// it with the saved location's `PrayerDayBoundaries` and the shared
/// `PrayerScheduleProjection`; a missing schedule follows the device's
/// 12:00 rule in the domain (`features/qiyam/domain/qiyam_night.dart`).
abstract interface class QiyamNightPort {
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  });
}
