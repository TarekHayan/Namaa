# Contract: Today Owner Integration

**Scope**: FR-002 through FR-015 and FR-019. New port names below are planned interfaces.

## 1. Dependency boundary

- Today domain/application use their own DTOs/ports and infrastructure-free result/failure types.
- Three named adapters under features/today/data may import the relevant owner's application/domain contracts, never owner presentation, data implementations, Drift, Supabase or tables.
- App composition supplies existing repositories, services, sessions and navigation.
- Only owners persist changes. Today never inserts awards, directly commits Tasks/Habits or starts its own cloud query.
- Add an architecture scanner covering imports, relative-import bypasses and direct-storage access.

## 2. Scope

| Mode | Tasks/Maps/XP owner | Habit owner |
|---|---|---|
| Development preview | Existing kTasksPreviewAccountId | Existing kHabitsPreviewAccountId |
| Real account | Resolved authenticated accountId | Same authenticated accountId |
| Unknown/signed-out account mode | None | None |

Preview bindings are fixed in composition and use existing preview sessions. Preserve both stores without migration/copying/deletion. Do not accept arbitrary owner IDs from routes or enable cross-account aggregation in account mode. Every command receives its own source's bound owner ID.

## 3. TodayTasksPort

**Read:** Observe TaskRepository.watchTasks for the bound owner; exclude deleted/foreign rows, map to TodayTaskReference, and preserve owner sequence. Current Drift ordering is scheduled date, creation time, then Task ID.

At each clock update, obtain overdue membership through TaskReviewQueries.overdue using current local calendar date and UTC now. Task summary includes all scheduled-today Tasks, including completed; do not reuse TaskRules.today's open-only filter. Do First uses urgentImportant only, not TaskRules.urgent. Agenda/priority/overdue derive from the same snapshot and clock.

**Write:** Submit taskId, expected Task owner, displayed localDate and desired completion. Inline controls apply only to scheduled-today Tasks; other-date priority references navigate to Tasks. Invoke TaskCompletionService.completeTask/reopenTask with the expected-day guard below. Existing completion UoW owns Task/award/outbox atomicity. After local success invoke existing owner synchronization without waiting for connectivity; sync failure does not undo or misreport the local commit.

## 4. TodayHabitsPort

**Read:** Observe HabitRepository.watchHabits and watchDays for the bound Habit owner. Require a usable response from both; either failure/closure invalidates this source. Run HabitQueries.today for the current date and retain:

`isDue || (isCompleted && day.earnedWhileDue)`

Preserve owner order, completion and currentStreak. Never calculate a second streak.

**Write:** Submit habitId, expected Habit owner, displayed localDate and desired completion to HabitCommands.completeHabitToday/undoHabitToday with expected-day protection:

- Complete only a due current-day incomplete Habit.
- Undo a recorded current-day completion, including retained completion after schedule removal.
- Undo of an unscheduled retained completion removes eligibility and the row.
- No past-day editing, new unscheduled completion or Habit XP.
- Invoke existing owner sync after a successful local save without blocking on network.

## 5. TodayXpPort

Observe existing AwardLedgerPort.watchAwards for the bound XP owner. Expose existing unique keys, actual amounts and UTC award instants. Sum within current device-local day boundaries; do not infer XP from Task status/schedule or filter through current Task existence.

No new XP read API, aggregate table, write method, award type, level, daily target or cloud endpoint is needed. Ledger failure is independent of Task source health. A Task action can still use its owner's atomic award path while the XP display is unavailable; never invent the missing total.

## 6. Bounded owner-command hardening

Current owner reads/checks do not fully close async day and deletion races. Implement these changes before enabling Today actions.

### Tasks

1. Add optional expectedLocalDate plus an injectable current-local-date reader to TaskCompletionService. Existing callers omitting the date restriction remain all-date capable.
2. Use TaskRepository.runInTransaction around fresh Task read, checks and existing TaskCompletionUnitOfWork commit on the same FoundationDatabase.
3. Validate expected account, nondeleted entity and, for Today calls, both current device day and fresh Task scheduled date equal expectedLocalDate.
4. Recheck session and clock after awaited reads/checks immediately before writing. Concurrent owner edit/reschedule/delete cannot interleave between the authoritative transactional read and write.
5. Repeated desired state is a no-op only after identity/day/existence/eligibility checks.
6. Preserve one lifetime award; failure rolls back Task, award and outbox together.

### Habits

1. Add optional expectedLocalDate to completeHabitToday/undoHabitToday, using existing injectable HabitCalendar.
2. Add HabitRepository.runInTransaction, implemented by DriftHabitRepository with rollback on failed AppResult, matching the existing Tasks pattern.
3. Transactionally reread current parent Habit and day; reject absent/deleted parent, require current schedule eligibility for new completion, allow retained-completion undo.
4. Validate displayed date at entry and recheck current calendar after awaited reads/session checks immediately before writing. Even callers omitting expectedLocalDate must reject a captured day that changes during the operation.
5. Build changes from fresh transactional versions; do not overwrite a concurrent completion/undo with an old day aggregate.
6. Preserve same-date idempotence, recorded localDate/offset, schedule evidence, owner streak and day+outbox atomicity. Rejected guards write nothing.

The final check before the owner write is its validation point. A valid committed operation is not reversed when the screen later changes day/account; only obsolete presentation callbacks are ignored. Do not put cloud work inside local transactions.

### Presentation behavior

- Use desired state; serialize/coalesce per owner/entity. Duplicate taps must not enqueue stale inversions.
- Show success only after confirmed local owner persistence. Healthy owner streams remain the display authority.
- Failure preserves the latest confirmed state, including legitimate concurrent changes; do not roll back to an older UI snapshot.
- Refresh/rebuild/locale/theme/subscription retry creates no business writes.
- Never automatically replay a write after an observer timeout or ambiguous command outcome. Read confirmed owner state, keep pending/uncertain feedback until resolution and retry through existing idempotent owner behavior.

## 7. Existing sync/security

Owner commits keep encrypted data, atomic pending records, credential protection and existing conflict/reconciliation rules. Today observes resulting local changes; it adds no cloud polling, Realtime subscription, outbox entity or conflict history. Remote canonical award reconciliation can change the daily projection and must be observed.

Account loss clears the view without deleting stored records. Two-device verification uses an existing isolated real test account/session; development preview is deliberately local and not a cloud synchronization identity.

## 8. Required proofs

- Correct bindings and zero foreign values across account/mode changes, delayed emissions/results.
- Complete denominator; stable agenda/priority/overdue; map-linked Task once.
- Retained Habit completion/undo and owner streak equality.
- Actual award boundaries, deleted/reopened Task awards and remote reconciliation.
- Midnight/account changes during awaited commands; concurrent delete/edit/schedule/day changes; rapid taps.
- Zero writes on failed guards and ten read-only refreshes.
- Regress existing Tasks/Habits/linked Maps commands and one-time XP with no Habit awards.
