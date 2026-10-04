import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';

class _MemoryLocalStore implements LocalStorePort {
  _MemoryLocalStore({Map<String, String>? preferences, this.writeFailure})
    : preferences = <String, String>{...?preferences};

  final Map<String, String> preferences;
  final AppFailure? writeFailure;

  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.success(preferences[key]);

  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    final failure = writeFailure;
    if (failure != null) {
      return AppResult<void>.failure(failure);
    }
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> markChangeConflicted(String operationId) async =>
      AppResult<void>.success(null);

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async => AppResult<List<PendingChangeRecord>>.success(const []);

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async =>
      AppResult<void>.success(null);

  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> recordRecoverableFailure(
    String operationId,
    String summary,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async => AppResult<MigrationOutcome>.success(
    MigrationOutcome(completedVersion: targetSchemaVersion, recovered: false),
  );
}

void main() {
  group('Locale preferences', () {
    test('restores a supported persisted Arabic locale', () async {
      final restore = RestoreLocalePreferenceUseCase(
        localStore: _MemoryLocalStore(preferences: {'locale': 'ar'}),
      );

      final preference = (await restore()).valueOrNull!;

      expect(preference.languageCode, 'ar');
      expect(preference.usedFallback, isFalse);
    });

    test(
      'falls back to English for a missing or unsupported stored locale',
      () async {
        for (final stored in <String?>[null, 'fr', 'ar-EG']) {
          final store = _MemoryLocalStore(
            preferences: stored == null ? null : {'locale': stored},
          );

          final preference = (await RestoreLocalePreferenceUseCase(
            localStore: store,
          )()).valueOrNull!;

          expect(preference.languageCode, 'en');
          expect(preference.usedFallback, isTrue);
        }
      },
    );

    test('saves a supported locale locally', () async {
      final store = _MemoryLocalStore();
      final save = SaveLocalePreferenceUseCase(localStore: store);

      final preference = (await save('ar')).valueOrNull!;

      expect(preference.languageCode, 'ar');
      expect(preference.usedFallback, isFalse);
      expect(store.preferences['locale'], 'ar');
    });

    test(
      'persists the English fallback for an unsupported requested locale',
      () async {
        final store = _MemoryLocalStore();
        final save = SaveLocalePreferenceUseCase(localStore: store);

        final preference = (await save('fr')).valueOrNull!;

        expect(preference.languageCode, 'en');
        expect(preference.usedFallback, isTrue);
        expect(store.preferences['locale'], 'en');
      },
    );

    test(
      'returns local persistence failures without changing the preference',
      () async {
        final failure = AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'foundation.locale.recoverable',
          occurredAt: DateTime.utc(2026),
        );
        final store = _MemoryLocalStore(writeFailure: failure);

        final result = await SaveLocalePreferenceUseCase(localStore: store)(
          'ar',
        );

        expect(result.failureOrNull, same(failure));
        expect(store.preferences, isEmpty);
      },
    );
  });
}
