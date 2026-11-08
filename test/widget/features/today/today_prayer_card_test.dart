import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_prayer_reference.dart';
import 'package:namma_project/features/today/domain/today_projection.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/today_prayer_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_progress_hero.dart';
import 'package:namma_project/features/today/presentation/widgets/today_quick_hubs.dart';

void main() {
  testWidgets('setup and unavailable states never show invented prayer times', (
    tester,
  ) async {
    final setup = TodaySection.empty(
      TodayPrayerReference(
        ownerId: 'owner-a',
        city: null,
        timeZoneId: null,
        localDate: null,
        nextName: null,
        nextUtc: null,
        followingName: null,
        followingUtc: null,
        nowUtc: DateTime.utc(2026, 6, 21),
      ),
    );
    Widget card(TodaySection<TodayPrayerReference> section) => MaterialApp(
      supportedLocales: FoundationLocalizations.supportedLocales,
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      home: Scaffold(
        body: TodayPrayerCard(colors: AppColors.light, prayer: section),
      ),
    );
    await tester.pumpWidget(card(setup));
    final copy = FoundationLocalizations.of(
      tester.element(find.byType(TodayPrayerCard)),
    );
    expect(find.text(copy.prayerSetupBody), findsOneWidget);
    expect(find.text(copy.dashboardNextPrayer), findsNothing);
    await tester.pumpWidget(
      card(
        TodaySection.unavailable(
          AppFailure.recoverable(
            category: AppFailureCategory.network,
            messageKey: 'prayerScheduleUnavailable',
            occurredAt: DateTime.utc(2026),
          ),
        ),
      ),
    );
    expect(find.text(copy.prayerScheduleUnavailable), findsOneWidget);
    expect(find.text(copy.dashboardNextPrayer), findsNothing);
  });

  testWidgets('Home shows owner Prayer instants without sample values', (
    tester,
  ) async {
    final section = TodaySection.available(
      TodayPrayerReference(
        ownerId: 'owner-a',
        city: 'Dubai',
        timeZoneId: 'Asia/Dubai',
        localDate: '2026-06-21',
        nextName: PrayerName.dhuhr,
        nextUtc: DateTime.utc(2026, 6, 21, 8, 15),
        followingName: PrayerName.asr,
        followingUtc: DateTime.utc(2026, 6, 21, 11, 30),
        nowUtc: DateTime.utc(2026, 6, 21, 8),
        localFallback: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TodayPrayerCard(colors: AppColors.light, prayer: section),
        ),
      ),
    );
    final copy = FoundationLocalizations.of(
      tester.element(find.byType(TodayPrayerCard)),
    );
    expect(find.text('Dubai'), findsOneWidget);
    expect(find.text(copy.prayerDhuhr), findsOneWidget);
    expect(find.text('12:15 PM'), findsOneWidget);
    expect(find.text('00:15:00'), findsOneWidget);
    expect(find.text(copy.dashboardSampleBadge), findsNothing);
    expect(find.text(copy.prayerSourceLocal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prayer metric and quick hub use real state and route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state =
        TodayState.loading(
          TodayScope.account(accountId: 'owner-a', generation: 0),
          TodayCalendar(
            localDate: TodayLocalDate(2026, 6, 21),
            nowUtc: DateTime.utc(2026, 6, 21, 12),
            utcOffsetMinutes: 0,
            dayStartUtc: DateTime.utc(2026, 6, 21),
            nextDayStartUtc: DateTime.utc(2026, 6, 22),
            projectionRevision: 0,
          ),
          prayerEnabled: true,
        ).copyWith(
          xp: TodaySection.available(
            TodayXpSummary(
              awards: [
                TodayAwardReference(
                  ownerId: 'owner-a',
                  source: 'prayer_done',
                  sourceId: 'fajr',
                  amount: 10,
                  awardedAtUtc: DateTime.utc(2026, 6, 21, 12),
                ),
              ],
              amount: 10,
            ),
          ),
          prayer: TodaySection.available(
            TodayPrayerReference(
              ownerId: 'owner-a',
              city: 'Cairo',
              timeZoneId: 'Africa/Cairo',
              localDate: '2026-06-21',
              nextName: PrayerName.asr,
              nextUtc: DateTime.utc(2026, 6, 21, 13),
              followingName: PrayerName.maghrib,
              followingUtc: DateTime.utc(2026, 6, 21, 16),
              nowUtc: DateTime.utc(2026, 6, 21, 12),
              completedCount: 2,
              reportsAvailable: true,
              unconfirmedReportIds: const ['fajr'],
            ),
          ),
        );
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final strings = resolveTodayStrings(context);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TodayProgressHero(
                      state: state,
                      strings: strings,
                      colors: AppColors.light,
                      onOpenPrayer: () => opens++,
                    ),
                    TodayQuickHubs(
                      colors: AppColors.light,
                      onPrayer: () => opens++,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('10 XP · Awaiting sync confirmation'), findsOneWidget);
    expect(find.text('4/5'), findsNothing);
    await tester.tap(find.text('2/5'));
    await tester.pump();
    final copy = FoundationLocalizations.of(
      tester.element(find.byType(TodayQuickHubs)),
    );
    await tester.tap(find.text(copy.prayerTitle));
    expect(opens, 2);
    expect(tester.takeException(), isNull);
  });
}
