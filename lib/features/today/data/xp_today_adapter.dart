library;

import 'package:namma_project/features/xp/application/award_ledger.dart';

import '../application/today_xp_port.dart';
import '../domain/today_models.dart';

final class XpTodayAdapter implements TodayXpPort {
  const XpTodayAdapter(this._ledger);
  final AwardLedgerPort _ledger;

  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) => _ledger
      .watchAwards(ownerId)
      .map(
        (awards) => List.unmodifiable([
          for (final award in awards)
            if (award.accountId == ownerId)
              TodayAwardReference(
                ownerId: ownerId,
                source: award.source,
                sourceId: award.sourceId,
                amount: award.amount,
                awardedAtUtc: award.awardedAt,
              ),
        ]),
      );
}
