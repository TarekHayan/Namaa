import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/data/local/qiyam_unit_of_work.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/qiyam_inbound_synchronizer.dart';
import 'package:namma_project/features/qiyam/data/qiyam_reconciler.dart';
import 'package:namma_project/features/qiyam/data/qiyam_remote_models.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_reader.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/foundation_test_support.dart';

/// T063: the Qiyam inbound synchronizer — the same contract as the Adhkar
/// one, over night records and the `qiyam_done` award.
void main() {
  final identity = const UuidQiyamIdentity();
  final night = '2026-11-11';

  late FoundationDatabase db;
  late DriftQiyamRepository repository;
  late DriftQiyamUnitOfWork unitOfWork;
  late DriftAwardLedger ledger;
  late FakeQiyamReader reader;
  late QiyamInboundSynchronizer synchronizer;
  late TemporaryDatabasePath temp;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 80),
    );
    repository = DriftQiyamRepository(db);
    unitOfWork = DriftQiyamUnitOfWork(
      database: db,
      repository: repository,
      awards: DriftAwardLedger(db),
    );
    ledger = DriftAwardLedger(db);
    reader = FakeQiyamReader();
    synchronizer = QiyamInboundSynchronizer(
      reader: reader,
      reconciler: QiyamReconciler(
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

  QiyamNightRecord remoteNight({
    required bool performed,
    required DateTime at,
    String owner = 'owner',
  }) => QiyamNightRecord(
    accountId: owner,
    nightDate: night,
    recordId: identity.nightRecordId(night),
    performed: performed,
    rakahs: performed ? 8 : null,
    witr: performed,
    startTime: performed ? '23:00' : null,
    endTime: performed ? '01:30' : null,
    note: performed ? 'inbound note' : null,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: at,
    updatedAt: at,
    lastAcknowledgedUpdatedAt: null,
  );

  test('imports pages; a failed page applies nothing and the next pass '
      'restarts from the start', () async {
    final at = DateTime.utc(2026, 11, 11, 20);
    reader
      ..pages = [
        [remoteNight(performed: true, at: at)],
      ]
      ..failPageIndex = 0;

    final failed = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(failed.failureOrNull, isNotNull);
    expect(
      await repository
          .readFresh(accountId: 'owner', nightDate: night)
          .then((r) => r.valueOrNull),
      isNull,
    );

    reader.failPageIndex = null;
    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(result.valueOrNull!.importedNights, 1);
    expect(
      await repository
          .readFresh(accountId: 'owner', nightDate: night)
          .then((r) => r.valueOrNull!.performed),
      isTrue,
    );
  });

  test('the qiyam_done award settles once by (source, sourceId)', () async {
    final at = DateTime.utc(2026, 11, 11, 20);
    await unitOfWork.commit(
      QiyamSaveRequest(
        accountId: 'owner',
        nightDate: night,
        recordId: identity.nightRecordId(night),
        performed: true,
        rakahs: 4,
        witr: true,
        startTime: '22:10',
        endTime: '02:40',
        note: 'local note',
        recordedZoneId: 'UTC',
        recordedOffsetMinutes: 0,
        updatedAt: at,
        operationId: 'op-1',
        expectedCurrentVersion: null,
        acknowledgedBase: null,
        queueForSync: false,
      ),
    );
    reader.awards = [
      XpAward(
        accountId: 'owner',
        source: kQiyamDoneAwardSource,
        sourceId: identity.nightRecordId(night),
        amount: 30,
        awardedAt: DateTime.utc(2026, 11, 11, 20, 30),
      ),
    ];
    final result = await synchronizer.receive(
      accountId: 'owner',
      isCurrentScope: () => true,
    );
    expect(result.valueOrNull!.importedAwards, 1);
    expect(await db.select(db.xpAwards).get(), hasLength(1));
    await synchronizer.receive(accountId: 'owner', isCurrentScope: () => true);
    expect(await db.select(db.xpAwards).get(), hasLength(1));
  });

  test(
    'conflicts upsert by their stable id; a foreign owner fails the pass',
    () async {
      final at = DateTime.utc(2026, 11, 11, 20);
      final active = remoteNight(performed: true, at: at);
      final retained = remoteNight(
        performed: false,
        at: DateTime.utc(2026, 11, 11, 19),
      );
      reader.conflicts = [
        QiyamRemoteConflict(
          id: 'qy-conflict-stable',
          active: active,
          retained: retained,
          detectedAt: DateTime.utc(2026, 11, 11, 21),
        ),
      ];
      await synchronizer.receive(
        accountId: 'owner',
        isCurrentScope: () => true,
      );
      expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);

      reader.nights = [
        remoteNight(performed: true, at: at, owner: 'foreign-owner'),
      ];
      final foreign = await synchronizer.receive(
        accountId: 'owner',
        isCurrentScope: () => true,
      );
      expect(foreign.failureOrNull, isNotNull);
      expect(await db.rawScalar('SELECT count(*) FROM conflict_records'), 1);
    },
  );
}

final class FakeQiyamReader implements QiyamRemoteReader {
  List<List<QiyamNightRecord>> pages = const [];
  List<QiyamNightRecord> nights = const [];
  List<XpAward> awards = const [];
  List<QiyamRemoteConflict> conflicts = const [];
  int? failPageIndex;

  @override
  Future<QiyamRemoteSnapshot> readAll(String accountId) async {
    final collected = <QiyamNightRecord>[];
    for (var i = 0; i < pages.length; i++) {
      if (failPageIndex == i) {
        throw StateError('page $i failed');
      }
      collected.addAll(pages[i]);
    }
    collected.addAll(nights);
    return QiyamRemoteSnapshot(
      nights: List.unmodifiable(collected),
      awards: List.unmodifiable(awards),
      conflicts: List.unmodifiable(conflicts),
    );
  }
}
