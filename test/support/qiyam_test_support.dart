import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_conflict_evidence.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_cubit.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_screen.dart';

/// Shared fakes and a pump helper for the Qiyam widget tests. The
/// supplication content is a placeholder (never real religious text, which
/// lives only in the reviewed catalog asset).
final DateTime kQiyamTestNow = DateTime.utc(2026, 11, 11, 3);

QiyamNightState qiyamAvailable([String nightDate = '2026-11-11']) =>
    QiyamNightState(
      scheduleState: QiyamScheduleState.available,
      nightDate: nightDate,
      lastThirdUtc: DateTime.utc(2026, 11, 11, 1, 40),
      editable: true,
      nextBoundaryUtc: DateTime.utc(2026, 11, 11, 16, 50),
      zoneId: 'UTC',
      zoneOffsetMinutes: 0,
    );

/// No saved Prayer location: the night follows the device rule, there is no
/// last third, and recording works.
QiyamNightState qiyamSetupRequired([String nightDate = '2026-11-11']) =>
    QiyamNightState(
      scheduleState: QiyamScheduleState.setupRequired,
      nightDate: nightDate,
      lastThirdUtc: null,
      editable: true,
      nextBoundaryUtc: DateTime.utc(2026, 11, 11, 12),
      zoneId: 'UTC+02:00',
      zoneOffsetMinutes: 120,
    );

/// A saved schedule that cannot produce its instants: recording is paused.
const QiyamNightState kQiyamUnavailable = QiyamNightState(
  scheduleState: QiyamScheduleState.unavailable,
  nightDate: null,
  lastThirdUtc: null,
  editable: false,
  nextBoundaryUtc: null,
  zoneId: null,
  zoneOffsetMinutes: null,
);

QiyamNightRecord qiyamRecord(
  String nightDate, {
  bool performed = true,
  int? rakahs = 4,
  bool witr = true,
  String? startTime = '01:00',
  String? endTime = '02:00',
  String? note,
}) => QiyamNightRecord(
  accountId: 'owner',
  nightDate: nightDate,
  recordId: 'record:$nightDate',
  performed: performed,
  rakahs: performed ? rakahs : null,
  witr: performed ? witr : false,
  startTime: performed ? startTime : null,
  endTime: performed ? endTime : null,
  note: performed ? note : null,
  recordedZoneId: 'UTC',
  recordedOffsetMinutes: 0,
  createdAt: kQiyamTestNow,
  updatedAt: kQiyamTestNow,
  lastAcknowledgedUpdatedAt: null,
);

final class FakeQiyamClock implements QiyamClockPort {
  FakeQiyamClock([DateTime? now]) : _now = now ?? kQiyamTestNow;

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeQiyamNightPort implements QiyamNightPort {
  FakeQiyamNightPort(this.state);

  QiyamNightState state;

  /// When set, a resolution waits for it (to look at the loading state).
  Completer<void>? gate;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async {
    final pending = gate;
    if (pending != null) await pending.future;
    return AppResult.success(state);
  }
}

final class FakeQiyamRepository implements QiyamRepository {
  /// The stored record of the current night (what `readFresh` returns).
  QiyamNightRecord? current;
  int streakToReturn = 0;
  bool failStreak = false;
  bool failHistory = false;

  /// The recorded rows behind the history, keyed by night date.
  final Map<String, QiyamNightRecord> seeded = {};

  /// The `limit` of each history page the screen asked for, in order.
  final List<int> pageLimits = [];

  AppFailure _failure() => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'qiyam.night.store_failed',
    occurredAt: kQiyamTestNow,
  );

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async =>
      AppResult.success(current?.nightDate == nightDate ? current : null);

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) => const Stream.empty();

  @override
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) async => failStreak
      ? AppResult.failure(_failure())
      : AppResult.success(streakToReturn);

  @override
  Future<AppResult<QiyamHistoryPage>> history({
    required String accountId,
    required String before,
    int limit = 30,
  }) async {
    pageLimits.add(limit);
    if (failHistory) return AppResult.failure(_failure());
    final matching =
        seeded.values
            .where((row) => row.nightDate.compareTo(before) < 0)
            .toList()
          ..sort((a, b) => b.nightDate.compareTo(a.nightDate));
    final hasMore = matching.length > limit;
    return AppResult.success(
      QiyamHistoryPage(
        records: hasMore ? matching.sublist(0, limit) : matching,
        hasMore: hasMore,
      ),
    );
  }

  @override
  Future<AppResult<void>> writeNight(
    QiyamNightRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => throw UnimplementedError();
}

final class FakeQiyamSupplications implements QiyamSupplicationsPort {
  const FakeQiyamSupplications();

  /// A body long enough to need more than four lines on any phone.
  static String get longText => List.filled(24, 'supplication body').join(' ');

  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async => AppResult.success([
    QiyamSupplication(
      id: 's1',
      textAr: 'test s1 $longText',
      sourceAr: 'test source s1',
    ),
    QiyamSupplication(
      id: 's2',
      textAr: 'test s2 $longText',
      sourceAr: 'test source s2',
    ),
  ]);
}

/// Records every draft the cubit saves and answers with [outcome], or with
/// [failure] when set.
final class RecordingQiyamCommands implements QiyamCommandRunner {
  Object? outcome = const QiyamNightSaved(firstPerformed: false);
  AppFailure? failure;
  final drafts = <QiyamNightDraft>[];

  /// When set, a save waits for it (to look at the "Saving…" state).
  Completer<void>? gate;

  @override
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  }) async {
    drafts.add(draft);
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = this.failure;
    if (failure != null) return AppResult.failure(failure);
    return AppResult.success(outcome! as QiyamCommandOutcome);
  }
}

AppFailure qiyamPersistenceFailure() => AppFailure.recoverable(
  category: AppFailureCategory.persistence,
  messageKey: 'qiyam.night.save_failed',
  occurredAt: kQiyamTestNow,
);

AppFailure qiyamValidationFailure(String messageKey) => AppFailure.recoverable(
  category: AppFailureCategory.validation,
  messageKey: messageKey,
  occurredAt: kQiyamTestNow,
);

/// A widget test that closes its cubits before it ends (their night
/// boundary timer would otherwise be reported as pending).
void qiyamTestWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) => testWidgets(description, (tester) async {
  await body(tester);
  await QiyamHarness.closeAll();
});

/// Everything one Qiyam widget test needs, with the defaults of a normal
/// night: an available schedule, nothing recorded yet.
final class QiyamHarness {
  QiyamHarness({QiyamNightState? night})
    : nightPort = FakeQiyamNightPort(night ?? qiyamAvailable());

  final FakeQiyamNightPort nightPort;
  final repository = FakeQiyamRepository();
  final commands = RecordingQiyamCommands();
  final clock = FakeQiyamClock();

  static final List<QiyamCubit> _live = [];

  QiyamCubit buildCubit() {
    final cubit = QiyamCubit(
      ownerId: 'owner',
      nightPort: nightPort,
      repository: repository,
      supplications: const FakeQiyamSupplications(),
      commands: commands,
      clock: clock,
    );
    _live.add(cubit);
    return cubit;
  }

  /// Closes every cubit the test built, so no night-boundary timer is left
  /// pending when the test body ends.
  static Future<void> closeAll() async {
    final all = List<QiyamCubit>.of(_live);
    _live.clear();
    for (final cubit in all) {
      await cubit.close();
    }
  }

  /// Pumps the screen in the real app theme and loads [cubit]. The cubit is
  /// closed when the test ends.
  Future<void> pump(
    WidgetTester tester,
    QiyamCubit cubit, {
    Locale locale = const Locale('ar'),
    Brightness brightness = Brightness.light,
    Size size = const Size(390, 900),
    double textScale = 1.0,
    Stream<List<QiyamConflictEvidence>>? conflicts,
    VoidCallback? onOpenPrayerSetup,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    addTearDown(closeAll);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: QiyamScreen(
            conflicts: conflicts,
            onOpenPrayerSetup: onOpenPrayerSetup,
          ),
        ),
      ),
    );
    unawaited(cubit.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
  }

  /// Lets a debounce (and the save behind it) run.
  static Future<void> settle(
    WidgetTester tester, [
    Duration by = const Duration(milliseconds: 1100),
  ]) async {
    await tester.pump(by);
    await tester.pump();
  }
}
