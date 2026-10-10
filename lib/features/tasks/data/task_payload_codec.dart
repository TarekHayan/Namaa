import 'dart:convert';

import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Stable JSON codec for local outbox and remote Task aggregate payloads.
final class TaskPayloadCodec {
  const TaskPayloadCodec();

  String encode(Task task) => jsonEncode(<String, Object?>{
    'id': task.id,
    'accountId': task.accountId,
    'title': task.title,
    'description': task.description,
    'scheduledDate': _date(task.scheduledDate),
    'scheduledTime': task.scheduledTime?.toIso8601String(),
    'targetDeadline': task.targetDeadline?.toUtc().toIso8601String(),
    'targetDeadlineUtcOffsetMinutes': task.targetDeadlineUtcOffsetMinutes,
    'category': task.category.name,
    'quadrant': _quadrant(task.quadrant),
    'estimatedDurationMinutes': task.estimatedDurationMinutes,
    'checklistItems': <Map<String, Object?>>[
      for (final item in task.checklistItems)
        <String, Object?>{
          'id': item.id,
          'text': item.text,
          'completed': item.completed,
          'order': item.order,
        },
    ],
    'completedAt': task.completedAt?.toUtc().toIso8601String(),
    'completionXp': task.completionXp,
    'createdAt': task.createdAt.toUtc().toIso8601String(),
    'updatedAt': task.updatedAt.toUtc().toIso8601String(),
    'deletedAt': task.deletedAt?.toUtc().toIso8601String(),
  });

  Task decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Task payload must be a JSON object');
      }
      return Task.restore(
        id: _string(decoded, 'id'),
        accountId: _string(decoded, 'accountId'),
        title: _string(decoded, 'title'),
        description: _nullableString(decoded, 'description'),
        scheduledDate: _parseDate(_string(decoded, 'scheduledDate')),
        scheduledTime: _nullableLocalDateTime(decoded, 'scheduledTime'),
        targetDeadline: _nullableUtcDateTime(decoded, 'targetDeadline'),
        targetDeadlineUtcOffsetMinutes: _nullableInt(
          decoded,
          'targetDeadlineUtcOffsetMinutes',
        ),
        category: _category(_string(decoded, 'category')),
        quadrant: _parseQuadrant(_string(decoded, 'quadrant')),
        estimatedDurationMinutes: _nullableInt(
          decoded,
          'estimatedDurationMinutes',
        ),
        checklistItems: _checklist(decoded['checklistItems']),
        completedAt: _nullableUtcDateTime(decoded, 'completedAt'),
        completionXp: _integer(decoded, 'completionXp'),
        createdAt: _utcDateTime(decoded, 'createdAt'),
        updatedAt: _utcDateTime(decoded, 'updatedAt'),
        deletedAt: _nullableUtcDateTime(decoded, 'deletedAt'),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid Task payload', error);
    }
  }

  static List<ChecklistItem> _checklist(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('checklistItems must be a JSON array');
    }
    return <ChecklistItem>[for (final entry in value) _checklistItem(entry)];
  }

  static ChecklistItem _checklistItem(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Checklist item must be a JSON object');
    }
    final completed = value['completed'];
    if (completed is! bool) {
      throw const FormatException('Checklist completed must be a boolean');
    }
    return ChecklistItem(
      id: _string(value, 'id'),
      text: _string(value, 'text'),
      completed: completed,
      order: _integer(value, 'order'),
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('scheduledDate must use YYYY-MM-DD');
    }
    final result = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (_date(result) != value) {
      throw const FormatException('scheduledDate is not a valid date');
    }
    return result;
  }

  static DateTime _utcDateTime(Map<String, dynamic> map, String key) {
    final parsed = DateTime.tryParse(_string(map, key));
    if (parsed == null) {
      throw FormatException('$key must be an ISO-8601 date-time');
    }
    return parsed.toUtc();
  }

  static DateTime? _nullableUtcDateTime(Map<String, dynamic> map, String key) {
    if (map[key] == null) {
      return null;
    }
    return _utcDateTime(map, key);
  }

  static DateTime? _nullableLocalDateTime(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = _nullableString(map, key);
    if (value == null) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.isUtc || _hasExplicitOffset(value)) {
      throw FormatException('$key must be a local wall-clock date-time');
    }
    return parsed;
  }

  static bool _hasExplicitOffset(String value) =>
      value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('$key must be a string or null');
    }
    return value;
  }

  static int _integer(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('$key must be an integer');
    }
    return value;
  }

  static int? _nullableInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('$key must be an integer or null');
    }
    return value;
  }

  static TaskCategory _category(String value) {
    for (final category in TaskCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    throw FormatException('Unknown Task category: $value');
  }

  static String _quadrant(EisenhowerQuadrant value) => switch (value) {
    EisenhowerQuadrant.urgentImportant => 'urgent_important',
    EisenhowerQuadrant.notUrgentImportant => 'not_urgent_important',
    EisenhowerQuadrant.urgentNotImportant => 'urgent_not_important',
    EisenhowerQuadrant.notUrgentNotImportant => 'not_urgent_not_important',
  };

  static EisenhowerQuadrant _parseQuadrant(String value) => switch (value) {
    'urgent_important' => EisenhowerQuadrant.urgentImportant,
    'not_urgent_important' => EisenhowerQuadrant.notUrgentImportant,
    'urgent_not_important' => EisenhowerQuadrant.urgentNotImportant,
    'not_urgent_not_important' => EisenhowerQuadrant.notUrgentNotImportant,
    _ => throw FormatException('Unknown Eisenhower quadrant: $value'),
  };
}
