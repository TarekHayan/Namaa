import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/habit_reconciler.dart';
import 'package:namma_project/features/habits/data/supabase_habit_reader.dart';
import 'package:namma_project/features/habits/data/supabase_habit_sync_adapter.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/habits_test_support.dart';

/// End-to-end device proof against the isolated non-production Supabase
/// project. Every value is injected by the CI operator; production endpoints
/// and server-side keys remain rejected by [SupabaseEnvironmentConfig].
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'staging Auth, Data API, session, sync, and account isolation work',
    (tester) async {
      const url = String.fromEnvironment('NAMAA_SUPABASE_URL');
      const publishableKey = String.fromEnvironment(
        'NAMAA_SUPABASE_PUBLISHABLE_KEY',
      );
      const ownerEmail = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_A_EMAIL',
      );
      const ownerPassword = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_A_PASSWORD',
      );
      const otherEmail = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_B_EMAIL',
      );
      const otherPassword = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_B_PASSWORD',
      );

      for (final value in <String>[
        url,
        publishableKey,
        ownerEmail,
        ownerPassword,
        otherEmail,
        otherPassword,
      ]) {
        expect(
          value,
          isNotEmpty,
          reason: 'All isolated non-production CI values must be injected.',
        );
      }

      expect(
        () => SupabaseEnvironmentConfig.localStack(
          url: Uri.parse('https://prod.example.supabase.co'),
          publishableKey: 'sb_publishable_boundary-check',
        ),
        throwsA(isA<ConfigurationError>()),
      );
      expect(
        () => SupabaseEnvironmentConfig.isolatedNonProduction(
          url: Uri.parse('https://prod.example.supabase.co'),
          publishableKey: 'sb_publishable_boundary-check',
        ),
        throwsA(isA<ConfigurationError>()),
      );
      expect(
        () => SupabaseEnvironmentConfig.isolatedNonProduction(
          url: Uri.parse('https://arbitrary.example.com'),
          publishableKey: 'sb_publishable_boundary-check',
        ),
        throwsA(isA<ConfigurationError>()),
      );

      final stagingUri = Uri.parse(url);
      final config = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: stagingUri,
        publishableKey: publishableKey,
        approvedHosts: <String>{stagingUri.host},
      );
      final ownerClient = createSupabaseClient(config);
      final otherClient = createSupabaseClient(config);
      addTearDown(ownerClient.dispose);
      addTearDown(otherClient.dispose);

      final ownerAuth = await ownerClient.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      final otherAuth = await otherClient.auth.signInWithPassword(
        email: otherEmail,
        password: otherPassword,
      );
      expect(ownerAuth.session, isNotNull);
      expect(otherAuth.session, isNotNull);
      expect(ownerAuth.user!.id, isNot(otherAuth.user!.id));

      final sessionAdapter = SupabaseSessionAdapter(
        gateway: SupabaseAuthGatewayImpl(ownerClient),
      );
      expect((await sessionAdapter.initialize()).failureOrNull, isNull);
      final syncContext = await sessionAdapter.obtainSyncContext();
      expect(syncContext.failureOrNull, isNull);
      expect(syncContext.valueOrNull!.accountId, ownerAuth.user!.id);

      final entityId = _randomUuid();
      final operationId = 'ci-$entityId';
      const ownerPayload = 'foundation-staging-owner-payload';
      final ownerSync = SupabaseSyncAdapter(
        gateway: SupabaseProbeGatewayImpl(ownerClient),
      );
      final otherSync = SupabaseSyncAdapter(
        gateway: SupabaseProbeGatewayImpl(otherClient),
      );

      addTearDown(() async {
        await ownerClient
            .from(kFoundationProbeTable)
            .delete()
            .eq('id', entityId);
      });

      final create = await ownerSync.dispatchChange(
        OutboundChange(
          operationId: operationId,
          accountId: ownerAuth.user!.id,
          entityType: 'foundation_record',
          entityId: entityId,
          kind: ChangeKind.create,
          payload: ownerPayload,
          versionTimestamp: DateTime.now().toUtc(),
        ),
      );
      expect(create.failureOrNull, isNull);

      final ownerRead = await ownerSync.obtainRemoteVersion(
        entityType: 'foundation_record',
        entityId: entityId,
      );
      expect(ownerRead.failureOrNull, isNull);
      expect(ownerRead.valueOrNull?.payload, ownerPayload);

      final crossAccountRead = await otherSync.obtainRemoteVersion(
        entityType: 'foundation_record',
        entityId: entityId,
      );
      expect(crossAccountRead.failureOrNull, isNull);
      expect(crossAccountRead.valueOrNull, isNull);

      final crossAccountWrite = await otherSync.dispatchChange(
        OutboundChange(
          operationId: 'other-$operationId',
          accountId: otherAuth.user!.id,
          entityType: 'foundation_record',
          entityId: entityId,
          kind: ChangeKind.update,
          payload: 'cross-account-overwrite',
          versionTimestamp: DateTime.now().toUtc().add(
            const Duration(minutes: 1),
          ),
        ),
      );
      expect(crossAccountWrite.failureOrNull, isNotNull);

      final unchangedOwnerRead = await ownerSync.obtainRemoteVersion(
        entityType: 'foundation_record',
        entityId: entityId,
      );
      expect(unchangedOwnerRead.failureOrNull, isNull);
      expect(unchangedOwnerRead.valueOrNull?.payload, ownerPayload);
    },
  );

  testWidgets(
    'staging Habits synchronize between devices and isolate accounts',
    (tester) async {
      const url = String.fromEnvironment('NAMAA_SUPABASE_URL');
      const publishableKey = String.fromEnvironment(
        'NAMAA_SUPABASE_PUBLISHABLE_KEY',
      );
      const ownerEmail = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_A_EMAIL',
      );
      const ownerPassword = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_A_PASSWORD',
      );
      const otherEmail = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_B_EMAIL',
      );
      const otherPassword = String.fromEnvironment(
        'NAMAA_STAGING_TEST_USER_B_PASSWORD',
      );
      for (final value in [
        url,
        publishableKey,
        ownerEmail,
        ownerPassword,
        otherEmail,
        otherPassword,
      ]) {
        expect(value, isNotEmpty);
      }
      final stagingUri = Uri.parse(url);
      final config = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: stagingUri,
        publishableKey: publishableKey,
        approvedHosts: {stagingUri.host},
      );
      final deviceA = createSupabaseClient(config);
      final deviceB = createSupabaseClient(config);
      final otherAccount = createSupabaseClient(config);
      addTearDown(deviceA.dispose);
      addTearDown(deviceB.dispose);
      addTearDown(otherAccount.dispose);
      final ownerA = await deviceA.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      final ownerB = await deviceB.auth.signInWithPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      final foreign = await otherAccount.auth.signInWithPassword(
        email: otherEmail,
        password: otherPassword,
      );
      final ownerId = ownerA.user!.id;
      expect(ownerB.user!.id, ownerId);
      expect(foreign.user!.id, isNot(ownerId));

      final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
      final encryptionKey = List<int>.generate(32, (index) => index + 100);
      final databaseA = await FoundationDatabase.openEncrypted(
        path: paths[0].allocate(),
        key: encryptionKey,
      );
      final databaseB = await FoundationDatabase.openEncrypted(
        path: paths[1].allocate(),
        key: encryptionKey,
      );
      addTearDown(() async {
        await databaseA.close();
        await databaseB.close();
        for (final path in paths) {
          path.dispose();
        }
      });
      final localA = DriftHabitRepository(
        database: databaseA,
        codec: const HabitPayloadCodec(),
      );
      final localB = DriftHabitRepository(
        database: databaseB,
        codec: const HabitPayloadCodec(),
      );
      final sessionA = SupabaseSessionAdapter(
        gateway: SupabaseAuthGatewayImpl(deviceA),
      );
      expect((await sessionA.initialize()).failureOrNull, isNull);
      final commands = HabitCommands(repository: localA, session: sessionA);
      final created = await commands.createHabit(
        const CreateHabitInput(
          name: 'Staging Habit',
          weekdays: HabitsTestSchedules.daily,
        ),
        expectedAccountId: ownerId,
      );
      expect(created.failureOrNull, isNull);
      final habit = created.valueOrNull!;
      final completed = await commands.completeHabitToday(
        habit.id,
        expectedAccountId: ownerId,
      );
      expect(completed.failureOrNull, isNull);
      final day = completed.valueOrNull!;

      final outbox = DriftLocalStore(databaseA);
      final pending = (await outbox.readPendingChanges(ownerId)).valueOrNull!;
      expect(pending, hasLength(2));
      final adapter = SupabaseHabitSyncAdapter(
        gateway: SupabaseHabitGatewayImpl(deviceA),
      );
      for (final change in pending) {
        final outbound = OutboundChange(
          operationId: change.operationId,
          accountId: change.accountId,
          entityType: change.entityType,
          entityId: change.entityId,
          kind: change.kind,
          payload: change.serializedChange,
          versionTimestamp: change.versionTimestamp,
        );
        for (var retry = 0; retry < 2; retry++) {
          final result = await adapter.dispatchChange(outbound);
          expect(result.failureOrNull, isNull);
          expect(result.valueOrNull, isA<DispatchAcknowledged>());
        }
        expect(
          (await outbox.acknowledgeChange(
            change.operationId,
            change.operationId,
          )).failureOrNull,
          isNull,
        );
      }
      expect((await outbox.readPendingChanges(ownerId)).valueOrNull, isEmpty);

      final remoteB = await SupabaseHabitReader(
        gateway: SupabaseHabitGatewayImpl(deviceB),
      ).readAll(ownerId);
      expect(remoteB.failureOrNull, isNull);
      final snapshot = remoteB.valueOrNull!;
      expect(
        snapshot.habits.where((item) => item.id == habit.id),
        hasLength(1),
      );
      expect(
        snapshot.days.where(
          (item) => item.habitId == habit.id && item.localDate == day.localDate,
        ),
        hasLength(1),
      );
      final reconciler = HabitReconciler(
        store: localB,
        localStore: DriftLocalStore(databaseB),
      );
      final inbound = await reconciler.reconcile(
        accountId: ownerId,
        remote: snapshot,
      );
      final habitIds = snapshot.habits.map((habit) => habit.id).toSet();
      final orphanDays = snapshot.days
          .where((day) => !habitIds.contains(day.habitId))
          .length;
      expect(
        inbound.failureOrNull,
        isNull,
        reason:
            'Habit staging inbound failed: '
            '${inbound.failureOrNull?.technicalCause}; '
            'habits=${snapshot.habits.length}, days=${snapshot.days.length}, '
            'orphanDays=$orphanDays',
      );
      expect(
        (await localB.readHabit(
          accountId: ownerId,
          habitId: habit.id,
        )).valueOrNull?.name,
        habit.name,
      );
      expect(
        (await localB.readDay(
          accountId: ownerId,
          habitId: habit.id,
          localDate: day.localDate,
        )).valueOrNull?.isCompleted,
        isTrue,
      );
      final foreignRead = await SupabaseHabitReader(
        gateway: SupabaseHabitGatewayImpl(otherAccount),
      ).readAll(foreign.user!.id);
      expect(foreignRead.failureOrNull, isNull);
      expect(
        foreignRead.valueOrNull!.habits.any((item) => item.id == habit.id),
        isFalse,
      );
      expect(
        foreignRead.valueOrNull!.days.any((item) => item.habitId == habit.id),
        isFalse,
      );

      final removed = await commands.deleteHabit(
        habit.id,
        confirmed: true,
        expectedAccountId: ownerId,
      );
      expect(removed.failureOrNull, isNull);
      final deleteChange = (await outbox.readPendingChanges(
        ownerId,
      )).valueOrNull!.single;
      final deleteResult = await adapter.dispatchChange(
        OutboundChange(
          operationId: deleteChange.operationId,
          accountId: deleteChange.accountId,
          entityType: deleteChange.entityType,
          entityId: deleteChange.entityId,
          kind: deleteChange.kind,
          payload: deleteChange.serializedChange,
          versionTimestamp: deleteChange.versionTimestamp,
        ),
      );
      expect(deleteResult.failureOrNull, isNull);
      expect(deleteResult.valueOrNull, isA<DispatchVersionConflict>());
      final afterDelete = await SupabaseHabitReader(
        gateway: SupabaseHabitGatewayImpl(deviceB),
      ).readAll(ownerId);
      expect(afterDelete.failureOrNull, isNull);
      expect(
        afterDelete.valueOrNull!.habits
            .singleWhere((item) => item.id == habit.id)
            .isDeleted,
        isTrue,
      );
      expect(
        (await reconciler.reconcile(
          accountId: ownerId,
          remote: afterDelete.valueOrNull!,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await localB.readHabit(
          accountId: ownerId,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      expect(
        (await localB.watchHabits(ownerId).first).any(
          (item) => item.id == habit.id,
        ),
        isFalse,
      );
      expect(
        await databaseB.rawScalar('SELECT count(*) FROM conflict_records'),
        greaterThan(0),
      );
    },
  );
}

String _randomUuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
