import 'package:supabase_flutter/supabase_flutter.dart';

import 'my_adhkar_remote_models.dart';

/// One complete owner-scoped My Adhkar snapshot: the groups, the entries
/// with their group sets, and the retained conflicts.
final class MyAdhkarRemoteSnapshot {
  const MyAdhkarRemoteSnapshot({
    required this.groups,
    required this.items,
    required this.conflicts,
  });

  final List<MyAdhkarRemoteGroup> groups;
  final List<MyAdhkarRemoteItem> items;
  final List<MyAdhkarRemoteConflict> conflicts;
}

abstract interface class MyAdhkarRemoteReader {
  Future<MyAdhkarRemoteSnapshot> readAll(String accountId);
}

/// One keyset page of raw rows per call: ordered by the table's key, strictly
/// after [after] (or from the start when null), at most [limit] rows, only
/// the owner's. The Supabase implementation is the only code that touches
/// the client, so the paging rules are testable without a network.
abstract interface class MyAdhkarPageSource {
  String? get currentAccountId;

  /// `my_adhkar_groups`, ordered by `group_id`.
  Future<List<Map<String, dynamic>>> groupPage({
    required String accountId,
    required int limit,
    String? after,
  });

  /// `my_adhkar_items` with their `my_adhkar_item_groups` rows embedded in
  /// the same row (so a group set always belongs to its version), ordered by
  /// `item_id`.
  Future<List<Map<String, dynamic>>> itemPage({
    required String accountId,
    required int limit,
    String? after,
  });

  /// `my_adhkar_conflicts`, ordered by `conflict_id`.
  Future<List<Map<String, dynamic>>> conflictPage({
    required String accountId,
    required int limit,
    String? after,
  });
}

final class SupabaseMyAdhkarPageSource implements MyAdhkarPageSource {
  SupabaseMyAdhkarPageSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> groupPage({
    required String accountId,
    required int limit,
    String? after,
  }) async {
    var query = _client
        .from('my_adhkar_groups')
        .select()
        .eq('owner', accountId);
    if (after != null) query = query.gt('group_id', after);
    final rows = await query.order('group_id', ascending: true).limit(limit);
    return _maps(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> itemPage({
    required String accountId,
    required int limit,
    String? after,
  }) async {
    var query = _client
        .from('my_adhkar_items')
        .select('*, my_adhkar_item_groups(group_id, added_at)')
        .eq('owner', accountId);
    if (after != null) query = query.gt('item_id', after);
    final rows = await query.order('item_id', ascending: true).limit(limit);
    return _maps(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> conflictPage({
    required String accountId,
    required int limit,
    String? after,
  }) async {
    var query = _client
        .from('my_adhkar_conflicts')
        .select()
        .eq('owner', accountId);
    if (after != null) query = query.gt('conflict_id', after);
    final rows = await query.order('conflict_id', ascending: true).limit(limit);
    return _maps(rows);
  }

  static List<Map<String, dynamic>> _maps(List<dynamic> rows) => [
    for (final row in rows) Map<String, dynamic>.from(row as Map),
  ];
}

/// Each pass restarts from the first stable key. A concurrent insertion
/// behind the cursor is picked up by the next pass instead of being lost; a
/// failed page fails the pass without advancing anything, so the retry
/// starts again from the first key. A page that does not advance, an
/// oversized page, a foreign owner or an invalid row fails the pass.
final class SupabaseMyAdhkarReader implements MyAdhkarRemoteReader {
  SupabaseMyAdhkarReader(this._source, {this.pageSize = 100}) {
    if (pageSize < 1 || pageSize > 1000) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
  }

  final MyAdhkarPageSource _source;
  final int pageSize;

  @override
  Future<MyAdhkarRemoteSnapshot> readAll(String accountId) async {
    _requireOwner(accountId);
    final groups = await _scan<MyAdhkarRemoteGroup>(
      accountId: accountId,
      keyField: 'group_id',
      fetch: (after) => _source.groupPage(
        accountId: accountId,
        limit: pageSize,
        after: after,
      ),
      parse: (row) => MyAdhkarRemoteGroup.fromJson(row, accountId),
    );
    final items = await _scan<MyAdhkarRemoteItem>(
      accountId: accountId,
      keyField: 'item_id',
      fetch: (after) =>
          _source.itemPage(accountId: accountId, limit: pageSize, after: after),
      parse: (row) => MyAdhkarRemoteItem.fromJson(row, accountId),
    );
    final conflicts = await _scan<MyAdhkarRemoteConflict>(
      accountId: accountId,
      keyField: 'conflict_id',
      fetch: (after) => _source.conflictPage(
        accountId: accountId,
        limit: pageSize,
        after: after,
      ),
      parse: (row) => MyAdhkarRemoteConflict.fromRow(row, accountId),
    );
    return MyAdhkarRemoteSnapshot(
      groups: List.unmodifiable(groups),
      items: List.unmodifiable(items),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  Future<List<T>> _scan<T>({
    required String accountId,
    required String keyField,
    required Future<List<Map<String, dynamic>>> Function(String? after) fetch,
    required T Function(Map<String, dynamic> row) parse,
  }) async {
    final result = <T>[];
    String? after;
    while (true) {
      final rows = await fetch(after);
      _requireOwner(accountId);
      if (rows.length > pageSize) {
        throw StateError('My Adhkar page is larger than requested');
      }
      var previous = after;
      for (final row in rows) {
        final key = row[keyField];
        if (key is! String ||
            (previous != null && key.compareTo(previous) <= 0)) {
          throw const FormatException('My Adhkar page cursor did not advance');
        }
        previous = key;
        result.add(parse(row));
      }
      if (rows.length < pageSize) return result;
      after = previous;
    }
  }

  void _requireOwner(String expected) {
    if (_source.currentAccountId != expected) {
      throw StateError('Authenticated account changed during My Adhkar read');
    }
  }
}
