import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/composition/unconfigured_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';

class _FailingSecureStore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) async =>
      throw StateError('simulated vault failure');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('simulated vault failure');

  @override
  Future<void> delete(String key) async =>
      throw StateError('simulated vault failure');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;

  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('unconfigured composition root', () {
    test('resolves all six ports as safe-fail test doubles', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );

      expect(getIt<LocalStorePort>(), isA<UnconfiguredLocalStore>());
      expect(getIt<CloudSessionPort>(), isA<UnconfiguredCloudSession>());
      expect(getIt<CloudSyncPort>(), isA<UnconfiguredCloudSync>());
      expect(getIt<CredentialVaultPort>(), isA<UnconfiguredCredentialVault>());
      expect(getIt<ConnectivityPort>(), isA<UnconfiguredConnectivity>());
      expect(
        getIt<PlatformCapabilityPort>(),
        isA<UnconfiguredPlatformCapability>(),
      );
    });

    test('resolves the bootstrap use case and the Foundation Cubit', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );

      expect(getIt<FoundationCubit>(), isA<FoundationCubit>());
      expect(getIt<FoundationCubit>(), isNot(same(getIt<FoundationCubit>())));
    });

    test('port operations report a blocking configuration failure', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );

      final result = await getIt<LocalStorePort>().readPreference('locale');
      final failure = result.failureOrNull;
      expect(failure, isNotNull);
      expect(failure!.category, AppFailureCategory.configuration);
      expect(failure.recoverable, isFalse);
      expect(failure.messageKey, kFoundationUnconfiguredMessageKey);
      expect(failure.technicalCause, isNull);
    });

    test('credential vault operations never return secret material', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );

      final read = await getIt<CredentialVaultPort>().readSecret('db-key');
      expect(read.valueOrNull, isNull);
      expect(read.failureOrNull, isNotNull);
    });
  });

  group('normal application composition', () {
    test('default launch resolves real Foundation adapters', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'namaa_normal_launch_',
      );
      final dbPath = <String>[
        tempDir.path,
        'foundation_encrypted.db',
      ].join(Platform.pathSeparator);

      // Normal startup uses real Foundation adapters by default.
      await configureDependencies(
        secureStoreOverride: InMemorySecureKeyValueStore(),
        databasePathOverride: dbPath,
      );

      expect(getIt<LocalStorePort>(), isA<DriftLocalStore>());
      expect(getIt<CloudSessionPort>(), isA<SupabaseSessionAdapter>());
      expect(getIt<CloudSyncPort>(), isA<SupabaseSyncAdapter>());
      expect(getIt<CredentialVaultPort>(), isA<SecureCredentialVault>());
      expect(getIt<FoundationCubit>(), isA<FoundationCubit>());

      // Close the opened database
      final store = getIt<LocalStorePort>() as DriftLocalStore;
      await store.database.close();
      await tempDir.delete(recursive: true);
    });

    test(
      'vault access failure reaches a safe blocking state instead of crashing',
      () async {
        await configureDependencies(secureStoreOverride: _FailingSecureStore());

        // Registers safe-fail doubles so the app remains valid.
        expect(getIt<LocalStorePort>(), isA<UnconfiguredLocalStore>());
        final cubit = getIt<FoundationCubit>();
        expect(cubit.state, isA<FoundationStartup>());

        await cubit.bootstrap();
        expect(
          cubit.state,
          anyOf(
            isA<FoundationBlockingFailure>(),
            isA<FoundationRecoverableFailure>(),
          ),
        );
      },
    );

    test(
      'database opening failure reaches a safe failure state instead of crashing',
      () async {
        await configureDependencies(
          secureStoreOverride: InMemorySecureKeyValueStore(),
          // Pointing to an invalid directory path causes database open to fail.
          databasePathOverride: '\x00invalid_db_path',
        );

        expect(getIt<LocalStorePort>(), isA<UnconfiguredLocalStore>());
        final cubit = getIt<FoundationCubit>();
        await cubit.bootstrap();
        expect(
          cubit.state,
          anyOf(
            isA<FoundationBlockingFailure>(),
            isA<FoundationRecoverableFailure>(),
          ),
        );
      },
    );

    test('can be reconfigured repeatedly without throwing', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );
      await configureDependencies(environment: FoundationEnvironment.test);

      expect(getIt<LocalStorePort>(), isA<DriftLocalStore>());
      expect(getIt<CloudSessionPort>(), isA<SupabaseSessionAdapter>());

      final store = getIt<LocalStorePort>() as DriftLocalStore;
      await store.database.close();
    });
  });
}
