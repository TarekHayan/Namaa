/// The wire representations of the My Adhkar remote rows (migration 0017,
/// contracts/adhkar-qiyam-sync.md). Every parser validates the identity: a
/// foreign owner's row is rejected instead of decoded. Payloads carry no
/// owner and no base version — those live on the operation envelope.
library;

import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

DateTime _instant(Object? value, String field) {
  if (value is! String) {
    throw FormatException('My Adhkar row lacks $field');
  }
  final parsed = DateTime.parse(value);
  // A string with an offset or `Z` parses to a UTC instant; one without
  // would be read in the device's zone, so it is rejected.
  if (!parsed.isUtc) {
    throw FormatException('My Adhkar $field has no time zone');
  }
  return parsed;
}

DateTime? _optionalInstant(Object? value, String field) =>
    value == null ? null : _instant(value, field);

final class MyAdhkarRemoteGroup {
  const MyAdhkarRemoteGroup({
    required this.accountId,
    required this.groupId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory MyAdhkarRemoteGroup.fromJson(
    Map<String, dynamic> json,
    String accountId,
  ) {
    final owner = json['owner'];
    if (owner != null && owner != accountId) {
      throw const FormatException('Foreign My Adhkar group row');
    }
    if (json['group_id'] is! String || json['name'] is! String) {
      throw const FormatException('My Adhkar group row is incomplete');
    }
    return MyAdhkarRemoteGroup(
      accountId: accountId,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      createdAt: _instant(json['created_at'], 'created_at'),
      updatedAt: _instant(json['updated_at'], 'updated_at'),
      deletedAt: _optionalInstant(json['deleted_at'], 'deleted_at'),
    );
  }

  final String accountId;
  final String groupId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  MyAdhkarGroup toDomain() => MyAdhkarGroup(
    accountId: accountId,
    groupId: groupId,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastAcknowledgedUpdatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  /// The wire payload (no owner, no base version).
  Map<String, dynamic> payload() => {
    'group_id': groupId,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

final class MyAdhkarRemoteItem {
  MyAdhkarRemoteItem({
    required this.accountId,
    required this.itemId,
    required this.text,
    required this.source,
    required List<String> groupIds,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    Map<String, DateTime> groupAddedAt = const {},
  }) : groupIds = List.unmodifiable([...groupIds]..sort()),
       groupAddedAt = Map.unmodifiable(groupAddedAt);

  /// Parses one `my_adhkar_items` row. The group set comes from the RPC
  /// outcome's `group_ids`, or from the embedded `my_adhkar_item_groups`
  /// rows of a page read (which also carry each membership's `added_at`).
  factory MyAdhkarRemoteItem.fromJson(
    Map<String, dynamic> json,
    String accountId,
  ) {
    final owner = json['owner'];
    if (owner != null && owner != accountId) {
      throw const FormatException('Foreign My Adhkar entry row');
    }
    if (json['item_id'] is! String || json['text'] is! String) {
      throw const FormatException('My Adhkar entry row is incomplete');
    }
    final groupIds = <String>[];
    final addedAt = <String, DateTime>{};
    final embedded = json['my_adhkar_item_groups'];
    final plain = json['group_ids'];
    if (embedded is List) {
      for (final row in embedded) {
        if (row is! Map || row['group_id'] is! String) {
          throw const FormatException('My Adhkar membership row is invalid');
        }
        final groupId = row['group_id'] as String;
        if (row['owner'] != null && row['owner'] != accountId) {
          throw const FormatException('Foreign My Adhkar membership row');
        }
        groupIds.add(groupId);
        if (row['added_at'] != null) {
          addedAt[groupId] = _instant(row['added_at'], 'added_at');
        }
      }
    } else if (plain is List) {
      for (final id in plain) {
        if (id is! String) {
          throw const FormatException('My Adhkar group id is invalid');
        }
        groupIds.add(id);
      }
    } else if (json['deleted_at'] == null) {
      throw const FormatException('My Adhkar live entry has no group set');
    }
    if (groupIds.toSet().length != groupIds.length) {
      throw const FormatException('My Adhkar group set has duplicates');
    }
    if (json['deleted_at'] == null && groupIds.isEmpty) {
      throw const FormatException('My Adhkar live entry has no group');
    }
    return MyAdhkarRemoteItem(
      accountId: accountId,
      itemId: json['item_id'] as String,
      text: json['text'] as String,
      source: json['source'] as String?,
      groupIds: groupIds,
      createdAt: _instant(json['created_at'], 'created_at'),
      updatedAt: _instant(json['updated_at'], 'updated_at'),
      deletedAt: _optionalInstant(json['deleted_at'], 'deleted_at'),
      groupAddedAt: addedAt,
    );
  }

  final String accountId;
  final String itemId;
  final String text;
  final String? source;

  /// Sorted, unmodifiable.
  final List<String> groupIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// The server's `added_at` of each membership when a page read carried it;
  /// empty for an RPC outcome.
  final Map<String, DateTime> groupAddedAt;

  bool get isDeleted => deletedAt != null;

  /// The domain entry stamped as acknowledged at the server's version. A
  /// live remote row always carries at least one group.
  MyDhikrItem toDomain() => MyDhikrItem(
    accountId: accountId,
    itemId: itemId,
    text: text,
    source: source,
    groupIds: groupIds,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastAcknowledgedUpdatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  /// The wire payload (no owner, no base version); the group set is sorted
  /// so the version is order-stable.
  Map<String, dynamic> payload() => {
    'item_id': itemId,
    'text': text,
    'source': source,
    'group_ids': groupIds,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

/// One retained conflict as the server reports it: the stable conflict id,
/// the entity it belongs to, both versions as the wire objects, and the
/// detection instant.
final class MyAdhkarRemoteConflict {
  const MyAdhkarRemoteConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.active,
    required this.retained,
    required this.detectedAt,
  });

  /// Parses one `my_adhkar_conflicts` row.
  factory MyAdhkarRemoteConflict.fromRow(
    Map<String, dynamic> row,
    String accountId,
  ) {
    if (row['owner'] != null && row['owner'] != accountId) {
      throw const FormatException('Foreign My Adhkar conflict row');
    }
    final entityType = row['entity_type'];
    if (entityType != 'group' && entityType != 'item') {
      throw const FormatException('Unknown My Adhkar conflict entity');
    }
    if (row['conflict_id'] is! String ||
        row['entity_id'] is! String ||
        row['active_record'] is! Map ||
        row['retained_record'] is! Map) {
      throw const FormatException('My Adhkar conflict row is incomplete');
    }
    return MyAdhkarRemoteConflict(
      id: row['conflict_id'] as String,
      entityType: entityType as String,
      entityId: row['entity_id'] as String,
      active: Map<String, dynamic>.from(row['active_record'] as Map),
      retained: Map<String, dynamic>.from(row['retained_record'] as Map),
      detectedAt: _instant(row['detected_at'], 'detected_at'),
    );
  }

  final String id;

  /// 'group' or 'item', exactly as migration 0017 records it.
  final String entityType;
  final String entityId;
  final Map<String, dynamic> active;
  final Map<String, dynamic> retained;
  final DateTime detectedAt;
}

/// One dispatch receipt: exactly one of [group] or [item] is set.
final class MyAdhkarDispatchReceipt {
  const MyAdhkarDispatchReceipt({
    required this.operationId,
    required this.entityType,
    required this.group,
    required this.item,
    required this.conflict,
    this.groupDeleted = false,
  });

  final String operationId;
  final String entityType;
  final MyAdhkarRemoteGroup? group;
  final MyAdhkarRemoteItem? item;
  final MyAdhkarRemoteConflict? conflict;

  /// The server deleted the submitted entry because every group it named
  /// was deleted (`group_deleted`); the active version is the deletion.
  final bool groupDeleted;

  /// The server's active version stamp.
  DateTime get activeVersion =>
      group?.updatedAt ?? item?.updatedAt ?? (throw StateError('no record'));
}

/// Wire helpers shared by the gateway and the adapter.
final class MyAdhkarRemoteModels {
  const MyAdhkarRemoteModels._();

  /// Parses one RPC outcome (migration 0017), validating the owner and the
  /// operation and record identities against the request.
  static MyAdhkarDispatchReceipt receipt(
    Map<String, dynamic> row, {
    required String accountId,
    required String operationId,
    required String recordId,
    required String entityType,
  }) {
    if (row['owner'] != accountId) {
      throw const FormatException('Foreign My Adhkar receipt');
    }
    if (row['operation_id'] != operationId ||
        row['record_id'] != recordId ||
        row['entity_type'] != entityType) {
      throw const FormatException('My Adhkar receipt identity mismatch');
    }
    final activeRow = row['active_record'];
    if (activeRow is! Map) {
      throw const FormatException('My Adhkar receipt has no active record');
    }
    final retainedRow = row['retained_record'];
    final conflictId = row['conflict_id'];
    if ((retainedRow == null) != (conflictId == null)) {
      throw const FormatException('My Adhkar conflict receipt incomplete');
    }
    final conflict = retainedRow == null
        ? null
        : MyAdhkarRemoteConflict(
            id: conflictId as String,
            entityType: entityType,
            entityId: recordId,
            active: Map<String, dynamic>.from(activeRow),
            retained: Map<String, dynamic>.from(retainedRow as Map),
            detectedAt: _instant(row['detected_at'], 'detected_at'),
          );
    final active = Map<String, dynamic>.from(activeRow);
    if (entityType == 'group') {
      final group = MyAdhkarRemoteGroup.fromJson(active, accountId);
      if (group.groupId != recordId) {
        throw const FormatException('My Adhkar active record mismatch');
      }
      return MyAdhkarDispatchReceipt(
        operationId: operationId,
        entityType: entityType,
        group: group,
        item: null,
        conflict: conflict,
      );
    }
    final item = MyAdhkarRemoteItem.fromJson(active, accountId);
    if (item.itemId != recordId) {
      throw const FormatException('My Adhkar active record mismatch');
    }
    return MyAdhkarDispatchReceipt(
      operationId: operationId,
      entityType: entityType,
      group: null,
      item: item,
      conflict: conflict,
      groupDeleted: row['group_deleted'] == true,
    );
  }

  /// The wire payload of a local group, exactly as the outbox stores it.
  static Map<String, dynamic> groupPayload(MyAdhkarGroup group) => {
    'group_id': group.groupId,
    'name': group.name,
    'created_at': group.createdAt.toUtc().toIso8601String(),
    'updated_at': group.updatedAt.toUtc().toIso8601String(),
    'deleted_at': group.deletedAt?.toUtc().toIso8601String(),
  };

  /// The wire payload of a local entry, exactly as the outbox stores it.
  static Map<String, dynamic> itemPayload(MyDhikrItem item) => {
    'item_id': item.itemId,
    'text': item.text,
    'source': item.source,
    'group_ids': [...item.groupIds]..sort(),
    'created_at': item.createdAt.toUtc().toIso8601String(),
    'updated_at': item.updatedAt.toUtc().toIso8601String(),
    'deleted_at': item.deletedAt?.toUtc().toIso8601String(),
  };
}
