import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/map_reconciler.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'ten two-device offline/reconnect trials preserve records and isolation',
    (tester) async {
      final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
      final files = [paths[0].allocate(), paths[1].allocate()];
      final key = List<int>.generate(32, (i) => 0xa0 + i);
      var dbA = await FoundationDatabase.openEncrypted(
        path: files[0],
        key: key,
      );
      final dbB = await FoundationDatabase.openEncrypted(
        path: files[1],
        key: key,
      );
      DriftMapRepository repo(FoundationDatabase db) =>
          DriftMapRepository(database: db, codec: const MapPayloadCodec());
      var storeA = repo(dbA);
      final storeB = repo(dbB);
      final cloud = _MapCloud();
      var nowA = DateTime.utc(2026, 10, 18, 9);
      var nowB = DateTime.utc(2026, 10, 18, 9, 1);
      final nextA = _ids(0x8111);
      final nextB = _ids(0x8222);
      final sessionA = MindMapsTestSession();
      final sessionB = MindMapsTestSession();
      MapCommands commands(
        DriftMapRepository store,
        MindMapsTestSession session,
        String Function() next,
        DateTime Function() clock,
      ) => MapCommands(
        repository: store,
        session: session,
        nextId: next,
        nowUtc: clock,
      );
      MapGraphCommands graphCommands(
        DriftMapRepository store,
        MindMapsTestSession session,
        String Function() next,
        DateTime Function() clock,
      ) => MapGraphCommands(
        repository: store,
        session: session,
        nextId: next,
        nowUtc: clock,
      );
      var actionsA = commands(storeA, sessionA, nextA, () => nowA);
      var graphA = graphCommands(storeA, sessionA, nextA, () => nowA);
      final graphB = graphCommands(storeB, sessionB, nextB, () => nowB);

      Future<void> send(FoundationDatabase db, String owner) async {
        final outbox = DriftLocalStore(db);
        final pending = (await outbox.readPendingChanges(owner)).valueOrNull!;
        for (final change in pending) {
          cloud.apply(change);
          cloud.apply(change); // duplicate delivery must be idempotent
          expect(
            (await outbox.acknowledgeChange(
              change.operationId,
              change.operationId,
            )).failureOrNull,
            isNull,
          );
        }
      }

      Future<void> receive(
        FoundationDatabase db,
        DriftMapRepository store,
        String owner,
      ) async {
        final result = await MapReconciler(
          store: store,
          localStore: DriftLocalStore(db),
        ).reconcile(ownerId: owner, remote: cloud.snapshot(owner));
        expect(result.failureOrNull, isNull);
      }

      addTearDown(() async {
        await sessionA.dispose();
        await sessionB.dispose();
        await dbA.close();
        await dbB.close();
        for (final path in paths) {
          path.dispose();
        }
      });

      final map = (await actionsA.createMap(
        title: 'Offline project',
      )).valueOrNull!;
      final first = (await graphA.addNode(
        mapId: map.id,
        kind: MindMapNodeKind.branch,
        title: 'First',
      )).valueOrNull!.nodes.single.after;
      final second = (await graphA.addNode(
        mapId: map.id,
        kind: MindMapNodeKind.branch,
        title: 'Second',
      )).valueOrNull!.nodes.single.after;
      await send(dbA, kMindMapsTestAccountA);
      await receive(dbB, storeB, kMindMapsTestAccountA);
      expect(
        (await storeB.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!.nodes,
        hasLength(3),
      );

      for (var trial = 0; trial < 10; trial++) {
        nowA = DateTime.utc(2026, 10, 18, 10 + trial * 3);
        nowB = DateTime.utc(2026, 10, 18, 11 + trial * 3);
        expect(
          (await graphA.editNode(
            mapId: map.id,
            nodeId: first.id,
            title: 'A-$trial',
          )).failureOrNull,
          isNull,
        );
        expect(
          (await graphB.editNode(
            mapId: map.id,
            nodeId: second.id,
            title: 'B-$trial',
          )).failureOrNull,
          isNull,
        );
        if (trial.isOdd) {
          expect(
            (await graphB.editNode(
              mapId: map.id,
              nodeId: first.id,
              title: 'B-first-$trial',
            )).failureOrNull,
            isNull,
          );
        }
        await dbA.close();
        dbA = await FoundationDatabase.openEncrypted(path: files[0], key: key);
        storeA = repo(dbA);
        actionsA = commands(storeA, sessionA, nextA, () => nowA);
        graphA = graphCommands(storeA, sessionA, nextA, () => nowA);
        await send(dbA, map.ownerId);
        await send(dbB, map.ownerId);
        await receive(dbA, storeA, map.ownerId);
        await receive(dbB, storeB, map.ownerId);
        final a = (await storeA.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!;
        final b = (await storeB.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!;
        final expectedFirst = trial.isOdd ? 'B-first-$trial' : 'A-$trial';
        expect(
          a.nodes.singleWhere((node) => node.id == first.id).title,
          expectedFirst,
        );
        expect(
          b.nodes.singleWhere((node) => node.id == first.id).title,
          expectedFirst,
        );
        expect(
          a.nodes.singleWhere((node) => node.id == second.id).title,
          'B-$trial',
        );
        expect(
          b.nodes.singleWhere((node) => node.id == second.id).title,
          'B-$trial',
        );
        expect(cloud.receiptCount, greaterThan(0));
      }

      // Competing relationship roles for one unordered pair select one edge.
      nowA = DateTime.utc(2026, 10, 20, 9);
      nowB = DateTime.utc(2026, 10, 20, 10);
      expect(
        (await graphA.setParent(
          mapId: map.id,
          childId: first.id,
          parentId: map.centralNodeId,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await graphB.setSideLink(
          mapId: map.id,
          firstId: first.id,
          secondId: map.centralNodeId,
          connected: true,
        )).failureOrNull,
        isNull,
      );
      await send(dbA, map.ownerId);
      await send(dbB, map.ownerId);
      await receive(dbA, storeA, map.ownerId);
      await receive(dbB, storeB, map.ownerId);
      final structural = (await storeA.readGraph(
        ownerId: map.ownerId,
        mapId: map.id,
      )).valueOrNull!;
      expect(structural.parentSlots, isEmpty);
      expect(structural.sideLinks, hasLength(1));

      // Newer node deletion beats an offline edit and hides incident edges.
      nowB = DateTime.utc(2026, 10, 20, 11);
      nowA = DateTime.utc(2026, 10, 20, 12);
      expect(
        (await graphB.editNode(
          mapId: map.id,
          nodeId: first.id,
          title: 'Offline late edit',
        )).failureOrNull,
        isNull,
      );
      expect(
        (await graphA.deleteNode(
          mapId: map.id,
          nodeId: first.id,
          confirmed: true,
        )).failureOrNull,
        isNull,
      );
      await send(dbB, map.ownerId);
      await send(dbA, map.ownerId);
      await receive(dbB, storeB, map.ownerId);
      expect(
        (await storeB.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!.nodes.any((n) => n.id == first.id),
        isFalse,
      );

      // A map tombstone hides a later child edit; the rejected version remains.
      nowA = DateTime.utc(2026, 10, 20, 13);
      nowB = DateTime.utc(2026, 10, 20, 14);
      expect(
        (await graphB.editNode(
          mapId: map.id,
          nodeId: second.id,
          title: 'After delete offline',
        )).failureOrNull,
        isNull,
      );
      expect(
        (await actionsA.deleteMap(
          mapId: map.id,
          confirmed: true,
        )).failureOrNull,
        isNull,
      );
      await send(dbA, map.ownerId);
      await send(dbB, map.ownerId);
      await receive(dbB, storeB, map.ownerId);
      expect(
        (await storeB.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull,
        isNull,
      );
      expect(cloud.snapshot(map.ownerId).conflicts, isNotEmpty);

      // Another account's map and conflict pages remain invisible to owner A.
      final foreignSession = MindMapsTestSession(
        initialAccountId: kMindMapsTestAccountB,
      );
      addTearDown(foreignSession.dispose);
      final foreign = (await commands(
        storeB,
        foreignSession,
        nextB,
        () => nowB,
      ).createMap(title: 'Private B')).valueOrNull!;
      await send(dbB, kMindMapsTestAccountB);
      expect(
        cloud
            .snapshot(kMindMapsTestAccountA)
            .maps
            .any((item) => item.id == foreign.id),
        isFalse,
      );
      expect(
        (await storeA.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: foreign.id,
        )).valueOrNull,
        isNull,
      );
    },
  );
}

String Function() _ids(int group) {
  var value = 0;
  return () {
    value++;
    return '00000000-0000-4000-${group.toRadixString(16)}-'
        '${value.toRadixString(16).padLeft(12, '0')}';
  };
}

final class _MapCloud {
  static const codec = MapPayloadCodec();
  final _maps = <String, MindMap>{};
  final _nodes = <String, MindMapNode>{};
  final _slots = <String, ParentSlot>{};
  final _links = <String, SideLink>{};
  final _conflicts = <String, MapRemoteConflict>{};
  final _receipts = <String, String>{};
  int get receiptCount => _receipts.length;

  void apply(PendingChangeRecord change) {
    final receipt = '${change.accountId}:${change.operationId}';
    final oldReceipt = _receipts[receipt];
    if (oldReceipt != null) {
      if (oldReceipt != change.serializedChange) {
        throw StateError('operation identity collision');
      }
      return;
    }
    _receipts[receipt] = change.serializedChange;
    final value = jsonDecode(change.serializedChange) as Map<String, dynamic>;
    if (value['ownerId'] != change.accountId) {
      throw StateError('foreign map mutation');
    }
    final mapId = change.entityType == kMindMapEntityType
        ? value['id'] as String
        : value['mapId'] as String;
    final mapKey = '${change.accountId}:$mapId';
    if (change.entityType != kMindMapEntityType &&
        _maps[mapKey]?.isDeleted == true) {
      final map = _maps[mapKey]!;
      _conflicts[receipt] = MapRemoteConflict(
        id: receipt,
        ownerId: change.accountId,
        mapId: mapId,
        entityType: change.entityType,
        entityId: change.entityId,
        activePayload: codec.encodeMap(map),
        activeAt: map.updatedAt,
        retainedPayload: change.serializedChange,
        retainedAt: change.versionTimestamp,
      );
      return;
    }
    switch (change.entityType) {
      case kMindMapEntityType:
        final map = codec.decodeMap(change.serializedChange);
        _upsert(_maps, mapKey, map, map.updatedAt, (e) => e.updatedAt);
      case kMindMapNodeEntityType:
        final node = codec.decodeNode(change.serializedChange);
        _upsert(
          _nodes,
          '${node.ownerId}:${node.mapId}:${node.id}',
          node,
          node.updatedAt,
          (e) => e.updatedAt,
        );
      case kMindMapParentSlotEntityType:
        final slot = codec.decodeParentSlot(change.serializedChange);
        final key = '${slot.ownerId}:${slot.mapId}:${slot.childNodeId}';
        _upsert(_slots, key, slot, slot.updatedAt, (e) => e.updatedAt);
        if (!slot.isDeleted) {
          final side = _links.values
              .where(
                (item) =>
                    item.ownerId == slot.ownerId &&
                    item.mapId == slot.mapId &&
                    !item.isDeleted &&
                    _samePair(
                      item.firstNodeId,
                      item.secondNodeId,
                      slot.childNodeId,
                      slot.parentNodeId,
                    ),
              )
              .firstOrNull;
          if (side != null && slot.updatedAt.isAfter(side.updatedAt)) {
            _links['${side.ownerId}:${side.mapId}:${side.id}'] = copySideLink(
              side,
              revisionId: side.revisionId,
              updatedAt: slot.updatedAt,
              deletedAt: slot.updatedAt,
            );
          }
        }
      case kMindMapSideLinkEntityType:
        final link = codec.decodeSideLink(change.serializedChange);
        final key = '${link.ownerId}:${link.mapId}:${link.id}';
        _upsert(_links, key, link, link.updatedAt, (e) => e.updatedAt);
        if (!link.isDeleted) {
          final slot = _slots.values
              .where(
                (item) =>
                    item.ownerId == link.ownerId &&
                    item.mapId == link.mapId &&
                    !item.isDeleted &&
                    _samePair(
                      item.childNodeId,
                      item.parentNodeId,
                      link.firstNodeId,
                      link.secondNodeId,
                    ),
              )
              .firstOrNull;
          if (slot != null && link.updatedAt.isAfter(slot.updatedAt)) {
            _slots['${slot.ownerId}:${slot.mapId}:${slot.childNodeId}'] =
                copyParentSlot(
                  slot,
                  revisionId: slot.revisionId,
                  updatedAt: link.updatedAt,
                  deletedAt: link.updatedAt,
                );
          }
        }
    }
  }

  static void _upsert<T>(
    Map<String, T> rows,
    String key,
    T incoming,
    DateTime at,
    DateTime Function(T) version,
  ) {
    final old = rows[key];
    if (old == null || at.isAfter(version(old))) rows[key] = incoming;
  }

  static bool _samePair(String a, String b, String c, String d) =>
      (a == c && b == d) || (a == d && b == c);

  MapRemoteSnapshot snapshot(String owner) => MapRemoteSnapshot(
    maps: _maps.values.where((e) => e.ownerId == owner),
    nodes: _nodes.values.where((e) => e.ownerId == owner),
    parentSlots: _slots.values.where((e) => e.ownerId == owner),
    sideLinks: _links.values.where((e) => e.ownerId == owner),
    conflicts: _conflicts.values.where((e) => e.ownerId == owner),
  );
}
