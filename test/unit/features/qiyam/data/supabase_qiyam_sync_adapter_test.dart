import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/data/local/qiyam_unit_of_work.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/qiyam_remote_models.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_gateway.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_sync_adapter.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T061: the Qiyam night outbound dispatch — the same receipt/finalization
/// contract as the Adhkar counts (`apply_qiyam_night_change_v1`), with the
/// night's typed fields and the `qiyam_done` award settled by (source,
/// sourceId) where the source id IS the night record id.
void main() {
  final identity = const UuidQiyamIdentity();
  final night = '2026-11-11';
  final updated = DateTime.utc(2026, 11, 11, 20, 5);
  final recordId = identity.nightRecordId(night);

  late FoundationDatabase db;
  late DriftQiyamRepository repository;
  late DriftQiyamUnitOfWork unitOfWork;
  late FakeQiyamGateway gateway;
  late SupabaseQiyamSyncAdapter adapter;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 60),
    );
    repository = DriftQiyamRepository(db);
    unitOfWork = DriftQiyamUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
    gateway = FakeQiyamGateway();
    adapter = SupabaseQiyamSyncAdapter(
      gateway: gateway,
      repository: repository,
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  QiyamSaveRequest request({
    bool performed = true,
    required DateTime at,
    String operationId = 'op-1',
    DateTime? expectedCurrentVersion,
  }) => QiyamSaveRequest(
    accountId: 'owner',
    nightDate: night,
    recordId: recordId,
    performed: performed,
    rakahs: performed ? 4 : null,
    witr: performed,
    startTime: performed ? '22:10' : null,
    endTime: performed ? '02:40' : null,
    note: performed ? 'test note' : null,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    updatedAt: at,
    operationId: operationId,
    expectedCurrentVersion: expectedCurrentVersion,
    acknowledgedBase: null,
    queueForSync: true,
  );

  QiyamNightRecord localRecord({required DateTime at}) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: night,
    recordId: recordId,
    performed: true,
    rakahs: 4,
    witr: true,
    startTime: '22:10',
    endTime: '02:40',
    note: 'test note',
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: at,
    updatedAt: at,
    lastAcknowledgedUpdatedAt: null,
  );

  QiyamNightRecord serverRecord({
    bool performed = true,
    required DateTime at,
  }) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: night,
    recordId: recordId,
    performed: performed,
    rakahs: performed ? 8 : null,
    witr: performed,
    startTime: performed ? '23:00' : null,
    endTime: performed ? '01:30' : null,
    note: performed ? 'server note' : null,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: DateTime.utc(2026, 11, 11, 19),
    updatedAt: at,
    lastAcknowledgedUpdatedAt: null,
  );

  String payload(QiyamNightRecord record) => jsonEncode({
    'night_date': record.nightDate,
    'performed': record.performed,
    'rakahs': record.rakahs,
    'witr': record.witr,
    'start_time': record.startTime,
    'end_time': record.endTime,
    'note': record.note,
    'recorded_zone_id': record.recordedZoneId,
    'recorded_offset_minutes': record.recordedOffsetMinutes,
    'updated_at': record.updatedAt.toIso8601String(),
    'base_updated_at': record.lastAcknowledgedUpdatedAt?.toIso8601String(),
  });

  OutboundChange change(QiyamNightRecord record, String operationId) =>
      OutboundChange(
        operationId: operationId,
        accountId: 'owner',
        entityType: 'qiyam_night',
        entityId: recordId,
        kind: ChangeKind.create,
        payload: payload(record),
        versionTimestamp: record.updatedAt,
        baseUpdatedAt: record.lastAcknowledgedUpdatedAt,
      );

  test('the RPC arguments map the typed night fields with no owner or XP '
      'amount', () async {
    final local = serverRecord(at: updated);
    await unitOfWork.commit(request(at: updated));
    gateway.receipt = QiyamDispatchReceipt(
      operationId: 'op-1',
      active: local,
      conflict: null,
      award: null,
    );

    final outcome = await adapter.dispatchChange(
      change(localRecord(at: updated), 'op-1'),
    );

    expect(outcome.failureOrNull, isNull);
    final args = gateway.capturedParams!;
    expect(args['p_night_date'], night);
    expect(args['p_performed'], isTrue);
    expect(args['p_rakahs'], 4);
    expect(args['p_witr'], isTrue);
    expect(args['p_start_time'], '22:10');
    expect(args['p_end_time'], '02:40');
    expect(args['p_note'], 'test note');
    expect(args['p_recorded_zone_id'], 'UTC');
    expect(args['p_recorded_offset_minutes'], 0);
    expect(args['p_updated_at'], updated.toIso8601String());
    expect(args['p_operation_id'], 'op-1');
    for (final key in args.keys) {
      expect(
        key.contains('owner') || key.contains('xp'),
        isFalse,
        reason: 'owner and XP are never client-sent',
      );
    }
    final acknowledged = outcome.valueOrNull! as DispatchAcknowledged;
    expect(acknowledged.acknowledgementId, 'op-1');
  });

  test('the receipt maps the active record, conflict and canonical award '
      'before the ACK', () async {
    final local = serverRecord(at: updated);
    await unitOfWork.commit(request(at: updated));
    final serverActive = serverRecord(at: DateTime.utc(2026, 11, 11, 21));
    gateway.receipt = QiyamDispatchReceipt(
      operationId: 'op-1',
      active: serverActive,
      conflict: QiyamRemoteConflict(
        id: 'q-conflict-1',
        active: serverActive,
        retained: local,
        detectedAt: DateTime.utc(2026, 11, 11, 21, 10),
      ),
      award: XpAward(
        accountId: 'owner',
        source: kQiyamDoneAwardSource,
        sourceId: recordId,
        amount: 30,
        awardedAt: DateTime.utc(2026, 11, 11, 21),
      ),
    );

    final outcome = await adapter.dispatchChange(
      change(localRecord(at: updated), 'op-1'),
    );

    final acknowledged = outcome.valueOrNull! as DispatchAcknowledged;
    expect(acknowledged.remoteVersionTimestamp, serverActive.updatedAt);
    final applied = await repository.readFresh(
      accountId: 'owner',
      nightDate: night,
    );
    expect(applied.valueOrNull!.rakahs, 8);
    expect(
      applied.valueOrNull!.lastAcknowledgedUpdatedAt,
      serverActive.updatedAt,
    );
    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1));
    expect(award.single.source, kQiyamDoneAwardSource);
    expect(award.single.sourceId, recordId);
    expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);
  });

  test('a failed dispatch leaves the night pending and untouched', () async {
    await unitOfWork.commit(request(at: updated));
    gateway.error = StateError('network down');

    final outcome = await adapter.dispatchChange(
      change(localRecord(at: updated), 'op-1'),
    );

    expect(outcome.failureOrNull, isNotNull);
    expect(
      (await repository.readFresh(
        accountId: 'owner',
        nightDate: night,
      )).valueOrNull!.lastAcknowledgedUpdatedAt,
      isNull,
    );
    expect(
      await db.rawScalar(
        'SELECT count(*) FROM pending_changes WHERE state = 0',
      ),
      1,
    );
  });

  test('an old response cannot overwrite a newer local night', () async {
    final first = serverRecord(at: updated);
    await unitOfWork.commit(request(at: updated));
    final secondAt = DateTime.utc(2026, 11, 11, 22);
    final secondCommit = await unitOfWork.commit(
      request(
        performed: false,
        at: secondAt,
        operationId: 'op-2',
        expectedCurrentVersion: updated,
      ),
    );
    expect(secondCommit.failureOrNull, isNull);

    gateway.receipt = QiyamDispatchReceipt(
      operationId: 'op-1',
      active: first,
      conflict: null,
      award: null,
    );
    final outcome = await adapter.dispatchChange(
      change(localRecord(at: updated), 'op-1'),
    );
    expect(outcome.failureOrNull, isNull);

    final local = await repository.readFresh(
      accountId: 'owner',
      nightDate: night,
    );
    expect(
      local.valueOrNull!.updatedAt,
      secondAt,
      reason: 'the newer local version survived the old response',
    );
    expect(
      local.valueOrNull!.lastAcknowledgedUpdatedAt,
      first.updatedAt,
      reason: 'the acknowledged base rebases to what the server has',
    );
  });

  test('finalization is one transaction: a foreign receipt rolls everything '
      'back', () async {
    await unitOfWork.commit(request(at: updated));
    final foreignActive = QiyamNightRecord(
      accountId: 'other-owner',
      nightDate: night,
      recordId: recordId,
      performed: true,
      rakahs: 8,
      witr: true,
      startTime: '23:00',
      endTime: '01:30',
      note: 'server note',
      recordedZoneId: 'UTC',
      recordedOffsetMinutes: 0,
      createdAt: DateTime.utc(2026, 11, 11, 19),
      updatedAt: DateTime.utc(2026, 11, 11, 21),
      lastAcknowledgedUpdatedAt: null,
    );
    gateway.receipt = QiyamDispatchReceipt(
      operationId: 'op-1',
      active: foreignActive,
      conflict: null,
      award: XpAward(
        accountId: 'owner',
        source: kQiyamDoneAwardSource,
        sourceId: recordId,
        amount: 30,
        awardedAt: DateTime.utc(2026, 11, 11, 21),
      ),
    );

    final outcome = await adapter.dispatchChange(
      change(localRecord(at: updated), 'op-1'),
    );
    expect(outcome.failureOrNull, isNotNull);
    // The provisional replica from the local commit stays; the canonical
    // settlement (awarded_at 21:00) was rolled back and never landed.
    final awards = await db.select(db.xpAwards).get();
    expect(awards, hasLength(1));
    expect(awards.single.awardedAt, updated);
    expect(
      (await repository.readFresh(
        accountId: 'owner',
        nightDate: night,
      )).valueOrNull!.lastAcknowledgedUpdatedAt,
      isNull,
    );
    expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 0);
  });
}

final class FakeQiyamGateway implements SupabaseQiyamGateway {
  QiyamDispatchReceipt? receipt;
  Object? error;
  Map<String, Object?>? capturedParams;

  @override
  String? get currentAccountId => 'owner';

  @override
  Future<QiyamNightRecord?> fetchNight({
    required String expectedAccountId,
    required String recordId,
  }) async => null;

  @override
  Future<QiyamDispatchReceipt> applyChange({
    required String expectedAccountId,
    required QiyamNightRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    capturedParams = {
      'p_night_date': record.nightDate,
      'p_performed': record.performed,
      'p_rakahs': record.rakahs,
      'p_witr': record.witr,
      'p_start_time': record.startTime,
      'p_end_time': record.endTime,
      'p_note': record.note,
      'p_recorded_zone_id': record.recordedZoneId,
      'p_recorded_offset_minutes': record.recordedOffsetMinutes,
      'p_updated_at': record.updatedAt.toIso8601String(),
      'p_base_updated_at': baseUpdatedAt?.toIso8601String(),
      'p_operation_id': operationId,
    };
    final error = this.error;
    if (error != null) throw error;
    return receipt!;
  }
}
