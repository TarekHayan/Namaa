import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../../../../support/foundation_test_support.dart';

/// T101: the reshaped My Adhkar store (data-model.md "My Adhkar", reshaped
/// 2026-11-16): groups and entries (text + optional source) with their
/// membership join, no counter. Group create/rename/delete with the FR-029
/// cascade and exactly ONE outbox entry for the group delete; membership
/// written in the same transaction as the entry with `added_at` kept for a
/// kept group; the edit guarded on `deleted_at IS NULL` and the prior
/// `updated_at`; the entry delete with a monotonic `updated_at`; outbox
/// types `my_adhkar_group` and `my_adhkar_item` only; owner isolation; and
/// never an `xp_awards` row (FR-026).
void main() {
  final key = List<int>.generate(32, (index) => index + 140);
  final now = DateTime.utc(2026, 11, 16, 9);

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    repository = DriftMyAdhkarRepository(db);
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  const entryGroupId = 'gggggggg-1111-4111-8111-111111111111';
  const otherGroupId = 'gggggggg-2222-4222-8222-222222222222';

  MyAdhkarGroup group({
    String groupId = entryGroupId,
    String name = 'test group',
    String owner = 'owner',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => MyAdhkarGroup(
    accountId: owner,
    groupId: groupId,
    name: name,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 16, 8),
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 16, 8, 30),
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  MyDhikrItem item({
    String owner = 'owner',
    String itemId = '11111111-2222-4333-8444-555555555555',
    String text = 'test dhikr',
    String? source = 'test source',
    required List<String> groupIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => MyDhikrItem(
    accountId: owner,
    itemId: itemId,
    text: text,
    source: source,
    groupIds: groupIds,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 16, 8, 40),
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 16, 8, 50),
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  Future<void> seedGroup([
    MyAdhkarGroup? seeded,
    String operationId = 'seed-group',
  ]) => repository.runInTransaction(
    () => repository.insertGroup(
      seeded ?? group(),
      operationId: operationId,
      queueForSync: false,
    ),
  );

  Future<void> seedItem(MyDhikrItem seeded, {String? operationId}) =>
      repository.runInTransaction(
        () => repository.insertItem(
          seeded,
          operationId: operationId ?? 'seed-${seeded.itemId}',
          queueForSync: false,
        ),
      );

  Future<int> xpAwardsCount() async =>
      (await db.rawScalar('SELECT count(*) FROM xp_awards')) as int;

  Future<List<Map<String, Object?>>> outboxRows() async {
    final rows = await db
        .customSelect(
          'SELECT entity_type, entity_id, kind FROM pending_changes '
          'ORDER BY created_at, operation_id',
        )
        .get();
    return [
      for (final row in rows)
        {
          'entityType': row.read<String>('entity_type'),
          'entityId': row.read<String>('entity_id'),
          'kind': row.read<int>('kind'),
        },
    ];
  }

  test(
    'group create, rename and watchGroups show the live entry counts',
    () async {
      await seedGroup();
      await seedGroup(
        group(
          groupId: otherGroupId,
          name: 'other group',
          createdAt: DateTime.utc(2026, 11, 16, 8, 10),
        ),
        'seed-group-2',
      );
      await seedItem(item(groupIds: const [entryGroupId]));
      await seedItem(
        item(
          itemId: '22222222-3333-4333-8444-555555555555',
          groupIds: const [entryGroupId, otherGroupId],
          createdAt: DateTime.utc(2026, 11, 16, 8, 45),
        ),
      );

      final groups = await repository.watchGroups('owner').first;
      expect(
        groups.map((s) => s.group.groupId),
        [entryGroupId, otherGroupId],
        reason: 'groups order by created_at, oldest first',
      );
      expect(groups.map((s) => s.liveEntryCount), [2, 1]);

      // A rename keeps the entries.
      final prior = (await repository.readGroupFresh(
        accountId: 'owner',
        groupId: entryGroupId,
      )).valueOrNull!;
      await repository.runInTransaction(() {
        return repository.renameGroup(
          prior.copyWith(name: 'renamed group', updatedAt: now),
          priorUpdatedAt: prior.updatedAt,
          operationId: 'op-rename-1',
          queueForSync: true,
        );
      });
      final renamed = await repository.watchGroups('owner').first;
      expect(renamed.first.group.name, 'renamed group');
      expect(renamed.first.liveEntryCount, 2, reason: 'a rename keeps entries');
      expect(renamed.first.group.createdAt, DateTime.utc(2026, 11, 16, 8));
      expect(await xpAwardsCount(), 0);
    },
  );

  test('the group delete cascade: an entry only in that group is deleted, '
      'an entry also in a live group stays', () async {
    await seedGroup();
    await seedGroup(
      group(groupId: otherGroupId, name: 'other group'),
      'seed-group-2',
    );
    await seedItem(item(groupIds: const [entryGroupId]));
    await seedItem(
      item(
        itemId: '22222222-3333-4333-8444-555555555555',
        groupIds: const [entryGroupId, otherGroupId],
        createdAt: DateTime.utc(2026, 11, 16, 8, 45),
      ),
    );

    final cascaded = await repository.runInTransaction(() {
      return repository.deleteGroupCascade(
        accountId: 'owner',
        groupId: entryGroupId,
        deletedAt: now,
        operationId: 'op-del-group',
        queueForSync: true,
      );
    });
    expect(cascaded.valueOrNull, 1, reason: 'only the first entry cascades');

    final groupsAfter = await repository.watchGroups('owner').first;
    expect(groupsAfter.map((s) => s.group.groupId), [otherGroupId]);
    expect(groupsAfter.single.liveEntryCount, 1);

    final cascadedEntry = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(cascadedEntry.isDeleted, isTrue);
    expect(cascadedEntry.deletedAt, now);
    expect(
      cascadedEntry.groupIds,
      isEmpty,
      reason: 'the cascade removed its membership',
    );
    expect(
      cascadedEntry.updatedAt.isAfter(DateTime.utc(2026, 11, 16, 8, 50)),
      isTrue,
      reason: 'the cascaded tombstone carries a monotonic updated_at',
    );

    final keptEntry = (await repository.readFresh(
      accountId: 'owner',
      itemId: '22222222-3333-4333-8444-555555555555',
    )).valueOrNull!;
    expect(keptEntry.isDeleted, isFalse);
    expect(keptEntry.groupIds, [
      otherGroupId,
    ], reason: 'FR-029: an entry in another live group stays');
    final groupItems = await repository
        .watchGroupItems(accountId: 'owner', groupId: otherGroupId)
        .first;
    expect(groupItems.map((i) => i.itemId), [
      '22222222-3333-4333-8444-555555555555',
    ]);

    // Exactly ONE outbox entry for the group delete: the group, never the
    // cascaded entry (the server applies the same cascade itself).
    final rows = await outboxRows();
    expect(rows, hasLength(1));
    expect(rows.single['entityType'], 'my_adhkar_group');
    expect(rows.single['entityId'], entryGroupId);
    expect(rows.single['kind'], 1, reason: 'the delete is an update');
    expect(await xpAwardsCount(), 0);
  });

  test('previewDeleteMyAdhkarGroup support: liveEntriesOnlyInGroup counts '
      'the entries the delete would remove', () async {
    await seedGroup();
    await seedGroup(
      group(groupId: otherGroupId, name: 'other group'),
      'seed-group-2',
    );
    await seedItem(item(groupIds: const [entryGroupId]));
    await seedItem(
      item(
        itemId: '22222222-3333-4333-8444-555555555555',
        groupIds: const [entryGroupId, otherGroupId],
        createdAt: DateTime.utc(2026, 11, 16, 8, 45),
      ),
    );
    expect(
      (await repository.liveEntriesOnlyInGroup(
        accountId: 'owner',
        groupId: entryGroupId,
      )).valueOrNull,
      1,
    );
    expect(
      (await repository.liveEntriesOnlyInGroup(
        accountId: 'owner',
        groupId: otherGroupId,
      )).valueOrNull,
      0,
      reason: 'its single entry also lives in the other group',
    );
  });

  test('membership is written with the entry in one transaction and a kept '
      'group keeps its added_at', () async {
    await seedGroup();
    await seedGroup(
      group(groupId: otherGroupId, name: 'other group'),
      'seed-group-2',
    );
    await seedItem(item(groupIds: const [entryGroupId, otherGroupId]));

    String? originalAddedAt;
    final membershipRows = await db
        .customSelect(
          'SELECT group_id, added_at FROM my_adhkar_item_groups '
          "WHERE account_id = 'owner' AND item_id = "
          "'11111111-2222-4333-8444-555555555555' ORDER BY group_id",
        )
        .get();
    expect(membershipRows.map((r) => r.read<String>('group_id')), [
      entryGroupId,
      otherGroupId,
    ]);
    originalAddedAt = membershipRows.first.read<String>('added_at');
    expect(
      DateTime.parse(membershipRows.first.read<String>('added_at')),
      DateTime.utc(2026, 11, 16, 8, 40),
      reason: 'on add, added_at is the entry creation time',
    );

    // Edit: keep the first group, drop the second, add a third. The kept
    // group's added_at stays; the new group gets the edit time.
    final prior = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    const thirdGroupId = 'gggggggg-3333-4333-8333-333333333333';
    await seedGroup(
      group(groupId: thirdGroupId, name: 'third group'),
      'seed-group-3',
    );
    final editTime = DateTime.utc(2026, 11, 16, 10);
    await repository.runInTransaction(() {
      return repository.updateItem(
        prior.copyWith(
          text: 'edited dhikr',
          groupIds: [entryGroupId, thirdGroupId],
          updatedAt: editTime,
        ),
        priorUpdatedAt: prior.updatedAt,
        operationId: 'op-edit-1',
        queueForSync: true,
      );
    });

    final after = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(after.text, 'edited dhikr');
    expect(after.groupIds, [entryGroupId, thirdGroupId]);
    final rowsAfter = await db
        .customSelect(
          'SELECT group_id, added_at FROM my_adhkar_item_groups '
          "WHERE account_id = 'owner' AND item_id = "
          "'11111111-2222-4333-8444-555555555555' ORDER BY group_id",
        )
        .get();
    expect(
      rowsAfter.map((r) => r.read<String>('group_id')),
      [entryGroupId, thirdGroupId],
      reason: 'the removed group lost its membership row',
    );
    expect(
      rowsAfter.first.read<String>('added_at'),
      originalAddedAt,
      reason: 'a kept group keeps its added_at',
    );
    expect(
      DateTime.parse(rowsAfter.last.read<String>('added_at')),
      editTime,
      reason: 'a new group gets the edit time',
    );
  });

  test('watchGroupItems orders by the membership added_at', () async {
    await seedGroup();
    // Added to the group later, but created first.
    await seedItem(
      item(
        itemId: '22222222-3333-4333-8444-555555555555',
        groupIds: const [entryGroupId],
        createdAt: DateTime.utc(2026, 11, 16, 8, 45),
        updatedAt: DateTime.utc(2026, 11, 16, 8, 55),
      ),
    );
    await seedItem(item(groupIds: const [entryGroupId]));
    final items = await repository
        .watchGroupItems(accountId: 'owner', groupId: entryGroupId)
        .first;
    expect(
      items.map((i) => i.itemId),
      [
        '11111111-2222-4333-8444-555555555555',
        '22222222-3333-4333-8444-555555555555',
      ],
      reason: 'the order inside the group is added_at, oldest first',
    );
  });

  test(
    'the edit is guarded on deleted_at IS NULL and the prior updated_at',
    () async {
      await seedGroup();
      await seedItem(item(groupIds: const [entryGroupId]));
      final prior = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;

      // A stale prior version is rejected and writes nothing.
      final stale = await repository.runInTransaction(() {
        return repository.updateItem(
          prior.copyWith(text: 'stale edit', updatedAt: now),
          priorUpdatedAt: DateTime.utc(2026, 11, 16, 8, 49),
          operationId: 'op-edit-stale',
          queueForSync: false,
        );
      });
      expect(stale.failureOrNull, isNotNull);
      expect(
        (await repository.readFresh(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
        )).valueOrNull!.text,
        'test dhikr',
        reason: 'a stale edit writes nothing',
      );

      // Delete the entry, then an edit against the pre-delete state must be
      // rejected by the deleted_at IS NULL guard.
      await repository.runInTransaction(() {
        return repository.markItemDeleted(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
          deletedAt: now,
          operationId: 'op-del-1',
          queueForSync: false,
        );
      });
      final afterDelete = await repository.runInTransaction(() {
        return repository.updateItem(
          prior.copyWith(text: 'resurrecting edit', updatedAt: now),
          priorUpdatedAt: prior.updatedAt,
          operationId: 'op-edit-del',
          queueForSync: false,
        );
      });
      expect(afterDelete.failureOrNull, isNotNull);
      final stored = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      expect(stored.isDeleted, isTrue, reason: 'deletion is final');
      expect(stored.text, 'test dhikr', reason: 'never a resurrection');
      expect(await xpAwardsCount(), 0);
    },
  );

  test(
    'the entry delete uses a monotonic updated_at never before createdAt',
    () async {
      await seedGroup();
      await seedItem(item(groupIds: const [entryGroupId]));
      // A delete "now" that sits before the prior updated_at: the tombstone
      // still moves forward.
      final early = await repository.runInTransaction(() {
        return repository.markItemDeleted(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
          deletedAt: DateTime.utc(2026, 11, 16, 8),
          operationId: 'op-del-early',
          queueForSync: false,
        );
      });
      final tombstoned = early.valueOrNull!;
      expect(tombstoned.isDeleted, isTrue);
      expect(
        tombstoned.updatedAt,
        DateTime.utc(2026, 11, 16, 8, 50, 0, 0, 1),
        reason: 'max(now, prior + 1 microsecond)',
      );
      expect(
        tombstoned.updatedAt.isBefore(tombstoned.createdAt),
        isFalse,
        reason: 'never before createdAt',
      );
      expect(
        await repository
            .watchGroupItems(accountId: 'owner', groupId: entryGroupId)
            .first,
        isEmpty,
        reason: 'a deleted entry is hidden from its group',
      );
    },
  );

  test('outbox types are my_adhkar_group and my_adhkar_item only, with '
      'create and update kinds', () async {
    // Queued: the group create must land in the outbox too.
    await repository.runInTransaction(() {
      return repository.insertGroup(
        group(),
        operationId: 'op-group-add',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() {
      return repository.insertItem(
        item(groupIds: const [entryGroupId]),
        operationId: 'op-item-add',
        queueForSync: true,
      );
    });
    final prior = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    await repository.runInTransaction(() {
      return repository.updateItem(
        prior.copyWith(text: 'edited dhikr', updatedAt: now),
        priorUpdatedAt: prior.updatedAt,
        operationId: 'op-item-edit',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() {
      return repository.renameGroup(
        group(name: 'renamed group', updatedAt: now),
        priorUpdatedAt: DateTime.utc(2026, 11, 16, 8, 30),
        operationId: 'op-group-rename',
        queueForSync: true,
      );
    });

    final rows = await outboxRows();
    // Ordered by created_at then operation_id: the item edit and the group
    // rename share the same instant, so their operation ids decide.
    expect(rows.map((r) => r['entityType']), [
      'my_adhkar_group',
      'my_adhkar_item',
      'my_adhkar_group',
      'my_adhkar_item',
    ]);
    expect(rows.map((r) => r['kind']), [0, 0, 1, 1]);

    // The entry payload carries the group set and never an owner or XP
    // field; the group payload never carries an entry.
    final payloads = await db
        .customSelect(
          'SELECT entity_type, serialized_change FROM pending_changes '
          'ORDER BY version_timestamp',
        )
        .get();
    final entryPayload =
        jsonDecode(
              payloads
                  .where(
                    (row) =>
                        row.read<String>('entity_type') == 'my_adhkar_item',
                  )
                  .first
                  .read<String>('serialized_change'),
            )
            as Map<String, dynamic>;
    expect(entryPayload['item_id'], '11111111-2222-4333-8444-555555555555');
    expect(entryPayload['text'], isA<String>());
    expect(entryPayload['source'], isA<String?>());
    expect(entryPayload['group_ids'], [entryGroupId]);
    expect(entryPayload.keys, isNot(contains('owner')));
    expect(entryPayload.keys, isNot(contains('amount')));
    final groupPayload =
        jsonDecode(
              payloads
                  .where(
                    (row) =>
                        row.read<String>('entity_type') == 'my_adhkar_group',
                  )
                  .first
                  .read<String>('serialized_change'),
            )
            as Map<String, dynamic>;
    expect(groupPayload['group_id'], entryGroupId);
    expect(groupPayload['name'], isA<String>());
    expect(groupPayload.keys, isNot(contains('owner')));
    expect(await xpAwardsCount(), 0);
  });

  test(
    'owner isolation: owner B never sees owner A groups or entries',
    () async {
      await seedGroup();
      await seedItem(item(groupIds: const [entryGroupId]));
      expect(await repository.watchGroups('owner-b').first, isEmpty);
      expect(
        await repository
            .watchGroupItems(accountId: 'owner-b', groupId: entryGroupId)
            .first,
        isEmpty,
      );
      expect(
        (await repository.readGroupFresh(
          accountId: 'owner-b',
          groupId: entryGroupId,
        )).valueOrNull,
        isNull,
      );
      expect(
        (await repository.readFresh(
          accountId: 'owner-b',
          itemId: '11111111-2222-4333-8444-555555555555',
        )).valueOrNull,
        isNull,
      );
      expect(await repository.watchGroups('owner').first, hasLength(1));
      expect(await xpAwardsCount(), 0);
    },
  );
}
