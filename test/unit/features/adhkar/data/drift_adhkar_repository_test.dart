import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/adhkar_unit_of_work.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T024: the transactional Adhkar count store (data-model.md). Every commit
/// is one transaction: the count write, the provisional set award on the
/// first completion, and the outbox entry — or nothing at all on failure.
void main() {
  final key = List<int>.generate(32, (index) => index + 100);
  const identity = UuidAdhkarIdentity();

  // The approved set the screen shows, mirrored into the commit requests
  // (client set completion uses the same item set as the catalog).
  late FoundationDatabase db;
  late DriftAdhkarRepository repository;
  late DriftAdhkarUnitOfWork unitOfWork;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    repository = DriftAdhkarRepository(db, identity: identity);
    unitOfWork = DriftAdhkarUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  AdhkarCommitRequest request({
    String owner = 'owner',
    String day = '2026-11-10',
    String itemId = 'm1',
    int newCount = 1,
    required DateTime updatedAt,
    String operationId = 'op-1',
    DateTime? expectedCurrentVersion,
    DateTime? acknowledgedBase,
    bool queueForSync = true,
    List<AdhkarListItem>? listItems,
  }) => AdhkarCommitRequest(
    accountId: owner,
    adhkarDay: day,
    itemId: itemId,
    recordId: identity.itemRecordId(day, itemId),
    catalogVersion: 1,
    list: itemId.startsWith('m') ? 'morning' : 'evening',
    newCount: newCount,
    updatedAt: updatedAt,
    operationId: operationId,
    expectedCurrentVersion: expectedCurrentVersion,
    acknowledgedBase: acknowledgedBase,
    queueForSync: queueForSync,
    listItems:
        listItems ??
        (itemId.startsWith('m')
            ? const [
                AdhkarListItem(itemId: 'm1', target: 1),
                AdhkarListItem(itemId: 'm2', target: 3),
              ]
            : const [AdhkarListItem(itemId: 'e1', target: 1)]),
    setAwardSourceId: identity.setAwardSourceId(
      day,
      itemId.startsWith('m') ? 'morning' : 'evening',
    ),
  );

  test('an increment writes count+1, the provisional set award on '
      'completion, and the outbox entry, in one transaction', () async {
    final outcome = await unitOfWork.commit(
      request(
        updatedAt: DateTime.utc(2026, 11, 10, 8),
        listItems: const [AdhkarListItem(itemId: 'm1', target: 1)],
      ),
    );
    expect(outcome.failureOrNull, isNull);
    expect(outcome.valueOrNull!.newCount, 1);
    // The morning set is [m1:1, m2:3]; m1 at 1 of 1 completes it.
    expect(outcome.valueOrNull!.setCompleted, isTrue);
    expect(outcome.valueOrNull!.awardInserted, isTrue);

    expect(
      await repository
          .readFresh(accountId: 'owner', adhkarDay: '2026-11-10', itemId: 'm1')
          .then((r) => r.valueOrNull!.count),
      1,
    );
    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1));
    expect(award.single.source, kAdhkarSetDoneAwardSource);
    expect(award.single.amount, 15);
    expect(
      award.single.sourceId,
      identity.setAwardSourceId('2026-11-10', 'morning'),
    );
    final outbox = await db.select(db.pendingChanges).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.entityType, 'adhkar_item');
    expect(outbox.single.entityId, identity.itemRecordId('2026-11-10', 'm1'));
    final payload =
        jsonDecode(outbox.single.serializedChange) as Map<String, dynamic>;
    expect(payload['item_id'], 'm1');
    expect(payload['count'], 1);
    expect(payload['catalog_version'], 1);
  });

  test('a non-completing increment writes the count and the outbox but no '
      'award', () async {
    final outcome = await unitOfWork.commit(
      request(itemId: 'm2', updatedAt: DateTime.utc(2026, 11, 10, 8)),
    );
    expect(outcome.valueOrNull!.setCompleted, isFalse);
    expect(outcome.valueOrNull!.awardInserted, isFalse);
    expect(await db.select(db.xpAwards).get(), isEmpty);
    expect(await db.select(db.pendingChanges).get(), hasLength(1));
  });

  test('incrementing at the target is a no-op with no outbox entry', () async {
    await unitOfWork.commit(request(updatedAt: DateTime.utc(2026, 11, 10, 8)));
    final outboxBefore = await db.select(db.pendingChanges).get();
    final outcome = await unitOfWork.commit(
      request(
        updatedAt: DateTime.utc(2026, 11, 10, 9),
        operationId: 'op-2',
        expectedCurrentVersion: DateTime.utc(2026, 11, 10, 8),
      ),
    );
    expect(outcome.valueOrNull!.wroteCount, isFalse);
    expect(outcome.valueOrNull!.newCount, 1);
    expect(
      await db.select(db.pendingChanges).get(),
      hasLength(outboxBefore.length),
    );
  });

  test(
    'a reset writes 0, appends the outbox entry and leaves the award',
    () async {
      await unitOfWork.commit(
        request(
          updatedAt: DateTime.utc(2026, 11, 10, 8),
          listItems: const [AdhkarListItem(itemId: 'm1', target: 1)],
        ),
      );
      final outcome = await unitOfWork.commit(
        request(
          newCount: 0,
          updatedAt: DateTime.utc(2026, 11, 10, 9),
          operationId: 'op-reset',
          expectedCurrentVersion: DateTime.utc(2026, 11, 10, 8),
        ),
      );
      expect(outcome.valueOrNull!.newCount, 0);
      expect(outcome.valueOrNull!.setCompleted, isFalse);
      final awards = await db.select(db.xpAwards).get();
      expect(awards, hasLength(1), reason: 'awards are never revoked');
      final outbox = await db.select(db.pendingChanges).get();
      expect(outbox, hasLength(2));
    },
  );

  test(
    'a failed commit (non-monotonic version) leaves nothing behind',
    () async {
      await unitOfWork.commit(
        request(
          updatedAt: DateTime.utc(2026, 11, 10, 9),
          listItems: const [AdhkarListItem(itemId: 'm1', target: 1)],
        ),
      );
      final failure = await unitOfWork.commit(
        request(
          updatedAt: DateTime.utc(2026, 11, 10, 8),
          operationId: 'op-stale',
        ),
      );
      expect(failure.failureOrNull, isNotNull);
      expect(
        await repository
            .readFresh(
              accountId: 'owner',
              adhkarDay: '2026-11-10',
              itemId: 'm1',
            )
            .then((r) => r.valueOrNull!.updatedAt),
        DateTime.utc(2026, 11, 10, 9),
      );
      expect(await db.select(db.pendingChanges).get(), hasLength(1));
      expect(await db.select(db.xpAwards).get(), hasLength(1));
    },
  );

  test('reads and writes are isolated per owner', () async {
    await unitOfWork.commit(request(updatedAt: DateTime.utc(2026, 11, 10, 8)));
    final other = await unitOfWork.commit(
      request(
        owner: 'other',
        updatedAt: DateTime.utc(2026, 11, 10, 8),
        operationId: 'op-other',
      ),
    );
    expect(other.failureOrNull, isNull);
    final ownerRows = await repository
        .watchDay(accountId: 'owner', adhkarDay: '2026-11-10')
        .first;
    expect(ownerRows, hasLength(1));
    expect(ownerRows.single.accountId, 'owner');
  });

  test('the streak query returns the days with both set awards', () async {
    const morningComplete = [AdhkarListItem(itemId: 'm1', target: 1)];
    // Day 1: morning and evening both complete.
    await unitOfWork.commit(
      request(
        day: '2026-11-09',
        updatedAt: DateTime.utc(2026, 11, 9, 8),
        listItems: morningComplete,
      ),
    );
    await unitOfWork.commit(
      request(
        day: '2026-11-09',
        itemId: 'e1',
        updatedAt: DateTime.utc(2026, 11, 9, 20),
        operationId: 'op-d1-e',
      ),
    );
    // Day 2: only morning.
    await unitOfWork.commit(
      request(
        updatedAt: DateTime.utc(2026, 11, 10, 8),
        operationId: 'op-d2-m',
        listItems: morningComplete,
      ),
    );
    final days = await repository.fullyCompletedDays(
      accountId: 'owner',
      lastDay: '2026-11-11',
      maxLookBackDays: 30,
    );
    expect(days.valueOrNull, {'2026-11-09'});
  });
}
