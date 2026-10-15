import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 8, 9);
  const codec = TaskPayloadCodec();
  late _MemoryTaskRepository repository;
  late _ConflictStore localStore;
  late TaskReconciler reconciler;

  setUp(() {
    repository = _MemoryTaskRepository();
    localStore = _ConflictStore();
    reconciler = TaskReconciler(
      repository: repository,
      localStore: localStore,
      codec: codec,
      detectedAt: () => baseTime.add(const Duration(hours: 1)),
    );
  });

  test('initial inbound pull imports a missing account Task', () async {
    final remote = _task(title: 'Remote first copy', updatedAt: baseTime);

    final result = await reconciler.reconcile(
      accountId: kTasksTestAccountA,
      remoteTasks: <Task>[remote],
    );

    expect(result.valueOrNull?.imported, 1);
    expect(repository.current?.title, 'Remote first copy');
    expect(localStore.conflicts, isEmpty);
  });

  test(
    'pending local change is never silently discarded by inbound state',
    () async {
      final local = _task(title: 'Pending local', updatedAt: baseTime);
      final remote = _task(
        title: 'Newer remote',
        updatedAt: baseTime.add(const Duration(minutes: 2)),
      );
      repository
        ..current = local
        ..pending = true;

      final result = await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );

      expect(result.valueOrNull?.conflictsRecorded, 1);
      expect(repository.current?.title, 'Newer remote');
      expect(
        localStore.conflicts.single.activeVersion.source,
        VersionSource.remote,
      );
      expect(
        localStore.conflicts.single.retainedVersion.source,
        VersionSource.local,
      );
      expect(
        localStore.conflicts.single.retainedVersion.payload,
        contains('Pending local'),
      );
    },
  );

  test(
    'newest UTC Task becomes active and older remote remains visible',
    () async {
      final local = _task(
        title: 'Newer local',
        updatedAt: baseTime.add(const Duration(minutes: 5)),
      );
      final remote = _task(title: 'Older remote', updatedAt: baseTime);
      repository.current = local;

      final result = await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );

      expect(result.valueOrNull?.conflictsRecorded, 1);
      expect(repository.current?.title, 'Newer local');
      expect(
        localStore.conflicts.single.activeVersion.source,
        VersionSource.local,
      );
      expect(
        localStore.conflicts.single.retainedVersion.source,
        VersionSource.remote,
      );
      expect(
        localStore.conflicts.single.retainedVersion.payload,
        contains('Older remote'),
      );
    },
  );

  test(
    'newest UTC remote becomes active and older local remains visible',
    () async {
      final local = _task(title: 'Older local', updatedAt: baseTime);
      final remote = _task(
        title: 'Newer remote',
        updatedAt: baseTime.add(const Duration(minutes: 5)),
      );
      repository.current = local;

      await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );

      expect(repository.current?.title, 'Newer remote');
      expect(
        localStore.conflicts.single.activeVersion.source,
        VersionSource.remote,
      );
      expect(
        localStore.conflicts.single.retainedVersion.source,
        VersionSource.local,
      );
    },
  );

  test(
    'equal timestamps retain both versions without selecting a winner',
    () async {
      final local = _task(title: 'Local equal', updatedAt: baseTime);
      final remote = _task(title: 'Remote equal', updatedAt: baseTime);
      repository.current = local;

      final result = await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );

      expect(result.valueOrNull?.equalTimestampConflicts, 1);
      expect(repository.current?.title, 'Local equal');
      expect(localStore.conflicts, hasLength(1));
      expect(
        localStore.conflicts.single.activeVersion.payload,
        contains('Local equal'),
      );
      expect(
        localStore.conflicts.single.retainedVersion.payload,
        contains('Remote equal'),
      );
    },
  );

  test(
    'newer delete competes with edit and retains the edited loser',
    () async {
      final localEdit = _task(title: 'Unsynced edit', updatedAt: baseTime);
      final remoteDelete = _task(
        title: 'Prior remote value',
        updatedAt: baseTime.add(const Duration(minutes: 2)),
      ).markDeleted(baseTime.add(const Duration(minutes: 2)));
      repository.current = localEdit;

      await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remoteDelete],
      );

      expect(repository.current?.isDeleted, isTrue);
      expect(
        localStore.conflicts.single.activeVersion.source,
        VersionSource.remote,
      );
      expect(
        localStore.conflicts.single.retainedVersion.payload,
        contains('Unsynced edit'),
      );
    },
  );

  test('different-account inbound Task fails without local mutation', () async {
    final foreign = _task(
      accountId: kTasksTestAccountB,
      title: 'Foreign Task',
      updatedAt: baseTime,
    );

    final result = await reconciler.reconcile(
      accountId: kTasksTestAccountA,
      remoteTasks: <Task>[foreign],
    );

    expect(result.failureOrNull, isNotNull);
    expect(repository.current, isNull);
    expect(localStore.conflicts, isEmpty);
  });
}

Task _task({
  String accountId = kTasksTestAccountA,
  String title = 'Task',
  required DateTime updatedAt,
}) => Task.create(
  id: kTasksTestTaskId,
  accountId: accountId,
  title: title,
  scheduledDate: DateTime(2026, 10, 8),
  createdAt: updatedAt,
);

final class _MemoryTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream<List<TaskConflictRecord>>.value(const []);
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  Task? current;
  bool pending = false;

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    current = task;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    current = request.task;
    pending = true;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(pending);

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async => AppResult<Task?>.success(
    current?.accountId == accountId && current?.id == taskId ? current : null,
  );

  @override
  Stream<List<Task>> watchTasks(String accountId) => Stream<List<Task>>.value(
    current?.accountId == accountId ? <Task>[current!] : const <Task>[],
  );
}

final class _ConflictStore implements LocalStorePort {
  final List<ConflictRecordInput> conflicts = <ConflictRecordInput>[];

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async {
    conflicts.add(conflict);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) => recordConflict(conflict);

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> markChangeConflicted(String operationId) async =>
      AppResult<void>.success(null);

  @override
  Future<AppResult<void>> recordRecoverableFailure(
    String operationId,
    String summary,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async => AppResult<List<PendingChangeRecord>>.success(
    const <PendingChangeRecord>[],
  );

  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.success(null);

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async => AppResult<MigrationOutcome>.success(
    MigrationOutcome(completedVersion: targetSchemaVersion, recovered: false),
  );

  @override
  Future<AppResult<void>> savePreference(String key, String value) async =>
      AppResult<void>.success(null);
}
