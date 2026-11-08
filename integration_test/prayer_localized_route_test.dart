import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/prayer_report_unit_of_work.dart';
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/application/prayer_device_location_port.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_report_commands.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_preferences.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/presentation/prayer_cubit.dart';
import 'package:namma_project/features/prayer/presentation/prayer_screen.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_status_actions.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_dashboard_view.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

import '../test/support/foundation_test_support.dart';

const owner = kPrayerPreviewAccountId;

class _Location implements PrayerDeviceLocationPort {
  @override
  Future<PrayerDeviceLocation> locate() async => PrayerDeviceLocation(
    city: PrayerCity(
      provider: 'device',
      providerCityId: '30.0444,31.2357',
      name: 'Current location',
      countryCode: 'XX',
      countryName: 'GPS',
      latitude: 30.0444,
      longitude: 31.2357,
      timeZoneId: 'Africa/Cairo',
    ),
    suggestedMethod: 'egyptian',
  );

  @override
  Future<void> openSettings(PrayerLocationProblem problem) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final (locale, keyboard) in [
    (const Locale('ar'), false),
    (const Locale('ar'), true),
    (const Locale('en'), false),
    (const Locale('en'), true),
  ]) {
    testWidgets(
      'localized preview saves location and prayer actions in $locale keyboard=$keyboard',
      (tester) async {
        final path = TemporaryDatabasePath();
        final file = path.allocate();
        final key = List<int>.generate(32, (i) => i + 31);
        var db = await FoundationDatabase.openEncrypted(path: file, key: key);
        PrayerCubit? cubit;
        FoundationAppRouter? router;
        addTearDown(() async {
          router?.dispose();
          await cubit?.close();
          await db.close();
          path.dispose();
        });

        Future<void> openFromHome() async {
          final card = find.byKey(kDashboardPrayerGroup);
          await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
          await tester.pumpAndSettle();
          await tester.tap(card.hitTestable());
          await tester.pumpAndSettle();
        }

        Future<void> openScreen() async {
          final prefs = DriftPrayerPreferences(db);
          final reports = DriftPrayerRepository(db);
          final clock = ZonedPrayerClock(
            now: () => DateTime.utc(2026, 11, 1, 12),
          );
          cubit = PrayerCubit(
            ownerId: owner,
            context: PrayerContextService(
              preferences: prefs,
              reports: reports,
              calculator: AdhanPrayerCalculator(),
              clock: clock,
            ),
            reportCommands: (scope, ownerScope) => PrayerReportCommands(
              ownerId: owner,
              repository: reports,
              unitOfWork: DriftPrayerReportUnitOfWork(
                database: db,
                reports: reports,
                awards: DriftAwardLedger(db),
              ),
              identity: UuidPrayerReportIdentity(),
              clock: clock,
              isCurrentScope: scope,
              isCurrentOwnerContext: ownerScope,
              queueForSync: false,
            ),
          );
          late FoundationAppRouter appRouter;
          appRouter = FoundationAppRouter(
            rootBuilder: (homeContext) => TodayDashboardView(
              state: TodayState.loading(
                TodayScope.account(accountId: owner, generation: 1),
                TodayCalendar(
                  localDate: TodayLocalDate(2026, 11, 1),
                  nowUtc: DateTime.utc(2026, 11, 1, 12),
                  utcOffsetMinutes: 120,
                  dayStartUtc: DateTime.utc(2026, 10, 31, 22),
                  nextDayStartUtc: DateTime.utc(2026, 11, 1, 22),
                  projectionRevision: 1,
                ),
                prayerEnabled: true,
              ),
              strings: resolveTodayStrings(homeContext),
              onRefresh: () {},
              onTasks: () {},
              onHabits: () {},
              onMindMaps: () {},
              onPrayer: () =>
                  unawaited(appRouter.router.push<void>(kPrayerRoute)),
              onPreferences: () {},
              onRetryTasks: () {},
              onRetryHabits: () {},
              onRetryXp: () {},
              onSetTaskCompleted: (_, _) {},
              onSetHabitCompleted: (_, _) {},
            ),
            prayerSession: const PrayerPreviewSession(),
            prayerBuilder: (routeContext, routeOwner) => TodayNavigationShell(
              colors: AppColors.light,
              section: TodayNavigationSection.prayer,
              onHome: () => appRouter.go(kTodayRoute),
              onTasks: () {},
              onHabits: () {},
              onMindMaps: () {},
              onPrayer: () {},
              onPreferences: () {},
              child: Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    key: const Key('integration_prayer_back'),
                    onPressed: () => appRouter.router.pop(),
                  ),
                ),
                body: PrayerScreen(
                  ownerId: routeOwner,
                  cubit: cubit!,
                  commands: PrayerPreferencesCommands(prefs),
                  location: _Location(),
                ),
              ),
            ),
          );
          router = appRouter;
          await tester.pumpWidget(
            MaterialApp.router(
              locale: locale,
              supportedLocales: FoundationLocalizations.supportedLocales,
              localizationsDelegates:
                  FoundationLocalizations.localizationsDelegates,
              routerConfig: appRouter.router,
            ),
          );
          await openFromHome();
          await tester.pump(const Duration(milliseconds: 200));
        }

        Future<void> activateByKeyboard(String key) async {
          final finder = find.byKey(Key(key));
          await tester.ensureVisible(finder);
          await tester.pump();
          for (var attempt = 0; attempt < 80; attempt++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final focused = FocusManager.instance.primaryFocus?.context;
            if (focused == null || !focused.mounted) continue;
            final button = focused.findAncestorWidgetOfExactType<AppButton>();
            final status = focused
                .findAncestorWidgetOfExactType<PrayerStatusButton>();
            final tile = focused.findAncestorWidgetOfExactType<ListTile>();
            if (button?.key == Key(key) ||
                status?.key == Key(key) ||
                tile?.key == Key(key)) {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pump(const Duration(milliseconds: 250));
              return;
            }
          }
          fail('Keyboard could not focus $key');
        }

        await openScreen();
        // First visit uses the device location; there is no city search.
        for (var i = 0; i < 10; i++) {
          if (find.byKey(const Key('prayer_header')).evaluate().isNotEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byKey(const Key('prayer_header')), findsOneWidget);
        for (final name in PrayerName.values) {
          final action = find.byKey(
            Key('prayer_status_${name.wireName}_completed_on_time'),
          );
          await tester.ensureVisible(action);
          await tester.pump();
          if (keyboard) {
            await activateByKeyboard(
              'prayer_status_${name.wireName}_completed_on_time',
            );
          } else {
            await tester.tap(action);
          }
          await tester.pump(const Duration(milliseconds: 250));
        }
        final reset = find.byKey(const Key('prayer_status_fajr_pending'));
        await tester.ensureVisible(reset);
        await tester.pump();
        if (keyboard) {
          await activateByKeyboard('prayer_status_fajr_pending');
        } else {
          await tester.tap(reset);
        }
        await tester.pump(const Duration(milliseconds: 250));
        expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 5);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM prayer_reports WHERE status = 'pending'",
          ),
          1,
        );
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM prayer_reports WHERE status = 'completed_on_time'",
          ),
          4,
        );
        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
        await tester.tap(find.byKey(const Key('integration_prayer_back')));
        await tester.pumpAndSettle();
        expect(find.byKey(kDashboardPrayerGroup), findsOneWidget);
        await openFromHome();
        expect(find.byKey(const Key('prayer_header')), findsOneWidget);
        await cubit!.close();
        cubit = null;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router?.dispose();
        router = null;
        await db.close();
        db = await FoundationDatabase.openEncrypted(path: file, key: key);
        await openScreen();
        expect(find.byKey(const Key('prayer_header')), findsOneWidget);
        final saved = (await DriftPrayerPreferences(
          db,
        ).read(owner)).valueOrNull?.city;
        expect(saved?.provider, 'device');
        expect(saved?.timeZoneId, 'Africa/Cairo');
        expect(await db.rawScalar('SELECT count(*) FROM prayer_reports'), 5);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM prayer_reports WHERE status = 'pending'",
          ),
          1,
        );
      },
    );
  }
}
