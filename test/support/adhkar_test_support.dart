import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// Fakes for the Adhkar screen and reader widget tests. The catalog holds
/// placeholder text only (never real adhkar, supplication or Quran text).

/// The clock the tests pin to one instant.
final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

/// A times port that always resolves [state].
final class FakeTimesPort implements AdhkarTimesPort {
  FakeTimesPort(this.state);

  AdhkarClockState state;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async => AppResult.success(state);
}

/// A morning clock with the schedule available and counting open.
AdhkarClockState morningClock({
  bool morningCountable = true,
  bool eveningCountable = false,
}) => AdhkarClockState(
  scheduleState: AdhkarScheduleState.available,
  day: '2026-11-10',
  period: AdhkarPeriod.morning,
  nextBoundaryUtc: DateTime.utc(2026, 11, 10, 16, 50),
  morningCountable: morningCountable,
  eveningCountable: eveningCountable,
  fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
  maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
  zoneId: 'UTC',
);

/// No saved Prayer location: unrestricted counting on the device day.
const AdhkarClockState setupClock = AdhkarClockState(
  scheduleState: AdhkarScheduleState.setupRequired,
  day: '2026-11-10',
  period: AdhkarPeriod.unrestricted,
  nextBoundaryUtc: null,
  morningCountable: true,
  eveningCountable: true,
  fajrUtc: null,
  maghribUtc: null,
  zoneId: null,
);

/// A saved schedule that cannot produce its times: counting is locked.
const AdhkarClockState unavailableClock = AdhkarClockState(
  scheduleState: AdhkarScheduleState.unavailable,
  day: null,
  period: null,
  nextBoundaryUtc: null,
  morningCountable: false,
  eveningCountable: false,
  fajrUtc: null,
  maghribUtc: null,
  zoneId: null,
);

Map<String, Object?> _item(
  String id,
  String list,
  int position,
  int target, {
  String kind = 'dhikr',
  String? virtue,
  String? preface,
  String? reference,
}) => {
  'item_id': id,
  'list': list,
  'position': position,
  'target': target,
  'kind': kind,
  'text_ar': kind == 'quran' ? 'placeholder verse text' : 'test item $id',
  'virtue_ar': virtue,
  'reference_ar': reference ?? 'test ref $id',
  if (kind == 'quran') ...{
    'surah': 'test surah',
    'ayah_from': 1,
    'ayah_to': 2,
    'preface_ar': preface,
  },
  'approved': true,
};

/// The placeholder catalog: Morning m1 (1x), m2 (3x, virtue), m3 (2x), m4 (a
/// Quran item with a preface), Evening e1 (1x) and e2 (2x).
final class FakeCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.success(
        AdhkarCatalog.fromJson({
          'catalog_version': 1,
          'attribution': 'test attribution line',
          'items': [
            _item('m1', 'morning', 1, 1, virtue: 'test virtue m1'),
            _item('m2', 'morning', 2, 3, virtue: 'test virtue m2'),
            _item('m3', 'morning', 3, 2),
            _item(
              'm4',
              'morning',
              4,
              1,
              kind: 'quran',
              preface: 'placeholder preface',
              reference: 'test reference m4',
            ),
            _item('e1', 'evening', 1, 1, virtue: 'test virtue e1'),
            _item('e2', 'evening', 2, 2),
          ],
          'qiyam_supplications': <Map<String, Object?>>[],
        }),
      );
}

/// A catalog port that fails until [works] is set (the retry path).
final class SwitchableCatalog implements AdhkarCatalogPort {
  bool works = false;

  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) => works
      ? FakeCatalog().snapshot(ownerId)
      : FailingCatalog().snapshot(ownerId);
}

/// A catalog whose snapshot fails: the content-unavailable state.
final class FailingCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'adhkar.catalog.unavailable',
          occurredAt: DateTime.utc(2026, 11, 10),
        ),
      );
}

/// The counts of one Adhkar day, shared by the repository (what the screen
/// loads) and the commands (what a tap changes).
final class FakeDay {
  FakeDay([Map<String, int>? counts]) : counts = {...?counts};

  final Map<String, int> counts;
}

final class FakeRepository implements AdhkarRepository {
  FakeRepository(this.day);

  final FakeDay day;

  @override
  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  }) async* {
    yield [
      for (final entry in day.counts.entries)
        AdhkarCountRecord(
          accountId: 'owner',
          adhkarDay: adhkarDay,
          itemId: entry.key,
          recordId: 'rec-${entry.key}',
          catalogVersion: 1,
          list: entry.key.startsWith('m') ? 'morning' : 'evening',
          count: entry.value,
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

/// Count commands that behave like the real ones over [day]: an increment
/// adds one up to the target (an item at its target is left alone) and
/// reports a completed set when every item of the list has reached it; a
/// reset writes zero. Every call is recorded.
final class SimulatedCommands implements AdhkarCommandRunner {
  SimulatedCommands(this.day, this.targets);

  final FakeDay day;

  /// The target and list of every item id.
  final Map<String, ({int target, String list})> targets;
  final incrementCalls = <String>[];
  final resetCalls = <String>[];

  /// How many times an increment reported a completed set (the award
  /// decision lives in the real transaction; the UI must show it once).
  int completedSets = 0;

  @override
  Future<AppResult<AdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  }) async {
    incrementCalls.add(itemId);
    final spec = targets[itemId]!;
    final current = day.counts[itemId] ?? 0;
    if (current >= spec.target) {
      return const AppResult.success(AdhkarAtTarget());
    }
    day.counts[itemId] = current + 1;
    final complete = targets.entries
        .where((entry) => entry.value.list == spec.list)
        .every((entry) => (day.counts[entry.key] ?? 0) >= entry.value.target);
    if (complete) completedSets++;
    return AppResult.success(
      AdhkarIncremented(newCount: current + 1, setCompleted: complete),
    );
  }

  @override
  Future<AppResult<AdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  }) async {
    resetCalls.add(itemId);
    day.counts[itemId] = 0;
    return const AppResult.success(AdhkarReset());
  }
}

/// The targets of [FakeCatalog] for [SimulatedCommands].
const Map<String, ({int target, String list})> fakeCatalogTargets = {
  'm1': (target: 1, list: 'morning'),
  'm2': (target: 3, list: 'morning'),
  'm3': (target: 2, list: 'morning'),
  'm4': (target: 1, list: 'morning'),
  'e1': (target: 1, list: 'evening'),
  'e2': (target: 2, list: 'evening'),
};
