import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 11, 8);
  final firstCompletion = DateTime.utc(2026, 10, 11, 9);
  final reopenedAt = DateTime.utc(2026, 10, 11, 10);
  final secondCompletion = DateTime.utc(2026, 10, 11, 11);

  Task openTask({List<ChecklistItem> checklistItems = const []}) => Task.create(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    accountId: '11111111-1111-1111-1111-111111111111',
    title: 'Finish the report',
    scheduledDate: DateTime(2026, 10, 11),
    checklistItems: checklistItems,
    completionXp: 35,
    createdAt: createdAt,
  );

  test('explicit completion records its UTC time and advances the version', () {
    final task = openTask();

    final completed = task.complete(firstCompletion);

    expect(completed.id, task.id);
    expect(completed.completedAt, firstCompletion);
    expect(completed.updatedAt, firstCompletion);
    expect(completed.completionChangedAt, firstCompletion);
    expect(completed.isCompleted, isTrue);
    expect(completed.completionXp, 35);
  });

  test('reopening clears completion and preserves the reward snapshot', () {
    final completed = openTask().complete(firstCompletion);

    final reopened = completed.reopen(reopenedAt);

    expect(reopened.completedAt, isNull);
    expect(reopened.updatedAt, reopenedAt);
    expect(reopened.completionChangedAt, reopenedAt);
    expect(reopened.completionXp, completed.completionXp);
    expect(reopened.id, completed.id);
  });

  test('recompletion records a new current completion time', () {
    final reopened = openTask().complete(firstCompletion).reopen(reopenedAt);

    final completedAgain = reopened.complete(secondCompletion);

    expect(completedAgain.completedAt, secondCompletion);
    expect(completedAgain.updatedAt, secondCompletion);
    expect(completedAgain.completionChangedAt, secondCompletion);
  });

  test('repeating complete while already complete is not a new event', () {
    final completed = openTask().complete(firstCompletion);

    final repeated = completed.complete(secondCompletion);

    expect(repeated, same(completed));
    expect(repeated.completedAt, firstCompletion);
    expect(repeated.updatedAt, firstCompletion);
    expect(repeated.completionChangedAt, firstCompletion);
  });

  test('title edits do not advance completion transition', () {
    final completed = openTask().complete(firstCompletion);
    final renamed = completed.copyWith(title: 'Renamed', updatedAt: reopenedAt);
    expect(renamed.completionChangedAt, firstCompletion);
    final reopened = renamed.reopen(secondCompletion);
    expect(reopened.completionChangedAt, secondCompletion);
  });

  test('an incomplete checklist does not block explicit completion', () {
    const checklist = <ChecklistItem>[
      ChecklistItem(
        id: 'step-1',
        text: 'Collect the figures',
        completed: true,
        order: 0,
      ),
      ChecklistItem(
        id: 'step-2',
        text: 'Write the conclusion',
        completed: false,
        order: 1,
      ),
    ];
    final task = openTask(checklistItems: checklist);

    final completed = task.complete(firstCompletion);

    expect(completed.isCompleted, isTrue);
    expect(completed.checklistItems, checklist);
    expect(completed.checklistItems.last.completed, isFalse);
  });
}
