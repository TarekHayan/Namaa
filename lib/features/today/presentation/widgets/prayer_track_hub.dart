import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

import '../../domain/today_adhkar_qiyam_reference.dart';
import '../today_adhkar_qiyam_display.dart';

class PrayerTrackHub extends StatefulWidget {
  const PrayerTrackHub({
    super.key,
    required this.onPrayer,
    this.onAdhkar,
    this.onQiyam,
    this.watchAdhkarQiyam,
  });
  final VoidCallback onPrayer;

  /// Opens the real Adhkar screen; null keeps the tile "coming soon".
  final VoidCallback? onAdhkar;

  /// Opens the real Qiyam screen; null keeps the tile "coming soon".
  final VoidCallback? onQiyam;

  /// Starts the live Adhkar/Qiyam values for the tile subtitles. The hub
  /// owns the subscription; a slow or failed source only leaves the
  /// subtitles out and never blocks the tiles.
  final Stream<TodayAdhkarQiyamReference> Function()? watchAdhkarQiyam;

  @override
  State<PrayerTrackHub> createState() => _PrayerTrackHubState();
}

class _PrayerTrackHubState extends State<PrayerTrackHub> {
  StreamSubscription<TodayAdhkarQiyamReference>? _subscription;
  TodayAdhkarQiyamReference? _live;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    try {
      _subscription = widget.watchAdhkarQiyam?.call().listen(
        (value) {
          if (mounted) setState(() => _live = value);
        },
        onError: (_, _) {
          if (mounted) setState(() => _live = null);
        },
      );
    } catch (_) {
      _live = null;
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  /// The tile's action: Prayer (0) and, once wired, Adhkar (3) and Qiyam (4)
  /// open their screens; the rest stay "coming soon".
  VoidCallback? _open(int index) => switch (index) {
    0 => widget.onPrayer,
    3 => widget.onAdhkar,
    4 => widget.onQiyam,
    _ => null,
  };

  /// The live subtitle of an active tile; null leaves the tile without one.
  String? _subtitle(int index, FoundationLocalizations copy, String locale) {
    final live = _live;
    if (live == null) return null;
    if (index == 3 && todayAdhkarReadable(live)) {
      return copy.dashboardTrackAdhkarSubtitle(
        todayRatio(live.morningCompleted, live.morningTotal),
        todayRatio(live.eveningCompleted, live.eveningTotal),
      );
    }
    if (index == 4 && todayQiyamReadable(live)) {
      if (live.tonight == TodayQiyamTonight.yes ||
          live.tonight == TodayQiyamTonight.no) {
        return copy.dashboardTrackQiyamRecorded;
      }
      final lastThird = todayLastThirdText(live, locale);
      return lastThird == null ? null : copy.qiyamLastThird(lastThird);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final entries = [
      (copy.dashboardComingSoonPrayerTitle, Icons.schedule_rounded),
      (copy.dashboardComingSoonFocusTitle, Icons.timer_outlined),
      (copy.dashboardComingSoonQuranTitle, Icons.menu_book_outlined),
      (copy.dashboardComingSoonAdhkarTitle, Icons.self_improvement_outlined),
      (copy.dashboardComingSoonQiyamTitle, Icons.nights_stay_outlined),
    ];
    final subtitles = [
      for (var i = 0; i < entries.length; i++) _subtitle(i, copy, locale),
    ];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // A tab page: the navigation bar is the way out.
              Text(
                copy.dashboardTrack,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < entries.length; i++)
                Card(
                  child: ListTile(
                    key: Key('prayer_track_$i'),
                    leading: Icon(entries[i].$2),
                    title: Text(entries[i].$1),
                    subtitle: _open(i) == null
                        ? Text(copy.dashboardComingSoon)
                        : subtitles[i] == null
                        ? null
                        : Text(
                            subtitles[i]!,
                            key: Key('prayer_track_subtitle_$i'),
                          ),
                    trailing: _open(i) == null
                        ? const Icon(Icons.lock_clock_outlined)
                        : const Icon(Icons.chevron_right),
                    onTap: _open(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
