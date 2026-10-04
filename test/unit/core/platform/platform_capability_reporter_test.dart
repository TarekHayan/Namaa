import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/platform/platform_capability_reporter.dart';

void main() {
  test('reports each configured adapter probe independently', () async {
    final reporter = PlatformCapabilityReporter(
      targetProvider: () => 'windows',
      encryptedLocalStoreProbe: () async => true,
      credentialVaultProbe: () async => false,
      supabaseInitializationProbe: () async {
        throw StateError('simulated adapter failure');
      },
      offlineReconnectProbe: () async => true,
    );

    final capabilities = (await reporter.report()).valueOrNull!;
    final availability = <String, bool>{
      for (final capability in capabilities)
        capability.name: capability.available,
    };

    expect(availability, <String, bool>{
      'target': true,
      'encrypted_local_store': true,
      'credential_vault': false,
      'supabase_initialization': false,
      'offline_reconnect': true,
    });
  });

  test('does not claim unprobed or unsupported capabilities', () async {
    final unprobed = PlatformCapabilityReporter(
      targetProvider: () => 'android',
    );
    final unsupported = PlatformCapabilityReporter(
      targetProvider: () => 'web',
      encryptedLocalStoreProbe: () async => true,
    );

    final unprobedCapabilities = (await unprobed.report()).valueOrNull!;
    final unsupportedCapabilities = (await unsupported.report()).valueOrNull!;

    expect(
      unprobedCapabilities
          .where((capability) => capability.name != 'target')
          .every((capability) => !capability.available),
      isTrue,
    );
    expect(
      unsupportedCapabilities.every((capability) => !capability.available),
      isTrue,
    );
  });
}
