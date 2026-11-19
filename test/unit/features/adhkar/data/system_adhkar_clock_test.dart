import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/system_adhkar_clock.dart';

void main() {
  test('the system clock samples the device time in UTC', () {
    final before = DateTime.now().toUtc();
    final sampled = const SystemAdhkarClock().nowUtc();
    final after = DateTime.now().toUtc();
    expect(sampled.isUtc, isTrue);
    expect(sampled.isBefore(before), isFalse);
    expect(sampled.isAfter(after), isFalse);
  });
}
