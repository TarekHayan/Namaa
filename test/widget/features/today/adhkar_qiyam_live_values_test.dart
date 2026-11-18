import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/today/domain/today_adhkar_qiyam_reference.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_dashboard_view.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/prayer_track_hub.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_focus_reflection_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';
import 'package:namma_project/features/today/presentation/widgets/today_progress_hero.dart';

/// T057: Home and the Track hub show the Adhkar/Qiyam port's live values, the
/// same numbers the Adhkar and Qiyam screens show. Quran and Focus stay
/// "coming soon"; any remaining sample value keeps its provenance label.
void main() {
  TodayAdhkarQiyamReference reference({
    int morning = 3,
    int morningTotal = 10,
    int evening = 0,
    int eveningTotal = 9,
    TodayAdhkarPeriod? period = TodayAdhkarPeriod.morning,
    TodayQiyamTonight tonight = TodayQiyamTonight.unanswered,
    bool scheduleUnavailable = false,
    bool adhkarLoadFailed = false,
    bool qiyamLoadFailed = false,
    DateTime? lastThirdUtc,
    String? zone = 'Africa/Cairo',
  }) => TodayAdhkarQiyamReference(
    ownerId: 'owner',
    scheduleUnavailable: scheduleUnavailable,
    adhkarLoadFailed: adhkarLoadFailed,
    morningCompleted: morning,
    morningTotal: morningTotal,
    eveningCompleted: evening,
    eveningTotal: eveningTotal,
    period: period,
    qiyamLoadFailed: qiyamLoadFailed,
    tonight: tonight,
    adhkarStreak: 1,
    qiyamStreak: 1,
    // 02:41 Cairo time (UTC+2 in winter).
    lastThirdUtc: lastThirdUtc ?? DateTime.utc(2026, 11, 18, 0, 41),
    qiyamZoneId: zone,
  );

  Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: FoundationLocalizations.localizationsDelegates,
    supportedLocales: FoundationLocalizations.supportedLocales,
    home: home,
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  TodayState stateWith(TodaySection<TodayAdhkarQiyamReference>? section) {
    final day = TodayLocalDate(2026, 11, 18);
    final base = TodayState.loading(
      TodayScope.account(accountId: 'owner', generation: 1),
      TodayCalendar(
        localDate: day,
        nowUtc: DateTime.utc(2026, 11, 18, 10),
        utcOffsetMinutes: 120,
        dayStartUtc: DateTime.utc(2026, 11, 18),
        nextDayStartUtc: DateTime.utc(2026, 11, 19),
        projectionRevision: 1,
      ),
    );
    return section == null ? base : base.copyWith(adhkarQiyam: section);
  }

  Widget dashboard(
    TodayState state, {
    VoidCallback? onAdhkar,
    VoidCallback? onQiyam,
    Locale locale = const Locale('en'),
  }) => app(
    Builder(
      builder: (context) => TodayDashboardView(
        state: state,
        strings: resolveTodayStrings(context),
        onRefresh: () {},
        onTasks: () {},
        onHabits: () {},
        onMindMaps: () {},
        onPreferences: () {},
        onAdhkar: onAdhkar,
        onQiyam: onQiyam,
        onRetryTasks: () {},
        onRetryHabits: () {},
        onRetryXp: () {},
        onSetTaskCompleted: (_, _) {},
        onSetHabitCompleted: (_, _) {},
      ),
    ),
    locale: locale,
  );

  /// The tile's semantic label, read from the `Semantics` widget itself.
  Finder metric(String title, String value) => find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.label == '$title: $value',
  );

  group('Track hub subtitles', () {
    testWidgets('show Morning x/N, Evening x/N and the last third', (
      tester,
    ) async {
      phone(tester);
      final controller =
          StreamController<TodayAdhkarQiyamReference>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(
        app(
          PrayerTrackHub(
            onPrayer: () {},
            onAdhkar: () {},
            onQiyam: () {},
            watchAdhkarQiyam: () => controller.stream,
          ),
        ),
      );
      // Until the first value the tiles stay active, without subtitles.
      expect(find.byKey(const Key('prayer_track_subtitle_3')), findsNothing);
      expect(find.byKey(const Key('prayer_track_subtitle_4')), findsNothing);
      controller.add(reference());
      await tester.pump();
      await tester.pump();
      expect(find.text('Morning 3/10 · Evening 0/9'), findsOneWidget);
      expect(find.text('Last third of the night 02:41'), findsOneWidget);
      // A change of the counts updates the subtitle live.
      controller.add(reference(morning: 4, evening: 1));
      await tester.pump();
      await tester.pump();
      expect(find.text('Morning 4/10 · Evening 1/9'), findsOneWidget);
    });

    testWidgets('a recorded night reads Recorded for both answers', (
      tester,
    ) async {
      phone(tester);
      final controller =
          StreamController<TodayAdhkarQiyamReference>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(
        app(
          PrayerTrackHub(
            onPrayer: () {},
            onAdhkar: () {},
            onQiyam: () {},
            watchAdhkarQiyam: () => controller.stream,
          ),
        ),
      );
      controller.add(reference(tonight: TodayQiyamTonight.yes));
      await tester.pump();
      await tester.pump();
      expect(find.text('Recorded'), findsOneWidget);
      controller.add(reference(tonight: TodayQiyamTonight.no));
      await tester.pump();
      await tester.pump();
      expect(find.text('Recorded'), findsOneWidget);
    });

    testWidgets('Arabic copy, and the subtitle follows the layout direction', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          PrayerTrackHub(
            onPrayer: () {},
            onAdhkar: () {},
            onQiyam: () {},
            watchAdhkarQiyam: () => Stream.value(reference()),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(PrayerTrackHub)),
      );
      expect(
        find.text(copy.dashboardTrackAdhkarSubtitle('3/10', '0/9')),
        findsOneWidget,
      );
      expect(find.textContaining('الصباح'), findsOneWidget);
      expect(find.textContaining('المساء'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(PrayerTrackHub))),
        TextDirection.rtl,
      );
    });

    testWidgets('a locked schedule, a failed read or a failed source leave '
        'the tiles active without a subtitle', (tester) async {
      phone(tester);
      var opened = 0;
      final controller =
          StreamController<TodayAdhkarQiyamReference>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(
        app(
          PrayerTrackHub(
            onPrayer: () {},
            onAdhkar: () => opened++,
            onQiyam: () => opened++,
            watchAdhkarQiyam: () => controller.stream,
          ),
        ),
      );
      controller.add(
        reference(
          scheduleUnavailable: true,
          morning: 0,
          morningTotal: 0,
          eveningTotal: 0,
          tonight: TodayQiyamTonight.locked,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('prayer_track_subtitle_3')), findsNothing);
      expect(find.byKey(const Key('prayer_track_subtitle_4')), findsNothing);
      controller.add(reference(adhkarLoadFailed: true, qiyamLoadFailed: true));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('prayer_track_subtitle_3')), findsNothing);
      expect(find.byKey(const Key('prayer_track_subtitle_4')), findsNothing);
      controller.addError(StateError('offline'));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('prayer_track_subtitle_3')), findsNothing);
      await tester.tap(find.byKey(const Key('prayer_track_3')));
      await tester.tap(find.byKey(const Key('prayer_track_4')));
      expect(opened, 2);
    });

    testWidgets('Quran and Focus stay coming soon and never get a live '
        'subtitle', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          PrayerTrackHub(
            onPrayer: () {},
            onAdhkar: () {},
            onQiyam: () {},
            watchAdhkarQiyam: () => Stream.value(reference()),
          ),
        ),
      );
      await tester.pump();
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(PrayerTrackHub)),
      );
      for (final index in [1, 2]) {
        expect(
          find.descendant(
            of: find.byKey(Key('prayer_track_$index')),
            matching: find.text(copy.dashboardComingSoon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(Key('prayer_track_$index')),
            matching: find.byIcon(Icons.lock_clock_outlined),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('the shell passes the live source to the hub it opens', (
      tester,
    ) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        app(
          TodayNavigationShell(
            colors: AppColors.light,
            section: TodayNavigationSection.home,
            onHome: () {},
            onTasks: () {},
            onHabits: () {},
            onMindMaps: () {},
            onPrayer: () {},
            onAdhkar: () => opened++,
            onQiyam: () {},
            onPreferences: () {},
            watchAdhkarQiyam: () => Stream.value(reference()),
            child: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.tap(find.byKey(kTodayBottomTrackKey));
      await tester.pumpAndSettle();
      expect(find.text('Morning 3/10 · Evening 0/9'), findsOneWidget);
      await tester.tap(find.byKey(const Key('prayer_track_3')));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });
  });

  group('Home progress hero', () {
    Future<void> pumpHero(
      WidgetTester tester,
      TodaySection<TodayAdhkarQiyamReference>? section, {
      VoidCallback? onAdhkar,
      VoidCallback? onQiyam,
      Locale locale = const Locale('en'),
    }) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                child: TodayProgressHero(
                  state: stateWith(section),
                  strings: resolveTodayStrings(context),
                  colors: AppColors.light,
                  onOpenAdhkar: onAdhkar,
                  onOpenQiyam: onQiyam,
                ),
              ),
            ),
          ),
          locale: locale,
        ),
      );
    }

    testWidgets('the Adhkar tile shows the current period\'s x/N and opens '
        'the screen', (tester) async {
      var opened = 0;
      await pumpHero(
        tester,
        TodaySection.available(reference()),
        onAdhkar: () => opened++,
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      expect(metric(copy.adhkarTabMorning, '3/10'), findsOneWidget);
      // No sample badge on the live tile.
      expect(find.text('19'), findsNothing);
      await tester.tap(find.text('3/10'));
      expect(opened, 1);
    });

    testWidgets('in the evening the tile shows the Evening list', (
      tester,
    ) async {
      await pumpHero(
        tester,
        TodaySection.available(
          reference(period: TodayAdhkarPeriod.evening, evening: 5),
        ),
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      expect(metric(copy.adhkarTabEvening, '5/9'), findsOneWidget);
    });

    testWidgets('the Qiyam tile shows tonight\'s answer and opens the '
        'screen', (tester) async {
      var opened = 0;
      await pumpHero(
        tester,
        TodaySection.available(reference(tonight: TodayQiyamTonight.yes)),
        onQiyam: () => opened++,
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      expect(
        metric(copy.dashboardAdhkarQiyam, copy.qiyamSegYes),
        findsOneWidget,
      );
      await tester.tap(find.text('✓'));
      expect(opened, 1);
    });

    testWidgets('a No, an unanswered and a locked night read differently', (
      tester,
    ) async {
      await pumpHero(
        tester,
        TodaySection.available(reference(tonight: TodayQiyamTonight.no)),
      );
      expect(find.text('✗'), findsOneWidget);
      await pumpHero(tester, TodaySection.available(reference()));
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      expect(
        metric(copy.dashboardAdhkarQiyam, copy.qiyamHistoryNotRecorded),
        findsOneWidget,
      );
    });

    testWidgets('loading, unavailable, failed read and no schedule never '
        'show progress', (tester) async {
      await pumpHero(tester, TodaySection.loading());
      // The Tasks tile is loading too; the Adhkar tile adds the second.
      expect(find.text('--/--'), findsNWidgets(2));
      expect(find.text('--'), findsOneWidget);

      await pumpHero(
        tester,
        TodaySection.unavailable(
          AppFailure.recoverable(
            category: AppFailureCategory.persistence,
            messageKey: 'todaySourceUnavailable',
            occurredAt: DateTime.utc(2026, 11, 18),
          ),
        ),
      );
      expect(find.text('!'), findsWidgets);

      await pumpHero(
        tester,
        TodaySection.available(
          reference(adhkarLoadFailed: true, qiyamLoadFailed: true),
        ),
      );
      expect(find.text('!'), findsWidgets);
      expect(find.text('3/10'), findsNothing);

      await pumpHero(
        tester,
        TodaySection.empty(
          reference(
            scheduleUnavailable: true,
            morning: 0,
            morningTotal: 0,
            tonight: TodayQiyamTonight.locked,
            period: null,
          ),
        ),
      );
      expect(find.text('0/0'), findsNothing);
    });

    testWidgets('Quran and Focus keep their sample label', (tester) async {
      await pumpHero(tester, TodaySection.available(reference()));
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      expect(
        metric(
          copy.dashboardSampleValue,
          '${copy.dashboardQuran} 75%',
        ).evaluate().length,
        1,
      );
      expect(find.text('50m'), findsOneWidget);
    });

    testWidgets('the Home dashboard shows the live values in Arabic and '
        'opens the real routes', (tester) async {
      phone(tester);
      // Tall enough to lay the whole page out, so no section hides behind
      // the header while it scrolls.
      tester.view.physicalSize = const Size(390, 4200);
      var adhkar = 0;
      var qiyam = 0;
      await tester.pumpWidget(
        dashboard(
          stateWith(TodaySection.available(reference(evening: 2))),
          onAdhkar: () => adhkar++,
          onQiyam: () => qiyam++,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3/10'), findsOneWidget);
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayProgressHero)),
      );
      final adhkarHub = find.descendant(
        of: find.byKey(kDashboardHubsGroup),
        matching: find.text(copy.dashboardComingSoonAdhkarTitle),
      );
      await tester.tap(adhkarHub);
      await tester.pump();
      final qiyamHub = find.descendant(
        of: find.byKey(kDashboardHubsGroup),
        matching: find.text(copy.dashboardComingSoonQiyamTitle),
      );
      await tester.tap(qiyamHub);
      await tester.pump();
      expect((adhkar, qiyam), (1, 1));
    });
  });

  group('Focus and reflection card', () {
    Future<void> pumpCard(
      WidgetTester tester,
      TodaySection<TodayAdhkarQiyamReference>? section, {
      VoidCallback? onAdhkar,
      VoidCallback? onQiyam,
    }) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayFocusReflectionCard(
                colors: AppColors.light,
                adhkarQiyam: section,
                onAdhkar: onAdhkar,
                onQiyam: onQiyam,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the Adhkar and Qiyam rows show live values and open the '
        'screens', (tester) async {
      var adhkar = 0;
      var qiyam = 0;
      await pumpCard(
        tester,
        TodaySection.available(
          reference(morning: 10, tonight: TodayQiyamTonight.yes),
        ),
        onAdhkar: () => adhkar++,
        onQiyam: () => qiyam++,
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayFocusReflectionCard)),
      );
      expect(find.text('${copy.dashboardAdhkarMorning} 10/10'), findsOneWidget);
      expect(find.text('${copy.dashboardAdhkarEvening} 0/9'), findsOneWidget);
      expect(find.text('${copy.dashboardAdhkarQiyam} ✓'), findsOneWidget);
      await tester.tap(find.text('${copy.dashboardAdhkarMorning} 10/10'));
      await tester.tap(find.text('${copy.dashboardAdhkarEvening} 0/9'));
      await tester.tap(find.text('${copy.dashboardAdhkarQiyam} ✓'));
      expect((adhkar, qiyam), (2, 1));
      // The sample notice is no longer shown for them.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the Pomodoro block and the quote keep their sample label '
        'while the Adhkar rows carry none', (tester) async {
      await pumpCard(tester, TodaySection.available(reference()));
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayFocusReflectionCard)),
      );
      expect(find.text(copy.dashboardSampleBadge), findsNWidgets(2));
    });

    testWidgets('without a source the rows show their label alone', (
      tester,
    ) async {
      await pumpCard(tester, null);
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayFocusReflectionCard)),
      );
      expect(find.text(copy.dashboardAdhkarMorning), findsOneWidget);
      expect(find.text('3/10'), findsNothing);
    });
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'the live tiles and subtitles fit 320 px at 200% text (hero 150%) in '
      '$locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 3200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates:
                FoundationLocalizations.localizationsDelegates,
            supportedLocales: FoundationLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      // The existing ring gauge was drawn for up to 150% text.
                      MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: const TextScaler.linear(1.5)),
                        child: TodayProgressHero(
                          state: stateWith(
                            TodaySection.available(
                              reference(
                                period: TodayAdhkarPeriod.evening,
                                evening: 12,
                                eveningTotal: 15,
                                tonight: TodayQiyamTonight.yes,
                              ),
                            ),
                          ),
                          strings: resolveTodayStrings(context),
                          colors: AppColors.light,
                        ),
                      ),
                      SizedBox(
                        height: 700,
                        child: PrayerTrackHub(
                          onPrayer: () {},
                          onAdhkar: () {},
                          onQiyam: () {},
                          watchAdhkarQiyam: () => Stream.value(reference()),
                        ),
                      ),
                      TodayFocusReflectionCard(
                        colors: AppColors.light,
                        adhkarQiyam: TodaySection.available(reference()),
                        onAdhkar: () {},
                        onQiyam: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
