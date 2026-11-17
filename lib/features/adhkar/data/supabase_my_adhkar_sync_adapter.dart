import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/my_dhikr.dart';
import 'drift_my_adhkar_repository.dart';
import 'supabase_my_adhkar_gateway.dart';

/// The My Adhkar outbound dispatcher (contracts/adhkar-qiyam-sync.md): maps
/// the outbox operation onto the typed `apply_my_adhkar_group_change_v1` or
/// `apply_my_adhkar_item_change_v1` RPC, then finalizes the receipt locally
/// in one repository transaction before the generic coordinator
/// acknowledges. A failure anywhere leaves the operation pending. The
/// engine's chronological outbox order is kept across both entity types —
/// no reordering (676e881).
final class SupabaseMyAdhkarSyncAdapter implements CloudSyncPort {
  const SupabaseMyAdhkarSyncAdapter({
    required SupabaseMyAdhkarGateway gateway,
    required DriftMyAdhkarRepository repository,
  }) : _gateway = gateway,
       _repository = repository;

  final SupabaseMyAdhkarGateway _gateway;
  final DriftMyAdhkarRepository _repository;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      final payload = jsonDecode(change.payload);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('My Adhkar operation must be an object');
      }
      switch (change.entityType) {
        // `await` inside the try: a returned future's error would escape
        // the catch otherwise.
        case kMyAdhkarGroupEntityType:
          return await _dispatchGroup(change, payload);
        case kMyAdhkarItemEntityType:
          return await _dispatchItem(change, payload);
        default:
          throw const FormatException('Unsupported My Adhkar operation');
      }
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  Future<AppResult<DispatchOutcome>> _dispatchGroup(
    OutboundChange change,
    Map<String, dynamic> payload,
  ) async {
    final updatedAt = _stampedVersion(change, payload);
    final group = MyAdhkarGroup(
      accountId: change.accountId,
      groupId: change.entityId,
      name: payload['name'] as String,
      createdAt: DateTime.parse(payload['created_at'] as String).toUtc(),
      updatedAt: updatedAt,
      lastAcknowledgedUpdatedAt: change.baseUpdatedAt,
      deletedAt: payload['deleted_at'] == null
          ? null
          : DateTime.parse(payload['deleted_at'] as String).toUtc(),
    );
    final receipt = await _gateway.applyGroupChange(
      expectedAccountId: change.accountId,
      group: group,
      operationId: change.operationId,
      baseUpdatedAt: change.baseUpdatedAt,
    );
    if (_gateway.currentAccountId != change.accountId) {
      throw StateError('My Adhkar owner changed before finalization');
    }
    final finalized = await _repository.finalizeGroupReceipt(
      accountId: change.accountId,
      groupId: change.entityId,
      outboundVersion: change.versionTimestamp,
      receipt: receipt,
    );
    if (finalized.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(
      DispatchAcknowledged(
        acknowledgementId: receipt.operationId,
        remoteVersionTimestamp: receipt.activeVersion,
      ),
    );
  }

  Future<AppResult<DispatchOutcome>> _dispatchItem(
    OutboundChange change,
    Map<String, dynamic> payload,
  ) async {
    final updatedAt = _stampedVersion(change, payload);
    final groups = payload['group_ids'];
    final item = MyDhikrItem(
      accountId: change.accountId,
      itemId: change.entityId,
      text: payload['text'] as String,
      source: payload['source'] as String?,
      groupIds: groups is List
          ? List<String>.from(groups.map((g) => g as String))
          : const [],
      createdAt: DateTime.parse(payload['created_at'] as String).toUtc(),
      updatedAt: updatedAt,
      lastAcknowledgedUpdatedAt: change.baseUpdatedAt,
      deletedAt: payload['deleted_at'] == null
          ? null
          : DateTime.parse(payload['deleted_at'] as String).toUtc(),
    );
    final receipt = await _gateway.applyItemChange(
      expectedAccountId: change.accountId,
      item: item,
      operationId: change.operationId,
      baseUpdatedAt: change.baseUpdatedAt,
    );
    if (_gateway.currentAccountId != change.accountId) {
      throw StateError('My Adhkar owner changed before finalization');
    }
    final finalized = await _repository.finalizeItemReceipt(
      accountId: change.accountId,
      itemId: change.entityId,
      outboundVersion: change.versionTimestamp,
      receipt: receipt,
    );
    if (finalized.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(
      DispatchAcknowledged(
        acknowledgementId: receipt.operationId,
        remoteVersionTimestamp: receipt.activeVersion,
      ),
    );
  }

  /// The payload's version must be the operation's own stamp.
  DateTime _stampedVersion(
    OutboundChange change,
    Map<String, dynamic> payload,
  ) {
    final updatedAt = DateTime.parse(payload['updated_at'] as String).toUtc();
    if (updatedAt != change.versionTimestamp) {
      throw const FormatException('My Adhkar outbox version mismatch');
    }
    return updatedAt;
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final owner = _gateway.currentAccountId;
      if (owner == null) throw StateError('My Adhkar owner missing');
      switch (entityType) {
        case kMyAdhkarGroupEntityType:
          final group = await _gateway.fetchGroup(
            expectedAccountId: owner,
            groupId: entityId,
          );
          return AppResult.success(
            group == null
                ? null
                : RemoteVersion(
                    entityType: entityType,
                    entityId: entityId,
                    versionTimestamp: group.updatedAt,
                    payload: jsonEncode(group.payload()),
                  ),
          );
        case kMyAdhkarItemEntityType:
          final item = await _gateway.fetchItem(
            expectedAccountId: owner,
            itemId: entityId,
          );
          return AppResult.success(
            item == null
                ? null
                : RemoteVersion(
                    entityType: entityType,
                    entityId: entityId,
                    versionTimestamp: item.updatedAt,
                    payload: jsonEncode(item.payload()),
                  ),
          );
        default:
          throw const FormatException('Unsupported My Adhkar entity');
      }
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: 'my_adhkar.sync.failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
