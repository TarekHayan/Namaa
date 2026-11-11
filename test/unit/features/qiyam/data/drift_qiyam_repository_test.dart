import 'dart:convert';

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
}
