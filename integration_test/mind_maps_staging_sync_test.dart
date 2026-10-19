import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/supabase_map_sync_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('isolated Supabase merges graph records and isolates accounts', (
    tester,
  ) async {
    const url = String.fromEnvironment('NAMAA_SUPABASE_URL');
    const key = String.fromEnvironment('NAMAA_SUPABASE_PUBLISHABLE_KEY');
    const emailA = String.fromEnvironment('NAMAA_STAGING_TEST_USER_A_EMAIL');
    const passwordA = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_A_PASSWORD',
    );
    const emailB = String.fromEnvironment('NAMAA_STAGING_TEST_USER_B_EMAIL');
    const passwordB = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_B_PASSWORD',
    );
    for (final value in [url, key, emailA, passwordA, emailB, passwordB]) {
      expect(
        value,
        isNotEmpty,
        reason: 'Isolated staging credentials required',
      );
    }
    final stagingUri = Uri.parse(url);
    final config = SupabaseEnvironmentConfig.isolatedNonProduction(
      url: stagingUri,
      publishableKey: key,
      approvedHosts: {stagingUri.host},
    );
    final clientA = createSupabaseClient(config);
    final clientA2 = createSupabaseClient(config);
    final clientB = createSupabaseClient(config);
    addTearDown(clientA.dispose);
    addTearDown(clientA2.dispose);
    addTearDown(clientB.dispose);
    final authA = await clientA.auth.signInWithPassword(
      email: emailA,
      password: passwordA,
    );
    final authA2 = await clientA2.auth.signInWithPassword(
      email: emailA,
      password: passwordA,
    );
    final authB = await clientB.auth.signInWithPassword(
      email: emailB,
      password: passwordB,
    );
    final owner = authA.user!.id;
    final other = authB.user!.id;
    expect(authA2.user!.id, owner);
    expect(other, isNot(owner));
    final gatewayA = SupabaseMapGatewayImpl(clientA);
    final gatewayA2 = SupabaseMapGatewayImpl(clientA2);
    final gatewayB = SupabaseMapGatewayImpl(clientB);
    const codec = MapPayloadCodec();
    final now = DateTime.now().toUtc();
    final mapId = _uuid();
    final centerId = _uuid();
    final map = MindMap(
      ownerId: owner,
      id: mapId,
      title: 'CI map $mapId',
      centralNodeId: centerId,
      revisionId: _uuid(),
      createdAt: now,
      updatedAt: now,
    );
    final center = MindMapNode(
      ownerId: owner,
      mapId: mapId,
      id: centerId,
      kind: MindMapNodeKind.central,
      title: map.title,
      x: 0,
      y: 0,
      revisionId: _uuid(),
      createdAt: now,
      updatedAt: now,
    );
    Future<Map<String, dynamic>> apply({
      required SupabaseMapGateway gateway,
      required String type,
      required String entityId,
      required String encoded,
      required DateTime at,
      required String operation,
      String kind = 'create',
    }) => gateway.applyChange(
      expectedOwnerId: owner,
      entityType: type,
      mapId: mapId,
      entityId: entityId,
      payload: Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      operationId: operation,
      kind: kind,
      updatedAt: at,
    );

    final createOperation = _uuid();
    final mapReceipt = await apply(
      gateway: gatewayA,
      type: kMindMapEntityType,
      entityId: mapId,
      encoded: codec.encodeMap(map),
      at: now,
      operation: createOperation,
    );
    expect(mapReceipt['owner'], owner);
    addTearDown(() async {
      final deletedAt = DateTime.now().toUtc().add(const Duration(minutes: 1));
      final deleted = MindMap(
        ownerId: owner,
        id: mapId,
        title: map.title,
        centralNodeId: centerId,
        revisionId: _uuid(),
        createdAt: now,
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      );
      await apply(
        gateway: gatewayA,
        type: kMindMapEntityType,
        entityId: mapId,
        encoded: codec.encodeMap(deleted),
        at: deletedAt,
        operation: _uuid(),
        kind: 'delete',
      );
    });
    final replay = await apply(
      gateway: gatewayA,
      type: kMindMapEntityType,
      entityId: mapId,
      encoded: codec.encodeMap(map),
      at: now,
      operation: createOperation,
    );
    expect(replay['replayed'], true);
    await apply(
      gateway: gatewayA,
      type: kMindMapNodeEntityType,
      entityId: '$mapId:$centerId',
      encoded: codec.encodeNode(center),
      at: now,
      operation: _uuid(),
    );

    final firstId = _uuid();
    final secondId = _uuid();
    MindMapNode node(String id, String title, DateTime updated) => MindMapNode(
      ownerId: owner,
      mapId: mapId,
      id: id,
      kind: MindMapNodeKind.branch,
      title: title,
      x: 0,
      y: 100,
      revisionId: _uuid(),
      createdAt: now,
      updatedAt: updated,
    );
    for (final id in [firstId, secondId]) {
      await apply(
        gateway: gatewayA,
        type: kMindMapNodeEntityType,
        entityId: '$mapId:$id',
        encoded: codec.encodeNode(node(id, 'Initial $id', now)),
        at: now,
        operation: _uuid(),
      );
    }
    final firstAt = now.add(const Duration(seconds: 1));
    final secondAt = now.add(const Duration(seconds: 2));
    await apply(
      gateway: gatewayA,
      type: kMindMapNodeEntityType,
      entityId: '$mapId:$firstId',
      encoded: codec.encodeNode(node(firstId, 'Device A', firstAt)),
      at: firstAt,
      operation: _uuid(),
      kind: 'update',
    );
    await apply(
      gateway: gatewayA2,
      type: kMindMapNodeEntityType,
      entityId: '$mapId:$secondId',
      encoded: codec.encodeNode(node(secondId, 'Device B', secondAt)),
      at: secondAt,
      operation: _uuid(),
      kind: 'update',
    );
    final parentAt = now.add(const Duration(seconds: 3));
    final slot = ParentSlot(
      ownerId: owner,
      mapId: mapId,
      childNodeId: firstId,
      parentNodeId: centerId,
      revisionId: _uuid(),
      updatedAt: parentAt,
    );
    await apply(
      gateway: gatewayA2,
      type: kMindMapParentSlotEntityType,
      entityId: '$mapId:parent:$firstId',
      encoded: codec.encodeParentSlot(slot),
      at: parentAt,
      operation: _uuid(),
    );
    final sideAt = now.add(const Duration(seconds: 4));
    final endpoints = [firstId, secondId]..sort();
    final side = SideLink(
      ownerId: owner,
      mapId: mapId,
      firstNodeId: endpoints.first,
      secondNodeId: endpoints.last,
      revisionId: _uuid(),
      updatedAt: sideAt,
    );
    await apply(
      gateway: gatewayA,
      type: kMindMapSideLinkEntityType,
      entityId: '$mapId:side:${endpoints.first}:${endpoints.last}',
      encoded: codec.encodeSideLink(side),
      at: sideAt,
      operation: _uuid(),
    );

    // Select only this test's random map. CI targets use the same staging
    // users concurrently and may be creating other maps at this instant.
    expect(
      await clientA2.from('mind_maps').select('id').eq('id', mapId),
      hasLength(1),
    );
    final ownerNodes = await clientA2
        .from('mind_map_nodes')
        .select('node_id,payload')
        .eq('map_id', mapId);
    String titleOf(String id) =>
        (ownerNodes.singleWhere((row) => row['node_id'] == id)['payload']
                as Map<String, dynamic>)['title']
            as String;
    expect(titleOf(firstId), 'Device A');
    expect(titleOf(secondId), 'Device B');
    expect(
      await clientA2
          .from('mind_map_parent_slots')
          .select('child_node_id')
          .eq('map_id', mapId),
      hasLength(1),
    );
    expect(
      await clientA2
          .from('mind_map_side_links')
          .select('first_node_id')
          .eq('map_id', mapId),
      hasLength(1),
    );

    final newerAt = now.add(const Duration(seconds: 5));
    final olderAt = now.add(const Duration(milliseconds: 4500));
    await apply(
      gateway: gatewayA2,
      type: kMindMapNodeEntityType,
      entityId: '$mapId:$firstId',
      encoded: codec.encodeNode(node(firstId, 'Newer same node', newerAt)),
      at: newerAt,
      operation: _uuid(),
      kind: 'update',
    );
    final loser = await apply(
      gateway: gatewayA,
      type: kMindMapNodeEntityType,
      entityId: '$mapId:$firstId',
      encoded: codec.encodeNode(node(firstId, 'Older same node', olderAt)),
      at: olderAt,
      operation: _uuid(),
      kind: 'update',
    );
    expect(loser['conflict_detected'], true);
    final ownerConflicts = await clientA2
        .from('mind_map_conflicts')
        .select('retained_payload')
        .eq('map_id', mapId);
    expect(
      ownerConflicts.any(
        (row) =>
            (row['retained_payload'] as Map<String, dynamic>)['title'] ==
            'Older same node',
      ),
      true,
    );

    expect(
      await clientB.from('mind_maps').select('id').eq('id', mapId),
      isEmpty,
    );
    expect(
      await clientB
          .from('mind_map_nodes')
          .select('node_id')
          .eq('map_id', mapId),
      isEmpty,
    );
    expect(
      await clientB
          .from('mind_map_parent_slots')
          .select('child_node_id')
          .eq('map_id', mapId),
      isEmpty,
    );
    expect(
      await clientB
          .from('mind_map_side_links')
          .select('first_node_id')
          .eq('map_id', mapId),
      isEmpty,
    );
    expect(
      await clientB
          .from('mind_map_conflicts')
          .select('conflict_id')
          .eq('map_id', mapId),
      isEmpty,
    );
    await expectLater(
      gatewayB.applyChange(
        expectedOwnerId: other,
        entityType: kMindMapNodeEntityType,
        mapId: mapId,
        entityId: '$mapId:$firstId',
        payload: Map<String, dynamic>.from(
          jsonDecode(codec.encodeNode(node(firstId, 'Foreign', secondAt)))
              as Map,
        ),
        operationId: _uuid(),
        kind: 'update',
        updatedAt: secondAt,
      ),
      throwsA(isA<Exception>()),
    );
  });
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
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
