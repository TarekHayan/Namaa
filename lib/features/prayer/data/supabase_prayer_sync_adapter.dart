import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'drift_prayer_repository.dart';
import 'prayer_remote_models.dart';
import 'supabase_prayer_gateway.dart';

final class SupabasePrayerSyncAdapter implements CloudSyncPort {
  const SupabasePrayerSyncAdapter({
    required SupabasePrayerGateway gateway,
    required DriftPrayerRepository repository,
  }) : _gateway = gateway,
       _repository = repository;

  final SupabasePrayerGateway _gateway;
  final DriftPrayerRepository _repository;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      if (change.entityType != kPrayerReportEntityType ||
          (change.kind != ChangeKind.create &&
              change.kind != ChangeKind.update)) {
        throw const FormatException('Unsupported Prayer operation');
      }
      final payload = jsonDecode(change.payload);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Prayer operation must be an object');
      }
      final date = PrayerLocalDate.parse(payload['localDate'] as String);
      final name = PrayerNameWire.parse(payload['prayerName'] as String);
      final DateTime createdAt;
      if (payload['createdAt'] case final String value) {
        createdAt = DateTime.parse(value).toUtc();
      } else {
        // Old queued operations created before this payload field was added.
        final legacy = await _repository.createdAtFor(
          accountId: change.accountId,
          date: date,
          prayerName: name,
          reportId: change.entityId,
        );
        if (legacy.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        createdAt = legacy.valueOrNull!;
      }
      final report = PrayerReport(
        accountId: change.accountId,
        reportId: change.entityId,
        date: date,
        name: name,
        status: PrayerStatusWire.parse(payload['status'] as String),
        reportedCompletionAt: payload['reportedCompletionAt'] == null
            ? null
            : DateTime.parse(payload['reportedCompletionAt'] as String).toUtc(),
        recordedZoneId: payload['recordedZoneId'] as String,
        recordedOffsetMinutes: payload['recordedOffsetMinutes'] as int,
        createdAt: createdAt,
        updatedAt: DateTime.parse(payload['updatedAt'] as String).toUtc(),
      );
      final encoded =
          jsonDecode(PrayerRemoteModels.payload(report))
              as Map<String, dynamic>;
      if (!payload.containsKey('createdAt')) encoded.remove('createdAt');
      if (report.updatedAt != change.versionTimestamp ||
          jsonEncode(encoded) != change.payload) {
        throw const FormatException('Prayer outbox version mismatch');
      }
      final receipt = await _gateway.applyChange(
        expectedAccountId: change.accountId,
        report: report,
        operationId: change.operationId,
        baseUpdatedAt: change.baseUpdatedAt,
      );
      if (_gateway.currentAccountId != change.accountId) {
        throw StateError('Prayer owner changed before finalization');
      }
      final finalized = await _repository.finalizeReceipt(
        accountId: change.accountId,
        reportId: change.entityId,
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
      if (entityType != kPrayerReportEntityType) {
        throw const FormatException('Unsupported Prayer entity');
      }
      final owner = _gateway.currentAccountId;
      if (owner == null) throw StateError('Prayer owner missing');
      final report = await _gateway.fetchReport(
        expectedAccountId: owner,
        reportId: entityId,
      );
      return AppResult.success(
        report == null
            ? null
            : RemoteVersion(
                entityType: entityType,
                entityId: entityId,
                versionTimestamp: report.updatedAt,
                payload: PrayerRemoteModels.payload(report),
              ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: 'prayer.sync.failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
