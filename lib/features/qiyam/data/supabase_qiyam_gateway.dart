import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/qiyam_night_record.dart';
import 'qiyam_remote_models.dart';

/// The Supabase boundary for one Qiyam night change (contracts/
/// adhkar-qiyam-sync.md): the typed RPC `apply_qiyam_night_change_v1` — the
/// client sends no owner and no record id (the server recomputes it).
abstract interface class SupabaseQiyamGateway {
  String? get currentAccountId;

  Future<QiyamNightRecord?> fetchNight({
    required String expectedAccountId,
    required String recordId,
  });

  Future<QiyamDispatchReceipt> applyChange({
    required String expectedAccountId,
    required QiyamNightRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  });
}

final class SupabaseQiyamGatewayImpl implements SupabaseQiyamGateway {
  SupabaseQiyamGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  @override
  Future<QiyamNightRecord?> fetchNight({
    required String expectedAccountId,
    required String recordId,
  }) async {
    _requireOwner(expectedAccountId);
    final response = await _client
        .from('qiyam_nights')
        .select()
        .eq('owner', expectedAccountId)
        .eq('record_id', recordId)
        .maybeSingle();
    _requireOwner(expectedAccountId);
    return response == null
        ? null
        : QiyamRemoteModels.record(
            Map<String, dynamic>.from(response),
            expectedAccountId,
          );
  }

  @override
  Future<QiyamDispatchReceipt> applyChange({
    required String expectedAccountId,
    required QiyamNightRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    _requireOwner(expectedAccountId);
    if (record.accountId != expectedAccountId) {
      throw const FormatException('Qiyam outbound owner mismatch');
    }
    final response = await _client.rpc<dynamic>(
      'apply_qiyam_night_change_v1',
      params: <String, Object?>{
        'p_night_date': record.nightDate,
        'p_performed': record.performed,
        'p_rakahs': record.rakahs,
        'p_witr': record.witr,
        'p_start_time': record.startTime,
        'p_end_time': record.endTime,
        'p_note': record.note,
        'p_recorded_zone_id': record.recordedZoneId,
        'p_recorded_offset_minutes': record.recordedOffsetMinutes,
        'p_updated_at': record.updatedAt.toUtc().toIso8601String(),
        'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
        'p_operation_id': operationId,
      },
    );
    _requireOwner(expectedAccountId);
    if (response is! Map) {
      throw const FormatException('Qiyam RPC returned no receipt');
    }
    final row = Map<String, dynamic>.from(response);
    if (row['owner'] != expectedAccountId ||
        row['operation_id'] != operationId ||
        row['record_id'] != record.recordId) {
      throw const FormatException('Qiyam receipt identity mismatch');
    }
    final active = QiyamRemoteModels.record(
      Map<String, dynamic>.from(row['active_record'] as Map),
      expectedAccountId,
    );
    if (active.recordId != record.recordId) {
      throw const FormatException('Qiyam active record mismatch');
    }
    final retainedRow = row['retained_record'];
    final conflictId = row['conflict_id'];
    if ((retainedRow == null) != (conflictId == null)) {
      throw const FormatException('Qiyam conflict receipt incomplete');
    }
    final conflict = retainedRow == null
        ? null
        : QiyamRemoteConflict(
            id: conflictId as String,
            active: active,
            retained: QiyamRemoteModels.record(
              Map<String, dynamic>.from(retainedRow as Map),
              expectedAccountId,
            ),
            detectedAt: DateTime.parse(row['detected_at'] as String).toUtc(),
          );
    final awardRow = row['canonical_award'];
    final award = awardRow == null
        ? null
        : QiyamRemoteModels.award(
            Map<String, dynamic>.from(awardRow as Map),
            expectedAccountId,
          );
    if (award != null && award.sourceId != record.recordId) {
      throw const FormatException('Qiyam award identity mismatch');
    }
    return QiyamDispatchReceipt(
      operationId: operationId,
      active: active,
      conflict: conflict,
      award: award,
    );
  }

  void _requireOwner(String expected) {
    if (currentAccountId != expected) {
      throw StateError('Authenticated account changed during Qiyam sync');
    }
  }
}
