import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import '../../support/theme_test_support.dart';

class _ReadyCloudSession implements CloudSessionPort {
  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: 'account-1'),
      );
}

FoundationCubit _foundationCubit() =>
    FoundationCubit(BootstrapUseCase(cloudSession: _ReadyCloudSession()));

LocaleCubit _localeCubit() {
  final store = ThemeMemoryLocalStore();
  return LocaleCubit(
    restore: RestoreLocalePreferenceUseCase(localStore: store),
    save: SaveLocalePreferenceUseCase(localStore: store),
  );
}

ThemeCubit _themeCubit(ThemeMemoryLocalStore store) => ThemeCubit(
  restore: RestoreThemePreferenceUseCase(localStore: store),
  save: SaveThemePreferenceUseCase(localStore: store),
);

Future<void> _pumpApp(WidgetTester tester, ThemeCubit themeCubit) async {
  final foundationCubit = _foundationCubit();
  final localeCubit = _localeCubit();
  addTearDown(foundationCubit.close);
  addTearDown(localeCubit.close);
  addTearDown(themeCubit.close);
  await tester.pumpWidget(
    FoundationApp(
      cubitOverride: foundationCubit,
      localeCubitOverride: localeCubit,
      themeCubitOverride: themeCubit,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the root follows the restored light, dark, and system selections',
    (tester) async {
      final store = ThemeMemoryLocalStore();
      final cubit = _themeCubit(store);
      await _pumpApp(tester, cubit);

      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);

      await cubit.selectAppearance('light');
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.light);

      await cubit.selectAppearance('dark');
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.dark);

      await cubit.selectAppearance('system');
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.system);
    },
  );
}
