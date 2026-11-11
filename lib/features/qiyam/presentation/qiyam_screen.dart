import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'qiyam_cubit.dart';
import 'widgets/qiyam_header.dart';
import 'widgets/qiyam_history_section.dart';
import 'widgets/qiyam_supplications_card.dart';
import 'widgets/qiyam_tracker_card.dart';

/// The Qiyam screen (contracts/adhkar-qiyam-ui.md): the prototype's order —
/// the heading with the last-third and streak chips, the tracker card with
/// the Yes/No answer and the details form, the supplications, then the
/// history section. An unavailable schedule keeps the screen visible but
/// recording locked (owner decision, 2026-11-10); the +30 XP celebration is
/// one-shot per night. On desktop (≥ 1024 px) the history sits in a side
/// column.
final class QiyamScreen extends StatelessWidget {
  const QiyamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<QiyamCubit>();
    final state = cubit.state;
    final copy = QiyamStrings(FoundationLocalizations.of(context));
    final locale = FoundationLocalizations.of(context).localeName;

    final history = QiyamHistorySection(
      copy: copy,
      locale: locale,
      entries: state.history,
      loading: state.historyLoading,
      failed: state.historyFailed,
      complete: state.historyComplete,
      onLoadMore: cubit.loadMoreHistory,
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1024;
            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QiyamHeader(
                  copy: copy,
                  night: state.night,
                  locale: locale,
                  locked: state.recordingLocked,
                  streak: state.streak,
                  streakFailed: state.streakFailed,
                ),
                const SizedBox(height: 12),
                QiyamTrackerCard(
                  copy: copy,
                  night: state.night,
                  record: state.record,
                  form: state.form,
                  status: state.actionStatus,
                  failureMessageKey: state.failureMessageKey,
                  onYes: cubit.answerYes,
                  onNo: cubit.answerNo,
                  onRakahs: cubit.selectRakahs,
                  onWitr: cubit.toggleWitr,
                  onTimes: cubit.updateTimes,
                  onNote: cubit.updateNote,
                ),
                const SizedBox(height: 12),
                if (state.celebration)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CelebrationBanner(copy: copy),
                  ),
                QiyamSupplicationsCard(
                  copy: copy,
                  supplications: state.supplications,
                  locale: locale,
                ),
              ],
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainColumn),
                        const SizedBox(width: 16),
                        SizedBox(width: 380, child: history),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        mainColumn,
                        const SizedBox(height: 12),
                        history,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

final class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({required this.copy});

  final QiyamStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('qiyam_celebration'),
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
                copy.xpEarned,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
