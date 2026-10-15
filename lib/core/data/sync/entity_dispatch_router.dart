/// Entity-owned synchronization dispatch without turning the Foundation probe
/// adapter into a generic product-domain transport.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

const String kFoundationRecordEntityType = 'foundation_record';
const String kTaskEntityType = 'task';
const String _unsupportedEntityMessageKey = 'foundation.cloud.recoverable';

/// Routes each durable outbox entity to the adapter that owns its remote
/// representation.
///
/// Unknown entity types fail recoverably. They are never acknowledged, so a
/// future registered adapter can safely retry the same durable operation.
final class EntityDispatchRouter implements CloudSyncPort {
  EntityDispatchRouter({
    required CloudSyncPort foundationAdapter,
    required CloudSyncPort taskAdapter,
  }) : _adapters = {
         kFoundationRecordEntityType: foundationAdapter,
         kTaskEntityType: taskAdapter,
       };

  final Map<String, CloudSyncPort> _adapters;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    final adapter = _adapters[change.entityType];
    if (adapter == null) {
      return AppResult.failure(_unsupportedEntityFailure());
    }
    return adapter.dispatchChange(change);
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    final adapter = _adapters[entityType];
    if (adapter == null) {
      return AppResult.failure(_unsupportedEntityFailure());
    }
    return adapter.obtainRemoteVersion(
      entityType: entityType,
      entityId: entityId,
    );
  }

  AppFailure _unsupportedEntityFailure() => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: _unsupportedEntityMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: 'no synchronization adapter registered for entity type',
  );
}
