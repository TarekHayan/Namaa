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
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/data/adhkar_inbound_synchronizer.dart';
import 'package:namma_project/features/adhkar/data/adhkar_reconciler.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_inbound_synchronizer.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_reconciler.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_gateway.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_reader.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_sync_adapter.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_gateway.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_reader.dart';
import 'package:namma_project/features/adhkar/data/supabase_my_adhkar_sync_adapter.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
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
      DateTime? acknowledgedBase,
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
      acknowledgedBase: acknowledgedBase,
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
      DateTime? acknowledgedBase,
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
      acknowledgedBase: acknowledgedBase,
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
    // The summary counts every conflict the pass applied (as Prayer does);
    // the upsert by stable id is proven by the row count staying at one.
    expect(duplicatePass.failureOrNull, isNull);
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
    // The inbound pass already imported that version on device A, so the
    // command's preconditions are the local row's current and acknowledged
    // versions (the same values the Cubit passes).
    final m3Local = (await adhkarStores[0].readFresh(
      accountId: owner,
      adhkarDay: day,
      itemId: 'm3',
    )).valueOrNull;
    expect(m3Local?.updatedAt, m3Base!.updatedAt);
    expect(
      (await adhkarWork[0].commit(
        adhkarCommit(
          itemId: 'm3',
          count: 10,
          at: at(150),
          operationId: op('adhkar-m3-final'),
          expectedCurrentVersion: m3Local!.updatedAt,
          acknowledgedBase: m3Local.lastAcknowledgedUpdatedAt,
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
          // Each dispatch acknowledged the previous version, so it is both
          // the current and the acknowledged base.
          expectedCurrentVersion: at(200),
          acknowledgedBase: at(200),
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
          acknowledgedBase: at(210),
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
          // Device B has never pulled this night: it writes offline from an
          // empty local row, and the server resolves its stale base.
          expectedCurrentVersion: null,
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

    // Device 1 pulls the owner's nights: its local night converges on the
    // server's active version, and a duplicate inbound pass imports nothing
    // new.
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
    expect(pullResult.failureOrNull, isNull);
    final activeNight = await SupabaseQiyamGatewayImpl(clients[1]).fetchNight(
      expectedAccountId: owner,
      recordId: qiyamIdentity.nightRecordId(night),
    );
    final localNight = (await qiyamStores[1].readFresh(
      accountId: owner,
      nightDate: night,
    )).valueOrNull;
    expect(localNight?.performed, activeNight!.performed);
    expect(localNight?.updatedAt, activeNight.updatedAt);
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

  testWidgets('two encrypted devices converge on My Adhkar groups and '
      'entries, with visible conflicts and final deletes', (tester) async {
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
    SupabaseClient testClient() => SupabaseClient(
      config.url.toString(),
      config.publishableKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    // Clients 0 and 1 are the same owner on two devices; client 2 is owner B.
    final clients = <SupabaseClient>[testClient(), testClient(), testClient()];
    final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
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
    const password = 'LocalMyAdhkarIntegration2026!';
    late final String owner;
    late final String ownerB;
    if (local) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final signup = await clients[0].auth.signUp(
        email: 'my-adhkar-$stamp@example.test',
        password: password,
      );
      if (signup.session == null || signup.user == null) {
        fail('Local Supabase did not create an authenticated test session');
      }
      owner = signup.user!.id;
      await clients[1].auth.signInWithPassword(
        email: 'my-adhkar-$stamp@example.test',
        password: password,
      );
      final signupB = await clients[2].auth.signUp(
        email: 'my-adhkar-b-$stamp@example.test',
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
          path: paths[i].allocate(),
          key: List<int>.generate(32, (j) => j + 80 + i),
        ),
      );
    }

    // Per-run unique fixtures: every name, text and operation carries the
    // run tag, and every assertion addresses the entities this run created
    // by their IDs, so a shared account and repeated runs never collide.
    final runTag = Random.secure().nextInt(1 << 32).toRadixString(16);
    // One global script clock: each command on either device is stamped one
    // minute after the previous one (all in the recent past, inside the
    // server's two-day future window), so "newer" is exactly script order.
    final scriptBase = DateTime.now().toUtc().subtract(
      const Duration(hours: 2),
    );
    var step = 0;
    final clocks = [_ScriptClock(scriptBase), _ScriptClock(scriptBase)];
    void tick(int device) =>
        clocks[device].now = scriptBase.add(Duration(minutes: ++step));

    final repos = [for (final db in dbs) DriftMyAdhkarRepository(db)];
    final cmds = [
      for (var i = 0; i < 2; i++)
        MyAdhkarCommands(
          ownerId: owner,
          clock: clocks[i],
          repository: repos[i],
          identity: const UuidMyAdhkarIdentity(),
        ),
    ];
    final adapters = [
      for (var i = 0; i < 2; i++)
        SupabaseMyAdhkarSyncAdapter(
          gateway: SupabaseMyAdhkarGatewayImpl(clients[i]),
          repository: repos[i],
        ),
    ];
    final inbound = [
      for (var i = 0; i < 2; i++)
        MyAdhkarInboundSynchronizer(
          reader: SupabaseMyAdhkarReader(
            SupabaseMyAdhkarPageSource(clients[i]),
            pageSize: 2,
          ),
          reconciler: MyAdhkarReconciler(
            repository: repos[i],
            localStore: DriftLocalStore(dbs[i]),
          ),
        ),
    ];

    Future<int> awardRows(SupabaseClient client, String forOwner) async =>
        (await client.from('xp_awards').select().eq('owner', forOwner)).length;
    final awardsBefore = await awardRows(clients[0], owner);
    final awardsBeforeB = await awardRows(clients[2], ownerB);

    // ---- helpers -------------------------------------------------------
    Future<void> push(
      int device,
      String forOwner,
      CloudSyncPort adapter,
    ) async {
      final rows = (await DriftLocalStore(
        dbs[device],
      ).readPendingChanges(forOwner)).valueOrNull!;
      for (final row in rows) {
        final change = OutboundChange(
          operationId: row.operationId,
          accountId: forOwner,
          entityType: row.entityType,
          entityId: row.entityId,
          kind: row.kind,
          payload: row.serializedChange,
          versionTimestamp: row.versionTimestamp,
          baseUpdatedAt: row.baseUpdatedAt,
        );
        final result = await adapter.dispatchChange(change);
        expect(result.failureOrNull, isNull, reason: row.operationId);
        expect(
          result.valueOrNull,
          isA<DispatchAcknowledged>(),
          reason: row.operationId,
        );
        final ack = result.valueOrNull! as DispatchAcknowledged;
        expect(
          (await DriftLocalStore(dbs[device]).acknowledgeChange(
            row.operationId,
            ack.acknowledgementId,
            ack.remoteVersionTimestamp!,
          )).failureOrNull,
          isNull,
          reason: row.operationId,
        );
      }
    }

    Future<void> pushAll(int device) => push(device, owner, adapters[device]);

    Future<void> pull(int device) async {
      final result = await inbound[device].receive(
        accountId: owner,
        isCurrentScope: () => true,
      );
      expect(result.failureOrNull, isNull, reason: 'inbound pass $device');
    }

    Future<void> syncBoth() async {
      await pushAll(0);
      await pushAll(1);
      await pull(0);
      await pull(1);
    }

    Future<String> newGroup(int device, String name) async {
      tick(device);
      final result = await cmds[device].createGroup(name: '$name $runTag');
      return (result.valueOrNull! as MyAdhkarGroupCreated).groupId;
    }

    Future<String> newEntry(
      int device,
      String text,
      List<String> groups, {
      String? source,
    }) async {
      tick(device);
      final result = await cmds[device].add(
        draft: MyDhikrDraft(
          text: '$text $runTag',
          source: source,
          groupIds: groups,
        ),
      );
      return (result.valueOrNull! as MyAdhkarAdded).itemId;
    }

    Future<MyDhikrItem> localEntry(int device, String id) async =>
        (await repos[device].readFresh(
          accountId: owner,
          itemId: id,
        )).valueOrNull!;

    Future<bool> localGroupLive(int device, String id) async {
      final group = (await repos[device].readGroupFresh(
        accountId: owner,
        groupId: id,
      )).valueOrNull;
      return group != null && !group.isDeleted;
    }

    Future<int> localConflicts(int device, String entityId) async =>
        (await dbs[device].rawScalar(
              'SELECT count(*) FROM conflict_records WHERE account_id = '
              "'$owner' AND entity_id = '$entityId'",
            ))
            as int;

    Future<Map<String, dynamic>?> remoteItem(String id) async {
      final rows = await clients[0]
          .from('my_adhkar_items')
          .select()
          .eq('owner', owner)
          .eq('item_id', id);
      return rows.isEmpty ? null : Map<String, dynamic>.from(rows.single);
    }

    Future<List<String>> remoteMemberships(String id) async =>
        (await clients[0]
                .from('my_adhkar_item_groups')
                .select()
                .eq('owner', owner)
                .eq('item_id', id))
            .map((row) => (row as Map)['group_id'] as String)
            .toList()
          ..sort();

    Future<int> remoteConflicts(String entityId) async =>
        (await clients[0]
                .from('my_adhkar_conflicts')
                .select()
                .eq('owner', owner)
                .eq('entity_id', entityId))
            .length;

    // --------------------------------------------------------------------
    // Case 1: both devices create groups and add entries; one entry is in
    // two groups; everything converges on both devices.
    // --------------------------------------------------------------------
    final groupA1 = await newGroup(0, 'group a1');
    final groupA2 = await newGroup(0, 'group a2');
    final entryShared = await newEntry(0, 'entry shared', [
      groupA1,
      groupA2,
    ], source: 'source shared');
    final entryOnlyA1 = await newEntry(0, 'entry only a1', [groupA1]);
    final groupB1 = await newGroup(1, 'group b1');
    final entryB = await newEntry(1, 'entry b', [groupB1]);
    await syncBoth();
    for (final device in [0, 1]) {
      for (final id in [groupA1, groupA2, groupB1]) {
        expect(await localGroupLive(device, id), isTrue, reason: 'group $id');
      }
      for (final id in [entryShared, entryOnlyA1, entryB]) {
        expect((await localEntry(device, id)).isDeleted, isFalse);
      }
      expect(
        (await localEntry(device, entryShared)).groupIds.toSet(),
        {groupA1, groupA2},
        reason: 'one entry in two groups is one entry on device $device',
      );
      expect((await localEntry(device, entryShared)).source, 'source shared');
    }
    expect(await remoteMemberships(entryShared), [groupA1, groupA2]..sort());
    expect(
      await dbs[0].rawScalar('SELECT count(*) FROM conflict_records'),
      0,
      reason: 'a clean convergence has no conflict',
    );
    expect(await dbs[1].rawScalar('SELECT count(*) FROM conflict_records'), 0);

    // --------------------------------------------------------------------
    // Case 2: group A1 is deleted on device A while device B, offline, adds
    // to it. The group delete wins; B's entry that was only in A1 is
    // deleted and kept as a visible conflict; B's entry also in group B1
    // stays there; A's entry also in A2 stays there.
    // --------------------------------------------------------------------
    final entryBOnlyA1 = await newEntry(1, 'entry b only a1', [groupA1]);
    final entryBKept = await newEntry(1, 'entry b kept', [groupA1, groupB1]);
    tick(0);
    final deleteResult = await cmds[0].deleteGroup(groupId: groupA1);
    expect(
      (deleteResult.valueOrNull! as MyAdhkarGroupDeleted).cascadedEntries,
      1,
      reason: 'only the entry that was solely in A1',
    );
    await pushAll(0);
    await pushAll(1);
    await pull(0);
    await pull(1);
    for (final device in [0, 1]) {
      expect(await localGroupLive(device, groupA1), isFalse);
      expect((await localEntry(device, entryOnlyA1)).isDeleted, isTrue);
      expect(
        (await localEntry(device, entryBOnlyA1)).isDeleted,
        isTrue,
        reason: 'B\'s entry left with no live group is deleted',
      );
      final kept = await localEntry(device, entryBKept);
      expect(kept.isDeleted, isFalse);
      expect(kept.groupIds, [groupB1]);
      final shared = await localEntry(device, entryShared);
      expect(shared.isDeleted, isFalse);
      expect(shared.groupIds, [groupA2]);
    }
    expect(
      await remoteConflicts(entryBOnlyA1),
      1,
      reason: 'B\'s version is kept as one conflict on the server',
    );
    expect(await localConflicts(1, entryBOnlyA1), 1);
    expect(
      await localConflicts(0, entryBOnlyA1),
      1,
      reason: 'device A sees the conflict after its inbound pass',
    );
    expect(await localConflicts(1, entryBKept), 0);
    expect(await remoteConflicts(entryOnlyA1), 0);

    // --------------------------------------------------------------------
    // Case 3: the same entry edited on both devices offline gives ONE
    // visible conflict and converges on the newest version.
    // --------------------------------------------------------------------
    tick(0);
    expect(
      (await cmds[0].edit(
        itemId: entryB,
        draft: MyDhikrDraft(
          text: 'entry b edited on a $runTag',
          groupIds: [groupB1],
        ),
      )).valueOrNull,
      isA<MyAdhkarEdited>(),
    );
    tick(1);
    expect(
      (await cmds[1].edit(
        itemId: entryB,
        draft: MyDhikrDraft(
          text: 'entry b edited on b $runTag',
          groupIds: [groupB1],
        ),
      )).valueOrNull,
      isA<MyAdhkarEdited>(),
    );
    await syncBoth();
    expect(await remoteConflicts(entryB), 1, reason: 'one stable conflict');
    for (final device in [0, 1]) {
      expect(
        (await localEntry(device, entryB)).text,
        'entry b edited on b $runTag',
        reason: 'the newest version wins on device $device',
      );
      expect(await localConflicts(device, entryB), 1);
    }
    // A duplicate inbound pass adds no second conflict.
    await pull(0);
    expect(await localConflicts(0, entryB), 1);

    // --------------------------------------------------------------------
    // Case 4: a delete stays final against a newer edit made on the other
    // device: the edit is kept as a conflict and never restores the entry.
    // --------------------------------------------------------------------
    tick(0);
    expect(
      (await cmds[0].delete(itemId: entryBKept)).valueOrNull,
      isA<MyAdhkarDeleted>(),
    );
    tick(1);
    expect(
      (await cmds[1].edit(
        itemId: entryBKept,
        draft: MyDhikrDraft(
          text: 'entry b kept edited later $runTag',
          groupIds: [groupB1],
        ),
      )).valueOrNull,
      isA<MyAdhkarEdited>(),
    );
    await pushAll(0);
    await pushAll(1);
    await pull(0);
    await pull(1);
    expect((await remoteItem(entryBKept))!['deleted_at'], isNotNull);
    expect(await remoteMemberships(entryBKept), isEmpty);
    expect(await remoteConflicts(entryBKept), 1);
    for (final device in [0, 1]) {
      expect(
        (await localEntry(device, entryBKept)).isDeleted,
        isTrue,
        reason: 'a delete is final on device $device',
      );
    }
    // A fresh pull keeps it deleted.
    await pull(1);
    expect((await localEntry(1, entryBKept)).isDeleted, isTrue);

    // --------------------------------------------------------------------
    // Case 5: on one device, offline, edit an entry and then delete its only
    // group; after sync the entry is deleted on both devices with NO
    // conflict record: the edit reaches the server before the cascade.
    // --------------------------------------------------------------------
    final groupC = await newGroup(0, 'group c');
    final entryC = await newEntry(0, 'entry c', [groupC]);
    await syncBoth();
    expect(await localGroupLive(1, groupC), isTrue);
    tick(1);
    expect(
      (await cmds[1].edit(
        itemId: entryC,
        draft: MyDhikrDraft(
          text: 'entry c edited offline $runTag',
          groupIds: [groupC],
        ),
      )).valueOrNull,
      isA<MyAdhkarEdited>(),
    );
    tick(1);
    expect(
      (await cmds[1].deleteGroup(groupId: groupC)).valueOrNull,
      isA<MyAdhkarGroupDeleted>(),
    );
    expect(
      (await localEntry(1, entryC)).isDeleted,
      isTrue,
      reason: 'the local cascade deleted it at once',
    );
    await pushAll(1);
    await pull(0);
    await pull(1);
    expect((await remoteItem(entryC))!['deleted_at'], isNotNull);
    expect(
      await remoteConflicts(entryC),
      0,
      reason: 'no conflict: the edit arrived before the group delete',
    );
    for (final device in [0, 1]) {
      expect(await localGroupLive(device, groupC), isFalse);
      expect((await localEntry(device, entryC)).isDeleted, isTrue);
      expect(await localConflicts(device, entryC), 0);
    }

    // --------------------------------------------------------------------
    // Case 6: owner B is isolated. Its group and entry never reach owner A,
    // and owner B never sees owner A's rows.
    // --------------------------------------------------------------------
    final cmdB = MyAdhkarCommands(
      ownerId: ownerB,
      clock: clocks[1],
      repository: repos[1],
      identity: const UuidMyAdhkarIdentity(),
    );
    tick(1);
    final groupOfB =
        ((await cmdB.createGroup(name: 'owner b group $runTag')).valueOrNull!
                as MyAdhkarGroupCreated)
            .groupId;
    tick(1);
    final entryOfB =
        ((await cmdB.add(
                  draft: MyDhikrDraft(
                    text: 'owner b entry $runTag',
                    groupIds: [groupOfB],
                  ),
                )).valueOrNull!
                as MyAdhkarAdded)
            .itemId;
    await push(
      1,
      ownerB,
      SupabaseMyAdhkarSyncAdapter(
        gateway: SupabaseMyAdhkarGatewayImpl(clients[2]),
        repository: repos[1],
      ),
    );
    await pull(0);
    expect(await localGroupLive(0, groupOfB), isFalse);
    expect(
      (await repos[0].readFresh(
        accountId: owner,
        itemId: entryOfB,
      )).valueOrNull,
      isNull,
      reason: 'owner A\'s store never holds owner B\'s entry',
    );
    expect(
      await clients[0]
          .from('my_adhkar_groups')
          .select()
          .eq('group_id', groupOfB),
      isEmpty,
      reason: 'row-level security hides owner B\'s group from owner A',
    );
    expect(
      await clients[0].from('my_adhkar_items').select().eq('item_id', entryOfB),
      isEmpty,
    );
    expect(
      await clients[2]
          .from('my_adhkar_items')
          .select()
          .eq('item_id', entryShared),
      isEmpty,
      reason: 'owner B never sees owner A\'s entries',
    );
    expect(
      await clients[2]
          .from('my_adhkar_groups')
          .select()
          .eq('group_id', groupA2),
      isEmpty,
    );
    expect(
      await clients[2]
          .from('my_adhkar_conflicts')
          .select()
          .eq('entity_id', entryB),
      isEmpty,
    );

    // --------------------------------------------------------------------
    // Case 7: My Adhkar never writes the XP ledger, locally or on the server.
    // --------------------------------------------------------------------
    expect(await dbs[0].rawScalar('SELECT count(*) FROM xp_awards'), 0);
    expect(await dbs[1].rawScalar('SELECT count(*) FROM xp_awards'), 0);
    expect(await awardRows(clients[0], owner), awardsBefore);
    expect(await awardRows(clients[2], ownerB), awardsBeforeB);
  });
}

final class _ScriptClock implements AdhkarClockPort {
  _ScriptClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}
