import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/adhkar_repository.dart';
import 'adhkar_remote_models.dart';
import 'drift_adhkar_repository.dart';
import 'supabase_adhkar_gateway.dart';

/// The Adhkar outbound dispatcher (contracts/adhkar-qiyam-sync.md): maps the
/// outbox operation onto the typed `apply_adhkar_item_change_v1` RPC, then
/// finalizes the receipt locally in one repository transaction before the
/// generic coordinator acknowledges. A failure anywhere leaves the
/// operation pending.
final class SupabaseAdhkarSyncAdapter implements CloudSyncPort {
  const SupabaseAdhkarSyncAdapter({
    required SupabaseAdhkarGateway gateway,
    required DriftAdhkarRepository repository,
  }) : _gateway = gateway,
       _repository = repository;

  final SupabaseAdhkarGateway _gateway;
  final DriftAdhkarRepository _repository;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      if (change.entityType != kAdhkarItemEntityType ||
          (change.kind != ChangeKind.create &&
              change.kind != ChangeKind.update)) {
        throw const FormatException('Unsupported Adhkar operation');
      }
      final payload = jsonDecode(change.payload);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Adhkar operation must be an object');
      }
      final updatedAt = DateTime.parse(payload['updated_at'] as String).toUtc();
      if (updatedAt != change.versionTimestamp) {
        throw const FormatException('Adhkar outbox version mismatch');
      }
      final record = AdhkarCountRecord(
        accountId: change.accountId,
        adhkarDay: payload['adhkar_day'] as String,
        itemId: payload['item_id'] as String,
        recordId: change.entityId,
        catalogVersion: payload['catalog_version'] as int,
        list:
            payload['list'] as String? ?? _listOf(payload['item_id'] as String),
        count: payload['count'] as int,
        createdAt: updatedAt,
        updatedAt: updatedAt,
        lastAcknowledgedUpdatedAt: change.baseUpdatedAt,
      );
      if (record.updatedAt != change.versionTimestamp) {
        throw const FormatException('Adhkar outbox version mismatch');
      }
      final receipt = await _gateway.applyChange(
        expectedAccountId: change.accountId,
        record: record,
        operationId: change.operationId,
        baseUpdatedAt: change.baseUpdatedAt,
      );
      if (_gateway.currentAccountId != change.accountId) {
        throw StateError('Adhkar owner changed before finalization');
      }
      final finalized = await _repository.finalizeReceipt(
        accountId: change.accountId,
        adhkarDay: record.adhkarDay,
        itemId: record.itemId,
        outboundVersion: change.versionTimestamp,
        receipt: receipt,
      );
      if (finalized.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      // The generic coordinator performs the only outbox acknowledgement.
      return AppResult.success(
        DispatchAcknowledged(
          acknowledgementId: receipt.operationId,
          remoteVersionTimestamp: receipt.active.updatedAt,
        ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      if (entityType != kAdhkarItemEntityType) {
        throw const FormatException('Unsupported Adhkar entity');
      }
      final owner = _gateway.currentAccountId;
      if (owner == null) throw StateError('Adhkar owner missing');
      final record = await _gateway.fetchCount(
        expectedAccountId: owner,
        recordId: entityId,
      );
      return AppResult.success(
        record == null
            ? null
            : RemoteVersion(
                entityType: entityType,
                entityId: entityId,
                versionTimestamp: record.updatedAt,
                payload: AdhkarRemoteModels.payload(record),
              ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  /// The list is derived from the catalog server-side; the payload carries
  /// no list. The local row already knows it, but the wire record needs one
  /// only to satisfy the domain field rules, and the item's stable prefix
  /// is what the reviewed catalog uses (m*/e*).
  static String _listOf(String itemId) =>
      itemId.startsWith('m') ? 'morning' : 'evening';

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: 'adhkar.sync.failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
