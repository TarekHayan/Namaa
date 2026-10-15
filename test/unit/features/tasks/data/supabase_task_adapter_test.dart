import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/tasks/data/supabase_task_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8, 9);
  const codec = TaskPayloadCodec();

  OutboundChange change({
    String operationId = kTasksTestOperationId,
    ChangeKind kind = ChangeKind.update,
    String? payload,
    DateTime? versionTimestamp,
  }) => OutboundChange(
    operationId: operationId,
    accountId: kTasksTestAccountA,
    entityType: 'task',
    entityId: kTasksTestTaskId,
    kind: kind,
    payload: payload ?? codec.encode(_task(updatedAt: versionTimestamp ?? now)),
    versionTimestamp: versionTimestamp ?? now,
  );

  group('Task outbound RPC adapter', () {
    test('real gateway rejects a stale account before making an RPC', () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
      );
      addTearDown(client.dispose);
      final gateway = SupabaseTaskGatewayImpl(client);

      await expectLater(
        gateway.applyTaskChange(
          expectedAccountId: kTasksTestAccountA,
          id: kTasksTestTaskId,
          payload: <String, dynamic>{'title': 'Not uploaded'},
          operationId: kTasksTestOperationId,
          kind: 'update',
          updatedAt: now,
        ),
        throwsStateError,
      );
    });

    test(
      'maps operation, kind, payload and UTC timestamp without owner input',
      () async {
        final gateway = _FakeTaskGateway()
          ..applyResponse = _acknowledgedRow(now: now);
        final adapter = SupabaseTaskSyncAdapter(gateway: gateway);

        final result = await adapter.dispatchChange(
          change(kind: ChangeKind.delete),
        );

        expect(result.valueOrNull, isA<DispatchAcknowledged>());
        expect(gateway.applied, hasLength(1));
        expect(gateway.applied.single.expectedAccountId, kTasksTestAccountA);
        expect(gateway.applied.single.id, kTasksTestTaskId);
        expect(gateway.applied.single.operationId, kTasksTestOperationId);
        expect(gateway.applied.single.kind, 'delete');
        expect(gateway.applied.single.updatedAt, now);
        expect(gateway.applied.single.updatedAt.isUtc, isTrue);
        expect(gateway.applied.single.payload, isA<Map<String, dynamic>>());
        expect(
          gateway.applied.single.sentOwnerField,
          isFalse,
          reason: 'apply_task_change derives ownership from auth.uid()',
        );
      },
    );

    test(
      'maps a durable acknowledgement and replay to one acknowledgement',
      () async {
        final gateway = _FakeTaskGateway()
          ..applyResponse = _acknowledgedRow(now: now, replayed: true);
        final adapter = SupabaseTaskSyncAdapter(gateway: gateway);

        final result = await adapter.dispatchChange(change());

        expect(
          result.valueOrNull,
          isA<DispatchAcknowledged>()
              .having(
                (outcome) => outcome.acknowledgementId,
                'acknowledgementId',
                kTasksTestOperationId,
              )
              .having(
                (outcome) => outcome.remoteVersionTimestamp,
                'remoteVersionTimestamp',
                now,
              ),
        );
      },
    );

    test(
      'sends completion and reopening as stable Task operations only',
      () async {
        final gateway = _FakeTaskGateway();
        final adapter = SupabaseTaskSyncAdapter(gateway: gateway);
        final completedAt = now.add(const Duration(minutes: 1));
        final reopenedAt = now.add(const Duration(minutes: 2));
        final completed = _task(updatedAt: now).complete(completedAt);
        final reopened = completed.reopen(reopenedAt);

        gateway.applyResponse = _acknowledgedRow(
          now: completedAt,
          operationId: 'complete-operation',
        );
        final completion = await adapter.dispatchChange(
          change(
            operationId: 'complete-operation',
            payload: codec.encode(completed),
            versionTimestamp: completedAt,
          ),
        );
        gateway.applyResponse = _acknowledgedRow(
          now: reopenedAt,
          operationId: 'reopen-operation',
        );
        final reopening = await adapter.dispatchChange(
          change(
            operationId: 'reopen-operation',
            payload: codec.encode(reopened),
            versionTimestamp: reopenedAt,
          ),
        );

        expect(completion.valueOrNull, isA<DispatchAcknowledged>());
        expect(reopening.valueOrNull, isA<DispatchAcknowledged>());
        expect(gateway.applied, hasLength(2));
        expect(gateway.applied.first.operationId, 'complete-operation');
        expect(
          gateway.applied.first.payload['completedAt'],
          completedAt.toIso8601String(),
        );
        expect(gateway.applied.first.payload['completionXp'], 20);
        expect(gateway.applied.last.operationId, 'reopen-operation');
        expect(gateway.applied.last.payload['completedAt'], isNull);
        expect(gateway.applied.last.payload['completionXp'], 20);
      },
    );

    test('maps retained remote evidence to a version conflict', () async {
      final retainedAt = now.subtract(const Duration(minutes: 5));
      final gateway = _FakeTaskGateway()
        ..applyResponse = <String, dynamic>{
          ..._acknowledgedRow(now: now),
          'conflict_detected': true,
          'retained_payload': <String, dynamic>{'title': 'Remote loser'},
          'retained_updated_at': retainedAt.toIso8601String(),
          'retained_deleted_at': null,
        };
      final adapter = SupabaseTaskSyncAdapter(gateway: gateway);

      final result = await adapter.dispatchChange(change());

      expect(
        result.valueOrNull,
        isA<DispatchVersionConflict>()
            .having(
              (outcome) => outcome.remoteVersionTimestamp,
              'remoteVersionTimestamp',
              retainedAt,
            )
            .having(
              (outcome) => outcome.remotePayload,
              'remotePayload',
              contains('Remote loser'),
            ),
      );
    });

    test(
      'rejects non-Task entity dispatch without calling the gateway',
      () async {
        final gateway = _FakeTaskGateway();
        final adapter = SupabaseTaskSyncAdapter(gateway: gateway);
        final wrongEntity = OutboundChange(
          operationId: 'wrong-type-op',
          accountId: kTasksTestAccountA,
          entityType: 'foundation_record',
          entityId: kTasksTestTaskId,
          kind: ChangeKind.update,
          payload: '{}',
          versionTimestamp: now,
        );

        final result = await adapter.dispatchChange(wrongEntity);

        expect(result.failureOrNull, isNotNull);
        expect(gateway.applied, isEmpty);
      },
    );
  });

  group('account-scoped paginated Task reader', () {
    test(
      'fetches every page, including tombstones, before completing',
      () async {
        final active = _task();
        final deletedAt = now.add(const Duration(minutes: 1));
        final tombstone = _task(
          id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          updatedAt: deletedAt,
        ).markDeleted(deletedAt);
        final gateway = _FakeTaskGateway()
          ..pages['<first>'] = TaskRemotePage(
            rows: <Map<String, dynamic>>[_remoteRow(active)],
            nextCursor: 'page-2',
          )
          ..pages['page-2'] = TaskRemotePage(
            rows: <Map<String, dynamic>>[_remoteRow(tombstone)],
          );
        final reader = SupabaseTaskReader(gateway: gateway, codec: codec);

        final result = await reader.readAllTasks(kTasksTestAccountA);

        expect(gateway.requestedCursors, <String?>[null, 'page-2']);
        expect(result.valueOrNull, hasLength(2));
        expect(
          result.valueOrNull!
              .singleWhere((task) => task.id == tombstone.id)
              .isDeleted,
          isTrue,
        );
      },
    );

    test(
      'fails safely if a remote page contains another account owner',
      () async {
        final gateway = _FakeTaskGateway()
          ..pages['<first>'] = TaskRemotePage(
            rows: <Map<String, dynamic>>[
              _remoteRow(_task(), owner: kTasksTestAccountB),
            ],
          );
        final reader = SupabaseTaskReader(gateway: gateway, codec: codec);

        final result = await reader.readAllTasks(kTasksTestAccountA);

        expect(result.failureOrNull, isNotNull);
        expect(result.valueOrNull, isNull);
      },
    );
  });

  group('account-scoped paginated Task award reader', () {
    test(
      'fetches every award page and deduplicates by immutable key',
      () async {
        final first = _remoteAwardRow();
        final second = _remoteAwardRow(
          sourceId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          amount: 35,
        );
        final gateway = _FakeTaskGateway()
          ..awardPages['<first>'] = TaskAwardRemotePage(
            rows: <Map<String, dynamic>>[first],
            nextCursor: 'page-2',
          )
          ..awardPages['page-2'] = TaskAwardRemotePage(
            rows: <Map<String, dynamic>>[first, second],
          );
        final reader = SupabaseTaskReader(gateway: gateway, codec: codec);

        final result = await reader.readAllTaskAwards(kTasksTestAccountA);

        expect(gateway.requestedAwardCursors, <String?>[null, 'page-2']);
        expect(result.failureOrNull, isNull);
        expect(result.valueOrNull, hasLength(2));
        expect(
          result.valueOrNull!.map((award) => award.amount),
          containsAll(<int>[20, 35]),
        );
      },
    );

    test('fails safely if an award belongs to another account', () async {
      final gateway = _FakeTaskGateway()
        ..awardPages['<first>'] = TaskAwardRemotePage(
          rows: <Map<String, dynamic>>[
            _remoteAwardRow(owner: kTasksTestAccountB),
          ],
        );
      final reader = SupabaseTaskReader(gateway: gateway, codec: codec);

      final result = await reader.readAllTaskAwards(kTasksTestAccountA);

      expect(result.failureOrNull, isNotNull);
      expect(result.valueOrNull, isNull);
    });
  });
}

Task _task({String id = kTasksTestTaskId, DateTime? updatedAt}) => Task.create(
  id: id,
  accountId: kTasksTestAccountA,
  title: 'Remote task',
  scheduledDate: DateTime(2026, 10, 8),
  createdAt: updatedAt ?? DateTime.utc(2026, 10, 8, 9),
);

Map<String, dynamic> _acknowledgedRow({
  required DateTime now,
  bool replayed = false,
  String operationId = kTasksTestOperationId,
}) => <String, dynamic>{
  'id': kTasksTestTaskId,
  'owner': kTasksTestAccountA,
  'payload': <String, dynamic>{'title': 'Remote task'},
  'operation_id': operationId,
  'updated_at': now.toIso8601String(),
  'deleted_at': null,
  'conflict_detected': false,
  'retained_payload': null,
  'retained_updated_at': null,
  'retained_deleted_at': null,
  'replayed': replayed,
};

Map<String, dynamic> _remoteRow(Task task, {String? owner}) =>
    <String, dynamic>{
      'id': task.id,
      'owner': owner ?? task.accountId,
      'payload': jsonDecode(const TaskPayloadCodec().encode(task)),
      'updated_at': task.updatedAt.toIso8601String(),
      'deleted_at': task.deletedAt?.toIso8601String(),
    };

Map<String, dynamic> _remoteAwardRow({
  String owner = kTasksTestAccountA,
  String sourceId = kTasksTestTaskId,
  int amount = 20,
}) => <String, dynamic>{
  'owner': owner,
  'source': kTaskDoneAwardSource,
  'source_id': sourceId,
  'amount': amount,
  'awarded_at': DateTime.utc(2026, 10, 8, 10).toIso8601String(),
};

final class _AppliedCall {
  const _AppliedCall({
    required this.expectedAccountId,
    required this.id,
    required this.operationId,
    required this.kind,
    required this.payload,
    required this.updatedAt,
    required this.sentOwnerField,
  });

  final String expectedAccountId;
  final String id;
  final String operationId;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool sentOwnerField;
}

final class _FakeTaskGateway implements SupabaseTaskGateway {
  Map<String, dynamic> applyResponse = <String, dynamic>{};
  final List<_AppliedCall> applied = <_AppliedCall>[];
  final Map<String, TaskRemotePage> pages = <String, TaskRemotePage>{};
  final Map<String, TaskAwardRemotePage> awardPages =
      <String, TaskAwardRemotePage>{};
  final List<String?> requestedCursors = <String?>[];
  final List<String?> requestedAwardCursors = <String?>[];

  @override
  Future<Map<String, dynamic>> applyTaskChange({
    required String expectedAccountId,
    required String id,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    applied.add(
      _AppliedCall(
        expectedAccountId: expectedAccountId,
        id: id,
        operationId: operationId,
        kind: kind,
        payload: payload,
        updatedAt: updatedAt,
        sentOwnerField: false,
      ),
    );
    return applyResponse;
  }

  @override
  Future<TaskRemotePage> fetchTaskPage({
    required int pageSize,
    String? cursor,
  }) async {
    requestedCursors.add(cursor);
    return pages[cursor ?? '<first>'] ?? const TaskRemotePage(rows: []);
  }

  @override
  Future<TaskAwardRemotePage> fetchTaskAwardPage({
    required int pageSize,
    String? cursor,
  }) async {
    requestedAwardCursors.add(cursor);
    return awardPages[cursor ?? '<first>'] ??
        const TaskAwardRemotePage(rows: []);
  }
}
