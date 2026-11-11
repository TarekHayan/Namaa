import 'dart:math';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/qiyam_night.dart';
import '../domain/qiyam_night_record.dart';
import 'qiyam_clock_port.dart';
import 'qiyam_identity_port.dart';
import 'qiyam_night_port.dart';
import 'qiyam_repository.dart';

/// The outcomes of the SaveQiyamNight command (contracts/
/// adhkar-qiyam-application.md).
sealed class QiyamCommandOutcome {
  const QiyamCommandOutcome();
}

/// The draft was committed; [firstPerformed] is true when this commit
/// inserted the provisional `qiyam_done` award (the celebration fires only
/// once per night; awards are never revoked).
final class QiyamNightSaved extends QiyamCommandOutcome {
  const QiyamNightSaved({required this.firstPerformed});

  final bool firstPerformed;
}

/// The captured Qiyam night is no longer the current one; the UI refreshes.
final class QiyamNightChanged extends QiyamCommandOutcome {
  const QiyamNightChanged();
}

/// The Prayer schedule is unavailable: the screen stays visible but
/// recording is locked (owner decision, 2026-11-10) — never a calendar-day
/// or noon fallback.
final class QiyamRecordingLocked extends QiyamCommandOutcome {
  const QiyamRecordingLocked();
}

/// The command boundary the Cubit drives (guards included).
abstract interface class QiyamCommandRunner {
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  });
}

/// The SaveQiyamNight command. Every call samples `now` exactly once and
/// stamps the commit with it, which keeps the record inside the server's
/// `[night - 1 day, night + 2 days)` award window.
final class SaveQiyamNight implements QiyamCommandRunner {
  SaveQiyamNight({
    required String ownerId,
    required QiyamNightPort nightPort,
    required QiyamRepository repository,
    required QiyamNightCommitPort commits,
    required QiyamClockPort clock,
    required QiyamIdentityPort identity,
  }) : _ownerId = ownerId,
       _nightPort = nightPort,
       _repository = repository,
       _commits = commits,
       _clock = clock,
       _identity = identity {
    if (ownerId.trim().isEmpty) throw ArgumentError('Owner is required');
  }

  final String _ownerId;
  final QiyamNightPort _nightPort;
  final QiyamRepository _repository;
  final QiyamNightCommitPort _commits;
  final QiyamClockPort _clock;
  final QiyamIdentityPort _identity;

  @override
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  }) async {
    final now = _clock.nowUtc();
    final resolved = await _nightPort.resolve(ownerId: _ownerId, nowUtc: now);
    if (resolved.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final state = resolved.valueOrNull!;
    if (state.scheduleState == QiyamScheduleState.unavailable) {
      return const AppResult.success(QiyamRecordingLocked());
    }
    final nightDate = state.nightDate;
    if (nightDate == null) {
      throw StateError('An available or setup-required night has a date');
    }
    if (capturedNight != nightDate) {
      return const AppResult.success(QiyamNightChanged());
    }
    // The draft validation comes before any read or write; the first
    // violation is reported with its own message key.
    final violations = draft.violations();
    if (violations.isNotEmpty) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: _messageKey(violations.first),
          occurredAt: now,
        ),
      );
    }
    final priorRead = await _repository.readFresh(
      accountId: _ownerId,
      nightDate: nightDate,
    );
    if (priorRead.failureOrNull case final failure?) {
      // A storage failure is not "no row yet": writing would clobber the
      // real record.
      return AppResult.failure(failure);
    }
    final prior = priorRead.valueOrNull;
    final version = prior != null && !now.isAfter(prior.updatedAt)
        ? prior.updatedAt.add(const Duration(microseconds: 1))
        : now;
    final committed = await _commits.commit(
      QiyamSaveRequest(
        accountId: _ownerId,
        nightDate: nightDate,
        recordId: _identity.nightRecordId(nightDate),
        performed: draft.performed,
        rakahs: draft.rakahs,
        witr: draft.witr,
        startTime: draft.startTime,
        endTime: draft.endTime,
        note: draft.note,
        recordedZoneId: state.zoneId!,
        recordedOffsetMinutes: state.zoneOffsetMinutes!,
        updatedAt: version,
        operationId: _nextOperationId(),
        expectedCurrentVersion: prior?.updatedAt,
        acknowledgedBase: prior?.lastAcknowledgedUpdatedAt,
        queueForSync: true,
      ),
    );
    if (committed.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(
      QiyamNightSaved(firstPerformed: committed.valueOrNull!.awardInserted),
    );
  }

  static String _messageKey(QiyamDraftViolation violation) =>
      switch (violation) {
        QiyamDraftViolation.rakahs => 'qiyam.night.invalid_rakahs',
        QiyamDraftViolation.time => 'qiyam.night.invalid_time',
        QiyamDraftViolation.note => 'qiyam.night.note_too_long',
        QiyamDraftViolation.notPerformedDetails =>
          'qiyam.night.not_performed_details',
      };
}

String _nextOperationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String byte(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return 'qiyam-${byte(0)}${byte(1)}${byte(2)}${byte(3)}-'
      '${byte(4)}${byte(5)}-${byte(6)}${byte(7)}-'
      '${byte(8)}${byte(9)}-'
      '${byte(10)}${byte(11)}${byte(12)}${byte(13)}${byte(14)}${byte(15)}';
}
