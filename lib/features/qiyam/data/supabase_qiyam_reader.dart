import 'package:namma_project/features/xp/domain/xp_award.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/qiyam_night_record.dart';
import 'qiyam_remote_models.dart';

/// One complete owner-scoped Qiyam snapshot (nights, night awards, retained
/// conflicts). Qiyam has no catalog table.
final class QiyamRemoteSnapshot {
  const QiyamRemoteSnapshot({
    required this.nights,
    required this.awards,
    required this.conflicts,
  });

  final List<QiyamNightRecord> nights;
  final List<XpAward> awards;
  final List<QiyamRemoteConflict> conflicts;
}

abstract interface class QiyamRemoteReader {
  Future<QiyamRemoteSnapshot> readAll(String accountId);
}

/// Each pass restarts from the first stable key; a failed page fails the
/// pass without advancing anything (as in 008).
final class SupabaseQiyamReader implements QiyamRemoteReader {
  SupabaseQiyamReader(this._client, {this.pageSize = 100}) {
    if (pageSize < 1 || pageSize > 1000) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
  }

  final SupabaseClient _client;
  final int pageSize;

  @override
  Future<QiyamRemoteSnapshot> readAll(String accountId) async {
    _requireOwner(accountId);
    final nights = <QiyamNightRecord>[];
    String? cursor;
    do {
      final query = _client
          .from('qiyam_nights')
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
          QiyamRemoteModels.record(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.recordId).toList(), cursor);
      nights.addAll(page);
      cursor = page.length == pageSize ? page.last.recordId : null;
    } while (cursor != null);

    final awards = <XpAward>[];
    cursor = null;
    do {
      final query = _client
          .from('xp_awards')
          .select()
          .eq('owner', accountId)
          .eq('source', kQiyamDoneAwardSource);
      final rows = await (cursor == null
          ? query.order('source_id', ascending: true).limit(pageSize)
          : query
                .gt('source_id', cursor)
                .order('source_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          QiyamRemoteModels.award(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.sourceId).toList(), cursor);
      awards.addAll(page);
      cursor = page.length == pageSize ? page.last.sourceId : null;
    } while (cursor != null);

    final conflicts = <QiyamRemoteConflict>[];
    cursor = null;
    do {
      final query = _client
          .from('qiyam_conflicts')
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
          QiyamRemoteConflict(
            id: row['conflict_id'] as String,
            active: QiyamRemoteModels.record(
              Map<String, dynamic>.from(row['active_record'] as Map),
              accountId,
            ),
            retained: QiyamRemoteModels.record(
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

    return QiyamRemoteSnapshot(
      nights: List.unmodifiable(nights),
      awards: List.unmodifiable(awards),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  void _requireOwner(String expected) {
    if (_client.auth.currentUser?.id != expected) {
      throw StateError('Authenticated account changed during Qiyam read');
    }
  }

  void _validatePage(List<String> keys, String? previous) {
    for (var i = 0; i < keys.length; i++) {
      if ((i == 0 && previous != null && keys[i].compareTo(previous) <= 0) ||
          (i > 0 && keys[i].compareTo(keys[i - 1]) <= 0)) {
        throw const FormatException('Qiyam page cursor did not advance');
      }
    }
  }
}
