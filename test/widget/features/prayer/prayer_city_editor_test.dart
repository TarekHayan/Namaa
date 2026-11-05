import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/city_search_port.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/presentation/prayer_city_editor.dart';

class _Search extends Fake implements CitySearchPort {
  final cancelledOwners = <String>[];
  bool offline = false;
  @override
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  }) async => offline
      ? AppResult.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.network,
            messageKey: 'prayerSearchOffline',
            occurredAt: DateTime.utc(2026),
          ),
        )
      : AppResult.success([
          PrayerCity(
            provider: 'fixture',
            providerCityId: 'cairo',
            name: 'Cairo',
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'Africa/Cairo',
          ),
        ]);

  @override
  void cancel({required String ownerId, required int generation}) {
    cancelledOwners.add(ownerId);
  }
}

class _Store extends Fake implements PrayerPreferencesPort {
  PrayerPreferences? saved;
  bool fail = false;

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) async {
    if (fail) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'prayerSaveFailed',
          occurredAt: DateTime.utc(2026),
        ),
      );
    }
    saved = preferences;
    return AppResult.success(preferences);
  }
}

void main() {
  testWidgets(
    'offline first search explains failure without inventing a city',
    (tester) async {
      final search = _Search()..offline = true;
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PrayerCityEditor(
              ownerId: 'owner-a',
              search: search,
              commands: PrayerPreferencesCommands(_Store()),
              onSaved: () {},
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('prayer_city_search')),
        'Cairo',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(PrayerCityEditor)),
      );
      expect(find.text(copy.prayerSearchOffline), findsOneWidget);
      expect(find.byKey(const Key('prayer_city_cairo')), findsNothing);
      expect(
        tester
            .widget<AppButton>(find.byKey(const Key('prayer_city_confirm')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('failed city save keeps the previous confirmed city', (
    tester,
  ) async {
    final store = _Store()..fail = true;
    final current = PrayerPreferences(
      accountId: 'owner-a',
      city: PrayerCity(
        provider: 'fixture',
        providerCityId: 'london',
        name: 'London',
        countryCode: 'GB',
        countryName: 'United Kingdom',
        latitude: 51.5,
        longitude: -0.1,
        timeZoneId: 'Europe/London',
      ),
      calculationMethod: 'muslimWorldLeague',
      revision: 1,
      updatedAt: DateTime.utc(2026),
    );
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PrayerCityEditor(
            ownerId: 'owner-a',
            search: _Search(),
            commands: PrayerPreferencesCommands(store),
            current: current,
            onSaved: () => saved = true,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('prayer_city_search')),
      'Cairo',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const Key('prayer_city_cairo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('prayer_city_confirm')));
    await tester.pump();
    expect(saved, isFalse);
    expect(store.saved, isNull);
    expect(find.text('London, United Kingdom'), findsOneWidget);
    final copy = FoundationLocalizations.of(
      tester.element(find.byType(PrayerCityEditor)),
    );
    expect(find.text(copy.prayerSaveFailed), findsOneWidget);
  });

  testWidgets('switching owner resets search and cannot save old candidate', (
    tester,
  ) async {
    final search = _Search();
    final store = _Store();
    Widget editor(String owner) => MaterialApp(
      supportedLocales: FoundationLocalizations.supportedLocales,
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      home: Scaffold(
        body: PrayerCityEditor(
          ownerId: owner,
          search: search,
          commands: PrayerPreferencesCommands(store),
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpWidget(editor('owner-a'));
    await tester.enterText(
      find.byKey(const Key('prayer_city_search')),
      'Cairo',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const Key('prayer_city_cairo')));
    await tester.pump();
    await tester.pumpWidget(editor('owner-b'));
    await tester.pump();
    expect(search.cancelledOwners, contains('owner-a'));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.byKey(const Key('prayer_city_cairo')), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('prayer_city_confirm')))
          .onPressed,
      isNull,
    );
    expect(store.saved, isNull);
  });

  testWidgets('keyboard can select a search result and confirm it', (
    tester,
  ) async {
    final store = _Store();
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PrayerCityEditor(
            ownerId: 'owner-a',
            search: _Search(),
            commands: PrayerPreferencesCommands(store),
            onSaved: () => saved = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('prayer_city_search')));
    await tester.enterText(
      find.byKey(const Key('prayer_city_search')),
      'Cairo',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    Future<bool> focusKey(String key) async {
      for (var i = 0; i < 15; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) continue;
        final tile = ctx.findAncestorWidgetOfExactType<ListTile>();
        final button = ctx.findAncestorWidgetOfExactType<AppButton>();
        if (tile?.key == Key(key) || button?.key == Key(key)) return true;
      }
      return false;
    }

    expect(await focusKey('prayer_city_cairo'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('prayer_city_cairo')))
          .selected,
      isTrue,
    );
    expect(await focusKey('prayer_city_confirm'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(store.saved?.city.name, 'Cairo');
  });
  testWidgets('city selection is explicit and saved under the route owner', (
    tester,
  ) async {
    final store = _Store();
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PrayerCityEditor(
            ownerId: 'owner-a',
            search: _Search(),
            commands: PrayerPreferencesCommands(store),
            onSaved: () => closed = true,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('prayer_city_search')),
      'Cairo',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byKey(const Key('prayer_city_cairo')), findsOneWidget);
    expect(store.saved, isNull);
    await tester.tap(find.byKey(const Key('prayer_city_cairo')));
    await tester.pump();
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('prayer_city_cairo')))
          .selected,
      isTrue,
    );
    await tester.ensureVisible(find.byKey(const Key('prayer_city_confirm')));
    await tester.tap(find.byKey(const Key('prayer_city_confirm')));
    await tester.pumpAndSettle();
    expect(store.saved?.accountId, 'owner-a');
    expect(store.saved?.city.name, 'Cairo');
    expect(store.saved?.calculationMethod, 'egyptian');
    expect(closed, isTrue);
  });

  testWidgets(
    'phone sheet scrolls above the keyboard and cancellation preserves the city',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _Store();
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) => PrayerCityEditor(
                    ownerId: 'owner-a',
                    search: _Search(),
                    commands: PrayerPreferencesCommands(store),
                    asSheet: true,
                    onSaved: () => Navigator.pop(sheetContext),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prayer_city_search')));
      await tester.enterText(
        find.byKey(const Key('prayer_city_search')),
        'Cairo',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byKey(const Key('prayer_city_cairo')), findsOneWidget);
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('prayer_city_cancel')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('prayer_city_cancel')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('prayer_city_cancel')));
      await tester.pumpAndSettle();
      expect(store.saved, isNull);
      expect(find.byKey(const Key('prayer_city_search')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
