import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

import '../../../../support/foundation_test_support.dart';

PrayerPreferences _choice(String account, String city, int revision) =>
    PrayerPreferences(
      accountId: account,
      city: PrayerCity(
        provider: 'test',
        providerCityId: city,
        name: city,
        countryCode: 'EG',
        countryName: 'Egypt',
        latitude: 30.04,
        longitude: 31.24,
        timeZoneId: 'Africa/Cairo',
      ),
      calculationMethod: 'egyptian',
      revision: revision,
      updatedAt: DateTime.utc(2026, 10, 29, 12, 0, revision),
    );

void main() {
  final key = List<int>.generate(32, (i) => i + 30);
  test(
    'confirmed city is owner-local, survives restart, and has no outbox',
    () async {
      final temp = TemporaryDatabasePath();
      final path = temp.allocate();
      var db = await FoundationDatabase.openEncrypted(path: path, key: key);
      try {
        final store = DriftPrayerPreferences(db);
        final first = _choice('owner-a', 'Cairo', 1);
        final second = _choice('owner-b', 'Giza', 1);
        expect(
          (await store.save(first, expectedRevision: null)).valueOrNull,
          first,
        );
        expect(
          (await store.save(second, expectedRevision: null)).valueOrNull,
          second,
        );
        expect((await store.read('owner-a')).valueOrNull, first);
        expect((await store.read('owner-b')).valueOrNull, second);
        expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
        await db.close();
        db = await FoundationDatabase.openEncrypted(path: path, key: key);
        expect(
          (await DriftPrayerPreferences(db).read('owner-a')).valueOrNull,
          first,
        );
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test('stale save and invalid zone preserve last confirmed choice', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    try {
      final store = DriftPrayerPreferences(db);
      final first = _choice('owner', 'Cairo', 1);
      expect(
        (await store.save(first, expectedRevision: null)).failureOrNull,
        isNull,
      );
      expect(
        (await store.save(
          _choice('owner', 'Giza', 2),
          expectedRevision: null,
        )).failureOrNull,
        isNotNull,
      );
      final invalid = PrayerPreferences(
        accountId: 'owner',
        city: first.city.copyWith(timeZoneId: 'Not/A_Time_Zone'),
        calculationMethod: 'egyptian',
        revision: 2,
        updatedAt: DateTime.utc(2026, 10, 29, 13),
      );
      expect(
        (await store.save(invalid, expectedRevision: 1)).failureOrNull,
        isNotNull,
      );
      expect((await store.read('owner')).valueOrNull, first);
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  test('different installations keep independent confirmed cities', () async {
    final firstPath = TemporaryDatabasePath();
    final secondPath = TemporaryDatabasePath();
    final firstFile = firstPath.allocate();
    final secondFile = secondPath.allocate();
    try {
      var db = await FoundationDatabase.openEncrypted(
        path: firstFile,
        key: key,
      );
      await DriftPrayerPreferences(
        db,
      ).save(_choice('owner', 'Cairo', 1), expectedRevision: null);
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: secondFile, key: key);
      await DriftPrayerPreferences(
        db,
      ).save(_choice('owner', 'Giza', 1), expectedRevision: null);
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: firstFile, key: key);
      expect(
        (await DriftPrayerPreferences(db).read('owner')).valueOrNull?.city.name,
        'Cairo',
      );
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: secondFile, key: key);
      expect(
        (await DriftPrayerPreferences(db).read('owner')).valueOrNull?.city.name,
        'Giza',
      );
      await db.close();
      final raw = latin1.decode(
        File(firstFile).readAsBytesSync(),
        allowInvalid: true,
      );
      expect(
        raw,
        isNot(contains('Cairo')),
        reason: 'saved city stays in the encrypted database',
      );
    } finally {
      firstPath.dispose();
      secondPath.dispose();
    }
  });
}
