import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/data/xp_today_adapter.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../../../../support/today_fixtures.dart';

class _Ledger implements SharedAwardLedgerPort {
  _Ledger(this.values);
  final List<TaskCompletionAward> values;
  @override
  Stream<List<XpAward>> watchSharedAwards(String ownerId) =>
      Stream.value([for (final value in values) _stored(value)]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LiveLedger implements SharedAwardLedgerPort {
  final updates = StreamController<List<XpAward>>.broadcast(sync: true);
  @override
  Stream<List<XpAward>> watchSharedAwards(String ownerId) => updates.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

XpAward _stored(TaskCompletionAward value) => XpAward.fromStored(
  accountId: value.accountId,
  source: value.source,
  sourceId: value.sourceId,
  amount: value.amount,
  awardedAt: value.awardedAt,
);

void main() {
  test(
    'exposes actual owner awards even for deleted and reopened Tasks',
    () async {
      final fixture = TodayOwnerFixture.mixedDates();
      final rows = await XpTodayAdapter(
        _Ledger(fixture.awards),
      ).watchAwards(TodayFixtureAccounts.accountA).first;
      expect(rows.length, 3);
      expect(
        rows.map((a) => a.sourceId),
        contains(TodayOwnerFixture.taskId(14)),
      );
      expect(rows.first.awardedAtUtc, DateTime.utc(2026, 10, 11, 10));
    },
  );
  test(
    'reconciliation emission replaces award evidence without estimating from Tasks',
    () async {
      final fixture = TodayOwnerFixture.mixedDates();
      final ledger = _LiveLedger();
      final emissions = <List<int>>[];
      final subscription = XpTodayAdapter(ledger)
          .watchAwards(TodayFixtureAccounts.accountA)
          .listen((rows) {
            emissions.add(rows.map((row) => row.amount).toList());
          });
      ledger.updates.add([_stored(fixture.awards[1])]);
      final original = fixture.awards[1];
      ledger.updates.add([
        _stored(
          TaskCompletionAward(
            accountId: original.accountId,
            source: original.source,
            sourceId: original.sourceId,
            amount: original.amount + 5,
            awardedAt: original.awardedAt,
          ),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [
        [original.amount],
        [original.amount + 5],
      ]);
      await subscription.cancel();
      await ledger.updates.close();
    },
  );
  test('Today includes Prayer XP from the one shared ledger', () async {
    final ledger = _LiveLedger();
    final result = XpTodayAdapter(ledger).watchAwards('owner').first;
    ledger.updates.add([
      XpAward(
        accountId: 'owner',
        source: 'task_done',
        sourceId: 'task',
        amount: 20,
        awardedAt: DateTime.utc(2026, 10, 29),
      ),
      XpAward(
        accountId: 'owner',
        source: 'prayer_done',
        sourceId: 'fajr',
        amount: 10,
        awardedAt: DateTime.utc(2026, 10, 29, 5),
      ),
      XpAward(
        accountId: 'other',
        source: 'prayer_done',
        sourceId: 'fajr',
        amount: 5,
        awardedAt: DateTime.utc(2026, 10, 29, 5),
      ),
    ]);
    final awards = await result;
    expect(awards.map((award) => award.amount), [20, 10]);
    await ledger.updates.close();
  });
}
