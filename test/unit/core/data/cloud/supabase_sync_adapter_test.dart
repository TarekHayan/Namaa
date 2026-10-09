import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';

class _FakeSupabaseProbeGateway implements SupabaseProbeGateway {
  Map<String, dynamic>? storedRow;
  bool applyChangeCalled = false;
  Map<String, dynamic>? appliedChange;

  @override
  Future<Map<String, dynamic>?> fetchRow(String entityId) async => storedRow;

  @override
  Future<Map<String, dynamic>?> applyChange({
    required String entityId,
    required String payload,
    required String operationId,
    required String kind,
    required DateTime versionTimestamp,
  }) async {
    applyChangeCalled = true;
    appliedChange = {
      'id': entityId,
      'payload': payload,
      'operation_id': operationId,
      'kind': kind,
      'updated_at': versionTimestamp.toIso8601String(),
    };

    if (storedRow != null) {
      if (storedRow!['operation_id'] == operationId) {
        return storedRow; // Idempotent
      }
      return storedRow; // Conflict
    }

    if (kind == 'delete') {
      storedRow = null;
    } else {
      storedRow = {
        'id': entityId,
        'owner': 'account-1', // Mocked account owner
        'payload': payload,
        'operation_id': operationId,
        'updated_at': versionTimestamp.toIso8601String(),
      };
    }
    return null; // Success
  }
}

void main() {
  final now = DateTime.utc(2026, 9, 6, 12);

  OutboundChange buildChange({
    required String operationId,
    required ChangeKind kind,
    required DateTime versionTimestamp,
    String payload = '{"test":true}',
  }) => OutboundChange(
    operationId: operationId,
    accountId: 'account-1',
    entityType: 'foundation_probe',
    entityId: 'probe-1',
    kind: kind,
    payload: payload,
    versionTimestamp: versionTimestamp,
  );

  group('SupabaseSyncAdapter conflict preservation', () {
    test(
      'remote-older conflict returns DispatchVersionConflict and does not overwrite',
      () async {
        final gateway = _FakeSupabaseProbeGateway()
          ..storedRow = {
            'id': 'probe-1',
            'owner': 'account-1',
            'payload': 'remote-older-payload',
            'operation_id': 'op-remote-1',
            'updated_at': now
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
          };
        final adapter = SupabaseSyncAdapter(gateway: gateway);

        final change = buildChange(
          operationId: 'op-local-newer',
          kind: ChangeKind.update,
          versionTimestamp: now,
        );

        final result = await adapter.dispatchChange(change);
        expect(result.valueOrNull, isA<DispatchVersionConflict>());
        final conflict = result.valueOrNull as DispatchVersionConflict;
        expect(
          conflict.remoteVersionTimestamp,
          now.subtract(const Duration(minutes: 5)),
        );
        expect(conflict.remotePayload, 'remote-older-payload');
      },
    );

    test(
      'remote-newer conflict returns DispatchVersionConflict and does not overwrite',
      () async {
        final gateway = _FakeSupabaseProbeGateway()
          ..storedRow = {
            'id': 'probe-1',
            'owner': 'account-1',
            'payload': 'remote-newer-payload',
            'operation_id': 'op-remote-1',
            'updated_at': now.add(const Duration(minutes: 5)).toIso8601String(),
          };
        final adapter = SupabaseSyncAdapter(gateway: gateway);

        final change = buildChange(
          operationId: 'op-local-older',
          kind: ChangeKind.update,
          versionTimestamp: now,
        );

        final result = await adapter.dispatchChange(change);
        expect(result.valueOrNull, isA<DispatchVersionConflict>());
        final conflict = result.valueOrNull as DispatchVersionConflict;
        expect(
          conflict.remoteVersionTimestamp,
          now.add(const Duration(minutes: 5)),
        );
        expect(conflict.remotePayload, 'remote-newer-payload');
      },
    );

    test(
      'equal-timestamp conflict returns DispatchVersionConflict and does not overwrite',
      () async {
        final gateway = _FakeSupabaseProbeGateway()
          ..storedRow = {
            'id': 'probe-1',
            'owner': 'account-1',
            'payload': 'remote-equal-payload',
            'operation_id': 'op-remote-1',
            'updated_at': now.toIso8601String(),
          };
        final adapter = SupabaseSyncAdapter(gateway: gateway);

        final change = buildChange(
          operationId: 'op-local-equal',
          kind: ChangeKind.update,
          versionTimestamp: now,
        );

        final result = await adapter.dispatchChange(change);
        expect(result.valueOrNull, isA<DispatchVersionConflict>());
        final conflict = result.valueOrNull as DispatchVersionConflict;
        expect(conflict.remoteVersionTimestamp, now);
        expect(conflict.remotePayload, 'remote-equal-payload');
      },
    );

    test(
      'idempotent replay with same operation_id returns DispatchAcknowledged without mutation',
      () async {
        final gateway = _FakeSupabaseProbeGateway()
          ..storedRow = {
            'id': 'probe-1',
            'owner': 'account-1',
            'payload': 'original-payload',
            'operation_id': 'op-same-1',
            'updated_at': now.toIso8601String(),
          };
        final adapter = SupabaseSyncAdapter(gateway: gateway);

        final change = buildChange(
          operationId: 'op-same-1',
          kind: ChangeKind.update,
          versionTimestamp: now,
        );

        final result = await adapter.dispatchChange(change);
        expect(result.valueOrNull, isA<DispatchAcknowledged>());
        final ack = result.valueOrNull as DispatchAcknowledged;
        expect(ack.acknowledgementId, 'op-same-1');
      },
    );

    test(
      'newer local version retains the remote candidate returned after atomic apply',
      () async {
        final gateway = _FakeSupabaseProbeGateway()
          ..storedRow = {
            'id': 'probe-1',
            'owner': 'account-1',
            'payload': '{"local":true}',
            'operation_id': 'op-local-newer',
            'updated_at': now.toIso8601String(),
            'conflict_detected': true,
            'retained_payload': 'remote-older-payload',
            'retained_updated_at': now
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
          };
        final adapter = SupabaseSyncAdapter(gateway: gateway);

        final result = await adapter.dispatchChange(
          buildChange(
            operationId: 'op-local-newer',
            kind: ChangeKind.update,
            versionTimestamp: now,
          ),
        );

        expect(result.valueOrNull, isA<DispatchVersionConflict>());
        final conflict = result.valueOrNull as DispatchVersionConflict;
        expect(conflict.remotePayload, 'remote-older-payload');
        expect(
          conflict.remoteVersionTimestamp,
          now.subtract(const Duration(minutes: 5)),
        );
      },
    );
  });

  group('SupabaseSyncAdapter create, update, delete operations', () {
    test('create operation calls upsertRow', () async {
      final gateway = _FakeSupabaseProbeGateway();
      final adapter = SupabaseSyncAdapter(gateway: gateway);

      final change = buildChange(
        operationId: 'op-create-1',
        kind: ChangeKind.create,
        versionTimestamp: now,
        payload: '{"created":true}',
      );

      final result = await adapter.dispatchChange(change);
      expect(result.valueOrNull, isA<DispatchAcknowledged>());
      expect(gateway.applyChangeCalled, isTrue);
      expect(gateway.appliedChange?['id'], 'probe-1');
      expect(gateway.appliedChange?['payload'], '{"created":true}');
    });

    test('update operation calls upsertRow when no remote conflict', () async {
      final gateway = _FakeSupabaseProbeGateway();
      final adapter = SupabaseSyncAdapter(gateway: gateway);

      final change = buildChange(
        operationId: 'op-update-1',
        kind: ChangeKind.update,
        versionTimestamp: now,
        payload: '{"updated":true}',
      );

      final result = await adapter.dispatchChange(change);
      expect(result.valueOrNull, isA<DispatchAcknowledged>());
      expect(gateway.applyChangeCalled, isTrue);
      expect(gateway.appliedChange?['payload'], '{"updated":true}');
    });

    test('delete operation calls deleteRow instead of upsertRow', () async {
      final gateway = _FakeSupabaseProbeGateway();
      final adapter = SupabaseSyncAdapter(gateway: gateway);

      final change = buildChange(
        operationId: 'op-delete-1',
        kind: ChangeKind.delete,
        versionTimestamp: now,
      );

      final result = await adapter.dispatchChange(change);
      expect(result.valueOrNull, isA<DispatchAcknowledged>());
      expect(gateway.applyChangeCalled, isTrue);
      expect(gateway.appliedChange?['id'], 'probe-1');
    });
  });
}
