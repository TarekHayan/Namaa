import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    show FoundationDatabase;
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';
import '../../../support/foundation_test_support.dart';

void main() {
  test(
    'shared ledger inserts once and reconciles canonical prayer amount',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 40),
      );
      try {
        final ledger = DriftAwardLedger(db);
        final first = XpAward(
          accountId: 'owner',
          source: 'prayer_done',
          sourceId: 'report',
          amount: 5,
          awardedAt: DateTime.utc(2026, 10, 29),
        );
        final corrected = XpAward(
          accountId: 'owner',
          source: 'prayer_done',
          sourceId: 'report',
          amount: 10,
          awardedAt: DateTime.utc(2026, 10, 30),
        );
        expect(
          (await ledger.insertSharedOnce(first)).valueOrNull?.name,
          'inserted',
        );
        expect(
          (await ledger.insertSharedOnce(corrected)).valueOrNull?.name,
          'alreadyExists',
        );
        expect(
          (await ledger.readSharedAward(
            accountId: 'owner',
            source: 'prayer_done',
            sourceId: 'report',
          )).valueOrNull,
          first,
        );
        expect(
          (await ledger.applyRemoteSharedAward(corrected)).failureOrNull,
          isNull,
        );
        expect(
          (await ledger.readSharedAward(
            accountId: 'owner',
            source: 'prayer_done',
            sourceId: 'report',
          )).valueOrNull,
          corrected,
        );
        await db.rawExecute(
          'INSERT INTO xp_awards '
          '(account_id, source, source_id, amount, awarded_at) VALUES '
          "('owner', 'task_completion', 'legacy-task', 15, "
          "'2026-10-20T10:00:00Z')",
        );
        final mixed = await ledger.watchSharedAwards('owner').first;
        expect(
          mixed.map((award) => award.source),
          containsAll(['task_completion', 'prayer_done']),
        );
        expect(
          await ledger.watchAwards('owner').first,
          isEmpty,
          reason: 'Task-only readers must ignore Prayer and legacy rows',
        );
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );
}
