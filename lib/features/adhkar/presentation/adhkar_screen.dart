import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import 'adhkar_cubit.dart';
import 'adhkar_state.dart';
import 'widgets/adhkar_header.dart';
import 'widgets/adhkar_progress_card.dart';
import 'widgets/dhikr_item_card.dart';
import 'widgets/my_adhkar_tab.dart';

/// The Adhkar screen (contracts/adhkar-qiyam-ui.md): the prototype's order —
/// heading with the streak chip and the Morning/Evening switch, the progress
/// card, then the item cards. Content unavailable renders a recoverable
/// notice; an unavailable schedule keeps the lists visible with counting
/// locked (owner decision, 2026-11-10).
final class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AdhkarCubit>();
    final state = cubit.state;
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final locale = FoundationLocalizations.of(context).localeName;

    if (state.contentUnavailable) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              copy.contentUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final clock = state.clock;
    // My Adhkar is the user's own collection: no progress card, counter,
    // time window or locked state, and no Adhkar schedule notice.
    final isMine = state.selectedTab == AdhkarTab.myAdhkar;
    final morning = state.selectedTab == AdhkarTab.morning;
    final items = isMine
        ? const <DhikrItem>[]
        : state.catalog?.itemsOf(
                morning ? AdhkarList.morning : AdhkarList.evening,
              ) ??
              const [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdhkarHeader(
                copy: copy,
                streak: state.streak,
                selectedTab: state.selectedTab,
                scheduleState: isMine ? null : clock?.scheduleState,
                onTabChanged: cubit.selectTab,
              ),
              const SizedBox(height: 12),
              if (isMine)
                const MyAdhkarTab()
              else ...[
                AdhkarProgressCard(
                  copy: copy,
                  locale: locale,
                  listLabel: copy.tabLabel(morning),
                  completed: morning
                      ? state.completedOf(AdhkarList.morning)
                      : state.completedOf(AdhkarList.evening),
                  total: morning
                      ? state.totalOf(AdhkarList.morning)
                      : state.totalOf(AdhkarList.evening),
                  countable: morning
                      ? (clock?.morningCountable ?? false)
                      : (clock?.eveningCountable ?? false),
                  startsAtUtc: clock?.nextBoundaryUtc,
                  zoneId: clock?.zoneId,
                  countingLocked: state.countingLocked,
                ),
                const SizedBox(height: 12),
                if (state.celebration != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CelebrationBanner(copy: copy),
                  ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DhikrItemCard(
                      copy: copy,
                      locale: locale,
                      key: Key('adhkar_item_card_${item.itemId}'),
                      itemId: item.itemId,
                      position: item.position,
                      target: item.target,
                      isQuran: item.kind == DhikrKind.quran,
                      textAr: item.textAr,
                      virtueAr: item.virtueAr,
                      referenceAr: item.referenceAr,
                      surah: item.surah,
                      ayahFrom: item.ayahFrom,
                      ayahTo: item.ayahTo,
                      prefaceAr: item.prefaceAr,
                      count: state.countOf(item.itemId),
                      status: state.itemStatus[item.itemId],
                      countable: morning
                          ? (clock?.morningCountable ?? false)
                          : (clock?.eveningCountable ?? false),
                      onCount: () =>
                          cubit.increment(item.itemId, clock?.day ?? ''),
                      onReset: () => cubit.reset(item.itemId, clock?.day ?? ''),
                    ),
                  ),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      copy.quranAttribution,
                      key: const Key('adhkar_attribution'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({required this.copy});

  final AdhkarStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('adhkar_celebration'),
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.celebration_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                copy.setComplete,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
