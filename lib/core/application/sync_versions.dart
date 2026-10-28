/// Shared version rules used by both outbound and inbound synchronization.
library;

import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';

/// The versions a server may hold for one record while this device still has
/// queued edits to it: the base each queued edit started from, and each queued
/// version itself (an upload that landed but whose acknowledgement was lost).
///
/// A remote snapshot at one of these versions is not a clash. The device's
/// queued edits are newer work on top of it, and the outbox will upload them.
final class PendingSyncVersions {
  const PendingSyncVersions._(this._knownMicros);

  final Set<int> _knownMicros;

  /// Groups pending operations by `(entityType, entityId)`.
  static Map<(String, String), PendingSyncVersions> index(
    Iterable<PendingChangeRecord> changes,
  ) {
    final known = <(String, String), Set<int>>{};
    for (final change in changes) {
      if (change.state != PendingChangeState.pending) continue;
      final versions = known.putIfAbsent((
        change.entityType,
        change.entityId,
      ), () => <int>{});
      versions.add(change.versionTimestamp.toUtc().microsecondsSinceEpoch);
      final base = change.baseUpdatedAt;
      if (base != null) versions.add(base.toUtc().microsecondsSinceEpoch);
    }
    return {
      for (final entry in known.entries)
        entry.key: PendingSyncVersions._(entry.value),
    };
  }

  bool knows(DateTime remoteVersion) =>
      _knownMicros.contains(remoteVersion.toUtc().microsecondsSinceEpoch);
}

/// One identity for one clash between two versions of a record.
///
/// Inbound reconciliation and outbound dispatch can each detect the same clash,
/// and they see the remote version as different text: outbound gets the
/// server's stored JSON (a Task's `completionChangedAt` is rewritten there as
/// `+00:00`), inbound re-encodes it through the feature codec (`Z`). So when
/// the two timestamps differ, the record and the two timestamps alone identify
/// the clash.
///
/// Equal timestamps cannot tell two different clashes apart, so only then are
/// the payloads hashed in. Only inbound reconciliation records an
/// equal-timestamp clash (outbound keeps it open as a retryable failure), so
/// that hash is always computed from one consistent encoding.
String syncConflictId({
  required String accountId,
  required String entityType,
  required String entityId,
  required DateTime activeAt,
  required DateTime retainedAt,
  required String activePayload,
  required String retainedPayload,
}) {
  final identity =
      'sync-conflict:$accountId:$entityType:$entityId:'
      '${activeAt.toUtc().microsecondsSinceEpoch}:'
      '${retainedAt.toUtc().microsecondsSinceEpoch}';
  if (!_sameInstant(activeAt, retainedAt)) return identity;
  return '$identity:${_payloadHash(activePayload, retainedPayload)}';
}

bool _sameInstant(DateTime left, DateTime right) =>
    left.toUtc().microsecondsSinceEpoch == right.toUtc().microsecondsSinceEpoch;

String _payloadHash(String activePayload, String retainedPayload) {
  final candidatePair = jsonEncode([
    canonicalSyncPayload(activePayload),
    canonicalSyncPayload(retainedPayload),
  ]);
  var first = 0x811c9dc5;
  var second = 0x9e3779b9;
  for (final byte in utf8.encode(candidatePair)) {
    first = ((first ^ byte) * 0x01000193) & 0xffffffff;
    second = ((second ^ byte) * 0x85ebca6b) & 0xffffffff;
  }
  return '${first.toRadixString(16).padLeft(8, '0')}'
      '${second.toRadixString(16).padLeft(8, '0')}';
}

String canonicalSyncPayload(String payload) {
  try {
    return jsonEncode(_sortedJson(jsonDecode(payload)));
  } on FormatException {
    return payload;
  }
}

Object? _sortedJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _sortedJson(value[key])};
  }
  if (value is List) return value.map(_sortedJson).toList();
  return value;
}
