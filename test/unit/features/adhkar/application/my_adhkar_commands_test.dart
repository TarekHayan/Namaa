import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../../../../support/foundation_test_support.dart';

/// T102: the reshaped My Adhkar commands (contracts/
/// adhkar-qiyam-application.md "My Adhkar ports and commands", reshaped
/// 2026-11-16): groups (create, rename, delete with the preview count) and
/// entries (add, edit with the group set, delete), with `groupDeleted`,
/// `groupLimitReached`, `limitReached`, `itemDeleted` and typed validation
/// failures. There is no day guard, locked state, counter or Adhkar times
/// dependency, the edit reads, checks and writes in one transaction, the
/// delete uses a monotonic `updated_at`, and no command touches the XP
/// ledger (FR-026). Real store, fake clock.
void main() {
  final key = List<int>.generate(32, (index) => index + 180);
  final now = DateTime.utc(2026, 11, 16, 9);

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late FakeClock clock;
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
    commands = MyAdhkarCommands(
      ownerId: 'owner',
      clock: clock,
      repository: repository,
      identity: const UuidMyAdhkarIdentity(),
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  Future<String> seedGroup(String name) async {
    final created =
        (await commands.createGroup(name: name)).valueOrNull
            as MyAdhkarGroupCreated;
    return created.groupId;
  }

  Future<String> seedEntry({
    required List<String> groupIds,
    String text = 'test dhikr',
    String? source = 'test source',
  }) async {
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

  test('createGroup stores the trimmed name with a fresh UUIDv4 id', () async {
    final outcome =
        (await commands.createGroup(name: '  test group  ')).valueOrNull
            as MyAdhkarGroupCreated;
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      ).hasMatch(outcome.groupId),
      isTrue,
    );
    final stored = (await repository.readGroupFresh(
      accountId: 'owner',
      groupId: outcome.groupId,
    )).valueOrNull!;
    expect(stored.name, 'test group');
    expect(stored.createdAt, now);
    expect(stored.isDeleted, isFalse);
    expect(await xpRows(), 0);
  });

  test(
    'createGroup rejects a blank or over-long name with typed failures',
    () async {
      final blank = await commands.createGroup(name: '   ');
      expect(blank.failureOrNull!.category, AppFailureCategory.validation);
      expect(blank.failureOrNull!.messageKey, 'my_adhkar.group.invalid_name');
      final long = await commands.createGroup(name: 'ا' * 61);
      expect(long.failureOrNull!.messageKey, 'my_adhkar.group.invalid_name');
    },
  );

  test('createGroup reports groupLimitReached at 100 live groups', () async {
    for (var i = 0; i < 100; i++) {
      final created =
          (await commands.createGroup(name: 'group $i')).valueOrNull
              as MyAdhkarGroupCreated;
      // Keep the ids local to this test only.
      if (i == 0) {
        expect(created.groupId, isNotEmpty);
      }
    }
    final over = (await commands.createGroup(name: 'one more')).valueOrNull;
    expect(over, isA<MyAdhkarGroupLimitReached>());
    expect(
      (await repository.liveGroupCount(accountId: 'owner')).valueOrNull,
      100,
    );
    expect(await xpRows(), 0);
  });

  test('renameGroup renames a live group, keeps its entries and rejects a '
      'deleted or unknown group', () async {
    final groupId = await seedGroup('old name');
    final itemId = await seedEntry(groupIds: [groupId]);

    final renamed = await commands.renameGroup(
      groupId: groupId,
      name: '  renamed group  ',
    );
    expect(renamed.valueOrNull, isA<MyAdhkarGroupRenamed>());
    final stored = (await repository.readGroupFresh(
      accountId: 'owner',
      groupId: groupId,
    )).valueOrNull!;
    expect(stored.name, 'renamed group');
    expect(
      await repository
          .watchGroupItems(accountId: 'owner', groupId: groupId)
          .first
          .then((items) => items.map((i) => i.itemId)),
      [itemId],
      reason: 'a rename keeps its entries',
    );

    // Rename a deleted group: groupDeleted, and the tombstone never moves.
    await commands.deleteGroup(groupId: groupId);
    final afterDelete = await commands.renameGroup(
      groupId: groupId,
      name: 'resurrecting name',
    );
    expect(afterDelete.valueOrNull, isA<MyAdhkarGroupDeleted>());
    final tombstoned = (await repository.readGroupFresh(
      accountId: 'owner',
      groupId: groupId,
    )).valueOrNull!;
    expect(tombstoned.name, 'renamed group');
    expect(tombstoned.isDeleted, isTrue);

    final unknown = await commands.renameGroup(
      groupId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      name: 'nowhere',
    );
    expect(unknown.failureOrNull!.messageKey, 'my_adhkar.group.unknown');
    expect(await xpRows(), 0);
  });

  test('previewDeleteGroup counts the entries the delete would remove and '
      'deleteGroup applies the FR-029 cascade', () async {
    final groupIdA = await seedGroup('group a');
    final groupIdB = await seedGroup('group b');
    final onlyHere = await seedEntry(groupIds: [groupIdA]);
    final alsoThere = await seedEntry(groupIds: [groupIdA, groupIdB]);

    expect(
      await commands
          .previewDeleteGroup(groupId: groupIdA)
          .then((r) => r.valueOrNull),
      1,
    );
    expect(
      await commands
          .previewDeleteGroup(groupId: groupIdB)
          .then((r) => r.valueOrNull),
      0,
      reason: 'its entry also lives in group a',
    );

    final deleted = await commands.deleteGroup(groupId: groupIdA);
    final outcome = deleted.valueOrNull as MyAdhkarGroupDeleted;
    expect(outcome.cascadedEntries, 1);
    final gone = (await repository.readFresh(
      accountId: 'owner',
      itemId: onlyHere,
    )).valueOrNull!;
    expect(gone.isDeleted, isTrue);
    final kept = (await repository.readFresh(
      accountId: 'owner',
      itemId: alsoThere,
    )).valueOrNull!;
    expect(kept.isDeleted, isFalse);
    expect(kept.groupIds, [groupIdB]);

    // Deleting the already deleted group is a no-op with the same outcome.
    final again = await commands.deleteGroup(groupId: groupIdA);
    expect((again.valueOrNull as MyAdhkarGroupDeleted).cascadedEntries, 0);
    final previewAfter = await commands.previewDeleteGroup(groupId: groupIdA);
    expect(
      previewAfter.valueOrNull,
      0,
      reason: 'a deleted group removes nothing',
    );
    expect(await xpRows(), 0);
  });

  test('previewDeleteGroup on an unknown group fails', () async {
    final preview = await commands.previewDeleteGroup(
      groupId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    );
    expect(preview.valueOrNull, isNull);
    expect(preview.failureOrNull!.messageKey, 'my_adhkar.group.unknown');
  });

  test('add stores the trimmed fields with the group set and returns the '
      'entry id', () async {
    final groupId = await seedGroup('group a');
    final added =
        (await commands.add(
              draft: MyDhikrDraft(
                text: '  test dhikr  ',
                source: '  test source  ',
                groupIds: [groupId],
              ),
            )).valueOrNull
            as MyAdhkarAdded;
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: added.itemId,
    )).valueOrNull!;
    expect(stored.text, 'test dhikr');
    expect(stored.source, 'test source');
    expect(stored.groupIds, [groupId]);
    expect(stored.createdAt, now);
    expect(await xpRows(), 0);
  });

  test(
    'add rejects invalid drafts with typed failures and writes nothing',
    () async {
      final blankText = await commands.add(
        draft: MyDhikrDraft(text: '   ', groupIds: ['g1']),
      );
      expect(
        blankText.failureOrNull!.messageKey,
        'my_adhkar.draft.invalid_text',
      );
      final longSource = await commands.add(
        draft: MyDhikrDraft(
          text: 'test dhikr',
          source: 'ا' * 501,
          groupIds: ['g1'],
        ),
      );
      expect(
        longSource.failureOrNull!.messageKey,
        'my_adhkar.draft.invalid_source',
      );
      final emptyGroups = await commands.add(
        draft: const MyDhikrDraft(text: 'test dhikr'),
      );
      expect(
        emptyGroups.failureOrNull!.messageKey,
        'my_adhkar.draft.empty_group_set',
      );
      expect(await repository.watchGroups('owner').first, isEmpty);
      expect(await xpRows(), 0);
    },
  );

  test('add rejects a deleted group in the set with groupDeleted and an '
      'unknown one with a failure', () async {
    final groupId = await seedGroup('group a');
    await commands.deleteGroup(groupId: groupId);
    final deletedRef = await commands.add(
      draft: MyDhikrDraft(text: 'test dhikr', groupIds: [groupId]),
    );
    expect(deletedRef.valueOrNull, isA<MyAdhkarGroupDeleted>());
    final unknownRef = await commands.add(
      draft: MyDhikrDraft(
        text: 'test dhikr',
        groupIds: ['ffffffff-ffff-4fff-8fff-ffffffffffff'],
      ),
    );
    expect(unknownRef.failureOrNull!.messageKey, 'my_adhkar.group.unknown');
    expect(
      (await repository.liveEntryCount(accountId: 'owner')).valueOrNull,
      0,
    );
    expect(await xpRows(), 0);
  });

  test(
    'add reports limitReached at 1000 live entries, counting live only',
    () async {
      final groupId = await seedGroup('group a');
      for (var i = 0; i < 999; i++) {
        final n = i.toString().padLeft(12, '0');
        await repository.runInTransaction(() {
          return repository.insertItem(
            MyDhikrItem(
              accountId: 'owner',
              itemId: '$n-4444-4333-8444-555555555555',
              text: 'test dhikr $i',
              source: null,
              groupIds: [groupId],
              createdAt: now,
              updatedAt: now,
              lastAcknowledgedUpdatedAt: null,
              deletedAt: null,
            ),
            operationId: 'seed-$i',
            queueForSync: false,
          );
        });
      }
      final tombstoneSeed = await repository.runInTransaction(() {
        return repository.insertItem(
          MyDhikrItem(
            accountId: 'owner',
            itemId: 'eeeeeeee-4444-4333-8444-555555555555',
            text: 'deleted seed',
            source: null,
            groupIds: const [],
            createdAt: now,
            updatedAt: now,
            lastAcknowledgedUpdatedAt: null,
            deletedAt: now,
          ),
          operationId: 'seed-deleted',
          queueForSync: false,
        );
      });
      expect(tombstoneSeed.failureOrNull, isNull);
      expect(
        (await repository.liveEntryCount(accountId: 'owner')).valueOrNull,
        999,
        reason: 'the seed loop landed exactly 999 live entries',
      );

      // 999 live entries: one more fits.
      final fits =
          (await commands.add(
                draft: MyDhikrDraft(
                  text: 'test dhikr fits',
                  groupIds: [groupId],
                ),
              )).valueOrNull
              as MyAdhkarAdded;
      expect(fits.itemId, isNotEmpty);
      // 1000 live entries: the add is rejected.
      final over = (await commands.add(
        draft: MyDhikrDraft(text: 'test dhikr over', groupIds: [groupId]),
      )).valueOrNull;
      expect(over, isA<MyAdhkarLimitReached>());
      expect(
        (await repository.liveEntryCount(accountId: 'owner')).valueOrNull,
        1000,
      );
      expect(await xpRows(), 0);
    },
  );

  test('edit changes the fields and the group set, reading, checking and '
      'writing in one transaction', () async {
    final groupIdA = await seedGroup('group a');
    final groupIdB = await seedGroup('group b');
    final itemId = await seedEntry(groupIds: [groupIdA]);

    final edited = await commands.edit(
      itemId: itemId,
      draft: MyDhikrDraft(
        text: '  edited dhikr  ',
        groupIds: [groupIdA, groupIdB],
      ),
    );
    expect(edited.valueOrNull, isA<MyAdhkarEdited>());
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: itemId,
    )).valueOrNull!;
    expect(stored.text, 'edited dhikr');
    expect(stored.source, isNull, reason: 'a blank source clears it');
    // The stored group set is read back sorted for stable comparisons.
    expect(stored.groupIds.length, 2);
    expect(stored.groupIds.toSet(), {groupIdA, groupIdB});
    expect(
      await repository
          .watchGroupItems(accountId: 'owner', groupId: groupIdB)
          .first
          .then((items) => items.map((i) => i.itemId)),
      [itemId],
      reason: 'the entry shows in the newly joined group too',
    );
    expect(await xpRows(), 0);
  });

  test(
    'edit rejects a deleted entry, a deleted group and invalid drafts',
    () async {
      final groupId = await seedGroup('group a');
      final itemId = await seedEntry(groupIds: [groupId]);
      await commands.deleteGroup(groupId: groupId);

      // The entry cascaded away with its last group: editing is itemDeleted.
      final deletedEntry = await commands.edit(
        itemId: itemId,
        draft: MyDhikrDraft(text: 'test dhikr', groupIds: [groupId]),
      );
      expect(deletedEntry.valueOrNull, isA<MyAdhkarItemDeleted>());

      // The entry survives on a second group, so an edit referencing the
      // deleted group reaches the group check.
      final otherGroup = await seedGroup('group b');
      final thirdGroup = await seedGroup('group c');
      final live = await seedEntry(groupIds: [otherGroup, thirdGroup]);
      await commands.deleteGroup(groupId: otherGroup);
      final deletedGroupRef = await commands.edit(
        itemId: live,
        draft: MyDhikrDraft(text: 'test dhikr', groupIds: [otherGroup]),
      );
      expect(deletedGroupRef.valueOrNull, isA<MyAdhkarGroupDeleted>());

      final invalid = await commands.edit(
        itemId: live,
        draft: const MyDhikrDraft(text: 'test dhikr'),
      );
      expect(
        invalid.failureOrNull!.messageKey,
        'my_adhkar.draft.empty_group_set',
      );
      expect(await xpRows(), 0);
    },
  );

  test('delete tombstones the entry with a monotonic updated_at and a '
      'second delete is a no-op', () async {
    final groupId = await seedGroup('group a');
    final itemId = await seedEntry(groupIds: [groupId]);
    final prior = (await repository.readFresh(
      accountId: 'owner',
      itemId: itemId,
    )).valueOrNull!;

    final outcome = await commands.delete(itemId: itemId);
    expect(outcome.valueOrNull, isA<MyAdhkarDeleted>());
    final tombstoned = (await repository.readFresh(
      accountId: 'owner',
      itemId: itemId,
    )).valueOrNull!;
    expect(tombstoned.isDeleted, isTrue);
    expect(
      tombstoned.updatedAt.isAfter(prior.updatedAt) ||
          tombstoned.updatedAt ==
              prior.updatedAt.add(const Duration(microseconds: 1)),
      isTrue,
      reason: 'the version moves forward monotonically',
    );
    expect(tombstoned.groupIds, isEmpty);

    final again = await commands.delete(itemId: itemId);
    expect(again.valueOrNull, isA<MyAdhkarDeleted>());
    final unchanged = (await repository.readFresh(
      accountId: 'owner',
      itemId: itemId,
    )).valueOrNull!;
    expect(unchanged.deletedAt, tombstoned.deletedAt);
    expect(await xpRows(), 0);
  });

  test('delete of an unknown entry fails with a typed failure', () async {
    final result = await commands.delete(
      itemId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    );
    expect(result.failureOrNull!.messageKey, 'my_adhkar.item.unknown');
    expect(await xpRows(), 0);
  });
}

/// A fixed clock: the commands sample `now` once per command.
final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}
