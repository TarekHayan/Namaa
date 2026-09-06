/// Foundation application ports: the only surface through which Domain and
/// Application code reaches local persistence, cloud, connectivity, and
/// platform capabilities.
///
/// Concrete Supabase, Drift, secure-storage, and platform implementations
/// remain outside Domain and Application code
/// (specs/001-namaa-foundation/contracts/application-boundaries.md). Every
/// operation reports outcomes through [AppResult]; port types never leak SDK
/// or infrastructure types.
library;

import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';

// ---------------------------------------------------------------------------
// Shared contract enums
// ---------------------------------------------------------------------------

/// The intent of one durable change.
enum ChangeKind { create, update, delete }

/// Lifecycle of a durable pending operation.
///
/// `pending -> dispatching -> acknowledged`, or back to `pending` on a
/// recoverable failure, or to `conflict` on a remote version conflict.
enum PendingChangeState { pending, dispatching, acknowledged, conflict }

// ---------------------------------------------------------------------------
// Local Store port
// ---------------------------------------------------------------------------

/// A local record change to commit together with its pending operation in one
/// atomic transaction.
class LocalRecordChange {
  const LocalRecordChange({
    required this.recordId,
    required this.payload,
    required this.versionTimestamp,
    this.accountId,
  });

  /// Unique, non-empty persisted-record identifier.
  final String recordId;

  /// Owning account identifier; required when account-scoped.
  final String? accountId;

  /// Encrypted-at-rest probe payload; not a product schema.
  final String payload;

  /// Required UTC instant used as the change-ordering input.
  final DateTime versionTimestamp;
}

/// The pending operation half of an atomic local commit.
class PendingChangeRequest {
  const PendingChangeRequest({
    required this.operationId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.serializedChange,
    required this.createdAt,
    required this.versionTimestamp,
  });

  /// Globally unique, immutable idempotency key for one remote effect.
  final String operationId;

  /// Owning account identifier.
  final String accountId;

  /// Target record type; maps to the owning feature.
  final String entityType;

  /// Target record identifier.
  final String entityId;

  /// Create, update, or delete intent.
  final ChangeKind kind;

  /// Cloud-adapter input; encrypted at rest by the implementation.
  final String serializedChange;

  /// Required UTC queue audit instant.
  final DateTime createdAt;

  /// Required UTC ordering value of the underlying record change.
  final DateTime versionTimestamp;
}

/// A durable pending operation as read back from the store.
class PendingChangeRecord {
  const PendingChangeRecord({
    required this.operationId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.state,
    required this.attemptCount,
    required this.serializedChange,
    required this.createdAt,
    required this.versionTimestamp,
    this.lastFailureSummary,
  });

  final String operationId;
  final String accountId;
  final String entityType;
  final String entityId;
  final ChangeKind kind;
  final PendingChangeState state;

  /// Non-negative retry observability counter.
  final int attemptCount;

  /// Recoverable failure summary; contains no secret.
  final String? lastFailureSummary;
  final String serializedChange;
  final DateTime createdAt;
  final DateTime versionTimestamp;
}

/// One candidate version in a conflict record.
class RecordVersionInput {
  const RecordVersionInput({
    required this.source,
    required this.versionTimestamp,
    required this.payload,
  });

  final VersionSource source;

  /// Required UTC ordering value.
  final DateTime versionTimestamp;

  /// Encrypted-at-rest payload of the candidate version.
  final String payload;
}

/// Input for persisting a visible conflict record.
class ConflictRecordInput {
  const ConflictRecordInput({
    required this.conflictId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.activeVersion,
    required this.retainedVersion,
    required this.detectedAt,
  });

  /// Stable conflict identifier.
  final String conflictId;
  final String accountId;
  final String entityType;
  final String entityId;

  /// Newest-timestamp candidate.
  final RecordVersionInput activeVersion;

  /// Non-winning candidate, retained as visible evidence.
  final RecordVersionInput retainedVersion;

  /// Required UTC audit instant.
  final DateTime detectedAt;
}

/// Outcome of a store-driven schema migration.
class MigrationOutcome {
  const MigrationOutcome({
    required this.completedVersion,
    required this.recovered,
    this.recoveryDetail,
  });

  /// Schema version now active.
  final int completedVersion;

  /// True when a failed migration was recovered with prior data retained.
  final bool recovered;

  /// Non-secret recovery description, present after failure/recovery.
  final String? recoveryDetail;
}

/// Local encrypted persistence port.
///
/// Commit is atomic: a visible local state change cannot exist without its
/// required pending change.
abstract interface class LocalStorePort {
  Future<AppResult<String?>> readPreference(String key);

  Future<AppResult<void>> savePreference(String key, String value);

  /// Atomically commits a local record change and its pending operation.
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  );

  /// Ordered pending operations for [accountId].
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  );

  /// Marks the operation durably acknowledged; immutable afterwards.
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  );

  /// Persists a visible conflict record.
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict);

  /// Runs the automatic schema migration to [targetSchemaVersion]; failure
  /// retains prior database state and is recoverable.
  Future<AppResult<MigrationOutcome>> runMigration(int targetSchemaVersion);
}

// ---------------------------------------------------------------------------
// Cloud Session port
// ---------------------------------------------------------------------------

/// Session status without Supabase SDK types.
enum CloudSessionStatus { unknown, signedOut, signedIn }

/// Non-secret session snapshot.
class CloudSessionSnapshot {
  const CloudSessionSnapshot({required this.status, this.accountId});

  final CloudSessionStatus status;

  /// Present only when [status] is signed-in; never a token or secret.
  final String? accountId;
}

/// Non-secret authorized synchronization context.
class CloudSyncContext {
  const CloudSyncContext({required this.accountId});

  /// Remote owner for account-scoped records; never a token or secret.
  final String accountId;
}

/// Cloud session port (Supabase Auth behind the boundary).
///
/// This contract defines no authentication UI or account workflow.
abstract interface class CloudSessionPort {
  /// Ready, recoverable failure, or configuration failure.
  Future<AppResult<void>> initialize();

  Stream<CloudSessionSnapshot> observeSession();

  Future<AppResult<CloudSyncContext>> obtainSyncContext();
}

// ---------------------------------------------------------------------------
// Cloud Sync port
// ---------------------------------------------------------------------------

/// One account-scoped change dispatched to the remote boundary.
class OutboundChange {
  const OutboundChange({
    required this.operationId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.payload,
    required this.versionTimestamp,
  });

  /// Stable idempotency key; repeated dispatch of the same ID is one logical
  /// remote effect.
  final String operationId;
  final String accountId;
  final String entityType;
  final String entityId;
  final ChangeKind kind;

  /// Cloud-adapter input.
  final String payload;

  /// Required UTC ordering value of the underlying record change.
  final DateTime versionTimestamp;
}

/// Outcome of a successful dispatch that is not a failure.
sealed class DispatchOutcome {
  const DispatchOutcome();
}

/// The remote durably acknowledged the operation; it must never be
/// re-dispatched.
final class DispatchAcknowledged extends DispatchOutcome {
  const DispatchAcknowledged({
    required this.acknowledgementId,
    this.remoteVersionTimestamp,
  });

  final String acknowledgementId;

  /// Remote version timestamp when the remote exposes one.
  final DateTime? remoteVersionTimestamp;
}

/// The remote holds a different version; a conflict record must retain the
/// non-winning version.
final class DispatchVersionConflict extends DispatchOutcome {
  const DispatchVersionConflict({
    required this.remoteVersionTimestamp,
    this.remotePayload,
  });

  final DateTime remoteVersionTimestamp;
  final String? remotePayload;
}

/// A remote record version, or absence.
class RemoteVersion {
  const RemoteVersion({
    required this.entityType,
    required this.entityId,
    required this.versionTimestamp,
    this.payload,
  });

  final String entityType;
  final String entityId;
  final DateTime versionTimestamp;
  final String? payload;
}

/// Cloud synchronization port (Supabase Postgres/Data API behind the
/// boundary).
abstract interface class CloudSyncPort {
  /// Acknowledgement, recoverable failure, or remote version conflict.
  Future<AppResult<DispatchOutcome>> dispatchChange(OutboundChange change);

  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  });
}

// ---------------------------------------------------------------------------
// Credential Vault port
// ---------------------------------------------------------------------------

/// OS-protected storage port for keys, credentials, and database key
/// material.
///
/// Only secrets use this port; they are never logged or serialized into
/// failure records.
abstract interface class CredentialVaultPort {
  /// The secret, controlled absence (null), or failure.
  Future<AppResult<String?>> readSecret(String key);

  Future<AppResult<void>> writeSecret(String key, String secret);

  Future<AppResult<void>> deleteSecret(String key);
}

// ---------------------------------------------------------------------------
// Connectivity port
// ---------------------------------------------------------------------------

/// Current connectivity classification.
enum ConnectivityStatus { offline, online }

/// Connectivity observation port.
abstract interface class ConnectivityPort {
  ConnectivityStatus get current;

  /// Broadcast stream of transitions; synchronization retry orchestration
  /// subscribes to trigger retries when connectivity returns.
  Stream<ConnectivityStatus> get changes;
}

// ---------------------------------------------------------------------------
// Platform capability port
// ---------------------------------------------------------------------------

/// One reported target capability; [detail] is non-secret.
class PlatformCapability {
  const PlatformCapability({
    required this.name,
    required this.available,
    this.detail,
  });

  final String name;
  final bool available;
  final String? detail;
}

/// Target-capability reporting port
/// (specs/001-namaa-foundation/research.md, decision 5).
abstract interface class PlatformCapabilityPort {
  Future<AppResult<List<PlatformCapability>>> report();
}
