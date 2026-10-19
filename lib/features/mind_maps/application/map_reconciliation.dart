import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';

final class MapReconciliationSummary {
  const MapReconciliationSummary({
    required this.imported,
    required this.conflictsRecorded,
    required this.equalTimestampConflicts,
  });
  final int imported;
  final int conflictsRecorded;
  final int equalTimestampConflicts;
}

abstract interface class MapReconciliationPort {
  Future<AppResult<MapReconciliationSummary>> reconcile({
    required String ownerId,
    required MapRemoteSnapshot remote,
  });
}

/// Raw tombstones must be readable even when the visible graph hides them.
abstract interface class MapReconciliationStorePort {
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  });
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
  Future<AppResult<String?>> readPayload({
    required String ownerId,
    required String entityType,
    required String entityId,
  });
  Future<AppResult<void>> applyInbound({
    required String entityType,
    required String payload,
  });
  Future<AppResult<bool>> hasPendingChange({
    required String ownerId,
    required String entityType,
    required String entityId,
  });
}

final class MapConflictView {
  const MapConflictView({
    required this.id,
    required this.mapId,
    required this.entityType,
    required this.entityId,
    required this.activeLabel,
    required this.retainedLabel,
    required this.unresolved,
  });
  final String id;
  final String mapId;
  final String entityType;
  final String entityId;
  final String activeLabel;
  final String retainedLabel;
  final bool unresolved;
}

abstract interface class MapConflictReaderPort {
  Stream<List<MapConflictView>> watchConflicts(String ownerId, String mapId);
}
