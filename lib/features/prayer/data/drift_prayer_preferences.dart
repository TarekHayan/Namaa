import 'package:drift/drift.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../application/prayer_preferences_port.dart';
import '../domain/prayer_city.dart';
import '../domain/prayer_preferences.dart';
import 'prayer_timezone_initializer.dart';

/// The chosen city belongs to this encrypted installation, never the outbox.
final class DriftPrayerPreferences implements PrayerPreferencesPort {
  DriftPrayerPreferences(this._database) {
    initializePrayerTimeZones();
  }

  final FoundationDatabase _database;

  @override
  Future<AppResult<PrayerPreferences?>> read(String accountId) async {
    try {
      final row = await (_database.select(
        _database.prayerDevicePreferences,
      )..where((table) => table.accountId.equals(accountId))).getSingleOrNull();
      return AppResult.success(row == null ? null : _decode(row));
    } catch (error) {
      return AppResult.failure(_failure(AppFailureCategory.persistence, error));
    }
  }

  @override
  Stream<PrayerPreferences?> watch(String accountId) =>
      (_database.select(_database.prayerDevicePreferences)
            ..where((table) => table.accountId.equals(accountId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _decode(row));

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) async {
    try {
      timezone.getLocation(preferences.city.timeZoneId);
    } catch (error) {
      return AppResult.failure(_failure(AppFailureCategory.validation, error));
    }
    try {
      return await _database.transaction(() async {
        final existing =
            await (_database.select(_database.prayerDevicePreferences)..where(
                  (table) => table.accountId.equals(preferences.accountId),
                ))
                .getSingleOrNull();
        if (existing?.revision != expectedRevision ||
            preferences.revision != (existing?.revision ?? 0) + 1) {
          return AppResult<PrayerPreferences>.failure(
            _failure(AppFailureCategory.validation, 'stale prayer preference'),
          );
        }
        await _database
            .into(_database.prayerDevicePreferences)
            .insertOnConflictUpdate(
              PrayerDevicePreferencesCompanion.insert(
                accountId: preferences.accountId,
                provider: preferences.city.provider,
                providerCityId: preferences.city.providerCityId,
                cityName: preferences.city.name,
                countryCode: preferences.city.countryCode,
                countryName: preferences.city.countryName,
                adminName: Value(preferences.city.adminName),
                latitude: preferences.city.latitude,
                longitude: preferences.city.longitude,
                timeZoneId: preferences.city.timeZoneId,
                calculationMethod: preferences.calculationMethod,
                revision: preferences.revision,
                updatedAt: preferences.updatedAt.toIso8601String(),
              ),
            );
        return AppResult.success(preferences);
      });
    } catch (error) {
      return AppResult.failure(_failure(AppFailureCategory.persistence, error));
    }
  }

  PrayerPreferences _decode(PrayerDevicePreference row) => PrayerPreferences(
    accountId: row.accountId,
    city: PrayerCity(
      provider: row.provider,
      providerCityId: row.providerCityId,
      name: row.cityName,
      countryCode: row.countryCode,
      countryName: row.countryName,
      adminName: row.adminName,
      latitude: row.latitude,
      longitude: row.longitude,
      timeZoneId: row.timeZoneId,
    ),
    calculationMethod: row.calculationMethod,
    revision: row.revision,
    updatedAt: DateTime.parse(row.updatedAt).toUtc(),
  );

  AppFailure _failure(AppFailureCategory category, Object error) =>
      AppFailure.recoverable(
        category: category,
        messageKey: category == AppFailureCategory.validation
            ? 'prayer.preferences.invalid'
            : kDatabaseUnreadableMessageKey,
        occurredAt: DateTime.now().toUtc(),
        technicalCause: error.runtimeType.toString(),
      );
}
