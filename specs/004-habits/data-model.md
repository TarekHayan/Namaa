# Habits 004 Data Model

**Scope:** design for 004, not an implemented migration. The current encrypted Foundation schema is v3; the proposed additive Habit schema is v4. See research.md and contracts/ for account and interaction behavior.

## Habit — Habits-owned metadata aggregate

| Field | Meaning and validation |
|---|---|
| id | Stable locally generated UUID; never reused. |
| accountId | Owner partition from the active Foundation session; a client payload is never cloud authorization. |
| name | Trimmed, nonblank user text. Duplicate names are allowed because identity is the ID. |
| scheduleRevisions | Nonempty ordered list of HabitScheduleRevision values. Latest active revision supplies current selected weekdays. |
| reminderMinuteOfDay | Optional local wall-clock minute 0–1439; saved preference only, not notification enablement. |
| createdAt, updatedAt | UTC instants. updatedAt is the version used by the Foundation conflict rule. |
| deletedAt | Nullable UTC tombstone. A deleted Habit and its days are hidden from active projections. |

The local key is (accountId, id). The remote key is (owner, id), with owner derived from the authenticated session. A Habit mutation and its PendingChange commit together. Metadata and schedule revisions form one versioned aggregate; competing metadata edits retain a visible losing version under the Foundation rule. Name and reminder edits do not add a schedule revision.

## HabitScheduleRevision — owned value in Habit

| Field | Meaning and validation |
|---|---|
| revisionId | Stable identity within a Habit. |
| effectiveAt | UTC instant of the user's weekday edit; supports multiple edits on one date. |
| effectiveLocalDate | YYYY-MM-DD at the acting device when edited; never rewritten after travel. |
| utcOffsetMinutes | Acting device's offset at edit, retained to interpret that local date. |
| weekdays | One or more distinct weekdays, represented canonically as Monday through Sunday. |

Creation supplies the first revision. Each weekday edit appends a revision and changes the active due state immediately. Earlier dates retain their prior effective schedule. Revisions are immutable inside a given Habit version; if competing Habit versions differ, the newest aggregate wins and the other remains a conflict record. A HabitDay completion retains its own earned-while-due evidence even when a concurrent schedule conflict changes the active metadata version.

## HabitDay — independent Habits-owned daily record

| Field | Meaning and validation |
|---|---|
| accountId, habitId, localDate | Unique identity of one Habit day; localDate is the acting device's immutable YYYY-MM-DD date. |
| completedAt | Nullable UTC instant. Null after an explicit undo; a row may remain to synchronize the undo. |
| earnedWhileDue | True only when completion was made while that local day was selected. A later schedule removal does not clear it. |
| earnedAgainstRevisionId | Revision active at completion, nullable after undo; provides evidence for same-day schedule edits. |
| recordedUtcOffsetMinutes | Acting device's offset when the latest action was recorded; does not change localDate. |
| updatedAt | UTC version instant for newest-version conflict selection. |

The local/remote unique key is (accountId or owner, habitId, localDate). A day is completed at most once in its current state; repeating completion is idempotent. Only today's localDate may be completed or undone. Completion requires the current due state. Undo may clear a completion even if a same-day schedule edit has since removed today; re-completion then requires today to be selected again. A row for an undone day remains as a versioned incomplete state so another device cannot restore a stale completion on retry. No day is created merely because it is due or missed; missed status and streak derive from revisions and completed days.

Different dates have independent versions, so two devices can complete different dates offline without replacing a whole Habit history snapshot. Two devices completing the same date converge to one row. Competing completed/undone versions of the same day use the Foundation timestamp and visible-loser conflict rule; equal timestamps remain unresolved and recoverable.

## Streak and due projections — derived, not persisted authority

1. Determine today from the viewing device's local calendar and the latest active Habit revision. A day added today is due immediately; a day removed today is no longer due.
2. For each closed local date, reconstruct whether its weekday was selected under the schedule effective for that date. A completed HabitDay with earnedWhileDue remains eligible even if a later same-day edit removed the weekday.
3. Walk eligible scheduled dates backward from today. If today is due but unfinished, leave the previously earned streak visible until today closes. A completed eligible date adds one. The first closed scheduled date without completion ends the current streak. Unscheduled dates are neutral.
4. A Habit with no eligible completions has streak zero. The calculation is scoped to one Habit ID, never shared with Tasks, XP, or another Habit.

The derived due/streak query must use the current account partition and exclude deleted Habit tombstones. A current-day completion can be undone and recalculated immediately; earlier dates are read-only in 004. Cross-device records keep their original localDate, even when another device is in a different time zone.

## Deletion, conflicts, and synchronization records

- DeleteHabit writes a versioned Habit tombstone and a pending operation. Owned HabitDay rows remain durably available for synchronization/conflict recovery but disappear from active views with their parent. There is no eager physical erasure or ID reuse.
- A newer Habit metadata edit versus its tombstone follows the approved newest-timestamp rule; the losing version remains visible. A HabitDay change racing with a deleted parent is retained as recoverable conflict evidence without silently resurrecting the parent.
- Existing Foundation PendingChanges stores stable operationId, accountId, entityType habit or habit_day, entityId, serialized version, and retry state. An operation is acknowledged only after the remote commit.
- Existing Foundation ConflictRecords retains nonwinning Habit or HabitDay payloads with owner, entity identity, timestamps, and sources. The Habit reconciler applies the winning row locally; the generic outbox conflict recorder does not do that for product entities.
- Remote operation receipts survive parent tombstones and make retry idempotent. Owner-only remote reads include active rows, tombstones, and all day pages needed for a complete inbound pass.

## Proposed local and remote structures

| Structure | Key / index purpose |
|---|---|
| HabitRecords | Primary key (accountId, habitId); indexes for account + deletedAt and account + updatedAt; revision payload stored with Habit. |
| HabitDayRecords | Primary key (accountId, habitId, localDate); indexes for account + habit + localDate and account + updatedAt. |
| public.habits | Primary key (owner, id), versioned payload and tombstone; owner-scoped RLS SELECT. |
| public.habit_days | Primary key (owner, habit_id, local_date), versioned completion payload; composite owner/habit relationship; owner-scoped RLS SELECT. |
| Habit operation receipts | Key (owner, operationId), entity kind/key, result and retained conflict metadata; no client read. |

The v3→v4 migration adds these structures without modifying Task, XP, Foundation probe, preferences, or existing account rows. Failure retains the prior encrypted database and a recoverable migration journal entry.

