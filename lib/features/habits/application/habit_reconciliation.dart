import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

final class HabitReconciliationSummary {
  const HabitReconciliationSummary({
    required this.imported,
    required this.conflictsRecorded,
    required this.equalTimestampConflicts,
  });
  final int imported;
  final int conflictsRecorded;
  final int equalTimestampConflicts;
}

/// Version identity is metadata per Habit and account/Habit/date per day.
abstract interface class HabitReconciliationStorePort {
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  });
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  });
  Future<AppResult<void>> applyInboundHabit(Habit habit);
  Future<AppResult<void>> applyInboundDay(HabitDay day);
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String entityType,
    required String entityId,
  });
}

abstract interface class HabitReconciliationPort {
  Future<AppResult<HabitReconciliationSummary>> reconcile({
    required String accountId,
    required HabitRemoteSnapshot remote,
  });
}

final class HabitConflictView {
  const HabitConflictView({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.activeLabel,
    required this.retainedLabel,
    required this.unresolved,
  });
  final String id;
  final String entityType;
  final String entityId;
  final String activeLabel;
  final String retainedLabel;
  final bool unresolved;
}

abstract interface class HabitConflictReaderPort {
  Stream<List<HabitConflictView>> watchConflicts(String accountId);
}
