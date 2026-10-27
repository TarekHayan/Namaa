import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/habits_test_support.dart';

void main() {
  late TemporaryDatabasePath path;
  late FoundationDatabase database;
  late HabitsTestClock clock;
  late HabitCommands commands;
  late DriftHabitRepository repository;
  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (i) => i + 50),
    );
    clock = HabitsTestClock();
    final ids = HabitsTestIds();
    repository = DriftHabitRepository(
      database: database,
      codec: const HabitPayloadCodec(),
    );
    commands = HabitCommands(
      repository: repository,
      session: const TasksPreviewSession(),
      nowUtc: clock.utcNow,
      localCalendar: clock.captureLocalCalendar,
      nextHabitId: ids.nextHabitId,
      nextRevisionId: ids.nextRevisionId,
      nextOperationId: ids.nextOperationId,
    );
  });
  tearDown(() async {
    await database.close();
    path.dispose();
  });

  test(
    'edit changes today immediately, saves reminder, and allows undo after removal',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {DateTime.monday}),
      )).valueOrNull!;
      expect(
        (await commands.completeHabitToday(habit.id)).failureOrNull,
        isNull,
      );
      final edited = (await commands.editHabit(
        EditHabitInput(
          habitId: habit.id,
          name: 'Read books',
          weekdays: {DateTime.wednesday},
          reminderMinuteOfDay: 480,
        ),
      )).valueOrNull!;
      expect(edited.name, 'Read books');
      expect(edited.reminderMinuteOfDay, 480);
      expect(edited.isDueOn(clock.localDate), isFalse);
      expect(edited.scheduleRevisions, hasLength(2));
      expect(
        await database.rawScalar(
          "SELECT count(*) FROM pending_changes WHERE entity_type = 'habit' "
          'AND base_updated_at IS NOT NULL',
        ),
        1,
      );
      expect(edited.currentRevision.effectiveAt, clock.utcNow());
      expect((await commands.undoHabitToday(habit.id)).failureOrNull, isNull);
      expect(
        (await commands.completeHabitToday(habit.id)).failureOrNull?.category,
        AppFailureCategory.validation,
      );
      final renamed = (await commands.editHabit(
        EditHabitInput(
          habitId: habit.id,
          name: 'Reading',
          weekdays: {DateTime.wednesday},
          reminderMinuteOfDay: null,
        ),
      )).valueOrNull!;
      expect(renamed.scheduleRevisions, hasLength(2));
      expect(renamed.reminderMinuteOfDay, isNull);
    },
  );

  test(
    'delete needs confirmation and account ownership; confirmed delete tombstones',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {DateTime.monday}),
      )).valueOrNull!;
      expect(
        (await commands.deleteHabit(
          habit.id,
          confirmed: false,
        )).failureOrNull?.category,
        AppFailureCategory.validation,
      );
      expect(
        (await commands.deleteHabit(
          habit.id,
          confirmed: true,
          expectedAccountId: kHabitsTestAccountB,
        )).failureOrNull?.category,
        AppFailureCategory.authorization,
      );
      expect(
        (await commands.deleteHabit(
          habit.id,
          confirmed: true,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      expect(
        await database.rawScalar(
          "SELECT count(*) FROM pending_changes WHERE entity_type = 'habit' "
          'AND base_updated_at IS NOT NULL',
        ),
        1,
      );
      expect(
        (await repository.readHabit(
          accountId: kTasksPreviewAccountId,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      expect(
        (await commands.editHabit(
          EditHabitInput(
            habitId: habit.id,
            name: 'New',
            weekdays: {1},
            reminderMinuteOfDay: null,
          ),
        )).failureOrNull?.category,
        AppFailureCategory.notFound,
      );
    },
  );

  test(
    'concurrent edit and delete preserve the last committed habit version',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {DateTime.monday}),
      )).valueOrNull!;

      final edit = commands.editHabit(
        EditHabitInput(
          habitId: habit.id,
          name: 'Read books',
          weekdays: {DateTime.monday},
          reminderMinuteOfDay: null,
        ),
      );
      final delete = commands.deleteHabit(habit.id, confirmed: true);
      final edited = await edit;
      final deleted = await delete;
      final stored = (await repository.readHabit(
        accountId: kTasksPreviewAccountId,
        habitId: habit.id,
      )).valueOrNull!;

      expect(deleted.failureOrNull, isNull);
      expect(stored.isDeleted, isTrue);
      if (edited.failureOrNull == null) {
        expect(stored.name, 'Read books');
        expect(
          stored.scheduleRevisions.length,
          edited.valueOrNull!.scheduleRevisions.length,
        );
      } else {
        expect(edited.failureOrNull?.category, AppFailureCategory.notFound);
      }
    },
  );
}
