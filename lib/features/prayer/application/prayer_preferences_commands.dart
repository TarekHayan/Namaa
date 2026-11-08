import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/prayer_city.dart';
import '../domain/prayer_preferences.dart';
import 'prayer_preferences_port.dart';

final class PrayerPreferencesCommands {
  PrayerPreferencesCommands(this._preferences);
  final PrayerPreferencesPort _preferences;

  Future<AppResult<PrayerPreferences>> confirm({
    required String ownerId,
    required PrayerCity city,
    required String method,
    required int? expectedRevision,
    required DateTime nowUtc,
  }) async {
    const methods = {
      'egyptian',
      'muslimWorldLeague',
      'ummAlQura',
      'dubai',
      'northAmerica',
      'kuwait',
      'qatar',
    };
    try {
      if (ownerId.trim().isEmpty ||
          !nowUtc.isUtc ||
          (expectedRevision != null && expectedRevision < 0) ||
          !methods.contains(method)) {
        throw ArgumentError('invalid prayer context');
      }
      return _preferences.save(
        PrayerPreferences(
          accountId: ownerId,
          city: city,
          calculationMethod: method,
          revision: (expectedRevision ?? 0) + 1,
          updatedAt: nowUtc,
        ),
        expectedRevision: expectedRevision,
      );
    } catch (_) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: 'prayer.preferences.invalid',
          occurredAt: nowUtc.toUtc(),
        ),
      );
    }
  }
}
