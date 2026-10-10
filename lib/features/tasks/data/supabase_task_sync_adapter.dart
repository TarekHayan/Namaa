import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int kDefaultTaskRemotePageSize = 100;

final class TaskRemotePage {
  const TaskRemotePage({required this.rows, this.nextCursor});

  final List<Map<String, dynamic>> rows;
  final String? nextCursor;
}

/// Narrow authenticated Supabase surface shared by Task upload and download.
abstract interface class SupabaseTaskGateway {
  Future<Map<String, dynamic>> applyTaskChange({
    required String expectedAccountId,
    required String id,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  });

  Future<TaskRemotePage> fetchTaskPage({required int pageSize, String? cursor});
}

/// Real gateway. Ownership is never sent: the RPC and RLS derive it from the
/// authenticated Supabase session.
final class SupabaseTaskGatewayImpl implements SupabaseTaskGateway {
  SupabaseTaskGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> applyTaskChange({
    required String expectedAccountId,
    required String id,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    if (_client.auth.currentUser?.id != expectedAccountId) {
      throw StateError('Authenticated account changed before Task upload');
    }
    final result = await _client.rpc<dynamic>(
      'apply_task_change',
      params: <String, Object?>{
        'p_id': id,
        'p_payload': payload,
        'p_operation_id': operationId,
        'p_updated_at': updatedAt.toUtc().toIso8601String(),
        'p_kind': kind,
      },
    );
    if (result is List<dynamic> && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    throw StateError('apply_task_change returned no result');
  }

  @override
  Future<TaskRemotePage> fetchTaskPage({
    required int pageSize,
    String? cursor,
  }) async {
    var query = _client.from('tasks').select();
    if (cursor != null) {
      query = query.gt('id', cursor);
    }
    final response = await query.order('id').limit(pageSize);
    final rows = <Map<String, dynamic>>[
      for (final row in response) Map<String, dynamic>.from(row as Map),
    ];
    return TaskRemotePage(
      rows: rows,
      nextCursor: rows.length == pageSize ? rows.last['id'] as String? : null,
    );
  }
}

/// Task-owned outbound adapter used by the Foundation entity router.
final class SupabaseTaskSyncAdapter implements CloudSyncPort {
  SupabaseTaskSyncAdapter({required SupabaseTaskGateway gateway})
    : _gateway = gateway;

  final SupabaseTaskGateway _gateway;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    if (change.entityType != kTaskEntityType) {
      return AppResult<DispatchOutcome>.failure(
        _cloudFailure('unsupported entity type ${change.entityType}'),
      );
    }
    try {
      final decoded = jsonDecode(change.payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Task payload must be a JSON object');
      }
      final row = await _gateway.applyTaskChange(
        expectedAccountId: change.accountId,
        id: change.entityId,
        payload: decoded,
        operationId: change.operationId,
        kind: change.kind.name,
        updatedAt: change.versionTimestamp.toUtc(),
      );
      if (row['owner'] != change.accountId) {
        throw StateError('Task RPC returned a different account owner');
      }

      if (row['conflict_detected'] == true) {
        final activeAt = _timestamp(row['updated_at']);
        final retainedAt = _timestamp(row['retained_updated_at']);
        final incomingIsActive = activeAt == change.versionTimestamp.toUtc();
        final competingAt = incomingIsActive ? retainedAt : activeAt;
        final competingPayload = incomingIsActive
            ? row['retained_payload']
            : row['payload'];
        if (competingAt != null) {
          return AppResult<DispatchOutcome>.success(
            DispatchVersionConflict(
              remoteVersionTimestamp: competingAt,
              remotePayload: competingPayload == null
                  ? null
                  : jsonEncode(competingPayload),
            ),
          );
        }
      }

      if (row['operation_id'] != change.operationId) {
        throw StateError('Task RPC acknowledgement did not match operation');
      }
      return AppResult<DispatchOutcome>.success(
        DispatchAcknowledged(
          acknowledgementId: change.operationId,
          remoteVersionTimestamp: _timestamp(row['updated_at']),
        ),
      );
    } catch (error) {
      return AppResult<DispatchOutcome>.failure(_cloudFailure(error));
    }
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    if (entityType != kTaskEntityType) {
      return AppResult<RemoteVersion?>.failure(
        _cloudFailure('unsupported entity type $entityType'),
      );
    }
    try {
      String? cursor;
      do {
        final page = await _gateway.fetchTaskPage(
          pageSize: kDefaultTaskRemotePageSize,
          cursor: cursor,
        );
        for (final row in page.rows) {
          if (row['id'] == entityId) {
            final updatedAt = _timestamp(row['updated_at']);
            if (updatedAt == null) {
              throw const FormatException('Remote Task version is missing');
            }
            return AppResult<RemoteVersion?>.success(
              RemoteVersion(
                entityType: entityType,
                entityId: entityId,
                versionTimestamp: updatedAt,
                payload: jsonEncode(row['payload']),
              ),
            );
          }
        }
        cursor = page.nextCursor;
      } while (cursor != null);
      return AppResult<RemoteVersion?>.success(null);
    } catch (error) {
      return AppResult<RemoteVersion?>.failure(_cloudFailure(error));
    }
  }

  static DateTime? _timestamp(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  static AppFailure _cloudFailure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: kCloudSyncRecoverableMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
