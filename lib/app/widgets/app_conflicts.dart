import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_typography.dart';
import 'app_back_link.dart';
import 'app_card.dart';
import 'app_pill.dart';

/// When a stored version was saved, for the version cards: "Today 6:12 AM",
/// "Yesterday 9:40 PM", or the full date and time. [today] and [yesterday]
/// build the translated day words around the formatted time.
String appConflictStamp({
  required DateTime at,
  required DateTime now,
  required String locale,
  required String Function(String time) today,
  required String Function(String time) yesterday,
}) {
  final local = at.toLocal();
  final time = DateFormat.jm(locale).format(local);
  final day = DateTime(now.year, now.month, now.day);
  final savedDay = DateTime(local.year, local.month, local.day);
  final difference = day.difference(savedDay).inDays;
  if (difference == 0) return today(time);
  if (difference == 1) return yesterday(time);
  return DateFormat.yMMMd(locale).add_jm().format(local);
}

/// The read-only "Sync differences" page: a back link, the title, the entry
/// cards and a footer saying nothing can be done here. It offers no
/// resolution action; the only control returns to the page it came from.
/// Callers pass the translated texts and the already built [entries]
/// ([AppConflictEntryCard]s). [pageKey], [backKey] and [footerKey] go on the
/// scrolling list, the back link and the footer so tests can find them.
class AppConflictsPage extends StatelessWidget {
  const AppConflictsPage({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.entries,
    required this.footer,
    this.pageKey,
    this.backKey,
    this.footerKey,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final List<Widget> entries;
  final String footer;
  final Key? pageKey;
  final Key? backKey;
  final Key? footerKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final wide = AppLayout.isWide(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = wide ? 32.0 : 20.0;
            final side = math.max(
              base,
              (constraints.maxWidth - AppLayout.columnMaxWidth) / 2,
            );
            return ListView(
              key: pageKey,
              padding: EdgeInsets.fromLTRB(side, 24, side, 24),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppBackLink(
                    key: backKey,
                    label: backLabel,
                    onTap: onBack,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.fixed(
                    28,
                    FontWeight.w800,
                    colors.textPrimary,
                    height: 1.4,
                  ),
                ),
                for (final entry in entries) ...[
                  const SizedBox(height: 16),
                  entry,
                ],
                const SizedBox(height: 20),
                _Footer(key: footerKey, text: footer),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One entry of the sync differences page: its [title] and the two stored
/// versions, stacked on a phone and side by side on a wide window. [titleKey]
/// goes on the title text.
class AppConflictEntryCard extends StatelessWidget {
  const AppConflictEntryCard({
    super.key,
    required this.title,
    required this.active,
    required this.saved,
    this.titleKey,
  });

  final String title;
  final Widget active;
  final Widget saved;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final wide = AppLayout.isWide(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            key: titleKey,
            style: AppTypography.fixed(17, FontWeight.w700, colors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: active),
                const SizedBox(width: 12),
                Expanded(child: saved),
              ],
            )
          else ...[
            active,
            const SizedBox(height: 12),
            saved,
          ],
        ],
      ),
    );
  }
}

/// One stored version inside an [AppConflictEntryCard]: its label chip, when
/// it was saved ([time], optional) and the caller's content. The active
/// version is highlighted; the saved one sits on the secondary surface.
class AppConflictVersionCard extends StatelessWidget {
  const AppConflictVersionCard({
    super.key,
    required this.label,
    required this.activeVersion,
    required this.child,
    this.time,
  });

  final String label;
  final bool activeVersion;
  final String? time;

  /// The version's value: a count, a name, a text, a "deleted" mark.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      tone: activeVersion ? AppCardTone.accent : AppCardTone.secondary,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPill(
            label: label,
            tone: activeVersion ? AppPillTone.filled : AppPillTone.neutral,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          ),
          if (time != null) ...[
            const SizedBox(height: 8),
            Text(
              time!,
              style: AppTypography.fixed(
                14,
                FontWeight.w400,
                colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

final class _Footer extends StatelessWidget {
  const _Footer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
