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
import 'adhkar_controls.dart';
import 'adhkar_style.dart';
import 'my_adhkar_forms.dart';
import 'my_adhkar_support.dart';

/// The My Adhkar tab (contracts/adhkar-qiyam-ui.md, Story 5; approved design
/// 2026-11-17, page 2): the user's own collection as two levels inside the
/// Adhkar page, the group list and an opened group, with a "back to groups"
/// control in the tab itself and no app-bar back arrow.
///
/// Device back closes the topmost layer first: an open sheet or dialog (a
/// route of its own, left to the navigator), then an in-place delete
/// confirmation, then an open group; with none of these open it is not
/// handled here, so the shell returns Home. Leaving the tab closes an open
/// group (the Adhkar screen does that when the tab changes).
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
    // A sheet or dialog above the page is closed by the navigator first.
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final cubit = context.read<MyAdhkarCubit>();
    if (_confirmGroupId != null || _confirmItemId != null) {
      _clearConfirmations();
      return true;
    }
    if (cubit.state.openedGroupId == null) return false;
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
      builder: (context, state) {
        final Widget body;
        if (state.loadFailed) {
          body = _MessageBlock(
            key: const Key('my_adhkar_load_failed'),
            text: copy.myAdhkarLoadFailed,
          );
        } else if (!state.loaded) {
          body = const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(key: Key('my_adhkar_loading')),
            ),
          );
        } else if (state.openedGroupId != null) {
          body = _OpenedGroup(
            copy: copy,
            cubit: cubit,
            state: state,
            confirmItemId: _confirmItemId,
            onConfirmItem: (id) => setState(() => _confirmItemId = id),
            onBack: () {
              _clearConfirmations();
              unawaited(cubit.closeGroup());
            },
          );
        } else {
          body = _GroupList(
            copy: copy,
            cubit: cubit,
            state: state,
            confirmGroupId: _confirmGroupId,
            confirmGroupCount: _confirmGroupCount,
            onConfirmGroup: (id, count) => setState(() {
              _confirmGroupId = id;
              _confirmGroupCount = count;
            }),
          );
        }
        return Column(
          key: const Key('my_adhkar_tab'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.openedGroupId == null || !state.loaded) ...[
              _Heading(copy: copy),
              const SizedBox(height: 16),
            ],
            body,
          ],
        );
      },
    );
    // Outside a Router (a bare MaterialApp) there is no dispatcher to listen
    // to.
    if (Router.maybeOf(context) == null) return content;
    return BackButtonListener(onBackButtonPressed: _handleBack, child: content);
  }
}

/// The tab's heading: what the tab is, and the note that it is the user's
/// own content, not reviewed by the app (FR-026).
final class _Heading extends StatelessWidget {
  const _Heading({required this.copy});

  final AdhkarStrings copy;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Column(
      key: const Key('my_adhkar_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.myAdhkarHeading,
          style: adhkarText(20, FontWeight.w700, palette.text, height: 1.45),
        ),
        const SizedBox(height: 6),
        Text(
          copy.myAdhkarNote,
          style: adhkarText(14, FontWeight.w400, palette.text2, height: 1.7),
        ),
      ],
    );
  }
}

final class _MessageBlock extends StatelessWidget {
  const _MessageBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: palette.card(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: adhkarText(16, FontWeight.w400, palette.text2, height: 1.8),
      ),
    );
  }
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
    final palette = AdhkarPalette.of(context);
    if (state.groups.isEmpty) {
      return Padding(
        key: const Key('my_adhkar_empty'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.soft,
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 40,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              copy.myAdhkarEmptyTitle,
              textAlign: TextAlign.center,
              style: adhkarText(
                20,
                FontWeight.w800,
                palette.text,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              copy.myAdhkarEmptyBody,
              textAlign: TextAlign.center,
              style: adhkarText(
                16,
                FontWeight.w400,
                palette.text2,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AdhkarGlow(
                enabled: true,
                child: FilledButton.icon(
                  key: const Key('my_adhkar_create_group'),
                  style: adhkarPrimaryStyle(palette),
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(copy.myAdhkarCreateGroup),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final atLimit = state.groupLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdhkarGlow(
          enabled: !atLimit,
          child: FilledButton.icon(
            key: const Key('my_adhkar_create_group'),
            style: adhkarPrimaryStyle(palette),
            onPressed: atLimit ? null : () => _openCreate(context),
            icon: const Icon(Icons.add, size: 20),
            label: Text(copy.myAdhkarCreateGroup),
          ),
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AdhkarNote(
              key: const Key('my_adhkar_group_limit_reason'),
              text: copy.myAdhkarCreateGroupDisabled,
            ),
          ),
        const SizedBox(height: 16),
        for (final summary in state.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
    final palette = AdhkarPalette.of(context);
    final group = summary.group;
    return Material(
      key: Key('my_adhkar_group_${group.groupId}'),
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(cubit.openGroup(group.groupId)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 6, 6),
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
                          style: adhkarText(17, FontWeight.w700, palette.text),
                        ),
                      ),
                      Text(
                        copy.groupEntries(summary.liveEntryCount),
                        key: Key('my_adhkar_group_count_${group.groupId}'),
                        style: adhkarText(14, FontWeight.w400, palette.text2),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: palette.text2),
                AdhkarMenu<_GroupAction>(
                  key: Key('my_adhkar_group_menu_${group.groupId}'),
                  tooltip: copy.menuLabel,
                  onSelected: (action) => _selected(context, action),
                  items: [
                    AdhkarMenuEntry(
                      value: _GroupAction.rename,
                      label: copy.myAdhkarRename,
                      icon: Icons.edit_outlined,
                    ),
                    AdhkarMenuEntry(
                      value: _GroupAction.delete,
                      label: copy.myAdhkarDelete,
                      icon: Icons.delete_outline,
                      destructive: true,
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

/// The in-place delete confirmation of the design: a tinted card with the
/// destructive and the cancel button side by side (stacked when narrow).
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
    final palette = AdhkarPalette.of(context);
    final confirm = FilledButton(
      key: confirmKey,
      style: adhkarDangerStyle(palette),
      onPressed: busy ? null : onConfirm,
      child: Text(confirmLabel),
    );
    final cancel = FilledButton(
      key: cancelKey,
      style: adhkarSecondaryStyle(
        palette,
        minHeight: 48,
        radius: 14,
        background: palette.surface,
      ),
      onPressed: busy ? null : onCancel,
      child: Text(cancelLabel),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.card(
        radius: 22,
        color: palette.errorSoft,
        borderColor: palette.error,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: adhkarText(17, FontWeight.w700, palette.text)),
          if (subtitle != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                subtitle!,
                textDirection: myAdhkarTextDirection(
                  subtitle!,
                  Directionality.of(context),
                ),
                style: adhkarText(14, FontWeight.w600, palette.text2),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            body,
            style: adhkarText(14, FontWeight.w400, palette.text, height: 1.7),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two buttons of at least 120 px with a 10 px gap; stacked when
              // they do not fit.
              if (constraints.maxWidth >= 250) {
                return Row(
                  children: [
                    Expanded(child: confirm),
                    const SizedBox(width: 10),
                    Expanded(child: cancel),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [confirm, const SizedBox(height: 10), cancel],
              );
            },
          ),
        ],
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
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final groupId = state.openedGroupId!;
    final name = state.openedGroup?.group.name ?? '';
    final atLimit = state.entryLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: InkWell(
            key: const Key('my_adhkar_back_to_groups'),
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 20, color: palette.accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        copy.myAdhkarBackToGroups,
                        style: adhkarText(16, FontWeight.w700, palette.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: Text(
                name,
                key: const Key('my_adhkar_group_title'),
                textDirection: myAdhkarTextDirection(
                  name,
                  Directionality.of(context),
                ),
                style: adhkarText(
                  28,
                  FontWeight.w800,
                  palette.text,
                  height: 1.4,
                ),
              ),
            ),
            AdhkarGlow(
              enabled: !atLimit,
              child: FilledButton.icon(
                key: const Key('my_adhkar_add_entry'),
                style: adhkarPrimaryStyle(palette, minHeight: 48),
                onPressed: atLimit
                    ? null
                    : () => showMyAdhkarForm(
                        context,
                        (_) => MyAdhkarEntryForm(
                          cubit: cubit,
                          openedGroupId: groupId,
                        ),
                      ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(copy.myAdhkarAdd),
              ),
            ),
          ],
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AdhkarNote(
              key: const Key('my_adhkar_add_limit_reason'),
              text: copy.myAdhkarAddDisabled,
            ),
          ),
        const SizedBox(height: 16),
        if (state.openedGroupItems.isEmpty)
          Padding(
            key: const Key('my_adhkar_group_empty'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface2,
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(Icons.add, size: 32, color: palette.text2),
                ),
                const SizedBox(height: 14),
                Text(
                  copy.myAdhkarGroupEmpty,
                  textAlign: TextAlign.center,
                  style: adhkarText(
                    16,
                    FontWeight.w400,
                    palette.text2,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in state.openedGroupItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: confirmItemId == item.itemId
                  ? _ConfirmationCard(
                      key: Key(
                        'my_adhkar_entry_delete_confirmation_${item.itemId}',
                      ),
                      title: copy.myAdhkarEntryDeleteTitle,
                      body: copy.myAdhkarEntryDeleteBody,
                      cancelKey: const Key('my_adhkar_entry_delete_cancel'),
                      confirmKey: const Key('my_adhkar_entry_delete_confirm'),
                      cancelLabel: copy.myAdhkarCancel,
                      confirmLabel: copy.myAdhkarDelete,
                      busy: state.busy,
                      onCancel: () => onConfirmItem(null),
                      onConfirm: () async {
                        final result = await cubit.deleteEntry(
                          itemId: item.itemId,
                        );
                        if (!result.ignored) onConfirmItem(null);
                      },
                    )
                  : _EntryCard(
                      copy: copy,
                      cubit: cubit,
                      openedGroupId: groupId,
                      item: item,
                      groups: state.groups,
                      onDelete: () => onConfirmItem(item.itemId),
                    ),
            ),
      ],
    );
  }
}

enum _EntryAction { edit, copy, delete }

/// One entry card: the overflow menu at the top corner, the text in Amiri
/// (selectable, direction from the text), the source below it in the
/// secondary style (selectable, its own direction, never opened), and a line
/// naming the entry's other groups. No number badge, counter, target or
/// reset.
final class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.copy,
    required this.cubit,
    required this.openedGroupId,
    required this.item,
    required this.groups,
    required this.onDelete,
  });

  final AdhkarStrings copy;
  final MyAdhkarCubit cubit;
  final String openedGroupId;
  final MyDhikrItem item;
  final List<MyAdhkarGroupSummary> groups;
  final VoidCallback onDelete;

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
        final palette = AdhkarPalette.of(context);
        await Clipboard.setData(
          ClipboardData(
            text: item.source == null
                ? item.text
                : '${item.text}\n${item.source}',
          ),
        );
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(_copiedToast(palette, copy.myAdhkarCopied));
      case _EntryAction.delete:
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final ambient = Directionality.of(context);
    final liveOtherNames = [
      for (final summary in groups)
        if (summary.group.groupId != openedGroupId &&
            item.groupIds.contains(summary.group.groupId))
          summary.group.name,
    ];
    final source = item.source;
    return Container(
      key: Key('my_adhkar_entry_${item.itemId}'),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 6, 18),
      decoration: palette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AdhkarMenu<_EntryAction>(
              key: Key('my_adhkar_entry_menu_${item.itemId}'),
              tooltip: copy.menuLabel,
              onSelected: (action) => _selected(context, action),
              items: [
                AdhkarMenuEntry(
                  value: _EntryAction.edit,
                  label: copy.myAdhkarEdit,
                  icon: Icons.edit_outlined,
                ),
                AdhkarMenuEntry(
                  value: _EntryAction.copy,
                  label: copy.myAdhkarCopy,
                  icon: Icons.copy_outlined,
                ),
                AdhkarMenuEntry(
                  value: _EntryAction.delete,
                  label: copy.myAdhkarDelete,
                  icon: Icons.delete_outline,
                  destructive: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  item.text,
                  key: Key('my_adhkar_entry_text_${item.itemId}'),
                  textDirection: myAdhkarTextDirection(item.text, ambient),
                  style: adhkarText(
                    22,
                    FontWeight.w400,
                    palette.text,
                    height: 2,
                  ).copyWith(fontFamily: kDhikrFontFamily),
                ),
                if (source != null) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    source,
                    key: Key('my_adhkar_entry_source_${item.itemId}'),
                    textDirection: myAdhkarTextDirection(source, ambient),
                    style: adhkarText(
                      14,
                      FontWeight.w400,
                      palette.text2,
                      height: 1.7,
                    ),
                  ),
                ],
                if (liveOtherNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: palette.border)),
                    ),
                    child: Text(
                      copy.otherGroups(liveOtherNames.join(copy.listSeparator)),
                      key: Key('my_adhkar_entry_other_groups_${item.itemId}'),
                      style: adhkarText(
                        13,
                        FontWeight.w600,
                        palette.accent,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The «تم النسخ» toast: a pill in the text color on the page background,
/// shown for about two seconds above the bottom bar.
SnackBar _copiedToast(AdhkarPalette palette, String message) => SnackBar(
  key: const Key('my_adhkar_copied_toast'),
  behavior: SnackBarBehavior.floating,
  backgroundColor: Colors.transparent,
  elevation: 0,
  padding: EdgeInsets.zero,
  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
  duration: const Duration(seconds: 2),
  content: Center(
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: palette.text,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 20, color: palette.bg),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: adhkarText(16, FontWeight.w700, palette.bg),
            ),
          ),
        ],
      ),
    ),
  ),
);
