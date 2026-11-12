import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/local/adhkar_unit_of_work.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/data/local/qiyam_unit_of_work.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/adhkar_inbound_synchronizer.dart';
import 'package:namma_project/features/adhkar/data/adhkar_reconciler.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_gateway.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_reader.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_sync_adapter.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/qiyam_inbound_synchronizer.dart';
import 'package:namma_project/features/qiyam/data/qiyam_reconciler.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_gateway.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_reader.dart';
import 'package:namma_project/features/qiyam/data/supabase_qiyam_sync_adapter.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/test_environment.dart';

/// T066: two encrypted stores against the LOCAL Supabase stack — receipts,
/// one visible conflict, one award per set and per night, a lost ACK with a
/// restart, duplicate inbound passes and owner isolation. The local catalog
/// fixture (catalog version 900, IDs and targets only, no text) comes from
/// `supabase/seed.sql` after `supabase db reset`; the pgTAP tests own
/// version 1 and seed it inside their own transactions, so the two never
/// collide. Hosted runs use the isolated staging credentials and never
/// touch production.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two encrypted devices converge, replay and retain awards', (
    tester,
  ) async {
    final environment = resolveTestSupabaseEnvironment();
    const localKey = String.fromEnvironment(
      'NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY',
    );
    const stagingUrl = String.fromEnvironment('NAMAA_SUPABASE_URL');
    const stagingKey = String.fromEnvironment('NAMAA_SUPABASE_PUBLISHABLE_KEY');
    const emailA = String.fromEnvironment('NAMAA_STAGING_TEST_USER_A_EMAIL');
    const passwordA = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_A_PASSWORD',
    );
    const emailB = String.fromEnvironment('NAMAA_STAGING_TEST_USER_B_EMAIL');
    const passwordB = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_B_PASSWORD',
    );
    final local = environment == SupabaseEnvironmentKind.localStack;
    late final SupabaseEnvironmentConfig config;
    if (local) {
      if (localKey.isEmpty) fail('Local Supabase publishable key is required');
      config = SupabaseEnvironmentConfig.localStack(
        url: requireLocalStackUrl(kSupabaseLocalUrl),
        publishableKey: localKey,
      );
    } else {
      for (final value in [
        stagingUrl,
        stagingKey,
        emailA,
        passwordA,
        emailB,
        passwordB,
      ]) {
        if (value.isEmpty) fail('Isolated staging credentials are required');
      }
      final uri = Uri.parse(stagingUrl);
      config = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: uri,
        publishableKey: stagingKey,
        approvedHosts: {uri.host},
      );
    }
    // Implicit auth: this isolated test owns its clients end to end.
    SupabaseClient testClient() => SupabaseClient(
      config.url.toString(),
      config.publishableKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final clients = <SupabaseClient>[testClient(), testClient(), testClient()];
    final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
    final databasePaths = [for (final path in paths) path.allocate()];
    final dbs = <FoundationDatabase>[];
    addTearDown(() async {
      for (final db in dbs) {
        await db.close();
      }
      for (final path in paths) {
        path.dispose();
      }
      for (final client in clients) {
        await client.dispose();
      }
    });
    const password = 'LocalAdhkarQiyamIntegration2026!';
    late final String owner;
    late final String ownerB;
    if (local) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final signup = await clients[0].auth.signUp(
        email: 'adhkar-qiyam-$stamp@example.test',
        password: password,
      );
      if (signup.session == null || signup.user == null) {
        fail('Local Supabase did not create an authenticated test session');
      }
      owner = signup.user!.id;
      await clients[1].auth.signInWithPassword(
        email: 'adhkar-qiyam-$stamp@example.test',
        password: password,
      );
      // Owner B exists only to prove isolation.
      final signupB = await clients[2].auth.signUp(
        email: 'adhkar-qiyam-b-$stamp@example.test',
        password: password,
      );
      if (signupB.session == null || signupB.user == null) {
        fail('Local Supabase did not create the second test owner');
      }
      ownerB = signupB.user!.id;
    } else {
      owner = (await clients[0].auth.signInWithPassword(
        email: emailA,
        password: passwordA,
      )).user!.id;
      await clients[1].auth.signInWithPassword(
        email: emailA,
        password: passwordA,
      );
      ownerB = (await clients[2].auth.signInWithPassword(
        email: emailB,
        password: passwordB,
      )).user!.id;
    }

    for (var i = 0; i < 2; i++) {
      dbs.add(
        await FoundationDatabase.openEncrypted(
          path: databasePaths[i],
          key: List<int>.generate(32, (j) => j + 40 + i),
        ),
      );
    }
    final adhkarStores = [for (final db in dbs) DriftAdhkarRepository(db)];
    final qiyamStores = [for (final db in dbs) DriftQiyamRepository(db)];
    final adhkarWork = [
      for (var i = 0; i < 2; i++)
        DriftAdhkarUnitOfWork(
          database: dbs[i],
          repository: adhkarStores[i],
          awards: DriftAwardLedger(dbs[i]),
        ),
    ];
    final qiyamWork = [
      for (var i = 0; i < 2; i++)
        DriftQiyamUnitOfWork(
          database: dbs[i],
          repository: qiyamStores[i],
          awards: DriftAwardLedger(dbs[i]),
        ),
    ];
    final adhkarAdapters = [
      for (var i = 0; i < 2; i++)
        SupabaseAdhkarSyncAdapter(
          gateway: SupabaseAdhkarGatewayImpl(clients[i]),
          repository: adhkarStores[i],
        ),
    ];
    final qiyamAdapters = [
      for (var i = 0; i < 2; i++)
        SupabaseQiyamSyncAdapter(
          gateway: SupabaseQiyamGatewayImpl(clients[i]),
          repository: qiyamStores[i],
        ),
    ];
    // Device 0's inbound synchronizer (a one-row page exercises every keyset
    // cursor and its restart).
    final adhkarInbound0 = AdhkarInboundSynchronizer(
      reader: SupabaseAdhkarReader(clients[0], pageSize: 1),
      reconciler: AdhkarReconciler(
        repository: adhkarStores[0],
        localStore: DriftLocalStore(dbs[0]),
        awards: DriftAwardLedger(dbs[0]),
      ),
    );

    // The local catalog fixture (version 900) must exist for the RPCs; it
    // comes from supabase/seed.sql after `supabase db reset`.
    final catalog = await clients[0]
        .from('adhkar_catalog_items')
        .select()
        .eq('catalog_version', 900);
    if (catalog.isEmpty) {
      fail(
        'Local catalog fixture missing: run `supabase db reset` so '
        'supabase/seed.sql provides catalog version 900.',
      );
    }

    // The test is rerunnable on every stack: a random past day (the server
    // rejects a day more than two days ahead) and a run-tagged operation ID,
    // so repeated runs and shared accounts never collide (Phase 6 review
    // finding 4).
    final fixtureDay = DateTime.utc(
      1000,
    ).add(Duration(days: Random.secure().nextInt(365000)));
    String isoDay(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final day = isoDay(fixtureDay);
    final night = isoDay(fixtureDay);
    final runTag = '-${Random.secure().nextInt(1 << 32).toRadixString(16)}';
    String op(String name) => '$name$runTag';
    // Every version sits inside its record's server window [day - 1, day + 2)
    // in UTC.
    DateTime at(int minutes) => DateTime.utc(
      fixtureDay.year,
      fixtureDay.month,
      fixtureDay.day,
    ).add(Duration(minutes: minutes));

    final identity = const UuidAdhkarIdentity();
    final qiyamIdentity = const UuidQiyamIdentity();
    const catalogVersion = 900;
    final setSourceId = identity.setAwardSourceId(day, 'morning');

    Future<OutboundChange> pending(int device, String operationId) async {
      final rows = (await DriftLocalStore(
        dbs[device],
      ).readPendingChanges(owner)).valueOrNull!;
      final row = rows.singleWhere((value) => value.operationId == operationId);
      return OutboundChange(
        operationId: row.operationId,
        accountId: owner,
        entityType: row.entityType,
        entityId: row.entityId,
        kind: row.kind,
        payload: row.serializedChange,
        versionTimestamp: row.versionTimestamp,
        baseUpdatedAt: row.baseUpdatedAt,
      );
    }

    Future<void> dispatchAdhkar(
      int device,
      OutboundChange change, {
      bool acknowledge = true,
    }) async {
      final result = await adhkarAdapters[device].dispatchChange(change);
      expect(result.failureOrNull, isNull, reason: change.operationId);
      final ack = result.valueOrNull;
      expect(ack, isA<DispatchAcknowledged>());
      if (acknowledge) {
        expect(
          (await DriftLocalStore(dbs[device]).acknowledgeChange(
            change.operationId,
            (ack as DispatchAcknowledged).acknowledgementId,
            ack.remoteVersionTimestamp!,
          )).failureOrNull,
          isNull,
        );
      }
    }

    Future<void> dispatchQiyam(
      int device,
      OutboundChange change, {
      bool acknowledge = true,
    }) async {
      final result = await qiyamAdapters[device].dispatchChange(change);
      expect(result.failureOrNull, isNull, reason: change.operationId);
      final ack = result.valueOrNull;
      expect(ack, isA<DispatchAcknowledged>());
      if (acknowledge) {
        expect(
          (await DriftLocalStore(dbs[device]).acknowledgeChange(
            change.operationId,
            (ack as DispatchAcknowledged).acknowledgementId,
            ack.remoteVersionTimestamp!,
          )).failureOrNull,
          isNull,
        );
      }
    }

    AdhkarCommitRequest adhkarCommit({
      required String itemId,
      required int count,
      required DateTime at,
      required String operationId,
      DateTime? expectedCurrentVersion,
    }) => AdhkarCommitRequest(
      accountId: owner,
      adhkarDay: day,
      itemId: itemId,
      recordId: identity.itemRecordId(day, itemId),
      catalogVersion: catalogVersion,
      list: itemId.startsWith('m') ? 'morning' : 'evening',
      newCount: count,
      updatedAt: at,
      operationId: operationId,
      expectedCurrentVersion: expectedCurrentVersion,
      acknowledgedBase: null,
      queueForSync: true,
      listItems: const [
        AdhkarListItem(itemId: 'm1', target: 1),
        AdhkarListItem(itemId: 'm2', target: 3),
        AdhkarListItem(itemId: 'm3', target: 10),
      ],
      setAwardSourceId: setSourceId,
    );

    QiyamSaveRequest qiyamCommit({
      required bool performed,
      required DateTime at,
      required String operationId,
      DateTime? expectedCurrentVersion,
    }) => QiyamSaveRequest(
      accountId: owner,
      nightDate: night,
      recordId: qiyamIdentity.nightRecordId(night),
      performed: performed,
      rakahs: performed ? 4 : null,
      witr: performed,
      startTime: performed ? '22:10' : null,
      endTime: performed ? '02:40' : null,
      note: performed ? 'integration note' : null,
      recordedZoneId: 'UTC',
      recordedOffsetMinutes: 0,
      updatedAt: at,
      operationId: operationId,
      expectedCurrentVersion: expectedCurrentVersion,
      acknowledgedBase: null,
      queueForSync: true,
    );

    Future<int> awardCount(String forOwner) async {
      final rows = await clients[0]
          .from('xp_awards')
          .select()
          .eq('owner', forOwner);
      return rows.length;
    }

    // --------------------------------------------------------------------
    // Case 2: the same item on both stores diverges into ONE visible
    // conflict with a stable id.
    // --------------------------------------------------------------------
    expect(
      (await adhkarWork[0].commit(
        adhkarCommit(
          itemId: 'm3',
          count: 5,
          at: at(30),
          operationId: op('adhkar-m3-a'),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchAdhkar(0, await pending(0, op('adhkar-m3-a')));
    expect(
      (await adhkarWork[1].commit(
        adhkarCommit(
          itemId: 'm3',
          count: 7,
          at: at(60),
          operationId: op('adhkar-m3-b'),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchAdhkar(1, await pending(1, op('adhkar-m3-b')));
    final conflictsA = await clients[0]
        .from('adhkar_conflicts')
        .select()
        .eq('owner', owner)
        .eq('item_id', 'm3');
    expect(conflictsA, hasLength(1), reason: 'one stable conflict');
    expect((conflictsA.single as Map)['conflict_id'], isNotEmpty);

    // The inbound pass imports the conflict evidence once; a duplicate pass
    // imports nothing more (case 5: duplicate inbound records).
    final firstPass = await adhkarInbound0.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(firstPass.valueOrNull!.importedConflicts, 1);
    final duplicatePass = await adhkarInbound0.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(duplicatePass.valueOrNull!.importedConflicts, 0);
    expect(await dbs[0].rawScalar('SELECT count(*) FROM conflict_records'), 1);

    // --------------------------------------------------------------------
    // Case 1: different items from the two devices complete the set, and
    // the 15 XP award is inserted exactly once.
    // --------------------------------------------------------------------
    expect(
      await awardCount(owner),
      0,
      reason: 'no award before the set completes',
    );
    expect(
      (await adhkarWork[0].commit(
        adhkarCommit(
          itemId: 'm1',
          count: 1,
          at: at(90),
          operationId: op('adhkar-m1-a'),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchAdhkar(0, await pending(0, op('adhkar-m1-a')));
    expect(
      (await adhkarWork[1].commit(
        adhkarCommit(
          itemId: 'm2',
          count: 3,
          at: at(120),
          operationId: op('adhkar-m2-b'),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchAdhkar(1, await pending(1, op('adhkar-m2-b')));
    // Device A pulls the server version for m3 (its base is stale), then
    // completes the set at the target.
    final m3Base = await SupabaseAdhkarGatewayImpl(clients[0]).fetchCount(
      expectedAccountId: owner,
      recordId: identity.itemRecordId(day, 'm3'),
    );
    expect(m3Base, isNotNull);
    expect(
      (await adhkarWork[0].commit(
        adhkarCommit(
          itemId: 'm3',
          count: 10,
          at: at(150),
          operationId: op('adhkar-m3-final'),
          expectedCurrentVersion: m3Base!.updatedAt,
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchAdhkar(0, await pending(0, op('adhkar-m3-final')));
    final setAwards = await clients[0]
        .from('xp_awards')
        .select()
        .eq('owner', owner)
        .eq('source', 'adhkar_set_done');
    expect(setAwards, hasLength(1), reason: 'one award for the whole set');
    expect((setAwards.single as Map)['source_id'], setSourceId);

    // The canonical award settles the local provisional replica once.
    final settlePass = await adhkarInbound0.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(settlePass.valueOrNull!.importedAwards, 1);
    final localAward = await DriftAwardLedger(dbs[0]).readSharedAward(
      accountId: owner,
      source: kAdhkarSetDoneAwardSource,
      sourceId: setSourceId,
    );
    expect(localAward.valueOrNull, isNotNull);

    // --------------------------------------------------------------------
    // Case 3: Qiyam Yes -> No -> Yes gives exactly one 30 XP award.
    // --------------------------------------------------------------------
    expect(
      (await qiyamWork[0].commit(
        qiyamCommit(
          performed: true,
          at: at(200),
          operationId: op('qiyam-yes-1'),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchQiyam(0, await pending(0, op('qiyam-yes-1')));
    expect(
      (await qiyamWork[0].commit(
        qiyamCommit(
          performed: false,
          at: at(210),
          operationId: op('qiyam-no'),
          expectedCurrentVersion: at(200),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchQiyam(0, await pending(0, op('qiyam-no')));
    expect(
      (await qiyamWork[0].commit(
        qiyamCommit(
          performed: true,
          at: at(220),
          operationId: op('qiyam-yes-2'),
          expectedCurrentVersion: at(210),
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchQiyam(0, await pending(0, op('qiyam-yes-2')));
    final nightAwards = await clients[0]
        .from('xp_awards')
        .select()
        .eq('owner', owner)
        .eq('source', 'qiyam_done');
    expect(nightAwards, hasLength(1), reason: 'Yes -> No -> Yes, one award');
    expect(
      (nightAwards.single as Map)['source_id'],
      qiyamIdentity.nightRecordId(night),
    );
    final awardsBeforeReplay = await awardCount(owner);

    // --------------------------------------------------------------------
    // Case 4: a lost ACK — the dispatch succeeds but the local
    // acknowledgement is lost; the retry replays the receipt (replayed=true,
    // no second remote effect), then acknowledges durably.
    // --------------------------------------------------------------------
    final serverNight = await SupabaseQiyamGatewayImpl(clients[1]).fetchNight(
      expectedAccountId: owner,
      recordId: qiyamIdentity.nightRecordId(night),
    );
    expect(serverNight, isNotNull);
    expect(
      (await qiyamWork[1].commit(
        QiyamSaveRequest(
          accountId: owner,
          nightDate: night,
          recordId: qiyamIdentity.nightRecordId(night),
          performed: false,
          rakahs: null,
          witr: false,
          startTime: null,
          endTime: null,
          note: null,
          recordedZoneId: 'UTC',
          recordedOffsetMinutes: 0,
          updatedAt: at(230),
          operationId: op('qiyam-lost-ack'),
          expectedCurrentVersion: serverNight!.updatedAt,
          acknowledgedBase: null,
          queueForSync: true,
        ),
      )).failureOrNull,
      isNull,
    );
    await dispatchQiyam(
      1,
      await pending(1, op('qiyam-lost-ack')),
      acknowledge: false,
    );
    await dispatchQiyam(1, await pending(1, op('qiyam-lost-ack')));
    expect(
      await awardCount(owner),
      awardsBeforeReplay,
      reason: 'the replay grants nothing new',
    );
    expect(
      (await DriftLocalStore(dbs[1]).readPendingChanges(
        owner,
      )).valueOrNull!.any((row) => row.operationId == op('qiyam-lost-ack')),
      isFalse,
      reason: 'the ACK is durable after the retry',
    );

    // Device 1 pulls the nights it has never seen; a duplicate inbound pass
    // imports nothing new.
    final qiyamPull = QiyamInboundSynchronizer(
      reader: SupabaseQiyamReader(clients[1], pageSize: 1),
      reconciler: QiyamReconciler(
        repository: qiyamStores[1],
        localStore: DriftLocalStore(dbs[1]),
        awards: DriftAwardLedger(dbs[1]),
      ),
    );
    final pullResult = await qiyamPull.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(pullResult.valueOrNull!.importedNights, greaterThanOrEqualTo(1));
    final duplicateNightPass = await qiyamPull.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(duplicateNightPass.valueOrNull!.importedNights, 0);

    // --------------------------------------------------------------------
    // Case 6: owner B is isolated — its rows never appear in owner A's
    // store, and every returned row carries the signed-in owner.
    // --------------------------------------------------------------------
    final ownerBRequest = AdhkarCommitRequest(
      accountId: ownerB,
      adhkarDay: day,
      itemId: 'm1',
      recordId: identity.itemRecordId(day, 'm1'),
      catalogVersion: catalogVersion,
      list: 'morning',
      newCount: 1,
      updatedAt: at(240),
      operationId: op('adhkar-b-1'),
      expectedCurrentVersion: null,
      acknowledgedBase: null,
      queueForSync: true,
      listItems: const [
        AdhkarListItem(itemId: 'm1', target: 1),
        AdhkarListItem(itemId: 'm2', target: 3),
        AdhkarListItem(itemId: 'm3', target: 10),
      ],
      setAwardSourceId: identity.setAwardSourceId(day, 'morning'),
    );
    expect(
      (await DriftAdhkarUnitOfWork(
        database: dbs[1],
        repository: DriftAdhkarRepository(dbs[1]),
        awards: DriftAwardLedger(dbs[1]),
      ).commit(ownerBRequest)).failureOrNull,
      isNull,
    );
    final ownerBRows = (await DriftLocalStore(
      dbs[1],
    ).readPendingChanges(ownerB)).valueOrNull!;
    final ownerBRow = ownerBRows.singleWhere(
      (value) => value.operationId == op('adhkar-b-1'),
    );
    final ownerBResult =
        await SupabaseAdhkarSyncAdapter(
          gateway: SupabaseAdhkarGatewayImpl(clients[2]),
          repository: DriftAdhkarRepository(dbs[1]),
        ).dispatchChange(
          OutboundChange(
            operationId: ownerBRow.operationId,
            accountId: ownerB,
            entityType: ownerBRow.entityType,
            entityId: ownerBRow.entityId,
            kind: ownerBRow.kind,
            payload: ownerBRow.serializedChange,
            versionTimestamp: ownerBRow.versionTimestamp,
            baseUpdatedAt: ownerBRow.baseUpdatedAt,
          ),
        );
    expect(ownerBResult.failureOrNull, isNull);

    // Owner A's inbound snapshot carries nothing of owner B's, and every
    // row the server returns to A carries A as the owner.
    final ownerAAfter = await adhkarInbound0.receive(
      accountId: owner,
      isCurrentScope: () => true,
    );
    expect(ownerAAfter.valueOrNull!.importedCounts, 0);
    final ownerACounts = await clients[0]
        .from('adhkar_item_counts')
        .select()
        .eq('owner', owner);
    for (final row in ownerACounts) {
      expect((row as Map)['owner'], owner);
    }
    expect(
      await DriftAwardLedger(dbs[0])
          .readSharedAward(
            accountId: owner,
            source: kAdhkarSetDoneAwardSource,
            sourceId: identity.setAwardSourceId(day, 'morning'),
          )
          .then((r) => r.valueOrNull),
      isNotNull,
      reason: 'owner A keeps exactly its own settled award',
    );
  });
}
