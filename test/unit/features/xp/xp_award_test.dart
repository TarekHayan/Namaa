import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29);
  test('only approved source and amount pairs are accepted', () {
    for (final pair in [
      ('task_done', 20),
      ('prayer_done', 10),
      ('prayer_done', 5),
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
    for (final pair in [
      ('other', 10),
      ('task_done', 5),
      ('prayer_done', 20),
      ('prayer_done', -1),
    ]) {
      expect(
        () => XpAward(
          accountId: 'owner',
          source: pair.$1,
          sourceId: 'source-id',
          amount: pair.$2,
          awardedAt: now,
        ),
        throwsArgumentError,
      );
    }
  });
}
