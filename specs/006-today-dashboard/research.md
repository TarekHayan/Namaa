# Research: Dashboard / Today

**Date**: 2026-10-22
**Input**: spec.md with both approved clarifications; Constitution v2.0.1; current owner implementations. Research is repository-based; no package upgrade or external service is selected.

## 1. Derived feature and explicit owner bridges

**Decision:** Add `features/today` with pure projection models/rules, application ports, owner adapters and a Cubit. Three narrow ports supply Tasks, Habits and actual XP; composition resolves identity and navigation. Today has no database table, migration, outbox entity, cloud endpoint or independent sync loop.

**Rationale:** Existing `TaskRepository.watchTasks`, `HabitRepository.watchHabits/watchDays` and `AwardLedgerPort.watchAwards` already provide local observable authorities. Owner writes and inbound synchronization invalidate those streams. `test/architecture/domain_dependency_test.dart` requires infrastructure-free domain/application. The Mind Maps Task bridge demonstrates an existing explicit cross-feature adapter pattern.

**Alternatives considered:** Reading Drift in widgets bypasses ownership; subscribing to TasksCubit/HabitsCubit couples screens and inherits their filters; a persisted dashboard snapshot duplicates business truth; a new event bus or reactive package is unnecessary. Use stock Dart stream subscriptions and existing flutter_bloc.

**Sources:** `lib/features/tasks/application/task_repository.dart`; `lib/features/habits/application/habit_repository.dart`; `lib/features/xp/application/award_ledger.dart`; `lib/features/mind_maps/data/tasks_map_link_adapter.dart`.

## 2. Task membership, agenda, priority and overdue

**Decision:** The Task adapter consumes the full owner stream, removes tombstones and retains owner sequence. Today selects all Tasks scheduled on the viewed date, including completed Tasks. Agenda sorts timed entries by saved minute, breaking ties by owner sequence, and presents untimed Tasks separately. Do First filters incomplete urgentImportant Tasks that are scheduled today OR appear in `TaskReviewQueries.overdue`, then takes the first three in owner sequence. Overdue count uses that same owner query across dates.

**Rationale:** `TaskRules.today` excludes completed Tasks, so cannot supply the denominator. `TaskRules.urgent` includes urgentNotImportant, so cannot supply Do First. `TaskReviewQueries.overdue` considers past scheduled calendar date OR passed target deadline; a future schedule with a past deadline is therefore eligible for priority but excluded from today's denominator. Elapsed saved time/duration alone is not overdue.

**Alternatives considered:** Reusing these similarly named filters unmodified gives incorrect counts; porting the prototype's all-date priority list contradicts the clarification; inventing 10:00 for untimed Tasks or auto-rescheduling overlaps changes owner behavior. Do not sort priority independently or count map nodes as Tasks.

**Sources:** `lib/features/tasks/domain/task_rules.dart`; `lib/features/tasks/application/task_review_queries.dart`; `lib/features/tasks/data/drift_task_repository.dart`.

## 3. Habit eligibility and streak authority

**Decision:** Run `HabitQueries.today` on the account's confirmed habit/day lists and current local date, then retain `isDue || (isCompleted && day.earnedWhileDue)`. Use the returned `currentStreak` unchanged. Treat the two Habit streams as one source section; do not declare it ready until both have emitted successfully.

**Rationale:** The existing query explicitly supports future Dashboard consumers but returns unscheduled Habits as well. Its history/streak logic already preserves earned completion after weekday removal, neutral unscheduled days and an unfinished current day. Undo of an unscheduled retained completion removes eligibility immediately.

**Alternatives considered:** Filtering due only loses a valid completion; displaying all query rows invents missed obligations; deriving a new streak creates a second authority.

**Sources:** `lib/features/habits/application/habit_queries.dart`; `lib/features/habits/domain/habit_day.dart`; `lib/features/habits/domain/habit_streak_rules.dart`.

## 4. Actual XP needs no new query or reward implementation

**Decision:** Adapt existing `AwardLedgerPort.watchAwards(accountId)`. Sum actual award amounts whose UTC instants fall in the viewing device's local day's half-open UTC interval. Include awards for deleted Tasks; reopening or recompletion never invents another award. A successful empty ledger yields zero XP; missing or failed data yields unavailable.

**Rationale:** `DriftAwardLedger` already watches the encrypted XP table and the owner completion unit of work atomically writes Task state, first award and outbox. Existing unique keys and remote reconciliation govern award identity. There is no missing daily-XP storage capability.

**Alternatives considered:** Completed Task count multiplied by XP, a second ledger, filtering awards through current Task existence, new Habit rewards, levels or daily targets are incorrect or outside scope. A custom aggregate SQL/index is unjustified at the specified 200-award fixture.

**Sources:** `lib/features/xp/application/award_ledger.dart`; `lib/features/xp/data/drift_award_ledger.dart`; `lib/features/tasks/application/task_completion_unit_of_work.dart`; `lib/features/tasks/application/task_completion_service.dart`.

## 5. Existing preview data uses two owner identifiers

**Decision:** Resolve a closed, composition-owned TodayScope. In development preview map Tasks/Mind Maps/XP to the existing `kTasksPreviewAccountId` and Habits to `kHabitsPreviewAccountId`; preserve both stores unchanged. In real-account mode all source owners must equal the same authenticated account. Never accept arbitrary owner IDs from route parameters or UI.

**Rationale:** `tasks_preview_adapters.dart` and `habits_preview_adapters.dart` currently use distinct durable preview identities and sessions. Treating one raw accountId as the whole preview scope would hide existing Habits or require unnecessary migration. A logical preview scope with explicit owner bindings preserves the user's trial data without weakening real-account isolation.

**Alternatives considered:** Migrating or deleting trial records is unnecessary; globally merging accounts is unsafe; making all owners use the Tasks session immediately would make existing Habit data disappear.

**Sources:** `lib/app/composition/tasks_preview_adapters.dart`; `lib/app/composition/habits_preview_adapters.dart`; `lib/app/composition/configure_dependencies.dart`; `lib/app/routing/app_router.dart`.

## 6. Guard actions at the owning command boundary

**Decision:** Today submits desired completion state with expected scope, displayed local date and entity ID; serialize/coalesce per-item taps. Add a bounded optional expected-day precondition to Task completion and Habit complete/undo commands. Fresh owner reads, nondeleted/schedule checks, session revalidation and final clock check must share the owner transaction boundary before a write. Use existing `TaskRepository.runInTransaction`; add the same small transaction capability to HabitRepository/DriftHabitRepository rather than a generic orchestration framework. Existing all-date Task callers retain their behavior.

**Rationale:** Current TaskCompletionService checks account twice but reads before its write transaction and has no date guard. HabitCommands captures the date before awaited reads and never rechecks it; commitDay does not currently reread the parent Habit or protect against stale day overwrite. A Today-only precheck cannot close those async races. Owner transactions must reject deletion, invalid rescheduling and superseded reads without writing records, awards or pending operations. The final guard defines the action's validation point; do not relabel a completed operation as failure merely because the UI day changes after it committed.

**Alternatives considered:** UI disabling alone does not prevent races; copying commands into Today duplicates rules; silently substituting the new date applies a different intent; broad changes to reward/sync protocols are unnecessary. Use current owner transaction/error patterns, including rollback when an AppResult is failure, and regress existing Tasks/Mind Maps/Habits callers.

**Sources:** `lib/features/tasks/application/task_completion_service.dart`; `lib/features/tasks/data/drift_task_repository.dart`; `lib/features/habits/application/habit_commands.dart`; `lib/features/habits/data/drift_habit_repository.dart`.

## 7. Local calendar, independent recovery and account generations

**Decision:** Inject a small current-calendar reader for deterministic tests; app lifecycle supplies resume/foreground signals. While foreground, compare local date and UTC offset at intervals of at most 30 seconds and on resume, before actions and on source events. Recompute overdue from the current instant even when no Task row changed. Construct local midnight and the next calendar midnight before conversion to UTC; never assume every day is 24 hours.

Each source gets its own loading deadline of at most ten seconds, stream error/done handling, retry subscription and last confirmed value. Quiet open streams are healthy after their first response; do not expire them merely for inactivity. A failed Habit substream makes only the Habit section unavailable/stale. Task-derived agenda/priority/overdue share the Task section's health. Late events are tagged by scope generation and subscription attempt; ignore them after replacement. Clear old identity synchronously before starting the next subscriptions.

**Rationale:** Prevents midnight/timezone drift, indefinite spinners, false zero counts, hidden overdue changes, source coupling and account leakage. Confirmed stale data may remain only within the same identity/day; never retain old-day or foreign values as today's current values. Locale/theme changes reformat without business writes.

**Alternatives considered:** A single Future.wait blocks healthy sources; a one-shot midnight timer misses clock/zone changes; cloud reads delay offline use; an inactivity timeout marks stable local data as failed; an unbounded cache risks displaying foreign content.

**Sources:** `lib/features/habits/presentation/habits_cubit.dart` (existing owner lifecycle reference); `lib/app/app.dart`; `lib/core/application/ports/foundation_ports.dart`.

## 8. Owner navigation and creation intents

**Decision:** Make Today the gated root route. Keep owner screens and preference controls reachable. Add validated owner route intents for new Task (current date), matrix, overdue and new Habit. Owners open their existing editor once after route/scope readiness and consume the intent; cancel creates no records. Today presentation calls a navigation callback/intent contract, not owner presentation or infrastructure.

**Rationale:** Existing editors are tied to their owner Cubits; directly opening them from Today application would couple state. The root currently provides Foundation bootstrap/recovery and ready feature navigation, while global LocaleCubit/ThemeCubit already own preferences. Add a small app-owned preference menu using those existing commands and keep technical probes out of the daily product content. Route replay/rebuild must not reopen editors or create records.

**Alternatives considered:** Duplicating forms diverges validation; arbitrary serialized owner objects in routes become stale; adding public sign-in now contradicts scope.

**Sources:** `lib/app/routing/app_router.dart`; `lib/app/app.dart`; `lib/features/tasks/presentation/task_editor.dart`; `lib/features/habits/presentation/habit_editor.dart`.

## 9. Incremental verification and existing CI

**Decision:** Plan focused projection, adapter, command-race, Cubit, routing/RTL and integration checks. Register a compact Today acceptance suite in existing platform runners; extend the current workflow path filter for 006 documents and existing suite selections as needed. Preserve PR-to-develop/manual triggers, focused reruns and the final full gate. No CI run is needed to produce planning documents.

**Rationale:** All five platforms share owner rules; root-route changes and owner command guards need regression evidence. Existing Android/iOS harness repairs are already verified and should not be redesigned for this screen. Performance claims require recorded mobile and desktop timings at the exact fixture scale; two-device/timezone criteria require actual integration evidence, not a passing widget substitute.

**Alternatives considered:** Full multi-device CI on every feature push contradicts user preference; only a happy-path widget test misses persistence/account/calendar defects; re-running successful jobs without a cause adds no evidence.

**Sources:** `.github/workflows/foundation-ci.yml`; `.github/scripts/run-android-integration.sh`; `.github/scripts/run-ios-integration.py`; `test/architecture/`; `integration_test/`.

## Resolution

All technical unknowns are resolved into the contracts below. The read-only Task/XP, Habits and app-integration research agrees on reuse of current local streams and identifies the bounded preview, routing and command-guard changes. No additional product clarification, constitutional exception, dependency or schema migration is required.
