import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/prayer_timezone_initializer.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('full offline IANA initialization runs only once per isolate', () {
    initializePrayerTimeZones();
    final originalLocal = tz.local;
    expect(identical(originalLocal, tz.UTC), isTrue);
    final cairo = tz.getLocation('Africa/Cairo');
    final newYork = tz.getLocation('America/New_York');
    expect(cairo.name, 'Africa/Cairo');
    expect(tz.getLocation('Asia/Dubai').name, 'Asia/Dubai');

    // A repeated call must not reset the shared database or another caller's
    // local-zone choice. This test restores the caller's choice afterwards.
    tz.setLocalLocation(newYork);
    try {
      initializePrayerTimeZones();
      expect(identical(tz.local, newYork), isTrue);
      expect(identical(tz.getLocation('Africa/Cairo'), cairo), isTrue);
    } finally {
      tz.setLocalLocation(originalLocal);
    }
  });
}
