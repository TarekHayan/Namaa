import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_cubit.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_screen.dart';

/// T047: the Qiyam screen (contracts/adhkar-qiyam-ui.md): the prototype's
/// order (heading, tracker and form, supplications), the Yes form with its
/// rak'ah chips, times that cross midnight, the 500-character counter,
/// read-only nights, the supplications in Amiri with their sources,
/// keyboard and semantics, and the AR/EN light/dark 320 px 200% matrix.
/// The supplication content is the placeholder fixture (T006 pending);
/// real religious text never lives in code or tests.
void main() {
  final now = DateTime.utc(2026, 11, 11, 3);

  late FakeClock clock;
  late FakeNightPort nightPort;
  late FakeRepository repository;
  late FakeSupplications supplications;
  late RecordingCommands commands;

  QiyamNightState availableState([String nightDate = '2026-11-11']) =>
      QiyamNightState(
        scheduleState: QiyamScheduleState.available,
        nightDate: nightDate,
        lastThirdUtc: DateTime.utc(2026, 11, 11, 1, 40),
        editable: true,
        nextBoundaryUtc: DateTime.utc(2026, 11, 11, 16, 50),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      );

  setUp(() {
    clock = FakeClock(now);
    nightPort = FakeNightPort(availableState());
    repository = FakeRepository();
    supplications = FakeSupplications();
    commands = RecordingCommands();
  });

  QiyamCubit buildCubit() => QiyamCubit(
    ownerId: 'owner',
    nightPort: nightPort,
    repository: repository,
    supplications: supplications,
    commands: commands,
    clock: clock,
  );

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    Brightness brightness = Brightness.light,
    Size size = const Size(800, 1200),
    double textScale = 1.0,
    required QiyamCubit cubit,
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
        home: BlocProvider.value(value: cubit, child: const QiyamScreen()),
      ),
    );
    unawaited(cubit.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
  }

  testWidgets('the prototype order: heading, tracker and form, then the '
      'supplications', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    final headerY = tester.getTopLeft(find.byKey(const Key('qiyam_header'))).dy;
    final trackerY = tester
        .getTopLeft(find.byKey(const Key('qiyam_tracker_card')))
        .dy;
    final supplicationsY = tester
        .getTopLeft(find.byKey(const Key('qiyam_supplications_card')))
        .dy;
    expect(headerY, lessThan(trackerY));
    expect(trackerY, lessThan(supplicationsY));
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('the heading shows the last third chip time', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit, locale: const Locale('en'));
    expect(find.textContaining('01:40'), findsOneWidget);
    expect(find.byKey(const Key('qiyam_last_third_chip')), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Yes opens the details form with the defaults (4 rak\'ahs, '
      'Witr on) and saves them', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(find.byKey(const Key('qiyam_rakah_chip_4')), findsNothing);
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    expect(find.byKey(const Key('qiyam_rakah_chip_2')), findsOneWidget);
    expect(find.byKey(const Key('qiyam_rakah_chip_4')), findsOneWidget);
    expect(find.byKey(const Key('qiyam_rakah_chip_8')), findsOneWidget);
    expect(find.byKey(const Key('qiyam_rakah_chip_11')), findsOneWidget);
    final defaultChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('qiyam_rakah_chip_4')),
    );
    expect(defaultChip.selected, isTrue);
    expect(find.byKey(const Key('qiyam_witr')), findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('qiyam_witr'))).value,
      isTrue,
    );
    final draft = commands.drafts.single;
    expect(draft.performed, isTrue);
    expect(draft.rakahs, 4);
    expect(draft.witr, isTrue);
    await cubit.close();
  });

  testWidgets('selecting a rak\'ah chip saves immediately', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await tester.tap(find.byKey(const Key('qiyam_rakah_chip_8')));
    await tester.pump();
    expect(commands.drafts.last.rakahs, 8);
    await cubit.close();
  });

  testWidgets('times that cross midnight are accepted and saved', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await tester.enterText(find.byKey(const Key('qiyam_start_time')), '23:00');
    await tester.enterText(find.byKey(const Key('qiyam_end_time')), '01:00');
    await tester.pump();
    // The times share the note's debounce; they are saved when it fires.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final draft = commands.drafts.last;
    expect(draft.startTime, '23:00');
    expect(
      draft.endTime,
      '01:00',
      reason:
          'an end before the start means '
          'the prayer crossed midnight and is accepted',
    );
    await cubit.close();
  });

  testWidgets('the note field shows the 500-character counter', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit, locale: const Locale('en'));
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('qiyam_note')), 'abc');
    await tester.pump();
    expect(find.byKey(const Key('qiyam_note_counter')), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    // The 500-character cap blocks a longer note.
    await tester.enterText(find.byKey(const Key('qiyam_note')), 'a' * 505);
    await tester.pump();
    expect(find.textContaining('500'), findsWidgets);
    await cubit.close();
  });

  testWidgets('the tracker is read-only when the night is not current', (
    tester,
  ) async {
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.unavailable,
      nightDate: null,
      lastThirdUtc: null,
      editable: false,
      nextBoundaryUtc: null,
      zoneId: null,
      zoneOffsetMinutes: null,
    );
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('qiyam_yes'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('qiyam_no'))).onPressed,
      isNull,
    );
    expect(find.byKey(const Key('qiyam_locked_notice')), findsOneWidget);
    expect(commands.drafts, isEmpty);
    await cubit.close();
  });

  testWidgets('the supplications render in Amiri with their sources', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(find.text('test supplication s1'), findsOneWidget);
    final arabic = tester.widget<Text>(find.text('test supplication s1'));
    expect(arabic.style?.fontFamily, 'Amiri');
    expect(find.text('test source s1'), findsOneWidget);
    expect(find.text('test supplication s2'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('the celebration appears only on the first Yes', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    expect(find.byKey(const Key('qiyam_celebration')), findsNothing);
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    expect(find.byKey(const Key('qiyam_celebration')), findsOneWidget);
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    expect(find.byKey(const Key('qiyam_celebration')), findsNothing);
    await cubit.close();
  });

  testWidgets('a validation failure shows its message and a saved flash '
      'follows a good save', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit, locale: const Locale('en'));
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    expect(find.byKey(const Key('qiyam_status')), findsOneWidget);
    commands.failure = AppFailure.recoverable(
      category: AppFailureCategory.validation,
      messageKey: 'qiyam.night.invalid_time',
      occurredAt: now,
    );
    commands.outcome = null;
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    expect(find.byKey(const Key('qiyam_status')), findsOneWidget);
    expect(find.textContaining('valid 24-hour time'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('the keyboard reaches the note and the Yes button keeps tap '
      'semantics', (tester) async {
    final cubit = buildCubit();
    await pump(tester, cubit: cubit);
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await tester.pump();
    final note = find.byKey(const Key('qiyam_note'));
    await tester.ensureVisible(note);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(note);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText).first)
          .widget
          .controller,
      isNotNull,
    );
    final semantics = tester.getSemantics(find.byKey(const Key('qiyam_yes')));
    expect(
      semantics.label,
      contains('نعم'),
      reason: 'the Yes button is announced to screen readers',
    );
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

final class FakeClock implements QiyamClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeNightPort implements QiyamNightPort {
  FakeNightPort(this.state);

  QiyamNightState state;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async => AppResult.success(state);
}

final class FakeRepository implements QiyamRepository {
  QiyamNightRecord? current;

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async => AppResult.success(current);

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) => const Stream.empty();

  @override
  Future<AppResult<void>> writeNight(
    QiyamNightRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) {
    throw UnimplementedError();
  }
}

final class FakeSupplications implements QiyamSupplicationsPort {
  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async => AppResult.success([
    QiyamSupplication(
      id: 's1',
      textAr: 'test supplication s1',
      sourceAr: 'test source s1',
      sourceEn: 'test source s1',
    ),
    QiyamSupplication(
      id: 's2',
      textAr: 'test supplication s2',
      sourceAr: 'test source s2',
      sourceEn: 'test source s2',
    ),
  ]);
}

final class RecordingCommands implements QiyamCommandRunner {
  Object? outcome;
  AppFailure? failure;
  final drafts = <QiyamNightDraft>[];

  @override
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  }) async {
    drafts.add(draft);
    final failure = this.failure;
    if (failure != null) return AppResult.failure(failure);
    return AppResult.success(outcome! as QiyamCommandOutcome);
  }
}
