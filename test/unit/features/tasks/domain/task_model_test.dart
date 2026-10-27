import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/domain/task_rules.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 8, 9);
  final today = DateTime(2026, 10, 8);

  Task buildTask({
    String title = '  Prepare weekly plan  ',
    String? description,
    DateTime? scheduledTime,
    DateTime? targetDeadline,
    int? targetDeadlineUtcOffsetMinutes,
    int? estimatedDurationMinutes,
    List<ChecklistItem> checklistItems = const <ChecklistItem>[],
  }) => Task.create(
    id: kTasksTestTaskId,
    accountId: kTasksTestAccountA,
    title: title,
    description: description,
    scheduledDate: today,
    scheduledTime: scheduledTime,
    targetDeadline: targetDeadline,
    targetDeadlineUtcOffsetMinutes: targetDeadlineUtcOffsetMinutes,
    estimatedDurationMinutes: estimatedDurationMinutes,
    checklistItems: checklistItems,
    createdAt: createdAt,
  );

  group('Task aggregate identity and defaults', () {
    test('creates one stable account-owned identity and trims its title', () {
      final task = buildTask();

      expect(task.id, kTasksTestTaskId);
      expect(task.accountId, kTasksTestAccountA);
      expect(task.title, 'Prepare weekly plan');
      expect(task.createdAt, createdAt);
      expect(task.updatedAt, createdAt);
      expect(task.deletedAt, isNull);
      expect(task.completedAt, isNull);
    });

    test('uses the verified title-only defaults', () {
      final task = buildTask();

      expect(task.scheduledDate, today);
      expect(task.category, TaskCategory.work);
      expect(task.quadrant, EisenhowerQuadrant.urgentImportant);
      expect(task.estimatedDurationMinutes, 30);
      expect(task.checklistItems, isEmpty);
    });

    test('rejects blank titles and invalid numeric snapshots', () {
      expect(() => buildTask(title: ' \n\t '), throwsArgumentError);
      expect(() => buildTask(estimatedDurationMinutes: 0), throwsArgumentError);
    });
  });

  group('Task value coverage', () {
    test('defines exactly the seven approved categories', () {
      expect(TaskCategory.values, <TaskCategory>[
        TaskCategory.work,
        TaskCategory.study,
        TaskCategory.personal,
        TaskCategory.health,
        TaskCategory.spiritual,
        TaskCategory.finance,
        TaskCategory.other,
      ]);
    });

    test('defines exactly the four approved Eisenhower quadrants', () {
      expect(EisenhowerQuadrant.values, <EisenhowerQuadrant>[
        EisenhowerQuadrant.urgentImportant,
        EisenhowerQuadrant.notUrgentImportant,
        EisenhowerQuadrant.urgentNotImportant,
        EisenhowerQuadrant.notUrgentNotImportant,
      ]);
    });

    test('preserves supported optional values', () {
      final scheduledTime = DateTime(2026, 10, 8, 14, 30);
      final deadline = DateTime.utc(2026, 10, 9, 18);
      const item = ChecklistItem(
        id: 'step-1',
        text: 'Collect notes',
        completed: false,
        order: 0,
      );

      final task = buildTask(
        description: 'Use the current project notes',
        scheduledTime: scheduledTime,
        targetDeadline: deadline,
        targetDeadlineUtcOffsetMinutes: 120,
        estimatedDurationMinutes: 45,
        checklistItems: const <ChecklistItem>[item],
      );

      expect(task.description, 'Use the current project notes');
      expect(task.scheduledTime, scheduledTime);
      expect(task.targetDeadline, deadline);
      expect(task.targetDeadlineUtcOffsetMinutes, 120);
      expect(task.estimatedDurationMinutes, 45);
      expect(task.checklistItems, const <ChecklistItem>[item]);
    });
  });

  group('Task tombstone', () {
    test(
      'deletion keeps identity and payload while hiding the active task',
      () {
        final task = buildTask();
        final deletedAt = createdAt.add(const Duration(hours: 1));

        final tombstone = task.markDeleted(deletedAt);

        expect(tombstone.id, task.id);
        expect(tombstone.accountId, task.accountId);
        expect(tombstone.title, task.title);
        expect(tombstone.deletedAt, deletedAt);
        expect(tombstone.updatedAt, deletedAt);
        expect(tombstone.isDeleted, isTrue);
      },
    );

    test('rejects a tombstone older than the current Task version', () {
      final task = buildTask();

      expect(
        () => task.markDeleted(createdAt.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });
  });

  group('Task projections', () {
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    Task projectionTask({
      required String id,
      required DateTime date,
      TaskCategory category = TaskCategory.work,
      EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
      DateTime? completedAt,
      DateTime? deletedAt,
    }) => Task.create(
      id: id,
      accountId: kTasksTestAccountA,
      title: id,
      scheduledDate: date,
      category: category,
      quadrant: quadrant,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: deletedAt ?? createdAt,
      deletedAt: deletedAt,
    );

    test('All includes completed but excludes tombstones', () {
      final open = projectionTask(id: 'open', date: today);
      final completed = projectionTask(
        id: 'completed',
        date: yesterday,
        completedAt: createdAt,
      );
      final deletedAt = createdAt.add(const Duration(minutes: 1));
      final deleted = projectionTask(
        id: 'deleted',
        date: today,
        deletedAt: deletedAt,
      );

      expect(TaskRules.all(<Task>[open, completed, deleted]), <Task>[
        open,
        completed,
      ]);
    });

    test('Today, Urgent and matrix contain open canonical identities only', () {
      final todayTask = projectionTask(id: 'today', date: today);
      final urgentFuture = projectionTask(
        id: 'urgent-future',
        date: tomorrow,
        quadrant: EisenhowerQuadrant.urgentNotImportant,
      );
      final nonUrgent = projectionTask(
        id: 'non-urgent',
        date: today,
        quadrant: EisenhowerQuadrant.notUrgentImportant,
      );
      final completed = projectionTask(
        id: 'completed',
        date: today,
        completedAt: createdAt,
      );
      final source = <Task>[todayTask, urgentFuture, nonUrgent, completed];

      expect(TaskRules.today(source, today), <Task>[todayTask, nonUrgent]);
      expect(TaskRules.urgent(source), <Task>[todayTask, urgentFuture]);
      final matrix = TaskRules.matrix(source);
      final matrixTasks = matrix.values.expand((tasks) => tasks).toList();
      expect(matrixTasks.toSet(), <Task>{todayTask, urgentFuture, nonUrgent});
      expect(matrixTasks, everyElement(isIn(source)));
      expect(matrixTasks.map((task) => task.id).toSet(), hasLength(3));
    });

    test('Completed and category filters reuse the same Task instances', () {
      final work = projectionTask(id: 'work', date: today);
      final study = projectionTask(
        id: 'study',
        date: today,
        category: TaskCategory.study,
        completedAt: createdAt,
      );
      final source = <Task>[work, study];

      expect(TaskRules.completed(source), <Task>[study]);
      expect(TaskRules.byCategory(source, TaskCategory.study), <Task>[study]);
      expect(
        identical(TaskRules.byCategory(source, TaskCategory.work).single, work),
        isTrue,
      );
    });
  });

  group('Task payload codec', () {
    const codec = TaskPayloadCodec();

    test('the reward is the shared constant, whatever a payload says', () {
      final task = buildTask();
      final encoded = jsonDecode(codec.encode(task)) as Map<String, dynamic>;
      expect(encoded['completionXp'], kTaskCompletionXp);

      // Older builds and other clients may send any value; it is never read.
      final legacy = jsonEncode(<String, dynamic>{
        ...encoded,
        'completionXp': 35,
      });
      final decoded = codec.decode(legacy);
      expect(decoded, task);
      expect(codec.encode(decoded), codec.encode(task));
    });

    test('round-trips all optional values, checklist order and tombstone', () {
      final deletedAt = createdAt.add(const Duration(hours: 2));
      final source = Task.create(
        id: kTasksTestTaskId,
        accountId: kTasksTestAccountA,
        title: 'Encoded Task',
        description: 'Every supported optional field',
        scheduledDate: today,
        scheduledTime: DateTime(2026, 10, 8, 14, 30),
        targetDeadline: DateTime.utc(2026, 10, 9, 18),
        targetDeadlineUtcOffsetMinutes: 120,
        category: TaskCategory.study,
        quadrant: EisenhowerQuadrant.notUrgentImportant,
        estimatedDurationMinutes: 45,
        checklistItems: const <ChecklistItem>[
          ChecklistItem(id: 'step-1', text: 'First', completed: true, order: 0),
          ChecklistItem(
            id: 'step-2',
            text: 'Second',
            completed: false,
            order: 1,
          ),
        ],
        completedAt: DateTime.utc(2026, 10, 8, 10),
        createdAt: createdAt,
        updatedAt: deletedAt,
        deletedAt: deletedAt,
      );

      final encoded = codec.encode(source);
      final decoded = codec.decode(encoded);

      expect(decoded, source);
      expect(codec.encode(decoded), encoded, reason: 'serialization is stable');
      expect(decoded.scheduledDate, today);
      expect(decoded.scheduledTime, DateTime(2026, 10, 8, 14, 30));
      expect(decoded.targetDeadline?.isUtc, isTrue);
      expect(decoded.targetDeadlineUtcOffsetMinutes, 120);
      expect(decoded.checklistItems.map((item) => item.id), <String>[
        'step-1',
        'step-2',
      ]);
    });

    test('preserves absent optional values and normalizes versions to UTC', () {
      final source = buildTask();
      final payload = jsonDecode(codec.encode(source)) as Map<String, dynamic>;
      payload['updatedAt'] = '2026-10-08T11:00:00+02:00';

      final decoded = codec.decode(jsonEncode(payload));

      expect(decoded.description, isNull);
      expect(decoded.scheduledTime, isNull);
      expect(decoded.targetDeadline, isNull);
      expect(decoded.completedAt, isNull);
      expect(decoded.deletedAt, isNull);
      expect(decoded.updatedAt, DateTime.utc(2026, 10, 8, 9));
      expect(decoded.updatedAt.isUtc, isTrue);
    });
  });
}
