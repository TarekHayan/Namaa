import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';

void main() {
  test('UUIDv5 vectors match for five prayers and leap date', () {
    final vectors =
        (jsonDecode(
                  File(
                    'test/fixtures/prayer/identity_vectors.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final identity = UuidPrayerReportIdentity();
    for (final vector in vectors) {
      final date = PrayerLocalDate.parse(vector['date'] as String);
      final name = PrayerName.values.byName(vector['prayer'] as String);
      expect(identity.reportId(date, name), vector['id']);
    }
    expect(
      'owner-a/${identity.reportId(PrayerLocalDate.parse('2026-10-29'), PrayerName.fajr)}',
      isNot(
        'owner-b/${identity.reportId(PrayerLocalDate.parse('2026-10-29'), PrayerName.fajr)}',
      ),
    );
  });
}
