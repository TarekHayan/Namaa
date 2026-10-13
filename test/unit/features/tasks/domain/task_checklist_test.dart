import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 8, 9);

  Task task({String id = 'task-a'}) => Task.create(
    id: id,
    accountId: 'account-a',
    title: 'Plan the day',
    scheduledDate: DateTime(2026, 10, 8),
    createdAt: createdAt,
  );

  test(
    'add preserves stable item IDs and insertion order inside one parent',
    () {
      final firstVersion = task().addChecklistItem(
        id: 'step-a',
        text: '  Draft outline  ',
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      );
      final secondVersion = firstVersion.addChecklistItem(
        id: 'step-b',
        text: 'Review outline',
        updatedAt: createdAt.add(const Duration(minutes: 2)),
      );

      expect(secondVersion.id, 'task-a');
      expect(secondVersion.checklistItems, const <ChecklistItem>[
        ChecklistItem(
          id: 'step-a',
          text: 'Draft outline',
          completed: false,
          order: 0,
        ),
        ChecklistItem(
          id: 'step-b',
          text: 'Review outline',
          completed: false,
          order: 1,
        ),
      ]);
    },
  );

  test('editing and checking a step change only its Task-owned value', () {
    final original = task().addChecklistItem(
      id: 'step-a',
      text: 'Draft outline',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    final edited = original.editChecklistItem(
      itemId: 'step-a',
      text: '  Final outline  ',
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    final checked = edited.setChecklistItemCompleted(
      itemId: 'step-a',
      completed: true,
      updatedAt: createdAt.add(const Duration(minutes: 3)),
    );

    expect(checked.checklistItems.single.id, 'step-a');
    expect(checked.checklistItems.single.order, 0);
    expect(checked.checklistItems.single.text, 'Final outline');
    expect(checked.checklistItems.single.completed, isTrue);
    expect(checked.scheduledDate, original.scheduledDate);
    expect(checked.category, original.category);
    expect(checked.quadrant, original.quadrant);
    expect(checked.completionXp, original.completionXp);
    expect(checked.completedAt, isNull);
  });

  test('blank step text and duplicate IDs are rejected', () {
    expect(
      () => task().addChecklistItem(
        id: 'step-a',
        text: '  ',
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );

    final withStep = task().addChecklistItem(
      id: 'step-a',
      text: 'First',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    expect(
      () => withStep.addChecklistItem(
        id: 'step-a',
        text: 'Duplicate',
        updatedAt: createdAt.add(const Duration(minutes: 2)),
      ),
      throwsArgumentError,
    );
    expect(
      () => withStep.editChecklistItem(
        itemId: 'step-a',
        text: '\n ',
        updatedAt: createdAt.add(const Duration(minutes: 2)),
      ),
      throwsArgumentError,
    );
  });

  test('remove affects only its parent and keeps remaining identity/order', () {
    final firstParent = task()
        .addChecklistItem(
          id: 'step-a',
          text: 'First',
          updatedAt: createdAt.add(const Duration(minutes: 1)),
        )
        .addChecklistItem(
          id: 'step-b',
          text: 'Second',
          updatedAt: createdAt.add(const Duration(minutes: 2)),
        );
    final otherParent = task(id: 'task-b');

    final changed = firstParent.removeChecklistItem(
      itemId: 'step-a',
      updatedAt: createdAt.add(const Duration(minutes: 3)),
    );

    expect(
      changed.checklistItems.map((ChecklistItem item) => item.id),
      <String>['step-b'],
    );
    expect(changed.checklistItems.single.order, 1);
    expect(otherParent.checklistItems, isEmpty);
  });

  test('all checked steps do not complete or reward the parent', () {
    final withStep = task().addChecklistItem(
      id: 'step-a',
      text: 'Only step',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    final checked = withStep.setChecklistItemCompleted(
      itemId: 'step-a',
      completed: true,
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );

    expect(checked.checklistItems.single.completed, isTrue);
    expect(checked.isCompleted, isFalse);
    expect(checked.completedAt, isNull);
    expect(checked.completionXp, 20);
  });

  test('explicit parent completion remains allowed with unfinished steps', () {
    final withIncompleteStep = task().addChecklistItem(
      id: 'step-a',
      text: 'Still open',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    final completedAt = createdAt.add(const Duration(minutes: 2));

    final completed = withIncompleteStep.complete(completedAt);

    expect(completed.isCompleted, isTrue);
    expect(completed.completedAt, completedAt);
    expect(completed.checklistItems.single.completed, isFalse);
  });
}
