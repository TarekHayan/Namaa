import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_settings_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_sync_service.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_commands.dart';
import 'package:namma_project/features/mind_maps/presentation/map_detail_screen.dart';

import 'map_editor_cubit.dart';
import 'map_editor_screen.dart';
import 'map_library_cubit.dart';
import 'map_library_state.dart';
import 'mind_maps_strings.dart';

const Key kMapLibraryCreateKey = Key('mind_map_create');
const Key kMapLibrarySearchKey = Key('mind_map_search');
const Key kMapLibraryEmptyKey = Key('mind_map_empty_library');
const Key kMapLibraryEmptySearchKey = Key('mind_map_empty_search');
const Key kMapLibraryConfirmDeleteKey = Key('mind_map_confirm_delete');
const Key kMapLibraryTitleFieldKey = Key('mind_map_title_field');
const Key kMapLibrarySaveKey = Key('mind_map_save');
const Key kMapLibraryDescriptionFieldKey = Key('mind_map_description_field');
const Key kMapLibraryGridKey = Key('mind_map_library_grid');

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
  MapEditorCubit? _editor;
  Stream<CloudSessionSnapshot>? _editorSession;
  bool _editorRevoked = false;

  void _closeEditor() {
    final editor = _editor;
    setState(() {
      _editor = null;
      _editorSession = null;
      _editorRevoked = false;
    });
    if (editor != null && !editor.isClosed) unawaited(editor.close());
  }

  @override
  void initState() {
    super.initState();
    widget.cubit.load(widget.ownerId);
  }

  @override
  void didUpdateWidget(MapLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      final editor = _editor;
      _editor = null;
      _editorSession = null;
      _editorRevoked = false;
      if (editor != null && !editor.isClosed) unawaited(editor.close());
      widget.cubit.load(widget.ownerId);
    }
  }

  @override
  void dispose() {
    final editor = _editor;
    if (editor != null && !editor.isClosed) unawaited(editor.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
    final editor = _editor;
    if (editor != null) {
      return StreamBuilder<CloudSessionSnapshot>(
        stream: _editorSession,
        builder: (context, snapshot) {
          if (snapshot.data == null && !_editorRevoked) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data?.status != CloudSessionStatus.signedIn ||
              snapshot.data?.accountId != widget.ownerId) {
            _editorRevoked = true;
          }
          if (_editorRevoked) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.signInRequired),
                    TextButton(
                      onPressed: _closeEditor,
                      child: Text(strings.back),
                    ),
                  ],
                ),
              ),
            );
          }
          return MapEditorScreen(
            cubit: editor,
            stringsResolver: widget.stringsResolver,
            onBack: _closeEditor,
            ownsCubit: false,
          );
        },
      );
    }
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return BlocBuilder<MapLibraryCubit, MapLibraryState>(
      bloc: widget.cubit,
      builder: (context, state) => Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: false,
        body: switch (state) {
          MapLibraryInitial() ||
          MapLibraryLoading() => const AppStatusView.loading(),
          MapLibraryFailure() => AppStatusView.error(
            title: strings.loadFailure,
            actionLabel: strings.retry,
            onAction: widget.cubit.retry,
          ),
          MapLibraryReady(:final ownerId) when ownerId != widget.ownerId =>
            const Center(child: CircularProgressIndicator()),
          MapLibraryReady(
            :final maps,
            :final hasMaps,
            :final lastFailure,
            :final syncStatus,
          ) =>
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _libraryHeader(context, strings, colors),
                      if (syncStatus == MapSyncStatus.synchronizing)
                        LinearProgressIndicator(color: colors.primary),
                      if (syncStatus == MapSyncStatus.failed)
                        MaterialBanner(
                          content: Text(strings.syncFailed),
                          actions: [
                            TextButton(
                              onPressed: widget.cubit.retrySync,
                              child: Text(strings.syncRetry),
                            ),
                          ],
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
                      if (hasMaps) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: TextField(
                                  key: kMapLibrarySearchKey,
                                  decoration: InputDecoration(
                                    hintText: strings.search,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    filled: true,
                                    fillColor: colors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: colors.border,
                                      ),
                                    ),
                                  ),
                                  onChanged: widget.cubit.search,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${maps.length} ${strings.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Expanded(
                        child: maps.isEmpty
                            ? _emptyLibrary(context, strings, colors, hasMaps)
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 1000
                                      ? 3
                                      : constraints.maxWidth >= 640
                                      ? 2
                                      : 1;
                                  final textScale =
                                      MediaQuery.textScalerOf(
                                        context,
                                      ).scale(14) /
                                      14;
                                  return GridView.builder(
                                    key: kMapLibraryGridKey,
                                    padding: const EdgeInsets.only(bottom: 28),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          mainAxisExtent:
                                              (240 +
                                                      (textScale - 1).clamp(
                                                            0,
                                                            1,
                                                          ) *
                                                          110)
                                                  .toDouble(),
                                        ),
                                    itemCount: maps.length,
                                    itemBuilder: (context, index) => _mapCard(
                                      context,
                                      maps[index],
                                      strings,
                                      colors,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }

  Widget _libraryHeader(
    BuildContext context,
    MindMapsStrings strings,
    AppColors colors,
  ) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final heading = Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.hub_outlined, color: colors.primary, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Directionality.of(context) == TextDirection.rtl
                        ? 'نظّم أهدافك، مسارات تعلمك، ومشاريعك في شبكات مرئية ذكية'
                        : 'Structure your goals, roadmaps & tasks into visual node graphs',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
        final create = AppButton(
          key: kMapLibraryCreateKey,
          onPressed: () => _showEditor(context, strings, create: true),
          icon: Icons.add_rounded,
          label: strings.create,
        );
        return Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [heading, const SizedBox(height: 16), create],
                )
              : Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    create,
                  ],
                ),
        );
      },
    );
  }

  Widget _emptyLibrary(
    BuildContext context,
    MindMapsStrings strings,
    AppColors colors,
    bool hasMaps,
  ) => SingleChildScrollView(
    child: Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMaps ? Icons.search_off_rounded : Icons.hub_outlined,
              color: colors.primary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              hasMaps ? strings.emptySearch : strings.emptyLibrary,
              key: hasMaps ? kMapLibraryEmptySearchKey : kMapLibraryEmptyKey,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (!hasMaps) ...[
              const SizedBox(height: 8),
              Text(
                Directionality.of(context) == TextDirection.rtl
                    ? 'ابدأ بإنشاء خريطتك الذهنية الأولى لتنظيم مسارات التعلم، المشاريع، أو تقسيم المهام المعقدة.'
                    : 'Start your first mind map to structure roadmaps, projects, or decompose complex milestones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                onPressed: () => _showEditor(context, strings, create: true),
                icon: Icons.add_rounded,
                label: strings.create,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _mapCard(
    BuildContext context,
    MapSummary summary,
    MindMapsStrings strings,
    AppColors colors,
  ) {
    final map = summary.map;
    final theme = Theme.of(context);
    void open() => _openMap(context, map.id);
    return AppHoverSurface(
      radius: 24,
      clickable: true,
      child: Material(
        key: ValueKey('mind-map-${map.id}'),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.hub_outlined,
                        color: colors.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            map.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(map.updatedAt.toLocal()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      key: ValueKey('mind-map-menu-${map.id}'),
                      tooltip: strings.settings,
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) {
                        switch (value) {
                          case 'open':
                            open();
                          case 'rename':
                            _showEditor(
                              context,
                              strings,
                              mapId: map.id,
                              title: map.title,
                            );
                          case 'description':
                            _showEditor(
                              context,
                              strings,
                              mapId: map.id,
                              description: map.description,
                              editDescription: true,
                            );
                          case 'duplicate':
                            widget.cubit.duplicate(map.id);
                          case 'delete':
                            _confirmDelete(context, map.id, strings);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'open',
                          child: Text(strings.editMap),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          key: ValueKey('mind-map-rename-${map.id}'),
                          child: Text(strings.editTitle),
                        ),
                        PopupMenuItem(
                          value: 'description',
                          key: ValueKey('mind-map-description-${map.id}'),
                          child: Text(strings.editDescription),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          key: ValueKey('mind-map-duplicate-${map.id}'),
                          child: Text(strings.duplicate),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          key: ValueKey('mind-map-delete-${map.id}'),
                          child: Text(
                            strings.delete,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (map.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(
                    map.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                Divider(color: colors.border),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${strings.nodeCount}: ${summary.nodeCount}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${summary.progressPercent}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: summary.progressPercent / 100,
                    minHeight: 7,
                    backgroundColor: colors.surfaceSecondary,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${strings.completedCount}: ${summary.completedCount}/${summary.nodeCount}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      strings.editMap,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMap(BuildContext context, String mapId) {
    final session = widget.cubit.session;
    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MapDetailScreen(
            repository: widget.cubit.repository,
            ownerId: widget.ownerId,
            mapId: mapId,
            stringsResolver: widget.stringsResolver,
          ),
        ),
      );
      return;
    }
    final editor = MapEditorCubit(
      repository: widget.cubit.repository,
      commands: MapGraphCommands(
        repository: widget.cubit.repository,
        session: session,
      ),
      history: MapEditorHistory(
        repository: widget.cubit.repository,
        session: session,
        ownerId: widget.ownerId,
        mapId: mapId,
      ),
      settingsCommands: MapSettingsCommands(
        repository: widget.cubit.repository,
        session: session,
      ),
      tasks: widget.cubit.tasks,
      syncService: widget.cubit.syncService,
      conflictReader: widget.cubit.conflictReader,
      session: session,
      taskLinks: widget.cubit.tasks == null
          ? null
          : MapTaskLinkCommands(
              repository: widget.cubit.repository,
              tasks: widget.cubit.tasks!,
              session: session,
            ),
      ownerId: widget.ownerId,
      mapId: mapId,
    );
    setState(() {
      _editor = editor;
      _editorSession = session.observeSession();
      _editorRevoked = false;
    });
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
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    var draft = editDescription ? description ?? '' : title ?? '';
    var descriptionDraft = description ?? '';
    String? error;
    final value = await showDialog<({String value, String? description})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.hub_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  create
                      ? strings.create
                      : editDescription
                      ? strings.editDescription
                      : strings.editTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: strings.cancel,
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: kMapLibraryTitleFieldKey,
                    initialValue: draft,
                    onChanged: (value) => draft = value,
                    autofocus: true,
                    maxLines: editDescription ? 3 : 1,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _mapInputDecoration(
                      editDescription
                          ? strings.mapDescription
                          : strings.mapTitle,
                      colors,
                      error,
                    ),
                  ),
                  if (create) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      key: kMapLibraryDescriptionFieldKey,
                      onChanged: (value) => descriptionDraft = value,
                      maxLines: 3,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: _mapInputDecoration(
                        strings.mapDescription,
                        colors,
                        null,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            AppButton(
              key: kMapLibrarySaveKey,
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
              label: strings.save,
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

  InputDecoration _mapInputDecoration(
    String label,
    AppColors colors,
    String? error,
  ) => InputDecoration(
    labelText: label,
    errorText: error,
    filled: true,
    fillColor: colors.surfaceSecondary,
    labelStyle: TextStyle(color: colors.textSecondary),
    floatingLabelStyle: TextStyle(color: colors.primary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.primary),
    ),
  );

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
