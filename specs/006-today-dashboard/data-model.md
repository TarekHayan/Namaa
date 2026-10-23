# Data Model: Dashboard / Today

**Date**: 2026-10-22
**Persistence decision**: No Today business table, schema version, migration, cloud record, pending-change type or history store. All structures below are immutable in-memory projections or presentation state. Existing owner records remain encrypted and canonical.

## 1. TodayScope

| Field | Meaning / validation |
|---|---|
| mode | Closed development preview or resolved real-account mode. |
| scopeKey | Opaque comparison key, includes mode; never supplied as an arbitrary owner query from a route. |
| taskOwnerId | Tasks and linked Mind Maps owner. |
| habitOwnerId | Habits owner. |
| xpOwnerId | Shared award owner; must equal taskOwnerId in current scope. |
| generation | In-memory increasing identity revision; late events/results from old revisions are discarded. |

Relationships:

- Preview binds the existing `kTasksPreviewAccountId` to Tasks/Maps/XP and existing `kHabitsPreviewAccountId` to Habits in composition. These are one logical preview experience with two existing owner stores, not a general cross-account aggregate.
- Account mode requires every owner ID to equal the same authenticated accountId.
- Unknown/signed-out account mode has no resolved TodayScope and displays no retained business data.
- Switching mode/account clears all section values and pending feedback before a new scope is observed. No preview records are copied, migrated or deleted.

## 2. TodayCalendar

| Field | Meaning / validation |
|---|---|
| localDate | Current device-local Gregorian calendar key, YYYY-MM-DD; locale affects presentation only. |
| nowUtc | UTC instant for owner overdue queries and action validation. |
| utcOffsetMinutes | Current device offset, used for change detection and owner Habit recording. |
| dayStartUtc | Local midnight for localDate converted to UTC. |
| nextDayStartUtc | Next local calendar midnight converted independently to UTC. |
| projectionRevision | Changes when day/zone boundaries change; invalidates obsolete date-sensitive action feedback. |

Invariant: dayStartUtc <= award instant < nextDayStartUtc defines XP membership. Construct successive local calendar dates before UTC conversion; do not add a fixed 24 hours or apply today's fixed offset to historical instants. Task scheduled dates and HabitDay.localDate are existing calendar values, not instants to shift through time zones. Previously recorded Habit dates and offsets are never rewritten.

A clock instant change also refreshes overdue results even if the date is unchanged. The adapter supplies current `nowUtc` to owner overdue queries.

## 3. Owner source projections

Names describe the planned contract; exact Dart constructor syntax is left to implementation.

### TodayTaskReference

| Field | Meaning |
|---|---|
| taskId, ownerId | Existing stable Task identity, qualified by resolved Task owner. |
| title | Existing owner text. |
| scheduledLocalDate | Calendar date interpreted by Tasks, without timezone conversion. |
| scheduledMinuteOfDay | Optional saved hour/minute as 0..1439; null means untimed. |
| estimatedDurationMinutes | Existing optional estimate, unchanged. |
| isCompleted | Canonical Task state. |
| isUrgentImportant | Owner quadrant equals urgentImportant. |
| isOverdue | Owner `TaskReviewQueries.overdue` membership at current calendar/instant. |
| ownerOrder | Position in canonical Task emission, preserved as stable tie-breaker. |

Deleted Tasks are excluded by adapter and owner check. Source identity is the Task ID, never map node ID. Reference may appear in agenda and priority without being counted twice within a summary. Do First entries from other dates are navigation references; Today inline completion controls apply only to today's scheduled Task set.

### TodayHabitReference

| Field | Meaning |
|---|---|
| habitId, ownerId, name | Existing owner-qualified Habit and label. |
| localDate | Query day, must match TodayCalendar. |
| isDue | Owner schedule membership on that day. |
| isCompleted | Owner current-day completion state. |
| earnedWhileDue | Current completion evidence from HabitDay; false when no completed day. |
| currentStreak | `HabitToday.currentStreak`, never recomputed by Today. |
| ownerOrder | Owner Habit query order. |

Eligible iff nondeleted and `isDue || (isCompleted && earnedWhileDue)`. One row per habit. Complete action only when due and incomplete; undo allowed on a recorded current-day completion, including a retained completion after schedule removal. Undo of an unscheduled Habit removes its row and reduces both numerator and denominator. No negative streak, invented missed day or XP field.

The adapter needs both confirmed Habit and HabitDay snapshots. Failure of either invalidates the Habit section; it must not combine a newly loaded list with an unconfirmed/failed days list and claim a current summary.

### TodayAwardReference

| Field | Meaning |
|---|---|
| ownerId, source, sourceId | Existing ledger unique key; no new award identifier. |
| amount | Owner's nonnegative actual XP amount. |
| awardedAtUtc | Actual existing award instant; UTC required. |

Read all canonical ledger rows for xpOwnerId. Do not join to current Task existence/completion. Remote award reconciliation may change the canonical instant/amount, so recompute from the next owner emission. No reward can be inserted by this read port.

## 4. Derived daily view

### TaskSummary

- `items`: distinct nondeleted Tasks with scheduledLocalDate equal to viewed localDate, including completed.
- `eligibleCount`: items.length.
- `completedCount`: completed subset.
- `openItems` / `completedItems`: partition of items, preserving owner order.
- `percent`: nearest whole number of 100 * completedCount / eligibleCount when eligibleCount > 0; null for confirmed empty.
- Invariant: 0 <= completedCount <= eligibleCount; percent in 0..100 when defined.

### HabitSummary

- `items`: eligible TodayHabitReference values.
- Same independent count/rounding contract as TaskSummary.
- No combined percentage or overall score.
- Streak is per Habit and comes from its owner.

### Agenda

- Contains the scheduled-today Task set exactly once.
- Timed list: ascending scheduledMinuteOfDay, then ownerOrder.
- Untimed list: ownerOrder; separate labeled section.
- Completed state stays visible; estimate is display only.
- Overlap is permitted and does not mutate schedules or indicate actual activity.

### PriorityAndOverdue

- `doFirst`: first three canonical-order Tasks satisfying incomplete && urgentImportant && (scheduled today || owner-overdue).
- `overdueCount`: number of distinct owner-overdue Tasks across dates and quadrants.
- Saved scheduled date is available on every priority reference.
- Future-only Task without overdue condition cannot enter doFirst; a future Task with expired deadline can enter it.
- These subsets do not alter TaskSummary's denominator.

### DailyXpSummary

- `amount`: sum of actual award amounts in TodayCalendar's half-open interval.
- Confirmed no awards = zero XP; unavailable ledger = unknown, not zero.
- Task deletion/reopen leaves the award intact; another completion does not create another lifetime reward.
- No Habit awards, estimated XP, level, target or overall score.

## 5. SectionState<T>

One state for Tasks (including agenda/priority/overdue), one for Habits and one for XP.

| State | Value / display | Supported behavior |
|---|---|---|
| loading | No confirmed current value; localized loading label. | Initial response deadline <=10 seconds; other sections work. |
| available | Confirmed current-scope/day value. | Safe owner actions enabled where applicable. |
| empty | Confirmed successful response with no eligible items/awards. | Explain no items; Task/Habit ratio undefined, counts zero; XP zero. |
| unavailable | Failure, unexpected stream closure, or no initial usable response by deadline. | Localized retry; no numerical claim. |
| stale | Last confirmed same-scope/day value retained after failure. | Explicit outdated label + retry; unsafe actions disabled. |

A health state is distinct from command failure. If a command fails but healthy owner watches remain confirmed, keep the latest authoritative value and show action feedback without marking unrelated sources unavailable. A successfully committed owner change remains authoritative even if a later stream fails.

Subscriptions have an attempt revision. Retry cancels/replaces only that source and resets its response deadline; late emissions from old attempts are ignored. Never show old-account or old-day derived values as current stale data. Retain confirmed raw owner snapshots across day changes only when still healthy, then reproject for the new day.

## 6. ActionIntent and pending state

Fields: scope generation, projection revision, entity kind/id, expected ownerId, displayed localDate, desired completion boolean and in-flight marker. No persisted dashboard operation or reward ID.

Transitions:

1. Ready source + allowed current-day action -> pending for that item.
2. Revalidate scope/day; call the owner command with expected account/day.
3. Owner transaction rereads current entity, validates eligibility/session/day, commits state plus existing required outbox/award or fails with no write.
4. On confirmed success, existing local watches update the projection; feedback is shown only for the still-current generation.
5. On failure, preserve latest confirmed owner state, show localized recovery and release pending marker.
6. Day/identity change invalidates pending presentation feedback. Never convert an old-day intent into a new-day mutation automatically.

Per-item commands are serialized/coalesced so rapid duplicate taps do not enqueue stale toggles. Commands express desired state; no optimistic second XP or habit history. Account/date changes after the owner's validation/commit do not roll back a valid historical operation; only its obsolete UI callback is ignored.

## 7. Existing persistence and bounded owner changes

No new stored entity is needed. Add optional expected-day command parameters and injectable calendar readers in owning application services. Use TaskRepository.runInTransaction for fresh read -> checks -> existing completion UoW. Add equivalent rollback-on-failure transaction capability to HabitRepository and DriftHabitRepository; guard complete/undo with fresh parent/day reads and existing schedule/history rules.

All concrete transaction work uses the same FoundationDatabase instance. On a rejected guard, no Task/HabitDay/XP/pending row may be written. Existing all-date Task actions, retained Habit completions, idempotent awards, encrypted storage, remote protocols and conflict records retain their contracts.
