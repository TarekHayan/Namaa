import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/presentation/map_detail_screen.dart';

import 'map_library_cubit.dart';
import 'map_library_state.dart';
import 'mind_maps_strings.dart';

const Key kMapLibraryCreateKey = Key('mind_map_create');
const Key kMapLibrarySearchKey = Key('mind_map_search');
const Key kMapLibraryEmptyKey = Key('mind_map_empty_library');
const Key kMapLibraryEmptySearchKey = Key('mind_map_empty_search');
const Key kMapLibraryConfirmDeleteKey = Key('mind_map_confirm_delete');
const Key kMapLibraryTitleFieldKey = Key('mind_map_title_field');
const Key kMapLibraryDescriptionFieldKey = Key('mind_map_description_field');

class MapLibraryScreen extends StatefulWidget {
  const MapLibraryScreen({
    super.key,
    required this.cubit,
    required this.ownerId,
    required this.stringsResolver,
  });

  final MapLibraryCubit cubit;
  final String ownerId;
  final MindMapsStringsResolver stringsResolver;

  @override
  State<MapLibraryScreen> createState() => _MapLibraryScreenState();
}

class _MapLibraryScreenState extends State<MapLibraryScreen> {
  @override
  void initState() {
    super.initState();
    widget.cubit.load(widget.ownerId);
  }

  @override
  void didUpdateWidget(MapLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) widget.cubit.load(widget.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
    return BlocBuilder<MapLibraryCubit, MapLibraryState>(
      bloc: widget.cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(strings.title)),
        floatingActionButton: FloatingActionButton.extended(
          key: kMapLibraryCreateKey,
          tooltip: strings.create,
          onPressed: () => _showEditor(context, strings, create: true),
          icon: const Icon(Icons.add),
          label: Text(strings.create),
        ),
        body: switch (state) {
          MapLibraryInitial() || MapLibraryLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MapLibraryFailure() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.loadFailure),
                TextButton(
                  onPressed: widget.cubit.retry,
                  child: Text(strings.retry),
                ),
              ],
            ),
          ),
          MapLibraryReady(:final ownerId) when ownerId != widget.ownerId =>
            const Center(child: CircularProgressIndicator()),
          MapLibraryReady(:final maps, :final hasMaps, :final lastFailure) =>
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        key: kMapLibrarySearchKey,
                        decoration: InputDecoration(
                          labelText: strings.search,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: widget.cubit.search,
                      ),
                    ),
                    if (lastFailure != null)
                      MaterialBanner(
                        content: Text(_failureText(strings, lastFailure)),
                        actions: [
                          TextButton(
                            onPressed: widget.cubit.clearFailure,
                            child: Text(strings.cancel),
                          ),
                        ],
                      ),
                    Expanded(
                      child: maps.isEmpty
                          ? Center(
                              child: Text(
                                hasMaps
                                    ? strings.emptySearch
                                    : strings.emptyLibrary,
                                key: hasMaps
                                    ? kMapLibraryEmptySearchKey
                                    : kMapLibraryEmptyKey,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                              itemCount: maps.length,
                              itemBuilder: (context, index) =>
                                  _mapCard(context, maps[index], strings),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }

  Widget _mapCard(
    BuildContext context,
    MapSummary summary,
    MindMapsStrings strings,
  ) {
    final map = summary.map;
    return Card(
      key: ValueKey('mind-map-${map.id}'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(map.title),
              subtitle: Text(
                [
                  if (map.description?.isNotEmpty ?? false) map.description!,
                  '${strings.nodeCount}: ${summary.nodeCount} • '
                      '${strings.completedCount}: ${summary.completedCount} '
                      '(${summary.progressPercent}%)',
                ].join('\n'),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MapDetailScreen(
                    repository: widget.cubit.repository,
                    session: widget.cubit.session,
                    tasks: widget.cubit.tasks,
                    ownerId: widget.ownerId,
                    mapId: map.id,
                    stringsResolver: widget.stringsResolver,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: ValueKey('mind-map-rename-${map.id}'),
                  onPressed: () => _showEditor(
                    context,
                    strings,
                    mapId: map.id,
                    title: map.title,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(strings.editTitle),
                ),
                TextButton.icon(
                  key: ValueKey('mind-map-description-${map.id}'),
                  onPressed: () => _showEditor(
                    context,
                    strings,
                    mapId: map.id,
                    description: map.description,
                    editDescription: true,
                  ),
                  icon: const Icon(Icons.notes_outlined),
                  label: Text(strings.editDescription),
                ),
                TextButton.icon(
                  key: ValueKey('mind-map-duplicate-${map.id}'),
                  onPressed: () => widget.cubit.duplicate(map.id),
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(strings.duplicate),
                ),
                TextButton.icon(
                  key: ValueKey('mind-map-delete-${map.id}'),
                  onPressed: () => _confirmDelete(context, map.id, strings),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    MindMapsStrings strings, {
    bool create = false,
    String? mapId,
    String? title,
    String? description,
    bool editDescription = false,
  }) async {
    var draft = editDescription ? description ?? '' : title ?? '';
    var descriptionDraft = description ?? '';
    String? error;
    final value = await showDialog<({String value, String? description})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            create
                ? strings.create
                : editDescription
                ? strings.editDescription
                : strings.editTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: kMapLibraryTitleFieldKey,
                initialValue: draft,
                onChanged: (value) => draft = value,
                autofocus: true,
                maxLines: editDescription ? 3 : 1,
                decoration: InputDecoration(
                  labelText: editDescription
                      ? strings.mapDescription
                      : strings.mapTitle,
                  errorText: error,
                ),
              ),
              if (create)
                TextFormField(
                  key: kMapLibraryDescriptionFieldKey,
                  onChanged: (value) => descriptionDraft = value,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: strings.mapDescription,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!editDescription && draft.trim().isEmpty) {
                  setDialogState(() => error = strings.titleRequired);
                  return;
                }
                Navigator.pop(dialogContext, (
                  value: draft,
                  description: create ? descriptionDraft : null,
                ));
              },
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) return;
    if (create) {
      await widget.cubit.create(value.value, value.description);
    } else if (editDescription) {
      await widget.cubit.describe(mapId!, value.value);
    } else {
      await widget.cubit.rename(mapId!, value.value);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String mapId,
    MindMapsStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: kMapLibraryConfirmDeleteKey,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.cubit.delete(mapId, confirmed: true);
    }
  }

  String _failureText(MindMapsStrings strings, AppFailure failure) =>
      switch (failure.messageKey) {
        'mind_maps.error.account' => strings.accountFailure,
        'mind_maps.error.not_found' => strings.notFound,
        _ => strings.saveFailure,
      };
}
