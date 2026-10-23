import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/preferences/app_preferences_sheet.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';

class _Store implements LocalStorePort {
  final saved = <String, String>{};
  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult.success(saved[key]);
  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    saved[key] = value;
    return const AppResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'language and appearance choices use existing persisted preferences',
    (tester) async {
      final store = _Store();
      final locale = LocaleCubit(
        restore: RestoreLocalePreferenceUseCase(localStore: store),
        save: SaveLocalePreferenceUseCase(localStore: store),
      );
      final theme = ThemeCubit(
        restore: RestoreThemePreferenceUseCase(localStore: store),
        save: SaveThemePreferenceUseCase(localStore: store),
      );
      addTearDown(() async {
        await locale.close();
        await theme.close();
      });
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>.value(value: locale),
            BlocProvider<ThemeCubit>.value(value: theme),
          ],
          child: MaterialApp(
            localizationsDelegates:
                FoundationLocalizations.localizationsDelegates,
            supportedLocales: FoundationLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showAppPreferencesSheet(context),
                  child: const Text('Open preferences'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open preferences'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(locale.state.languageCode, 'ar');
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(theme.state.appearanceMode, 'dark');
      expect(store.saved, containsPair('locale', 'ar'));
      expect(store.saved, containsPair('appearance', 'dark'));
    },
  );
}
