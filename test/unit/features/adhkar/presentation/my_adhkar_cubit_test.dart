import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_state.dart';

import '../../../../support/foundation_test_support.dart';

/// T096: the My Adhkar Cubit (contracts/adhkar-qiyam-application.md,
/// reshaped 2026-11-16). It loads the groups with their counts, opens and
/// closes a group, creates, renames and deletes a group (with the preview
/// count), adds, edits (including the group set) and deletes an entry,
/// reflects the 1000-entry and 100-group limits as flags, ignores a command
/// while another is in flight, never emits after close, and is bound to one
/// owner. It has no Adhkar clock, times port, counter, celebration or streak,
/// so it works the same when the Prayer schedule is unavailable (FR-026).
/// Real encrypted store, stepping clock.
void main() {
  final key = List<int>.generate(32, (index) => index + 220);

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late _StepClock clock;
  late MyAdhkarCommands commands;
  late MyAdhkarCubit cubit;
  late TemporaryDatabasePath temp;

  MyAdhkarCubit cubitFor(String owner, {MyAdhkarCommandRunner? runner}) =>
      MyAdhkarCubit(
        ownerId: owner,
        repository: repository,
        commands:
            runner ??
            MyAdhkarCommands(
              ownerId: owner,
              clock: clock,
              repository: repository,
              identity: const UuidMyAdhkarIdentity(),
            ),
      );

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    repository = DriftMyAdhkarRepository(db);
    clock = _StepClock(DateTime.utc(2026, 11, 16, 9));
    commands = MyAdhkarCommands(
      ownerId: 'owner',
      clock: clock,
      repository: repository,
      identity: const UuidMyAdhkarIdentity(),
    );
    cubit = cubitFor('owner');
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
    temp.dispose();
  });

  Future<MyAdhkarState> settled(
    bool Function(MyAdhkarState state) done, {
    MyAdhkarCubit? of,
  }) async {
    final target = of ?? cubit;
    if (done(target.state)) return target.state;
    return target.stream.firstWhere(done).timeout(const Duration(seconds: 10));
  }

  Future<String> seedGroup(String name) async {
    clock.advance();
    final created =
        (await commands.createGroup(name: name)).valueOrNull
            as MyAdhkarGroupCreated;
    return created.groupId;
  }

  Future<String> seedEntry(
    List<String> groupIds, {
    String text = 'entry text',
    String? source,
  }) async {
    clock.advance();
    final added =
        (await commands.add(
              draft: MyDhikrDraft(
                text: text,
                source: source,
                groupIds: groupIds,
              ),
            )).valueOrNull
            as MyAdhkarAdded;
    return added.itemId;
  }

  Future<int> xpRows() async =>
      (await db.rawScalar('SELECT count(*) FROM xp_awards')) as int;

  test('before load the state is empty and not loaded', () {
    expect(cubit.state.loaded, isFalse);
    expect(cubit.state.groups, isEmpty);
    expect(cubit.state.openedGroupId, isNull);
    expect(cubit.state.groupLimitReached, isFalse);
    expect(cubit.state.entryLimitReached, isFalse);
  });

  test('load exposes the live groups oldest first with their entry counts, '
      'and is idempotent', () async {
    final first = await seedGroup('group a');
    final second = await seedGroup('group b');
    await seedEntry([first]);
    await seedEntry([first, second]);

    await cubit.load();
    await cubit.load();

    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.loadFailed, isFalse);
    expect(cubit.state.groups.map((s) => s.group.groupId), [first, second]);
    expect(cubit.state.groups.map((s) => s.liveEntryCount), [2, 1]);
    expect(
      cubit.state.liveEntryCount,
      2,
      reason: 'an entry in two groups is one entry',
    );
    expect(cubit.state.openedGroupId, isNull);
  });

  test('open and close a group inside the tab; the entries carry their '
      'full group set and follow later changes', () async {
    final groupA = await seedGroup('group a');
    final groupB = await seedGroup('group b');
    final shared = await seedEntry([groupA, groupB], text: 'entry text 1');
    await cubit.load();

    await cubit.openGroup(groupA);
    expect(cubit.state.openedGroupId, groupA);
    expect(cubit.state.openedGroup?.group.name, 'group a');
    expect(cubit.state.openedGroupItems.map((i) => i.itemId), [shared]);
    expect(
      cubit.state.openedGroupItems.single.groupIds.toSet(),
      {groupA, groupB},
      reason: 'the card needs the other groups and the edit form the set',
    );

    clock.advance();
    final added = await cubit.addEntry(
      draft: MyDhikrDraft(text: 'entry text 2', groupIds: [groupA]),
    );
    expect(added.succeeded, isTrue);
    final afterAdd = await settled((s) => s.openedGroupItems.length == 2);
    expect(
      afterAdd.openedGroupItems.map((i) => i.text),
      ['entry text 1', 'entry text 2'],
      reason: 'the order the entries were added to the group',
    );

    await cubit.closeGroup();
    expect(cubit.state.openedGroupId, isNull);
    expect(cubit.state.openedGroupItems, isEmpty);
  });

  test('create, rename and delete a group', () async {
    await cubit.load();

    final created = await cubit.createGroup(name: '  group a  ');
    expect(created.succeeded, isTrue);
    expect(created.groupId, isNotNull);
    await settled((s) => s.groups.length == 1);
    expect(cubit.state.groups.single.group.name, 'group a');

    final renamed = await cubit.renameGroup(
      groupId: created.groupId!,
      name: 'group a2',
    );
    expect(renamed.succeeded, isTrue);
    await settled((s) => s.groups.single.group.name == 'group a2');

    final deleted = await cubit.deleteGroup(groupId: created.groupId!);
    expect(deleted.succeeded, isTrue);
    expect(deleted.deletedEntries, 0);
    await settled((s) => s.groups.isEmpty);
    expect(await xpRows(), 0);
  });

  test('the delete preview counts only the entries whose only group it is; '
      'deleting the opened group closes it and keeps the shared entry '
      'elsewhere', () async {
    final groupA = await seedGroup('group a');
    final groupB = await seedGroup('group b');
    await seedEntry([groupA], text: 'entry text 1');
    final shared = await seedEntry([groupA, groupB], text: 'entry text 2');
    await cubit.load();
    await cubit.openGroup(groupA);

    expect(await cubit.previewDeleteGroup(groupId: groupA), 1);

    final deleted = await cubit.deleteGroup(groupId: groupA);
    expect(deleted.succeeded, isTrue);
    expect(deleted.deletedEntries, 1);
    expect(cubit.state.openedGroupId, isNull, reason: 'a deleted group closes');
    await settled((s) => s.groups.length == 1);
    expect(cubit.state.groups.single.group.groupId, groupB);
    expect(cubit.state.groups.single.liveEntryCount, 1);
    expect(cubit.state.liveEntryCount, 1);

    await cubit.openGroup(groupB);
    expect(cubit.state.openedGroupItems.map((i) => i.itemId), [shared]);
    expect(cubit.state.openedGroupItems.single.groupIds, [groupB]);
  });

  test('an opened group deleted by sync closes by itself', () async {
    final groupA = await seedGroup('group a');
    await cubit.load();
    await cubit.openGroup(groupA);

    clock.advance();
    await repository.runInTransaction(
      () async => AppResult.success(
        (await repository.deleteGroupCascade(
          accountId: 'owner',
          groupId: groupA,
          deletedAt: clock.nowUtc(),
          operationId: 'remote-delete',
          queueForSync: false,
        )).valueOrNull,
      ),
    );

    await settled((s) => s.groups.isEmpty);
    await settled((s) => s.openedGroupId == null);
  });

  test('add, edit (including the group set) and delete an entry', () async {
    final groupA = await seedGroup('group a');
    final groupB = await seedGroup('group b');
    await cubit.load();
    await cubit.openGroup(groupA);

    final added = await cubit.addEntry(
      draft: MyDhikrDraft(
        text: ' entry text 1 ',
        source: ' source 1 ',
        groupIds: [groupA],
      ),
    );
    expect(added.succeeded, isTrue);
    final itemId = added.itemId!;
    await settled((s) => s.openedGroupItems.length == 1);
    expect(cubit.state.openedGroupItems.single.text, 'entry text 1');
    expect(cubit.state.openedGroupItems.single.source, 'source 1');
    await settled((s) => s.liveEntryCount == 1);

    final edited = await cubit.editEntry(
      itemId: itemId,
      draft: MyDhikrDraft(
        text: 'entry text edited',
        groupIds: [groupA, groupB],
      ),
    );
    expect(edited.succeeded, isTrue);
    await settled((s) => s.openedGroupItems.single.text == 'entry text edited');
    expect(cubit.state.openedGroupItems.single.source, isNull);
    expect(cubit.state.openedGroupItems.single.groupIds.toSet(), {
      groupA,
      groupB,
    });
    await settled(
      (s) =>
          s.groups.length == 2 && s.groups.every((g) => g.liveEntryCount == 1),
    );
    expect(cubit.state.liveEntryCount, 1);

    // A text-only edit (same group set) shows at once too.
    final retexted = await cubit.editEntry(
      itemId: itemId,
      draft: MyDhikrDraft(
        text: 'entry text edited again',
        source: 'source 2',
        groupIds: [groupA, groupB],
      ),
    );
    expect(retexted.succeeded, isTrue);
    await settled(
      (s) =>
          s.openedGroupItems.single.text == 'entry text edited again' &&
          s.openedGroupItems.single.source == 'source 2',
    );

    final deleted = await cubit.deleteEntry(itemId: itemId);
    expect(deleted.succeeded, isTrue);
    await settled((s) => s.openedGroupItems.isEmpty);
    await settled((s) => s.groups.every((g) => g.liveEntryCount == 0));
    expect(cubit.state.liveEntryCount, 0);
    expect(await xpRows(), 0, reason: 'My Adhkar never writes XP (FR-026)');
  });

  test('validation failures are typed and write nothing', () async {
    final groupA = await seedGroup('group a');
    await cubit.load();

    expect(
      (await cubit.createGroup(name: '   ')).failure,
      MyAdhkarFailure.groupNameInvalid,
    );
    expect(
      (await cubit.createGroup(name: 'x' * 61)).failure,
      MyAdhkarFailure.groupNameInvalid,
    );
    expect(
      (await cubit.renameGroup(groupId: groupA, name: '')).failure,
      MyAdhkarFailure.groupNameInvalid,
    );
    expect(
      (await cubit.addEntry(
        draft: MyDhikrDraft(text: '  ', groupIds: [groupA]),
      )).failure,
      MyAdhkarFailure.textInvalid,
    );
    expect(
      (await cubit.addEntry(
        draft: MyDhikrDraft(text: 'x' * 2001, groupIds: [groupA]),
      )).failure,
      MyAdhkarFailure.textInvalid,
    );
    expect(
      (await cubit.addEntry(
        draft: MyDhikrDraft(
          text: 'entry text',
          source: 's' * 501,
          groupIds: [groupA],
        ),
      )).failure,
      MyAdhkarFailure.sourceInvalid,
    );
    expect(
      (await cubit.addEntry(
        draft: const MyDhikrDraft(text: 'entry text'),
      )).failure,
      MyAdhkarFailure.groupSetInvalid,
    );
    expect(
      (await cubit.renameGroup(groupId: 'missing', name: 'group x')).failure,
      MyAdhkarFailure.groupUnknown,
    );
    expect(
      (await cubit.editEntry(
        itemId: 'missing',
        draft: MyDhikrDraft(text: 'entry text', groupIds: [groupA]),
      )).failure,
      MyAdhkarFailure.itemUnknown,
    );
    expect(cubit.state.busy, isFalse, reason: 'a failure releases the guard');
    expect(cubit.state.groups, hasLength(1));
    expect(cubit.state.liveEntryCount, 0);
  });

  test('an entry for a deleted group, and the edit of a deleted entry, are '
      'typed failures', () async {
    final groupA = await seedGroup('group a');
    final groupB = await seedGroup('group b');
    final itemId = await seedEntry([groupA]);
    await cubit.load();
    await cubit.deleteGroup(groupId: groupB);
    await cubit.deleteEntry(itemId: itemId);

    expect(
      (await cubit.addEntry(
        draft: MyDhikrDraft(text: 'entry text', groupIds: [groupB]),
      )).failure,
      MyAdhkarFailure.groupDeleted,
    );
    expect(
      (await cubit.editEntry(
        itemId: itemId,
        draft: MyDhikrDraft(text: 'entry text', groupIds: [groupA]),
      )).failure,
      MyAdhkarFailure.itemDeleted,
    );
  });

  test('the 100-group limit is a flag and a typed failure', () async {
    clock.advance();
    final base = clock.nowUtc();
    await repository.runInTransaction(() async {
      for (var i = 0; i < kMyAdhkarGroupLimit; i++) {
        final inserted = await repository.insertGroup(
          MyAdhkarGroup(
            accountId: 'owner',
            groupId:
                '${i.toString().padLeft(8, '0')}-0000-4000-8000-000000000000',
            name: 'group $i',
            createdAt: base,
            updatedAt: base,
            lastAcknowledgedUpdatedAt: null,
            deletedAt: null,
          ),
          operationId: 'seed-group-$i',
          queueForSync: false,
        );
        if (inserted.failureOrNull != null) throw StateError('seed $i');
      }
      return const AppResult<void>.success(null);
    });

    await cubit.load();
    expect(cubit.state.groups, hasLength(100));
    expect(cubit.state.groupLimitReached, isTrue);
    expect(
      (await cubit.createGroup(name: 'one too many')).failure,
      MyAdhkarFailure.groupLimitReached,
    );
    expect(cubit.state.groups, hasLength(100));
  });

  test(
    'the 1000-entry limit is a flag and a typed failure',
    () async {
      final groupA = await seedGroup('group a');
      clock.advance();
      final base = clock.nowUtc();
      await repository.runInTransaction(() async {
        for (var i = 0; i < kMyAdhkarEntryLimit; i++) {
          final inserted = await repository.insertItem(
            MyDhikrItem(
              accountId: 'owner',
              itemId:
                  '${i.toString().padLeft(8, '0')}-4444-4333-8444-555555555555',
              text: 'entry text $i',
              source: null,
              groupIds: [groupA],
              createdAt: base,
              updatedAt: base,
              lastAcknowledgedUpdatedAt: null,
              deletedAt: null,
            ),
            operationId: 'seed-entry-$i',
            queueForSync: false,
          );
          if (inserted.failureOrNull != null) throw StateError('seed $i');
        }
        return const AppResult<void>.success(null);
      });

      await cubit.load();
      await settled((s) => s.liveEntryCount == kMyAdhkarEntryLimit);
      expect(cubit.state.entryLimitReached, isTrue);
      expect(
        (await cubit.addEntry(
          draft: MyDhikrDraft(text: 'one too many', groupIds: [groupA]),
        )).failure,
        MyAdhkarFailure.entryLimitReached,
      );

      // Deleting one entry lifts the flag again.
      final removed = await cubit.deleteEntry(
        itemId: '00000000-4444-4333-8444-555555555555',
      );
      expect(removed.succeeded, isTrue);
      await settled((s) => !s.entryLimitReached);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('a command is ignored while another is in flight', () async {
    final gate = Completer<void>();
    final runner = _GatedRunner(gate.future);
    final guarded = cubitFor('owner', runner: runner);
    addTearDown(guarded.close);
    await guarded.load();

    final first = guarded.createGroup(name: 'group a');
    await settled((s) => s.busy, of: guarded);
    final second = await guarded.createGroup(name: 'group b');
    final third = await guarded.addEntry(
      draft: const MyDhikrDraft(text: 'entry text', groupIds: ['g']),
    );
    expect(second.ignored, isTrue);
    expect(third.ignored, isTrue);
    expect(second.succeeded, isFalse);
    expect(runner.calls, ['createGroup'], reason: 'only the first ran');

    gate.complete();
    final firstResult = await first;
    expect(firstResult.succeeded, isTrue);
    expect(guarded.state.busy, isFalse);

    final again = await guarded.createGroup(name: 'group b');
    expect(again.succeeded, isTrue, reason: 'the guard released');
    expect(runner.calls, ['createGroup', 'createGroup']);
  });

  test(
    'a throwing command is a typed failure and releases the guard',
    () async {
      final throwing = cubitFor('owner', runner: _ThrowingRunner());
      addTearDown(throwing.close);
      await throwing.load();
      final result = await throwing.createGroup(name: 'group a');
      expect(result.failure, MyAdhkarFailure.unavailable);
      expect(throwing.state.busy, isFalse);
    },
  );

  test('closing during a command emits nothing and does not throw', () async {
    final gate = Completer<void>();
    final closing = cubitFor('owner', runner: _GatedRunner(gate.future));
    await closing.load();
    final pending = closing.createGroup(name: 'group a');
    await settled((s) => s.busy, of: closing);
    await closing.close();
    gate.complete();
    final result = await pending;
    expect(result.succeeded, isTrue);
  });

  test('the Cubit is bound to its owner: another owner sees nothing and '
      'cannot reach the first owner\'s groups', () async {
    final groupA = await seedGroup('group a');
    await seedEntry([groupA]);
    final other = cubitFor('other-owner');
    addTearDown(other.close);
    await other.load();
    expect(other.state.loaded, isTrue);
    expect(other.state.groups, isEmpty);
    expect(other.state.liveEntryCount, 0);

    await other.openGroup(groupA);
    expect(
      other.state.openedGroupItems,
      isEmpty,
      reason: 'another owner never reads the first owner\'s entries',
    );
    expect(
      (await other.renameGroup(groupId: groupA, name: 'group hijack')).failure,
      MyAdhkarFailure.groupUnknown,
    );
    await cubit.load();
    expect(cubit.state.groups.single.group.name, 'group a');
  });

  test('works with no Adhkar times, counter, celebration or streak: only '
      'My Adhkar rows and outbox types are written', () async {
    await cubit.load();
    final groupId = (await cubit.createGroup(name: 'group a')).groupId!;
    await cubit.addEntry(
      draft: MyDhikrDraft(text: 'entry text', groupIds: [groupId]),
    );
    final types = await db
        .customSelect('SELECT DISTINCT entity_type FROM pending_changes')
        .get();
    expect(types.map((row) => row.read<String>('entity_type')).toSet(), {
      'my_adhkar_group',
      'my_adhkar_item',
    });
    expect(
      (await db.rawScalar('SELECT count(*) FROM adhkar_item_counts')) as int,
      0,
      reason: 'no Adhkar count, streak input or set award',
    );
    expect(await xpRows(), 0);
  });
}

final class _StepClock implements AdhkarClockPort {
  _StepClock(this._now);

  DateTime _now;

  void advance() => _now = _now.add(const Duration(minutes: 1));

  @override
  DateTime nowUtc() => _now;
}

/// A runner whose create-group command waits on a gate, to hold one command
/// in flight; every other command succeeds at once.
final class _GatedRunner implements MyAdhkarCommandRunner {
  _GatedRunner(this._gate);

  final Future<void> _gate;
  final List<String> calls = [];

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> createGroup({
    required String name,
  }) async {
    calls.add('createGroup');
    await _gate;
    return const AppResult.success(MyAdhkarGroupCreated(groupId: 'g-fake'));
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> renameGroup({
    required String groupId,
    required String name,
  }) async {
    calls.add('renameGroup');
    return const AppResult.success(MyAdhkarGroupRenamed());
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> deleteGroup({
    required String groupId,
  }) async {
    calls.add('deleteGroup');
    return const AppResult.success(MyAdhkarGroupDeleted(cascadedEntries: 0));
  }

  @override
  Future<AppResult<int>> previewDeleteGroup({required String groupId}) async =>
      const AppResult.success(0);

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> add({
    required MyDhikrDraft draft,
  }) async {
    calls.add('add');
    return const AppResult.success(MyAdhkarAdded(itemId: 'i-fake'));
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String itemId,
    required MyDhikrDraft draft,
  }) async {
    calls.add('edit');
    return const AppResult.success(MyAdhkarEdited());
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> delete({
    required String itemId,
  }) async {
    calls.add('delete');
    return const AppResult.success(MyAdhkarDeleted());
  }
}

final class _ThrowingRunner implements MyAdhkarCommandRunner {
  @override
  Future<AppResult<MyAdhkarCommandOutcome>> createGroup({
    required String name,
  }) => throw StateError('boom');

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> renameGroup({
    required String groupId,
    required String name,
  }) => throw StateError('boom');

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> deleteGroup({
    required String groupId,
  }) => throw StateError('boom');

  @override
  Future<AppResult<int>> previewDeleteGroup({required String groupId}) =>
      throw StateError('boom');

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> add({
    required MyDhikrDraft draft,
  }) => throw StateError('boom');

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String itemId,
    required MyDhikrDraft draft,
  }) => throw StateError('boom');

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> delete({required String itemId}) =>
      throw StateError('boom');
}
