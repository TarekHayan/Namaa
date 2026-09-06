/// Safe-fail test-double registration surface for the Foundation composition
/// root.
///
/// Every adapter reports a blocking configuration failure instead of touching
/// infrastructure, so an unconfigured or misconfigured app still boots into a
/// safe startup state
/// (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';

/// Message key reported by every unconfigured adapter.
const String kFoundationUnconfiguredMessageKey = kMessageKeyUnconfigured;

AppFailure _unconfiguredFailure() => AppFailure.blocking(
  category: AppFailureCategory.configuration,
  messageKey: kFoundationUnconfiguredMessageKey,
  // Fixed deterministic instant; the unconfigured double has no clock.
  occurredAt: DateTime.utc(1970),
);

class UnconfiguredLocalStore implements LocalStorePort {
  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> savePreference(String key, String value) async =>
      AppResult<void>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async => AppResult<void>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async =>
      AppResult<List<PendingChangeRecord>>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  ) async => AppResult<void>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async =>
      AppResult<void>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async => AppResult<MigrationOutcome>.failure(_unconfiguredFailure());
}

class UnconfiguredCloudSession implements CloudSessionPort {
  @override
  Future<AppResult<void>> initialize() async =>
      AppResult<void>.failure(_unconfiguredFailure());

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.failure(_unconfiguredFailure());
}

class UnconfiguredCloudSync implements CloudSyncPort {
  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async => AppResult<DispatchOutcome>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async => AppResult<RemoteVersion?>.failure(_unconfiguredFailure());
}

class UnconfiguredCredentialVault implements CredentialVaultPort {
  @override
  Future<AppResult<String?>> readSecret(String key) async =>
      AppResult<String?>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> writeSecret(String key, String secret) async =>
      AppResult<void>.failure(_unconfiguredFailure());

  @override
  Future<AppResult<void>> deleteSecret(String key) async =>
      AppResult<void>.failure(_unconfiguredFailure());
}

class UnconfiguredConnectivity implements ConnectivityPort {
  @override
  ConnectivityStatus get current => ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get changes => const Stream.empty();
}

class UnconfiguredPlatformCapability implements PlatformCapabilityPort {
  @override
  Future<AppResult<List<PlatformCapability>>> report() async =>
      AppResult<List<PlatformCapability>>.failure(_unconfiguredFailure());
}
