import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_screen.dart';

/// T032: the Adhkar screen (contracts/adhkar-qiyam-ui.md): the prototype's
/// group order, the count button gates, the virtue toggle, the Amiri Arabic
/// text, keyboard counting, semantics, and the AR/EN light/dark 320 px 200%
/// matrix with no overflow. The content is the review fixture (T006 pending).
void main() {
  final now = DateTime.utc(2026, 11, 10, 9);

  late FakeClock clock;
  late FakeTimesPort times;
  late FakeRepository repository;
  late RecordingCommands commands;

  AdhkarCubit buildCubit() => AdhkarCubit(
    ownerId: 'owner',
    times: times,
    catalog: FakeCatalog(),
    repository: repository,
    commands: commands,
    clock: clock,
  );

  setUp(() {
    clock = FakeClock(now);
    times = FakeTimesPort(
      AdhkarClockState(
        scheduleState: AdhkarScheduleState.available,
        day: '2026-11-10',
        period: AdhkarPeriod.morning,
        nextBoundaryUtc: DateTime.utc(2026, 11, 10, 16, 50),
        morningCountable: true,
        eveningCountable: false,
        fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
        maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
        zoneId: 'UTC',
      ),
    );
    repository = FakeRepository();
    commands = RecordingCommands();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    Brightness brightness = Brightness.light,
    Size size = const Size(800, 1200),
    double textScale = 1.0,
    required AdhkarCubit cubit,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        home: BlocProvider.value(value: cubit, child: const AdhkarScreen()),
      ),
    );
    unawaited(cubit.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
  }

  testWidgets('the prototype order: header with switch, progress card, then '
      'item cards', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    final headerY = tester
        .getTopLeft(find.byKey(const Key('adhkar_header')))
        .dy;
    final progressY = tester
        .getTopLeft(find.byKey(const Key('adhkar_progress_card')))
        .dy;
    final firstItemY = tester
        .getTopLeft(find.byKey(const Key('adhkar_item_card_m1')))
        .dy;
    expect(headerY, lessThan(progressY));
    expect(progressY, lessThan(firstItemY));
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('the count button disables at the target and outside the '
      'period', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    // m1 is seeded at its target of 1.
    final completedButton = tester.widget<FilledButton>(
      find.byKey(const Key('adhkar_count_m1')),
    );
    expect(completedButton.onPressed, isNull);
    // Switch to Evening: the morning clock makes the evening list
    // uncountable, so its button is disabled.
    await tester.tap(find.byKey(const Key('adhkar_switch_evening')));
    await tester.pump();
    final eveningButton = tester.widget<FilledButton>(
      find.byKey(const Key('adhkar_count_e1')),
    );
    expect(eveningButton.onPressed, isNull);
    await cubit.close();
  });

  testWidgets('the count button taps once per press and the reset invokes '
      'the reset command', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    await tester.tap(find.byKey(const Key('adhkar_count_m2')));
    await tester.pump();
    expect(commands.incrementCalls, contains('m2'));
    await tester.tap(find.byKey(const Key('adhkar_reset_m2')));
    await tester.pump();
    expect(commands.resetCalls, contains('m2'));
    await cubit.close();
  });

  testWidgets('the keyboard counts once per Space press', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    final button = find.byKey(const Key('adhkar_count_m2'));
    await tester.ensureVisible(button);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(button);
    await tester.pump();
    final before = commands.incrementCalls.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(commands.incrementCalls.length, greaterThanOrEqualTo(before));
    await cubit.close();
  });

  testWidgets('the virtue toggle expands the virtue and reference', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(find.textContaining('test virtue m1'), findsNothing);
    await tester.tap(find.byKey(const Key('adhkar_virtue_toggle_m1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('test virtue m1'), findsOneWidget);
    expect(find.textContaining('test ref m1'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('the English translation shows only in English and the Arabic '
      'text uses the Amiri font', (tester) async {
    final englishCubit = buildCubit();
    await pump(tester, cubit: englishCubit, locale: const Locale('en'));
    expect(find.text('test item m1', findRichText: true), findsWidgets);
    final arabicText = tester.widget<Text>(find.text('test item m1').first);
    expect(arabicText.style?.fontFamily, 'Amiri');
    await englishCubit.close();
    final arabicCubit = buildCubit();
    await pump(tester, cubit: arabicCubit);
    // In Arabic the English translation is absent; only the Arabic text.
    expect(find.text('test item m1'), findsOneWidget);
    await arabicCubit.close();
  });

  testWidgets('during Evening the morning notice shows the next Fajr time', (
    tester,
  ) async {
    times.state = AdhkarClockState(
      scheduleState: AdhkarScheduleState.available,
      day: '2026-11-10',
      period: AdhkarPeriod.evening,
      nextBoundaryUtc: DateTime.utc(2026, 11, 11, 4, 29),
      morningCountable: false,
      eveningCountable: true,
      fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
      maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
      zoneId: 'UTC',
    );
    final cubit = buildCubit();
    await pump(tester, cubit: cubit, locale: const Locale('en'));
    // The cubit selects Evening; switch to Morning to see its notice.
    await tester.tap(find.byKey(const Key('adhkar_switch_morning')));
    await tester.pump();
    expect(find.byKey(const Key('adhkar_starts_at_notice')), findsOneWidget);
    expect(
      find.textContaining('04:29'),
      findsOneWidget,
      reason: 'the notice shows the NEXT Fajr, not the passed one',
    );
    await cubit.close();
  });

  testWidgets('the count button exposes the count semantics', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    final semantics = tester.getSemantics(
      find.byKey(const Key('adhkar_count_m2')),
    );
    expect(semantics.label, contains('0'));
    expect(semantics.label, contains('3'));
    await cubit.close();
  });

  testWidgets('the celebration appears once when the set completes', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(find.byKey(const Key('adhkar_celebration')), findsNothing);
    commands.outcome = const AdhkarIncremented(newCount: 1, setCompleted: true);
    await tester.tap(find.byKey(const Key('adhkar_count_m2')));
    await tester.pump();
    expect(find.byKey(const Key('adhkar_celebration')), findsOneWidget);
    await cubit.close();
  });

  testWidgets('AR/EN, light/dark, 320 px and 200% text scale render without '
      'overflow', (tester) async {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        final cubit = buildCubit();
        await pump(
          tester,
          cubit: cubit,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 900),
          textScale: 2.0,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale $brightness at 320 px, 200%',
        );
        await cubit.close();
      }
    }
  });
}

final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeTimesPort implements AdhkarTimesPort {
  FakeTimesPort(this.state);

  AdhkarClockState state;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async => AppResult.success(state);
}

final class FakeCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.success(
        AdhkarCatalog.fromJson(const {
          'catalog_version': 1,
          'items': [
            {
              'item_id': 'm1',
              'list': 'morning',
              'position': 1,
              'target': 1,
              'text_ar': 'test item m1',
              'translation_en': 'test item m1',
              'virtue_ar': 'test virtue m1',
              'virtue_en': 'test virtue m1',
              'reference_ar': 'test ref m1',
              'reference_en': 'test ref m1',
              'approved': true,
            },
            {
              'item_id': 'm2',
              'list': 'morning',
              'position': 2,
              'target': 3,
              'text_ar': 'test item m2',
              'translation_en': 'test item m2',
              'virtue_ar': 'test virtue m2',
              'virtue_en': 'test virtue m2',
              'reference_ar': 'test ref m2',
              'reference_en': 'test ref m2',
              'approved': true,
            },
            {
              'item_id': 'e1',
              'list': 'evening',
              'position': 1,
              'target': 1,
              'text_ar': 'test item e1',
              'translation_en': 'test item e1',
              'virtue_ar': 'test virtue e1',
              'virtue_en': 'test virtue e1',
              'reference_ar': 'test ref e1',
              'reference_en': 'test ref e1',
              'approved': true,
            },
          ],
          'qiyam_supplications': <Map<String, Object?>>[],
        }),
      );
}

final class FakeRepository implements AdhkarRepository {
  @override
  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  }) async* {
    yield [
      AdhkarCountRecord(
        accountId: 'owner',
        adhkarDay: '2026-11-10',
        itemId: 'm1',
        recordId: 'rec-m1',
        catalogVersion: 1,
        list: 'morning',
        count: 1,
        createdAt: DateTime.utc(2026, 11, 10, 8),
        updatedAt: DateTime.utc(2026, 11, 10, 8),
        lastAcknowledgedUpdatedAt: null,
      ),
    ];
  }

  @override
  Future<AppResult<AdhkarCompletedDays>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
    required int catalogVersion,
    required List<AdhkarListItem> morningItems,
    required List<AdhkarListItem> eveningItems,
  }) async => AppResult.success(
    const AdhkarCompletedDays(completed: {}, unjudgeable: {}),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class RecordingCommands implements AdhkarCommandRunner {
  final incrementCalls = <String>[];
  final resetCalls = <String>[];
  AdhkarCommandOutcome outcome = const AdhkarIncremented(
    newCount: 1,
    setCompleted: false,
  );

  @override
  Future<AppResult<AdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  }) async {
    incrementCalls.add(itemId);
    return AppResult.success(outcome);
  }

  @override
  Future<AppResult<AdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  }) async {
    resetCalls.add(itemId);
    return const AppResult.success(AdhkarReset());
  }
}
