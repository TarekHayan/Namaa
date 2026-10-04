import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_client_factory.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/default_connectivity_port.dart';
import 'package:namma_project/core/platform/platform_capability_reporter.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';

/// Target-capability coverage for T053.
///
/// These tests use only Foundation adapters and the local Supabase client
/// configuration. They never contact a production endpoint and introduce no
/// product-domain behavior.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'validates configured Foundation adapters on the current target',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'namaa_platform_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final database = await FoundationDatabase.openEncrypted(
        path: '${directory.path}${Platform.pathSeparator}foundation.db',
        key: List<int>.filled(32, 7),
      );
      addTearDown(database.close);
      final store = DriftLocalStore(database);
      expect(
        (await store.savePreference('appearance', 'system')).failureOrNull,
        isNull,
      );
      expect((await store.readPreference('appearance')).valueOrNull, 'system');

      const vaultKey = 'namaa.foundation.platform_test_probe';
      const vaultValue = 'foundation-platform-probe';
      final vault = SecureCredentialVault(
        store: FlutterSecureKeyValueStore(),
      );
      final previous = await vault.readSecret(vaultKey);
      expect(previous.failureOrNull, isNull);
      addTearDown(() async {
        if (previous.valueOrNull == null) {
          await vault.deleteSecret(vaultKey);
        } else {
          await vault.writeSecret(vaultKey, previous.valueOrNull!);
        }
      });
      expect(
        (await vault.writeSecret(vaultKey, vaultValue)).failureOrNull,
        isNull,
      );
      expect((await vault.readSecret(vaultKey)).valueOrNull, vaultValue);
      expect((await vault.deleteSecret(vaultKey)).failureOrNull, isNull);

      final client = createSupabaseClient(
        SupabaseEnvironmentConfig.localStack(
          publishableKey: 'sb_publishable_platform_probe',
        ),
      );
      addTearDown(client.dispose);
      final session = SupabaseSessionAdapter(
        gateway: SupabaseAuthGatewayImpl(client),
      );
      expect((await session.initialize()).failureOrNull, isNull);

      final connectivity = DefaultConnectivityPort();
      addTearDown(connectivity.dispose);
      final transitions = <ConnectivityStatus>[];
      final subscription = connectivity.changes.listen(transitions.add);
      addTearDown(subscription.cancel);
      connectivity.set(ConnectivityStatus.offline);
      connectivity.set(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);
      expect(transitions, <ConnectivityStatus>[
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
      ]);

      final reporter = PlatformCapabilityReporter(
        targetProvider: () => Platform.operatingSystem,
        encryptedLocalStoreProbe: () async =>
            (await store.readPreference('appearance')).valueOrNull == 'system',
        credentialVaultProbe: () async {
          final write = await vault.writeSecret(vaultKey, vaultValue);
          if (write.failureOrNull != null) {
            return false;
          }
          final read = await vault.readSecret(vaultKey);
          await vault.deleteSecret(vaultKey);
          return read.valueOrNull == vaultValue;
        },
        supabaseInitializationProbe: () async =>
            (await session.initialize()).failureOrNull == null,
        offlineReconnectProbe: () async =>
            transitions.length == 2 &&
            transitions.first == ConnectivityStatus.offline &&
            transitions.last == ConnectivityStatus.online,
      );
      final capabilities = (await reporter.report()).valueOrNull!;
      expect(capabilities, isNotEmpty);
      expect(
        capabilities.every((capability) => capability.available),
        isTrue,
      );
    },
  );

  testWidgets(
    'launches the registered root and applies every appearance mode',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'namaa_platform_app_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final database = await FoundationDatabase.openEncrypted(
        path: '${directory.path}${Platform.pathSeparator}foundation.db',
        key: List<int>.filled(32, 9),
      );
      addTearDown(database.close);
      final store = DriftLocalStore(database);

      final client = createSupabaseClient(
        SupabaseEnvironmentConfig.localStack(
          publishableKey: 'sb_publishable_platform_app_probe',
        ),
      );
      addTearDown(client.dispose);
      final session = SupabaseSessionAdapter(
        gateway: SupabaseAuthGatewayImpl(client),
      );
      final foundationCubit = FoundationCubit(
        BootstrapUseCase(cloudSession: session),
      );
      final localeCubit = LocaleCubit(
        restore: RestoreLocalePreferenceUseCase(localStore: store),
        save: SaveLocalePreferenceUseCase(localStore: store),
      );
      final themeCubit = ThemeCubit(
        restore: RestoreThemePreferenceUseCase(localStore: store),
        save: SaveThemePreferenceUseCase(localStore: store),
      );
      addTearDown(foundationCubit.close);
      addTearDown(localeCubit.close);
      addTearDown(themeCubit.close);

      await tester.pumpWidget(
        FoundationApp(
          cubitOverride: foundationCubit,
          localeCubitOverride: localeCubit,
          themeCubitOverride: themeCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(kFoundationRootReadyKey), findsOneWidget);
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);

      for (final selection in <(String, ThemeMode)>[
        ('light', ThemeMode.light),
        ('dark', ThemeMode.dark),
        ('system', ThemeMode.system),
      ]) {
        await themeCubit.selectAppearance(selection.$1);
        await tester.pumpAndSettle();
        expect(app().themeMode, selection.$2);
      }

      final appRouter = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
      );
      addTearDown(appRouter.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: appRouter.router,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
        ),
      );
      appRouter.go('/unregistered-feature');
      await tester.pumpAndSettle();
      expect(find.byKey(kFoundationUnknownRouteKey), findsOneWidget);
    },
  );
}
