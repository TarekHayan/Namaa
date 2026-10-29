import 'package:timezone/data/latest_all.dart' as timezone_data;

bool _initialized = false;

/// Loads the bundled full IANA database once per isolate at startup.
///
/// The package establishes its default UTC context on first initialization.
/// Composition calls this before zone consumers; Prayer subsequently resolves
/// saved cities explicitly and never sets them as the global local zone.
void initializePrayerTimeZones() {
  if (_initialized) return;
  timezone_data.initializeTimeZones();
  _initialized = true;
}
