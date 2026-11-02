library;

import 'dart:async';

import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

/// Joins the two explicitly approved preview ledgers for Today's read model.
///
/// Rows stay in their original owner partitions. The returned references are
/// scoped to Today's existing XP owner so the domain projection can remain as
/// strict in preview as it is for a real single-account scope.
final class PrayerPreviewXpAdapter implements TodayXpPort {
  const PrayerPreviewXpAdapter(this._ledger);

  final SharedAwardLedgerPort _ledger;

  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) {
    if (ownerId != kTasksPreviewAccountId) {
      return Stream.error(
        ArgumentError.value(ownerId, 'ownerId', 'Unknown preview XP owner'),
      );
    }

    late StreamController<List<TodayAwardReference>> controller;
    StreamSubscription<List<XpAward>>? taskSubscription;
    StreamSubscription<List<XpAward>>? prayerSubscription;
    List<XpAward>? taskRows;
    List<XpAward>? prayerRows;

    void emitWhenReady() {
      final tasks = taskRows;
      final prayers = prayerRows;
      if (tasks == null || prayers == null || controller.isClosed) return;
      controller.add(
        List.unmodifiable([
          ..._references(tasks, kTasksPreviewAccountId, ownerId),
          ..._references(prayers, kPrayerPreviewAccountId, ownerId),
        ]),
      );
    }

    controller = StreamController<List<TodayAwardReference>>(
      onListen: () {
        taskSubscription = _ledger
            .watchSharedAwards(kTasksPreviewAccountId)
            .listen((rows) {
              taskRows = rows;
              emitWhenReady();
            }, onError: controller.addError);
        prayerSubscription = _ledger
            .watchSharedAwards(kPrayerPreviewAccountId)
            .listen((rows) {
              prayerRows = rows;
              emitWhenReady();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await taskSubscription?.cancel();
        await prayerSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  static Iterable<TodayAwardReference> _references(
    Iterable<XpAward> rows,
    String sourceOwner,
    String todayOwner,
  ) sync* {
    for (final award in rows) {
      if (award.accountId != sourceOwner) continue;
      yield TodayAwardReference(
        ownerId: todayOwner,
        source: award.source,
        sourceId: award.sourceId,
        amount: award.amount,
        awardedAtUtc: award.awardedAt,
      );
    }
  }
}
