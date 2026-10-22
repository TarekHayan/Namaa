import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';

void main() {
  test('real scope keeps every source on one account', () {
    final scope = TodayScope.account(accountId: 'account-a', generation: 2);
    expect(scope.taskOwnerId, scope.habitOwnerId);
    expect(scope.taskOwnerId, scope.xpOwnerId);
    expect(scope.scopeKey, 'account:account-a');
    expect(
      () => TodayScope.preview(
        taskOwnerId: 'same',
        habitOwnerId: 'same',
        generation: 0,
      ),
      throwsArgumentError,
    );
  });

  test('local dates keep calendar identity and reject invalid keys', () {
    final day = TodayLocalDate.parse('2026-10-12');
    expect(day.next.key, '2026-10-13');
    expect(day.weekday, DateTime.monday);
    expect(() => TodayLocalDate.parse('2026-02-30'), throwsArgumentError);
    expect(() => TodayLocalDate.parse('2026-1-2'), throwsFormatException);
  });

  test('unavailable is unknown while confirmed empty retains its value', () {
    final failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'fixture.failure',
      occurredAt: DateTime.utc(2026, 10, 12),
    );
    final empty = TodaySection<List<String>>.empty(const []);
    final unavailable = TodaySection<List<String>>.unavailable(failure);
    final stale = TodaySection<List<String>>.stale(const ['old'], failure);
    expect(empty.hasConfirmedValue, isTrue);
    expect(empty.value, isEmpty);
    expect(unavailable.hasConfirmedValue, isFalse);
    expect(unavailable.value, isNull);
    expect(stale.hasConfirmedValue, isTrue);
    expect(stale.allowsMutation, isFalse);
    expect(stale.needsRetry, isTrue);
  });
}
