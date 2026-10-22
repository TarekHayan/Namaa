import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/map_reconciler.dart';
import 'package:namma_project/features/mind_maps/data/supabase_map_sync_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../test/support/mind_maps_test_support.dart';

// Run concurrently on Windows (A) and Android (B) with one random RUN_ID.
// The remote control map coordinates the two independent encrypted stores.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('ten hosted two-device offline restart and reconnect trials', (
    tester,
  ) async {
    const url = String.fromEnvironment('NAMAA_SUPABASE_URL');
    const key = String.fromEnvironment('NAMAA_SUPABASE_PUBLISHABLE_KEY');
    const email = String.fromEnvironment('NAMAA_STAGING_TEST_USER_A_EMAIL');
    const password = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_A_PASSWORD',
    );
    const role = String.fromEnvironment('NAMAA_TWO_DEVICE_ROLE');
    const runId = String.fromEnvironment('NAMAA_TWO_DEVICE_RUN_ID');
    for (final value in [url, key, email, password, role, runId]) {
      expect(value, isNotEmpty, reason: 'Isolated two-device staging setup');
    }
    expect(role, anyOf('A', 'B'));
    expect(runId, matches(RegExp(r'^[0-9a-f-]{36}$')));

    final uri = Uri.parse(url);
    final client = createSupabaseClient(
      SupabaseEnvironmentConfig.isolatedNonProduction(
        url: uri,
        publishableKey: key,
        approvedHosts: {uri.host},
      ),
    );
    addTearDown(client.dispose);
    final auth = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    debugPrint('SC003 role=$role signed in');
    final owner = auth.user!.id;
    final gateway = SupabaseMapGatewayImpl(client);
    const codec = MapPayloadCodec();
    final controlId = '${runId[0] == 'a' ? 'b' : 'a'}${runId.substring(1)}';
    final directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'namaa_two_device_${runId}_$role',
    )..createSync(recursive: true);
    final databasePath =
        '${directory.path}${Platform.pathSeparator}foundation_encrypted.db';
    final encryptionKey = List<int>.generate(32, (i) => i + 17);
    var db = await FoundationDatabase.openEncrypted(
      path: databasePath,
      key: encryptionKey,
    );
    DriftMapRepository repo() => DriftMapRepository(database: db, codec: codec);
    final session = MindMapsTestSession(initialAccountId: owner);
    addTearDown(() async {
      await session.dispose();
      await db.close();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    Future<void> restart() async {
      await db.close();
      db = await FoundationDatabase.openEncrypted(
        path: databasePath,
        key: encryptionKey,
      );
    }

    Future<void> synchronize() async {
      final local = DriftLocalStore(db);
      final outbound = await SynchronizationCoordinator(
        localStore: local,
        cloudSession: session,
        cloudSync: SupabaseMapSyncAdapter(gateway: gateway),
      ).synchronize();
      expect(outbound.failureOrNull, isNull);
      expect(outbound.valueOrNull!.recoverableFailures, 0);
      expect(outbound.valueOrNull!.equalTimestampConflicts, 0);
      final mapRows = await client
          .from('mind_maps')
          .select('payload')
          .eq('id', runId);
      expect(mapRows, hasLength(1));
      final nodeRows = await client
          .from('mind_map_nodes')
          .select('payload')
          .eq('map_id', runId);
      final conflictRows = await client
          .from('mind_map_conflicts')
          .select()
          .eq('map_id', runId);
      final remote = MapRemoteSnapshot(
        maps: [
          for (final row in mapRows)
            codec.decodeMap(jsonEncode(row['payload'])),
        ],
        nodes: [
          for (final row in nodeRows)
            codec.decodeNode(jsonEncode(row['payload'])),
        ],
        parentSlots: const [],
        sideLinks: const [],
        conflicts: [
          for (final row in conflictRows)
            MapRemoteConflict(
              id: row['conflict_id'] as String,
              ownerId: owner,
              mapId: runId,
              entityType: row['entity_type'] as String,
              entityId: row['entity_id'] as String,
              activePayload: jsonEncode(row['active_payload']),
              activeAt: DateTime.parse(
                row['active_updated_at'] as String,
              ).toUtc(),
              retainedPayload: jsonEncode(row['retained_payload']),
              retainedAt: DateTime.parse(
                row['retained_updated_at'] as String,
              ).toUtc(),
            ),
        ],
      );
      final inbound = await MapReconciler(
        store: repo(),
        localStore: local,
      ).reconcile(ownerId: owner, remote: remote);
      expect(inbound.failureOrNull, isNull);
    }

    Future<String?> controlPhase() async {
      final rows = await client
          .from('mind_maps')
          .select('payload')
          .eq('id', controlId);
      if (rows.isEmpty) return null;
      return (rows.single['payload'] as Map<String, dynamic>)['title']
          as String;
    }

    Future<void> waitFor(String phase) async {
      final until = DateTime.now().add(const Duration(minutes: 10));
      while (DateTime.now().isBefore(until)) {
        try {
          if (await controlPhase() == phase) return;
        } on Exception {
          // A brief staging network interruption must not end a device trial.
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      fail('Timed out awaiting two-device phase $phase');
    }

    MindMap? control;
    Future<void> signal(String phase) async {
      final old =
          control ??
          codec.decodeMap(
            jsonEncode(
              (await client
                      .from('mind_maps')
                      .select('payload')
                      .eq('id', controlId))
                  .single['payload'],
            ),
          );
      final now = DateTime.now().toUtc();
      final updated = MindMap(
        ownerId: owner,
        id: old.id,
        title: phase,
        centralNodeId: old.centralNodeId,
        revisionId: _uuid(),
        createdAt: old.createdAt,
        updatedAt: now.isAfter(old.updatedAt)
            ? now
            : old.updatedAt.add(const Duration(microseconds: 1)),
      );
      final payload =
          jsonDecode(codec.encodeMap(updated)) as Map<String, dynamic>;
      final operationId = _uuid();
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await gateway.applyChange(
            expectedOwnerId: owner,
            entityType: 'mind_map',
            mapId: controlId,
            entityId: controlId,
            payload: payload,
            operationId: operationId,
            kind: 'update',
            updatedAt: updated.updatedAt,
          );
          control = updated;
          return;
        } on Exception {
          if (attempt == 2) rethrow;
          await Future<void>.delayed(Duration(seconds: attempt + 1));
        }
      }
    }

    if (role == 'A') {
      var generated = 0;
      String nextId() => ++generated == 2 ? runId : _uuid();
      final map = (await MapCommands(
        repository: repo(),
        session: session,
        nextId: nextId,
      ).createMap(title: 'Two-device acceptance')).valueOrNull!;
      expect(map.id, runId);
      final commands = MapGraphCommands(repository: repo(), session: session);
      for (final title in ['A', 'B', 'Shared']) {
        expect(
          (await commands.addNode(
            mapId: runId,
            kind: MindMapNodeKind.branch,
            title: title,
          )).failureOrNull,
          isNull,
        );
      }
      await synchronize();
      final now = DateTime.now().toUtc();
      control = MindMap(
        ownerId: owner,
        id: controlId,
        title: 'seeded',
        centralNodeId: _uuid(),
        revisionId: _uuid(),
        createdAt: now,
        updatedAt: now,
      );
      await gateway.applyChange(
        expectedOwnerId: owner,
        entityType: 'mind_map',
        mapId: controlId,
        entityId: controlId,
        payload: jsonDecode(codec.encodeMap(control!)) as Map<String, dynamic>,
        operationId: _uuid(),
        kind: 'create',
        updatedAt: now,
      );
      final center = MindMapNode(
        ownerId: owner,
        mapId: controlId,
        id: control!.centralNodeId,
        kind: MindMapNodeKind.central,
        title: 'Control',
        x: 0,
        y: 0,
        revisionId: _uuid(),
        createdAt: now,
        updatedAt: now,
      );
      await gateway.applyChange(
        expectedOwnerId: owner,
        entityType: 'mind_map_node',
        mapId: controlId,
        entityId: '$controlId:${center.id}',
        payload: jsonDecode(codec.encodeNode(center)) as Map<String, dynamic>,
        operationId: _uuid(),
        kind: 'create',
        updatedAt: now,
      );
      await waitFor('B-ready');
      debugPrint('SC003 role=A seeded graph and peer is ready');
    } else {
      await waitFor('seeded');
      await synchronize();
      await signal('B-ready');
      debugPrint('SC003 role=B imported seed graph');
    }

    // Both devices derive version timestamps from the same durable seed.
    // Their launch times may differ by several minutes during an Android build.
    final base = (await repo().readGraph(
      ownerId: owner,
      mapId: runId,
    )).valueOrNull!.map.createdAt.add(const Duration(days: 1));

    for (var trial = 0; trial < 10; trial++) {
      final graph = (await repo().readGraph(
        ownerId: owner,
        mapId: runId,
      )).valueOrNull!;
      final a = graph.nodes.singleWhere(
        (node) => node.title == (trial == 0 ? 'A' : 'A-${trial - 1}'),
      );
      final b = graph.nodes.singleWhere(
        (node) => node.title == (trial == 0 ? 'B' : 'B-${trial - 1}'),
      );
      final shared = graph.nodes.singleWhere(
        (node) =>
            node.title == (trial == 0 ? 'Shared' : 'Shared-A-${trial - 1}'),
      );
      if (role == 'A') {
        final commands = MapGraphCommands(
          repository: repo(),
          session: session,
          nowUtc: () => base.add(Duration(minutes: trial * 10 + 2)),
        );
        expect(
          (await commands.editNode(
            mapId: runId,
            nodeId: a.id,
            title: 'A-$trial',
          )).failureOrNull,
          isNull,
        );
        expect(
          (await commands.editNode(
            mapId: runId,
            nodeId: shared.id,
            title: 'Shared-A-$trial',
          )).failureOrNull,
          isNull,
        );
        await restart();
        expect(
          (await repo().readGraph(
            ownerId: owner,
            mapId: runId,
          )).valueOrNull!.nodes.singleWhere((node) => node.id == a.id).title,
          'A-$trial',
        );
        await signal('A-edited-$trial');
        await waitFor('B-sent-$trial');
        await synchronize();
        await _verify(repo(), owner, runId, a.id, b.id, shared.id, trial);
        await signal('A-sent-$trial');
        await waitFor('B-verified-$trial');
      } else {
        await waitFor('A-edited-$trial');
        final commands = MapGraphCommands(
          repository: repo(),
          session: session,
          nowUtc: () => base.add(Duration(minutes: trial * 10 + 1)),
        );
        expect(
          (await commands.editNode(
            mapId: runId,
            nodeId: b.id,
            title: 'B-$trial',
          )).failureOrNull,
          isNull,
        );
        expect(
          (await commands.editNode(
            mapId: runId,
            nodeId: shared.id,
            title: 'Shared-B-$trial',
          )).failureOrNull,
          isNull,
        );
        await restart();
        expect(
          (await repo().readGraph(
            ownerId: owner,
            mapId: runId,
          )).valueOrNull!.nodes.singleWhere((node) => node.id == b.id).title,
          'B-$trial',
        );
        await synchronize();
        await signal('B-sent-$trial');
        await waitFor('A-sent-$trial');
        await synchronize();
        await _verify(repo(), owner, runId, a.id, b.id, shared.id, trial);
        await signal('B-verified-$trial');
      }
      final remoteNodes = await client
          .from('mind_map_nodes')
          .select('node_id')
          .eq('map_id', runId);
      expect(
        remoteNodes,
        hasLength(4),
        reason: 'trial $trial has no duplicates',
      );
      debugPrint('SC003 role=$role trial=${trial + 1}/10 passed');
    }
  });
}

Future<void> _verify(
  DriftMapRepository repo,
  String owner,
  String mapId,
  String aId,
  String bId,
  String sharedId,
  int trial,
) async {
  final graph = (await repo.readGraph(
    ownerId: owner,
    mapId: mapId,
  )).valueOrNull!;
  expect(graph.nodes, hasLength(4));
  expect(graph.nodes.singleWhere((node) => node.id == aId).title, 'A-$trial');
  expect(graph.nodes.singleWhere((node) => node.id == bId).title, 'B-$trial');
  expect(
    graph.nodes.singleWhere((node) => node.id == sharedId).title,
    'Shared-A-$trial',
  );
  final conflicts = await repo.watchConflicts(owner, mapId).first;
  expect(
    conflicts.any((conflict) => conflict.retainedLabel == 'Shared-B-$trial'),
    isTrue,
    reason: 'trial $trial losing edit remains reviewable',
  );
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
