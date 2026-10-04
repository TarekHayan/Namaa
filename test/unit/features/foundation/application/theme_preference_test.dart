import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import '../../../../support/theme_test_support.dart';

void main() {
  group('Theme preferences', () {
    test('restores a persisted supported appearance mode', () async {
      final preference = (await RestoreThemePreferenceUseCase(
        localStore: ThemeMemoryLocalStore(preferences: {'appearance': 'dark'}),
      )()).valueOrNull!;

      expect(preference.appearanceMode, 'dark');
      expect(preference.usedFallback, isFalse);
    });

    test(
      'falls back to system for missing or unsupported stored appearance',
      () async {
        for (final stored in <String?>[null, 'amoled', 'Dark']) {
          final preference = (await RestoreThemePreferenceUseCase(
            localStore: ThemeMemoryLocalStore(
              preferences: stored == null ? null : {'appearance': stored},
            ),
          )()).valueOrNull!;

          expect(preference.appearanceMode, 'system');
          expect(preference.usedFallback, isTrue);
        }
      },
    );

    test('saves the selected supported appearance mode locally', () async {
      final store = ThemeMemoryLocalStore();
      final preference = (await SaveThemePreferenceUseCase(localStore: store)(
        'light',
      )).valueOrNull!;

      expect(preference.appearanceMode, 'light');
      expect(store.preferences['appearance'], 'light');
    });

    test(
      'returns a persistence failure without changing the saved appearance',
      () async {
        final store = ThemeMemoryLocalStore(
          writeFailure: AppFailure.recoverable(
            category: AppFailureCategory.persistence,
            messageKey: 'foundation.theme.recoverable',
            occurredAt: DateTime.utc(2026),
          ),
        );

        final result = await SaveThemePreferenceUseCase(localStore: store)(
          'dark',
        );

        expect(result.failureOrNull, isNotNull);
        expect(store.preferences, isEmpty);
      },
    );
  });
}
