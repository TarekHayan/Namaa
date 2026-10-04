/// Target-capability reporting at the outer platform boundary.
library;

import 'dart:io';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

/// Supplies a target identifier without letting Platform leak into Domain or
/// application use cases.
typedef PlatformTargetProvider = String Function();

/// Executes one non-secret, infrastructure-owned capability check.
///
/// A probe returns `false` when its configured adapter is unavailable. Any
/// unexpected exception is also converted into an unavailable capability so
/// one failed adapter cannot prevent the remaining checks from being reported.
typedef PlatformCapabilityProbe = Future<bool> Function();

/// Reports whether the current target is one of Namaa's approved Flutter
/// targets and which Foundation adapters are configured for target validation.
///
/// This is a report of the configured platform boundary, not a replacement
/// for the executable platform validation matrix required before production
/// lock-in.
class PlatformCapabilityReporter implements PlatformCapabilityPort {
  PlatformCapabilityReporter({
    PlatformTargetProvider? targetProvider,
    PlatformCapabilityProbe? encryptedLocalStoreProbe,
    PlatformCapabilityProbe? credentialVaultProbe,
    PlatformCapabilityProbe? supabaseInitializationProbe,
    PlatformCapabilityProbe? offlineReconnectProbe,
  }) : _targetProvider = targetProvider ?? (() => Platform.operatingSystem),
       _encryptedLocalStoreProbe = encryptedLocalStoreProbe,
       _credentialVaultProbe = credentialVaultProbe,
       _supabaseInitializationProbe = supabaseInitializationProbe,
       _offlineReconnectProbe = offlineReconnectProbe;

  final PlatformTargetProvider _targetProvider;
  final PlatformCapabilityProbe? _encryptedLocalStoreProbe;
  final PlatformCapabilityProbe? _credentialVaultProbe;
  final PlatformCapabilityProbe? _supabaseInitializationProbe;
  final PlatformCapabilityProbe? _offlineReconnectProbe;

  static const Set<String> _supportedTargets = <String>{
    'android',
    'ios',
    'windows',
    'macos',
    'linux',
  };

  @override
  Future<AppResult<List<PlatformCapability>>> report() async {
    try {
      final target = _targetProvider().toLowerCase();
      final supported = _supportedTargets.contains(target);
      final detail = supported
          ? 'Foundation adapters configured for $target; validate on this target before production lock-in.'
          : 'Unsupported Foundation target: $target.';
      final encryptedLocalStore = await _probe(
        supported: supported,
        probe: _encryptedLocalStoreProbe,
      );
      final credentialVault = await _probe(
        supported: supported,
        probe: _credentialVaultProbe,
      );
      final supabaseInitialization = await _probe(
        supported: supported,
        probe: _supabaseInitializationProbe,
      );
      final offlineReconnect = await _probe(
        supported: supported,
        probe: _offlineReconnectProbe,
      );
      return AppResult<List<PlatformCapability>>.success(<PlatformCapability>[
        PlatformCapability(
          name: 'target',
          available: supported,
          detail: detail,
        ),
        PlatformCapability(
          name: 'encrypted_local_store',
          available: encryptedLocalStore,
          detail: _probeDetail(target, encryptedLocalStore),
        ),
        PlatformCapability(
          name: 'credential_vault',
          available: credentialVault,
          detail: _probeDetail(target, credentialVault),
        ),
        PlatformCapability(
          name: 'supabase_initialization',
          available: supabaseInitialization,
          detail: _probeDetail(target, supabaseInitialization),
        ),
        PlatformCapability(
          name: 'offline_reconnect',
          available: offlineReconnect,
          detail: _probeDetail(target, offlineReconnect),
        ),
      ]);
    } catch (_) {
      return AppResult<List<PlatformCapability>>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.configuration,
          messageKey: 'foundation.platform.recoverable',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<bool> _probe({
    required bool supported,
    required PlatformCapabilityProbe? probe,
  }) async {
    if (!supported || probe == null) {
      return false;
    }
    try {
      return await probe();
    } catch (_) {
      return false;
    }
  }

  String _probeDetail(String target, bool available) => available
      ? 'Validated through the configured Foundation adapter on $target.'
      : 'Unavailable or not validated through the configured adapter on $target.';
}
