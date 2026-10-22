import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/composition/today_scope_resolver.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
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

class _Preferences implements LocalStorePort {
  @override Future<AppResult<String?>> readPreference(String key) async => const AppResult.success(null);
  @override Future<AppResult<void>> savePreference(String key, String value) async => const AppResult.success(null);
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Clock implements TodayCalendarPort {
  @override TodayCalendar sample({required int projectionRevision}) => TodayCalendar(
    localDate: TodayLocalDate(2026, 10, 12), nowUtc: DateTime.utc(2026, 10, 12, 12), utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, 12), nextDayStartUtc: DateTime.utc(2026, 10, 13), projectionRevision: projectionRevision);
}
class _TaskSnapshot implements TodayTaskReadSnapshot {
  _TaskSnapshot(this.ownerId);
  @override final String ownerId;
  @override List<TodayTaskReference> project(TodayCalendar calendar) => [];
}
class _HabitSnapshot implements TodayHabitReadSnapshot {
  _HabitSnapshot(this.ownerId);
  @override final String ownerId;
  @override List<TodayHabitReference> project(TodayCalendar calendar) => [];
}
class _Tasks implements TodayTasksPort {
  @override Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => Stream.value(_TaskSnapshot(ownerId));
}
class _Habits implements TodayHabitsPort {
  @override Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) => Stream.value(_HabitSnapshot(ownerId));
}
class _Xp implements TodayXpPort {
  @override Stream<List<TodayAwardReference>> watchAwards(String ownerId) => Stream.value([]);
}
class _FailingSession implements CloudSessionPort {
  @override Future<AppResult<void>> initialize() async => AppResult.failure(AppFailure.blocking(
    category: AppFailureCategory.configuration, messageKey: 'foundation.bootstrap.blocking', occurredAt: DateTime.utc(2026, 10, 12)));
  @override Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();
  @override Future<AppResult<CloudSyncContext>> obtainSyncContext() async => AppResult.failure(AppFailure.blocking(
    category: AppFailureCategory.configuration, messageKey: 'foundation.bootstrap.blocking', occurredAt: DateTime.utc(2026, 10, 12)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<CloudSessionPort>(const TasksPreviewSession());
    GetIt.instance.registerSingleton<HabitsPreviewSession>(const HabitsPreviewSession());
    GetIt.instance.registerSingleton<TodayScopeResolver>(TodayScopeResolver.preview());
    GetIt.instance.registerFactoryParam<TodayCubit, TodayScope, void>((scope, _) => TodayCubit(
      scope: scope, calendar: _Clock(), tasks: _Tasks(), habits: _Habits(), xp: _Xp()));
  });
  tearDown(() => GetIt.instance.reset());

  Future<(FoundationCubit, LocaleCubit, ThemeCubit)> controls(CloudSessionPort session) async {
    final preferences = _Preferences();
    return (
      FoundationCubit(BootstrapUseCase(cloudSession: session)),
      LocaleCubit(restore: RestoreLocalePreferenceUseCase(localStore: preferences), save: SaveLocalePreferenceUseCase(localStore: preferences)),
      ThemeCubit(restore: RestoreThemePreferenceUseCase(localStore: preferences), save: SaveThemePreferenceUseCase(localStore: preferences)),
    );
  }

  testWidgets('preview ready root opens Today and preferences without sign-in', (tester) async {
    final (foundation, locale, theme) = await controls(const TasksPreviewSession());
    addTearDown(() async { await foundation.close(); await locale.close(); await theme.close(); });
    await tester.pumpWidget(FoundationApp(cubitOverride: foundation, localeCubitOverride: locale, themeCubitOverride: theme));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(kFoundationRootReadyKey), findsOneWidget);
    expect(find.byKey(kTodayScreenKey), findsOneWidget);
    expect(find.byKey(kTodayTasksNavigationKey), findsOneWidget);
    expect(find.byKey(kTodayHabitsNavigationKey), findsOneWidget);
    await tester.tap(find.byKey(kTodayPreferencesKey));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Foundation startup and failure shell never expose Today owner data', (tester) async {
    final (foundation, locale, theme) = await controls(_FailingSession());
    addTearDown(() async { await foundation.close(); await locale.close(); await theme.close(); });
    await tester.pumpWidget(FoundationApp(cubitOverride: foundation, localeCubitOverride: locale, themeCubitOverride: theme));
    expect(find.byKey(kFoundationRootStartupKey), findsOneWidget);
    await tester.pump();
    expect(find.byKey(kFoundationRootFailureKey), findsOneWidget);
    expect(find.byKey(kTodayScreenKey), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
