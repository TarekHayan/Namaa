/// The Foundation composition root: the one place where ports are bound to
/// adapters.
///
/// Domain never registers or resolves SDK instances; only this composition
/// surface wires implementations behind the ports
/// (specs/001-namaa-foundation/plan.md, Structure Decision).
library;

import 'package:get_it/get_it.dart';
import 'package:namma_project/app/composition/unconfigured_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';

/// The environments the composition root can prepare.
enum FoundationEnvironment { unconfigured, local, test, nonProduction }

/// Configures the dependency graph for [environment].
///
/// Until environment-specific adapters are wired (US1, T037), every
/// environment resolves the safe-fail doubles from
/// `unconfigured_adapters.dart`: all six ports report blocking configuration
/// failures instead of touching infrastructure.
Future<void> configureDependencies({
  FoundationEnvironment environment = FoundationEnvironment.unconfigured,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();

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

  getIt.registerLazySingleton<BootstrapUseCase>(
    () => BootstrapUseCase(cloudSession: getIt<CloudSessionPort>()),
  );
  getIt.registerFactory<FoundationCubit>(
    () => FoundationCubit(getIt<BootstrapUseCase>()),
  );
}
