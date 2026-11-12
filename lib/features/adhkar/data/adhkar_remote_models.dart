import 'dart:convert';

import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../application/adhkar_repository.dart';
import 'uuid_adhkar_identity.dart';

/// One retained conflict version pair as the server reports it (contracts/
/// adhkar-qiyam-sync.md): the stable conflict id, the active record, the
/// losing version and the detection instant.
final class AdhkarRemoteConflict {
  const AdhkarRemoteConflict({
    required this.id,
    required this.active,
    required this.retained,
    required this.detectedAt,
  });

  final String id;
  final AdhkarCountRecord active;
  final AdhkarCountRecord retained;
  final DateTime detectedAt;
}

/// One dispatch receipt: the replayed-or-fresh outcome of
/// `apply_adhkar_item_change_v1` with the server's active record, the
/// optional retained conflict and the optional canonical set award.
final class AdhkarDispatchReceipt {
  const AdhkarDispatchReceipt({
    required this.operationId,
    required this.active,
    required this.conflict,
    required this.award,
  });

  final String operationId;
  final AdhkarCountRecord active;
  final AdhkarRemoteConflict? conflict;
  final XpAward? award;
}

abstract final class AdhkarRemoteModels {
  /// The server's active row (0016's `active_record` jsonb, owner stripped)
  /// into the domain record, validating the deterministic identity.
  static AdhkarCountRecord record(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Adhkar record');
    }
    final record = AdhkarCountRecord(
      accountId: owner,
      adhkarDay: row['adhkar_day'] as String,
      itemId: row['item_id'] as String,
      recordId: row['record_id'] as String,
      catalogVersion: row['catalog_version'] as int,
      list: row['list'] as String,
      count: row['count'] as int,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      lastAcknowledgedUpdatedAt: null,
    );
    if (record.recordId !=
        const UuidAdhkarIdentity().itemRecordId(
          record.adhkarDay,
          record.itemId,
        )) {
      throw const FormatException('Adhkar record identity mismatch');
    }
    return record;
  }

  static XpAward award(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Adhkar award');
    }
    final source = row['source'] as String;
    if (source != kAdhkarSetDoneAwardSource) {
      throw const FormatException('Unexpected Adhkar award source');
    }
    return XpAward(
      accountId: owner,
      source: source,
      sourceId: row['source_id'] as String,
      amount: row['amount'] as int,
      awardedAt: DateTime.parse(row['awarded_at'] as String).toUtc(),
    );
  }

  /// The semantic wire payload of one count record — the same key set the
  /// outbox carries, without the acknowledged base (which travels as its own
  /// RPC argument and is excluded from the fingerprint).
  static String payload(AdhkarCountRecord record) => jsonEncode({
    'adhkar_day': record.adhkarDay,
    'item_id': record.itemId,
    'catalog_version': record.catalogVersion,
    'count': record.count,
    'updated_at': record.updatedAt.toIso8601String(),
  });
}
