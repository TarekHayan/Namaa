import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/adhkar_repository.dart';
import 'adhkar_remote_models.dart';

/// The Supabase boundary for one Adhkar count change (contracts/
/// adhkar-qiyam-sync.md): the typed RPC `apply_adhkar_item_change_v1` — the
/// client sends no owner, no record id (the server recomputes it), no list
/// and no XP amount.
abstract interface class SupabaseAdhkarGateway {
  String? get currentAccountId;

  Future<AdhkarCountRecord?> fetchCount({
    required String expectedAccountId,
    required String recordId,
  });

  Future<AdhkarDispatchReceipt> applyChange({
    required String expectedAccountId,
    required AdhkarCountRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  });
}

final class SupabaseAdhkarGatewayImpl implements SupabaseAdhkarGateway {
  SupabaseAdhkarGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  @override
  Future<AdhkarCountRecord?> fetchCount({
    required String expectedAccountId,
    required String recordId,
  }) async {
    _requireOwner(expectedAccountId);
    final response = await _client
        .from('adhkar_item_counts')
        .select()
        .eq('owner', expectedAccountId)
        .eq('record_id', recordId)
        .maybeSingle();
    _requireOwner(expectedAccountId);
    return response == null
        ? null
        : AdhkarRemoteModels.record(
            Map<String, dynamic>.from(response),
            expectedAccountId,
          );
  }

  @override
  Future<AdhkarDispatchReceipt> applyChange({
    required String expectedAccountId,
    required AdhkarCountRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    _requireOwner(expectedAccountId);
    if (record.accountId != expectedAccountId) {
      throw const FormatException('Adhkar outbound owner mismatch');
    }
    final response = await _client.rpc<dynamic>(
      'apply_adhkar_item_change_v1',
      params: <String, Object?>{
        'p_adhkar_day': record.adhkarDay,
        'p_item_id': record.itemId,
        'p_catalog_version': record.catalogVersion,
        'p_count': record.count,
        'p_updated_at': record.updatedAt.toUtc().toIso8601String(),
        'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
        'p_operation_id': operationId,
      },
    );
    _requireOwner(expectedAccountId);
    if (response is! Map) {
      throw const FormatException('Adhkar RPC returned no receipt');
    }
    final row = Map<String, dynamic>.from(response);
    if (row['owner'] != expectedAccountId ||
        row['operation_id'] != operationId ||
        row['record_id'] != record.recordId) {
      throw const FormatException('Adhkar receipt identity mismatch');
    }
    final active = AdhkarRemoteModels.record(
      Map<String, dynamic>.from(row['active_record'] as Map),
      expectedAccountId,
    );
    if (active.recordId != record.recordId) {
      throw const FormatException('Adhkar active record mismatch');
    }
    final retainedRow = row['retained_record'];
    final conflictId = row['conflict_id'];
    if ((retainedRow == null) != (conflictId == null)) {
      throw const FormatException('Adhkar conflict receipt incomplete');
    }
    final conflict = retainedRow == null
        ? null
        : AdhkarRemoteConflict(
            id: conflictId as String,
            active: active,
            retained: AdhkarRemoteModels.record(
              Map<String, dynamic>.from(retainedRow as Map),
              expectedAccountId,
            ),
            detectedAt: DateTime.parse(row['detected_at'] as String).toUtc(),
          );
    final awardRow = row['canonical_award'];
    final award = awardRow == null
        ? null
        : AdhkarRemoteModels.award(
            Map<String, dynamic>.from(awardRow as Map),
            expectedAccountId,
          );
    return AdhkarDispatchReceipt(
      operationId: operationId,
      active: active,
      conflict: conflict,
      award: award,
    );
  }

  void _requireOwner(String expected) {
    if (currentAccountId != expected) {
      throw StateError('Authenticated account changed during Adhkar sync');
    }
  }
}
