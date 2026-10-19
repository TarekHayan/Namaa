import 'package:flutter/material.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_reconciliation.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/application/map_settings_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_sync_service.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_port.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import 'map_editor_cubit.dart';
import 'map_editor_screen.dart';
import 'mind_maps_strings.dart';

const Key kMindMapDetailKey = Key('mind_map_detail');
const Key kMindMapCentralNodeKey = Key('mind_map_central_node');

/// A quick graph summary with an entry to the full editor.
class MapDetailScreen extends StatelessWidget {
  const MapDetailScreen({
    super.key,
    required this.repository,
    required this.ownerId,
    required this.mapId,
    required this.stringsResolver,
    this.session,
    this.tasks,
    this.syncService,
    this.conflictReader,
  });

  final MapRepository repository;
  final String ownerId;
  final String mapId;
  final MindMapsStringsResolver stringsResolver;
  final CloudSessionPort? session;
  final MapTaskLinkPort? tasks;
  final MapSyncService? syncService;
  final MapConflictReaderPort? conflictReader;

  @override
  Widget build(BuildContext context) {
    final strings = stringsResolver(context);
    if (session == null) return _ownedContent(context, strings);
    return StreamBuilder<CloudSessionSnapshot>(
      stream: session!.observeSession(),
      builder: (context, snapshot) {
        final value = snapshot.data;
        if (value?.status != CloudSessionStatus.signedIn ||
            value?.accountId != ownerId) {
          return Scaffold(body: Center(child: Text(strings.signInRequired)));
        }
        return _ownedContent(context, strings);
      },
    );
  }

  Widget _ownedContent(BuildContext context, MindMapsStrings strings) {
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
        MindMapNode? center;
        for (final node in graph.nodes) {
          if (node.id == graph.map.centralNodeId) {
            center = node;
            break;
          }
        }
        return StreamBuilder<List<MapLinkedTask>>(
          stream:
              tasks?.watchAccessibleTasks(ownerId) ??
              Stream.value(const <MapLinkedTask>[]),
          builder: (context, taskSnapshot) {
            final linked = {
              for (final task in taskSnapshot.data ?? const <MapLinkedTask>[])
                task.id: task,
            };
            final summary = MapQueries.summary(graph, tasks: linked);
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
                      if (session != null)
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MapEditorScreen(
                                cubit: MapEditorCubit(
                                  repository: repository,
                                  commands: MapGraphCommands(
                                    repository: repository,
                                    session: session!,
                                  ),
                                  history: MapEditorHistory(
                                    repository: repository,
                                    session: session!,
                                    ownerId: ownerId,
                                    mapId: mapId,
                                  ),
                                  settingsCommands: MapSettingsCommands(
                                    repository: repository,
                                    session: session!,
                                  ),
                                  tasks: tasks,
                                  syncService: syncService,
                                  conflictReader: conflictReader,
                                  session: session,
                                  taskLinks: tasks == null
                                      ? null
                                      : MapTaskLinkCommands(
                                          repository: repository,
                                          tasks: tasks!,
                                          session: session!,
                                        ),
                                  ownerId: ownerId,
                                  mapId: mapId,
                                ),
                                stringsResolver: stringsResolver,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit_note),
                          label: Text(strings.editMap),
                        ),
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
      },
    );
  }
}
