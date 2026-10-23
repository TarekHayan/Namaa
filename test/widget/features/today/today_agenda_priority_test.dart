import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/features/today/domain/today_agenda.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/presentation/widgets/today_agenda_section.dart';
import 'package:namma_project/features/today/presentation/widgets/today_overdue_section.dart';
import 'package:namma_project/features/today/presentation/widgets/today_priority_section.dart';

void main() {
  final today = TodayLocalDate(2026, 10, 23);
  TodayTaskReference task(
    String id,
    int? minute, {
    bool completed = false,
    TodayLocalDate? date,
    bool overdue = false,
  }) => TodayTaskReference(
    taskId: id,
    ownerId: 'owner',
    title: id,
    scheduledLocalDate: date ?? today,
    scheduledMinuteOfDay: minute,
    estimatedDurationMinutes: minute == null ? null : 45,
    isCompleted: completed,
    isUrgentImportant: true,
    isOverdue: overdue,
    ownerOrder: minute ?? 0,
  );

  testWidgets(
    'agenda separates untimed, preserves saved duration and opens owner',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TodayAgendaSection(
                agenda: TodayAgenda.project(today, [
                  task('Timed work', 540),
                  task('Untimed work', null, completed: true),
                ], ownerId: 'owner'),
                strings: resolveTodayStrings(context),
                onOpenTasks: () => opens++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Timed'), findsOneWidget);
      expect(find.text('Untimed'), findsOneWidget);
      expect(find.textContaining('45'), findsOneWidget);
      expect(find.textContaining('9:00'), findsOneWidget);
      final untimed = tester.widget<ListTile>(
        find.byKey(const Key('today_task_Untimed work')),
      );
      expect(untimed.subtitle.toString(), isNot(contains('9:00')));
      await tester.tap(find.text('Untimed work'));
      expect(opens, 1);
    },
  );

  testWidgets('priority and overdue use owner links and keep dates visible', (
    tester,
  ) async {
    var opens = 0;
    var matrix = 0;
    var overdue = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final strings = resolveTodayStrings(context);
              return Column(
                children: [
                  TodayPrioritySection(
                    tasks: [
                      task(
                        'First',
                        null,
                        date: TodayLocalDate(2026, 10, 22),
                        overdue: true,
                      ),
                    ],
                    strings: strings,
                    onOpenTasks: () => opens++,
                    onOpenMatrix: () => matrix++,
                  ),
                  TodayOverdueSection(
                    count: 2,
                    strings: strings,
                    onOpenOverdue: () => overdue++,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('October'), findsWidgets);
    expect(find.byKey(const Key('today_task_action_First')), findsNothing);
    await tester.tap(find.text('First'));
    await tester.tap(find.byKey(const Key('today_open_matrix')));
    await tester.tap(find.byKey(const Key('today_open_overdue')));
    expect((opens, matrix, overdue), (1, 1, 1));
  });

  testWidgets('Arabic agenda labels and task references inherit RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TodayAgendaSection(
              agenda: TodayAgenda.project(today, [
                task('مهمة طويلة اليوم', 540),
                task('مهمة بدون وقت', null),
              ], ownerId: 'owner'),
              strings: resolveTodayStrings(context),
              onOpenTasks: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('بموعد محدد'), findsOneWidget);
    expect(find.text('بدون موعد محدد'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('مهمة طويلة اليوم'))),
      TextDirection.rtl,
    );
  });
}
