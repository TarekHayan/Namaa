import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

class PrayerTrackHub extends StatelessWidget {
  const PrayerTrackHub({
    super.key,
    required this.onPrayer,
    this.onAdhkar,
    this.onQiyam,
  });
  final VoidCallback onPrayer;

  /// Opens the real Adhkar screen; null keeps the tile "coming soon".
  final VoidCallback? onAdhkar;

  /// Opens the real Qiyam screen; null keeps the tile "coming soon".
  final VoidCallback? onQiyam;

  /// The tile's action: Prayer (0) and, once wired, Adhkar (3) and Qiyam (4)
  /// open their screens; the rest stay "coming soon".
  VoidCallback? _open(int index) => switch (index) {
    0 => onPrayer,
    3 => onAdhkar,
    4 => onQiyam,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final entries = [
      (copy.dashboardComingSoonPrayerTitle, Icons.schedule_rounded),
      (copy.dashboardComingSoonFocusTitle, Icons.timer_outlined),
      (copy.dashboardComingSoonQuranTitle, Icons.menu_book_outlined),
      (copy.dashboardComingSoonAdhkarTitle, Icons.self_improvement_outlined),
      (copy.dashboardComingSoonQiyamTitle, Icons.nights_stay_outlined),
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
                        : null,
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
