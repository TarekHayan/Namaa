# Adhkar and Qiyam application contract

References: [data-model](../data-model.md), [research](../research.md). All names are planned.

## Prayer → read port (new, owned by Prayer)

`PrayerDayBoundaries` (in `lib/features/prayer/application/`):

```text
Future<DayBoundariesResult> boundaries(ownerId, civilDate)
  -> available(date, fajrUtc, maghribUtc, nextFajrUtc, zoneId)
   | setupRequired | unavailable(reason)
Stream<void> changes(ownerId)   // the saved location or method changed
```

- **Data source.** It reads only the encrypted annual timetable, falling back to the local calculator under 008's rules. It makes no network call per request.
- **Missing times.** If any of the three instants cannot be computed (for example, at high latitude), the result is `unavailable`. It never substitutes a guessed time.

## Adhkar ports and commands (`lib/features/adhkar/`)

- **`AdhkarTimesPort`**: implemented in composition by a `PrayerDayBoundaries` adapter. It returns the `AdhkarClockState` for `now`.
- **`AdhkarCatalogPort`**: the validated catalog for a given version, and the current version.
- **`AdhkarRepository`**:
  - `watchDay(owner, day)` returns the counts for that day;
  - `streak(owner, today)`;
  - transactional `increment` and `reset`.
- **`IncrementDhikr(owner, capturedDay, itemId)`**:
  1. Sample `now` once.
  2. Re-resolve the clock.
  3. Reject the command with `dayChanged` if `capturedDay` is no longer the current Adhkar day.
  4. Reject it with `outsidePeriod(startsAt)` if the item's list is not countable now.
  5. Otherwise, run the increment transaction.

  The command returns `incremented(newCount, setCompleted)`, `atTarget` (a no-op), or a typed failure.
- **`ResetDhikr(owner, capturedDay, itemId)`**: the same day guard, but it is allowed outside the period, so an accidental count can still be fixed. It writes 0.

## Qiyam ports and commands (`lib/features/qiyam/`)

- **`QiyamNightPort`**: implemented in composition by a `PrayerDayBoundaries` adapter. It returns the current night date, the last-third instant from `PrayerScheduleProjection.from(today: D, tomorrow: D+1)`, and the availability.
- **`QiyamRepository`**:
  - `watchNight(owner, nightDate)`;
  - `history(owner, before, limit = 30)`;
  - `streak(owner, currentNight)`;
  - a transactional `save`.
- **`SaveQiyamNight(owner, capturedNight, draft)`**:
  1. Re-resolve the current night.
  2. Reject the command with `nightChanged` if it is not `capturedNight`.
  3. Validate the draft:
     - when performed, rakahs must be in {2, 4, 8, 11}, times must be valid `HH:mm` values or null, and the note must be ≤ 500 characters;
     - when not performed, the detail fields must be empty.
  4. Run the save transaction.

  The command returns `saved(firstPerformed: bool)` or a typed failure. No other command can write to a previous night.

## Cubits and lifecycle

- **`AdhkarCubit(owner)`**:
  - It loads the catalog, the clock and the day counts, and selects the tab for the current period.
  - It schedules one timer for `nextBoundary`, and re-resolves the clock on resume and on Prayer `changes`.
  - A completed set emits a one-shot celebration event.
  - Results from an earlier owner generation are discarded.
- **`QiyamCubit(owner)`**:
  - It loads the night, the record, the streak and the first history page.
  - It re-resolves the night at the next Maghrib, on resume and on Prayer `changes`.
  - Edits are saved through the command. The note input is debounced by 400 ms, and pending text is flushed when the screen is left.
- **Per-action state.** Each action has `pending`, `saved` or `failed` feedback, and stale results cannot cross an owner change.

## Today bridge

- **`TodayAdhkarQiyamPort.watch(owner)`**: returns `TodayAdhkarQiyamReference` (see the data model).
- **Implementation.** It is implemented in `lib/features/today/data/adhkar_qiyam_today_adapter.dart` through Adhkar and Qiyam application APIs only. Today presentation never imports Adhkar or Qiyam data code.

## Preview and owner boundaries

- **Debug preview owner.** It uses the same commands with local-only persistence and awards, and nothing is uploaded, as in 008.
- **Changing the account** closes the old Cubits and opens new ones, so no record from the previous owner is shown.
