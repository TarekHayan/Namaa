import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/app/composition/prayer_preview_xp_adapter.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/composition/today_scope_resolver.dart';
import 'package:namma_project/features/today/data/xp_today_adapter.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

final class _Ledger implements SharedAwardLedgerPort {
  _Ledger(this.rows);

  final Map<String, List<XpAward>> rows;
  final calls = <String>[];

  @override
  Stream<List<XpAward>> watchSharedAwards(String accountId) {
    calls.add(accountId);
    return Stream.value(rows[accountId] ?? const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

XpAward _award({
  required String owner,
  required String source,
  required String sourceId,
  required int amount,
}) => XpAward(
  accountId: owner,
  source: source,
  sourceId: sourceId,
  amount: amount,
  awardedAt: DateTime.utc(2026, 11, 1, 5),
);

void main() {
  test('preview scope keeps Task, Habit and Prayer owners isolated', () async {
    final scope = await TodayScopeResolver.preview().resolveInitial();

    expect(scope?.taskOwnerId, kTasksPreviewAccountId);
    expect(scope?.habitOwnerId, kHabitsPreviewAccountId);
    expect(scope?.prayerOwnerId, kPrayerPreviewAccountId);
    expect(scope?.xpOwnerId, kTasksPreviewAccountId);
    expect(
      {scope?.taskOwnerId, scope?.habitOwnerId, scope?.prayerOwnerId}.length,
      3,
    );
  });

  test(
    'preview XP joins only fixed Task and Prayer ledgers without row copies',
    () async {
      final ledger = _Ledger({
        kTasksPreviewAccountId: [
          _award(
            owner: kTasksPreviewAccountId,
            source: 'task_done',
            sourceId: 'task-1',
            amount: 20,
          ),
          _award(
            owner: 'foreign-owner',
            source: 'task_done',
            sourceId: 'foreign',
            amount: 20,
          ),
        ],
        kPrayerPreviewAccountId: [
          _award(
            owner: kPrayerPreviewAccountId,
            source: 'prayer_done',
            sourceId: '2026-11-01/fajr',
            amount: 10,
          ),
        ],
        kHabitsPreviewAccountId: [
          _award(
            owner: kHabitsPreviewAccountId,
            source: 'task_done',
            sourceId: 'habit-partition',
            amount: 20,
          ),
        ],
      });

      final rows = await PrayerPreviewXpAdapter(
        ledger,
      ).watchAwards(kTasksPreviewAccountId).first;

      expect(ledger.calls, [kTasksPreviewAccountId, kPrayerPreviewAccountId]);
      expect(rows.map((row) => row.amount), [20, 10]);
      expect(
        rows.every((row) => row.ownerId == kTasksPreviewAccountId),
        isTrue,
      );
      expect(
        ledger.rows[kPrayerPreviewAccountId]!.single.accountId,
        kPrayerPreviewAccountId,
        reason: 'The adapter must not copy or rewrite the stored Prayer row.',
      );
    },
  );

  test('account mode reads the one resolved real owner only', () async {
    final ledger = _Ledger({
      'account-a': [
        _award(
          owner: 'account-a',
          source: 'prayer_done',
          sourceId: '2026-11-01/dhuhr',
          amount: 5,
        ),
      ],
    });

    final rows = await XpTodayAdapter(ledger).watchAwards('account-a').first;

    expect(ledger.calls, ['account-a']);
    expect(rows.single.ownerId, 'account-a');
  });

  test('preview adapter rejects any non-closed XP owner', () {
    expect(
      PrayerPreviewXpAdapter(
        _Ledger(const {}),
      ).watchAwards('real-account').first,
      throwsArgumentError,
    );
  });
}
