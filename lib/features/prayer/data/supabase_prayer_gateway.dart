import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'prayer_remote_models.dart';

abstract interface class SupabasePrayerGateway {
  String? get currentAccountId;

  Future<PrayerReport?> fetchReport({
    required String expectedAccountId,
    required String reportId,
  });

  Future<PrayerDispatchReceipt> applyChange({
    required String expectedAccountId,
    required PrayerReport report,
    required String operationId,
    required DateTime? baseUpdatedAt,
  });
}

final class SupabasePrayerGatewayImpl implements SupabasePrayerGateway {
  SupabasePrayerGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  @override
  Future<PrayerReport?> fetchReport({
    required String expectedAccountId,
    required String reportId,
  }) async {
    _requireOwner(expectedAccountId);
    final response = await _client
        .from('prayer_reports')
        .select()
        .eq('owner', expectedAccountId)
        .eq('report_id', reportId)
        .maybeSingle();
    _requireOwner(expectedAccountId);
    return response == null
        ? null
        : PrayerRemoteModels.report(
            Map<String, dynamic>.from(response),
            expectedAccountId,
          );
  }

  @override
  Future<PrayerDispatchReceipt> applyChange({
    required String expectedAccountId,
    required PrayerReport report,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    _requireOwner(expectedAccountId);
    if (report.accountId != expectedAccountId) {
      throw const FormatException('Prayer outbound owner mismatch');
    }
    final response = await _client.rpc<dynamic>(
      'apply_prayer_report_change_v1',
      params: <String, Object?>{
        'p_report_id': report.reportId,
        'p_local_date': report.date.value,
        'p_prayer_name': report.name.wireName,
        'p_status': report.status.wireName,
        'p_reported_completion_at': report.reportedCompletionAt
            ?.toUtc()
            .toIso8601String(),
        'p_recorded_zone_id': report.recordedZoneId,
        'p_recorded_offset_minutes': report.recordedOffsetMinutes,
        'p_created_at': report.createdAt.toUtc().toIso8601String(),
        'p_updated_at': report.updatedAt.toUtc().toIso8601String(),
        'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
        'p_operation_id': operationId,
      },
    );
    _requireOwner(expectedAccountId);
    if (response is! Map) {
      throw const FormatException('Prayer RPC returned no receipt');
    }
    final row = Map<String, dynamic>.from(response);
    if (row['owner'] != expectedAccountId ||
        row['operation_id'] != operationId ||
        row['report_id'] != report.reportId) {
      throw const FormatException('Prayer receipt identity mismatch');
    }
    final active = PrayerRemoteModels.report(
      Map<String, dynamic>.from(row['active_report'] as Map),
      expectedAccountId,
    );
    if (active.reportId != report.reportId) {
      throw const FormatException('Prayer active report mismatch');
    }
    final retainedRow = row['retained_report'];
    final conflictId = row['conflict_id'];
    if ((retainedRow == null) != (conflictId == null)) {
      throw const FormatException('Prayer conflict receipt incomplete');
    }
    final conflict = retainedRow == null
        ? null
        : PrayerRemoteConflict(
            id: conflictId as String,
            active: active,
            retained: PrayerRemoteModels.report(
              Map<String, dynamic>.from(retainedRow as Map),
              expectedAccountId,
            ),
            // Server time, identical to what a later inbound pull reads.
            detectedAt: DateTime.parse(row['detected_at'] as String).toUtc(),
          );
    final awardRow = row['canonical_award'];
    final award = awardRow == null
        ? null
        : PrayerRemoteModels.award(
            Map<String, dynamic>.from(awardRow as Map),
            expectedAccountId,
          );
    if (award != null && award.sourceId != report.reportId) {
      throw const FormatException('Prayer award identity mismatch');
    }
    return PrayerDispatchReceipt(
      operationId: operationId,
      active: active,
      conflict: conflict,
      award: award,
    );
  }

  void _requireOwner(String expected) {
    if (currentAccountId != expected) {
      throw StateError('Authenticated account changed during Prayer sync');
    }
  }
}
