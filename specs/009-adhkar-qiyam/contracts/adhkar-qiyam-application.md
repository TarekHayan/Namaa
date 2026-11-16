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

## My Adhkar ports and commands (`lib/features/adhkar/`, Story 5)

My Adhkar lives inside the Adhkar feature: it shares the Adhkar day, the clock and the counter rules, and it never imports Qiyam.

- **`MyAdhkarRepository`**:
  - `watchGroups(owner)` returns the live groups, oldest first, each with its number of live items;
  - `watchGroupItems(owner, groupId)` returns the group's live items in the order they were added to it, each with its full group set;
  - `watchCounts(owner, day)` returns that day's counts;
  - transactional group `create`, `rename` and `delete`, and item `add`, `edit`, `delete`, `increment` and `reset`.
- **`MyAdhkarIdentityPort`**: new group and item IDs (UUIDv4) and count record IDs (UUIDv5, data-model.md).
- **`CreateMyAdhkarGroup(owner, name)`**: validates the name (1–60 code points after trimming) and the 30-group limit. Returns `created(groupId)`, `groupLimitReached` or a typed validation failure.
- **`RenameMyAdhkarGroup(owner, groupId, name)`**: the same name rule. Rejects a deleted group with `groupDeleted`.
- **`DeleteMyAdhkarGroup(owner, groupId)`**: the cascade in data-model.md (FR-029), in one transaction. `previewDeleteMyAdhkarGroup(owner, groupId)` returns how many items the delete would remove, for the confirmation. Deleting an already deleted group is a no-op.
- **`AddMyDhikr(owner, draft)`**: validates the draft (text 1–1000 code points after trimming, target 1–1000, note ≤ 300, `groupIds` non-empty and all live) and the 100-item limit, then adds. Returns `added(itemId)`, `limitReached`, `groupDeleted` or a typed validation failure.
- **`EditMyDhikr(owner, itemId, capturedDay, draft)`**: the same validation, including the group set. A group kept in the set keeps its `added_at`; a new group gets the edit time. Lowering the target below today's count clamps today's count in the same transaction. Rejects a deleted item with `itemDeleted`.
- **`DeleteMyDhikr(owner, itemId)`**: sets the tombstone. Deleting an already deleted item is a no-op.
- **`IncrementMyDhikr(owner, capturedDay, itemId)`** and **`ResetMyDhikr(owner, capturedDay, itemId)`**: the same day guard as `IncrementDhikr`, with no period check and no award. They are rejected with `locked` when the schedule is unavailable, and with `itemDeleted` for a deleted item.

None of these commands calls the XP ledger.

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
  - The third tab, My Adhkar, reads `MyAdhkarRepository` through the same Cubit (or a child `MyAdhkarCubit` composed beside it). Its counts never feed the set completion, the celebration or the streak.
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
