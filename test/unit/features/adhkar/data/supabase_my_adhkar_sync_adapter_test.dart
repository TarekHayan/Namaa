import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_remote_models.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_gateway.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_sync_adapter.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/foundation_test_support.dart';

/// T092: the My Adhkar outbound dispatch for both entity types (contracts/
/// adhkar-qiyam-sync.md). The typed RPC arguments map from the outbox
/// payload (the group set rides inside the entry change; a delete sends an
/// empty set; no owner, XP or count ever travels); the response maps the
/// receipt's active and retained versions; local finalization happens in one
/// repository transaction before the ACK; `group_deleted` is applied as the
/// entry's deletion; `group_missing` and any other failure leave the
/// operation pending; an old response never overwrites newer local work; and
/// the engine keeps its chronological order across both entity types.
void main() {
  final created = DateTime.utc(2026, 11, 16, 8);
  final now = DateTime.utc(2026, 11, 16, 9);
  const groupId = 'aaaaaaaa-1111-4111-8111-111111111111';
  const otherGroupId = 'aaaaaaaa-2222-4222-8222-222222222222';
  const itemId = 'bbbbbbbb-2222-4222-8222-222222222222';

  late FoundationDatabase db;
  late DriftMyAdhkarRepository repository;
  late FakeMyAdhkarGateway gateway;
  late SupabaseMyAdhkarSyncAdapter adapter;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 200),
    );
    repository = DriftMyAdhkarRepository(db);
    gateway = FakeMyAdhkarGateway();
    adapter = SupabaseMyAdhkarSyncAdapter(
      gateway: gateway,
      repository: repository,
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  MyAdhkarGroup group({
    String id = groupId,
    String name = 'group text 1',
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? acknowledged,
  }) => MyAdhkarGroup(
    accountId: 'owner',
    groupId: id,
    name: name,
    createdAt: created,
    updatedAt: updatedAt ?? now,
    lastAcknowledgedUpdatedAt: acknowledged,
    deletedAt: deletedAt,
  );

  MyDhikrItem item({
    String text = 'entry text 1',
    String? source = 'source text 1',
    List<String> groupIds = const [groupId],
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => MyDhikrItem(
    accountId: 'owner',
    itemId: itemId,
    text: text,
    source: source,
    groupIds: groupIds,
    createdAt: created,
    updatedAt: updatedAt ?? now,
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  OutboundChange groupChange(
    MyAdhkarGroup g, {
    String operationId = 'op-group-1',
    DateTime? base,
  }) => OutboundChange(
    operationId: operationId,
    accountId: 'owner',
    entityType: kMyAdhkarGroupEntityType,
    entityId: g.groupId,
    kind: ChangeKind.create,
    payload: jsonEncode(MyAdhkarRemoteModels.groupPayload(g)),
    versionTimestamp: g.updatedAt,
    baseUpdatedAt: base,
  );

  OutboundChange itemChange(
    MyDhikrItem i, {
    String operationId = 'op-item-1',
    DateTime? base,
  }) => OutboundChange(
    operationId: operationId,
    accountId: 'owner',
    entityType: kMyAdhkarItemEntityType,
    entityId: i.itemId,
    kind: ChangeKind.update,
    payload: jsonEncode(MyAdhkarRemoteModels.itemPayload(i)),
    versionTimestamp: i.updatedAt,
    baseUpdatedAt: base,
  );

  Future<void> seedLocally({List<String> itemGroups = const [groupId]}) async {
    final result = await repository.runInTransaction(() async {
      for (final id in {groupId, otherGroupId}) {
        final inserted = await repository.insertGroup(
          group(id: id),
          operationId: 'local-group-$id',
          queueForSync: false,
        );
        if (inserted.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
      }
      return repository.insertItem(
        item(groupIds: itemGroups),
        operationId: 'local-item',
        queueForSync: false,
      );
    });
    expect(result.failureOrNull, isNull);
  }

  Future<int> xpRows() async =>
      (await db.rawScalar('SELECT count(*) FROM xp_awards')) as int;
  Future<int> conflictRows() async =>
      (await db.rawScalar('SELECT count(*) FROM conflict_records')) as int;
  Future<MyDhikrItem> storedItem() async => (await repository.readFresh(
    accountId: 'owner',
    itemId: itemId,
  )).valueOrNull!;
  Future<String> membershipAddedAt(String group) async =>
      (await db.rawScalar(
            'SELECT added_at FROM my_adhkar_item_groups '
            "WHERE item_id = '$itemId' AND group_id = '$group'",
          ))
          as String;

  suite('RPC arguments', () {
    test('a group maps to exactly the contract parameters', () {
      final params = MyAdhkarRpcParams.group(
        group: group(),
        operationId: 'op-1',
        baseUpdatedAt: created,
      );
      expect(params, {
        'p_group_id': groupId,
        'p_name': 'group text 1',
        'p_created_at': '2026-11-16T08:00:00.000Z',
        'p_deleted': false,
        'p_updated_at': '2026-11-16T09:00:00.000Z',
        'p_base_updated_at': '2026-11-16T08:00:00.000Z',
        'p_operation_id': 'op-1',
      });
    });

    test('a deleted group carries p_deleted and no base on a first send', () {
      final params = MyAdhkarRpcParams.group(
        group: group(deletedAt: now),
        operationId: 'op-2',
        baseUpdatedAt: null,
      );
      expect(params['p_deleted'], isTrue);
      expect(params['p_base_updated_at'], isNull);
    });

    test('an entry maps its text, source and sorted group set', () {
      final params = MyAdhkarRpcParams.item(
        item: item(groupIds: const [otherGroupId, groupId]),
        operationId: 'op-3',
        baseUpdatedAt: created,
      );
      expect(params, {
        'p_item_id': itemId,
        'p_text': 'entry text 1',
        'p_source': 'source text 1',
        'p_group_ids': [groupId, otherGroupId],
        'p_created_at': '2026-11-16T08:00:00.000Z',
        'p_deleted': false,
        'p_updated_at': '2026-11-16T09:00:00.000Z',
        'p_base_updated_at': '2026-11-16T08:00:00.000Z',
        'p_operation_id': 'op-3',
      });
    });

    test('an entry delete sends an empty group set and a null source', () {
      final params = MyAdhkarRpcParams.item(
        item: item(groupIds: const [], source: null, deletedAt: now),
        operationId: 'op-4',
        baseUpdatedAt: null,
      );
      expect(params['p_deleted'], isTrue);
      expect(params['p_group_ids'], isEmpty);
      expect(params['p_source'], isNull);
    });

    test('no owner, XP amount, count or day ever travels', () {
      final keys = {
        ...MyAdhkarRpcParams.group(
          group: group(),
          operationId: 'op',
          baseUpdatedAt: null,
        ).keys,
        ...MyAdhkarRpcParams.item(
          item: item(),
          operationId: 'op',
          baseUpdatedAt: null,
        ).keys,
      };
      for (final forbidden in [
        'p_owner',
        'p_amount',
        'p_xp',
        'p_count',
        'p_target',
        'p_day',
        'p_adhkar_day',
      ]) {
        expect(keys, isNot(contains(forbidden)));
      }
    });
  });

  suite('receipt parsing', () {
    Map<String, dynamic> serverItemOutcome({bool groupDeleted = false}) => {
      'owner': 'owner',
      'operation_id': 'op-1',
      'record_id': itemId,
      'entity_type': 'item',
      'active_record': {
        'item_id': itemId,
        'text': 'entry text 1',
        'source': null,
        'created_at': '2026-11-16T08:00:00+00:00',
        'updated_at': '2026-11-16T09:00:00+00:00',
        'deleted_at': groupDeleted ? '2026-11-16T09:00:00+00:00' : null,
        'group_ids': groupDeleted ? <String>[] : [groupId],
      },
      'active_version': '2026-11-16T09:00:00+00:00',
      'conflict_id': groupDeleted
          ? 'cccccccc-1111-4111-8111-111111111111'
          : null,
      'retained_record': groupDeleted
          ? {
              'item_id': itemId,
              'text': 'entry text 1',
              'source': null,
              'group_ids': [groupId],
              'created_at': '2026-11-16T08:00:00+00:00',
              'updated_at': '2026-11-16T09:00:00+00:00',
              'deleted_at': null,
            }
          : null,
      'detected_at': groupDeleted ? '2026-11-16T09:00:01+00:00' : null,
      'group_deleted': groupDeleted,
      'replayed': false,
    };

    test('a plain entry outcome maps the active record and its groups', () {
      final receipt = MyAdhkarRemoteModels.receipt(
        serverItemOutcome(),
        accountId: 'owner',
        operationId: 'op-1',
        recordId: itemId,
        entityType: 'item',
      );
      expect(receipt.item!.groupIds, [groupId]);
      expect(receipt.item!.isDeleted, isFalse);
      expect(receipt.conflict, isNull);
      expect(receipt.groupDeleted, isFalse);
      expect(receipt.activeVersion, now);
    });

    test('a group_deleted outcome maps the deletion and the kept conflict', () {
      final receipt = MyAdhkarRemoteModels.receipt(
        serverItemOutcome(groupDeleted: true),
        accountId: 'owner',
        operationId: 'op-1',
        recordId: itemId,
        entityType: 'item',
      );
      expect(receipt.groupDeleted, isTrue);
      expect(receipt.item!.isDeleted, isTrue);
      expect(receipt.item!.groupIds, isEmpty);
      expect(receipt.conflict!.id, 'cccccccc-1111-4111-8111-111111111111');
      expect(receipt.conflict!.entityId, itemId);
      expect(receipt.conflict!.retained['group_ids'], [groupId]);
    });

    test('a foreign owner or a mismatched identity is rejected', () {
      for (final broken in [
        serverItemOutcome()..['owner'] = 'someone-else',
        serverItemOutcome()..['operation_id'] = 'op-other',
        serverItemOutcome()..['record_id'] = 'other-record',
        serverItemOutcome()..['entity_type'] = 'group',
        serverItemOutcome()..['conflict_id'] = 'cccccccc',
      ]) {
        expect(
          () => MyAdhkarRemoteModels.receipt(
            broken,
            accountId: 'owner',
            operationId: 'op-1',
            recordId: itemId,
            entityType: 'item',
          ),
          throwsFormatException,
        );
      }
    });
  });

  suite('outbound dispatch', () {
    test('the group dispatch hands the gateway the outbox group, finalizes '
        'locally and acknowledges the server version', () async {
      await seedLocally();
      final outcome =
          (await adapter.dispatchChange(groupChange(group()))).valueOrNull
              as DispatchAcknowledged;
      expect(outcome.acknowledgementId, 'op-group-1');
      expect(outcome.remoteVersionTimestamp, now);
      expect(gateway.groupCalls.single.groupId, groupId);
      expect(gateway.groupCalls.single.name, 'group text 1');
      expect(gateway.groupCalls.single.isDeleted, isFalse);
      final stored = (await repository.readGroupFresh(
        accountId: 'owner',
        groupId: groupId,
      )).valueOrNull!;
      expect(stored.lastAcknowledgedUpdatedAt, now);
      expect(await xpRows(), 0);
    });

    test('the entry dispatch hands over the group set and keeps the local '
        'added_at order of a kept membership', () async {
      await seedLocally(itemGroups: const [groupId, otherGroupId]);
      final before = await membershipAddedAt(groupId);
      final outcome =
          (await adapter.dispatchChange(
                itemChange(item(groupIds: const [groupId, otherGroupId])),
              )).valueOrNull
              as DispatchAcknowledged;
      expect(outcome.acknowledgementId, 'op-item-1');
      expect(gateway.itemCalls.single.groupIds, [groupId, otherGroupId]);
      expect(gateway.itemCalls.single.source, 'source text 1');
      final stored = await storedItem();
      expect(stored.lastAcknowledgedUpdatedAt, now);
      expect(stored.groupIds, [groupId, otherGroupId]);
      expect(await membershipAddedAt(groupId), before);
      expect(await xpRows(), 0);
    });

    test('the server dropping a deleted group from the set is applied '
        'locally', () async {
      await seedLocally(itemGroups: const [groupId, otherGroupId]);
      gateway.itemAnswer = (submitted, operationId) => itemReceipt(
        operationId,
        item(groupIds: const [otherGroupId], updatedAt: submitted.updatedAt),
      );
      await adapter.dispatchChange(
        itemChange(item(groupIds: const [groupId, otherGroupId])),
      );
      expect((await storedItem()).groupIds, [otherGroupId]);
    });

    test('an entry delete is sent with p_deleted and no groups, and the '
        'server version is acknowledged', () async {
      await seedLocally();
      final tombstone = item(groupIds: const [], deletedAt: now);
      final outcome =
          (await adapter.dispatchChange(itemChange(tombstone))).valueOrNull
              as DispatchAcknowledged;
      expect(outcome.remoteVersionTimestamp, now);
      expect(gateway.itemCalls.single.isDeleted, isTrue);
      expect(gateway.itemCalls.single.groupIds, isEmpty);
    });

    test('the group_deleted outcome is applied as the entry deletion and '
        'its conflict evidence is kept read-only', () async {
      await seedLocally();
      final serverVersion = now.add(const Duration(microseconds: 1));
      gateway.itemAnswer = (submitted, operationId) {
        final deleted = item(
          groupIds: const [],
          updatedAt: serverVersion,
          deletedAt: serverVersion,
        );
        return MyAdhkarDispatchReceipt(
          operationId: operationId,
          entityType: 'item',
          group: null,
          item: MyAdhkarRemoteItem.fromJson(
            MyAdhkarRemoteModels.itemPayload(deleted),
            'owner',
          ),
          groupDeleted: true,
          conflict: MyAdhkarRemoteConflict(
            id: 'cccccccc-1111-4111-8111-111111111111',
            entityType: 'item',
            entityId: itemId,
            active: MyAdhkarRemoteModels.itemPayload(deleted),
            retained: MyAdhkarRemoteModels.itemPayload(submitted),
            detectedAt: serverVersion,
          ),
        );
      };
      final outcome =
          (await adapter.dispatchChange(
                itemChange(item(), operationId: 'op-gone'),
              )).valueOrNull
              as DispatchAcknowledged;
      expect(outcome.acknowledgementId, 'op-gone');
      expect(outcome.remoteVersionTimestamp, serverVersion);
      final stored = await storedItem();
      expect(stored.isDeleted, isTrue, reason: 'group_deleted deletes locally');
      expect(stored.groupIds, isEmpty);
      expect(stored.updatedAt, serverVersion);
      expect(stored.lastAcknowledgedUpdatedAt, serverVersion);
      final conflicts = await repository.watchConflicts('owner').first;
      expect(conflicts, hasLength(1));
      expect(conflicts.single.id, 'cccccccc-1111-4111-8111-111111111111');
      expect(conflicts.single.entityType, 'item');
      expect(conflicts.single.entityId, itemId);
      expect(conflicts.single.retained['deleted_at'], isNull);
      expect(await xpRows(), 0);
    });

    test('group_missing leaves the operation pending as a recoverable '
        'failure and writes nothing locally', () async {
      await seedLocally();
      gateway.itemFailure = PostgrestException(
        message: 'My Adhkar group missing',
        code: '22023',
        hint: 'group_missing',
      );
      final result = await adapter.dispatchChange(itemChange(item()));
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.recoverable, isTrue);
      expect((await storedItem()).lastAcknowledgedUpdatedAt, isNull);
      expect(await conflictRows(), 0);
    });

    test('any other failure leaves the operation pending with no local '
        'write', () async {
      await seedLocally();
      gateway.groupFailure = StateError('network down');
      final result = await adapter.dispatchChange(groupChange(group()));
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.recoverable, isTrue);
      expect(
        (await repository.readGroupFresh(
          accountId: 'owner',
          groupId: groupId,
        )).valueOrNull!.lastAcknowledgedUpdatedAt,
        isNull,
      );
    });

    test('a receipt that cannot be settled locally fails and keeps no '
        'conflict evidence', () async {
      // The entry has no local row: the receipt cannot be settled, so the
      // operation stays pending and nothing (not even the conflict) is kept.
      gateway.itemAnswer = (submitted, operationId) => MyAdhkarDispatchReceipt(
        operationId: operationId,
        entityType: 'item',
        group: null,
        item: MyAdhkarRemoteItem.fromJson(
          MyAdhkarRemoteModels.itemPayload(submitted),
          'owner',
        ),
        conflict: MyAdhkarRemoteConflict(
          id: 'cccccccc-2222-4222-8222-222222222222',
          entityType: 'item',
          entityId: itemId,
          active: MyAdhkarRemoteModels.itemPayload(submitted),
          retained: MyAdhkarRemoteModels.itemPayload(submitted),
          detectedAt: now,
        ),
      );
      final result = await adapter.dispatchChange(itemChange(item()));
      expect(result.failureOrNull, isNotNull);
      expect(await conflictRows(), 0);
    });

    test(
      'an owner change before finalization fails without a local write',
      () async {
        await seedLocally();
        gateway.itemAnswer = (submitted, operationId) {
          gateway.account = 'someone-else';
          return itemReceipt(operationId, submitted);
        };
        final result = await adapter.dispatchChange(itemChange(item()));
        expect(result.failureOrNull, isNotNull);
        expect((await storedItem()).lastAcknowledgedUpdatedAt, isNull);
      },
    );

    test('an old response never overwrites newer local work', () async {
      await seedLocally();
      // A newer local edit exists when the older dispatch is finalized.
      final newer = item(
        text: 'entry text 2',
        updatedAt: now.add(const Duration(minutes: 5)),
      );
      await repository.runInTransaction(
        () => repository.updateItem(
          newer,
          priorUpdatedAt: now,
          operationId: 'local-newer-edit',
          queueForSync: false,
        ),
      );
      final outcome =
          (await adapter.dispatchChange(
                itemChange(item(), operationId: 'op-item-old'),
              )).valueOrNull
              as DispatchAcknowledged;
      expect(outcome.acknowledgementId, 'op-item-old');
      final stored = await storedItem();
      expect(stored.text, 'entry text 2');
      expect(stored.updatedAt, now.add(const Duration(minutes: 5)));
      expect(
        stored.lastAcknowledgedUpdatedAt,
        now,
        reason: 'only the acknowledged base advances',
      );
      expect(await xpRows(), 0);
    });

    test(
      'an old group response never overwrites a newer local rename',
      () async {
        await seedLocally();
        final renamed = group(
          name: 'group text 2',
          updatedAt: now.add(const Duration(minutes: 5)),
        );
        await repository.runInTransaction(
          () => repository.renameGroup(
            renamed,
            priorUpdatedAt: now,
            operationId: 'local-newer-rename',
            queueForSync: false,
          ),
        );
        await adapter.dispatchChange(groupChange(group()));
        final stored = (await repository.readGroupFresh(
          accountId: 'owner',
          groupId: groupId,
        )).valueOrNull!;
        expect(stored.name, 'group text 2');
        expect(stored.lastAcknowledgedUpdatedAt, now);
      },
    );

    test('an unknown entity type or a mismatched version fails without '
        'contacting the gateway', () async {
      final badType = OutboundChange(
        operationId: 'op-bad',
        accountId: 'owner',
        entityType: 'my_adhkar_count',
        entityId: itemId,
        kind: ChangeKind.create,
        payload: '{}',
        versionTimestamp: now,
      );
      expect((await adapter.dispatchChange(badType)).failureOrNull, isNotNull);
      final mismatched = OutboundChange(
        operationId: 'op-mismatch',
        accountId: 'owner',
        entityType: kMyAdhkarItemEntityType,
        entityId: itemId,
        kind: ChangeKind.create,
        payload: jsonEncode(MyAdhkarRemoteModels.itemPayload(item())),
        versionTimestamp: now.add(const Duration(minutes: 1)),
      );
      expect(
        (await adapter.dispatchChange(mismatched)).failureOrNull,
        isNotNull,
      );
      expect(gateway.groupCalls, isEmpty);
      expect(gateway.itemCalls, isEmpty);
    });
  });

  suite('router and engine order', () {
    late EntityDispatchRouter router;

    setUp(() {
      const unused = _NoopCloudSync();
      router = EntityDispatchRouter(
        foundationAdapter: unused,
        taskAdapter: unused,
        habitAdapter: unused,
        habitDayAdapter: unused,
        mapAdapter: unused,
        myAdhkarAdapter: adapter,
      );
    });

    test('both entity types reach the My Adhkar adapter', () async {
      await seedLocally();
      expect(
        (await router.dispatchChange(groupChange(group()))).failureOrNull,
        isNull,
      );
      expect(
        (await router.dispatchChange(itemChange(item()))).failureOrNull,
        isNull,
      );
      expect(gateway.groupCalls, hasLength(1));
      expect(gateway.itemCalls, hasLength(1));
    });

    test('the engine dispatches groups and entries in the outbox\'s '
        'chronological order, with no reordering', () async {
      // Offline history: create a group, add an entry naming it, edit the
      // entry, then delete the group (the cascade queues the group only).
      final t0 = DateTime.utc(2026, 11, 16, 10);
      final result = await repository.runInTransaction(() async {
        final g = await repository.insertGroup(
          group(updatedAt: t0),
          operationId: 'q-group-create',
          queueForSync: true,
        );
        if (g.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
        final i = await repository.insertItem(
          item(updatedAt: t0.add(const Duration(minutes: 1))),
          operationId: 'q-item-create',
          queueForSync: true,
        );
        if (i.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
        final e = await repository.updateItem(
          item(
            text: 'entry text 2',
            updatedAt: t0.add(const Duration(minutes: 2)),
          ),
          priorUpdatedAt: t0.add(const Duration(minutes: 1)),
          operationId: 'q-item-edit',
          queueForSync: true,
        );
        if (e.failureOrNull case final failure?) {
          return AppResult<void>.failure(failure);
        }
        final d = await repository.deleteGroupCascade(
          accountId: 'owner',
          groupId: groupId,
          deletedAt: t0.add(const Duration(minutes: 3)),
          operationId: 'q-group-delete',
          queueForSync: true,
        );
        return d.failureOrNull == null
            ? const AppResult<void>.success(null)
            : AppResult<void>.failure(d.failureOrNull!);
      });
      expect(result.failureOrNull, isNull);

      final coordinator = SynchronizationCoordinator(
        localStore: DriftLocalStore(db),
        cloudSession: const _OwnerSession('owner'),
        cloudSync: router,
      );
      final summary = (await coordinator.synchronize()).valueOrNull!;
      expect(summary.recoverableFailures, 0);
      expect(summary.acknowledged, 4);
      expect(gateway.order, [
        'group:$groupId',
        'item:$itemId',
        'item:$itemId',
        'group:$groupId',
      ]);
      // The cascade queued no per-entry operation: one entry create, one
      // edit, and the group's create and delete are all there is.
      final rows = await db.select(db.pendingChanges).get();
      expect(rows, hasLength(4));
    });

    test('a group_missing failure leaves that entry pending and does not '
        'block the other operations', () async {
      final t0 = DateTime.utc(2026, 11, 16, 10);
      await repository.runInTransaction(() async {
        await repository.insertGroup(
          group(updatedAt: t0),
          operationId: 'q-group-create',
          queueForSync: true,
        );
        await repository.insertGroup(
          group(
            id: otherGroupId,
            updatedAt: t0.add(const Duration(seconds: 1)),
          ),
          operationId: 'q-group-2-create',
          queueForSync: true,
        );
        return repository.insertItem(
          item(updatedAt: t0.add(const Duration(minutes: 1))),
          operationId: 'q-item-create',
          queueForSync: true,
        );
      });
      gateway.itemFailure = PostgrestException(
        message: 'My Adhkar group missing',
        code: '22023',
        hint: 'group_missing',
      );
      final coordinator = SynchronizationCoordinator(
        localStore: DriftLocalStore(db),
        cloudSession: const _OwnerSession('owner'),
        cloudSync: router,
      );
      final summary = (await coordinator.synchronize()).valueOrNull!;
      expect(summary.recoverableFailures, 1);
      expect(summary.acknowledged, 2, reason: 'both group creates go through');
      final pending = await DriftLocalStore(db).readPendingChanges('owner');
      expect(pending.valueOrNull!.single.operationId, 'q-item-create');
      expect(pending.valueOrNull!.single.attemptCount, 1);
    });
  });
}

/// `group` is a local helper inside `main`; this keeps flutter_test's.
void suite(String description, void Function() body) =>
    group(description, body);

MyAdhkarDispatchReceipt itemReceipt(String operationId, MyDhikrItem active) =>
    MyAdhkarDispatchReceipt(
      operationId: operationId,
      entityType: 'item',
      group: null,
      item: MyAdhkarRemoteItem.fromJson(
        MyAdhkarRemoteModels.itemPayload(active),
        'owner',
      ),
      conflict: null,
    );

/// Records every hand-off and answers with an echo receipt unless scripted.
final class FakeMyAdhkarGateway implements SupabaseMyAdhkarGateway {
  final List<MyAdhkarGroup> groupCalls = [];
  final List<MyDhikrItem> itemCalls = [];
  final List<String> order = [];
  Object? groupFailure;
  Object? itemFailure;
  MyAdhkarDispatchReceipt Function(MyDhikrItem submitted, String operationId)?
  itemAnswer;
  String? account = 'owner';

  @override
  String? get currentAccountId => account;

  @override
  Future<MyAdhkarDispatchReceipt> applyGroupChange({
    required String expectedAccountId,
    required MyAdhkarGroup group,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    groupCalls.add(group);
    order.add('group:${group.groupId}');
    if (groupFailure case final failure?) throw failure;
    return MyAdhkarDispatchReceipt(
      operationId: operationId,
      entityType: 'group',
      group: MyAdhkarRemoteGroup.fromJson(
        MyAdhkarRemoteModels.groupPayload(group),
        'owner',
      ),
      item: null,
      conflict: null,
    );
  }

  @override
  Future<MyAdhkarDispatchReceipt> applyItemChange({
    required String expectedAccountId,
    required MyDhikrItem item,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    itemCalls.add(item);
    order.add('item:${item.itemId}');
    if (itemFailure case final failure?) throw failure;
    final answer = itemAnswer;
    return answer == null
        ? itemReceipt(operationId, item)
        : answer(item, operationId);
  }

  @override
  Future<MyAdhkarRemoteGroup?> fetchGroup({
    required String expectedAccountId,
    required String groupId,
  }) async => null;

  @override
  Future<MyAdhkarRemoteItem?> fetchItem({
    required String expectedAccountId,
    required String itemId,
  }) async => null;
}

final class _NoopCloudSync implements CloudSyncPort {
  const _NoopCloudSync();

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(OutboundChange change) =>
      throw StateError('the My Adhkar test must not reach another adapter');

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) => throw StateError('the My Adhkar test must not reach another adapter');
}

final class _OwnerSession implements CloudSessionPort {
  const _OwnerSession(this.accountId);

  final String accountId;

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.success(CloudSyncContext(accountId: accountId));
}
