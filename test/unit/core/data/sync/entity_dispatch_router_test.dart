import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

void main() {
  late _RecordingCloudSync foundationAdapter;
  late _RecordingCloudSync taskAdapter;
  late EntityDispatchRouter router;

  setUp(() {
    foundationAdapter = _RecordingCloudSync('foundation-ack');
    taskAdapter = _RecordingCloudSync('task-ack');
    router = EntityDispatchRouter(
      foundationAdapter: foundationAdapter,
      taskAdapter: taskAdapter,
    );
  });

  test(
    'foundation_record changes keep using the Foundation probe adapter',
    () async {
      final result = await router.dispatchChange(
        _change(entityType: kFoundationRecordEntityType),
      );

      expect(foundationAdapter.dispatched, hasLength(1));
      expect(taskAdapter.dispatched, isEmpty);
      expect(
        (result.valueOrNull as DispatchAcknowledged).acknowledgementId,
        'foundation-ack',
      );
    },
  );

  test('task changes are dispatched only to the Task adapter', () async {
    final result = await router.dispatchChange(
      _change(entityType: kTaskEntityType),
    );

    expect(foundationAdapter.dispatched, isEmpty);
    expect(taskAdapter.dispatched, hasLength(1));
    expect(
      (result.valueOrNull as DispatchAcknowledged).acknowledgementId,
      'task-ack',
    );
  });

  test('remote version lookup follows the same entity ownership map', () async {
    final result = await router.obtainRemoteVersion(
      entityType: kTaskEntityType,
      entityId: 'task-1',
    );

    expect(taskAdapter.lookups, [('task', 'task-1')]);
    expect(foundationAdapter.lookups, isEmpty);
    expect(result.failureOrNull, isNull);
  });

  test(
    'unknown entity types fail recoverably without acknowledgement',
    () async {
      final result = await router.dispatchChange(
        _change(entityType: 'unknown_entity'),
      );

      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.category, AppFailureCategory.cloud);
      expect(result.failureOrNull!.recoverable, isTrue);
      expect(foundationAdapter.dispatched, isEmpty);
      expect(taskAdapter.dispatched, isEmpty);
    },
  );
}

OutboundChange _change({required String entityType}) => OutboundChange(
  operationId: 'operation-1',
  accountId: 'account-1',
  entityType: entityType,
  entityId: 'entity-1',
  kind: ChangeKind.create,
  payload: '{"title":"Task"}',
  versionTimestamp: DateTime.utc(2026, 10, 8),
);

final class _RecordingCloudSync implements CloudSyncPort {
  _RecordingCloudSync(this.acknowledgementId);

  final String acknowledgementId;
  final List<OutboundChange> dispatched = [];
  final List<(String, String)> lookups = [];

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    dispatched.add(change);
    return AppResult.success(
      DispatchAcknowledged(acknowledgementId: acknowledgementId),
    );
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    lookups.add((entityType, entityId));
    return AppResult.success(null);
  }
}
