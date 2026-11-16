import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../../../../support/foundation_test_support.dart';

/// T089: the My Adhkar commands (contracts/adhkar-qiyam-application.md,
/// "My Adhkar ports and commands"): the day guard and the locked state on
/// counting, `itemDeleted`, `limitReached`, typed validation failures, the
/// target-lowering clamp, delete-final semantics, and that no command
/// touches the XP ledger (FR-026). Real store, fake clock and times.
void main() {
  final key = List<int>.generate(32, (index) => index + 180);
  final now = DateTime.utc(2026, 11, 15, 9);

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late FakeClock clock;
  late FakeTimesPort times;
  late MyAdhkarCommands commands;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    repository = DriftMyAdhkarRepository(db);
    clock = FakeClock(now);
    times = FakeTimesPort(_available('2026-11-15'));
    commands = MyAdhkarCommands(
      ownerId: 'owner',
      times: times,
      clock: clock,
      repository: repository,
      identity: const UuidMyAdhkarIdentity(),
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  MyDhikrItem seedItem({
    String itemId = '11111111-2222-4333-8444-555555555555',
    int target = 33,
    DateTime? deletedAt,
  }) {
    final item = MyDhikrItem(
      accountId: 'owner',
      itemId: itemId,
      text: 'test dhikr',
      target: target,
      note: null,
      createdAt: DateTime.utc(2026, 11, 15, 8),
      updatedAt: DateTime.utc(2026, 11, 15, 8, 30),
      lastAcknowledgedUpdatedAt: null,
      deletedAt: deletedAt,
    );
    return item;
  }

  Future<void> seed(MyDhikrItem item) => repository.runInTransaction<void>(
    () => repository.insertItem(
      item,
      operationId: 'seed-${item.itemId}',
      queueForSync: false,
    ),
  );

  Future<void> seedCount(String itemId, int count, {DateTime? expected}) =>
      repository.commitCount(
        MyAdhkarCountCommitRequest(
          accountId: 'owner',
          itemId: itemId,
          adhkarDay: '2026-11-15',
          recordId: 'seed-rec-$itemId',
          newCount: count,
          createdAt: DateTime.utc(2026, 11, 15, 8),
          updatedAt: expected != null
              ? now.add(const Duration(minutes: 5))
              : DateTime.utc(2026, 11, 15, 8, 45),
          operationId: 'seed-count-$itemId',
          expectedCurrentVersion: expected,
          acknowledgedBase: null,
          queueForSync: false,
          hadPrior: expected != null,
        ),
      );

  Future<int> xpRows() async =>
      (await db.rawScalar('SELECT count(*) FROM xp_awards')) as int;

  test('add stores the trimmed draft with default target and returns its '
      'new UUIDv4 item id', () async {
    final outcome =
        (await commands.add(
              draft: const MyDhikrDraft(text: '  test dhikr  '),
            )).valueOrNull
            as MyAdhkarAdded;
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      ).hasMatch(outcome.itemId),
      isTrue,
    );
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: outcome.itemId,
    )).valueOrNull!;
    expect(stored.text, 'test dhikr');
    expect(stored.target, 1, reason: 'the target defaults to 1');
    expect(stored.note, isNull);
    expect(stored.createdAt, now);
    expect(stored.isDeleted, isFalse);
    expect(await xpRows(), 0);
  });

  test('add rejects a blank text with a typed validation failure', () async {
    final result = await commands.add(draft: const MyDhikrDraft(text: '   '));
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull!.category, AppFailureCategory.validation);
    expect(result.failureOrNull!.messageKey, 'my_adhkar.draft.invalid_text');
    expect(await repository.watchItems('owner').first, isEmpty);
    expect(await xpRows(), 0);
  });

  test('add rejects an out-of-range target and an over-long note', () async {
    final target = await commands.add(
      draft: const MyDhikrDraft(text: 'test dhikr', target: 0),
    );
    expect(target.failureOrNull!.messageKey, 'my_adhkar.draft.invalid_target');
    final note = await commands.add(
      draft: MyDhikrDraft(text: 'test dhikr', note: 'ا' * 301),
    );
    expect(note.failureOrNull!.messageKey, 'my_adhkar.draft.note_too_long');
    expect(await repository.watchItems('owner').first, isEmpty);
  });

  test('add reports limitReached at 100 live items and counts only live '
      'items', () async {
    // 99 live items plus one deleted one: the deleted one does not count.
    await repository.runInTransaction(() async {
      for (var i = 0; i < 99; i++) {
        final n = i.toString().padLeft(8, '0');
        final insert = await repository.insertItem(
          seedItem(itemId: '$n-2222-4333-8444-555555555555'),
          operationId: 'seed-$i',
          queueForSync: false,
        );
        if (insert.failureOrNull != null) throw StateError('seed failed');
      }
      final deletedInsert = await repository.insertItem(
        seedItem(
          itemId: 'eeeeeeee-2222-4333-8444-555555555555',
          deletedAt: DateTime.utc(2026, 11, 15, 8, 50),
        ),
        operationId: 'seed-deleted',
        queueForSync: false,
      );
      if (deletedInsert.failureOrNull != null) throw StateError('seed failed');
      return const AppResult<void>.success(null);
    });
    final outcome = (await commands.add(
      draft: const MyDhikrDraft(text: 'test dhikr new'),
    )).valueOrNull;
    expect(outcome, isA<MyAdhkarAdded>(), reason: '99 live items: add works');
    final atLimit = (await commands.add(
      draft: const MyDhikrDraft(text: 'test dhikr over'),
    )).valueOrNull;
    expect(atLimit, isA<MyAdhkarLimitReached>());
    expect(
      (await repository.liveItemCount(accountId: 'owner')).valueOrNull,
      100,
    );
    expect(await xpRows(), 0);
  });

  test('increment counts up to the target, no-ops at the target and never '
      'passes it', () async {
    await seed(seedItem());
    final first =
        (await commands.increment(
              capturedDay: '2026-11-15',
              itemId: '11111111-2222-4333-8444-555555555555',
            )).valueOrNull
            as MyAdhkarCounted;
    expect(first.newCount, 1);
    final second =
        (await commands.increment(
              capturedDay: '2026-11-15',
              itemId: '11111111-2222-4333-8444-555555555555',
            )).valueOrNull
            as MyAdhkarCounted;
    expect(second.newCount, 2);
    // At the target: the no-op keeps the count and writes nothing. Two
    // increments already ran at `now`, so the stored version is now + 1µs.
    await seedCount(
      '11111111-2222-4333-8444-555555555555',
      33,
      expected: now.add(const Duration(microseconds: 1)),
    );
    final atTarget = (await commands.increment(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(atTarget, isA<MyAdhkarAtTarget>());
    final stored = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(stored.valueOrNull!.count, 33);
    expect(await xpRows(), 0);
  });

  test('the increment record id is the deterministic count identity', () async {
    await seed(seedItem(target: 5));
    await commands.increment(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    );
    final stored = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(
      stored.valueOrNull!.recordId,
      const UuidMyAdhkarIdentity().countRecordId(
        '11111111-2222-4333-8444-555555555555',
        '2026-11-15',
      ),
    );
  });

  test('increment and reset reject a stale day and write nothing', () async {
    await seed(seedItem());
    final increment = (await commands.increment(
      capturedDay: '2026-11-14',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(increment, isA<MyAdhkarDayChanged>());
    final reset = (await commands.reset(
      capturedDay: '2026-11-14',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(reset, isA<MyAdhkarDayChanged>());
    expect(
      (await repository.readCountFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        adhkarDay: '2026-11-15',
      )).valueOrNull,
      isNull,
      reason: 'a stale day writes nothing',
    );
    expect(await xpRows(), 0);
  });

  test(
    'increment and reset are locked when the schedule is unavailable',
    () async {
      await seed(seedItem());
      times.state = AdhkarClockState(
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
      final increment = (await commands.increment(
        capturedDay: '2026-11-15',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull;
      expect(increment, isA<MyAdhkarCountingLocked>());
      final reset = (await commands.reset(
        capturedDay: '2026-11-15',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull;
      expect(reset, isA<MyAdhkarCountingLocked>());
      expect(
        (await repository.readCountFresh(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
          adhkarDay: '2026-11-15',
        )).valueOrNull,
        isNull,
      );
      expect(await xpRows(), 0);
    },
  );

  test('increment and reset reject a deleted item with itemDeleted', () async {
    await seed(seedItem(deletedAt: DateTime.utc(2026, 11, 15, 8, 50)));
    final increment = (await commands.increment(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(increment, isA<MyAdhkarItemDeleted>());
    final reset = (await commands.reset(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(reset, isA<MyAdhkarItemDeleted>());
    expect(
      (await repository.readCountFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        adhkarDay: '2026-11-15',
      )).valueOrNull,
      isNull,
    );
  });

  test('reset writes a persisted 0 row', () async {
    await seed(seedItem());
    await seedCount('11111111-2222-4333-8444-555555555555', 7);
    final outcome = (await commands.reset(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull;
    expect(outcome, isA<MyAdhkarReset>());
    final stored = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(stored.valueOrNull!.count, 0);
  });

  test('edit keeps today\'s count and lowers it only when the target drops '
      'below it, in the same transaction', () async {
    await seed(seedItem());
    await seedCount('11111111-2222-4333-8444-555555555555', 20);
    final edited = (await commands.edit(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
      draft: const MyDhikrDraft(text: 'edited dhikr', target: 50),
    )).valueOrNull;
    expect(edited, isA<MyAdhkarEdited>());
    var stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(stored.text, 'edited dhikr');
    expect(stored.target, 50);
    var count = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(count.valueOrNull!.count, 20, reason: 'an edit keeps the count');

    // Lower the target below today's count: the count clamps to the target.
    final lowered = (await commands.edit(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
      draft: const MyDhikrDraft(text: 'edited dhikr', target: 10),
    )).valueOrNull;
    expect(lowered, isA<MyAdhkarEdited>());
    stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(stored.target, 10);
    count = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(count.valueOrNull!.count, 10, reason: 'FR-025 clamp');
    expect(await xpRows(), 0);
  });

  test('edit rejects a deleted item and an invalid draft', () async {
    await seed(seedItem(deletedAt: DateTime.utc(2026, 11, 15, 8, 50)));
    final deleted = (await commands.edit(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
      draft: const MyDhikrDraft(text: 'test dhikr'),
    )).valueOrNull;
    expect(deleted, isA<MyAdhkarItemDeleted>());
    final invalid = await commands.edit(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
      draft: const MyDhikrDraft(text: '   '),
    );
    expect(invalid.failureOrNull!.messageKey, 'my_adhkar.draft.invalid_text');
  });

  test('edit rejects a stale day without touching the item', () async {
    await seed(seedItem());
    final outcome = (await commands.edit(
      capturedDay: '2026-11-14',
      itemId: '11111111-2222-4333-8444-555555555555',
      draft: const MyDhikrDraft(text: 'stale edit'),
    )).valueOrNull;
    expect(outcome, isA<MyAdhkarDayChanged>());
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(stored.text, 'test dhikr');
  });

  test(
    'delete tombstones once and deleting again never moves the tombstone',
    () async {
      await seed(seedItem());
      final outcome = (await commands.delete(
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull;
      expect(outcome, isA<MyAdhkarDeleted>());
      expect(await repository.watchItems('owner').first, isEmpty);
      final stored = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      expect(stored.isDeleted, isTrue);
      // Deleting the already deleted item is a no-op.
      final again = (await commands.delete(
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull;
      expect(again, isA<MyAdhkarDeleted>());
      final unchanged = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      expect(unchanged.deletedAt, stored.deletedAt);
      expect(await xpRows(), 0);
    },
  );

  test('a failed times read propagates instead of counting', () async {
    await seed(seedItem());
    times.failure = AppFailure.recoverable(
      category: AppFailureCategory.configuration,
      messageKey: 'adhkar.times.unavailable',
      occurredAt: now,
    );
    final result = await commands.increment(
      capturedDay: '2026-11-15',
      itemId: '11111111-2222-4333-8444-555555555555',
    );
    expect(result.failureOrNull!.messageKey, 'adhkar.times.unavailable');
    expect(
      (await repository.readCountFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        adhkarDay: '2026-11-15',
      )).valueOrNull,
      isNull,
    );
    expect(await xpRows(), 0);
  });
}

AdhkarClockState _available(String day) => AdhkarClockState(
  scheduleState: AdhkarScheduleState.available,
  day: day,
  period: AdhkarPeriod.morning,
  nextBoundaryUtc: DateTime.utc(2026, 11, 15, 16, 50),
  morningCountable: true,
  eveningCountable: false,
  fajrUtc: DateTime.utc(2026, 11, 15, 4, 30),
  maghribUtc: DateTime.utc(2026, 11, 15, 16, 50),
  zoneId: 'UTC',
);

final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeTimesPort implements AdhkarTimesPort {
  FakeTimesPort(this.state);

  AdhkarClockState state;
  AppFailure? failure;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async {
    if (failure != null) {
      return AppResult.failure(failure!);
    }
    return AppResult.success(state);
  }
}
