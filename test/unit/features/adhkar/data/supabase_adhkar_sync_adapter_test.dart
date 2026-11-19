import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/adhkar_unit_of_work.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/adhkar_remote_models.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_gateway.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_sync_adapter.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T059: the Adhkar outbound dispatch (contracts/adhkar-qiyam-sync.md): the
/// typed RPC arguments map from the outbox payload without owner, record id,
/// list or XP amount; the response maps receipt/active/retained/
/// conflictId/canonicalAward; local finalization happens in one repository
/// transaction before the ACK, and a failure leaves the operation pending;
/// an old response never overwrites a newer local version.
void main() {
  final identity = const UuidAdhkarIdentity();
  final day = '2026-11-10';
  final updated = DateTime.utc(2026, 11, 10, 8);
  final recordId = identity.itemRecordId(day, 'm1');

  late FoundationDatabase db;
  late DriftAdhkarRepository repository;
  late DriftAdhkarUnitOfWork unitOfWork;
  late FakeAdhkarGateway gateway;
  late SupabaseAdhkarSyncAdapter adapter;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 30),
    );
    repository = DriftAdhkarRepository(db);
    unitOfWork = DriftAdhkarUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
    gateway = FakeAdhkarGateway();
    adapter = SupabaseAdhkarSyncAdapter(
      gateway: gateway,
      repository: repository,
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  AdhkarCommitRequest request({
    String itemId = 'm1',
    int newCount = 1,
    required DateTime at,
    String operationId = 'op-1',
    DateTime? expectedCurrentVersion,
  }) => AdhkarCommitRequest(
    accountId: 'owner',
    adhkarDay: day,
    itemId: itemId,
    recordId: identity.itemRecordId(day, itemId),
    catalogVersion: 1,
    list: itemId.startsWith('m') ? 'morning' : 'evening',
    newCount: newCount,
    updatedAt: at,
    operationId: operationId,
    expectedCurrentVersion: expectedCurrentVersion,
    acknowledgedBase: null,
    queueForSync: true,
    listItems: const [
      AdhkarListItem(itemId: 'm1', target: 1),
      AdhkarListItem(itemId: 'm2', target: 3),
    ],
    setAwardSourceId: identity.setAwardSourceId(day, 'morning'),
  );

  AdhkarCountRecord activeRecord({
    int count = 1,
    required DateTime at,
    DateTime? acknowledged,
  }) => AdhkarCountRecord(
    accountId: 'owner',
    adhkarDay: day,
    itemId: 'm1',
    recordId: recordId,
    catalogVersion: 1,
    list: 'morning',
    count: count,
    createdAt: DateTime.utc(2026, 11, 10, 7),
    updatedAt: at,
    lastAcknowledgedUpdatedAt: acknowledged,
  );

  /// The outbox payload exactly as the repository writes it.
  String payload(AdhkarCountRecord record) => jsonEncode({
    'adhkar_day': record.adhkarDay,
    'item_id': record.itemId,
    'catalog_version': record.catalogVersion,
    'count': record.count,
    'updated_at': record.updatedAt.toIso8601String(),
    'base_updated_at': record.lastAcknowledgedUpdatedAt?.toIso8601String(),
  });

  OutboundChange change(AdhkarCountRecord record, String operationId) =>
      OutboundChange(
        operationId: operationId,
        accountId: 'owner',
        entityType: 'adhkar_item',
        entityId: recordId,
        kind: ChangeKind.create,
        payload: payload(record),
        versionTimestamp: record.updatedAt,
        baseUpdatedAt: record.lastAcknowledgedUpdatedAt,
      );

  test('the RPC arguments map from the outbox payload with no owner, record '
      'id, list or XP amount', () async {
    final local = activeRecord(at: updated);
    await unitOfWork.commit(request(at: updated));
    gateway.receipt = AdhkarDispatchReceipt(
      operationId: 'op-1',
      active: local,
      conflict: null,
      award: null,
    );

    final outcome = await adapter.dispatchChange(
      change(activeRecord(at: updated), 'op-1'),
    );

    expect(outcome.failureOrNull, isNull);
    final args = gateway.capturedParams!;
    expect(args['p_adhkar_day'], day);
    expect(args['p_item_id'], 'm1');
    expect(args['p_catalog_version'], 1);
    expect(args['p_count'], 1);
    expect(args['p_updated_at'], updated.toIso8601String());
    expect(args['p_base_updated_at'], isNull);
    expect(args['p_operation_id'], 'op-1');
    for (final forbidden in args.keys) {
      expect(
        forbidden == 'p_owner' || forbidden.contains('record_id'),
        isFalse,
        reason: 'the client never sends an owner or a record id',
      );
      expect(
        forbidden.contains('list') || forbidden.contains('xp'),
        isFalse,
        reason: 'list and XP are server-derived',
      );
    }
    expect(outcome.valueOrNull, isA<DispatchAcknowledged>());
  });

  test('the outcome maps receipt, active, retained, conflictId and '
      'canonicalAward, finalized before the ACK', () async {
    await unitOfWork.commit(request(at: updated));
    final serverActive = activeRecord(
      count: 2,
      at: DateTime.utc(2026, 11, 10, 9),
    );
    final retained = activeRecord(at: updated);
    final setSourceId = identity.setAwardSourceId(day, 'morning');
    gateway.receipt = AdhkarDispatchReceipt(
      operationId: 'op-1',
      active: serverActive,
      conflict: AdhkarRemoteConflict(
        id: 'conflict-1',
        active: serverActive,
        retained: retained,
        detectedAt: DateTime.utc(2026, 11, 10, 9, 5),
      ),
      award: XpAward(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: setSourceId,
        amount: 15,
        awardedAt: DateTime.utc(2026, 11, 10, 9),
      ),
    );

    final outcome = await adapter.dispatchChange(
      change(activeRecord(at: updated), 'op-1'),
    );

    final acknowledged = outcome.valueOrNull! as DispatchAcknowledged;
    expect(acknowledged.acknowledgementId, 'op-1');
    expect(acknowledged.remoteVersionTimestamp, serverActive.updatedAt);

    // The server's active record was applied with the acknowledged marker.
    final local2 = await repository.readFresh(
      accountId: 'owner',
      adhkarDay: day,
      itemId: 'm1',
    );
    expect(local2.valueOrNull!.count, 2);
    expect(
      local2.valueOrNull!.lastAcknowledgedUpdatedAt,
      serverActive.updatedAt,
    );

    // The canonical award settled by (source, sourceId) — the SET source id,
    // never the item's record id — replacing the provisional 15 XP replica.
    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1));
    expect(award.single.source, kAdhkarSetDoneAwardSource);
    expect(award.single.sourceId, setSourceId);
    expect(award.single.awardedAt, DateTime.utc(2026, 11, 10, 9));

    // The conflict evidence is upserted by its stable id.
    expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);
    expect(
      await db.rawScalar(
        "SELECT count(*) FROM conflict_records WHERE conflict_id = 'conflict-1'",
      ),
      1,
    );
  });

  test('a failed dispatch leaves the local record untouched and reports a '
      'recoverable failure', () async {
    await unitOfWork.commit(request(at: updated));
    gateway.error = StateError('network down');

    final outcome = await adapter.dispatchChange(
      change(activeRecord(at: updated), 'op-1'),
    );

    expect(outcome.failureOrNull, isNotNull);
    expect(outcome.failureOrNull!.recoverable, isTrue);
    expect(
      (await repository.readFresh(
        accountId: 'owner',
        adhkarDay: day,
        itemId: 'm1',
      )).valueOrNull!.lastAcknowledgedUpdatedAt,
      isNull,
      reason: 'nothing was acknowledged locally',
    );
    // The outbox row is still pending (the coordinator never ACKed).
    expect(
      await db.rawScalar(
        'SELECT count(*) FROM pending_changes WHERE state = 0',
      ),
      1,
    );
  });

  test('an old response cannot overwrite a newer local version', () async {
    final first = activeRecord(at: updated);
    await unitOfWork.commit(request(at: updated));
    final secondAt = DateTime.utc(2026, 11, 10, 10);
    final secondCommit = await unitOfWork.commit(
      request(
        newCount: 0,
        at: secondAt,
        operationId: 'op-2',
        expectedCurrentVersion: updated,
      ),
    );
    expect(secondCommit.failureOrNull, isNull);

    // The replayed op-1 response arrives late, carrying the OLD version and
    // op-1's own outbox version (08:00), like a lost ACK retried later.
    gateway.receipt = AdhkarDispatchReceipt(
      operationId: 'op-1',
      active: first,
      conflict: null,
      award: null,
    );
    final outcome = await adapter.dispatchChange(change(first, 'op-1'));
    expect(outcome.failureOrNull, isNull);
    final local = await repository.readFresh(
      accountId: 'owner',
      adhkarDay: day,
      itemId: 'm1',
    );
    expect(
      local.valueOrNull!.updatedAt,
      secondAt,
      reason: 'the newer local version survived the old response',
    );
    expect(
      local.valueOrNull!.lastAcknowledgedUpdatedAt,
      first.updatedAt,
      reason:
          'the acknowledged base rebases to what the server has; the '
          'newer local version itself is never overwritten',
    );
  });

  test('finalization is one transaction: a foreign receipt rolls everything '
      'back', () async {
    await unitOfWork.commit(request(at: updated));
    final foreignActive = AdhkarCountRecord(
      accountId: 'other-owner',
      adhkarDay: day,
      itemId: 'm1',
      recordId: recordId,
      catalogVersion: 1,
      list: 'morning',
      count: 2,
      createdAt: DateTime.utc(2026, 11, 10, 7),
      updatedAt: DateTime.utc(2026, 11, 10, 9),
      lastAcknowledgedUpdatedAt: null,
    );
    gateway.receipt = AdhkarDispatchReceipt(
      operationId: 'op-1',
      active: foreignActive,
      conflict: null,
      award: XpAward(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: identity.setAwardSourceId(day, 'morning'),
        amount: 15,
        awardedAt: DateTime.utc(2026, 11, 10, 9),
      ),
    );

    final outcome = await adapter.dispatchChange(
      change(activeRecord(at: updated), 'op-1'),
    );
    expect(outcome.failureOrNull, isNotNull);
    // Rolled back together: the award was NOT settled, the record NOT applied.
    expect(await db.select(db.xpAwards).get(), hasLength(0));
    expect(
      (await repository.readFresh(
        accountId: 'owner',
        adhkarDay: day,
        itemId: 'm1',
      )).valueOrNull!.lastAcknowledgedUpdatedAt,
      isNull,
    );
    expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 0);
  });

  test('an outbox payload whose version does not match the change fails '
      'without contacting the gateway', () async {
    final outcome = await adapter.dispatchChange(
      OutboundChange(
        operationId: 'op-x',
        accountId: 'owner',
        entityType: 'adhkar_item',
        entityId: recordId,
        kind: ChangeKind.create,
        payload: payload(activeRecord(at: DateTime.utc(2026, 11, 10, 6))),
        versionTimestamp: updated,
      ),
    );
    expect(outcome.failureOrNull, isNotNull);
    expect(gateway.capturedParams, isNull);
  });
}

final class FakeAdhkarGateway implements SupabaseAdhkarGateway {
  AdhkarDispatchReceipt? receipt;
  Object? error;
  Map<String, Object?>? capturedParams;
  String? currentOwner = 'owner';

  @override
  String? get currentAccountId => currentOwner;

  @override
  Future<AdhkarCountRecord?> fetchCount({
    required String expectedAccountId,
    required String recordId,
  }) async => null;

  @override
  Future<AdhkarDispatchReceipt> applyChange({
    required String expectedAccountId,
    required AdhkarCountRecord record,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    capturedParams = {
      'p_adhkar_day': record.adhkarDay,
      'p_item_id': record.itemId,
      'p_catalog_version': record.catalogVersion,
      'p_count': record.count,
      'p_updated_at': record.updatedAt.toIso8601String(),
      'p_base_updated_at': baseUpdatedAt?.toIso8601String(),
      'p_operation_id': operationId,
    };
    final error = this.error;
    if (error != null) throw error;
    return receipt!;
  }
}
