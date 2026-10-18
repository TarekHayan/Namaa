import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/habits_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Arabic RTL and English Habit routes work on mobile and desktop',
    (tester) async {
      final path = TemporaryDatabasePath();
      final database = await FoundationDatabase.openEncrypted(
        path: path.allocate(),
        key: List<int>.generate(32, (i) => i + 130),
      );
      final clock = HabitsTestClock();
      final ids = HabitsTestIds();
      final repository = DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      );
      final cubit = HabitsCubit(
        repository: repository,
        commands: HabitCommands(
          repository: repository,
          session: const HabitsPreviewSession(),
          nowUtc: clock.utcNow,
          localCalendar: clock.captureLocalCalendar,
          nextHabitId: ids.nextHabitId,
          nextRevisionId: ids.nextRevisionId,
          nextOperationId: ids.nextOperationId,
        ),
        localCalendar: clock.captureLocalCalendar,
      );
      final router = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('root')),
        habitsSession: const HabitsPreviewSession(),
        habitsBuilder: (_, accountId) => HabitsScreen(
          cubit: cubit,
          accountId: accountId,
          stringsResolver: resolveHabitsStrings,
        ),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await cubit.close();
        await database.close();
        path.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      Widget app(Locale locale) => MaterialApp.router(
        locale: locale,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: router.router,
      );
      await tester.pumpWidget(app(const Locale('ar')));
      router.go(kHabitsRoute);
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitsMobileLayoutKey), findsOneWidget);
      expect(find.text('العادات'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(kHabitsMobileLayoutKey))),
        TextDirection.rtl,
      );
      await tester.tap(find.byKey(kHabitAddButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kHabitNameFieldKey));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(find.byKey(kHabitNameFieldKey), 'قراءة');
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitsDesktopLayoutKey), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
    },
  );
}
