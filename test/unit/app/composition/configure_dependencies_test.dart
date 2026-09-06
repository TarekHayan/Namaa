import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/composition/unconfigured_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('unconfigured composition root', () {
    test('resolves all six ports as safe-fail test doubles', () async {
      await configureDependencies();

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
      await configureDependencies();

      expect(getIt<FoundationCubit>(), isA<FoundationCubit>());
      expect(getIt<FoundationCubit>(), isNot(same(getIt<FoundationCubit>())));
    });

    test('port operations report a blocking configuration failure', () async {
      await configureDependencies();

      final result = await getIt<LocalStorePort>().readPreference('locale');
      final failure = result.failureOrNull;
      expect(failure, isNotNull);
      expect(failure!.category, AppFailureCategory.configuration);
      expect(failure.recoverable, isFalse);
      expect(failure.messageKey, kFoundationUnconfiguredMessageKey);
      expect(failure.technicalCause, isNull);
    });

    test('credential vault operations never return secret material', () async {
      await configureDependencies();

      final read = await getIt<CredentialVaultPort>().readSecret('db-key');
      expect(read.valueOrNull, isNull);
      expect(read.failureOrNull, isNotNull);
    });

    test('can be reconfigured repeatedly without throwing', () async {
      await configureDependencies();
      await configureDependencies(environment: FoundationEnvironment.test);

      expect(getIt<LocalStorePort>(), isA<UnconfiguredLocalStore>());
    });
  });
}
