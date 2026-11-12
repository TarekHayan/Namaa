import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/qiyam_night_record.dart';
import 'drift_qiyam_repository.dart';
import 'qiyam_remote_models.dart';
import 'supabase_qiyam_gateway.dart';

/// The Qiyam outbound dispatcher (contracts/adhkar-qiyam-sync.md): maps the
/// outbox operation onto the typed `apply_qiyam_night_change_v1` RPC, then
/// finalizes the receipt locally in one repository transaction before the
/// generic coordinator acknowledges.
final class SupabaseQiyamSyncAdapter implements CloudSyncPort {
  const SupabaseQiyamSyncAdapter({
    required SupabaseQiyamGateway gateway,
    required DriftQiyamRepository repository,
  }) : _gateway = gateway,
       _repository = repository;

  final SupabaseQiyamGateway _gateway;
  final DriftQiyamRepository _repository;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      if (change.entityType != kQiyamNightEntityType ||
          (change.kind != ChangeKind.create &&
              change.kind != ChangeKind.update)) {
        throw const FormatException('Unsupported Qiyam operation');
      }
      final payload = jsonDecode(change.payload);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Qiyam operation must be an object');
      }
      final updatedAt = DateTime.parse(payload['updated_at'] as String).toUtc();
      if (updatedAt != change.versionTimestamp) {
        throw const FormatException('Qiyam outbox version mismatch');
      }
      final performed = payload['performed'] as bool;
      final record = QiyamNightRecord(
        accountId: change.accountId,
        nightDate: payload['night_date'] as String,
        recordId: change.entityId,
        performed: performed,
        rakahs: payload['rakahs'] as int?,
        witr: payload['witr'] as bool,
        startTime: payload['start_time'] as String?,
        endTime: payload['end_time'] as String?,
        note: payload['note'] as String?,
        recordedZoneId: payload['recorded_zone_id'] as String,
        recordedOffsetMinutes: payload['recorded_offset_minutes'] as int,
        createdAt: updatedAt,
        updatedAt: updatedAt,
        lastAcknowledgedUpdatedAt: change.baseUpdatedAt,
      );
      final receipt = await _gateway.applyChange(
        expectedAccountId: change.accountId,
        record: record,
        operationId: change.operationId,
        baseUpdatedAt: change.baseUpdatedAt,
      );
      if (_gateway.currentAccountId != change.accountId) {
        throw StateError('Qiyam owner changed before finalization');
      }
      final finalized = await _repository.finalizeReceipt(
        accountId: change.accountId,
        nightDate: record.nightDate,
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
      if (entityType != kQiyamNightEntityType) {
        throw const FormatException('Unsupported Qiyam entity');
      }
      final owner = _gateway.currentAccountId;
      if (owner == null) throw StateError('Qiyam owner missing');
      final record = await _gateway.fetchNight(
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
                payload: QiyamRemoteModels.payload(record),
              ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: 'qiyam.sync.failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
