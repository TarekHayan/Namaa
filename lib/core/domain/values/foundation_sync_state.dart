/// Cross-cutting Foundation record synchronization states shared by Domain
/// and infrastructure.
///
/// Part of the Foundation Domain: infrastructure-free.
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
