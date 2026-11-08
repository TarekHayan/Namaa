import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/prayer/domain/prayer_conflict_evidence.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/prayer/presentation/prayer_conflicts_view.dart';

void main() {
  testWidgets('shows both saved versions without an edit action', (
    tester,
  ) async {
    final evidence = PrayerConflictEvidence(
      id: 'conflict-1',
      date: PrayerLocalDate.parse('2026-10-29'),
      name: PrayerName.fajr,
      activeStatus: PrayerStatus.completedOnTime,
      retainedStatus: PrayerStatus.completedLate,
      activeAt: DateTime.utc(2026, 10, 29, 5),
      retainedAt: DateTime.utc(2026, 10, 29, 6),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PrayerConflictsView(conflicts: Stream.value([evidence])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تغييرات الصلاة للمراجعة'), findsOneWidget);
    expect(find.text('النسخة الحالية'), findsOneWidget);
    expect(find.text('النسخة الأخرى المحفوظة'), findsOneWidget);
    expect(find.text('سجلات الأيام السابقة للعرض فقط'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
