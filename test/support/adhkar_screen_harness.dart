import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_conflicts_view.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_screen.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_cubit.dart';

import 'adhkar_test_support.dart';

/// The key of a marker the harness puts inside its stand-in shell: it is
/// visible with the page and gone while the full-screen reader covers it.
const Key kHarnessShellKey = Key('harness_shell');

/// Builds the real [AdhkarScreen] over the real [AdhkarCubit] with fake
/// ports, so a widget test drives the page, the reader and the sync page
/// through the same code the app runs.
///
/// The Cubit schedules a timer for the next period boundary, and a pending
/// timer fails a widget test before its tear-downs run, so a test defined
/// with [adhkarTestWidgets] has every Cubit the harness built closed at the
/// end of its own body.
final class AdhkarHarness {
  AdhkarHarness({
    AdhkarClockState? clock,
    Map<String, int>? counts,
    AdhkarCatalogPort? catalog,
  }) : day = FakeDay(counts ?? {'m1': 1}),
       times = FakeTimesPort(clock ?? morningClock()),
       catalog = catalog ?? FakeCatalog(),
       clock = FakeClock(DateTime.utc(2026, 11, 10, 9)) {
    commands = SimulatedCommands(day, fakeCatalogTargets);
  }

  final FakeDay day;
  final FakeTimesPort times;
  final AdhkarCatalogPort catalog;
  final FakeClock clock;
  late final SimulatedCommands commands;

  late AdhkarCubit cubit;
  GoRouter? router;

  AdhkarCubit buildCubit() => AdhkarCubit(
    ownerId: 'owner',
    times: times,
    catalog: catalog,
    repository: FakeRepository(day),
    commands: commands,
    clock: clock,
  );

  /// Pumps the screen. With [useRouter] the screen sits behind a `/adhkar`
  /// route above a Home route, with a stand-in shell that sends the device
  /// back to Home as the app's shell does.
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(400, 900),
    double textScale = 1.0,
    MyAdhkarCubit? myAdhkarCubit,
    AdhkarConflictsSource? conflicts,
    VoidCallback? onOpenPrayerSetup,
    bool useRouter = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    cubit = buildCubit();
    _open.add(cubit);
    Widget shell(BuildContext context, Widget page) => Stack(
      children: [
        Positioned.fill(child: page),
        const Positioned(
          left: 0,
          top: 0,
          child: SizedBox(key: kHarnessShellKey, width: 1, height: 1),
        ),
      ],
    );
    Widget screen(BuildContext context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        if (myAdhkarCubit != null) BlocProvider.value(value: myAdhkarCubit),
      ],
      child: AdhkarScreen(
        conflicts: conflicts,
        onOpenPrayerSetup: onOpenPrayerSetup,
        shellBuilder: (context, page) => useRouter
            ? PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) router!.go('/');
                },
                child: shell(context, page),
              )
            : shell(context, page),
      ),
    );
    final theme = ThemeData(brightness: brightness, useMaterial3: true);
    if (useRouter) {
      router = GoRouter(
        initialLocation: '/adhkar',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('home page'))),
          ),
          GoRoute(
            path: '/adhkar',
            builder: (context, state) => screen(context),
          ),
        ],
      );
      addTearDown(router!.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          key: UniqueKey(),
          locale: locale,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          theme: theme,
          routerConfig: router,
        ),
      );
    } else {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          locale: locale,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          theme: theme,
          home: Builder(builder: screen),
        ),
      );
    }
    unawaited(cubit.load());
    await settle(tester);
  }

  /// Lets the Cubit's futures and streams deliver.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
  }
}

final List<AdhkarCubit> _open = [];

/// A `testWidgets` that closes every harness Cubit when its body ends.
void adhkarTestWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      for (final cubit in _open) {
        await cubit.close();
      }
      _open.clear();
    }
  });
}
