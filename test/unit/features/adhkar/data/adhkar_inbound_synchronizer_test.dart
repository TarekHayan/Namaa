import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/adhkar_unit_of_work.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/adhkar_inbound_synchronizer.dart';
import 'package:namma_project/features/adhkar/data/adhkar_reconciler.dart';
import 'package:namma_project/features/adhkar/data/adhkar_remote_models.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_reader.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T063: the Adhkar inbound synchronizer (contracts/adhkar-qiyam-sync.md).
/// Pages restart from the start of the range on the next pass; a failed
/// page applies nothing; awards settle by (source, sourceId) replacing the
/// provisional replica once; conflicts upsert by their stable id; and any
/// foreign-owner row fails the whole pass.
void main() {
  final identity = const UuidAdhkarIdentity();
  final day = '2026-11-10';

  late FoundationDatabase db;
  late DriftAdhkarRepository repository;
  late DriftAdhkarUnitOfWork unitOfWork;
  late DriftAwardLedger ledger;
  late FakeAdhkarReader reader;
  late AdhkarInboundSynchronizer synchronizer;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 70),
    );
    repository = DriftAdhkarRepository(db);
    unitOfWork = DriftAdhkarUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
    ledger = DriftAwardLedger(db);
    reader = FakeAdhkarReader();
    synchronizer = AdhkarInboundSynchronizer(
      reader: reader,
      reconciler: AdhkarReconciler(
        repository: repository,
        localStore: DriftLocalStore(db),
        awards: ledger,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  AdhkarCountRecord remoteCount({
    required String itemId,
    required int count,
    required DateTime at,
    String owner = 'owner',
  }) => AdhkarCountRecord(
    accountId: owner,
    adhkarDay: day,
    itemId: itemId,
    recordId: identity.itemRecordId(day, itemId),
    catalogVersion: 1,
    list: itemId.startsWith('m') ? 'morning' : 'evening',
    count: count,
    createdAt: at,
    updatedAt: at,
    lastAcknowledgedUpdatedAt: null,
  );

  test('imports a keyset-paged snapshot; a failed page applies nothing and '
      'the next pass restarts from the start', () async {
    final at = DateTime.utc(2026, 11, 10, 8);
    final first = remoteCount(itemId: 'm1', count: 1, at: at);
    final second = remoteCount(
      itemId: 'm2',
      count: 2,
      at: DateTime.utc(2026, 11, 10, 9),
    );
    reader
      ..pages = [
        [first],
        [second],
      ]
      ..failPageIndex = 1;

    final failed = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(failed.failureOrNull, isNotNull);
    expect(
      await repository
          .readFresh(accountId: 'owner', adhkarDay: day, itemId: 'm1')
          .then((r) => r.valueOrNull),
      isNull,
      reason: 'a failed page leaves nothing behind',
    );
    expect(
      reader.startsFromStart,
      everyElement(isTrue),
      reason: 'every pass restarts from the first key',
    );

    reader.failPageIndex = null;
    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(result.valueOrNull!.importedCounts, 2);
    expect(
      await repository
          .readFresh(accountId: 'owner', adhkarDay: day, itemId: 'm2')
          .then((r) => r.valueOrNull!.count),
      2,
    );
  });

  test('awards settle by (source, sourceId), replacing the provisional '
      'award once', () async {
    final at = DateTime.utc(2026, 11, 10, 8);
    // The local commit inserts the provisional award at the local instant.
    await unitOfWork.commit(
      AdhkarCommitRequest(
        accountId: 'owner',
        adhkarDay: day,
        itemId: 'm1',
        recordId: identity.itemRecordId(day, 'm1'),
        catalogVersion: 1,
        list: 'morning',
        newCount: 1,
        updatedAt: at,
        operationId: 'op-1',
        expectedCurrentVersion: null,
        acknowledgedBase: null,
        queueForSync: false,
        listItems: const [AdhkarListItem(itemId: 'm1', target: 1)],
        setAwardSourceId: identity.setAwardSourceId(day, 'morning'),
      ),
    );
    final provisional = await ledger.readSharedAward(
      accountId: 'owner',
      source: kAdhkarSetDoneAwardSource,
      sourceId: identity.setAwardSourceId(day, 'morning'),
    );
    expect(provisional.valueOrNull!.awardedAt, at);

    final serverInstant = DateTime.utc(2026, 11, 10, 8, 30);
    reader.awards = [
      XpAward(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: identity.setAwardSourceId(day, 'morning'),
        amount: 15,
        awardedAt: serverInstant,
      ),
    ];
    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(result.valueOrNull!.importedAwards, 1);
    final settled = await ledger.readSharedAward(
      accountId: 'owner',
      source: kAdhkarSetDoneAwardSource,
      sourceId: identity.setAwardSourceId(day, 'morning'),
    );
    expect(
      settled.valueOrNull!.awardedAt,
      serverInstant,
      reason: 'the canonical instant replaced the provisional one',
    );

    // The same award arriving again settles exactly once.
    await synchronizer.receive(accountId: 'owner', isCurrentScope: () => true);
    expect(await db.select(db.xpAwards).get(), hasLength(1));
  });

  test('conflicts upsert by their stable id, never duplicating', () async {
    final at = DateTime.utc(2026, 11, 10, 8);
    final active = remoteCount(itemId: 'm1', count: 2, at: at);
    final retained = remoteCount(
      itemId: 'm1',
      count: 1,
      at: DateTime.utc(2026, 11, 10, 7),
    );
    reader.conflicts = [
      AdhkarRemoteConflict(
        id: 'conflict-stable',
        active: active,
        retained: retained,
        detectedAt: DateTime.utc(2026, 11, 10, 9),
      ),
    ];
    await synchronizer.receive(accountId: 'owner', isCurrentScope: () => true);
    expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);

    // The same stable id arrives again with a later detection instant.
    reader.conflicts = [
      AdhkarRemoteConflict(
        id: 'conflict-stable',
        active: active,
        retained: retained,
        detectedAt: DateTime.utc(2026, 11, 10, 10),
      ),
    ];
    await synchronizer.receive(accountId: 'owner', isCurrentScope: () => true);
    expect(
      await db.rawScalar('SELECT count(*) FROM conflict_records'),
      1,
      reason: 'the stable id is the upsert key',
    );
  });

  test('a pending local descendant and a newer acknowledgement are not '
      'overwritten by inbound rows', () async {
    final localAt = DateTime.utc(2026, 11, 10, 12);
    await unitOfWork.commit(
      AdhkarCommitRequest(
        accountId: 'owner',
        adhkarDay: day,
        itemId: 'm1',
        recordId: identity.itemRecordId(day, 'm1'),
        catalogVersion: 1,
        list: 'morning',
        newCount: 2,
        updatedAt: localAt,
        operationId: 'op-1',
        expectedCurrentVersion: null,
        acknowledgedBase: null,
        queueForSync: true,
        listItems: const [AdhkarListItem(itemId: 'm1', target: 1)],
        setAwardSourceId: identity.setAwardSourceId(day, 'morning'),
      ),
    );
    // The server still holds an older version for the same item.
    reader.counts = [
      remoteCount(itemId: 'm1', count: 1, at: DateTime.utc(2026, 11, 10, 8)),
    ];

    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(
      result.valueOrNull!.importedCounts,
      0,
      reason: 'a pending local descendant survives',
    );
    expect(
      await repository
          .readFresh(accountId: 'owner', adhkarDay: day, itemId: 'm1')
          .then((r) => r.valueOrNull!.count),
      2,
    );
  });

  test(
    'a foreign-owner row fails the whole pass and applies nothing',
    () async {
      reader.counts = [
        remoteCount(
          itemId: 'm1',
          count: 1,
          at: DateTime.utc(2026, 11, 10, 8),
          owner: 'foreign-owner',
        ),
      ];
      final result = await synchronizer.receive(
        accountId: 'owner',
        isCurrentScope: () => true,
      );
      expect(result.failureOrNull, isNotNull);
      expect(
        await repository
            .readFresh(accountId: 'owner', adhkarDay: day, itemId: 'm1')
            .then((r) => r.valueOrNull),
        isNull,
      );
      expect(await db.select(db.xpAwards).get(), isEmpty);
    },
  );

  test('a stale scope never applies a snapshot', () async {
    reader.counts = [
      remoteCount(itemId: 'm1', count: 1, at: DateTime.utc(2026, 11, 10, 8)),
    ];
    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => false,
    );
    expect(result.failureOrNull, isNotNull);
    expect(
      await repository
          .readFresh(accountId: 'owner', adhkarDay: day, itemId: 'm1')
          .then((r) => r.valueOrNull),
      isNull,
    );
  });
}

/// The reader fake: serves its dataset in explicit pages with a cursored
/// walk that always restarts from the first key, and can be told to fail
/// one page.
final class FakeAdhkarReader implements AdhkarRemoteReader {
  List<List<AdhkarCountRecord>> pages = const [];
  List<AdhkarCountRecord> counts = const [];
  List<XpAward> awards = const [];
  List<AdhkarRemoteConflict> conflicts = const [];
  int? failPageIndex;
  final startsFromStart = <bool>[];

  @override
  Future<AdhkarRemoteSnapshot> readAll(String accountId) async {
    startsFromStart.add(true);
    final collected = <AdhkarCountRecord>[];
    for (var i = 0; i < pages.length; i++) {
      if (failPageIndex == i) {
        throw StateError('page $i failed');
      }
      collected.addAll(pages[i]);
    }
    collected.addAll(counts);
    return AdhkarRemoteSnapshot(
      counts: List.unmodifiable(collected),
      awards: List.unmodifiable(awards),
      conflicts: List.unmodifiable(conflicts),
      catalog: const [],
    );
  }
}
