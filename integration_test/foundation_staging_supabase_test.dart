import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';

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
