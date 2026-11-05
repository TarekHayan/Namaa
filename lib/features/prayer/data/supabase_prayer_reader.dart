import 'package:supabase_flutter/supabase_flutter.dart';

import '../../xp/domain/xp_award.dart';
import '../domain/prayer_report.dart';
import 'prayer_remote_models.dart';

final class PrayerRemoteSnapshot {
  const PrayerRemoteSnapshot({
    required this.reports,
    required this.awards,
    required this.conflicts,
  });
  final List<PrayerReport> reports;
  final List<XpAward> awards;
  final List<PrayerRemoteConflict> conflicts;
}

abstract interface class PrayerRemoteReader {
  Future<PrayerRemoteSnapshot> readAll(String accountId);
}

/// Each pass restarts from the first stable key. A concurrent insertion behind
/// the cursor is picked up by the next pass instead of being permanently lost.
final class SupabasePrayerReader implements PrayerRemoteReader {
  SupabasePrayerReader(this._client, {this.pageSize = 100}) {
    if (pageSize < 1 || pageSize > 1000) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
  }

  final SupabaseClient _client;
  final int pageSize;

  @override
  Future<PrayerRemoteSnapshot> readAll(String accountId) async {
    _requireOwner(accountId);
    final reports = <PrayerReport>[];
    final awards = <XpAward>[];
    final conflicts = <PrayerRemoteConflict>[];
    String? cursor;
    do {
      final query = _client
          .from('prayer_reports')
          .select()
          .eq('owner', accountId);
      final rows = await (cursor == null
          ? query.order('report_id', ascending: true).limit(pageSize)
          : query
                .gt('report_id', cursor)
                .order('report_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          PrayerRemoteModels.report(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.reportId).toList(), cursor);
      reports.addAll(page);
      cursor = page.length == pageSize ? page.last.reportId : null;
    } while (cursor != null);

    cursor = null;
    do {
      final query = _client
          .from('xp_awards')
          .select()
          .eq('owner', accountId)
          .eq('source', kPrayerDoneAwardSource);
      final rows = await (cursor == null
          ? query.order('source_id', ascending: true).limit(pageSize)
          : query
                .gt('source_id', cursor)
                .order('source_id', ascending: true)
                .limit(pageSize));
      _requireOwner(accountId);
      final page = [
        for (final row in rows)
          PrayerRemoteModels.award(Map<String, dynamic>.from(row), accountId),
      ];
      _validatePage(page.map((e) => e.sourceId).toList(), cursor);
      awards.addAll(page);
      cursor = page.length == pageSize ? page.last.sourceId : null;
    } while (cursor != null);

    cursor = null;
    do {
      final query = _client
          .from('prayer_conflicts')
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
          PrayerRemoteModels.conflict(
            Map<String, dynamic>.from(row),
            accountId,
          ),
      ];
      _validatePage(page.map((e) => e.id).toList(), cursor);
      conflicts.addAll(page);
      cursor = page.length == pageSize ? page.last.id : null;
    } while (cursor != null);

    return PrayerRemoteSnapshot(
      reports: List.unmodifiable(reports),
      awards: List.unmodifiable(awards),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  void _requireOwner(String expected) {
    if (_client.auth.currentUser?.id != expected) {
      throw StateError('Authenticated account changed during Prayer read');
    }
  }

  void _validatePage(List<String> keys, String? previous) {
    for (var i = 0; i < keys.length; i++) {
      if ((i == 0 && previous != null && keys[i].compareTo(previous) <= 0) ||
          (i > 0 && keys[i].compareTo(keys[i - 1]) <= 0)) {
        throw const FormatException('Prayer page cursor did not advance');
      }
    }
  }
}
