import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport;
import 'package:namma_project/features/prayer/data/drift_prayer_preferences.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/prayer_reconciler.dart';
import 'package:namma_project/features/prayer/data/supabase_prayer_gateway.dart';
import 'package:namma_project/features/prayer/data/supabase_prayer_reader.dart';
import 'package:namma_project/features/prayer/data/supabase_prayer_sync_adapter.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two encrypted devices converge, replay and retain one award', (
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
    // The factory used by boundary tests is intentionally stateless and PKCE
    // needs protected storage. This isolated test uses implicit auth.
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
    const password = 'LocalPrayerIntegration2026!';
    late final String owner;
    if (local) {
      final email =
          'prayer-sync-${DateTime.now().microsecondsSinceEpoch}@example.test';
      final signup = await clients[0].auth.signUp(
        email: email,
        password: password,
      );
      if (signup.session == null || signup.user == null) {
        fail('Local Supabase did not create an authenticated test session');
      }
      owner = signup.user!.id;
      await clients[1].auth.signInWithPassword(
        email: email,
        password: password,
      );
      await clients[2].auth.signInWithPassword(
        email: email,
        password: password,
      );
    } else {
      owner = (await clients[0].auth.signInWithPassword(
        email: emailA,
        password: passwordA,
      )).user!.id;
      for (final client in clients.skip(1)) {
        final signedIn = await client.auth.signInWithPassword(
          email: emailA,
          password: passwordA,
        );
        expect(signedIn.user!.id, owner);
      }
    }

    for (var i = 0; i < 2; i++) {
      dbs.add(
        await FoundationDatabase.openEncrypted(
          path: databasePaths[i],
          key: List<int>.generate(32, (j) => j + 20 + i),
        ),
      );
    }
    final stores = [for (final db in dbs) DriftPrayerRepository(db)];
    for (var i = 0; i < 2; i++) {
      final cityName = i == 0 ? 'Cairo' : 'London';
      final zone = i == 0 ? 'Africa/Cairo' : 'Europe/London';
      expect(
        (await DriftPrayerPreferences(dbs[i]).save(
          PrayerPreferences(
            accountId: owner,
            city: PrayerCity(
              provider: 'fixture',
              providerCityId: cityName,
              name: cityName,
              countryCode: i == 0 ? 'EG' : 'GB',
              countryName: i == 0 ? 'Egypt' : 'United Kingdom',
              latitude: i == 0 ? 30.0 : 51.5,
              longitude: i == 0 ? 31.0 : -0.1,
              timeZoneId: zone,
            ),
            calculationMethod: 'egyptian',
            revision: 1,
            updatedAt: DateTime.utc(2026, 10, 29),
          ),
          expectedRevision: null,
        )).failureOrNull,
        isNull,
      );
    }
    final adapters = [
      for (var i = 0; i < 2; i++)
        SupabasePrayerSyncAdapter(
          gateway: SupabasePrayerGatewayImpl(clients[i]),
          repository: stores[i],
        ),
    ];
    // A one-row page exercises all three keyset cursors and their restart.
    final readers = [
      for (final client in clients) SupabasePrayerReader(client, pageSize: 1),
    ];
    // Staging users persist across runs. Use a fresh civil day so the exact
    // report identity and one-time XP assertions cannot inherit prior data.
    // The shared staging account keeps every run's rows, so each hosted run
    // picks its own random day. It must lie in the past: the server rejects
    // a report dated more than two days ahead (migration 0015).
    final fixtureDay = local
        ? DateTime.utc(2026, 10, 29)
        : DateTime.utc(
            1000,
          ).add(Duration(days: Random.secure().nextInt(365000)));
    String isoDay(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final date = PrayerLocalDate.parse(isoDay(fixtureDay));
    final initial = DateTime.utc(
      fixtureDay.year,
      fixtureDay.month,
      fixtureDay.day,
      5,
    );
    PrayerReport report(
      int device,
      PrayerName name,
      PrayerStatus status,
      int second, {
      DateTime? createdAt,
      PrayerLocalDate? day,
    }) {
      final version = initial.add(Duration(seconds: second));
      final localDay = day ?? date;
      return PrayerReport(
        accountId: owner,
        reportId: UuidPrayerReportIdentity().reportId(localDay, name),
        date: localDay,
        name: name,
        status: status,
        reportedCompletionAt: status.isCompleted ? version : null,
        recordedZoneId: device == 0 ? 'Africa/Cairo' : 'Europe/London',
        recordedOffsetMinutes: device == 0 ? 120 : 0,
        createdAt: createdAt ?? version,
        updatedAt: version,
      );
    }

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

    Future<void> dispatch(
      int device,
      OutboundChange change, {
      bool acknowledge = true,
    }) async {
      final result = await adapters[device].dispatchChange(change);
      expect(result.failureOrNull, isNull);
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

    Future<void> receive(int device) async {
      final remote = await readers[device].readAll(owner);
      final outcome = await PrayerReconciler(
        repository: stores[device],
        localStore: DriftLocalStore(dbs[device]),
        awards: DriftAwardLedger(dbs[device]),
      ).reconcile(accountId: owner, remote: remote);
      expect(outcome.failureOrNull, isNull);
    }

    // Different prayers merge even though the devices have different city
    // preferences. The reports' captured zones never change either city.
    final fajr = report(0, PrayerName.fajr, PrayerStatus.completedOnTime, 1);
    final dhuhr = report(1, PrayerName.dhuhr, PrayerStatus.completedLate, 2);
    expect(
      (await stores[0].writeLocal(
        fajr,
        operationId: 'device-a-fajr',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await stores[1].writeLocal(
        dhuhr,
        operationId: 'device-b-dhuhr',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    await dispatch(0, await pending(0, 'device-a-fajr'));
    await dispatch(1, await pending(1, 'device-b-dhuhr'));
    await receive(0);
    await receive(1);
    for (final store in stores) {
      expect(
        (await store.readFresh(
          accountId: owner,
          date: date,
          prayerName: PrayerName.fajr,
        )).valueOrNull?.status,
        PrayerStatus.completedOnTime,
      );
      expect(
        (await store.readFresh(
          accountId: owner,
          date: date,
          prayerName: PrayerName.dhuhr,
        )).valueOrNull?.status,
        PrayerStatus.completedLate,
      );
    }

    // Device-local city selection is never uploaded with reports. A report
    // from London's following calendar day retains its separate identity.
    final tomorrow = PrayerLocalDate.parse(
      isoDay(fixtureDay.add(const Duration(days: 1))),
    );
    final londonIsha = report(
      1,
      PrayerName.isha,
      PrayerStatus.completedLate,
      6,
      day: tomorrow,
    );
    expect(
      (await stores[1].writeLocal(
        londonIsha,
        operationId: 'device-b-next-day',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    await dispatch(1, await pending(1, 'device-b-next-day'));
    await receive(0);
    expect(
      (await stores[0].readFresh(
        accountId: owner,
        date: tomorrow,
        prayerName: PrayerName.isha,
      )).valueOrNull?.status,
      PrayerStatus.completedLate,
    );
    expect(
      (await DriftPrayerPreferences(dbs[0]).read(owner)).valueOrNull?.city.name,
      'Cairo',
    );
    expect(
      (await DriftPrayerPreferences(dbs[1]).read(owner)).valueOrNull?.city.name,
      'London',
    );

    // Equal timestamp edits retain one semantic conflict and converge.
    final tieA = report(0, PrayerName.maghrib, PrayerStatus.completedLate, 7);
    final tieB = report(1, PrayerName.maghrib, PrayerStatus.missed, 7);
    expect(
      (await stores[0].writeLocal(
        tieA,
        operationId: 'device-a-tie',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await stores[1].writeLocal(
        tieB,
        operationId: 'device-b-tie',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    final tieChangeA = await pending(0, 'device-a-tie');
    final tieChangeB = await pending(1, 'device-b-tie');
    await Future.wait([dispatch(0, tieChangeA), dispatch(1, tieChangeB)]);
    await receive(0);
    await receive(1);
    final tieSnapshot = await readers[2].readAll(owner);
    expect(
      tieSnapshot.conflicts
          .where((value) => value.active.reportId == tieA.reportId)
          .length,
      1,
    );
    final tieActive = tieSnapshot.reports
        .singleWhere((value) => value.reportId == tieA.reportId)
        .status;
    expect(
      tieSnapshot.awards
          .where((value) => value.sourceId == tieA.reportId)
          .length,
      1,
    );
    for (final store in stores) {
      expect(
        (await store.readFresh(
          accountId: owner,
          date: date,
          prayerName: PrayerName.maghrib,
        )).valueOrNull?.status,
        tieActive,
      );
    }

    // Two offline first writes to Asr race. The first eligible completion
    // fixes the award while a later report version remains visible.
    final asrA = report(0, PrayerName.asr, PrayerStatus.completedLate, 3);
    final asrB = report(1, PrayerName.asr, PrayerStatus.completedOnTime, 4);
    expect(
      (await stores[0].writeLocal(
        asrA,
        operationId: 'device-a-asr',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await stores[1].writeLocal(
        asrB,
        operationId: 'device-b-asr',
        acknowledgedBase: null,
        expectedCurrentVersion: null,
      )).failureOrNull,
      isNull,
    );
    final firstChange = await pending(0, 'device-a-asr');
    await dispatch(0, firstChange, acknowledge: false);
    await dispatch(1, await pending(1, 'device-b-asr'));
    for (var i = 0; i < 10; i++) {
      await dispatch(0, firstChange, acknowledge: false);
    }
    expect(
      (await DriftLocalStore(dbs[0]).acknowledgeChange(
        firstChange.operationId,
        firstChange.operationId,
        firstChange.versionTimestamp,
      )).failureOrNull,
      isNull,
    );
    await receive(0);
    await receive(1);
    final fresh = await readers[2].readAll(owner);
    final asrId = asrA.reportId;
    expect(
      fresh.reports.singleWhere((r) => r.reportId == asrId).status,
      PrayerStatus.completedOnTime,
    );
    expect(fresh.awards.singleWhere((a) => a.sourceId == asrId).amount, 5);
    expect(fresh.conflicts.where((c) => c.active.reportId == asrId).length, 1);
    expect(
      await dbs[0].rawScalar(
        "SELECT count(*) FROM xp_awards WHERE source = 'prayer_done' AND source_id = '$asrId'",
      ),
      1,
    );

    // The server's immutable award survives a later reset.
    final current = (await stores[0].readFresh(
      accountId: owner,
      date: date,
      prayerName: PrayerName.asr,
    )).valueOrNull!;
    final reset = report(
      0,
      PrayerName.asr,
      PrayerStatus.pending,
      5,
      createdAt: current.createdAt,
    );
    expect(
      (await stores[0].writeLocal(
        reset,
        operationId: 'device-a-reset',
        acknowledgedBase: current.lastAcknowledgedUpdatedAt,
        expectedCurrentVersion: current.updatedAt,
      )).failureOrNull,
      isNull,
    );
    await dispatch(0, await pending(0, 'device-a-reset'));
    final afterReset = await readers[2].readAll(owner);
    expect(afterReset.awards.singleWhere((a) => a.sourceId == asrId).amount, 5);
    expect(
      afterReset.reports.singleWhere((r) => r.reportId == asrId).status,
      PrayerStatus.pending,
    );

    // Closing and reopening the encrypted first device retains the canonical
    // award, the settled report and conflict evidence before another pass.
    await dbs[0].close();
    dbs[0] = await FoundationDatabase.openEncrypted(
      path: databasePaths[0],
      key: List<int>.generate(32, (j) => j + 20),
    );
    stores[0] = DriftPrayerRepository(dbs[0]);
    expect(
      (await stores[0].readFresh(
        accountId: owner,
        date: date,
        prayerName: PrayerName.asr,
      )).valueOrNull?.status,
      PrayerStatus.pending,
    );
    expect(
      await dbs[0].rawScalar(
        "SELECT count(*) FROM xp_awards WHERE source = 'prayer_done' AND source_id = '$asrId'",
      ),
      1,
    );
    expect(
      await dbs[0].rawScalar(
        "SELECT count(*) FROM conflict_records WHERE entity_id = '$asrId'",
      ),
      1,
    );
    await receive(0);
    expect(
      (await readers[0].readAll(owner)).reports
          .where((report) => report.date == date || report.date == tomorrow)
          .length,
      5,
    );
    expect(
      (await DriftPrayerPreferences(dbs[0]).read(owner)).valueOrNull?.city.name,
      'Cairo',
    );

    // A second authenticated owner sees none of the first owner's rows.
    final foreign = testClient();
    clients.add(foreign);
    final foreignOwner = local
        ? (await foreign.auth.signUp(
            email:
                'prayer-other-${DateTime.now().microsecondsSinceEpoch}@example.test',
            password: password,
          )).user!.id
        : (await foreign.auth.signInWithPassword(
            email: emailB,
            password: passwordB,
          )).user!.id;
    expect(foreignOwner, isNot(owner));
    final foreignSnapshot = await SupabasePrayerReader(
      foreign,
    ).readAll(foreignOwner);
    expect(
      foreignSnapshot.reports.where(
        (r) => r.date == date || r.date == tomorrow,
      ),
      isEmpty,
    );
    expect(foreignSnapshot.awards.where((a) => a.sourceId == asrId), isEmpty);
    expect(
      foreignSnapshot.conflicts.where((c) => c.active.reportId == asrId),
      isEmpty,
    );
    await clients[0].auth.signOut();
    await expectLater(readers[0].readAll(owner), throwsStateError);
  });
}
