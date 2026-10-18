import 'package:flutter/material.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import 'mind_maps_strings.dart';

const Key kMindMapDetailKey = Key('mind_map_detail');
const Key kMindMapCentralNodeKey = Key('mind_map_central_node');

/// A read-only graph preview until the full editor arrives in Phase 4.
class MapDetailScreen extends StatelessWidget {
  const MapDetailScreen({
    super.key,
    required this.repository,
    required this.ownerId,
    required this.mapId,
    required this.stringsResolver,
  });

  final MapRepository repository;
  final String ownerId;
  final String mapId;
  final MindMapsStringsResolver stringsResolver;

  @override
  Widget build(BuildContext context) {
    final strings = stringsResolver(context);
    return StreamBuilder<MapGraph?>(
      stream: repository.watchGraph(ownerId: ownerId, mapId: mapId),
      builder: (context, snapshot) {
        final graph = snapshot.data;
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text(strings.loadFailure)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (graph == null) {
          return Scaffold(body: Center(child: Text(strings.notFound)));
        }
        final summary = MapQueries.summary(graph);
        MindMapNode? center;
        for (final node in graph.nodes) {
          if (node.id == graph.map.centralNodeId) {
            center = node;
            break;
          }
        }
        return Scaffold(
          key: kMindMapDetailKey,
          appBar: AppBar(title: Text(graph.map.title)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (graph.map.description?.isNotEmpty ?? false)
                    Text(graph.map.description!),
                  const SizedBox(height: 12),
                  Text(
                    '${strings.nodeCount}: ${summary.nodeCount} • '
                    '${strings.completedCount}: ${summary.completedCount} '
                    '(${summary.progressPercent}%)',
                  ),
                  const SizedBox(height: 20),
                  if (center != null)
                    Card(
                      key: kMindMapCentralNodeKey,
                      child: ListTile(
                        leading: const Icon(Icons.hub_outlined),
                        title: Text(center.title),
                        subtitle: Text(strings.centralNode),
                      ),
                    ),
                  for (final node in graph.nodes)
                    if (node.id != graph.map.centralNodeId)
                      Card(child: ListTile(title: Text(node.title))),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const BackButtonIcon(),
                    label: Text(strings.back),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
