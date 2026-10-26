/// Calendar dates are stored as values captured by the acting device.
String habitLocalDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseHabitLocalDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw ArgumentError.value(value, 'localDate');
  final parsed = DateTime.utc(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  if (habitLocalDate(parsed) != value) {
    throw ArgumentError.value(value, 'localDate');
  }
  return parsed;
}

void validateHabitUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
}

void validateHabitOffset(int minutes) {
  if (minutes < -14 * 60 || minutes > 14 * 60) {
    throw ArgumentError.value(minutes, 'utcOffsetMinutes');
  }
}

/// One immutable selection of weekdays. Monday is 1 and Sunday is 7.
final class HabitScheduleRevision {
  HabitScheduleRevision({
    required this.revisionId,
    required this.effectiveAt,
    required this.effectiveLocalDate,
    required this.utcOffsetMinutes,
    required Iterable<int> weekdays,
    this.dailyTarget = 1,
  }) : weekdays = List<int>.unmodifiable(weekdays.toSet().toList()..sort()) {
    if (revisionId.trim().isEmpty) {
      throw ArgumentError.value(revisionId, 'revisionId');
    }
    validateHabitUtc(effectiveAt, 'effectiveAt');
    parseHabitLocalDate(effectiveLocalDate);
    validateHabitOffset(utcOffsetMinutes);
    if (this.weekdays.isEmpty ||
        this.weekdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(this.weekdays, 'weekdays');
    }
    if (dailyTarget < 1 || dailyTarget > 9999) {
      throw ArgumentError.value(dailyTarget, 'dailyTarget');
    }
  }

  final String revisionId;
  final DateTime effectiveAt;
  final String effectiveLocalDate;
  final int utcOffsetMinutes;
  final List<int> weekdays;
  final int dailyTarget;
}

/// Account-owned metadata; day actions are stored independently.
final class Habit {
  Habit._({
    required this.id,
    required this.accountId,
    required this.name,
    required this.scheduleRevisions,
    required this.reminderMinuteOfDay,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Habit.create({
    required String id,
    required String accountId,
    required String name,
    required Iterable<int> weekdays,
    required String revisionId,
    required DateTime createdAt,
    required String effectiveLocalDate,
    required int utcOffsetMinutes,
    int? reminderMinuteOfDay,
    int dailyTarget = 1,
  }) => Habit.restore(
    id: id,
    accountId: accountId,
    name: name,
    scheduleRevisions: [
      HabitScheduleRevision(
        revisionId: revisionId,
        effectiveAt: createdAt,
        effectiveLocalDate: effectiveLocalDate,
        utcOffsetMinutes: utcOffsetMinutes,
        weekdays: weekdays,
        dailyTarget: dailyTarget,
      ),
    ],
    reminderMinuteOfDay: reminderMinuteOfDay,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  factory Habit.restore({
    required String id,
    required String accountId,
    required String name,
    required Iterable<HabitScheduleRevision> scheduleRevisions,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? reminderMinuteOfDay,
    DateTime? deletedAt,
  }) {
    if (id.trim().isEmpty || accountId.trim().isEmpty) {
      throw ArgumentError('Habit identity must not be blank');
    }
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError.value(name, 'name');
    if (reminderMinuteOfDay != null &&
        (reminderMinuteOfDay < 0 || reminderMinuteOfDay > 1439)) {
      throw ArgumentError.value(reminderMinuteOfDay, 'reminderMinuteOfDay');
    }
    validateHabitUtc(createdAt, 'createdAt');
    validateHabitUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(updatedAt, 'updatedAt');
    }
    if (deletedAt != null) validateHabitUtc(deletedAt, 'deletedAt');
    final revisions = List<HabitScheduleRevision>.of(scheduleRevisions);
    if (revisions.isEmpty) {
      throw ArgumentError.value(revisions, 'scheduleRevisions');
    }
    for (var i = 1; i < revisions.length; i++) {
      if (revisions[i].effectiveAt.isBefore(revisions[i - 1].effectiveAt)) {
        throw ArgumentError.value(
          revisions,
          'scheduleRevisions',
          'must be ordered',
        );
      }
      if (revisions
          .take(i)
          .any((other) => other.revisionId == revisions[i].revisionId)) {
        throw ArgumentError.value(
          revisions,
          'scheduleRevisions',
          'duplicate revision',
        );
      }
    }
    return Habit._(
      id: id,
      accountId: accountId,
      name: normalized,
      scheduleRevisions: List.unmodifiable(revisions),
      reminderMinuteOfDay: reminderMinuteOfDay,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  final String id;
  final String accountId;
  final String name;
  final List<HabitScheduleRevision> scheduleRevisions;
  final int? reminderMinuteOfDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  bool get isDeleted => deletedAt != null;
  HabitScheduleRevision get currentRevision => scheduleRevisions.last;
  int get dailyTarget => currentRevision.dailyTarget;
  bool get hasRepetitions => dailyTarget > 1;

  Habit edit({
    required String name,
    required Iterable<int> weekdays,
    required int? reminderMinuteOfDay,
    required String revisionId,
    required DateTime editedAt,
    required String effectiveLocalDate,
    required int utcOffsetMinutes,
    int? dailyTarget,
  }) {
    if (isDeleted) throw StateError('Cannot edit a deleted habit');
    validateHabitUtc(editedAt, 'editedAt');
    parseHabitLocalDate(effectiveLocalDate);
    validateHabitOffset(utcOffsetMinutes);
    final selected = weekdays.toSet();
    final target = dailyTarget ?? currentRevision.dailyTarget;
    final scheduleChanged =
        selected.length != currentRevision.weekdays.length ||
        !selected.containsAll(currentRevision.weekdays) ||
        target != currentRevision.dailyTarget;
    final version = editedAt.isAfter(updatedAt)
        ? editedAt
        : updatedAt.add(const Duration(microseconds: 1));
    return Habit.restore(
      id: id,
      accountId: accountId,
      name: name,
      scheduleRevisions: [
        ...scheduleRevisions,
        if (scheduleChanged)
          HabitScheduleRevision(
            revisionId: revisionId,
            effectiveAt: editedAt,
            effectiveLocalDate: effectiveLocalDate,
            utcOffsetMinutes: utcOffsetMinutes,
            weekdays: selected,
            dailyTarget: target,
          ),
      ],
      reminderMinuteOfDay: reminderMinuteOfDay,
      createdAt: createdAt,
      updatedAt: version,
    );
  }

  Habit delete(DateTime deletedAt) {
    if (isDeleted) throw StateError('Habit already deleted');
    validateHabitUtc(deletedAt, 'deletedAt');
    final version = deletedAt.isAfter(updatedAt)
        ? deletedAt
        : updatedAt.add(const Duration(microseconds: 1));
    return Habit.restore(
      id: id,
      accountId: accountId,
      name: name,
      scheduleRevisions: scheduleRevisions,
      reminderMinuteOfDay: reminderMinuteOfDay,
      createdAt: createdAt,
      updatedAt: version,
      deletedAt: version,
    );
  }

  HabitScheduleRevision? revisionOn(String localDate) {
    parseHabitLocalDate(localDate);
    for (final revision in scheduleRevisions.reversed) {
      if (revision.effectiveLocalDate.compareTo(localDate) <= 0) {
        return revision;
      }
    }
    return null;
  }

  bool isDueOn(String localDate) =>
      revisionOn(
        localDate,
      )?.weekdays.contains(parseHabitLocalDate(localDate).weekday) ??
      false;
}
