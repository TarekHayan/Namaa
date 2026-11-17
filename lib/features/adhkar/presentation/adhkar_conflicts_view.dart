import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../domain/adhkar_conflict_evidence.dart';
import 'widgets/my_adhkar_support.dart';

/// Read-only evidence from the encrypted owner-scoped conflict store
/// (contracts/adhkar-qiyam-ui.md): both versions of each retained count
/// conflict and of each retained My Adhkar group or entry conflict, with no
/// resolve action of any kind. Count entries name the list and the item's
/// position from the catalog (never the internal item id), and the day is
/// formatted with the app locale (Phase 6 review finding 3). My Adhkar
/// entries show the user's own text, shortened when long.
class AdhkarConflictsView extends StatelessWidget {
  // Not const: the view caches its catalog future in a late final field.
  AdhkarConflictsView({
    super.key,
    required this.conflicts,
    this.myAdhkarConflicts,
    required this.catalog,
    required this.ownerId,
    required this.locale,
  });

  final Stream<List<AdhkarConflictEvidence>> conflicts;

  /// The owner's retained My Adhkar group and entry conflicts, when the
  /// caller wires them (T098); null shows only the count conflicts.
  final Stream<List<MyAdhkarConflictEvidence>>? myAdhkarConflicts;
  final AdhkarCatalogPort catalog;
  final String ownerId;
  final String locale;

  /// The longest text shown for a version of a My Adhkar entry, and for its
  /// source; longer text ends with an ellipsis.
  static const int maxTextCodePoints = 80;
  static const int maxSourceCodePoints = 60;

  /// The catalog resolves once per view; every row's title is a synchronous
  /// lookup over it (a future created inside build would be replaced on
  /// every rebuild and never surface).
  late final Future<AdhkarCatalog?> _catalogFuture = catalog
      .snapshot(ownerId)
      .then((result) => result.valueOrNull);

  @override
  Widget build(BuildContext context) => FutureBuilder<AdhkarCatalog?>(
    future: _catalogFuture,
    builder: (context, catalogSnapshot) =>
        StreamBuilder<List<AdhkarConflictEvidence>>(
          stream: conflicts,
          builder: (context, snapshot) =>
              StreamBuilder<List<MyAdhkarConflictEvidence>>(
                stream: myAdhkarConflicts,
                builder: (context, mineSnapshot) {
                  final rows =
                      snapshot.data ?? const <AdhkarConflictEvidence>[];
                  final mine =
                      mineSnapshot.data ?? const <MyAdhkarConflictEvidence>[];
                  if (rows.isEmpty && mine.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final copy = FoundationLocalizations.of(context);
                  final theme = Theme.of(context);
                  final resolvedCatalog = catalogSnapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        copy.adhkarConflicts,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final row in rows)
                        _countCard(context, copy, resolvedCatalog, row),
                      for (final row in mine) _myAdhkarCard(context, copy, row),
                    ],
                  );
                },
              ),
        ),
  );

  Widget _countCard(
    BuildContext context,
    FoundationLocalizations copy,
    AdhkarCatalog? resolvedCatalog,
    AdhkarConflictEvidence row,
  ) {
    final theme = Theme.of(context);
    final day = _day(row);
    final title = _titleFor(copy, resolvedCatalog, row);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              key: ValueKey('adhkar-conflict-${row.id}'),
              style: theme.textTheme.titleMedium,
            ),
            // The title falls back to the day when the catalog or the list
            // is unknown; the day is not repeated underneath.
            if (title != day)
              Text(
                day,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            _VersionLine(
              label: copy.adhkarConflictActive,
              state: copy.adhkarConflictCount(row.activeCount),
            ),
            const SizedBox(height: 6),
            _VersionLine(
              label: copy.adhkarConflictRetained,
              state: copy.adhkarConflictCount(row.retainedCount),
            ),
            const SizedBox(height: 10),
            Text(copy.adhkarConflictReadOnly, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _myAdhkarCard(
    BuildContext context,
    FoundationLocalizations copy,
    MyAdhkarConflictEvidence row,
  ) {
    final theme = Theme.of(context);
    final isGroup = row.entityType == 'group';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isGroup ? copy.myAdhkarConflictGroup : copy.myAdhkarConflictEntry,
              key: ValueKey('my-adhkar-conflict-${row.id}'),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              DateFormat.yMMMd(
                locale,
              ).add_jm().format(row.detectedAt.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _MyAdhkarVersion(
              label: copy.adhkarConflictActive,
              version: row.active,
              isGroup: isGroup,
              locale: locale,
              deletedLabel: copy.myAdhkarConflictDeleted,
            ),
            const SizedBox(height: 8),
            _MyAdhkarVersion(
              label: copy.adhkarConflictRetained,
              version: row.retained,
              isGroup: isGroup,
              locale: locale,
              deletedLabel: copy.myAdhkarConflictDeleted,
            ),
            const SizedBox(height: 10),
            Text(copy.adhkarConflictReadOnly, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// The human entry title: the list name plus the item's position from the
  /// catalog ("Morning adhkar · item 1"); an item the catalog does not know
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

  String _day(AdhkarConflictEvidence row) => DateFormat.MMMEd(locale).format(
    DateTime.utc(
      int.parse(row.adhkarDay.substring(0, 4)),
      int.parse(row.adhkarDay.substring(5, 7)),
      int.parse(row.adhkarDay.substring(8, 10)),
    ),
  );
}

class _VersionLine extends StatelessWidget {
  const _VersionLine({required this.label, required this.state});

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(state, textAlign: TextAlign.end)),
    ],
  );
}

/// One stored version of a My Adhkar group or entry: its label, then the
/// name (group) or the shortened text and source (entry), or "Deleted" for a
/// tombstone, then when that version was saved.
class _MyAdhkarVersion extends StatelessWidget {
  const _MyAdhkarVersion({
    required this.label,
    required this.version,
    required this.isGroup,
    required this.locale,
    required this.deletedLabel,
  });

  final String label;
  final Map<String, dynamic> version;
  final bool isGroup;
  final String locale;
  final String deletedLabel;

  static String? _string(Object? value) => value is String ? value : null;

  static String _shorten(String text, int limit) {
    final runes = text.runes.toList();
    if (runes.length <= limit) return text;
    return '${String.fromCharCodes(runes.take(limit))}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ambient = Directionality.of(context);
    final deleted = version['deleted_at'] != null;
    final primary = deleted
        ? deletedLabel
        : isGroup
        ? _string(version['name'])
        : _string(version['text']);
    final source = deleted || isGroup ? null : _string(version['source']);
    final savedAt = DateTime.tryParse(_string(version['updated_at']) ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        if (primary != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              deleted
                  ? primary
                  : _shorten(primary, AdhkarConflictsView.maxTextCodePoints),
              textDirection: myAdhkarTextDirection(primary, ambient),
            ),
          ),
        if (source != null && source.trim().isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _shorten(source, AdhkarConflictsView.maxSourceCodePoints),
              textDirection: myAdhkarTextDirection(source, ambient),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (savedAt != null)
          Text(
            DateFormat.yMMMd(locale).add_jm().format(savedAt.toLocal()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
