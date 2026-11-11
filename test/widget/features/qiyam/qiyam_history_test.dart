import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
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
import 'package:namma_project/features/qiyam/presentation/widgets/qiyam_history_section.dart';

/// T054: the Qiyam history section and the streak chip (contracts/
/// adhkar-qiyam-ui.md): past nights newest first and read-only, "Prayed ·
/// n rak'ahs · Witr" / "Did not pray" / "Not recorded" — the word "missed"
/// never appears — "Load more" fetching the next page only, the streak
/// chip separate from every other streak, and the side column at
/// ≥ 1024 px against the single phone column.
void main() {
  final now = DateTime.utc(2026, 11, 11, 3);

  QiyamNightRecord record(
    String nightDate, {
    bool performed = true,
    int? rakahs = 4,
    bool witr = true,
  }) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: nightDate,
    recordId: 'record:$nightDate',
    performed: performed,
    rakahs: performed ? rakahs : null,
    witr: performed ? witr : false,
    startTime: performed ? '01:00' : null,
    endTime: performed ? '02:00' : null,
    note: null,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: now,
    updatedAt: now,
    lastAcknowledgedUpdatedAt: null,
  );

  List<QiyamHistoryEntry> page() => [
    QiyamHistoryEntry(nightDate: '2026-11-10', record: record('2026-11-10')),
    QiyamHistoryEntry(
      nightDate: '2026-11-09',
      record: record('2026-11-09', performed: false),
    ),
    const QiyamHistoryEntry(nightDate: '2026-11-08'),
  ];

  Future<void> pumpSection(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    required List<QiyamHistoryEntry> entries,
    bool loading = false,
    bool failed = false,
    bool complete = false,
    required VoidCallback onLoadMore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: QiyamHistorySection(
              copy: QiyamStrings(FoundationLocalizations.of(context)),
              locale: locale.languageCode,
              entries: entries,
              loading: loading,
              failed: failed,
              complete: complete,
              onLoadMore: onLoadMore,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('entries render newest first with their states', (tester) async {
    var loadMoreCalls = 0;
    await pumpSection(
      tester,
      entries: page(),
      onLoadMore: () => loadMoreCalls++,
    );
    final prayed = tester.getTopLeft(find.text("Prayed · 4 rak'ahs · Witr"));
    final didNotPray = tester.getTopLeft(find.text('Did not pray'));
    final notRecorded = tester.getTopLeft(find.text('Not recorded'));
    expect(prayed.dy, lessThan(didNotPray.dy), reason: 'newest first');
    expect(didNotPray.dy, lessThan(notRecorded.dy));
    expect(loadMoreCalls, 0);
  });

  testWidgets('the word "missed" never appears in any state', (tester) async {
    await pumpSection(tester, entries: page(), onLoadMore: () {});
    expect(find.textContaining('missed'), findsNothing);
    expect(find.textContaining('Missed'), findsNothing);
  });

  testWidgets('the history is read-only: no text fields inside the section', (
    tester,
  ) async {
    await pumpSection(tester, entries: page(), onLoadMore: () {});
    expect(
      find.descendant(
        of: find.byKey(const Key('qiyam_history_section')),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('qiyam_history_section')),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );
  });

  testWidgets('"Load more" fetches the next page only and disappears at the '
      'end', (tester) async {
    var loadMoreCalls = 0;
    await pumpSection(
      tester,
      entries: page(),
      onLoadMore: () => loadMoreCalls++,
    );
    expect(find.byKey(const Key('qiyam_load_more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('qiyam_load_more')));
    expect(loadMoreCalls, 1);
    await pumpSection(
      tester,
      entries: page(),
      complete: true,
      onLoadMore: () => loadMoreCalls++,
    );
    expect(find.byKey(const Key('qiyam_load_more')), findsNothing);
    expect(loadMoreCalls, 1);
  });

  testWidgets('a failed page fetch shows the failure, not an empty history', (
    tester,
  ) async {
    await pumpSection(tester, entries: page(), failed: true, onLoadMore: () {});
    expect(find.byKey(const Key('qiyam_history_failed')), findsOneWidget);
    expect(find.text('Did not pray'), findsOneWidget);
  });

  testWidgets('a witr-less night shows "Prayed" without the Witr part', (
    tester,
  ) async {
    await pumpSection(
      tester,
      entries: [
        QiyamHistoryEntry(
          nightDate: '2026-11-10',
          record: record('2026-11-10', witr: false),
        ),
      ],
      onLoadMore: () {},
    );
    expect(find.text("Prayed · 4 rak'ahs"), findsOneWidget);
    expect(find.textContaining('Witr'), findsNothing);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    required QiyamCubit cubit,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: ThemeData(useMaterial3: true),
        home: BlocProvider.value(value: cubit, child: const QiyamScreen()),
      ),
    );
    unawaited(cubit.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
  }

  testWidgets('the history sits in a side column at ≥ 1024 px and below the '
      'supplications on the phone', (tester) async {
    final repository = FakeRepository()
      ..streakToReturn = 3
      ..historyPage = page();
    final cubit = buildCubit(repository);
    await pumpScreen(tester, cubit: cubit, size: const Size(1200, 900));
    final historyTop = tester
        .getTopLeft(find.byKey(const Key('qiyam_history_section')))
        .dy;
    final headerTop = tester
        .getTopLeft(find.byKey(const Key('qiyam_header')))
        .dy;
    expect(
      historyTop,
      headerTop,
      reason: 'on desktop the history is a side column beside the main one',
    );
    expect(find.byKey(const Key('qiyam_streak_chip')), findsOneWidget);
    await cubit.close();

    final phoneRepository = FakeRepository()
      ..streakToReturn = 3
      ..historyPage = page();
    final phoneCubit = buildCubit(phoneRepository);
    await pumpScreen(tester, cubit: phoneCubit, size: const Size(800, 1200));
    final phoneHistory = tester
        .getTopLeft(find.byKey(const Key('qiyam_history_section')))
        .dy;
    final supplications = tester
        .getTopLeft(find.byKey(const Key('qiyam_supplications_card')))
        .dy;
    expect(
      phoneHistory,
      greaterThan(supplications),
      reason: 'on the phone the history follows the supplications',
    );
    await phoneCubit.close();
  });

  testWidgets('the streak chip shows the derived streak; a failed read shows '
      'the failure and never 0', (tester) async {
    final repository = FakeRepository()..streakToReturn = 6;
    final cubit = buildCubit(repository);
    await pumpScreen(tester, cubit: cubit, size: const Size(800, 1200));
    expect(find.text('سلسلة القيام: 6'), findsOneWidget);
    await cubit.close();

    final failing = FakeRepository()..failStreak = true;
    final failingCubit = buildCubit(failing);
    await pumpScreen(tester, cubit: failingCubit, size: const Size(800, 1200));
    expect(find.byKey(const Key('qiyam_streak_chip')), findsNothing);
    expect(find.byKey(const Key('qiyam_streak_failed')), findsOneWidget);
    await failingCubit.close();
  });
}

QiyamCubit buildCubit(FakeRepository repository) {
  final cubit = QiyamCubit(
    ownerId: 'owner',
    nightPort: FakeNightPort(
      const QiyamNightState(
        scheduleState: QiyamScheduleState.available,
        nightDate: '2026-11-11',
        lastThirdUtc: null,
        editable: true,
        nextBoundaryUtc: null,
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      ),
    ),
    repository: repository,
    supplications: const FakeSupplications(),
    commands: FakeCommands(),
    clock: FakeClock(DateTime.utc(2026, 11, 11, 3)),
  );
  return cubit;
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
  int streakToReturn = 0;
  bool failStreak = false;
  List<QiyamHistoryEntry> historyPage = const [];
  bool historyHasMore = false;

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async => const AppResult.success(null);

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) => const Stream.empty();

  @override
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) async {
    if (failStreak) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'qiyam.night.store_failed',
          occurredAt: DateTime.utc(2026, 11, 11, 3),
        ),
      );
    }
    return AppResult.success(streakToReturn);
  }

  @override
  Future<AppResult<QiyamHistoryPage>> history({
    required String accountId,
    required String before,
    int limit = 30,
  }) async => AppResult.success(
    QiyamHistoryPage(entries: historyPage, hasMore: historyHasMore),
  );

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
  const FakeSupplications();

  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async => const AppResult.success([]);
}

final class FakeCommands implements QiyamCommandRunner {
  @override
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  }) async => AppResult.success(const QiyamNightSaved(firstPerformed: false));
}
