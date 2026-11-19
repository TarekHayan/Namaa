import 'package:namma_project/features/xp/domain/xp_award.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/adhkar_repository.dart';
import 'adhkar_remote_models.dart';

/// One server catalog row (ids and targets only — the reviewed text never
/// travels through sync).
final class AdhkarCatalogRow {
  const AdhkarCatalogRow({
    required this.catalogVersion,
    required this.itemId,
    required this.list,
    required this.target,
  });

  final int catalogVersion;
  final String itemId;
  final String list;
  final int target;
}

/// One complete owner-scoped Adhkar snapshot (counts, set awards, retained
/// conflicts, and the catalog rows of the versions the counts use).
final class AdhkarRemoteSnapshot {
  const AdhkarRemoteSnapshot({
    required this.counts,
    required this.awards,
    required this.conflicts,
    required this.catalog,
  });

  final List<AdhkarCountRecord> counts;
  final List<XpAward> awards;
  final List<AdhkarRemoteConflict> conflicts;
  final List<AdhkarCatalogRow> catalog;
}

abstract interface class AdhkarRemoteReader {
  Future<AdhkarRemoteSnapshot> readAll(String accountId);
}

/// The catalog table is read once per catalog version and cached for the
/// process lifetime (contracts/adhkar-qiyam-sync.md). An empty result is NOT
/// cached: a catalog seeded later must still be picked up (Phase 6 review
/// follow-up).
final class AdhkarCatalogCache {
  final _cache = <int, List<AdhkarCatalogRow>>{};

  Future<List<AdhkarCatalogRow>> rowsFor(
    int version,
    Future<List<AdhkarCatalogRow>> Function(int version) fetch,
  ) async {
    final cached = _cache[version];
    if (cached != null) return cached;
    final rows = await fetch(version);
    if (rows.isNotEmpty) {
      _cache[version] = rows;
    }
    return rows;
  }
}

/// Each pass restarts from the first stable key. A concurrent insertion behind
/// the cursor is picked up by the next pass instead of being permanently lost;
/// a failed page fails the pass without advancing anything.
final class SupabaseAdhkarReader implements AdhkarRemoteReader {
  SupabaseAdhkarReader(this._client, {this.pageSize = 100}) {
    if (pageSize < 1 || pageSize > 1000) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
  }

  final SupabaseClient _client;
  final int pageSize;
  final AdhkarCatalogCache _catalogCache = AdhkarCatalogCache();

  @override
  Future<AdhkarRemoteSnapshot> readAll(String accountId) async {
    _requireOwner(accountId);
    final counts = <AdhkarCountRecord>[];
    String? cursor;
    do {
      final query = _client
          .from('adhkar_item_counts')
          .select()
          .eq('owner', accountId);
      final rows = await (cursor == null
          ? query.order('record_id', ascending: true).limit(pageSize)
          : query
                .gt('record_id', cursor)
                .order('record_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          AdhkarRemoteModels.record(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.recordId).toList(), cursor);
      counts.addAll(page);
      cursor = page.length == pageSize ? page.last.recordId : null;
    } while (cursor != null);

    final awards = <XpAward>[];
    cursor = null;
    do {
      final query = _client
          .from('xp_awards')
          .select()
          .eq('owner', accountId)
          .eq('source', kAdhkarSetDoneAwardSource);
      final rows = await (cursor == null
          ? query.order('source_id', ascending: true).limit(pageSize)
          : query
                .gt('source_id', cursor)
                .order('source_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          AdhkarRemoteModels.award(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.sourceId).toList(), cursor);
      awards.addAll(page);
      cursor = page.length == pageSize ? page.last.sourceId : null;
    } while (cursor != null);

    final conflicts = <AdhkarRemoteConflict>[];
    cursor = null;
    do {
      final query = _client
          .from('adhkar_conflicts')
          .select()
          .eq('owner', accountId);
      final rows = await (cursor == null
          ? query.order('conflict_id', ascending: true).limit(pageSize)
          : query
                .gt('conflict_id', cursor)
                .order('conflict_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          AdhkarRemoteConflict(
            id: row['conflict_id'] as String,
            active: AdhkarRemoteModels.record(
              Map<String, dynamic>.from(row['active_record'] as Map),
              accountId,
            ),
            retained: AdhkarRemoteModels.record(
              Map<String, dynamic>.from(row['retained_record'] as Map),
              accountId,
            ),
            detectedAt: DateTime.parse(row['detected_at'] as String).toUtc(),
          ),
      ];
      _validatePage(page.map((e) => e.id).toList(), cursor);
      conflicts.addAll(page);
      cursor = page.length == pageSize ? page.last.id : null;
    } while (cursor != null);

    // The catalog rows for every version the counts reference — one read per
    // version, cached across passes.
    final catalog = <AdhkarCatalogRow>[];
    final versions = counts.map((row) => row.catalogVersion).toSet();
    for (final version in versions) {
      catalog.addAll(
        await _catalogCache.rowsFor(version, (v) async {
          final rows = await _client
              .from('adhkar_catalog_items')
              .select()
              .eq('catalog_version', v)
              .order('item_id', ascending: true);
          _requireOwner(accountId);
          return [
            for (final row in rows)
              AdhkarCatalogRow(
                catalogVersion: row['catalog_version'] as int,
                itemId: row['item_id'] as String,
                list: row['list'] as String,
                target: row['target'] as int,
              ),
          ];
        }),
      );
    }

    return AdhkarRemoteSnapshot(
      counts: List.unmodifiable(counts),
      awards: List.unmodifiable(awards),
      conflicts: List.unmodifiable(conflicts),
      catalog: List.unmodifiable(catalog),
    );
  }

  void _requireOwner(String expected) {
    if (_client.auth.currentUser?.id != expected) {
      throw StateError('Authenticated account changed during Adhkar read');
    }
  }

  void _validatePage(List<String> keys, String? previous) {
    for (var i = 0; i < keys.length; i++) {
      if ((i == 0 && previous != null && keys[i].compareTo(previous) <= 0) ||
          (i > 0 && keys[i].compareTo(keys[i - 1]) <= 0)) {
        throw const FormatException('Adhkar page cursor did not advance');
      }
    }
  }
}
