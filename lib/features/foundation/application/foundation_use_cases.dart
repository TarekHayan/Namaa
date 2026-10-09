/// Foundation application use cases.
///
/// They depend only on the Foundation ports
/// (lib/core/application/ports/foundation_ports.dart) and the Foundation
/// Domain; they never import Flutter, Drift, Supabase, routing, or
/// platform-adapter libraries.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';

DateTime _defaultNow() => DateTime.now().toUtc();

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------

/// Outcome of bootstrapping the application foundation.
final class BootstrapOutcome {
  const BootstrapOutcome({required this.cloudReady});

  /// True when the cloud session initialized; false stays recoverable.
  final bool cloudReady;
}

/// Initializes the cloud session so startup can proceed to a safe state.
class BootstrapUseCase {
  BootstrapUseCase({
    required CloudSessionPort cloudSession,
    AppFailure? initializationFailure,
  }) : _cloudSession = cloudSession,
       _initializationFailure = initializationFailure;

  final CloudSessionPort _cloudSession;
  final AppFailure? _initializationFailure;

  Future<AppResult<BootstrapOutcome>> call() async {
    final failure = _initializationFailure;
    if (failure != null) {
      return AppResult<BootstrapOutcome>.failure(failure);
    }
    final ready = await _cloudSession.initialize();
    return ready.when(
      success: (_) => AppResult<BootstrapOutcome>.success(
        const BootstrapOutcome(cloudReady: true),
      ),
      failure: (failure) => AppResult<BootstrapOutcome>.failure(failure),
    );
  }
}

// ---------------------------------------------------------------------------
// Preference restoration
// ---------------------------------------------------------------------------

/// A preference value read from the store, with fallback applied.
final class ResolvedPreference {
  const ResolvedPreference({
    required this.key,
    required this.value,
    required this.usedFallback,
  });

  final FoundationPreferenceKey key;

  /// A supported value for [key], never an invalid stored value.
  final String value;

  /// True when the stored value was missing or invalid and [value] is the
  /// safe fallback.
  final bool usedFallback;
}

/// Restores a Foundation preference, falling back to a supported value when
/// the stored value is missing or invalid (data-model: Application
/// Preference).
class RestorePreferenceUseCase {
  RestorePreferenceUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<ResolvedPreference>> call({
    required FoundationPreferenceKey key,
  }) async {
    final read = await _localStore.readPreference(key.name);
    final failure = read.failureOrNull;
    if (failure != null) {
      return AppResult<ResolvedPreference>.failure(failure);
    }
    final stored = read.valueOrNull;
    if (stored != null && key.isValidValue(stored)) {
      return AppResult<ResolvedPreference>.success(
        ResolvedPreference(key: key, value: stored, usedFallback: false),
      );
    }
    return AppResult<ResolvedPreference>.success(
      ResolvedPreference(
        key: key,
        value: key.fallbackValue,
        usedFallback: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local record commit
// ---------------------------------------------------------------------------

/// A local verification record to commit together with its pending operation.
final class CommitLocalRecordRequest {
  const CommitLocalRecordRequest({
    required this.recordId,
    required this.accountId,
    required this.payload,
    required this.versionTimestamp,
    required this.entityType,
    required this.entityId,
    required this.kind,
  });

  final String recordId;
  final String accountId;
  final String payload;
  final DateTime versionTimestamp;
  final String entityType;
  final String entityId;
  final PendingOperationKind kind;
}

/// Commits a local record change and its pending operation atomically
/// (application-boundaries: commit is atomic).
///
/// The pending operation ID is generated once here; every retry of the same
/// logical change reuses it.
class CommitLocalRecordUseCase {
  CommitLocalRecordUseCase({
    required LocalStorePort localStore,
    required String Function() generateOperationId,
    DateTime Function()? now,
  }) : _localStore = localStore,
       _generateOperationId = generateOperationId,
       _now = now ?? _defaultNow;

  final LocalStorePort _localStore;
  final String Function() _generateOperationId;
  final DateTime Function() _now;

  Future<AppResult<void>> call(CommitLocalRecordRequest request) async {
    // Validate pending-operation invariants through the Domain type first.
    final operationId = _generateOperationId();
    PendingChange.create(
      operationId: operationId,
      accountId: request.accountId,
      entityType: request.entityType,
      entityId: request.entityId,
      kind: request.kind,
      serializedChange: request.payload,
      createdAt: _now(),
      versionTimestamp: request.versionTimestamp,
    );
    return _localStore.commitLocalChange(
      LocalRecordChange(
        recordId: request.recordId,
        accountId: request.accountId,
        payload: request.payload,
        versionTimestamp: request.versionTimestamp,
      ),
      PendingChangeRequest(
        operationId: operationId,
        accountId: request.accountId,
        entityType: request.entityType,
        entityId: request.entityId,
        kind: _toChangeKind(request.kind),
        serializedChange: request.payload,
        createdAt: _now(),
        versionTimestamp: request.versionTimestamp,
      ),
    );
  }
}

ChangeKind _toChangeKind(PendingOperationKind kind) => switch (kind) {
  PendingOperationKind.create => ChangeKind.create,
  PendingOperationKind.update => ChangeKind.update,
  PendingOperationKind.delete => ChangeKind.delete,
};

// ---------------------------------------------------------------------------
// Pending synchronization and retry
// ---------------------------------------------------------------------------

/// Dispatches durable pending operations through the synchronization engine.
///
/// The durable outbox logic lives behind [PendingSynchronizationEngine]
/// (implemented in core/data); this use case is the application-layer
/// surface Cubits and other use cases call. One pass acknowledges successes
/// durably, records conflicts with retained evidence, and leaves
/// recoverable failures pending: re-running it is the retry, and operation
/// IDs never change, so remote effects stay idempotent.
class SynchronizePendingUseCase {
  SynchronizePendingUseCase(this._engine);

  final PendingSynchronizationEngine _engine;

  Future<AppResult<SyncSummary>> call() => _engine.synchronize();
}

/// Retries pending operations after a recoverable failure.
///
/// Deliberately thin: retrying is the same synchronization pass, and the
/// retained operation IDs keep remote effects idempotent.
class RetryPendingUseCase {
  RetryPendingUseCase({required SynchronizePendingUseCase synchronize})
    : _synchronize = synchronize;

  final SynchronizePendingUseCase _synchronize;

  Future<AppResult<SyncSummary>> call() => _synchronize();
}

// ---------------------------------------------------------------------------
// Conflict recording
// ---------------------------------------------------------------------------

/// Records a version conflict with retained evidence.
///
/// Distinct timestamps select the newest candidate as active; equal
/// timestamps produce a recoverable failure and no record, awaiting an
/// approved tie-breaker.
class RecordConflictUseCase {
  RecordConflictUseCase({
    required LocalStorePort localStore,
    DateTime Function()? now,
  }) : _localStore = localStore,
       _now = now ?? _defaultNow;

  final LocalStorePort _localStore;
  final DateTime Function() _now;

  Future<AppResult<void>> call({
    required String conflictId,
    required String accountId,
    required String entityType,
    required String entityId,
    required RecordVersion local,
    required RecordVersion remote,
  }) async {
    final resolution = resolveVersionConflict(local: local, remote: remote);
    if (resolution is! NewerVersionSelected) {
      return AppResult<void>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: kEqualTimestampConflictMessageKey,
          occurredAt: _now(),
          technicalCause: 'local and remote timestamps are equal',
        ),
      );
    }
    return _localStore.recordConflict(
      ConflictRecordInput(
        conflictId: conflictId,
        accountId: accountId,
        entityType: entityType,
        entityId: entityId,
        activeVersion: RecordVersionInput(
          source: resolution.active.source,
          versionTimestamp: resolution.active.versionTimestamp,
          payload: resolution.active.payload,
        ),
        retainedVersion: RecordVersionInput(
          source: resolution.retained.source,
          versionTimestamp: resolution.retained.versionTimestamp,
          payload: resolution.retained.payload,
        ),
        detectedAt: _now(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Migration recovery
// ---------------------------------------------------------------------------

/// Runs the automatic schema migration and surfaces a recoverable outcome.
///
/// A failed migration retains prior database state and is reported for
/// recovery; it never silently resets account data.
class RecoverMigrationUseCase {
  RecoverMigrationUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<MigrationOutcome>> call({
    required int targetSchemaVersion,
  }) => _localStore.runMigration(targetSchemaVersion);
}
