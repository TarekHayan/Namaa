/// Initial Foundation Domain entry types.
///
/// The Foundation owns only cross-cutting configuration, persistence,
/// synchronization, conflict, and failure records; it defines no
/// product-domain data (specs/001-namaa-foundation/data-model.md). This file
/// must never import Flutter, Drift, Supabase, routing, notification, or
/// platform-adapter libraries.
library;

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
enum FoundationPreferenceKey { locale, appearance }

/// A persisted Foundation application preference (locale, appearance).
///
/// Values are non-secret settings; secrets never live in preferences.
class ApplicationPreference {
  const ApplicationPreference({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  /// Stable, Foundation-owned preference identifier.
  final FoundationPreferenceKey key;

  /// Serialized non-secret setting value valid for [key].
  final String value;

  /// Required UTC instant of the last local change.
  final DateTime updatedAt;
}

/// A Foundation verification record persisted locally.
///
/// This is a Foundation-owned verification entity, not a generic
/// product-data container. Payloads are test/probe payloads only, encrypted
/// at rest by the local store.
class LocalRecord {
  const LocalRecord({
    required this.recordId,
    required this.payload,
    required this.versionTimestamp,
    required this.syncState,
    required this.updatedAt,
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

  /// Current synchronization state; only valid transitions are allowed.
  final FoundationSyncState syncState;

  /// Required UTC audit timestamp.
  final DateTime updatedAt;
}
