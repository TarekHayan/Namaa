import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

/// T013: the 009 XP sources in the shared, single-authority ledger.
/// `adhkar_set_done` is 15 once per owner/day/list, `qiyam_done` is 30 once
/// per owner/night. Task 20 and Prayer 10/5 stay unchanged.
void main() {
  final now = DateTime.utc(2026, 11, 9, 6);

  test('adhkar_set_done is accepted only with 15', () {
    expect(
      () => XpAward(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: 'adhkar/2026-11-09/morning',
        amount: 15,
        awardedAt: now,
      ),
      returnsNormally,
    );
    for (final amount in [5, 10, 20, 30, 0, -1]) {
      expect(
        () => XpAward(
          accountId: 'owner',
          source: kAdhkarSetDoneAwardSource,
          sourceId: 'source-id',
          amount: amount,
          awardedAt: now,
        ),
        throwsArgumentError,
        reason: 'amount $amount must be rejected',
      );
    }
  });

  test('qiyam_done is accepted only with 30', () {
    expect(
      () => XpAward(
        accountId: 'owner',
        source: kQiyamDoneAwardSource,
        sourceId: 'night-record-id',
        amount: 30,
        awardedAt: now,
      ),
      returnsNormally,
    );
    for (final amount in [5, 10, 15, 20, 0, -1]) {
      expect(
        () => XpAward(
          accountId: 'owner',
          source: kQiyamDoneAwardSource,
          sourceId: 'source-id',
          amount: amount,
          awardedAt: now,
        ),
        throwsArgumentError,
        reason: 'amount $amount must be rejected',
      );
    }
  });

  test('fromStored accepts both new sources', () {
    expect(
      XpAward.fromStored(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: 'adhkar/2026-11-09/evening',
        amount: 15,
        awardedAt: now,
      ).amount,
      15,
    );
    expect(
      XpAward.fromStored(
        accountId: 'owner',
        source: kQiyamDoneAwardSource,
        sourceId: 'night-record-id',
        amount: 30,
        awardedAt: now,
      ).amount,
      30,
    );
    // fromStored keeps its pre-existing loose amount semantics (legacy rows);
    // the strict constructor above is what enforces the 15/30 pairing.
    expect(
      XpAward.fromStored(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: 'source-id',
        amount: 30,
        awardedAt: now,
      ).amount,
      30,
    );
  });

  test('task_done 20 and prayer_done 10/5 stay unchanged', () {
    for (final pair in [
      ('task_done', 20),
      (kPrayerDoneAwardSource, 10),
      (kPrayerDoneAwardSource, 5),
    ]) {
      expect(
        () => XpAward(
          accountId: 'owner',
          source: pair.$1,
          sourceId: 'source-id',
          amount: pair.$2,
          awardedAt: now,
        ),
        returnsNormally,
      );
    }
    // The new sources do not open the door to arbitrary amounts elsewhere.
    expect(
      () => XpAward(
        accountId: 'owner',
        source: kAdhkarSetDoneAwardSource,
        sourceId: 'source-id',
        amount: 10,
        awardedAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('uniqueKey stays owner/source/sourceId', () {
    final award = XpAward(
      accountId: 'owner',
      source: kQiyamDoneAwardSource,
      sourceId: 'night-record-id',
      amount: 30,
      awardedAt: now,
    );
    expect(award.uniqueKey, 'owner/$kQiyamDoneAwardSource/night-record-id');
  });
}
