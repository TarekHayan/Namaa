import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/prayer_payload_codec.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/prayer/domain/prayer_version_policy.dart';

void main() {
  test('equal UTC versions converge regardless of arrival order', () {
    final vector =
        jsonDecode(
              File(
                'test/fixtures/prayer/conflict_vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final version = DateTime.fromMicrosecondsSinceEpoch(
      vector['versionMicros'] as int,
      isUtc: true,
    );
    final first = PrayerVersionDescriptor(
      updatedAt: version,
      status: 'completed_late',
      completionAt: version,
      zoneId: 'Africa/Cairo',
      offsetMinutes: 120,
    );
    final second = PrayerVersionDescriptor(
      updatedAt: version,
      status: 'missed',
      completionAt: null,
      zoneId: 'Africa/Cairo',
      offsetMinutes: 120,
    );
    expect(
      first.semanticKey,
      'completed_late|1793264400000000|Africa/Cairo|120',
    );
    expect(second.semanticKey, 'missed|null|Africa/Cairo|120');
    expect(PrayerVersionPolicy.choose(first, second), second);
    expect(PrayerVersionPolicy.choose(second, first), second);
    final adapter = UuidPrayerReportIdentity();
    expect(
      adapter.conflictNameId(
        PrayerVersionPolicy.conflictName(
          vector['reportId'] as String,
          first,
          second,
        ),
      ),
      vector['conflictId'],
    );
    expect(
      adapter.conflictNameId(
        PrayerVersionPolicy.conflictName(
          vector['reportId'] as String,
          second,
          first,
        ),
      ),
      vector['conflictId'],
    );
  });
  test(
    'payload contains only semantic fields, never XP or local settlement',
    () {
      final report = PrayerReport(
        accountId: 'owner',
        reportId: 'stable',
        date: PrayerLocalDate.parse('2026-10-29'),
        name: PrayerName.fajr,
        status: PrayerStatus.completedLate,
        reportedCompletionAt: DateTime.utc(2026, 10, 29, 10, 1, 2, 3, 4),
        recordedZoneId: 'Africa/Cairo',
        recordedOffsetMinutes: 120,
        createdAt: DateTime.utc(2026, 10, 29),
        updatedAt: DateTime.utc(2026, 10, 29, 10, 1, 2, 3, 5),
        canonicalRewardConfirmedAt: DateTime.utc(2026, 10, 29, 11),
      );
      final encoded = const PrayerPayloadCodec().encode(report);
      expect(
        encoded.keys,
        containsAll([
          'localDate',
          'prayerName',
          'status',
          'reportedCompletionAt',
          'recordedZoneId',
          'recordedOffsetMinutes',
          'updatedAt',
        ]),
      );
      expect(encoded.keys, hasLength(7));
      expect(encoded['updatedAt'], '2026-10-29T10:01:02.003005Z');
      expect(encoded.toString(), isNot(contains('XP')));
      expect(encoded.toString(), isNot(contains('_syncBaseUpdatedAt')));
      expect(encoded.toString(), isNot(contains('canonicalRewardConfirmedAt')));
    },
  );
}
