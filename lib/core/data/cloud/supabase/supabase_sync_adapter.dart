/// Supabase Postgres/Data API sync adapter behind the Cloud Sync port.
///
/// Supabase SDK types never cross the port. Idempotency: the remote row
/// carries `operation_id`; a repeated dispatch of the same operation ID
/// returns the acknowledgement without a second mutation
/// (contracts/synchronization.md).
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Message key for cloud sync failures (Arabic and English resources exist).
const String kCloudSyncRecoverableMessageKey = 'foundation.cloud.recoverable';

/// The remote probe table owned by migration 0001_foundation_probe.sql.
const String kFoundationProbeTable = 'foundation_probe';

/// The narrow Supabase surface the sync adapter needs.
abstract interface class SupabaseProbeGateway {
  Future<Map<String, dynamic>?> fetchRow(String entityId);

  Future<Map<String, dynamic>?> applyChange({
    required String entityId,
    required String payload,
    required String operationId,
    required String kind,
    required DateTime versionTimestamp,
  });
}

/// Gateway over a real [SupabaseClient].
class SupabaseProbeGatewayImpl implements SupabaseProbeGateway {
  SupabaseProbeGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchRow(String entityId) async {
    final row = await _client
        .from(kFoundationProbeTable)
        .select()
        .eq('id', entityId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<Map<String, dynamic>?> applyChange({
    required String entityId,
    required String payload,
    required String operationId,
    required String kind,
    required DateTime versionTimestamp,
  }) async {
    final result = await _client.rpc<dynamic>(
      'apply_foundation_change',
      params: {
        'p_id': entityId,
        'p_payload': payload,
        'p_operation_id': operationId,
        'p_updated_at': versionTimestamp.toIso8601String(),
        'p_kind': kind,
      },
    );
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return null;
  }
}

/// Cloud Sync implementation over the Supabase Postgres/Data API.
class SupabaseSyncAdapter implements CloudSyncPort {
  SupabaseSyncAdapter({required SupabaseProbeGateway gateway})
    : _gateway = gateway;

  final SupabaseProbeGateway _gateway;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      final remote = await _gateway.applyChange(
        entityId: change.entityId,
        payload: change.payload,
        operationId: change.operationId,
        kind: change.kind.name,
        versionTimestamp: change.versionTimestamp,
      );

      // When this operation superseded an older remote version, the RPC
      // returns that retained candidate as well as the active row. Record the
      // conflict even though the local version already won remotely.
      if (remote?['conflict_detected'] == true &&
          remote?['operation_id'] == change.operationId) {
        final retainedTimestamp = _timestampFrom(remote, 'retained_updated_at');
        if (retainedTimestamp != null) {
          return AppResult<DispatchOutcome>.success(
            DispatchVersionConflict(
              remoteVersionTimestamp: retainedTimestamp,
              remotePayload: remote?['retained_payload'] as String?,
            ),
          );
        }
      }

      // Idempotent replay: the same operation ID is one logical effect.
      if (remote != null && remote['operation_id'] == change.operationId) {
        return AppResult<DispatchOutcome>.success(
          DispatchAcknowledged(
            acknowledgementId: change.operationId,
            remoteVersionTimestamp: _timestampFrom(remote),
          ),
        );
      }

      // If a remote row exists with a different operation_id, it is a conflict.
      if (remote != null) {
        final remoteTimestamp = _timestampFrom(remote);
        if (remoteTimestamp != null) {
          // If timestamps differ, return DispatchVersionConflict so the coordinator
          // selects the newest timestamp and preserves the losing version.
          // If timestamps are equal, return DispatchVersionConflict so the coordinator
          // enters the unresolved equal-timestamp conflict path without overwriting either version.
          return AppResult<DispatchOutcome>.success(
            DispatchVersionConflict(
              remoteVersionTimestamp: remoteTimestamp,
              remotePayload: remote['payload'] as String?,
            ),
          );
        }
      }

      // No remote conflict and the RPC has atomically executed create, update, or delete.
      return AppResult<DispatchOutcome>.success(
        DispatchAcknowledged(acknowledgementId: change.operationId),
      );
    } catch (_) {
      return AppResult<DispatchOutcome>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: kCloudSyncRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final remote = await _gateway.fetchRow(entityId);
      final timestamp = _timestampFrom(remote);
      if (remote == null || timestamp == null) {
        return AppResult<RemoteVersion?>.success(null);
      }
      return AppResult<RemoteVersion?>.success(
        RemoteVersion(
          entityType: entityType,
          entityId: entityId,
          versionTimestamp: timestamp,
          payload: remote['payload'] as String?,
        ),
      );
    } catch (_) {
      return AppResult<RemoteVersion?>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: kCloudSyncRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  DateTime? _timestampFrom(
    Map<String, dynamic>? row, [
    String field = 'updated_at',
  ]) {
    final raw = row?[field];
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
