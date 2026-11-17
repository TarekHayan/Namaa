import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_inbound_sync_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_sync_service.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_inbound_sync_port.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_inbound_synchronizer.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_reconciler.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_remote_models.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_reader.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../../../../support/foundation_test_support.dart';

/// T094: the My Adhkar inbound pass (contracts/adhkar-qiyam-sync.md): keyset
/// pages for groups, entries (with their group sets) and conflicts that
/// restart from the first key on every pass; a failed page applies nothing
/// and the retry does not advance a cursor; the owner is validated; the
/// server's group-delete cascade is applied locally; tombstones apply and
/// never clear; pending local work is kept; and a My Adhkar failure stays
/// inside its own pass (T095, the Phase 6 isolation rule).
void main() {
  const g1 = 'aaaaaaaa-0000-4000-8000-000000000001';
  const g2 = 'aaaaaaaa-0000-4000-8000-000000000002';
  const g3 = 'aaaaaaaa-0000-4000-8000-000000000003';
  const g4 = 'aaaaaaaa-0000-4000-8000-000000000004';
  const g5 = 'aaaaaaaa-0000-4000-8000-000000000005';
  const i1 = 'bbbbbbbb-0000-4000-8000-000000000001';
  const i2 = 'bbbbbbbb-0000-4000-8000-000000000002';
  const i3 = 'bbbbbbbb-0000-4000-8000-000000000003';
  final created = DateTime.utc(2026, 11, 16, 8);
  final at = DateTime.utc(2026, 11, 16, 9);

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late FakePageSource source;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 210),
    );
    repository = DriftMyAdhkarRepository(db);
    source = FakePageSource();
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  MyAdhkarInboundSynchronizer synchronizer({int pageSize = 100}) =>
      MyAdhkarInboundSynchronizer(
        reader: SupabaseMyAdhkarReader(source, pageSize: pageSize),
        reconciler: MyAdhkarReconciler(
          repository: repository,
          localStore: DriftLocalStore(db),
        ),
      );

  Future<AppResult<MyAdhkarInboundSummary>> receive({int pageSize = 100}) =>
      synchronizer(
        pageSize: pageSize,
      ).receive(accountId: 'owner', isCurrentScope: () => true);

  Future<int> xpRows() async =>
      (await db.rawScalar('SELECT count(*) FROM xp_awards')) as int;

  Future<List<String>> liveGroupNames() async => [
    for (final s in await repository.watchGroups('owner').first) s.group.name,
  ];

  Future<MyDhikrItem?> entry(String id) async =>
      (await repository.readFresh(accountId: 'owner', itemId: id)).valueOrNull;

  Future<MyAdhkarGroup?> groupRecord(String id) async =>
      (await repository.readGroupFresh(
        accountId: 'owner',
        groupId: id,
      )).valueOrNull;

  Future<void> seedLocal({
    List<MyAdhkarGroup> groups = const [],
    List<MyDhikrItem> items = const [],
    bool queue = false,
  }) async {
    final result = await repository.runInTransaction(() async {
      for (final group in groups) {
        final inserted = await repository.insertGroup(
          group,
          operationId: 'seed-g-${group.groupId}',
          queueForSync: queue,
        );
        if (inserted.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
      }
      for (final item in items) {
        final inserted = await repository.insertItem(
          item,
          operationId: 'seed-i-${item.itemId}',
          queueForSync: queue,
        );
        if (inserted.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
      }
      return const AppResult<void>.success(null);
    });
    expect(result.failureOrNull, isNull);
  }

  MyAdhkarGroup localGroup(
    String id, {
    String name = 'local group',
    DateTime? updatedAt,
    DateTime? acknowledged,
    DateTime? deletedAt,
  }) => MyAdhkarGroup(
    accountId: 'owner',
    groupId: id,
    name: name,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    lastAcknowledgedUpdatedAt: acknowledged,
    deletedAt: deletedAt,
  );

  MyDhikrItem localItem(
    String id,
    List<String> groups, {
    String text = 'local entry',
    DateTime? updatedAt,
    DateTime? acknowledged,
  }) => MyDhikrItem(
    accountId: 'owner',
    itemId: id,
    text: text,
    source: null,
    groupIds: groups,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    lastAcknowledgedUpdatedAt: acknowledged,
    deletedAt: null,
  );

  suite('keyset pages', () {
    test('groups, entries and conflicts are read in key order, each page '
        'starting strictly after the last key of the previous one', () async {
      source
        ..groups = [
          for (final id in [g3, g1, g2, g5, g4]) groupRow(id),
        ]
        ..items = [
          for (final id in [i2, i1, i3]) itemRow(id, [g1]),
        ]
        ..conflicts = [conflictRow(cid(2)), conflictRow(cid(1))];
      final snapshot = await SupabaseMyAdhkarReader(
        source,
        pageSize: 2,
      ).readAll('owner');
      expect(snapshot.groups.map((g) => g.groupId), [g1, g2, g3, g4, g5]);
      expect(snapshot.items.map((i) => i.itemId), [i1, i2, i3]);
      expect(snapshot.conflicts.map((c) => c.id), [cid(1), cid(2)]);
      expect(source.cursors['groups'], [null, g2, g4]);
      expect(source.cursors['items'], [null, i2]);
      expect(source.cursors['conflicts'], [null, cid(2)]);
    });

    test('an exact multiple of the page size ends on an empty page', () async {
      source.groups = [groupRow(g1), groupRow(g2)];
      final snapshot = await SupabaseMyAdhkarReader(
        source,
        pageSize: 2,
      ).readAll('owner');
      expect(snapshot.groups, hasLength(2));
      expect(source.cursors['groups'], [null, g2]);
    });

    test(
      'an entry page carries each entry\'s group set and added_at',
      () async {
        source.items = [
          itemRow(
            i1,
            [g2, g1],
            addedAt: {g1: at, g2: at.add(const Duration(minutes: 1))},
          ),
          itemRow(i2, const [], deleted: true),
        ];
        final snapshot = await SupabaseMyAdhkarReader(source).readAll('owner');
        final live = snapshot.items.first;
        expect(live.groupIds, [g1, g2]);
        expect(live.groupAddedAt[g2], at.add(const Duration(minutes: 1)));
        expect(snapshot.items.last.isDeleted, isTrue);
        expect(snapshot.items.last.groupIds, isEmpty);
      },
    );

    test('a failed page fails the read; the retry restarts from the first '
        'key and the cursor never advanced past the failure', () async {
      source
        ..groups = [
          for (final id in [g1, g2, g3, g4]) groupRow(id),
        ]
        ..failGroupPageOnCall = 2;
      final reader = SupabaseMyAdhkarReader(source, pageSize: 2);
      await expectLater(reader.readAll('owner'), throwsA(isA<StateError>()));
      source.cursors['groups']!.clear();
      final snapshot = await reader.readAll('owner');
      expect(snapshot.groups, hasLength(4));
      expect(source.cursors['groups']!.first, isNull);
    });

    test(
      'a page that does not advance, or is oversized, fails the read',
      () async {
        source
          ..groups = [groupRow(g1), groupRow(g2)]
          ..ignoreCursor = true;
        await expectLater(
          SupabaseMyAdhkarReader(source, pageSize: 2).readAll('owner'),
          throwsFormatException,
        );
        source
          ..ignoreCursor = false
          ..ignoreLimit = true;
        await expectLater(
          SupabaseMyAdhkarReader(source, pageSize: 1).readAll('owner'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('a foreign owner row or an account change fails the read', () async {
      source.groups = [groupRow(g1, owner: 'someone-else')];
      await expectLater(
        SupabaseMyAdhkarReader(source).readAll('owner'),
        throwsFormatException,
      );
      source
        ..groups = [groupRow(g1)]
        ..switchAccountAfterFirstPage = true;
      await expectLater(
        SupabaseMyAdhkarReader(source).readAll('owner'),
        throwsA(isA<StateError>()),
      );
    });
  });

  suite('reconciliation', () {
    test('a snapshot of groups, entries and a conflict is imported', () async {
      source
        ..groups = [groupRow(g1, name: 'remote group 1'), groupRow(g2)]
        ..items = [
          itemRow(i1, [g1, g2], text: 'remote entry 1', source: 'source 1'),
          itemRow(i2, [g2]),
        ]
        ..conflicts = [conflictRow(cid(1), entityId: i1)];
      final result = await receive(pageSize: 2);
      final summary = result.valueOrNull!;
      expect(summary.importedGroups, 2);
      expect(summary.importedItems, 2);
      expect(summary.importedConflicts, 1);
      expect(await liveGroupNames(), ['remote group 1', 'remote group 2']);
      final first = (await entry(i1))!;
      expect(first.text, 'remote entry 1');
      expect(first.source, 'source 1');
      expect(first.groupIds, [g1, g2]);
      expect(first.lastAcknowledgedUpdatedAt, at);
      final conflicts = await repository.watchConflicts('owner').first;
      expect(conflicts.single.id, cid(1));
      expect(conflicts.single.entityId, i1);
      expect(await xpRows(), 0);
      expect(
        (await DriftLocalStore(db).readPendingChanges('owner')).valueOrNull,
        isEmpty,
        reason: 'an import never queues an outbound operation',
      );
    });

    test('importing the same snapshot again changes nothing', () async {
      source
        ..groups = [groupRow(g1)]
        ..items = [
          itemRow(i1, [g1]),
        ]
        ..conflicts = [conflictRow(cid(1), entityId: i1)];
      await receive();
      final again = (await receive()).valueOrNull!;
      expect(again.importedGroups, 0);
      expect(again.importedItems, 0);
      expect(await repository.watchConflicts('owner').first, hasLength(1));
    });

    test('a failed page applies nothing and the next pass restarts from the '
        'start', () async {
      source
        ..groups = [
          for (final id in [g1, g2, g3]) groupRow(id),
        ]
        ..items = [
          itemRow(i1, [g1]),
        ]
        ..failItemPageOnCall = 1;
      final failed = await receive(pageSize: 2);
      expect(failed.failureOrNull, isNotNull);
      expect(failed.failureOrNull!.recoverable, isTrue);
      expect(await liveGroupNames(), isEmpty, reason: 'nothing is applied');
      for (final list in source.cursors.values) {
        list.clear();
      }
      final retried = await receive(pageSize: 2);
      expect(retried.valueOrNull!.importedGroups, 3);
      expect(retried.valueOrNull!.importedItems, 1);
      expect(source.cursors['groups']!.first, isNull);
    });

    test(
      'a foreign-owner row fails the whole pass with nothing applied',
      () async {
        source
          ..groups = [groupRow(g1), groupRow(g2, owner: 'someone-else')]
          ..items = [
            itemRow(i1, [g1]),
          ];
        final result = await receive();
        expect(result.failureOrNull, isNotNull);
        expect(await liveGroupNames(), isEmpty);
        expect(await entry(i1), isNull);
      },
    );

    test('a stale scope fails the pass before anything is applied', () async {
      source.groups = [groupRow(g1)];
      final result = await synchronizer().receive(
        accountId: 'owner',
        isCurrentScope: () => false,
      );
      expect(result.failureOrNull?.category, AppFailureCategory.authorization);
      expect(await liveGroupNames(), isEmpty);
    });

    test(
      'a server group-delete cascade is applied locally: the entry left '
      'with no live group is deleted, the one in another group stays',
      () async {
        await seedLocal(
          groups: [localGroup(g1), localGroup(g2)],
          items: [
            localItem(i1, [g1]),
            localItem(i2, [g1, g2]),
          ],
        );
        source
          ..groups = [
            groupRow(g1, name: 'local group', deleted: true),
            groupRow(g2, name: 'local group'),
          ]
          ..items = [
            // The server deleted the entry only in g1; the other one lost g1
            // from its set (its own version carries the smaller set).
            itemRow(i1, const [], deleted: true),
            itemRow(i2, [g2], text: 'local entry'),
          ];
        final summary = (await receive()).valueOrNull!;
        expect(summary.importedGroups, 2);
        expect(summary.importedItems, 2);
        expect((await groupRecord(g1))!.isDeleted, isTrue);
        expect(await liveGroupNames(), ['local group']);
        final doomed = (await entry(i1))!;
        expect(doomed.isDeleted, isTrue);
        expect(doomed.groupIds, isEmpty);
        final kept = (await entry(i2))!;
        expect(kept.isDeleted, isFalse);
        expect(kept.groupIds, [g2]);
      },
    );

    test('tombstones are applied, and a local tombstone is never cleared by '
        'a live remote version', () async {
      await seedLocal(
        groups: [localGroup(g1), localGroup(g2)],
        items: [
          localItem(i1, [g1]),
          localItem(i2, [g2]),
        ],
      );
      // The device already deleted the entry i2 and the group g2 (the
      // tombstones are set locally and were sent: no pending operation).
      await db.customStatement(
        'UPDATE my_adhkar_items SET deleted_at = ?, updated_at = ? '
        "WHERE item_id = '$i2'",
        [at.toIso8601String(), at.toIso8601String()],
      );
      await db.customStatement(
        'UPDATE my_adhkar_groups SET deleted_at = ?, updated_at = ? '
        "WHERE group_id = '$g2'",
        [at.toIso8601String(), at.toIso8601String()],
      );
      source
        ..groups = [
          groupRow(g1, name: 'local group', deleted: true),
          groupRow(
            g2,
            name: 'resurrected',
            updated: at.add(const Duration(hours: 1)),
          ),
        ]
        ..items = [
          itemRow(i1, const [], deleted: true),
          itemRow(
            i2,
            [g2],
            text: 'resurrected',
            updated: at.add(const Duration(hours: 1)),
          ),
        ];
      await receive();
      expect(
        (await groupRecord(g1))!.isDeleted,
        isTrue,
        reason: 'a remote tombstone is applied',
      );
      expect((await entry(i1))!.isDeleted, isTrue);
      expect(
        (await groupRecord(g2))!.isDeleted,
        isTrue,
        reason: 'a local tombstone is never cleared',
      );
      expect((await groupRecord(g2))!.name, 'local group');
      expect((await entry(i2))!.isDeleted, isTrue);
      expect((await entry(i2))!.text, 'local entry');
    });

    test('rows with pending local work are kept untouched', () async {
      await seedLocal(
        groups: [localGroup(g1, name: 'local name', updatedAt: at)],
        queue: true,
      );
      await seedLocal(
        items: [
          localItem(i1, [g1], text: 'local edit', updatedAt: at),
        ],
        queue: true,
      );
      source
        ..groups = [
          groupRow(
            g1,
            name: 'remote name',
            updated: at.add(const Duration(hours: 1)),
          ),
          groupRow(g2),
        ]
        ..items = [
          itemRow(
            i1,
            [g1],
            text: 'remote edit',
            updated: at.add(const Duration(hours: 1)),
          ),
          itemRow(i2, [g2]),
        ];
      final summary = (await receive()).valueOrNull!;
      expect((await groupRecord(g1))!.name, 'local name');
      expect((await entry(i1))!.text, 'local edit');
      expect(summary.importedGroups, 1, reason: 'only the unrelated group');
      expect(summary.importedItems, 1, reason: 'only the unrelated entry');
      expect(
        (await DriftLocalStore(db).readPendingChanges('owner')).valueOrNull,
        hasLength(2),
        reason: 'the pending operations are still pending',
      );
    });

    test('an older remote version never overwrites a newer acknowledged '
        'one', () async {
      await seedLocal(
        groups: [
          localGroup(
            g1,
            name: 'acknowledged name',
            updatedAt: at,
            acknowledged: at,
          ),
        ],
      );
      source.groups = [
        groupRow(
          g1,
          name: 'older remote',
          updated: at.subtract(const Duration(minutes: 5)),
        ),
      ];
      final summary = (await receive()).valueOrNull!;
      expect(summary.importedGroups, 0);
      expect((await groupRecord(g1))!.name, 'acknowledged name');
    });

    test(
      'a remote set naming a group deleted on this device does not bring '
      'it back; an entry left with only deleted groups is left alone',
      () async {
        await seedLocal(
          groups: [localGroup(g1), localGroup(g2)],
          items: [
            localItem(i1, [g1, g2]),
            localItem(i2, [g1]),
          ],
        );
        await db.customStatement(
          'UPDATE my_adhkar_groups SET deleted_at = ?, updated_at = ? '
          "WHERE group_id = '$g1'",
          [at.toIso8601String(), at.toIso8601String()],
        );
        // The device deleted g1 (the delete is not delivered yet); the remote
        // entries still name it.
        source
          ..groups = [groupRow(g1), groupRow(g2)]
          ..items = [
            itemRow(i1, [g1, g2], text: 'remote text', updated: at),
            itemRow(i2, [g1], text: 'remote text 2', updated: at),
          ];
        await receive();
        expect(
          (await entry(i1))!.groupIds,
          [g2],
          reason: 'the locally deleted group is not linked again',
        );
        expect((await entry(i1))!.text, 'remote text');
        expect(
          (await entry(i2))!.text,
          'local entry',
          reason: 'an entry with only deleted groups waits for its own path',
        );
      },
    );

    test('a kept membership keeps its local added_at and a new one takes the '
        'server\'s', () async {
      await seedLocal(
        groups: [localGroup(g1), localGroup(g2)],
        items: [
          localItem(i1, [g1]),
        ],
      );
      final before = await db.rawScalar(
        "SELECT added_at FROM my_adhkar_item_groups WHERE group_id = '$g1'",
      );
      final serverAdded = at.add(const Duration(minutes: 7));
      source
        ..groups = [groupRow(g1), groupRow(g2)]
        ..items = [
          itemRow(
            i1,
            [g1, g2],
            text: 'remote text',
            updated: at,
            addedAt: {
              g1: at.subtract(const Duration(days: 1)),
              g2: serverAdded,
            },
          ),
        ];
      await receive();
      expect(
        await db.rawScalar(
          "SELECT added_at FROM my_adhkar_item_groups WHERE group_id = '$g1'",
        ),
        before,
      );
      expect(
        await db.rawScalar(
          "SELECT added_at FROM my_adhkar_item_groups WHERE group_id = '$g2'",
        ),
        serverAdded.toIso8601String(),
      );
    });

    test('an entry naming a group this device does not know yet is imported '
        'with that group', () async {
      source
        ..groups = [groupRow(g1)]
        ..items = [
          itemRow(i1, [g1, g5]),
        ];
      await receive();
      expect((await entry(i1))!.groupIds, [g1, g5]);
    });
  });

  suite('inbound group tombstone cascade', () {
    final deleteAt = at.add(const Duration(minutes: 30));

    test('the survivor case: an entry in the deleted group and in a live '
        'group ends only in the live one, with no outbox row and its '
        'acknowledged version untouched', () async {
      await seedLocal(
        groups: [
          localGroup(g1),
          localGroup(g2, acknowledged: created),
        ],
        items: [
          localItem(i1, [g1, g2], acknowledged: created),
        ],
      );
      // The server dropped (i1, g1) without bumping i1, so the snapshot has
      // no newer entry version: only the group's tombstone arrives.
      source
        ..groups = [
          groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
          groupRow(g2, name: 'local group', updated: created),
        ]
        ..items = [];
      final summary = (await receive()).valueOrNull!;
      expect(summary.importedGroups, 1);
      final survivor = (await entry(i1))!;
      expect(survivor.isDeleted, isFalse);
      expect(survivor.groupIds, [g2]);
      expect(survivor.updatedAt, created);
      expect(survivor.lastAcknowledgedUpdatedAt, created);
      expect(
        (await DriftLocalStore(db).readPendingChanges('owner')).valueOrNull,
        isEmpty,
      );
      expect(await xpRows(), 0);
    });

    test(
      'an entry only in the deleted group is deleted locally before its '
      'own server version arrives, and that version then converges',
      () async {
        await seedLocal(
          groups: [localGroup(g1)],
          items: [
            localItem(i1, [g1], acknowledged: created),
          ],
        );
        source
          ..groups = [
            groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
          ]
          ..items = [];
        await receive();
        final doomed = (await entry(i1))!;
        expect(doomed.isDeleted, isTrue);
        expect(doomed.groupIds, isEmpty);
        expect(
          doomed.updatedAt.isAfter(created),
          isTrue,
          reason: 'the tombstone moves the version forward',
        );
        expect(doomed.lastAcknowledgedUpdatedAt, created);
        expect(
          (await DriftLocalStore(db).readPendingChanges('owner')).valueOrNull,
          isEmpty,
          reason: 'the server applies the same cascade; nothing is queued',
        );
        final serverVersion = deleteAt.add(const Duration(microseconds: 1));
        source.items = [
          itemRow(i1, const [], deleted: true, updated: serverVersion),
        ];
        final summary = (await receive()).valueOrNull!;
        expect(summary.importedItems, 1);
        final converged = (await entry(i1))!;
        expect(converged.isDeleted, isTrue);
        expect(converged.lastAcknowledgedUpdatedAt, serverVersion);
      },
    );

    test('a group not known on this device counts as live, so an entry that '
        'also names it is not deleted', () async {
      await seedLocal(
        groups: [localGroup(g1)],
        items: [
          localItem(i1, [g1, g2], acknowledged: created),
        ],
      );
      source
        ..groups = [
          groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
        ]
        ..items = [];
      await receive();
      final kept = (await entry(i1))!;
      expect(kept.isDeleted, isFalse);
      expect(kept.groupIds, [g2]);
    });

    test(
      'a tombstone for a group already deleted here changes nothing',
      () async {
        await seedLocal(
          groups: [localGroup(g1, deletedAt: created)],
          items: [
            localItem(i1, [g1], acknowledged: created),
          ],
        );
        source.groups = [
          groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
        ];
        expect((await receive()).failureOrNull, isNull);
        expect(
          (await entry(i1))!.isDeleted,
          isFalse,
          reason: 'only a newly applied tombstone cascades',
        );
      },
    );

    test('a pending local edit of an entry the cascade deleted still '
        'dispatches safely: its receipt never resurrects the entry', () async {
      await seedLocal(groups: [localGroup(g1)]);
      final pendingAt = at.subtract(const Duration(minutes: 10));
      await seedLocal(
        items: [
          localItem(i1, [g1], text: 'local edit', updatedAt: pendingAt),
        ],
        queue: true,
      );
      source
        ..groups = [
          groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
        ]
        ..items = [];
      await receive();
      final tombstoned = (await entry(i1))!;
      expect(tombstoned.isDeleted, isTrue);
      expect(tombstoned.groupIds, isEmpty);
      expect(tombstoned.updatedAt.isAfter(pendingAt), isTrue);
      expect(
        (await DriftLocalStore(db).readPendingChanges('owner')).valueOrNull,
        hasLength(1),
        reason: 'the pending operation is still pending',
      );

      // The server answers the pending edit with group_deleted (a deletion)
      // or, in the worst case, with a live version: neither resurrects it.
      for (final live in [false, true]) {
        final serverVersion = deleteAt.add(
          Duration(microseconds: live ? 2 : 1),
        );
        final receipt = MyAdhkarDispatchReceipt(
          operationId: 'seed-i-$i1',
          entityType: 'item',
          group: null,
          item: MyAdhkarRemoteItem(
            accountId: 'owner',
            itemId: i1,
            text: 'local edit',
            source: null,
            groupIds: live ? [g2] : const [],
            createdAt: created,
            updatedAt: serverVersion,
            deletedAt: live ? null : serverVersion,
          ),
          conflict: null,
          groupDeleted: !live,
        );
        final finalized = await repository.finalizeItemReceipt(
          accountId: 'owner',
          itemId: i1,
          outboundVersion: pendingAt,
          receipt: receipt,
        );
        expect(finalized.failureOrNull, isNull);
        final after = (await entry(i1))!;
        expect(after.isDeleted, isTrue, reason: 'no resurrection (live=$live)');
        expect(after.groupIds, isEmpty);
        expect(after.lastAcknowledgedUpdatedAt, serverVersion);
      }
    });

    test('a pending edit of an entry that keeps a live group stays live '
        'with the smaller set', () async {
      await seedLocal(groups: [localGroup(g1), localGroup(g2)]);
      await seedLocal(
        items: [
          localItem(i1, [g1, g2], text: 'local edit', updatedAt: at),
        ],
        queue: true,
      );
      source
        ..groups = [
          groupRow(g1, name: 'local group', deleted: true, updated: deleteAt),
          groupRow(g2, name: 'local group', updated: created),
        ]
        ..items = [];
      await receive();
      final kept = (await entry(i1))!;
      expect(kept.isDeleted, isFalse);
      expect(kept.groupIds, [g2]);
      expect(kept.text, 'local edit');
    });
  });

  suite('isolation inside the Adhkar sync service', () {
    test('a failing My Adhkar import fails only this pass; the Adhkar import '
        'still ran', () async {
      final log = <String>[];
      final service = AdhkarSyncService(
        session: const _Session(),
        connectivity: const _Online(),
        outbound: _Outbound(log),
        inbound: _AdhkarInbound(log),
        myAdhkarInbound: _MyInbound(log, fail: true),
      );
      addTearDown(service.dispose);
      final result = await service.synchronize();
      expect(result.failureOrNull?.category, AppFailureCategory.cloud);
      expect(log, ['outbound', 'adhkar', 'my']);
    });

    test(
      'a failing Adhkar import does not stop the My Adhkar import',
      () async {
        final log = <String>[];
        final service = AdhkarSyncService(
          session: const _Session(),
          connectivity: const _Online(),
          outbound: _Outbound(log),
          inbound: _AdhkarInbound(log, fail: true),
          myAdhkarInbound: _MyInbound(log),
        );
        addTearDown(service.dispose);
        final result = await service.synchronize();
        expect(result.failureOrNull?.category, AppFailureCategory.cloud);
        expect(log, ['outbound', 'adhkar', 'my']);
      },
    );

    test('both imports succeeding is a successful pass', () async {
      final log = <String>[];
      final service = AdhkarSyncService(
        session: const _Session(),
        connectivity: const _Online(),
        outbound: _Outbound(log),
        inbound: _AdhkarInbound(log),
        myAdhkarInbound: _MyInbound(log),
      );
      addTearDown(service.dispose);
      expect((await service.synchronize()).failureOrNull, isNull);
      expect(log, ['outbound', 'adhkar', 'my']);
    });
  });
}

/// `group` is a local name in other suites of this package; this keeps
/// flutter_test's.
void suite(String description, void Function() body) =>
    group(description, body);

String cid(int n) => 'cccccccc-0000-4000-8000-${n.toString().padLeft(12, '0')}';

String _iso(DateTime value) => value.toUtc().toIso8601String();

Map<String, dynamic> groupRow(
  String id, {
  String? name,
  DateTime? updated,
  bool deleted = false,
  String owner = 'owner',
}) {
  final at = updated ?? DateTime.utc(2026, 11, 16, 9);
  return {
    'owner': owner,
    'group_id': id,
    'name': name ?? 'remote group ${id.substring(id.length - 1)}',
    'created_at': _iso(DateTime.utc(2026, 11, 16, 8)),
    'updated_at': _iso(at),
    'deleted_at': deleted ? _iso(at) : null,
  };
}

Map<String, dynamic> itemRow(
  String id,
  List<String> groups, {
  String text = 'remote entry',
  String? source,
  DateTime? updated,
  bool deleted = false,
  Map<String, DateTime> addedAt = const {},
  String owner = 'owner',
}) {
  final at = updated ?? DateTime.utc(2026, 11, 16, 9);
  return {
    'owner': owner,
    'item_id': id,
    'text': text,
    'source': source,
    'created_at': _iso(DateTime.utc(2026, 11, 16, 8)),
    'updated_at': _iso(at),
    'deleted_at': deleted ? _iso(at) : null,
    'my_adhkar_item_groups': [
      for (final group in groups)
        {
          'group_id': group,
          'added_at': _iso(addedAt[group] ?? DateTime.utc(2026, 11, 16, 8)),
        },
    ],
  };
}

Map<String, dynamic> conflictRow(String id, {String? entityId}) => {
  'owner': 'owner',
  'conflict_id': id,
  'entity_type': 'item',
  'entity_id': entityId ?? 'bbbbbbbb-0000-4000-8000-000000000001',
  'active_record': {
    'text': 'active',
    'updated_at': _iso(DateTime.utc(2026, 11, 16, 9)),
  },
  'retained_record': {
    'text': 'retained',
    'updated_at': _iso(DateTime.utc(2026, 11, 16, 8, 50)),
  },
  'detected_at': _iso(DateTime.utc(2026, 11, 16, 9, 1)),
};

/// Serves scripted rows page by page with real keyset semantics (strictly
/// after the cursor, ordered by key, at most `limit`), and records every
/// cursor it was asked for.
final class FakePageSource implements MyAdhkarPageSource {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> conflicts = [];
  final Map<String, List<String?>> cursors = {
    'groups': [],
    'items': [],
    'conflicts': [],
  };
  int? failGroupPageOnCall;
  int? failItemPageOnCall;
  bool ignoreCursor = false;
  bool ignoreLimit = false;
  bool switchAccountAfterFirstPage = false;
  String? account = 'owner';
  var _groupCalls = 0;
  var _itemCalls = 0;

  @override
  String? get currentAccountId => account;

  List<Map<String, dynamic>> _page(
    List<Map<String, dynamic>> rows,
    String key,
    String table,
    int limit,
    String? after,
  ) {
    cursors[table]!.add(after);
    final sorted = [...rows]
      ..sort((a, b) => (a[key] as String).compareTo(b[key] as String));
    final filtered = [
      for (final row in sorted)
        if (ignoreCursor ||
            after == null ||
            (row[key] as String).compareTo(after) > 0)
          row,
    ];
    final page = ignoreLimit ? filtered : filtered.take(limit).toList();
    if (switchAccountAfterFirstPage) account = 'someone-else';
    return page;
  }

  @override
  Future<List<Map<String, dynamic>>> groupPage({
    required String accountId,
    required int limit,
    String? after,
  }) async {
    _groupCalls++;
    if (failGroupPageOnCall == _groupCalls) {
      throw StateError('group page $_groupCalls failed');
    }
    return _page(groups, 'group_id', 'groups', limit, after);
  }

  @override
  Future<List<Map<String, dynamic>>> itemPage({
    required String accountId,
    required int limit,
    String? after,
  }) async {
    _itemCalls++;
    if (failItemPageOnCall == _itemCalls) {
      throw StateError('item page $_itemCalls failed');
    }
    return _page(items, 'item_id', 'items', limit, after);
  }

  @override
  Future<List<Map<String, dynamic>>> conflictPage({
    required String accountId,
    required int limit,
    String? after,
  }) async => _page(conflicts, 'conflict_id', 'conflicts', limit, after);
}

final class _Session implements CloudSessionPort {
  const _Session();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(CloudSyncContext(accountId: 'owner'));
}

final class _Online implements ConnectivityPort {
  const _Online();

  @override
  ConnectivityStatus get current => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get changes => const Stream.empty();
}

final class _Outbound implements PendingSynchronizationEngine {
  _Outbound(this.log);

  final List<String> log;

  @override
  Future<AppResult<SyncSummary>> synchronize() async {
    log.add('outbound');
    return const AppResult.success(
      SyncSummary(
        acknowledged: 0,
        conflictsRecorded: 0,
        equalTimestampConflicts: 0,
        recoverableFailures: 0,
      ),
    );
  }
}

AppFailure _cloudFailure() => AppFailure.recoverable(
  category: AppFailureCategory.cloud,
  messageKey: 'adhkar.sync.failed',
  occurredAt: DateTime.now().toUtc(),
);

final class _AdhkarInbound implements AdhkarInboundSyncPort {
  _AdhkarInbound(this.log, {this.fail = false});

  final List<String> log;
  final bool fail;

  @override
  Future<AppResult<AdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    log.add('adhkar');
    if (fail) return AppResult.failure(_cloudFailure());
    return const AppResult.success(
      AdhkarInboundSummary(
        importedCounts: 0,
        importedConflicts: 0,
        importedAwards: 0,
      ),
    );
  }
}

final class _MyInbound implements MyAdhkarInboundSyncPort {
  _MyInbound(this.log, {this.fail = false});

  final List<String> log;
  final bool fail;

  @override
  Future<AppResult<MyAdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    log.add('my');
    if (fail) return AppResult.failure(_cloudFailure());
    return const AppResult.success(
      MyAdhkarInboundSummary(
        importedGroups: 0,
        importedItems: 0,
        importedConflicts: 0,
      ),
    );
  }
}
