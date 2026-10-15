/// The Foundation composition root: the one place where ports are bound to
/// adapters.
///
/// Domain never registers or resolves SDK instances; only this composition
/// surface wires implementations behind the ports
/// (specs/001-namaa-foundation/plan.md, Structure Decision).
///
/// Environment wiring (US1, T037):
/// - `unconfigured` keeps the safe-fail doubles.
/// - `test` wires the real adapters against the local Supabase stack with an
///   in-memory vault and a temporary encrypted database.
/// - `local` and `nonProduction` wire the real adapters: OS-protected vault,
///   application-support encrypted database, and Supabase adapters bound to
///   the validated environment configuration. A missing or invalid cloud
///   configuration degrades to the safe-fail cloud adapters so the app still
///   boots into a safe state.
library;

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/composition/unconfigured_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/data/cloud/supabase/secure_supabase_storage.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/platform/connectivity_adapter.dart';
import 'package:namma_project/core/platform/default_connectivity_port.dart';
import 'package:namma_project/core/platform/platform_capability_reporter.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/synchronization_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_reconciliation.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/supabase_task_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// The environments the composition root can prepare.
enum FoundationEnvironment {
  unconfigured,
  local,
  test,
  nonProduction,
  tasksPreview,
}

/// Configures the dependency graph for [environment].
Future<void> configureDependencies({
  FoundationEnvironment environment = FoundationEnvironment.local,
  SecureKeyValueStore? secureStoreOverride,
  String? databasePathOverride,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();

  if (environment == FoundationEnvironment.unconfigured) {
    _registerSafeFail(getIt);
    _registerUseCasesAndCubits(getIt);
    return;
  }

  // -- Real adapter wiring (test / local / nonProduction) -------------------

  try {
    final secureStore =
        secureStoreOverride ??
        (environment == FoundationEnvironment.test
            ? InMemorySecureKeyValueStore()
            : FlutterSecureKeyValueStore());
    final vault = SecureCredentialVault(store: secureStore);
    getIt.registerLazySingleton<CredentialVaultPort>(() => vault);

    final key = await resolveDatabaseKey(vault);
    final dbPath = databasePathOverride ?? await _databasePath(environment);
    final database = await FoundationDatabase.openEncrypted(
      path: dbPath,
      key: key,
    );
    getIt.registerSingleton<FoundationDatabase>(
      database,
      dispose: (value) => value.close(),
    );
    final localStore = DriftLocalStore(database);
    getIt.registerLazySingleton<LocalStorePort>(() => localStore);
    const taskCodec = TaskPayloadCodec();
    getIt.registerLazySingleton<TaskPayloadCodec>(() => taskCodec);

    final preview = environment == FoundationEnvironment.tasksPreview;
    final cloud = preview
        ? null
        : await _cloudSessionFor(environment, secureStore: secureStore);
    final session = preview ? const TasksPreviewSession() : cloud!.adapter;
    getIt.registerLazySingleton<CloudSessionPort>(() => session);
    if (preview) {
      getIt.registerLazySingleton<CloudSyncPort>(() => UnconfiguredCloudSync());
      getIt.registerLazySingleton<TaskRemoteReaderPort>(
        () => UnconfiguredTaskRemoteReader(),
      );
      getIt.registerLazySingleton<TaskAwardRemoteReaderPort>(
        () => UnconfiguredTaskRemoteReader(),
      );
    } else {
      final foundationSync = SupabaseSyncAdapter(
        gateway: SupabaseProbeGatewayImpl(cloud!.client),
      );
      final taskGateway = SupabaseTaskGatewayImpl(cloud.client);
      final taskSyncAdapter = SupabaseTaskSyncAdapter(gateway: taskGateway);
      getIt.registerLazySingleton<SupabaseTaskGateway>(() => taskGateway);
      getIt.registerLazySingleton<CloudSyncPort>(
        () => EntityDispatchRouter(
          foundationAdapter: foundationSync,
          taskAdapter: taskSyncAdapter,
        ),
      );
      final taskReader = SupabaseTaskReader(
        gateway: taskGateway,
        codec: taskCodec,
      );
      getIt.registerLazySingleton<TaskRemoteReaderPort>(() => taskReader);
      getIt.registerLazySingleton<TaskAwardRemoteReaderPort>(() => taskReader);
    }

    getIt.registerLazySingleton<ConnectivityPort>(
      () => environment == FoundationEnvironment.test || preview
          ? DefaultConnectivityPort()
          : ConnectivityAdapter(Connectivity()),
    );
    getIt.registerLazySingleton<PlatformCapabilityPort>(
      () => PlatformCapabilityReporter(
        encryptedLocalStoreProbe: () async =>
            (await localStore.readPreference(
              FoundationPreferenceKey.appearance.name,
            )).failureOrNull ==
            null,
        credentialVaultProbe: () async =>
            (await vault.readSecret(
              'namaa.foundation.capability_probe',
            )).failureOrNull ==
            null,
        supabaseInitializationProbe: () async =>
            !preview && (await session.initialize()).failureOrNull == null,
        offlineReconnectProbe: () async {
          final connectivity = getIt<ConnectivityPort>();
          connectivity.current;
          connectivity.changes;
          return true;
        },
      ),
    );

    getIt.registerLazySingleton<PendingSynchronizationEngine>(
      () => preview
          ? const TasksPreviewSynchronization()
          : SynchronizationCoordinator(
              localStore: localStore,
              cloudSession: session,
              cloudSync: getIt<CloudSyncPort>(),
            ),
    );

    getIt.registerLazySingleton<TaskRepository>(
      () => DriftTaskRepository(database: database, codec: taskCodec),
    );
    getIt.registerLazySingleton<AwardLedgerPort>(
      () => DriftAwardLedger(database),
    );
    getIt.registerLazySingleton<TaskCompletionUnitOfWork>(
      () => DriftTaskCompletionUnitOfWork(
        database: database,
        codec: taskCodec,
        awardLedger: getIt<AwardLedgerPort>(),
      ),
    );
    getIt.registerLazySingleton<TaskReconciliationPort>(
      () => TaskReconciler(
        repository: getIt<TaskRepository>(),
        localStore: localStore,
        codec: taskCodec,
      ),
    );
    if (!preview) {
      getIt.registerLazySingleton<TaskSyncService>(
        () => TaskSyncService(
          session: session,
          connectivity: getIt<ConnectivityPort>(),
          outbound: getIt<PendingSynchronizationEngine>(),
          remoteReader: getIt<TaskRemoteReaderPort>(),
          reconciler: getIt<TaskReconciliationPort>(),
          awardReader: getIt<TaskAwardRemoteReaderPort>(),
          awardLedger: getIt<AwardLedgerPort>(),
        ),
        dispose: (service) => service.dispose(),
      );
    }

    _registerUseCasesAndCubits(getIt, enableTaskSync: !preview);
  } catch (error) {
    // If vault access, database opening, migration, or cloud configuration fails,
    // safe-fail doubles are registered with an initialization failure so the
    // application reaches a safe recoverable or blocking UI state instead of
    // crashing before runApp().
    await getIt.reset();
    _registerSafeFail(getIt);

    final AppFailure failure;
    if (error is AppFailure) {
      failure = error;
    } else if (error is ConfigurationError) {
      failure = AppFailure.blocking(
        category: AppFailureCategory.configuration,
        messageKey: kMessageKeyBootstrapBlocking,
        occurredAt: DateTime.now().toUtc(),
        technicalCause: error.message,
      );
    } else {
      failure = AppFailure.blocking(
        category: AppFailureCategory.persistence,
        messageKey: kMessageKeyBootstrapBlocking,
        occurredAt: DateTime.now().toUtc(),
        technicalCause: error.toString(),
      );
    }
    _registerUseCasesAndCubits(getIt, initializationFailure: failure);
  }
}

void _registerSafeFail(GetIt getIt) {
  getIt.registerLazySingleton<LocalStorePort>(() => UnconfiguredLocalStore());
  getIt.registerLazySingleton<CloudSessionPort>(
    () => UnconfiguredCloudSession(),
  );
  getIt.registerLazySingleton<CloudSyncPort>(() => UnconfiguredCloudSync());
  getIt.registerLazySingleton<CredentialVaultPort>(
    () => UnconfiguredCredentialVault(),
  );
  getIt.registerLazySingleton<ConnectivityPort>(
    () => UnconfiguredConnectivity(),
  );
  getIt.registerLazySingleton<PlatformCapabilityPort>(
    () => UnconfiguredPlatformCapability(),
  );
  getIt.registerLazySingleton<PendingSynchronizationEngine>(
    () => UnconfiguredEngine(),
  );
  getIt.registerLazySingleton<TaskRepository>(
    () => UnconfiguredTaskRepository(),
  );
  getIt.registerLazySingleton<AwardLedgerPort>(() => UnconfiguredAwardLedger());
  getIt.registerLazySingleton<TaskCompletionUnitOfWork>(
    () => UnconfiguredTaskCompletionUnitOfWork(),
  );
  getIt.registerLazySingleton<TaskRemoteReaderPort>(
    () => UnconfiguredTaskRemoteReader(),
  );
  getIt.registerLazySingleton<TaskAwardRemoteReaderPort>(
    () => UnconfiguredTaskRemoteReader(),
  );
  getIt.registerLazySingleton<TaskReconciliationPort>(
    () => UnconfiguredTaskReconciler(),
  );
  getIt.registerLazySingleton<TaskSyncService>(
    () => TaskSyncService(
      session: getIt<CloudSessionPort>(),
      connectivity: getIt<ConnectivityPort>(),
      outbound: getIt<PendingSynchronizationEngine>(),
      remoteReader: getIt<TaskRemoteReaderPort>(),
      reconciler: getIt<TaskReconciliationPort>(),
      awardReader: getIt<TaskAwardRemoteReaderPort>(),
      awardLedger: getIt<AwardLedgerPort>(),
    ),
    dispose: (service) => service.dispose(),
  );
}

void _registerUseCasesAndCubits(
  GetIt getIt, {
  AppFailure? initializationFailure,
  bool enableTaskSync = true,
}) {
  getIt.registerLazySingleton<TaskCommands>(
    () => TaskCommands(
      repository: getIt<TaskRepository>(),
      session: getIt<CloudSessionPort>(),
    ),
  );
  getIt.registerLazySingleton<TaskCompletionService>(
    () => TaskCompletionService(
      repository: getIt<TaskRepository>(),
      unitOfWork: getIt<TaskCompletionUnitOfWork>(),
      session: getIt<CloudSessionPort>(),
    ),
  );
  getIt.registerLazySingleton<BootstrapUseCase>(
    () => BootstrapUseCase(
      cloudSession: getIt<CloudSessionPort>(),
      initializationFailure: initializationFailure,
    ),
  );
  getIt.registerLazySingleton<SynchronizePendingUseCase>(
    () => SynchronizePendingUseCase(getIt<PendingSynchronizationEngine>()),
  );
  getIt.registerLazySingleton<RestoreLocalePreferenceUseCase>(
    () => RestoreLocalePreferenceUseCase(localStore: getIt<LocalStorePort>()),
  );
  getIt.registerLazySingleton<SaveLocalePreferenceUseCase>(
    () => SaveLocalePreferenceUseCase(localStore: getIt<LocalStorePort>()),
  );
  getIt.registerLazySingleton<RestoreThemePreferenceUseCase>(
    () => RestoreThemePreferenceUseCase(localStore: getIt<LocalStorePort>()),
  );
  getIt.registerLazySingleton<SaveThemePreferenceUseCase>(
    () => SaveThemePreferenceUseCase(localStore: getIt<LocalStorePort>()),
  );
  getIt.registerFactory<FoundationCubit>(
    () => FoundationCubit(getIt<BootstrapUseCase>()),
  );
  getIt.registerFactory<LocaleCubit>(
    () => LocaleCubit(
      restore: getIt<RestoreLocalePreferenceUseCase>(),
      save: getIt<SaveLocalePreferenceUseCase>(),
    ),
  );
  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(
      restore: getIt<RestoreThemePreferenceUseCase>(),
      save: getIt<SaveThemePreferenceUseCase>(),
    ),
  );
  getIt.registerFactory<SynchronizationCubit>(
    () => SynchronizationCubit(
      synchronize: getIt<SynchronizePendingUseCase>(),
      connectivity: getIt<ConnectivityPort>(),
    ),
  );
  getIt.registerFactory<TasksCubit>(
    () => TasksCubit(
      repository: getIt<TaskRepository>(),
      commands: getIt<TaskCommands>(),
      completionService: getIt<TaskCompletionService>(),
      awardLedger: getIt<AwardLedgerPort>(),
      localDate: _systemLocalDate,
      syncService: enableTaskSync ? getIt<TaskSyncService>() : null,
    ),
  );
}

DateTime _systemLocalDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Cloud session adapter bound to the validated environment configuration,
/// together with its client for the sync adapter.
///
/// A missing or invalid non-production configuration (for example no
/// injected `NAMAA_SUPABASE_URL`) falls back to the local-stack binding so
/// the app still boots safely; cloud operations then fail recoverably until
/// a valid configuration is provided.
Future<({SupabaseSessionAdapter adapter, SupabaseClient client})>
_cloudSessionFor(
  FoundationEnvironment environment, {
  required SecureKeyValueStore secureStore,
}) async {
  final config = switch (environment) {
    FoundationEnvironment.local ||
    FoundationEnvironment.test => _localStackConfig(),
    FoundationEnvironment.nonProduction => _nonProductionConfig(),
    _ => _localStackConfig(),
  };
  final client = environment == FoundationEnvironment.test
      ? createSupabaseClient(config)
      : await createPersistentSupabaseClient(
          config,
          sessionStorage: SecureSupabaseSessionStorage(
            store: secureStore,
            persistSessionKey: 'namaa.supabase.${config.url.host}.session',
          ),
          pkceStorage: SecureSupabasePkceStorage(store: secureStore),
        );
  return (
    adapter: SupabaseSessionAdapter(gateway: SupabaseAuthGatewayImpl(client)),
    client: client,
  );
}

SupabaseEnvironmentConfig _localStackConfig() {
  const key = String.fromEnvironment('NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY');
  return SupabaseEnvironmentConfig.localStack(
    publishableKey: key.isEmpty ? kLocalStackFallbackKey : key,
  );
}

SupabaseEnvironmentConfig _nonProductionConfig() {
  try {
    return SupabaseEnvironmentConfig.isolatedNonProduction();
  } on ConfigurationError {
    // An unconfigured non-production run must still boot safely; cloud
    // operations against the local stack fail recoverably instead.
    return SupabaseEnvironmentConfig.localStack(
      publishableKey: kLocalStackFallbackKey,
    );
  }
}

/// Temporary encrypted database for the test environment; the
/// application-support directory for device environments.
Future<String> _databasePath(FoundationEnvironment environment) async {
  if (environment == FoundationEnvironment.test) {
    final temp = await Directory.systemTemp.createTemp('namaa_test_db_');
    return <String>[
      temp.path,
      'foundation_encrypted.db',
    ].join(Platform.pathSeparator);
  }
  final support = await getApplicationSupportDirectory();
  return <String>[
    support.path,
    'foundation_encrypted.db',
  ].join(Platform.pathSeparator);
}
