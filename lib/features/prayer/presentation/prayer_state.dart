import '../domain/prayer_day_snapshot.dart';
import '../domain/prayer_name.dart';

enum PrayerActionPhase { idle, saving, saved, failed }

final class PrayerState {
  const PrayerState({
    this.snapshot,
    this.failed = false,
    this.actions = const {},
  });

  final PrayerDaySnapshot? snapshot;
  final bool failed;
  final Map<PrayerName, PrayerActionPhase> actions;

  PrayerState copyWith({
    PrayerDaySnapshot? snapshot,
    bool? failed,
    Map<PrayerName, PrayerActionPhase>? actions,
  }) => PrayerState(
    snapshot: snapshot ?? this.snapshot,
    failed: failed ?? this.failed,
    actions: actions ?? this.actions,
  );
}
