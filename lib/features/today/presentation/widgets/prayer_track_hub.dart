import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

class PrayerTrackHub extends StatelessWidget {
  const PrayerTrackHub({super.key, required this.onPrayer});
  final VoidCallback onPrayer;

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
                    subtitle: i == 0 ? null : Text(copy.dashboardComingSoon),
                    trailing: i == 0
                        ? const Icon(Icons.chevron_right)
                        : const Icon(Icons.lock_clock_outlined),
                    onTap: i == 0 ? onPrayer : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
