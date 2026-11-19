import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_back_link.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_confirmation.dart';
import 'package:namma_project/app/widgets/app_empty_state.dart';
import 'package:namma_project/app/widgets/app_icon_badge.dart';
import 'package:namma_project/app/widgets/app_ink_surface.dart';
import 'package:namma_project/app/widgets/app_menu_button.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/app/widgets/app_toast.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../my_adhkar_cubit.dart';
import '../my_adhkar_state.dart';
import 'adhkar_style.dart';
import 'my_adhkar_forms.dart';

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
    final colors = AppColors.of(context);
    return Column(
      key: const Key('my_adhkar_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.myAdhkarHeading,
          style: AppTypography.fixed(
            20,
            FontWeight.w700,
            colors.textPrimary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          copy.myAdhkarNote,
          style: AppTypography.fixed(
            14,
            FontWeight.w400,
            colors.textSecondary,
            height: 1.7,
          ),
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
    final colors = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.fixed(
          16,
          FontWeight.w400,
          colors.textSecondary,
          height: 1.8,
        ),
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
    if (state.groups.isEmpty) {
      return AppEmptyState(
        key: const Key('my_adhkar_empty'),
        icon: Icons.wb_sunny_outlined,
        title: copy.myAdhkarEmptyTitle,
        body: copy.myAdhkarEmptyBody,
        action: AppButton(
          key: const Key('my_adhkar_create_group'),
          label: copy.myAdhkarCreateGroup,
          icon: Icons.add,
          onPressed: () => _openCreate(context),
          look: AppButtonLook.refined,
          expanded: true,
        ),
      );
    }
    final atLimit = state.groupLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          key: const Key('my_adhkar_create_group'),
          label: copy.myAdhkarCreateGroup,
          icon: Icons.add,
          onPressed: atLimit ? null : () => _openCreate(context),
          look: AppButtonLook.refined,
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppInlineNote(
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
    final colors = AppColors.of(context);
    final group = summary.group;
    return AppInkSurface(
      key: Key('my_adhkar_group_${group.groupId}'),
      color: colors.surface,
      borderColor: colors.border,
      radius: 22,
      clip: Clip.antiAlias,
      minHeight: 68,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 6, 6),
      onTap: () => unawaited(cubit.openGroup(group.groupId)),
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
                    textDirection: AppTypography.directionFor(
                      group.name,
                      Directionality.of(context),
                    ),
                    style: AppTypography.fixed(
                      17,
                      FontWeight.w700,
                      colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  copy.groupEntries(summary.liveEntryCount),
                  key: Key('my_adhkar_group_count_${group.groupId}'),
                  style: AppTypography.fixed(
                    14,
                    FontWeight.w400,
                    colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
          AppMenuButton<_GroupAction>(
            key: Key('my_adhkar_group_menu_${group.groupId}'),
            tooltip: copy.menuLabel,
            onSelected: (action) => _selected(context, action),
            entries: [
              AppMenuEntry(
                value: _GroupAction.rename,
                label: copy.myAdhkarRename,
                icon: Icons.edit_outlined,
              ),
              AppMenuEntry(
                value: _GroupAction.delete,
                label: copy.myAdhkarDelete,
                icon: Icons.delete_outline,
                destructive: true,
              ),
            ],
          ),
        ],
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
  Widget build(BuildContext context) => AppInlineConfirmation(
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
    final colors = AppColors.of(context);
    final groupId = state.openedGroupId!;
    final name = state.openedGroup?.group.name ?? '';
    final atLimit = state.entryLimitReached;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppBackLink(
            key: const Key('my_adhkar_back_to_groups'),
            label: copy.myAdhkarBackToGroups,
            onTap: onBack,
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
                textDirection: AppTypography.directionFor(
                  name,
                  Directionality.of(context),
                ),
                style: AppTypography.fixed(
                  28,
                  FontWeight.w800,
                  colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            AppButton(
              key: const Key('my_adhkar_add_entry'),
              label: copy.myAdhkarAdd,
              icon: Icons.add,
              onPressed: atLimit
                  ? null
                  : () => showMyAdhkarForm(
                      context,
                      (_) => MyAdhkarEntryForm(
                        cubit: cubit,
                        openedGroupId: groupId,
                      ),
                    ),
              look: AppButtonLook.refined,
              size: AppButtonSize.small,
              tuning: const AppButtonTuning(radius: 16),
            ),
          ],
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AppInlineNote(
              key: const Key('my_adhkar_add_limit_reason'),
              text: copy.myAdhkarAddDisabled,
            ),
          ),
        const SizedBox(height: 16),
        if (state.openedGroupItems.isEmpty)
          AppEmptyState(
            key: const Key('my_adhkar_group_empty'),
            icon: Icons.add,
            badgeSize: 72,
            iconSize: 32,
            tone: AppBadgeTone.neutral,
            body: copy.myAdhkarGroupEmpty,
          )
        else
          for (final item in state.openedGroupItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: confirmItemId == item.itemId
                  ? AppInlineConfirmation(
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
        final toast = AppToast.of(context);
        await Clipboard.setData(
          ClipboardData(
            text: item.source == null
                ? item.text
                : '${item.text}\n${item.source}',
          ),
        );
        toast.show(
          copy.myAdhkarCopied,
          key: const Key('my_adhkar_copied_toast'),
        );
      case _EntryAction.delete:
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ambient = Directionality.of(context);
    final liveOtherNames = [
      for (final summary in groups)
        if (summary.group.groupId != openedGroupId &&
            item.groupIds.contains(summary.group.groupId))
          summary.group.name,
    ];
    final source = item.source;
    return AppCard(
      key: Key('my_adhkar_entry_${item.itemId}'),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 6, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppMenuButton<_EntryAction>(
              key: Key('my_adhkar_entry_menu_${item.itemId}'),
              tooltip: copy.menuLabel,
              onSelected: (action) => _selected(context, action),
              entries: [
                AppMenuEntry(
                  value: _EntryAction.edit,
                  label: copy.myAdhkarEdit,
                  icon: Icons.edit_outlined,
                ),
                AppMenuEntry(
                  value: _EntryAction.copy,
                  label: copy.myAdhkarCopy,
                  icon: Icons.copy_outlined,
                ),
                AppMenuEntry(
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
                  textDirection: AppTypography.directionFor(item.text, ambient),
                  style: AppTypography.fixed(
                    22,
                    FontWeight.w400,
                    colors.textPrimary,
                    height: 2,
                  ).copyWith(fontFamily: kDhikrFontFamily),
                ),
                if (source != null) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    source,
                    key: Key('my_adhkar_entry_source_${item.itemId}'),
                    textDirection: AppTypography.directionFor(source, ambient),
                    style: AppTypography.fixed(
                      14,
                      FontWeight.w400,
                      colors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
                if (liveOtherNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: Text(
                      copy.otherGroups(liveOtherNames.join(copy.listSeparator)),
                      key: Key('my_adhkar_entry_other_groups_${item.itemId}'),
                      style: AppTypography.fixed(
                        13,
                        FontWeight.w600,
                        colors.accentStrong,
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
