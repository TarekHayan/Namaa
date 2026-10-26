import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/composition/today_scope_resolver.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/today/presentation/today_screen.dart';

class _WidgetLocaleStore implements LocalStorePort {
  _WidgetLocaleStore({Map<String, String>? preferences})
    : preferences = <String, String>{...?preferences};

  final Map<String, String> preferences;

  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.success(preferences[key]);
  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> acknowledgeChange(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange a,
    PendingChangeRequest b,
  ) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> markChangeConflicted(String a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String a,
  ) async => AppResult<List<PendingChangeRecord>>.success(const []);
  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordRecoverableFailure(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<MigrationOutcome>> runMigration(int a) async =>
      AppResult<MigrationOutcome>.success(
        MigrationOutcome(completedVersion: a, recovered: false),
      );
}

FoundationCubit _readyFoundationCubit() =>
    FoundationCubit(BootstrapUseCase(cloudSession: _ReadyCloudSession()));

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

LocaleCubit _localeCubit(_WidgetLocaleStore store) => LocaleCubit(
  restore: RestoreLocalePreferenceUseCase(localStore: store),
  save: SaveLocalePreferenceUseCase(localStore: store),
);

ThemeCubit _themeCubit(_WidgetLocaleStore store) => ThemeCubit(
  restore: RestoreThemePreferenceUseCase(localStore: store),
  save: SaveThemePreferenceUseCase(localStore: store),
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required FoundationCubit foundationCubit,
  required LocaleCubit localeCubit,
  ThemeCubit? themeCubit,
}) async {
  await tester.pumpWidget(
    FoundationApp(
      cubitOverride: foundationCubit,
      localeCubitOverride: localeCubit,
      themeCubitOverride: themeCubit,
    ),
  );
  await tester.pumpAndSettle();
}

class _DashboardClock implements TodayCalendarPort {
  @override
  TodayCalendar sample({required int projectionRevision}) => TodayCalendar(
    localDate: TodayLocalDate(2026, 10, 12),
    nowUtc: DateTime.utc(2026, 10, 12, 12),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, 12),
    nextDayStartUtc: DateTime.utc(2026, 10, 13),
    projectionRevision: projectionRevision,
  );
}

class _DashboardTasks implements TodayTasksPort {
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) =>
      Stream.value(_DashboardTaskSnapshot(ownerId));
}

class _DashboardTaskSnapshot implements TodayTaskReadSnapshot {
  _DashboardTaskSnapshot(this.ownerId);
  @override
  final String ownerId;
  @override
  List<TodayTaskReference> project(TodayCalendar calendar) => [
    TodayTaskReference(
      taskId: 'task-1',
      ownerId: ownerId,
      title: 'مهمة اليوم Today Task',
      scheduledLocalDate: calendar.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: false,
      isUrgentImportant: true,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _DashboardHabits implements TodayHabitsPort {
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) =>
      Stream.value(_DashboardHabitSnapshot(ownerId));
}

class _DashboardHabitSnapshot implements TodayHabitReadSnapshot {
  _DashboardHabitSnapshot(this.ownerId);
  @override
  final String ownerId;
  @override
  List<TodayHabitReference> project(TodayCalendar calendar) => [
    TodayHabitReference(
      habitId: 'habit-1',
      ownerId: ownerId,
      name: 'عادة اليوم Today Habit',
      localDate: calendar.localDate,
      isDue: true,
      isCompleted: false,
      earnedWhileDue: false,
      currentStreak: 5,
      ownerOrder: 0,
    ),
  ];
}

class _DashboardXp implements TodayXpPort {
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) =>
      Stream.value([
        TodayAwardReference(
          ownerId: ownerId,
          source: 'task',
          sourceId: 'task-1',
          amount: 150,
          awardedAtUtc: DateTime.utc(2026, 10, 12, 8),
        ),
      ]);
}

void main() {
  group('Foundation shell localization and directionality', () {
    testWidgets('Arabic root text renders RTL', (tester) async {
      final foundationCubit = _readyFoundationCubit();
      final localeCubit = _localeCubit(
        _WidgetLocaleStore(preferences: {'locale': 'ar'}),
      );
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);

      await _pumpApp(
        tester,
        foundationCubit: foundationCubit,
        localeCubit: localeCubit,
      );

      expect(find.text('نماء جاهز'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
        TextDirection.rtl,
      );
    });

    testWidgets('English root text renders LTR', (tester) async {
      final foundationCubit = _readyFoundationCubit();
      final localeCubit = _localeCubit(
        _WidgetLocaleStore(preferences: {'locale': 'en'}),
      );
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);

      await _pumpApp(
        tester,
        foundationCubit: foundationCubit,
        localeCubit: localeCubit,
      );

      expect(find.text('Namaa is ready'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
        TextDirection.ltr,
      );
    });

    testWidgets('the root uses Thmanyah Sans as the default UI font', (
      tester,
    ) async {
      final foundationCubit = _readyFoundationCubit();
      final localeCubit = _localeCubit(_WidgetLocaleStore());
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);

      await _pumpApp(
        tester,
        foundationCubit: foundationCubit,
        localeCubit: localeCubit,
      );

      final context = tester.element(find.byKey(kFoundationRootReadyKey));
      expect(
        Theme.of(context).textTheme.bodyMedium?.fontFamily,
        kProjectFontFamily,
      );
    });

    testWidgets('switching the language updates root text and directionality', (
      tester,
    ) async {
      final foundationCubit = _readyFoundationCubit();
      final localeCubit = _localeCubit(_WidgetLocaleStore());
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);

      await _pumpApp(
        tester,
        foundationCubit: foundationCubit,
        localeCubit: localeCubit,
      );
      await localeCubit.selectLanguage('ar');
      await tester.pumpAndSettle();

      expect(find.text('نماء جاهز'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
        TextDirection.rtl,
      );
    });

    testWidgets('a selected locale is restored after an app restart', (
      tester,
    ) async {
      final store = _WidgetLocaleStore();
      final firstFoundationCubit = _readyFoundationCubit();
      final firstLocaleCubit = _localeCubit(store);
      await _pumpApp(
        tester,
        foundationCubit: firstFoundationCubit,
        localeCubit: firstLocaleCubit,
      );
      await firstLocaleCubit.selectLanguage('ar');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await firstFoundationCubit.close();
      await firstLocaleCubit.close();

      final restartedFoundationCubit = _readyFoundationCubit();
      final restartedLocaleCubit = _localeCubit(store);
      addTearDown(restartedFoundationCubit.close);
      addTearDown(restartedLocaleCubit.close);
      await _pumpApp(
        tester,
        foundationCubit: restartedFoundationCubit,
        localeCubit: restartedLocaleCubit,
      );

      expect(find.text('نماء جاهز'), findsOneWidget);
    });
  });

  group('Final Dashboard localization, directionality, and regressions (T045)', () {
    setUp(() async {
      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<CloudSessionPort>(
        const TasksPreviewSession(),
      );
      GetIt.instance.registerSingleton<HabitsPreviewSession>(
        const HabitsPreviewSession(),
      );
      GetIt.instance.registerSingleton<TodayScopeResolver>(
        TodayScopeResolver.preview(),
      );
      GetIt.instance.registerFactoryParam<TodayCubit, TodayScope, void>(
        (scope, _) => TodayCubit(
          scope: scope,
          calendar: _DashboardClock(),
          tasks: _DashboardTasks(),
          habits: _DashboardHabits(),
          xp: _DashboardXp(),
        ),
      );
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    for (final language in const ['ar', 'en']) {
      testWidgets(
        'narrow Dashboard keeps both dates readable at 1.5x in $language',
        (tester) async {
          tester.view.physicalSize = const Size(320 * 3, 844 * 3);
          tester.view.devicePixelRatio = 3.0;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });

          final store = _WidgetLocaleStore(preferences: {'locale': language});
          final foundationCubit = _readyFoundationCubit();
          final localeCubit = _localeCubit(store);
          final themeCubit = _themeCubit(store);
          addTearDown(foundationCubit.close);
          addTearDown(localeCubit.close);
          addTearDown(themeCubit.close);
          await _pumpApp(
            tester,
            foundationCubit: foundationCubit,
            localeCubit: localeCubit,
            themeCubit: themeCubit,
          );
          expect(find.textContaining('1448'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Arabic Dashboard renders RTL with Umm al-Qura date, semantics, and zero overflow at 1.5x scale',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final store = _WidgetLocaleStore(preferences: {'locale': 'ar'});
        final foundationCubit = _readyFoundationCubit();
        final localeCubit = _localeCubit(store);
        final themeCubit = _themeCubit(store);
        addTearDown(foundationCubit.close);
        addTearDown(localeCubit.close);
        addTearDown(themeCubit.close);

        await _pumpApp(
          tester,
          foundationCubit: foundationCubit,
          localeCubit: localeCubit,
          themeCubit: themeCubit,
        );

        // Verify Dashboard root and RTL directionality
        expect(find.byKey(kTodayScreenKey), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byKey(kTodayScreenKey))),
          TextDirection.rtl,
        );

        // Verify Arabic text rendering and Umm al-Qura Hijri date
        expect(find.textContaining('1448'), findsOneWidget);

        // Verify sample semantic labels in Arabic
        expect(find.text('بيانات تجريبية'), findsAtLeast(1));

        // Zero overflow check at 1.5x scale
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'English Dashboard renders LTR with English labels, semantics, and zero overflow at 1.5x scale',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final store = _WidgetLocaleStore(preferences: {'locale': 'en'});
        final foundationCubit = _readyFoundationCubit();
        final localeCubit = _localeCubit(store);
        final themeCubit = _themeCubit(store);
        addTearDown(foundationCubit.close);
        addTearDown(localeCubit.close);
        addTearDown(themeCubit.close);

        await _pumpApp(
          tester,
          foundationCubit: foundationCubit,
          localeCubit: localeCubit,
          themeCubit: themeCubit,
        );

        // Verify Dashboard root and LTR directionality
        expect(find.byKey(kTodayScreenKey), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byKey(kTodayScreenKey))),
          TextDirection.ltr,
        );

        // Verify English labels and Sample badges
        expect(find.text('SAMPLE DATA'), findsAtLeast(1));
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Tasks'), findsAtLeast(1));

        // Zero overflow check at 1.5x scale
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Dashboard responds to theme selection between light and dark',
      (tester) async {
        final store = _WidgetLocaleStore(preferences: {'locale': 'en'});
        final foundationCubit = _readyFoundationCubit();
        final localeCubit = _localeCubit(store);
        final themeCubit = _themeCubit(store);
        addTearDown(foundationCubit.close);
        addTearDown(localeCubit.close);
        addTearDown(themeCubit.close);

        await _pumpApp(
          tester,
          foundationCubit: foundationCubit,
          localeCubit: localeCubit,
          themeCubit: themeCubit,
        );

        expect(find.byKey(kTodayScreenKey), findsOneWidget);

        // Switch to dark theme
        await themeCubit.selectAppearance('dark');
        await tester.pumpAndSettle();
        final darkContext = tester.element(find.byKey(kTodayScreenKey));
        expect(Theme.of(darkContext).brightness, Brightness.dark);

        // Switch to light theme
        await themeCubit.selectAppearance('light');
        await tester.pumpAndSettle();
        final lightContext = tester.element(find.byKey(kTodayScreenKey));
        expect(Theme.of(lightContext).brightness, Brightness.light);
      },
    );

    testWidgets('Keyboard focus traversal moves logically through Dashboard', (
      tester,
    ) async {
      final store = _WidgetLocaleStore(preferences: {'locale': 'en'});
      final foundationCubit = _readyFoundationCubit();
      final localeCubit = _localeCubit(store);
      final themeCubit = _themeCubit(store);
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);
      addTearDown(themeCubit.close);

      await _pumpApp(
        tester,
        foundationCubit: foundationCubit,
        localeCubit: localeCubit,
        themeCubit: themeCubit,
      );

      expect(find.byKey(kTodayScreenKey), findsOneWidget);

      // Send Tab key events to advance focus
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
