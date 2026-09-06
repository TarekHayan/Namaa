/// Foundation Domain value types.
///
/// The Foundation owns only cross-cutting configuration, persistence,
/// synchronization, conflict, and failure records; it defines no
/// product-domain data (specs/001-namaa-foundation/data-model.md). This file
/// must never import Flutter, Drift, Supabase, routing, notification, or
/// platform-adapter libraries.
library;

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/values/version_source.dart';

// ---------------------------------------------------------------------------
// Shared domain enums
// ---------------------------------------------------------------------------

/// Synchronization states of a Foundation local record.
enum FoundationSyncState {
  /// Present locally only; never dispatched.
  localOnly,

  /// Queued in the durable outbox, awaiting dispatch or acknowledgement.
  pending,

  /// Remotely acknowledged; never dispatched again.
  acknowledged,

  /// A version conflict retained as visible evidence.
  conflict,
}

/// Foundation-owned preference keys.
enum FoundationPreferenceKey {
  locale,
  appearance;

  /// Values accepted for this key; anything else must fall back to a
  /// supported value (data-model: Application Preference).
  Set<String> get allowedValues => switch (this) {
    FoundationPreferenceKey.locale => const {'ar', 'en'},
    FoundationPreferenceKey.appearance => const {'light', 'dark', 'system'},
  };

  /// The safe fallback value used when a stored value is missing or invalid.
  ///
  /// The locale fallback is provisional until the locale use case (US2)
  /// approves the product default; the appearance fallback is `system`.
  String get fallbackValue => switch (this) {
    FoundationPreferenceKey.locale => 'en',
    FoundationPreferenceKey.appearance => 'system',
  };

  bool isValidValue(String value) => allowedValues.contains(value);
}

/// Intent of one durable change.
enum PendingOperationKind { create, update, delete }

/// Lifecycle of a pending operation.
///
/// `pending -> dispatching -> acknowledged`, or back to `pending` on a
/// recoverable failure, or to `conflict` on a remote version conflict.
enum PendingChangeLifecycle { pending, dispatching, acknowledged, conflict }

/// Status of a retained conflict record.
enum ConflictStatus { open, resolved }

/// Lifecycle of one migration attempt.
enum MigrationJournalStatus { started, completed, failed, recovered }

/// Recoverability classification of a failure state.
enum FailureRecoverability { recoverable, blocking }

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _requireUtc(DateTime instant, String name) {
  if (!instant.isUtc) {
    throw ArgumentError.value(instant, name, 'must be a UTC instant');
  }
}

// ---------------------------------------------------------------------------
// Application Preference
// ---------------------------------------------------------------------------

/// A persisted Foundation application preference (locale, appearance).
///
/// Values are non-secret settings; secrets never live in preferences.
class ApplicationPreference {
  const ApplicationPreference._({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  /// Creates a preference after validating [value] against [key].
  ///
  /// Throws [ArgumentError] when the value is invalid for the key or
  /// [updatedAt] is not UTC.
  factory ApplicationPreference.create({
    required FoundationPreferenceKey key,
    required String value,
    required DateTime updatedAt,
  }) {
    if (!key.isValidValue(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'not a valid value for $key; allowed: ${key.allowedValues}',
      );
    }
    _requireUtc(updatedAt, 'updatedAt');
    return ApplicationPreference._(
      key: key,
      value: value,
      updatedAt: updatedAt,
    );
  }

  /// Stable, Foundation-owned preference identifier.
  final FoundationPreferenceKey key;

  /// Validated non-secret setting value.
  final String value;

  /// Required UTC instant of the last local change.
  final DateTime updatedAt;
}

// ---------------------------------------------------------------------------
// Local Record
// ---------------------------------------------------------------------------

/// A Foundation verification record persisted locally.
///
/// This is a Foundation-owned verification entity, not a generic
/// product-data container. Payloads are test/probe payloads only, encrypted
/// at rest by the local store.
class LocalRecord {
  const LocalRecord._({
    required this.recordId,
    required this.payload,
    required this.versionTimestamp,
    required this.syncState,
    required this.updatedAt,
    this.accountId,
  });

  /// Creates a record after validating its invariants.
  ///
  /// Throws [ArgumentError] when [recordId] is empty or any timestamp is
  /// not UTC.
  factory LocalRecord.create({
    required String recordId,
    required String payload,
    required DateTime versionTimestamp,
    required FoundationSyncState syncState,
    required DateTime updatedAt,
    String? accountId,
  }) {
    if (recordId.isEmpty) {
      throw ArgumentError.value(recordId, 'recordId', 'must not be empty');
    }
    _requireUtc(versionTimestamp, 'versionTimestamp');
    _requireUtc(updatedAt, 'updatedAt');
    return LocalRecord._(
      recordId: recordId,
      payload: payload,
      versionTimestamp: versionTimestamp,
      syncState: syncState,
      updatedAt: updatedAt,
      accountId: accountId,
    );
  }

  /// Unique, non-empty persisted-record identifier.
  final String recordId;

  /// Owning account identifier; required when account-scoped.
  final String? accountId;

  /// Encrypted-at-rest probe payload; not a product schema.
  final String payload;

  /// Required UTC instant used as the change-ordering input.
  final DateTime versionTimestamp;

  /// Current synchronization state; only valid transitions are allowed.
  final FoundationSyncState syncState;

  /// Required UTC audit timestamp.
  final DateTime updatedAt;
}

// ---------------------------------------------------------------------------
// Pending Change
// ---------------------------------------------------------------------------

/// A durable pending operation: the idempotency key for one remote effect.
///
/// The operation ID is globally unique and immutable; a retry always retains
/// it. An acknowledged operation is terminal and is never dispatched again.
class PendingChange {
  const PendingChange._({
    required this.operationId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.serializedChange,
    required this.createdAt,
    required this.versionTimestamp,
    required this.attemptCount,
    required this.state,
    this.lastFailureSummary,
    this.acknowledgementId,
  });

  /// Creates a pending change after validating its invariants.
  ///
  /// Throws [ArgumentError] when an identifier is empty, [attemptCount] is
  /// negative, or a timestamp is not UTC.
  factory PendingChange.create({
    required String operationId,
    required String accountId,
    required String entityType,
    required String entityId,
    required PendingOperationKind kind,
    required String serializedChange,
    required DateTime createdAt,
    required DateTime versionTimestamp,
    int attemptCount = 0,
    PendingChangeLifecycle state = PendingChangeLifecycle.pending,
  }) {
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'must not be empty',
      );
    }
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'must not be empty');
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(
        attemptCount,
        'attemptCount',
        'must not be negative',
      );
    }
    _requireUtc(createdAt, 'createdAt');
    _requireUtc(versionTimestamp, 'versionTimestamp');
    return PendingChange._(
      operationId: operationId,
      accountId: accountId,
      entityType: entityType,
      entityId: entityId,
      kind: kind,
      serializedChange: serializedChange,
      createdAt: createdAt,
      versionTimestamp: versionTimestamp,
      attemptCount: attemptCount,
      state: state,
    );
  }

  final String operationId;
  final String accountId;

  /// Target record type; maps to the owning feature.
  final String entityType;
  final String entityId;
  final PendingOperationKind kind;

  /// Cloud-adapter input; encrypted at rest.
  final String serializedChange;

  /// Required UTC queue audit instant.
  final DateTime createdAt;

  /// Required UTC ordering value of the underlying record change.
  final DateTime versionTimestamp;

  /// Non-negative retry observability counter.
  final int attemptCount;

  /// Recoverable failure summary; contains no secret.
  final String? lastFailureSummary;

  /// Remote acknowledgement; immutable after acknowledgement.
  final String? acknowledgementId;

  /// Current lifecycle state.
  final PendingChangeLifecycle state;

  /// True only for [PendingChangeLifecycle.acknowledged], the terminal state.
  bool get isTerminal => state == PendingChangeLifecycle.acknowledged;

  PendingChange _copy({
    PendingChangeLifecycle? state,
    int? attemptCount,
    String? lastFailureSummary,
    String? acknowledgementId,
  }) => PendingChange._(
    operationId: operationId,
    accountId: accountId,
    entityType: entityType,
    entityId: entityId,
    kind: kind,
    serializedChange: serializedChange,
    createdAt: createdAt,
    versionTimestamp: versionTimestamp,
    attemptCount: attemptCount ?? this.attemptCount,
    state: state ?? this.state,
    lastFailureSummary: lastFailureSummary ?? this.lastFailureSummary,
    acknowledgementId: acknowledgementId ?? this.acknowledgementId,
  );

  /// Transitions `pending -> dispatching`.
  ///
  /// Throws [StateError] when the operation is not pending.
  PendingChange markDispatching() {
    if (state != PendingChangeLifecycle.pending) {
      throw StateError(
        'Operation $operationId cannot be dispatched from $state',
      );
    }
    return _copy(state: PendingChangeLifecycle.dispatching);
  }

  /// Transitions `dispatching -> acknowledged` (terminal).
  ///
  /// The acknowledgement ID is immutable after acknowledgement; a second
  /// acknowledgement attempt throws [StateError].
  PendingChange acknowledge({required String acknowledgementId}) {
    if (state == PendingChangeLifecycle.acknowledged) {
      throw StateError(
        'Operation $operationId is already acknowledged and is terminal',
      );
    }
    if (state != PendingChangeLifecycle.dispatching) {
      throw StateError(
        'Operation $operationId cannot be acknowledged from $state',
      );
    }
    if (acknowledgementId.isEmpty) {
      throw ArgumentError.value(
        acknowledgementId,
        'acknowledgementId',
        'must not be empty',
      );
    }
    return _copy(
      state: PendingChangeLifecycle.acknowledged,
      acknowledgementId: acknowledgementId,
    );
  }

  /// Transitions `dispatching -> pending` after a recoverable failure,
  /// incrementing the attempt counter and recording a secret-free summary.
  PendingChange recordRecoverableFailure({required String summary}) {
    if (state != PendingChangeLifecycle.dispatching) {
      throw StateError(
        'Operation $operationId cannot record a failure from $state',
      );
    }
    return _copy(
      state: PendingChangeLifecycle.pending,
      attemptCount: attemptCount + 1,
      lastFailureSummary: summary,
    );
  }

  /// Transitions `dispatching -> conflict` after a remote version conflict.
  PendingChange markConflict() {
    if (state != PendingChangeLifecycle.dispatching) {
      throw StateError('Operation $operationId cannot conflict from $state');
    }
    return _copy(state: PendingChangeLifecycle.conflict);
  }
}

// ---------------------------------------------------------------------------
// Conflict Record
// ---------------------------------------------------------------------------

/// One candidate version in a conflict.
class RecordVersion {
  const RecordVersion({
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

/// Result of comparing a local and a remote record version.
sealed class VersionConflictResolution {
  const VersionConflictResolution();
}

/// Distinct timestamps: the newest candidate is active and the non-winner is
/// retained as visible evidence.
final class NewerVersionSelected extends VersionConflictResolution {
  const NewerVersionSelected({required this.active, required this.retained});

  final RecordVersion active;
  final RecordVersion retained;
}

/// Equal timestamps: no winner is selected; the conflict stays open and
/// recoverable until a tie-breaker is separately approved
/// (research decision 3).
final class EqualTimestampConflict extends VersionConflictResolution {
  const EqualTimestampConflict({required this.local, required this.remote});

  final RecordVersion local;
  final RecordVersion remote;

  bool get recoverable => true;
}

/// Selects the active version for a conflict.
///
/// Distinct timestamps choose the newest candidate as active; equal
/// timestamps produce an [EqualTimestampConflict] with no winner.
VersionConflictResolution resolveVersionConflict({
  required RecordVersion local,
  required RecordVersion remote,
}) {
  final comparison = local.versionTimestamp.compareTo(remote.versionTimestamp);
  if (comparison > 0) {
    return NewerVersionSelected(active: local, retained: remote);
  }
  if (comparison < 0) {
    return NewerVersionSelected(active: remote, retained: local);
  }
  return EqualTimestampConflict(local: local, remote: remote);
}

/// A visible conflict record retaining the non-winning version.
class ConflictRecord {
  const ConflictRecord._({
    required this.conflictId,
    required this.accountId,
    required this.entityType,
    required this.entityId,
    required this.activeVersion,
    required this.retainedVersion,
    required this.detectedAt,
  });

  /// Opens a conflict record from a resolved (distinct-timestamp) conflict.
  ///
  /// Equal-timestamp conflicts are not recorded here; they remain an open,
  /// recoverable resolution until a tie-breaker is approved.
  factory ConflictRecord.open({
    required String conflictId,
    required String accountId,
    required String entityType,
    required String entityId,
    required NewerVersionSelected resolution,
    required DateTime detectedAt,
  }) {
    if (conflictId.isEmpty) {
      throw ArgumentError.value(conflictId, 'conflictId', 'must not be empty');
    }
    _requireUtc(detectedAt, 'detectedAt');
    return ConflictRecord._(
      conflictId: conflictId,
      accountId: accountId,
      entityType: entityType,
      entityId: entityId,
      activeVersion: resolution.active,
      retainedVersion: resolution.retained,
      detectedAt: detectedAt,
    );
  }

  final String conflictId;
  final String accountId;

  /// Conflicting record identity.
  final String entityType;
  final String entityId;

  /// Newest-timestamp candidate.
  final RecordVersion activeVersion;

  /// Non-winning candidate, retained as visible evidence.
  final RecordVersion retainedVersion;

  /// Conflicts start open; resolution is a later, approved action.
  ConflictStatus get status => ConflictStatus.open;

  /// Required UTC audit instant.
  final DateTime detectedAt;
}

// ---------------------------------------------------------------------------
// Migration Journal
// ---------------------------------------------------------------------------

/// One migration attempt recorded in the automatic migration journal.
///
/// A failed migration retains prior database state and makes recovery
/// visible; it never silently resets account data.
class MigrationJournalEntry {
  const MigrationJournalEntry._({
    required this.version,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.recoveryDetail,
  });

  /// Creates the `started` entry; [version] must be positive (monotonic
  /// ordering is enforced by the store).
  factory MigrationJournalEntry.start({
    required int version,
    required DateTime startedAt,
  }) {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be positive');
    }
    _requireUtc(startedAt, 'startedAt');
    return MigrationJournalEntry._(
      version: version,
      status: MigrationJournalStatus.started,
      startedAt: startedAt,
    );
  }

  /// Schema version attempted; monotonic.
  final int version;
  final MigrationJournalStatus status;

  /// Required UTC start instant.
  final DateTime startedAt;

  /// UTC completion audit instant, set on any terminal transition.
  final DateTime? endedAt;

  /// Non-secret recovery description, present after failure/recovery.
  final String? recoveryDetail;

  MigrationJournalEntry _transition({
    required MigrationJournalStatus to,
    required DateTime at,
    String? recoveryDetail,
  }) {
    _requireUtc(at, 'at');
    const allowedFrom = {
      MigrationJournalStatus.started,
      MigrationJournalStatus.failed,
    };
    if (!allowedFrom.contains(status)) {
      throw StateError('Migration $version cannot move from $status to $to');
    }
    return MigrationJournalEntry._(
      version: version,
      status: to,
      startedAt: startedAt,
      endedAt: at,
      recoveryDetail: recoveryDetail,
    );
  }

  /// `started -> completed`.
  MigrationJournalEntry markCompleted({required DateTime at}) =>
      _transition(to: MigrationJournalStatus.completed, at: at);

  /// `started -> failed`, retaining prior state and a recovery description.
  MigrationJournalEntry markFailed({
    required String recoveryDetail,
    required DateTime at,
  }) => _transition(
    to: MigrationJournalStatus.failed,
    at: at,
    recoveryDetail: recoveryDetail,
  );

  /// `failed -> recovered`, retaining prior data with a recovery description.
  MigrationJournalEntry markRecovered({
    required String recoveryDetail,
    required DateTime at,
  }) => _transition(
    to: MigrationJournalStatus.recovered,
    at: at,
    recoveryDetail: recoveryDetail,
  );
}

// ---------------------------------------------------------------------------
// Failure State
// ---------------------------------------------------------------------------

/// A Foundation boundary outcome description.
///
/// Carries the public failure category, recoverability, and a localized
/// message key; [technicalCause] is diagnostic and must never contain a
/// secret or credential.
class FailureState {
  const FailureState({
    required this.category,
    required this.recoverability,
    required this.userMessageKey,
    required this.occurredAt,
    this.technicalCause,
  });

  /// Maps a core [AppFailure] into the Foundation failure state, keeping
  /// public information only.
  factory FailureState.fromAppFailure(AppFailure failure) => FailureState(
    category: failure.category,
    recoverability: failure.recoverable
        ? FailureRecoverability.recoverable
        : FailureRecoverability.blocking,
    userMessageKey: failure.messageKey,
    technicalCause: failure.technicalCause,
    occurredAt: failure.occurredAt,
  );

  /// Public category only.
  final AppFailureCategory category;
  final FailureRecoverability recoverability;

  /// Localized message reference; Arabic and English resources exist.
  final String userMessageKey;

  /// Secret-free diagnostic detail, if any.
  final String? technicalCause;

  /// Required UTC audit instant.
  final DateTime occurredAt;
}
