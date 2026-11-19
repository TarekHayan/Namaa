import 'dart:convert';

import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/qiyam_unit_of_work.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T039: the transactional Qiyam night store (data-model.md). Every save is
/// one transaction: the record upsert, the provisional `qiyam_done` award on
/// the first `performed = true`, and the outbox entry — or nothing at all on
/// failure. Yes -> No -> Yes keeps exactly one award; awards are never
/// revoked.
void main() {
  final key = List<int>.generate(32, (index) => index + 100);
  const identity = UuidQiyamIdentity();

  late FoundationDatabase db;
  late DriftQiyamRepository repository;
  late DriftQiyamUnitOfWork unitOfWork;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    repository = DriftQiyamRepository(db);
    unitOfWork = DriftQiyamUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
  });

  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  QiyamSaveRequest request({
    String owner = 'owner',
    String nightDate = '2026-11-11',
    bool performed = true,
    int? rakahs = 4,
    bool witr = true,
    String? startTime = '22:10',
    String? endTime = '02:40',
    String? note = 'test note',
    required DateTime updatedAt,
    String operationId = 'op-1',
    DateTime? expectedCurrentVersion,
    DateTime? acknowledgedBase,
    bool queueForSync = true,
  }) {
    final recordId = identity.nightRecordId(nightDate);
    return QiyamSaveRequest(
      accountId: owner,
      nightDate: nightDate,
      recordId: recordId,
      performed: performed,
      rakahs: performed ? rakahs : null,
      witr: performed ? witr : false,
      startTime: performed ? startTime : null,
      endTime: performed ? endTime : null,
      note: performed ? note : null,
      recordedZoneId: 'UTC',
      recordedOffsetMinutes: 0,
      updatedAt: updatedAt,
      operationId: operationId,
      expectedCurrentVersion: expectedCurrentVersion,
      acknowledgedBase: acknowledgedBase,
      queueForSync: queueForSync,
    );
  }

  /// Seeds one stored row directly (no command, no outbox) for the
  /// streak-walk and history-page tests.
  Future<void> seed(
    String nightDate, {
    String owner = 'owner',
    bool performed = true,
    int? rakahs = 4,
  }) => db
      .into(db.qiyamNights)
      .insertOnConflictUpdate(
        _seedCompanion(
          nightDate,
          recordId: identity.nightRecordId(nightDate),
          owner: owner,
          performed: performed,
          rakahs: rakahs,
        ),
      );

  test('a performed save writes the record, the provisional award and the '
      'outbox entry, in one transaction', () async {
    final outcome = await unitOfWork.commit(
      request(updatedAt: DateTime.utc(2026, 11, 11, 20, 5)),
    );
    expect(outcome.failureOrNull, isNull);
    expect(outcome.valueOrNull!.wroteRecord, isTrue);
    expect(outcome.valueOrNull!.awardInserted, isTrue);

    final record = await repository
        .readFresh(accountId: 'owner', nightDate: '2026-11-11')
        .then((r) => r.valueOrNull!);
    expect(record.performed, isTrue);
    expect(record.rakahs, 4);
    expect(record.witr, isTrue);
    expect(record.startTime, '22:10');
    expect(record.endTime, '02:40');
    expect(record.note, 'test note');
    expect(record.recordId, identity.nightRecordId('2026-11-11'));

    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1));
    expect(award.single.source, kQiyamDoneAwardSource);
    expect(award.single.amount, 30);
    expect(award.single.sourceId, identity.nightRecordId('2026-11-11'));

    final outbox = await db.select(db.pendingChanges).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.entityType, 'qiyam_night');
    expect(outbox.single.entityId, identity.nightRecordId('2026-11-11'));
    final payload =
        jsonDecode(outbox.single.serializedChange) as Map<String, dynamic>;
    expect(payload['night_date'], '2026-11-11');
    expect(payload['performed'], isTrue);
    expect(payload['rakahs'], 4);
    expect(payload['witr'], isTrue);
    expect(payload['start_time'], '22:10');
    expect(payload['end_time'], '02:40');
    expect(payload['note'], 'test note');
    expect(payload['recorded_zone_id'], 'UTC');
    expect(payload['recorded_offset_minutes'], 0);
  });

  test(
    'a not-performed save writes the record and the outbox but no award',
    () async {
      final outcome = await unitOfWork.commit(
        request(performed: false, updatedAt: DateTime.utc(2026, 11, 11, 20, 5)),
      );
      expect(outcome.valueOrNull!.wroteRecord, isTrue);
      expect(outcome.valueOrNull!.awardInserted, isFalse);
      final record = await repository
          .readFresh(accountId: 'owner', nightDate: '2026-11-11')
          .then((r) => r.valueOrNull!);
      expect(record.performed, isFalse);
      expect(record.rakahs, isNull);
      expect(record.note, isNull);
      expect(await db.select(db.xpAwards).get(), isEmpty);
      expect(await db.select(db.pendingChanges).get(), hasLength(1));
    },
  );

  test('an edit while performed keeps exactly one award', () async {
    await unitOfWork.commit(
      request(updatedAt: DateTime.utc(2026, 11, 11, 20, 5)),
    );
    final outcome = await unitOfWork.commit(
      request(
        rakahs: 8,
        updatedAt: DateTime.utc(2026, 11, 11, 21),
        operationId: 'op-2',
        expectedCurrentVersion: DateTime.utc(2026, 11, 11, 20, 5),
      ),
    );
    expect(outcome.valueOrNull!.awardInserted, isFalse);
    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1), reason: 'awards are never duplicated');
    expect(
      (await repository
              .readFresh(accountId: 'owner', nightDate: '2026-11-11')
              .then((r) => r.valueOrNull!))
          .rakahs,
      8,
    );
  });

  test('Yes -> No -> Yes keeps exactly one award', () async {
    await unitOfWork.commit(
      request(updatedAt: DateTime.utc(2026, 11, 11, 20, 5)),
    );
    await unitOfWork.commit(
      request(
        performed: false,
        updatedAt: DateTime.utc(2026, 11, 11, 21),
        operationId: 'op-no',
        expectedCurrentVersion: DateTime.utc(2026, 11, 11, 20, 5),
      ),
    );
    final outcome = await unitOfWork.commit(
      request(
        updatedAt: DateTime.utc(2026, 11, 11, 22),
        operationId: 'op-yes-again',
        expectedCurrentVersion: DateTime.utc(2026, 11, 11, 21),
      ),
    );
    expect(outcome.valueOrNull!.awardInserted, isFalse);
    final award = await db.select(db.xpAwards).get();
    expect(award, hasLength(1), reason: 'the first Yes already earned it');
    final outbox = await db.select(db.pendingChanges).get();
    expect(outbox, hasLength(3));
  });

  test(
    'a failed commit (non-monotonic version) leaves nothing behind',
    () async {
      await unitOfWork.commit(
        request(updatedAt: DateTime.utc(2026, 11, 11, 21)),
      );
      final failure = await unitOfWork.commit(
        request(
          updatedAt: DateTime.utc(2026, 11, 11, 20, 5),
          operationId: 'op-stale',
        ),
      );
      expect(failure.failureOrNull, isNotNull);
      final record = await repository
          .readFresh(accountId: 'owner', nightDate: '2026-11-11')
          .then((r) => r.valueOrNull!);
      expect(record.updatedAt, DateTime.utc(2026, 11, 11, 21));
      expect(await db.select(db.pendingChanges).get(), hasLength(1));
      expect(await db.select(db.xpAwards).get(), hasLength(1));
    },
  );

  test('reads and writes are isolated per owner', () async {
    await unitOfWork.commit(
      request(updatedAt: DateTime.utc(2026, 11, 11, 20, 5)),
    );
    final other = await unitOfWork.commit(
      request(
        owner: 'other',
        updatedAt: DateTime.utc(2026, 11, 11, 20, 5),
        operationId: 'op-other',
      ),
    );
    expect(other.failureOrNull, isNull);
    final ownerRecord = await repository
        .watchNight(accountId: 'owner', nightDate: '2026-11-11')
        .first;
    expect(ownerRecord, isNotNull);
    expect(ownerRecord!.accountId, 'owner');
    final otherRecord = await repository
        .readFresh(accountId: 'other', nightDate: '2026-11-11')
        .then((r) => r.valueOrNull!);
    expect(otherRecord.accountId, 'other');
  });

  group('streak (T052)', () {
    test(
      'counts consecutive performed nights and stops at the first break',
      () async {
        await seed('2026-11-11');
        await seed('2026-11-10');
        await seed('2026-11-09');
        await seed('2026-11-08', performed: false);
        await seed('2026-11-07');

        final result = await repository.streak(
          accountId: 'owner',
          currentNight: '2026-11-11',
        );
        expect(result.valueOrNull, 3, reason: 'the explicit No ends the walk');
      },
    );

    test('an explicit No tonight does not break the run, like an unanswered '
        'current night (owner decision, 2026-11-12)', () async {
      await seed('2026-11-10');
      await seed('2026-11-09');

      final noTonight = await repository.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      expect(noTonight.valueOrNull, 2);

      await seed('2026-11-11', performed: false);
      final explicitNo = await repository.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      expect(explicitNo.valueOrNull, 2, reason: 'tonight stays editable');
    });

    test('is isolated per owner', () async {
      await seed('2026-11-11');
      await seed('2026-11-11', owner: 'other');
      final result = await repository.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      expect(result.valueOrNull, 1);
    });

    test('is capped at 3,650 visited nights', () async {
      // 3,652 performed nights: without the cap the walk would count them
      // all; with it, the streak stops at 3,650.
      const total = 3652;
      final companions = <QiyamNightsCompanion>[
        for (var i = 0; i < total; i++)
          _seedCompanion(
            _offsetDay(2026, 11, 11, i),
            recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
          ),
      ];
      await db.batch((batch) => batch.insertAll(db.qiyamNights, companions));

      final result = await repository.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      expect(result.valueOrNull, 3650);
    });

    test('a 300-night streak reads in batches — a handful of queries, not '
        'one per night', () async {
      await db.close();
      final batchTemp = TemporaryDatabasePath();
      final counter = _SelectCounter();
      final counted = await FoundationDatabase.openEncrypted(
        path: batchTemp.allocate(),
        key: key,
        interceptor: counter,
      );
      final countedRepo = DriftQiyamRepository(counted);
      const total = 300;
      await counted.batch(
        (batch) => batch.insertAll(counted.qiyamNights, [
          for (var i = 1; i <= total; i++)
            _seedCompanion(
              _offsetDay(2026, 11, 11, i),
              recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
            ),
        ]),
      );

      final before = counter.selects;
      final result = await countedRepo.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      final used = counter.selects - before;
      expect(result.valueOrNull, 300);
      expect(
        used,
        lessThanOrEqualTo(8),
        reason:
            'the walk reads descending batches of rows; one query per '
            'night would need 300+',
      );
      await counted.close();
      batchTemp.dispose();
    });
  });

  group('history (T052, review finding 1)', () {
    test('one page of 30 recorded rows, newest first; hasMore only when an '
        'older row exists', () async {
      // With fewer rows than the page holds, nothing older exists. The
      // two rows sit outside the 35-night cluster seeded below.
      await seed(_offsetDay(2026, 11, 11, 40));
      await seed(_offsetDay(2026, 11, 11, 41), performed: false);
      final short = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(short.valueOrNull!.records, hasLength(2));
      expect(short.valueOrNull!.records[0].performed, isTrue);
      expect(short.valueOrNull!.records[1].performed, isFalse);
      expect(short.valueOrNull!.hasMore, isFalse);

      // 35 consecutive recorded nights: the first page holds 30 rows and
      // an older row exists.
      const newest = 35;
      await db.batch(
        (batch) => batch.insertAll(db.qiyamNights, [
          for (var i = 1; i <= newest; i++)
            _seedCompanion(
              _offsetDay(2026, 11, 11, i),
              recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
            ),
        ]),
      );

      final full = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(full.valueOrNull!.records, hasLength(30));
      expect(full.valueOrNull!.records.first.nightDate, '2026-11-10');
      expect(full.valueOrNull!.records.first.performed, isTrue);
      expect(full.valueOrNull!.records.last.nightDate, '2026-10-12');
      expect(full.valueOrNull!.hasMore, isTrue);
    });

    test('a 40-night gap still reaches the older records', () async {
      // Ten recorded nights, then 40 nights with nothing, then ten more:
      // one page reaches both clusters because pages count recorded rows,
      // not calendar windows (2026-09-21 .. 2026-10-31 holds no row).
      final companions = <QiyamNightsCompanion>[
        for (var i = 1; i <= 10; i++)
          _seedCompanion(
            _offsetDay(2026, 11, 11, i),
            recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
          ),
        for (var i = 51; i <= 60; i++)
          _seedCompanion(
            _offsetDay(2026, 11, 11, i),
            recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
          ),
      ];
      await db.batch((batch) => batch.insertAll(db.qiyamNights, companions));

      final page = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(page.valueOrNull!.records, hasLength(20));
      expect(page.valueOrNull!.records.first.nightDate, '2026-11-10');
      expect(page.valueOrNull!.records.last.nightDate, '2026-09-12');
      expect(page.valueOrNull!.hasMore, isFalse);

      // The review's Ramadan shape: a full 30-row newest cluster leaves the
      // rows behind the gap exactly one "Load more" away — the gap never
      // hides them.
      await db.close();
      final gapTemp = TemporaryDatabasePath();
      final fullCluster = await FoundationDatabase.openEncrypted(
        path: gapTemp.allocate(),
        key: key,
      );
      await fullCluster.batch(
        (batch) => batch.insertAll(fullCluster.qiyamNights, [
          for (var i = 1; i <= 30; i++)
            _seedCompanion(
              _offsetDay(2026, 11, 11, i),
              recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, i)),
            ),
          _seedCompanion(
            _offsetDay(2026, 11, 11, 71),
            recordId: identity.nightRecordId(_offsetDay(2026, 11, 11, 71)),
          ),
        ]),
      );
      final fullRepo = DriftQiyamRepository(fullCluster);
      final page1 = await fullRepo.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(page1.valueOrNull!.records, hasLength(30));
      expect(page1.valueOrNull!.records.last.nightDate, '2026-10-12');
      expect(page1.valueOrNull!.hasMore, isTrue);
      final page2 = await fullRepo.history(
        accountId: 'owner',
        before: page1.valueOrNull!.records.last.nightDate,
      );
      expect(page2.valueOrNull!.records, hasLength(1));
      expect(page2.valueOrNull!.records.single.nightDate, '2026-09-01');
      expect(page2.valueOrNull!.hasMore, isFalse);
      await fullCluster.close();
      gapTemp.dispose();
    });

    test('a new user sees an empty page', () async {
      final page = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(page.valueOrNull!.records, isEmpty);
      expect(page.valueOrNull!.hasMore, isFalse);
    });

    test('is isolated per owner', () async {
      await seed('2026-11-10', owner: 'other');
      final result = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(result.valueOrNull!.records, isEmpty);

      final other = await repository.history(
        accountId: 'other',
        before: '2026-11-11',
      );
      expect(other.valueOrNull!.records.single.accountId, 'other');
    });

    test('a storage failure is a failure, never an empty page or a streak '
        'of 0', () async {
      // A closed store is the failure case: the reads must report a
      // failure, not "no record", an empty page or a streak of 0.
      await db.close();

      final streak = await repository.streak(
        accountId: 'owner',
        currentNight: '2026-11-11',
      );
      expect(streak.failureOrNull, isNotNull);
      expect(streak.valueOrNull, isNull);

      final history = await repository.history(
        accountId: 'owner',
        before: '2026-11-11',
      );
      expect(history.failureOrNull, isNotNull);
      expect(history.valueOrNull, isNull);
    });
  });
}

String _offsetDay(int year, int month, int day, int backDays) {
  final date = DateTime.utc(
    year,
    month,
    day,
  ).subtract(Duration(days: backDays));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

QiyamNightsCompanion _seedCompanion(
  String nightDate, {
  required String recordId,
  String owner = 'owner',
  bool performed = true,
  int? rakahs = 4,
}) => QiyamNightsCompanion.insert(
  accountId: owner,
  nightDate: nightDate,
  recordId: recordId,
  performed: performed,
  rakahs: Value(performed ? rakahs : null),
  witr: performed,
  startTime: Value(performed ? '01:00' : null),
  endTime: Value(performed ? '02:00' : null),
  note: const Value(null),
  recordedZoneId: 'UTC',
  recordedOffsetMinutes: 0,
  createdAt: DateTime.utc(2026, 11, 11, 20).toIso8601String(),
  updatedAt: DateTime.utc(2026, 11, 11, 20).toIso8601String(),
);

/// Counts executed SELECT statements through the test-only interceptor hook
/// of `FoundationDatabase.openEncrypted` (Phase 5 review finding 3).
final class _SelectCounter extends QueryInterceptor {
  int selects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    selects++;
    return super.runSelect(executor, statement, args);
  }
}
