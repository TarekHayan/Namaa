import 'package:namma_project/features/tasks/domain/checklist_item.dart';

enum TaskCategory { work, study, personal, health, spiritual, finance, other }

enum EisenhowerQuadrant {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

/// The account-owned Task aggregate and its durable synchronization version.
final class Task {
  Task._({
    required this.id,
    required this.accountId,
    required this.title,
    required this.scheduledDate,
    required this.category,
    required this.quadrant,
    required this.checklistItems,
    required this.completionXp,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.scheduledTime,
    this.targetDeadline,
    this.targetDeadlineUtcOffsetMinutes,
    this.estimatedDurationMinutes,
    this.completedAt,
    this.deletedAt,
  });

  factory Task.create({
    required String id,
    required String accountId,
    required String title,
    required DateTime scheduledDate,
    required DateTime createdAt,
    String? description,
    DateTime? scheduledTime,
    DateTime? targetDeadline,
    int? targetDeadlineUtcOffsetMinutes,
    TaskCategory category = TaskCategory.work,
    EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
    int? estimatedDurationMinutes,
    List<ChecklistItem> checklistItems = const <ChecklistItem>[],
    DateTime? completedAt,
    int completionXp = 20,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => Task.restore(
    id: id,
    accountId: accountId,
    title: title,
    description: description,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    targetDeadline: targetDeadline,
    targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
    category: category,
    quadrant: quadrant,
    estimatedDurationMinutes: estimatedDurationMinutes ?? 30,
    checklistItems: checklistItems,
    completedAt: completedAt,
    completionXp: completionXp,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  /// Restores persisted state without applying creation-only defaults.
  factory Task.restore({
    required String id,
    required String accountId,
    required String title,
    required DateTime scheduledDate,
    required DateTime createdAt,
    String? description,
    DateTime? scheduledTime,
    DateTime? targetDeadline,
    int? targetDeadlineUtcOffsetMinutes,
    TaskCategory category = TaskCategory.work,
    EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
    int? estimatedDurationMinutes,
    List<ChecklistItem> checklistItems = const <ChecklistItem>[],
    DateTime? completedAt,
    int completionXp = 20,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    final normalizedTitle = title.trim();
    _requireNonBlank(id, 'id');
    _requireNonBlank(accountId, 'accountId');
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be blank');
    }
    if (estimatedDurationMinutes != null && estimatedDurationMinutes <= 0) {
      throw ArgumentError.value(
        estimatedDurationMinutes,
        'estimatedDurationMinutes',
        'must be positive when present',
      );
    }
    if (completionXp < 0) {
      throw ArgumentError.value(
        completionXp,
        'completionXp',
        'must not be negative',
      );
    }
    if (targetDeadline == null && targetDeadlineUtcOffsetMinutes != null) {
      throw ArgumentError.value(
        targetDeadlineUtcOffsetMinutes,
        'targetDeadlineUtcOffsetMinutes',
        'requires targetDeadline',
      );
    }
    _requireUtc(createdAt, 'createdAt');
    final normalizedUpdatedAt = updatedAt ?? createdAt;
    _requireUtc(normalizedUpdatedAt, 'updatedAt');
    if (normalizedUpdatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        normalizedUpdatedAt,
        'updatedAt',
        'must not precede createdAt',
      );
    }
    final normalizedDeadline = targetDeadline?.toUtc();
    final normalizedCompletedAt = completedAt?.toUtc();
    final normalizedDeletedAt = deletedAt?.toUtc();
    if (normalizedCompletedAt != null &&
        normalizedCompletedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        completedAt,
        'completedAt',
        'must not precede createdAt',
      );
    }
    if (normalizedDeletedAt != null &&
        normalizedDeletedAt.isBefore(normalizedUpdatedAt)) {
      throw ArgumentError.value(
        deletedAt,
        'deletedAt',
        'must not precede updatedAt',
      );
    }
    _validateChecklist(checklistItems);

    return Task._(
      id: id,
      accountId: accountId,
      title: normalizedTitle,
      description: description,
      scheduledDate: DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      ),
      scheduledTime: scheduledTime,
      targetDeadline: normalizedDeadline,
      targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
      category: category,
      quadrant: quadrant,
      estimatedDurationMinutes: estimatedDurationMinutes,
      checklistItems: List<ChecklistItem>.unmodifiable(checklistItems),
      completedAt: normalizedCompletedAt,
      completionXp: completionXp,
      createdAt: createdAt,
      updatedAt: normalizedUpdatedAt,
      deletedAt: normalizedDeletedAt,
    );
  }

  static const Object _unchanged = Object();

  final String id;
  final String accountId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final DateTime? scheduledTime;
  final DateTime? targetDeadline;
  final int? targetDeadlineUtcOffsetMinutes;
  final TaskCategory category;
  final EisenhowerQuadrant quadrant;
  final int? estimatedDurationMinutes;
  final List<ChecklistItem> checklistItems;
  final DateTime? completedAt;
  final int completionXp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isCompleted => completedAt != null;
  bool get isDeleted => deletedAt != null;

  Task copyWith({
    String? title,
    Object? description = _unchanged,
    DateTime? scheduledDate,
    Object? scheduledTime = _unchanged,
    Object? targetDeadline = _unchanged,
    Object? targetDeadlineUtcOffsetMinutes = _unchanged,
    TaskCategory? category,
    EisenhowerQuadrant? quadrant,
    Object? estimatedDurationMinutes = _unchanged,
    List<ChecklistItem>? checklistItems,
    Object? completedAt = _unchanged,
    int? completionXp,
    DateTime? updatedAt,
    Object? deletedAt = _unchanged,
  }) => Task.restore(
    id: id,
    accountId: accountId,
    title: title ?? this.title,
    description: identical(description, _unchanged)
        ? this.description
        : description as String?,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    scheduledTime: identical(scheduledTime, _unchanged)
        ? this.scheduledTime
        : scheduledTime as DateTime?,
    targetDeadline: identical(targetDeadline, _unchanged)
        ? this.targetDeadline
        : targetDeadline as DateTime?,
    targetDeadlineUtcOffsetMinutes:
        identical(targetDeadlineUtcOffsetMinutes, _unchanged)
        ? this.targetDeadlineUtcOffsetMinutes
        : targetDeadlineUtcOffsetMinutes as int?,
    category: category ?? this.category,
    quadrant: quadrant ?? this.quadrant,
    estimatedDurationMinutes: identical(estimatedDurationMinutes, _unchanged)
        ? this.estimatedDurationMinutes
        : estimatedDurationMinutes as int?,
    checklistItems: checklistItems ?? this.checklistItems,
    completedAt: identical(completedAt, _unchanged)
        ? this.completedAt
        : completedAt as DateTime?,
    completionXp: completionXp ?? this.completionXp,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: identical(deletedAt, _unchanged)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  Task markDeleted(DateTime instant) {
    _requireUtc(instant, 'instant');
    if (instant.isBefore(updatedAt)) {
      throw ArgumentError.value(
        instant,
        'instant',
        'must not precede the current version',
      );
    }
    return copyWith(updatedAt: instant, deletedAt: instant);
  }

  /// Records an explicit completion. Repeating completion is not a new event.
  Task complete(DateTime instant) {
    _requireUtc(instant, 'instant');
    if (isCompleted) {
      return this;
    }
    _requireNewerVersion(instant);
    return copyWith(completedAt: instant, updatedAt: instant);
  }

  /// Clears the current completion state without touching checklist progress.
  Task reopen(DateTime instant) {
    _requireUtc(instant, 'instant');
    if (!isCompleted) {
      return this;
    }
    _requireNewerVersion(instant);
    return copyWith(completedAt: null, updatedAt: instant);
  }

  void _requireNewerVersion(DateTime instant) {
    if (!instant.isAfter(updatedAt)) {
      throw ArgumentError.value(
        instant,
        'instant',
        'must advance the current version',
      );
    }
  }

  static void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
  }

  static void _requireUtc(DateTime value, String name) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, name, 'must be UTC');
    }
  }

  static void _validateChecklist(List<ChecklistItem> items) {
    final ids = <String>{};
    final orders = <int>{};
    for (final item in items) {
      _requireNonBlank(item.id, 'checklistItem.id');
      if (item.text.trim().isEmpty) {
        throw ArgumentError.value(
          item.text,
          'checklistItem.text',
          'must not be blank',
        );
      }
      if (item.order < 0) {
        throw ArgumentError.value(
          item.order,
          'checklistItem.order',
          'must not be negative',
        );
      }
      if (!ids.add(item.id)) {
        throw ArgumentError.value(item.id, 'checklistItem.id', 'duplicate');
      }
      if (!orders.add(item.order)) {
        throw ArgumentError.value(
          item.order,
          'checklistItem.order',
          'duplicate',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          id == other.id &&
          accountId == other.accountId &&
          title == other.title &&
          description == other.description &&
          scheduledDate == other.scheduledDate &&
          scheduledTime == other.scheduledTime &&
          targetDeadline == other.targetDeadline &&
          targetDeadlineUtcOffsetMinutes ==
              other.targetDeadlineUtcOffsetMinutes &&
          category == other.category &&
          quadrant == other.quadrant &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          _listEquals(checklistItems, other.checklistItems) &&
          completedAt == other.completedAt &&
          completionXp == other.completionXp &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    accountId,
    title,
    description,
    scheduledDate,
    scheduledTime,
    targetDeadline,
    targetDeadlineUtcOffsetMinutes,
    category,
    quadrant,
    estimatedDurationMinutes,
    ...checklistItems,
    completedAt,
    completionXp,
    createdAt,
    updatedAt,
    deletedAt,
  ]);

  static bool _listEquals(List<Object?> left, List<Object?> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
