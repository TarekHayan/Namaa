import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../../../../support/foundation_test_support.dart';

/// T087: the transactional My Adhkar store (data-model.md "My Adhkar"):
/// add, edit, delete, increment and reset in one transaction each, the
/// 100-live-item limit, the target-lowering clamp written in the SAME
/// transaction as the edit, deleted items hidden from `watchItems`, outbox
/// entries of type `my_adhkar_item` and `my_adhkar_count`, owner isolation,
/// and never an `xp_awards` row. My Adhkar never touches XP (FR-026).
void main() {
  final key = List<int>.generate(32, (index) => index + 140);

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

  MyDhikrItem item({
    String owner = 'owner',
    String itemId = '11111111-2222-4333-8444-555555555555',
    String text = 'test dhikr',
    int target = 33,
    String? note = 'test note',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => MyDhikrItem(
    accountId: owner,
    itemId: itemId,
    text: text,
    target: target,
    note: note,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 15, 8),
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 15, 9),
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  MyAdhkarCountCommitRequest countRequest({
    String owner = 'owner',
    String itemId = '11111111-2222-4333-8444-555555555555',
    String day = '2026-11-15',
    int newCount = 1,
    required DateTime updatedAt,
    String operationId = 'op-count-1',
    bool hadPrior = false,
    bool queueForSync = true,
    DateTime? expectedCurrentVersion,
  }) => MyAdhkarCountCommitRequest(
    accountId: owner,
    itemId: itemId,
    adhkarDay: day,
    recordId: 'rec-${itemId.substring(0, 8)}-$day',
    newCount: newCount,
    createdAt: DateTime.utc(2026, 11, 15, 8),
    updatedAt: updatedAt,
    operationId: operationId,
    expectedCurrentVersion: expectedCurrentVersion,
    acknowledgedBase: null,
    queueForSync: queueForSync,
    hadPrior: hadPrior,
  );

  Future<List<Map<String, dynamic>>> outboxRows() async {
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

  test('add inserts the item and watchItems returns it oldest first', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(
          itemId: '22222222-3333-4777-8888-999999999999',
          text: 'test dhikr second',
          createdAt: DateTime.utc(2026, 11, 15, 7),
        ),
        operationId: 'op-add-2',
        queueForSync: true,
      );
    });
    final watched = await repository.watchItems('owner').first;
    expect(watched.map((i) => i.itemId), [
      // Oldest first by created_at, not by insertion order.
      '22222222-3333-4777-8888-999999999999',
      '11111111-2222-4333-8444-555555555555',
    ]);
    expect(
      watched
          .singleWhere(
            (i) => i.itemId == '11111111-2222-4333-8444-555555555555',
          )
          .text,
      'test dhikr',
    );
  });

  test('edit keeps the item identity and today\'s count', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    await repository.commitCount(
      countRequest(newCount: 7, updatedAt: DateTime.utc(2026, 11, 15, 9, 30)),
    );
    final prior = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    final edited = prior.copyWith(
      text: 'edited dhikr',
      target: 10,
      note: null,
      updatedAt: DateTime.utc(2026, 11, 15, 10),
    );
    await repository.runInTransaction(() async {
      return repository.updateItem(
        edited,
        operationId: 'op-edit-1',
        queueForSync: true,
      );
    });
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(stored.text, 'edited dhikr');
    expect(stored.target, 10);
    expect(stored.note, isNull);
    expect(stored.createdAt, DateTime.utc(2026, 11, 15, 8));
    // Today's count is untouched by the item edit itself.
    final count = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    expect(count.valueOrNull!.count, 7);
  });

  test('delete tombstones the item, hides it from watchItems and keeps '
      'deletion final', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() async {
      return repository.markDeleted(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        deletedAt: DateTime.utc(2026, 11, 15, 11),
        updatedAt: DateTime.utc(2026, 11, 15, 11),
        operationId: 'op-del-1',
        queueForSync: true,
      );
    });
    expect(await repository.watchItems('owner').first, isEmpty);
    final stored = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(stored.isDeleted, isTrue);
    expect(stored.deletedAt, DateTime.utc(2026, 11, 15, 11));
    // Deleting an already deleted item is a no-op that never changes the
    // tombstone (data-model.md, Delete command).
    await repository.runInTransaction(() async {
      return repository.markDeleted(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        deletedAt: DateTime.utc(2026, 11, 15, 12),
        updatedAt: DateTime.utc(2026, 11, 15, 12),
        operationId: 'op-del-2',
        queueForSync: true,
      );
    });
    final again = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(again.deletedAt, DateTime.utc(2026, 11, 15, 11));
  });

  test('increment writes count+1 and a reset persists a 0 row', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    final first = await repository.commitCount(
      countRequest(updatedAt: DateTime.utc(2026, 11, 15, 9, 1)),
    );
    expect(first.valueOrNull!.wroteCount, isTrue);
    expect(first.valueOrNull!.newCount, 1);
    final reset = await repository.commitCount(
      countRequest(
        newCount: 0,
        updatedAt: DateTime.utc(2026, 11, 15, 9, 2),
        operationId: 'op-count-2',
        hadPrior: true,
        expectedCurrentVersion: DateTime.utc(2026, 11, 15, 9, 1),
      ),
    );
    expect(reset.valueOrNull!.wroteCount, isTrue);
    final stored = await repository.readCountFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
      adhkarDay: '2026-11-15',
    );
    // The 0 row is persisted, so a stale count cannot come back.
    expect(stored.valueOrNull!.count, 0);
    final watched = await repository
        .watchCounts(accountId: 'owner', adhkarDay: '2026-11-15')
        .first;
    expect(watched.single.count, 0);
  });

  test('the live-item limit counts only non-deleted items', () async {
    for (var i = 0; i < 3; i++) {
      final n = i.toString().padLeft(8, '3');
      await repository.runInTransaction(() async {
        return repository.insertItem(
          item(itemId: '$n-4444-4333-8444-555555555555'),
          operationId: 'op-add-$i',
          queueForSync: false,
        );
      });
    }
    expect((await repository.liveItemCount(accountId: 'owner')).valueOrNull, 3);
    await repository.runInTransaction(() async {
      return repository.markDeleted(
        accountId: 'owner',
        itemId: '33333330-4444-4333-8444-555555555555',
        deletedAt: DateTime.utc(2026, 11, 15, 11),
        updatedAt: DateTime.utc(2026, 11, 15, 11),
        operationId: 'op-del-0',
        queueForSync: false,
      );
    });
    expect(
      (await repository.liveItemCount(accountId: 'owner')).valueOrNull,
      2,
      reason: 'deleted items do not count against the limit',
    );
    expect(
      (await repository.liveItemCount(accountId: 'owner-b')).valueOrNull,
      0,
    );
    expect(canAddMyDhikr(99), isTrue);
    expect(canAddMyDhikr(100), isFalse);
  });

  test('the target-lowering clamp writes today\'s count in the SAME '
      'transaction as the edit', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: false,
      );
    });
    await repository.commitCount(
      countRequest(newCount: 33, updatedAt: DateTime.utc(2026, 11, 15, 9, 30)),
    );
    // One transaction: the item edit and the clamped count write together…
    final committed = await repository.runInTransaction(() async {
      final prior = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      final editResult = await repository.updateItem(
        prior.copyWith(target: 10, updatedAt: DateTime.utc(2026, 11, 15, 10)),
        operationId: 'op-edit-1',
        queueForSync: false,
      );
      if (editResult.failureOrNull != null) return editResult;
      // FR-025: lowering the target below today's count sets the count to
      // the new target, in the same transaction as the edit.
      return repository.commitCount(
        MyAdhkarCountCommitRequest(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
          adhkarDay: '2026-11-15',
          recordId: 'rec-11111111-2026-11-15',
          newCount: clampMyDhikrCount(33, 10),
          createdAt: DateTime.utc(2026, 11, 15, 8),
          updatedAt: DateTime.utc(2026, 11, 15, 10),
          operationId: 'op-count-clamp',
          expectedCurrentVersion: DateTime.utc(2026, 11, 15, 9, 30),
          acknowledgedBase: null,
          queueForSync: false,
          hadPrior: true,
        ),
      );
    });
    expect(committed.failureOrNull, isNull);
    expect(
      (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!.target,
      10,
    );
    expect(
      (await repository.readCountFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        adhkarDay: '2026-11-15',
      )).valueOrNull!.count,
      10,
    );

    // …and a failure AFTER the count write rolls BOTH writes back.
    final rolledBack = await repository.runInTransaction(() async {
      final prior = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      await repository.updateItem(
        prior.copyWith(
          text: 'rolled back',
          updatedAt: DateTime.utc(2026, 11, 15, 11),
        ),
        operationId: 'op-edit-2',
        queueForSync: false,
      );
      await repository.commitCount(
        MyAdhkarCountCommitRequest(
          accountId: 'owner',
          itemId: '11111111-2222-4333-8444-555555555555',
          adhkarDay: '2026-11-15',
          recordId: 'rec-11111111-2026-11-15',
          newCount: 5,
          createdAt: DateTime.utc(2026, 11, 15, 8),
          updatedAt: DateTime.utc(2026, 11, 15, 11),
          operationId: 'op-count-rollback',
          expectedCurrentVersion: DateTime.utc(2026, 11, 15, 10),
          acknowledgedBase: null,
          queueForSync: false,
          hadPrior: true,
        ),
      );
      return AppResult<void>.failure(expectedFailure);
    });
    expect(rolledBack.failureOrNull, isNotNull);
    final after = (await repository.readFresh(
      accountId: 'owner',
      itemId: '11111111-2222-4333-8444-555555555555',
    )).valueOrNull!;
    expect(after.text, 'test dhikr', reason: 'the edit rolled back');
    expect(
      (await repository.readCountFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        adhkarDay: '2026-11-15',
      )).valueOrNull!.count,
      10,
      reason: 'the count write rolled back too',
    );
  });

  test('outbox entries use the my_adhkar_item and my_adhkar_count entity '
      'types with create and update kinds', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    await repository.commitCount(
      countRequest(updatedAt: DateTime.utc(2026, 11, 15, 9, 1)),
    );
    await repository.commitCount(
      countRequest(
        newCount: 2,
        updatedAt: DateTime.utc(2026, 11, 15, 9, 2),
        operationId: 'op-count-2',
        hadPrior: true,
        expectedCurrentVersion: DateTime.utc(2026, 11, 15, 9, 1),
      ),
    );
    await repository.runInTransaction(() async {
      final prior = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      return repository.updateItem(
        prior.copyWith(
          text: 'edited dhikr',
          updatedAt: DateTime.utc(2026, 11, 15, 10),
        ),
        operationId: 'op-edit-1',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() async {
      return repository.markDeleted(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        deletedAt: DateTime.utc(2026, 11, 15, 11),
        updatedAt: DateTime.utc(2026, 11, 15, 11),
        operationId: 'op-del-1',
        queueForSync: true,
      );
    });

    final rows = await outboxRows();
    final itemEntries = rows
        .where((r) => r['entityType'] == 'my_adhkar_item')
        .toList();
    final countEntries = rows
        .where((r) => r['entityType'] == 'my_adhkar_count')
        .toList();
    // add (create) + edit (update) + delete (update)
    expect(itemEntries.map((r) => r['kind']), [0, 1, 1]);
    // count create + count update
    expect(countEntries.map((r) => r['kind']), [0, 1]);
    expect(countEntries.first['entityId'], 'rec-11111111-2026-11-15');

    // The serialized payloads carry the My Adhkar fields and never an
    // owner id, list, catalog version or XP amount.
    final payloads = await db
        .customSelect(
          'SELECT entity_type, serialized_change FROM pending_changes '
          'ORDER BY entity_type, version_timestamp',
        )
        .get();
    for (final row in payloads) {
      final payload =
          jsonDecode(row.read<String>('serialized_change'))
              as Map<String, dynamic>;
      expect(payload.keys, isNot(contains('owner')));
      expect(payload.keys, isNot(contains('owner_id')));
      expect(payload.keys, isNot(contains('amount')));
      if (row.read<String>('entity_type') == 'my_adhkar_item') {
        expect(payload['item_id'], '11111111-2222-4333-8444-555555555555');
        expect(payload['text'], isA<String>());
        expect(payload['target'], isA<int>());
      } else {
        expect(payload['record_id'], 'rec-11111111-2026-11-15');
        expect(payload['count'], isA<int>());
      }
    }
  });

  test(
    'owner isolation: owner B never sees owner A\'s items or counts',
    () async {
      await repository.runInTransaction(() async {
        return repository.insertItem(
          item(owner: 'owner-a'),
          operationId: 'op-add-a',
          queueForSync: false,
        );
      });
      await repository.commitCount(
        countRequest(
          owner: 'owner-a',
          newCount: 3,
          updatedAt: DateTime.utc(2026, 11, 15, 9, 1),
        ),
      );
      expect(await repository.watchItems('owner-b').first, isEmpty);
      expect(
        await repository
            .watchCounts(accountId: 'owner-b', adhkarDay: '2026-11-15')
            .first,
        isEmpty,
      );
      final bRead = await repository.readFresh(
        accountId: 'owner-b',
        itemId: '11111111-2222-4333-8444-555555555555',
      );
      expect(bRead.valueOrNull, isNull);
      // Owner A still sees their own data.
      expect(await repository.watchItems('owner-a').first, hasLength(1));
    },
  );

  test('no xp_awards row is ever written by any My Adhkar operation', () async {
    await repository.runInTransaction(() async {
      return repository.insertItem(
        item(),
        operationId: 'op-add-1',
        queueForSync: true,
      );
    });
    await repository.commitCount(
      countRequest(newCount: 33, updatedAt: DateTime.utc(2026, 11, 15, 9, 30)),
    );
    await repository.runInTransaction(() async {
      final prior = (await repository.readFresh(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
      )).valueOrNull!;
      return repository.updateItem(
        prior.copyWith(target: 10, updatedAt: DateTime.utc(2026, 11, 15, 10)),
        operationId: 'op-edit-1',
        queueForSync: true,
      );
    });
    await repository.runInTransaction(() async {
      return repository.markDeleted(
        accountId: 'owner',
        itemId: '11111111-2222-4333-8444-555555555555',
        deletedAt: DateTime.utc(2026, 11, 15, 11),
        updatedAt: DateTime.utc(2026, 11, 15, 11),
        operationId: 'op-del-1',
        queueForSync: true,
      );
    });
    expect(
      await db.rawScalar('SELECT count(*) FROM xp_awards'),
      0,
      reason: 'My Adhkar never touches the XP ledger (FR-026)',
    );
  });
}

/// A marker failure used to force a transaction rollback.
final expectedFailure = AppFailure.recoverable(
  category: AppFailureCategory.persistence,
  messageKey: 'test.marker',
  occurredAt: DateTime.utc(2026, 11, 15),
);
