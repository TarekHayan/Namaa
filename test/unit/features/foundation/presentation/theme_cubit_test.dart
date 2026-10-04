import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import '../../../../support/theme_test_support.dart';

ThemeCubit _cubit(ThemeMemoryLocalStore store) => ThemeCubit(
  restore: RestoreThemePreferenceUseCase(localStore: store),
  save: SaveThemePreferenceUseCase(localStore: store),
);

void main() {
  blocTest<ThemeCubit, ThemeState>(
    'restores the persisted dark appearance mode',
    build: () =>
        _cubit(ThemeMemoryLocalStore(preferences: {'appearance': 'dark'})),
    act: (cubit) => cubit.restore(),
    expect: () => <Matcher>[
      isA<ThemeReady>()
          .having((state) => state.appearanceMode, 'appearanceMode', 'dark')
          .having((state) => state.themeMode, 'themeMode', ThemeMode.dark),
    ],
  );

  blocTest<ThemeCubit, ThemeState>(
    'selects light, dark, and system modes',
    build: () => _cubit(ThemeMemoryLocalStore()),
    act: (cubit) async {
      await cubit.selectAppearance('light');
      await cubit.selectAppearance('dark');
      await cubit.selectAppearance('system');
    },
    expect: () => <Matcher>[
      isA<ThemeReady>().having(
        (state) => state.themeMode,
        'themeMode',
        ThemeMode.light,
      ),
      isA<ThemeReady>().having(
        (state) => state.themeMode,
        'themeMode',
        ThemeMode.dark,
      ),
      isA<ThemeReady>().having(
        (state) => state.themeMode,
        'themeMode',
        ThemeMode.system,
      ),
    ],
  );

  blocTest<ThemeCubit, ThemeState>(
    'retains the active appearance and maps an unexpected save error safely',
    build: () => _cubit(ThemeMemoryLocalStore(throwOnWrite: true)),
    act: (cubit) => cubit.selectAppearance('dark'),
    expect: () => <Matcher>[
      isA<ThemePersistenceFailure>()
          .having((state) => state.appearanceMode, 'appearanceMode', 'system')
          .having(
            (state) => state.messageKey,
            'messageKey',
            kMessageKeyThemeRecoverable,
          ),
    ],
  );
}
