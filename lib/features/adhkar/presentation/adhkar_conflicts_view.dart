import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_layout.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_action_tile.dart';
import 'package:namma_project/app/widgets/app_back_link.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_pill.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../domain/adhkar_conflict_evidence.dart';
import 'widgets/adhkar_style.dart';

/// The owner-scoped conflict evidence behind the "Sync differences" row and
/// page (contracts/adhkar-qiyam-ui.md): the owner's retained count conflicts
/// and, when the caller wires them (T098), the retained My Adhkar group and
/// entry conflicts. Nothing here can resolve a conflict.
final class AdhkarConflictsSource {
  // Not const: the source caches its catalog future in a late final field.
  AdhkarConflictsSource({
    required this.conflicts,
    this.myAdhkarConflicts,
    required this.catalog,
    required this.ownerId,
    required this.locale,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final Stream<List<AdhkarConflictEvidence>> conflicts;

  /// The owner's retained My Adhkar group and entry conflicts; null shows
  /// only the count conflicts.
  final Stream<List<MyAdhkarConflictEvidence>>? myAdhkarConflicts;
  final AdhkarCatalogPort catalog;
  final String ownerId;
  final String locale;

  /// The clock behind "Today" and "Yesterday" in the version times.
  final DateTime Function() now;

  /// The catalog resolves once per source; every entry's title is a
  /// synchronous lookup over it (a future created inside build would be
  /// replaced on every rebuild and never surface).
  late final Future<AdhkarCatalog?> catalogFuture = catalog
      .snapshot(ownerId)
      .then((result) => result.valueOrNull);
}

/// The compact "Sync differences" row on the Adhkar page: it renders nothing
/// unless the owner has retained conflicts, and opens the read-only page.
final class AdhkarConflictsRow extends StatelessWidget {
  const AdhkarConflictsRow({
    super.key,
    required this.source,
    required this.onOpen,
  });

  final AdhkarConflictsSource source;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<AdhkarConflictEvidence>>(
        stream: source.conflicts,
        builder: (context, snapshot) =>
            StreamBuilder<List<MyAdhkarConflictEvidence>>(
              stream: source.myAdhkarConflicts,
              builder: (context, mineSnapshot) {
                final any =
                    (snapshot.data?.isNotEmpty ?? false) ||
                    (mineSnapshot.data?.isNotEmpty ?? false);
                if (!any) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AppActionTile(
                    key: const Key('adhkar_sync_row'),
                    icon: Icons.sync_alt_rounded,
                    label: FoundationLocalizations.of(context).adhkarConflicts,
                    onTap: onOpen,
                  ),
                );
              },
            ),
      );
}

/// The read-only "Sync differences" page, inside `/adhkar`: each entry has a
/// title and both versions, stacked on a phone and side by side on a wide
/// window, each with its time and its value (a count, a group name, a dhikr's
/// text cut to three lines, or "Deleted"), and the footer. No resolution
/// action is offered; the only control returns to the Adhkar page.
final class AdhkarConflictsPage extends StatelessWidget {
  const AdhkarConflictsPage({
    super.key,
    required this.source,
    required this.onBack,
  });

  final AdhkarConflictsSource source;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final copy = FoundationLocalizations.of(context);
    final wide = AppLayout.isWide(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = wide ? 32.0 : 20.0;
            final side = math.max(
              base,
              (constraints.maxWidth - AppLayout.columnMaxWidth) / 2,
            );
            return FutureBuilder<AdhkarCatalog?>(
              future: source.catalogFuture,
              builder: (context, catalogSnapshot) =>
                  StreamBuilder<List<AdhkarConflictEvidence>>(
                    stream: source.conflicts,
                    builder: (context, snapshot) =>
                        StreamBuilder<List<MyAdhkarConflictEvidence>>(
                          stream: source.myAdhkarConflicts,
                          builder: (context, mineSnapshot) {
                            final rows =
                                snapshot.data ??
                                const <AdhkarConflictEvidence>[];
                            final mine =
                                mineSnapshot.data ??
                                const <MyAdhkarConflictEvidence>[];
                            final resolvedCatalog = catalogSnapshot.data;
                            return ListView(
                              key: const Key('adhkar_sync_page'),
                              padding: EdgeInsets.fromLTRB(side, 24, side, 24),
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: AppBackLink(
                                    key: const Key('adhkar_sync_back'),
                                    label: copy.adhkarBackToAdhkar,
                                    onTap: onBack,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  copy.adhkarConflicts,
                                  style: AppTypography.fixed(
                                    28,
                                    FontWeight.w800,
                                    colors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                for (final row in rows) ...[
                                  const SizedBox(height: 16),
                                  _countCard(
                                    context,
                                    copy,
                                    resolvedCatalog,
                                    row,
                                    wide,
                                  ),
                                ],
                                for (final row in mine) ...[
                                  const SizedBox(height: 16),
                                  _myAdhkarCard(context, copy, row, wide),
                                ],
                                const SizedBox(height: 20),
                                _Footer(text: copy.adhkarConflictReadOnly),
                              ],
                            );
                          },
                        ),
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget _countCard(
    BuildContext context,
    FoundationLocalizations copy,
    AdhkarCatalog? resolvedCatalog,
    AdhkarConflictEvidence row,
    bool wide,
  ) {
    final title = _titleFor(copy, resolvedCatalog, row);
    return _EntryCard(
      cardKey: ValueKey('adhkar-conflict-${row.id}'),
      title: title,
      wide: wide,
      active: _VersionView(
        label: copy.adhkarConflictActive,
        time: _stamp(context, copy, row.activeAt),
        value: copy.adhkarConflictCount(row.activeCount),
        activeVersion: true,
      ),
      saved: _VersionView(
        label: copy.adhkarConflictRetained,
        time: _stamp(context, copy, row.retainedAt),
        value: copy.adhkarConflictCount(row.retainedCount),
        activeVersion: false,
      ),
    );
  }

  Widget _myAdhkarCard(
    BuildContext context,
    FoundationLocalizations copy,
    MyAdhkarConflictEvidence row,
    bool wide,
  ) {
    final isGroup = row.entityType == 'group';
    _VersionView version(
      Map<String, dynamic> data,
      String label, {
      required bool activeVersion,
    }) {
      final deleted = data['deleted_at'] != null;
      final value = deleted
          ? null
          : (isGroup ? _string(data['name']) : _string(data['text']));
      final savedAt = DateTime.tryParse(_string(data['updated_at']) ?? '');
      return _VersionView(
        label: label,
        time: savedAt == null ? null : _stamp(context, copy, savedAt),
        value: value,
        deleted: deleted,
        deletedLabel: copy.myAdhkarConflictDeleted,
        longText: !isGroup,
        activeVersion: activeVersion,
      );
    }

    return _EntryCard(
      cardKey: ValueKey('my-adhkar-conflict-${row.id}'),
      title: isGroup ? copy.myAdhkarConflictGroup : copy.myAdhkarConflictEntry,
      wide: wide,
      active: version(
        row.active,
        copy.adhkarConflictActive,
        activeVersion: true,
      ),
      saved: version(
        row.retained,
        copy.adhkarConflictRetained,
        activeVersion: false,
      ),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  /// "Today 6:12 AM", "Yesterday 9:40 PM", or the full date and time.
  String _stamp(
    BuildContext context,
    FoundationLocalizations copy,
    DateTime at,
  ) {
    final local = at.toLocal();
    final now = source.now();
    final time = DateFormat.jm(source.locale).format(local);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return copy.adhkarSyncToday(time);
    if (difference == 1) return copy.adhkarSyncYesterday(time);
    return DateFormat.yMMMd(source.locale).add_jm().format(local);
  }

  /// The human entry title: the list name plus the item's position from the
  /// catalog ("Morning adhkar · Dhikr 8"); an item the catalog does not know
  /// falls back to the list name alone, and an unknown list or catalog keeps
  /// the formatted day. No internal ids, no religious text.
  String _titleFor(
    FoundationLocalizations copy,
    AdhkarCatalog? resolvedCatalog,
    AdhkarConflictEvidence row,
  ) {
    final list = row.list;
    if (resolvedCatalog == null || list == null) {
      return _day(row);
    }
    final listName = switch (list) {
      'morning' => copy.adhkarConflictListMorning,
      'evening' => copy.adhkarConflictListEvening,
      _ => null,
    };
    if (listName == null) {
      return _day(row);
    }
    final listEnum = list == 'morning'
        ? AdhkarList.morning
        : AdhkarList.evening;
    for (final item in resolvedCatalog.itemsOf(listEnum)) {
      if (item.itemId == row.itemId) {
        return '$listName · ${copy.adhkarConflictItem(item.position)}';
      }
    }
    return listName;
  }

  String _day(AdhkarConflictEvidence row) =>
      DateFormat.MMMEd(source.locale).format(
        DateTime.utc(
          int.parse(row.adhkarDay.substring(0, 4)),
          int.parse(row.adhkarDay.substring(5, 7)),
          int.parse(row.adhkarDay.substring(8, 10)),
        ),
      );
}

final class _Footer extends StatelessWidget {
  const _Footer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      key: const Key('adhkar_sync_footer'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

final class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.cardKey,
    required this.title,
    required this.wide,
    required this.active,
    required this.saved,
  });

  final Key cardKey;
  final String title;
  final bool wide;
  final _VersionView active;
  final _VersionView saved;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            key: cardKey,
            style: AppTypography.fixed(17, FontWeight.w700, colors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: active),
                const SizedBox(width: 12),
                Expanded(child: saved),
              ],
            )
          else ...[
            active,
            const SizedBox(height: 12),
            saved,
          ],
        ],
      ),
    );
  }
}

/// One stored version: its label chip, when it was saved, and its value (a
/// count, a name, a dhikr's text cut to three lines, or "Deleted").
final class _VersionView extends StatelessWidget {
  const _VersionView({
    required this.label,
    required this.time,
    required this.activeVersion,
    this.value,
    this.deleted = false,
    this.deletedLabel = '',
    this.longText = false,
  });

  final String label;
  final String? time;
  final String? value;
  final bool deleted;
  final String deletedLabel;
  final bool longText;
  final bool activeVersion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ambient = Directionality.of(context);
    final text = value;
    return AppCard(
      tone: activeVersion ? AppCardTone.accent : AppCardTone.secondary,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPill(
            label: label,
            tone: activeVersion ? AppPillTone.filled : AppPillTone.neutral,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          ),
          if (time != null) ...[
            const SizedBox(height: 8),
            Text(
              time!,
              style: AppTypography.fixed(
                14,
                FontWeight.w400,
                colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (deleted)
            AppPill(
              key: const Key('adhkar_sync_deleted'),
              label: deletedLabel,
              tone: AppPillTone.error,
              icon: Icons.delete_outline,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            )
          else if (text != null && longText)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: AppTypography.directionFor(text, ambient),
                style: AppTypography.fixed(
                  22,
                  FontWeight.w400,
                  colors.textPrimary,
                  height: 1.9,
                ).copyWith(fontFamily: kDhikrFontFamily),
              ),
            )
          else if (text != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                text,
                textDirection: AppTypography.directionFor(text, ambient),
                style: AppTypography.fixed(
                  16,
                  FontWeight.w600,
                  colors.textPrimary,
                  height: 1.7,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
