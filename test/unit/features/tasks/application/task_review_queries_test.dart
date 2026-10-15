import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/tasks/application/task_review_queries.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

void main() {
  final nowUtc = DateTime.utc(2026, 10, 8, 9);
  final today = DateTime(2026, 10, 8);

  Task task({
    required String id,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
    DateTime? targetDeadline,
    int? targetDeadlineUtcOffsetMinutes,
    DateTime? completedAt,
    DateTime? deletedAt,
  }) => Task.create(
    id: id,
    accountId: 'account-a',
    title: id,
    scheduledDate: scheduledDate ?? today,
    scheduledTime: scheduledTime,
    targetDeadline: targetDeadline,
    targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
    completedAt: completedAt,
    createdAt: DateTime.utc(2026, 10),
    updatedAt: deletedAt ?? completedAt ?? DateTime.utc(2026, 10),
    deletedAt: deletedAt,
  );

  test(
    'completed history retains source identity and saved completion dates',
    () {
      final older = task(
        id: 'older',
        completedAt: DateTime.utc(2026, 10, 6, 15),
      );
      final newer = task(
        id: 'newer',
        completedAt: DateTime.utc(2026, 10, 8, 8),
      );
      final open = task(id: 'open');
      final deleted = task(
        id: 'deleted',
        completedAt: DateTime.utc(2026, 10, 7, 12),
        deletedAt: DateTime.utc(2026, 10, 8, 8),
      );

      final history = TaskReviewQueries.completedHistory(<Task>[
        older,
        open,
        deleted,
        newer,
      ]);

      expect(history.map((Task entry) => entry.id), <String>['older', 'newer']);
      expect(history.map((Task entry) => entry.completedAt), <DateTime?>[
        older.completedAt,
        newer.completedAt,
      ]);
    },
  );

  test('overdue includes an open Task whose scheduled date has passed', () {
    final overdue = TaskReviewQueries.overdue(
      <Task>[task(id: 'past-date', scheduledDate: DateTime(2026, 10, 7))],
      localDate: today,
      nowUtc: nowUtc,
    );

    expect(overdue.map((Task entry) => entry.id), <String>['past-date']);
  });

  test(
    'overdue includes a passed deadline using its saved instant context',
    () {
      final deadline = DateTime.parse('2026-10-08T10:30:00+02:00');
      final overdue = TaskReviewQueries.overdue(
        <Task>[
          task(
            id: 'past-deadline',
            targetDeadline: deadline,
            targetDeadlineUtcOffsetMinutes: 120,
          ),
        ],
        localDate: today,
        nowUtc: nowUtc,
      );

      expect(overdue.map((Task entry) => entry.id), <String>['past-deadline']);
    },
  );

  test('elapsed scheduled time today alone does not make a Task overdue', () {
    final overdue = TaskReviewQueries.overdue(
      <Task>[task(id: 'today-time', scheduledTime: DateTime(2026, 10, 8, 8))],
      localDate: today,
      nowUtc: nowUtc,
    );

    expect(overdue, isEmpty);
  });

  test('completed, deleted, and future Tasks are excluded from overdue', () {
    final overdue = TaskReviewQueries.overdue(
      <Task>[
        task(
          id: 'completed',
          scheduledDate: DateTime(2026, 10, 7),
          completedAt: DateTime.utc(2026, 10, 8, 8),
        ),
        task(
          id: 'deleted',
          scheduledDate: DateTime(2026, 10, 7),
          deletedAt: DateTime.utc(2026, 10, 8, 8),
        ),
        task(id: 'future', scheduledDate: DateTime(2026, 10, 9)),
      ],
      localDate: today,
      nowUtc: nowUtc,
    );

    expect(overdue, isEmpty);
  });
}
