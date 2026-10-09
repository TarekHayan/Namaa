/// The pending-synchronization engine contract.
///
/// Implemented by the durable outbox coordinator in core/data; application
/// use cases depend on this contract only, never on the data-layer
/// implementation.
library;

import 'package:namma_project/core/domain/results/app_result.dart';

/// Message key for a conflict awaiting an approved tie-breaker.
const String kEqualTimestampConflictMessageKey =
    'foundation.sync.equalTimestampConflict';

/// Message key for a recoverable dispatch failure.
const String kDispatchRecoverableMessageKey = 'foundation.sync.recoverable';

/// Counters for one synchronization pass.
final class SyncSummary {
  const SyncSummary({
    required this.acknowledged,
    required this.conflictsRecorded,
    required this.equalTimestampConflicts,
    required this.recoverableFailures,
  });

  /// Operations durably acknowledged in this pass.
  final int acknowledged;

  /// Conflict records written in this pass.
  final int conflictsRecorded;

  /// Conflicts left open because both timestamps are equal.
  final int equalTimestampConflicts;

  /// Operations that stay pending after a recoverable failure.
  final int recoverableFailures;
}

/// The durable outbox synchronization engine.
abstract interface class PendingSynchronizationEngine {
  /// Runs one durable pass over the pending outbox for the authorized
  /// account.
  Future<AppResult<SyncSummary>> synchronize();
}
