import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

final class HabitWriteRequest {
  HabitWriteRequest({
    required this.habit,
    required this.operationId,
    required this.kind,
    required this.queuedAt,
  }) {
    if (operationId.trim().isEmpty || !queuedAt.isUtc) {
      throw ArgumentError('Invalid Habit operation identity or clock');
    }
  }
  final Habit habit;
  final String operationId;
  final ChangeKind kind;
  final DateTime queuedAt;
}

final class HabitDayWriteRequest {
  HabitDayWriteRequest({
    required this.day,
    required this.operationId,
    required this.kind,
    required this.queuedAt,
  }) {
    if (operationId.trim().isEmpty || !queuedAt.isUtc) {
      throw ArgumentError('Invalid HabitDay operation identity or clock');
    }
  }
  final HabitDay day;
  final String operationId;
  final ChangeKind kind;
  final DateTime queuedAt;
}

abstract interface class HabitRepository {
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  });
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  });
  Stream<List<Habit>> watchHabits(String accountId);
  Stream<List<HabitDay>> watchDays(String accountId);
  Future<AppResult<void>> commitHabit(HabitWriteRequest request);
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request);
}
