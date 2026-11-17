import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../my_adhkar_cubit.dart';
import '../my_adhkar_state.dart';
import 'dhikr_item_card.dart' show kDhikrFontFamily;
import 'my_adhkar_forms.dart';
import 'my_adhkar_support.dart';

/// The My Adhkar tab (contracts/adhkar-qiyam-ui.md, Story 5): the user's own
/// collection as two levels inside the Adhkar page, the group list and an
/// opened group, with a "back to groups" control in the tab itself and no
/// app-bar back arrow. Device back closes an opened group first; with no
/// group open it is not handled here, so the shell returns Home.
///
/// Entries are two-field cards: selectable text in Amiri with the direction
/// of the text itself, an optional selectable plain-text source (a link is
/// never opened), and the entry's other groups. There is no counter, target,
/// time window or locked state, so the tab works when the Prayer schedule is
/// unavailable.
///
/// The tab reads the [MyAdhkarCubit] provided beside `AdhkarCubit` and
/// starts its loading itself.
final class MyAdhkarTab extends StatefulWidget {
  const MyAdhkarTab({super.key});

  @override
  State<MyAdhkarTab> createState() => _MyAdhkarTabState();
}

final class _MyAdhkarTabState extends State<MyAdhkarTab> {
  /// The group whose delete is awaiting an in-page confirmation, with the
  /// number of entries the delete would remove.
  String? _confirmGroupId;
  int _confirmGroupCount = 0;

  /// The entry whose delete is awaiting an in-page confirmation.
  String? _confirmItemId;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<MyAdhkarCubit>().load());
  }

  Future<bool> _handleBack() async {
    final cubit = context.read<MyAdhkarCubit>();
    if (cubit.state.openedGroupId == null) return false;
    _clearConfirmations();
    unawaited(cubit.closeGroup());
    return true;
  }

  void _clearConfirmations() {
    if (_confirmGroupId == null && _confirmItemId == null) return;
    setState(() {
      _confirmGroupId = null;
      _confirmItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final cubit = context.read<MyAdhkarCubit>();
    final content = BlocBuilder<MyAdhkarCubit, MyAdhkarState>(
      builder: (context, state) => Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMyAdhkarMaxContentWidth),
          child: Column(
            key: const Key('my_adhkar_tab'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(copy: copy),
              const SizedBox(height: 12),
              if (state.loadFailed)
                _MessageCard(
                  key: const Key('my_adhkar_load_failed'),
                  text: copy.myAdhkarLoadFailed,
                )
              else if (!state.loaded)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      key: Key('my_adhkar_loading'),
                    ),
                  ),
                )
              else if (state.openedGroupId != null)
                _OpenedGroup(
                  copy: copy,
                  cubit: cubit,
                  state: state,
                  confirmItemId: _confirmItemId,
                  onConfirmItem: (id) => setState(() => _confirmItemId = id),
                  onBack: _handleBack,
                )
              else
                _GroupList(
                  copy: copy,
                  cubit: cubit,
                  state: state,
                  confirmGroupId: _confirmGroupId,
                  confirmGroupCount: _confirmGroupCount,
                  onConfirmGroup: (id, count) => setState(() {
                    _confirmGroupId = id;
                    _confirmGroupCount = count;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
    // The device back button closes an opened group first. Outside a Router
    // (a bare MaterialApp) there is no dispatcher to listen to.
    if (Router.maybeOf(context) == null) return content;
    return BackButtonListener(onBackButtonPressed: _handleBack, child: content);
  }
}

/// The tab's heading: what the tab is, and the note that it is the user's
/// own content, not reviewed by the app (FR-026).
final class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.copy});

  final AdhkarStrings copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('my_adhkar_header'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.myAdhkarHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              copy.myAdhkarNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

/// The group list level: Create a group (disabled at the limit, with the
/// reason), the rows oldest first, and the empty state.
final class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.copy,
    required this.cubit,
    required this.state,
    required this.confirmGroupId,
    required this.confirmGroupCount,
    required this.onConfirmGroup,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final MyAdhkarState state;
  final String? confirmGroupId;
  final int confirmGroupCount;
  final void Function(String? groupId, int count) onConfirmGroup;

  void _openCreate(BuildContext context) =>
      showMyAdhkarForm(context, (_) => MyAdhkarGroupForm(cubit: cubit));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.groups.isEmpty) {
      return Card(
        key: const Key('my_adhkar_empty'),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.myAdhkarEmptyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                copy.myAdhkarEmptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('my_adhkar_create_group'),
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(copy.myAdhkarCreateGroup),
              ),
            ],
          ),
        ),
      );
    }
    final atLimit = state.groupLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          key: const Key('my_adhkar_create_group'),
          onPressed: atLimit ? null : () => _openCreate(context),
          icon: const Icon(Icons.add, size: 18),
          label: Text(copy.myAdhkarCreateGroup),
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              copy.myAdhkarCreateGroupDisabled,
              key: const Key('my_adhkar_group_limit_reason'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final summary in state.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: confirmGroupId == summary.group.groupId
                ? _GroupDeleteConfirmation(
                    copy: copy,
                    cubit: cubit,
                    group: summary.group,
                    count: confirmGroupCount,
                    busy: state.busy,
                    onDone: () => onConfirmGroup(null, 0),
                  )
                : _GroupRow(
                    copy: copy,
                    cubit: cubit,
                    summary: summary,
                    onDelete: (count) =>
                        onConfirmGroup(summary.group.groupId, count),
                  ),
          ),
      ],
    );
  }
}

enum _GroupAction { rename, delete }

/// One group row: the name (direction from the text itself), its entry
/// count, and the Rename / Delete overflow menu. Tapping the row opens it.
final class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.copy,
    required this.cubit,
    required this.summary,
    required this.onDelete,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final MyAdhkarGroupSummary summary;
  final ValueChanged<int> onDelete;

  Future<void> _selected(BuildContext context, _GroupAction action) async {
    switch (action) {
      case _GroupAction.rename:
        await showMyAdhkarForm(
          context,
          (_) => MyAdhkarGroupForm(cubit: cubit, existing: summary.group),
        );
      case _GroupAction.delete:
        final count = await cubit.previewDeleteGroup(
          groupId: summary.group.groupId,
        );
        if (!context.mounted) return;
        // The count is read before the confirmation; when it cannot be
        // read the delete is not offered rather than guessing a number.
        if (count != null) onDelete(count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = summary.group;
    return Card(
      key: Key('my_adhkar_group_${group.groupId}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(cubit.openGroup(group.groupId)),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 16,
            top: 4,
            bottom: 4,
            end: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        group.name,
                        textDirection: myAdhkarTextDirection(
                          group.name,
                          Directionality.of(context),
                        ),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      copy.groupEntries(summary.liveEntryCount),
                      key: Key('my_adhkar_group_count_${group.groupId}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_GroupAction>(
                key: Key('my_adhkar_group_menu_${group.groupId}'),
                onSelected: (action) => _selected(context, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _GroupAction.rename,
                    child: Text(copy.myAdhkarRename),
                  ),
                  PopupMenuItem(
                    value: _GroupAction.delete,
                    child: Text(copy.myAdhkarDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The in-page group delete confirmation, in the row's place: it states how
/// many entries the delete removes and that entries also in other groups
/// stay there (FR-029).
final class _GroupDeleteConfirmation extends StatelessWidget {
  const _GroupDeleteConfirmation({
    required this.copy,
    required this.cubit,
    required this.group,
    required this.count,
    required this.busy,
    required this.onDone,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final MyAdhkarGroup group;
  final int count;
  final bool busy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => _ConfirmationCard(
    key: Key('my_adhkar_group_delete_confirmation_${group.groupId}'),
    title: copy.myAdhkarGroupDeleteTitle,
    subtitle: group.name,
    body: copy.groupDeleteBody(count),
    cancelKey: const Key('my_adhkar_group_delete_cancel'),
    confirmKey: const Key('my_adhkar_group_delete_confirm'),
    cancelLabel: copy.myAdhkarCancel,
    confirmLabel: copy.myAdhkarDelete,
    busy: busy,
    onCancel: onDone,
    onConfirm: () async {
      final result = await cubit.deleteGroup(groupId: group.groupId);
      if (!result.ignored) onDone();
    },
  );
}

final class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.cancelKey,
    required this.confirmKey,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.busy,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String? subtitle;
  final String body;
  final Key cancelKey;
  final Key confirmKey;
  final String cancelLabel;
  final String confirmLabel;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
            if (subtitle != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  subtitle!,
                  textDirection: myAdhkarTextDirection(
                    subtitle!,
                    Directionality.of(context),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: [
                TextButton(
                  key: cancelKey,
                  onPressed: busy ? null : onCancel,
                  child: Text(cancelLabel),
                ),
                FilledButton(
                  key: confirmKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  onPressed: busy ? null : onConfirm,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The opened group level: the back control, the group name as the heading,
/// Add (disabled at the entry limit, with the reason), the empty state, and
/// the entry cards in the order they were added to the group.
final class _OpenedGroup extends StatelessWidget {
  const _OpenedGroup({
    required this.copy,
    required this.cubit,
    required this.state,
    required this.confirmItemId,
    required this.onConfirmItem,
    required this.onBack,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final MyAdhkarState state;
  final String? confirmItemId;
  final ValueChanged<String?> onConfirmItem;
  final Future<bool> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupId = state.openedGroupId!;
    final name = state.openedGroup?.group.name ?? '';
    final atLimit = state.entryLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('my_adhkar_back_to_groups'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(copy.myAdhkarBackToGroups),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            name,
            key: const Key('my_adhkar_group_title'),
            textDirection: myAdhkarTextDirection(
              name,
              Directionality.of(context),
            ),
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const Key('my_adhkar_add_entry'),
          onPressed: atLimit
              ? null
              : () => showMyAdhkarForm(
                  context,
                  (_) =>
                      MyAdhkarEntryForm(cubit: cubit, openedGroupId: groupId),
                ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(copy.myAdhkarAdd),
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              copy.myAdhkarAddDisabled,
              key: const Key('my_adhkar_add_limit_reason'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (state.openedGroupItems.isEmpty)
          _MessageCard(
            key: const Key('my_adhkar_group_empty'),
            text: copy.myAdhkarGroupEmpty,
          )
        else
          for (final item in state.openedGroupItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EntryCard(
                copy: copy,
                cubit: cubit,
                openedGroupId: groupId,
                item: item,
                groups: state.groups,
                busy: state.busy,
                confirming: confirmItemId == item.itemId,
                onConfirm: onConfirmItem,
              ),
            ),
      ],
    );
  }
}

enum _EntryAction { edit, copy, delete }

/// One entry card in the catalog's card style: the text in Amiri (selectable,
/// direction from the text), the source below it in the secondary style
/// (selectable, its own direction, never opened), a line naming the entry's
/// other groups, and the Edit / Copy / Delete menu. No number badge, counter,
/// target or reset.
final class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.copy,
    required this.cubit,
    required this.openedGroupId,
    required this.item,
    required this.groups,
    required this.busy,
    required this.confirming,
    required this.onConfirm,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final String openedGroupId;
  final MyDhikrItem item;
  final List<MyAdhkarGroupSummary> groups;
  final bool busy;
  final bool confirming;
  final ValueChanged<String?> onConfirm;

  Future<void> _selected(BuildContext context, _EntryAction action) async {
    switch (action) {
      case _EntryAction.edit:
        await showMyAdhkarForm(
          context,
          (_) => MyAdhkarEntryForm(
            cubit: cubit,
            openedGroupId: openedGroupId,
            existing: item,
          ),
        );
      case _EntryAction.copy:
        final messenger = ScaffoldMessenger.maybeOf(context);
        await Clipboard.setData(
          ClipboardData(
            text: item.source == null
                ? item.text
                : '${item.text}\n${item.source}',
          ),
        );
        messenger?.showSnackBar(SnackBar(content: Text(copy.myAdhkarCopied)));
      case _EntryAction.delete:
        onConfirm(item.itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ambient = Directionality.of(context);
    final liveOtherNames = [
      for (final summary in groups)
        if (summary.group.groupId != openedGroupId &&
            item.groupIds.contains(summary.group.groupId))
          summary.group.name,
    ];
    final source = item.source;
    return Card(
      key: Key('my_adhkar_entry_${item.itemId}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          item.text,
                          key: Key('my_adhkar_entry_text_${item.itemId}'),
                          textDirection: myAdhkarTextDirection(
                            item.text,
                            ambient,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: kDhikrFontFamily,
                            height: 1.9,
                          ),
                        ),
                        if (source != null) ...[
                          const SizedBox(height: 8),
                          SelectableText(
                            source,
                            key: Key('my_adhkar_entry_source_${item.itemId}'),
                            textDirection: myAdhkarTextDirection(
                              source,
                              ambient,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (liveOtherNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            copy.otherGroups(
                              liveOtherNames.join(copy.listSeparator),
                            ),
                            key: Key(
                              'my_adhkar_entry_other_groups_${item.itemId}',
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<_EntryAction>(
                  key: Key('my_adhkar_entry_menu_${item.itemId}'),
                  onSelected: (action) => _selected(context, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _EntryAction.edit,
                      child: Text(copy.myAdhkarEdit),
                    ),
                    PopupMenuItem(
                      value: _EntryAction.copy,
                      child: Text(copy.myAdhkarCopy),
                    ),
                    PopupMenuItem(
                      value: _EntryAction.delete,
                      child: Text(copy.myAdhkarDelete),
                    ),
                  ],
                ),
              ],
            ),
            if (confirming)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12, end: 10),
                child: _ConfirmationCard(
                  key: Key(
                    'my_adhkar_entry_delete_confirmation_${item.itemId}',
                  ),
                  title: copy.myAdhkarEntryDeleteTitle,
                  body: copy.myAdhkarEntryDeleteBody,
                  cancelKey: const Key('my_adhkar_entry_delete_cancel'),
                  confirmKey: const Key('my_adhkar_entry_delete_confirm'),
                  cancelLabel: copy.myAdhkarCancel,
                  confirmLabel: copy.myAdhkarDelete,
                  busy: busy,
                  onCancel: () => onConfirm(null),
                  onConfirm: () async {
                    final result = await cubit.deleteEntry(itemId: item.itemId);
                    if (!result.ignored) onConfirm(null);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
