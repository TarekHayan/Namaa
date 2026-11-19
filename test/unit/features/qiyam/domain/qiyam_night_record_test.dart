import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';

/// T038: the Qiyam field rules (fixed implementation facts): rak'ahs only
/// from {2, 4, 8, 11} when performed, optional `HH:mm` times (an end time
/// before the start time crosses midnight and is accepted), a note of at
/// most 500 characters, and every detail cleared when not performed.
void main() {
  const performed = QiyamNightDraft(
    performed: true,
    rakahs: 4,
    witr: true,
    startTime: '22:10',
    endTime: '02:40',
    note: 'test note',
  );

  test('a performed draft with valid details has no violations', () {
    expect(performed.violations(), isEmpty);
  });

  test(
    'rak\'ahs must be one of 2, 4, 8 or 11 and never null when performed',
    () {
      for (final rakahs in QiyamNightDraft.allowedRakahs) {
        expect(
          QiyamNightDraft(performed: true, rakahs: rakahs).violations(),
          isEmpty,
          reason: '$rakahs is allowed',
        );
      }
      for (final rakahs in const [1, 3, 5, 0, 12]) {
        expect(
          QiyamNightDraft(performed: true, rakahs: rakahs).violations(),
          contains(QiyamDraftViolation.rakahs),
        );
      }
      expect(
        const QiyamNightDraft(performed: true).violations(),
        contains(QiyamDraftViolation.rakahs),
      );
    },
  );

  test('times are optional `HH:mm` values; an end before the start crosses '
      'midnight and is accepted', () {
    expect(
      const QiyamNightDraft(
        performed: true,
        rakahs: 4,
        startTime: '23:50',
        endTime: '01:10',
      ).violations(),
      isEmpty,
      reason: 'the prayer can run past 00:00',
    );
    expect(
      const QiyamNightDraft(
        performed: true,
        rakahs: 4,
        startTime: '24:00',
      ).violations(),
      contains(QiyamDraftViolation.time),
    );
    expect(
      const QiyamNightDraft(
        performed: true,
        rakahs: 4,
        endTime: '9:30',
      ).violations(),
      contains(QiyamDraftViolation.time),
    );
    expect(
      const QiyamNightDraft(
        performed: true,
        rakahs: 4,
        endTime: '01:60',
      ).violations(),
      contains(QiyamDraftViolation.time),
    );
  });

  test('the note is limited to 500 characters', () {
    expect(
      QiyamNightDraft(
        performed: true,
        rakahs: 4,
        note: 'a' * QiyamNightDraft.maxNoteLength,
      ).violations(),
      isEmpty,
    );
    expect(
      QiyamNightDraft(
        performed: true,
        rakahs: 4,
        note: 'a' * (QiyamNightDraft.maxNoteLength + 1),
      ).violations(),
      contains(QiyamDraftViolation.note),
    );
  });

  test('a draft that is not performed must carry no details', () {
    expect(QiyamNightDraft.notPerformed.violations(), isEmpty);
    expect(
      const QiyamNightDraft(
        performed: false,
        rakahs: 4,
        witr: true,
        startTime: '22:10',
        endTime: '02:40',
        note: 'test note',
      ).violations(),
      contains(QiyamDraftViolation.notPerformedDetails),
    );
  });

  QiyamNightRecord record({
    bool performed = true,
    int? rakahs = 4,
    bool witr = true,
    String? startTime = '22:10',
    String? endTime = '02:40',
    String? note = 'test note',
  }) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: '2026-11-11',
    recordId: 'rec',
    performed: performed,
    rakahs: rakahs,
    witr: witr,
    startTime: startTime,
    endTime: endTime,
    note: note,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: DateTime.utc(2026, 11, 11, 20),
    updatedAt: DateTime.utc(2026, 11, 11, 20, 5),
    lastAcknowledgedUpdatedAt: null,
  );

  test('a valid record constructs', () {
    expect(record(), isA<QiyamNightRecord>());
    expect(
      record(
        performed: false,
        rakahs: null,
        witr: false,
        startTime: null,
        endTime: null,
        note: null,
      ),
      isA<QiyamNightRecord>(),
    );
  });

  test('a record with invalid details throws', () {
    expect(
      () => record(rakahs: 3),
      throwsArgumentError,
      reason: 'rak\'ahs outside the approved set',
    );
    expect(
      () => record(startTime: '25:00'),
      throwsArgumentError,
      reason: 'an invalid `HH:mm` start',
    );
    expect(
      () => record(note: 'a' * 501),
      throwsArgumentError,
      reason: 'a note above 500 characters',
    );
    expect(
      () => record(performed: false, rakahs: null, note: 'leftover'),
      throwsArgumentError,
      reason: 'details left over on an explicit No',
    );
  });
}
