import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/composition/unconfigured_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/platform/platform_capability_reporter.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_state.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

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

    test('resolves the bootstrap, locale, and theme Cubits', () async {
      await configureDependencies(
        environment: FoundationEnvironment.unconfigured,
      );

      expect(getIt<FoundationCubit>(), isA<FoundationCubit>());
      expect(getIt<FoundationCubit>(), isNot(same(getIt<FoundationCubit>())));
      expect(getIt<LocaleCubit>(), isA<LocaleCubit>());
      expect(getIt<LocaleCubit>(), isNot(same(getIt<LocaleCubit>())));
      expect(getIt<ThemeCubit>(), isA<ThemeCubit>());
      expect(getIt<ThemeCubit>(), isNot(same(getIt<ThemeCubit>())));
      expect(getIt<TaskCommands>(), isA<TaskCommands>());
      expect(getIt<AwardLedgerPort>(), isA<UnconfiguredAwardLedger>());
      expect(
        getIt<TaskCompletionUnitOfWork>(),
        isA<UnconfiguredTaskCompletionUnitOfWork>(),
      );
      expect(getIt<TaskCompletionService>(), isA<TaskCompletionService>());
      expect(
        getIt<TaskAwardRemoteReaderPort>(),
        isA<UnconfiguredTaskRemoteReader>(),
      );
      final firstTasksCubit = getIt<TasksCubit>();
      final secondTasksCubit = getIt<TasksCubit>();
      expect(firstTasksCubit, isA<TasksCubit>());
      expect(firstTasksCubit, isNot(same(secondTasksCubit)));
      await firstTasksCubit.close();
      await secondTasksCubit.close();
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
    test('local Tasks trial works without sign-in and keeps work', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'namaa_tasks_preview_',
      );
      final dbPath = <String>[
        tempDir.path,
        'foundation_encrypted.db',
      ].join(Platform.pathSeparator);
      final secureStore = InMemorySecureKeyValueStore();
      addTearDown(() async {
        await getIt.reset();
        await tempDir.delete(recursive: true);
      });

      await configureDependencies(
        environment: FoundationEnvironment.tasksPreview,
        secureStoreOverride: secureStore,
        databasePathOverride: dbPath,
      );
      expect(getIt<CloudSessionPort>(), isA<TasksPreviewSession>());
      expect(getIt<CloudSyncPort>(), isA<UnconfiguredCloudSync>());
      expect(getIt.isRegistered<TaskSyncService>(), isFalse);
      final session = getIt<CloudSessionPort>();
      expect((await session.initialize()).failureOrNull, isNull);
      expect(
        (await session.obtainSyncContext()).valueOrNull?.accountId,
        kTasksPreviewAccountId,
      );

      final tasksCubit = getIt<TasksCubit>();
      final ready = tasksCubit.stream
          .firstWhere((state) => state is TasksReady)
          .timeout(const Duration(seconds: 5));
      await tasksCubit.load(kTasksPreviewAccountId);
      await ready;
      final created = await tasksCubit.createTask(
        const CreateTaskInput(title: 'Trial task'),
      );
      expect(created.failureOrNull, isNull);
      final taskId = created.valueOrNull!.id;

      await tasksCubit.close();
      await getIt.reset();
      await configureDependencies(
        environment: FoundationEnvironment.tasksPreview,
        secureStoreOverride: secureStore,
        databasePathOverride: dbPath,
      );
      final restored = await getIt<TaskRepository>().readTask(
        accountId: kTasksPreviewAccountId,
        taskId: taskId,
      );
      expect(restored.valueOrNull?.title, 'Trial task');
    });

    test(
      'Mind Maps uses the Tasks preview owner and survives restart',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'namaa_maps_preview_',
        );
        final dbPath = <String>[
          tempDir.path,
          'foundation_encrypted.db',
        ].join(Platform.pathSeparator);
        final secureStore = InMemorySecureKeyValueStore();
        addTearDown(() async {
          await getIt.reset();
          await tempDir.delete(recursive: true);
        });
        await configureDependencies(
          environment: FoundationEnvironment.tasksPreview,
          secureStoreOverride: secureStore,
          databasePathOverride: dbPath,
        );
        expect(getIt<MapRepository>(), isA<DriftMapRepository>());
        final created = await getIt<MapCommands>().createMap(
          title: 'Preview map',
        );
        expect(created.failureOrNull, isNull);
        expect(created.valueOrNull!.ownerId, kTasksPreviewAccountId);
        final cubit = getIt<MapLibraryCubit>();
        final ready = cubit.stream.firstWhere(
          (state) => state is MapLibraryReady,
        );
        await cubit.load(kTasksPreviewAccountId);
        expect(
          (await ready as MapLibraryReady).maps.single.map.title,
          'Preview map',
        );
        await cubit.close();
        await getIt.reset();
        await configureDependencies(
          environment: FoundationEnvironment.tasksPreview,
          secureStoreOverride: secureStore,
          databasePathOverride: dbPath,
        );
        final restored = await getIt<MapRepository>().readGraph(
          ownerId: kTasksPreviewAccountId,
          mapId: created.valueOrNull!.id,
        );
        expect(
          restored.valueOrNull?.nodes.single.id,
          created.valueOrNull!.centralNodeId,
        );
      },
    );

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
      expect(getIt<CloudSyncPort>(), isA<EntityDispatchRouter>());
      expect(getIt<TaskRepository>(), isA<DriftTaskRepository>());
      expect(getIt<TaskCommands>(), isA<TaskCommands>());
      expect(getIt<AwardLedgerPort>(), isA<DriftAwardLedger>());
      expect(
        getIt<TaskCompletionUnitOfWork>(),
        isA<DriftTaskCompletionUnitOfWork>(),
      );
      expect(getIt<TaskCompletionService>(), isA<TaskCompletionService>());
      expect(getIt.isRegistered<TaskAwardRemoteReaderPort>(), isTrue);
      expect(getIt.isRegistered<TaskSyncService>(), isTrue);
      expect(getIt.isRegistered<TasksCubit>(), isTrue);
      expect(getIt<CredentialVaultPort>(), isA<SecureCredentialVault>());
      expect(
        getIt<PlatformCapabilityPort>(),
        isA<PlatformCapabilityReporter>(),
      );
      expect(getIt<FoundationCubit>(), isA<FoundationCubit>());
      expect(getIt<LocaleCubit>(), isA<LocaleCubit>());
      expect(getIt<ThemeCubit>(), isA<ThemeCubit>());

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
