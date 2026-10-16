---
description: "Dependency-ordered implementation tasks for Namaa Habits 004"
---

# Tasks: Namaa Habits 004

**Input**: specs/004-habits/spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md, and .specify/memory/constitution.md

**Scope**: Flutter/Dart Habits on Android, iOS, Windows, macOS, and Linux. Reuse encrypted Foundation storage, session and sync boundaries, Supabase, Cubit, and ARB localization. Auth UI and notification delivery are later features.

## Format: [ID] [P?] [Story] Description

- [P] means the task can run alongside other marked tasks after its phase prerequisites are met: different files and no dependency between those tasks.
- [US1]–[US4] map exactly to the four stories in specs/004-habits/spec.md.
- All paths below are repository relative. Tests listed before implementation must be added and observed failing for the missing behavior, then passing when the story is complete.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the existing 003/Foundation seams and provide deterministic test data.

- [X] T001 Document the verified v3 Drift schema, Task sync/session/preview patterns, existing migration and SQL test commands, and 004 boundaries in specs/004-habits/implementation-baseline.md.
- [X] T002 Create deterministic account, Habit ID, UTC clock, local date/offset, schedule, and failing-store fixtures in test/support/habits_test_support.dart.

**Checkpoint**: Implementation can use established Foundation interfaces without inventing another store or sign-in flow.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add protected, account-keyed Habit and HabitDay storage before any story writes data.

- [X] T003 Add encrypted v3→v4 migration tests in test/unit/core/data/local/habits_migration_test.dart covering retained Foundation, Task, XP, preferences and outbox rows; new composite keys/indexes; failed migration recovery without reset.
- [X] T004 Add HabitRecords and HabitDayRecords with account-scoped composite keys and indexes plus an additive v3→v4 migration in lib/core/data/local/foundation_database.dart; retain the existing encryption and migration journal.
- [X] T005 Regenerate Drift schema code in lib/core/data/local/foundation_database.g.dart and make test/unit/core/data/local/habits_migration_test.dart pass.

**Checkpoint**: Existing encrypted accounts upgrade safely; no Habit data can share a local key across accounts.

---

## Phase 3: User Story 1 — Create and complete recurring habits (P1) 🎯 MVP

**Goal**: Create several named weekday habits; show due today; complete or undo only the current local date with immediate, durable local results.

**Independent Test**: In the existing non-release preview, create two schedules, complete one due habit, restart offline, confirm only its date is complete, then undo; blank name, empty weekdays, and an unscheduled day are rejected.

### Tests for User Story 1 — write first

- [X] T006 [P] [US1] Test nonblank names, canonical weekday sets, valid reminder minutes, stable local dates/offsets, and one-day identity in test/unit/features/habits/domain/habit_model_test.dart.
- [X] T007 [P] [US1] Test CreateHabit, CompleteHabitToday, UndoHabitToday, ten repeated taps, past-date rejection, unscheduled-date rejection, and typed failures in test/unit/features/habits/application/habit_commands_test.dart.
- [X] T008 [P] [US1] Test atomic Habit/HabitDay row plus stable-ID PendingChange, account partitioning, restart, and rollback on local failure in test/unit/features/habits/data/drift_habit_repository_test.dart.
- [X] T009 [P] [US1] Test empty/list/create/validation/complete/undo states and accessible controls in test/widget/features/habits/habits_screen_test.dart.
- [X] T010 [P] [US1] Add a debug-preview create/complete/undo/offline-restart journey in integration_test/habits_offline_sync_test.dart; leave cross-device assertions for US4.

### Implementation for User Story 1

- [X] T011 [P] [US1] Define immutable account-owned Habit, initial schedule revision, name/weekdays/reminder validation, version, and tombstone fields in lib/features/habits/domain/habit.dart.
- [X] T012 [P] [US1] Define independently keyed HabitDay with immutable localDate, UTC action version, recorded offset, completion/undo, and earned-while-due evidence in lib/features/habits/domain/habit_day.dart.
- [X] T013 [US1] Encode/decode Habit revisions and HabitDay payloads with version and date/offset round trips in lib/features/habits/data/habit_payload_codec.dart.
- [X] T014 [US1] Define account-scoped Habit repository and atomic mutation/outbox interfaces in lib/features/habits/application/habit_repository.dart.
- [X] T015 [US1] Implement create, complete and undo use cases in lib/features/habits/application/habit_commands.dart using the current session account and acting device date; reject foreign/deleted habits and never award XP.
- [X] T016 [US1] Persist local Habit and HabitDay versions with their PendingChanges in one encrypted transaction, enforce one row per account/habit/date, and preserve confirmed state on failure in lib/features/habits/data/drift_habit_repository.dart.
- [X] T017 [US1] Expose account-scoped active Habits and due-today/completion projections for later screens and aggregators in lib/features/habits/application/habit_queries.dart.
- [X] T018 [P] [US1] Add English names, weekday labels, route gate, validation, save/undo and local failure strings in lib/app/l10n/app_en.arb.
- [X] T019 [P] [US1] Add equivalent Arabic names, weekday labels, validation, save/undo and local failure strings in lib/app/l10n/app_ar.arb.
- [X] T020 [US1] Regenerate localized Dart resources in lib/app/l10n/generated/app_localizations.dart after both ARB files are complete.
- [X] T021 [US1] Connect ARB messages to the Habits presentation boundary in lib/app/l10n/habits_strings_adapter.dart and lib/features/habits/presentation/habits_strings.dart.
- [X] T022 [US1] Implement one Cubit/state owner for loading, active account, local mutation, validation failure, save failure and per-habit due/completion state in lib/features/habits/presentation/habits_cubit.dart and lib/features/habits/presentation/habits_state.dart.
- [X] T023 [US1] Build the accessible create form with name and Monday–Sunday selection in lib/features/habits/presentation/habit_editor.dart.
- [X] T024 [US1] Build responsive empty/list and due-today completion/undo controls with localized semantics in lib/features/habits/presentation/habits_screen.dart.
- [X] T025 [US1] Register Habit local ports/Cubit and an isolated non-release preview account in lib/app/composition/configure_dependencies.dart and lib/app/composition/habits_preview_adapters.dart.
- [X] T026 [US1] Add session-gated /habits routing that constructs account-scoped data only after account resolution in lib/app/routing/app_router.dart.
- [X] T027 [US1] Add the Habits entry to the existing app navigation and preview flow in lib/app/app.dart.

**Checkpoint**: US1 passes its domain, local, widget and preview restart tests without a network or Auth UI.

---

## Phase 4: User Story 2 — Track each habit's streak (P2)

**Goal**: Derive each Habit streak from its own effective schedule and day records; show completed dates as read-only history.

**Independent Test**: A Monday/Wednesday Habit completed on both days has streak two, Tuesday is neutral, a closed missed selected day breaks it, an unfinished selected today does not, and a second daily Habit has an independent result.

### Tests for User Story 2 — write first

- [X] T028 [P] [US2] Test selected-day streaks, closed misses, pending today, duplicate day, zero history and per-Habit isolation across ten schedule cases in test/unit/features/habits/domain/habit_streak_rules_test.dart.
- [X] T029 [P] [US2] Test account-scoped completed-date/history projections and exclusion of deleted parents in test/unit/features/habits/application/habit_queries_test.dart.
- [X] T030 [P] [US2] Test displayed independent streaks and read-only prior dates in test/widget/features/habits/habit_history_view_test.dart.
- [X] T031 [P] [US2] Add due/missed/neutral-day and history journey for two Habits in integration_test/habits_streak_history_test.dart.

### Implementation for User Story 2

- [X] T032 [US2] Derive the current streak from Habit schedule revisions and one HabitDay per date, treating unfinished today as pending and unscheduled dates as neutral, in lib/features/habits/domain/habit_streak_rules.dart.
- [X] T033 [US2] Add one-Habit completed-date, schedule and streak projections to lib/features/habits/application/habit_queries.dart without a second canonical streak store.
- [X] T034 [US2] Add Arabic/English streak, history, date and pending-day strings in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb, then regenerate lib/app/l10n/generated/app_localizations.dart.
- [X] T035 [US2] Build localized, accessible, read-only history and streak presentation in lib/features/habits/presentation/habit_history_view.dart.
- [X] T036 [US2] Wire the independent streak/history state into lib/features/habits/presentation/habits_cubit.dart and lib/features/habits/presentation/habits_screen.dart.

**Checkpoint**: US2 tests pass independently using local seeded Habits and recorded dates; Task progress and XP stay untouched.

---

## Phase 5: User Story 3 — Edit or remove a habit (P2)

**Goal**: Change name, weekdays and saved reminder; preserve historical schedule and earned completions; tombstone a confirmed deletion.

**Independent Test**: Complete today, remove today from weekdays, keep that completion visible and counted, undo it, reject a new completion while unscheduled, inspect older dates against the former schedule, and delete only that Habit.

### Tests for User Story 3 — write first

- [ ] T037 [P] [US3] Test ordered same-day schedule revisions, effective historical schedule, earned-while-due preservation and local-date/offset stability in test/unit/features/habits/domain/habit_schedule_revision_test.dart.
- [ ] T038 [P] [US3] Test edit/reminder/delete commands, today-immediate due changes, undo after removal, no re-complete while unscheduled, and confirmation boundary in test/unit/features/habits/application/habit_edit_delete_test.dart.
- [ ] T039 [P] [US3] Test atomic edit/delete tombstone and outbox writes, retained child day rows, and rollback after failed local save in test/unit/features/habits/data/drift_habit_edit_delete_test.dart.
- [ ] T040 [P] [US3] Test editor updates, inactive reminder wording, deletion confirmation, localized save failure, and unaffected other Habits in test/widget/features/habits/habit_edit_delete_test.dart.
- [ ] T041 [P] [US3] Add same-day edit, historical streak and delete/restart journey in integration_test/habits_edit_delete_test.dart.

### Implementation for User Story 3

- [ ] T042 [US3] Append ordered schedule revisions with UTC edit instant, acting-device effective local date/offset and stable revision ID in lib/features/habits/domain/habit.dart; retain earlier revisions.
- [ ] T043 [US3] Apply the revision effective at each date's close while preserving an earned-while-due completion after same-day removal in lib/features/habits/domain/habit_streak_rules.dart.
- [ ] T044 [US3] Implement edit name/weekdays/reminder and explicit delete commands with typed validation and current-account checks in lib/features/habits/application/habit_commands.dart.
- [ ] T045 [US3] Persist edit versions and deletion tombstones atomically with outbox operations; keep child days for replay/conflict recovery in lib/features/habits/data/drift_habit_repository.dart.
- [ ] T046 [US3] Add Arabic/English edit, delete confirmation and inactive reminder messages in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb, then regenerate lib/app/l10n/generated/app_localizations.dart.
- [ ] T047 [US3] Extend the editor with current values, optional wall-clock reminder save/clear, and visibly inactive delivery status in lib/features/habits/presentation/habit_editor.dart.
- [ ] T048 [US3] Add delete confirmation and hide tombstoned Habit/history from active views in lib/features/habits/presentation/habits_screen.dart and lib/features/habits/presentation/habit_history_view.dart.
- [ ] T049 [US3] Update Cubit transitions for immediate due changes, retained completion, edit/delete failures, and last confirmed state in lib/features/habits/presentation/habits_cubit.dart.

**Checkpoint**: US3 passes edit/delete tests offline and after restart; no notification permission or delivery is invoked.

---

## Phase 6: User Story 4 — Continue habits across interruptions (P2)

**Goal**: Retry safely across devices, reconcile complete account snapshots, expose losing conflicts, and deny cross-account access.

**Independent Test**: Create/edit/complete/delete offline, restart, reconnect two devices, replay operations ten times, merge distinct and same dates, force complete/undo and edit/delete races, switch accounts mid-sync, and confirm no foreign data leaks.

### Tests for User Story 4 — write first

- [ ] T050 [P] [US4] Test owner-only Habit/Day/conflict reads, foreign-account denial, anonymous denial, direct-write denial and receipt-read denial in supabase/tests/habits_account_isolation_test.sql.
- [ ] T051 [P] [US4] Test atomic owner-derived mutation/receipt replay ten times, payload/date/parent validation, same-date uniqueness and tombstone retry in supabase/tests/habits_operation_integrity_test.sql.
- [ ] T052 [P] [US4] Test newest-version winner/visible loser, equal-time unresolved state, edit/delete race, day/delete race and different-date retention in supabase/tests/habits_conflict_integrity_test.sql.
- [ ] T053 [P] [US4] Test Habit and HabitDay dispatch, stable operation IDs, rejected unknown types, retry and acknowledgement only after commit in test/unit/core/data/sync/entity_dispatch_router_test.dart.
- [ ] T054 [P] [US4] Test outbound payloads/receipts and fully paginated owner reads including final page and tombstones in test/unit/features/habits/data/supabase_habit_adapter_test.dart.
- [ ] T055 [P] [US4] Test atomic local winner application, visible loser, equal-time recovery, day identity merge and parent tombstone handling in test/unit/features/habits/data/habit_reconciler_test.dart.
- [ ] T056 [P] [US4] Test outbound-before-inbound ordering, changed-account guards after each await, incomplete-page failure, and ready state only after full pass in test/unit/features/habits/application/habit_sync_service_test.dart.
- [ ] T057 [P] [US4] Test signed-out/unresolved/switching account route gates and preview-only access in test/widget/app/habits_route_test.dart.
- [ ] T058 [P] [US4] Extend integration_test/habits_offline_sync_test.dart with two-account/two-device reconnect, independent dates, same-date replay, conflicts, local failure and ten restart/reconnect trials.
- [ ] T059 [P] [US4] Add localized Arabic/English, RTL, keyboard/focus, and mobile/desktop route checks in integration_test/habits_localized_route_test.dart.

### Implementation for User Story 4

- [ ] T060 [US4] Create owner-keyed public.habits, public.habit_days and durable operation receipts with foreign keys, SELECT RLS and least-privilege grants in supabase/migrations/0006_habits_tables.sql.
- [ ] T061 [US4] Add authenticated owner-derived Habit/HabitDay mutation RPCs with payload validation, atomic receipts, newest-timestamp conflicts, equal-time recovery, and parent tombstone/day-race evidence in supabase/migrations/0007_habit_sync_api.sql.
- [ ] T062 [US4] Implement receipt-aware outbound Habit/HabitDay cloud mutations in lib/features/habits/data/supabase_habit_sync_adapter.dart.
- [ ] T063 [US4] Implement owner-scoped, paginated Habit/tombstone/Day reads and a complete-pass cursor in lib/features/habits/data/supabase_habit_reader.dart and lib/features/habits/application/habit_remote_reader.dart.
- [ ] T064 [US4] Define Habit synchronization and reconciliation ports with per-entity version identity in lib/features/habits/application/habit_reconciliation.dart.
- [ ] T065 [US4] Apply active winners atomically with Foundation ConflictRecords, preserve pending changes and equal-time/parent-race evidence, and merge days by account/habit/localDate in lib/features/habits/data/habit_reconciler.dart.
- [ ] T066 [US4] Implement account-checked outbound then full inbound sync, page-failure recovery and truthful ready state in lib/features/habits/application/habit_sync_service.dart.
- [ ] T067 [US4] Route habit and habit_day PendingChanges through their cloud adapters while retaining unknown types in lib/core/data/sync/entity_dispatch_router.dart.
- [ ] T068 [US4] Register cloud reader/adapter/reconciler/sync service only for a resolved authenticated account; keep preview isolated in lib/app/composition/configure_dependencies.dart.
- [ ] T069 [US4] Add Arabic/English syncing, conflict and recoverable failure messages in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb, then regenerate lib/app/l10n/generated/app_localizations.dart.
- [ ] T070 [US4] Show syncing, recoverable failure and visible Habit/Day conflict states with localized recovery details in lib/features/habits/presentation/habits_cubit.dart and lib/features/habits/presentation/habits_screen.dart.

**Checkpoint**: US4 passes local and Supabase security/replay tests; no partial page or account switch can report ready or expose another account.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Close architecture, localization, target, security and release evidence for the complete 004 slice.

- [ ] T071 [P] Add architecture checks preventing Habits storage access from Tasks/Today/Dashboard/Analytics and Habit XP mutation in test/architecture/habits_boundaries_test.dart.
- [ ] T072 [P] Add 004 trigger paths/branch and all four Habits integration entries (habits_offline_sync_test.dart, habits_streak_history_test.dart, habits_edit_delete_test.dart, habits_localized_route_test.dart) for Linux, Windows, macOS and iOS, preserving Android discovery, in .github/workflows/foundation-ci.yml.
- [ ] T073 Run format, analyze, all Flutter tests, local Supabase SQL tests, and every quickstart integration entry; record commands, outcomes and any environment limit in specs/004-habits/verification.md.
- [ ] T074 Verify persistence, account sync and localized primary flows on Android, iOS, Windows, macOS and Linux, using an isolated non-production project for authenticated device checks; append target results to specs/004-habits/verification.md.
- [ ] T075 Run the three-minute create/complete/streak comprehension check and compare against SC-007; record participant count, success rate and remaining issue in specs/004-habits/verification.md.
- [ ] T076 Review specs/004-habits/verification.md against every FR/SC, document public-release dependency on later Auth/initial account sync and deferred notification delivery, and mark 004 complete only when evidence and CI are green.

---

## Dependencies & Execution Order

### Phase dependencies

1. Setup → Foundational. The v4 migration and fixtures precede all feature persistence.
2. Foundational → US1. US1 is the local-preview MVP and must pass before adding derived history.
3. US1 → US2 and US3. US2 consumes US1 dates; US3 extends US1 revisions and the US2 streak rule. Complete US2 before the US3 history/streak changes.
4. US1–US3 → US4. Cloud reconciliation uses the stable Habit and HabitDay payloads and all local commands.
5. US1–US4 → Polish. Do not claim 004 complete from a rendering-only check.

### User story dependencies

- **US1 (P1)**: v4 storage only; delivers a working offline preview increment.
- **US2 (P2)**: consumes US1 Habit/HabitDay data; can be validated with seeded local rows before sync exists.
- **US3 (P2)**: consumes US1 commands and US2 streak projection; validates edits and deletion independently with offline fixtures.
- **US4 (P2)**: consumes stable records, commands and history from US1–US3; validates cross-device behavior without adding Auth UI.

Within each phase, add the story tests first, observe failure for unimplemented behavior, then implement domain → data/application → UI/integration. Each [P] group can be assigned across independent files after phase prerequisites are satisfied; edits to a shared file remain sequential.

## Parallel Examples

### User Story 1

- Run the five first-pass tests in test/unit/features/habits/domain/habit_model_test.dart, test/unit/features/habits/application/habit_commands_test.dart, test/unit/features/habits/data/drift_habit_repository_test.dart, test/widget/features/habits/habits_screen_test.dart, and integration_test/habits_offline_sync_test.dart in parallel.
- Create lib/features/habits/domain/habit.dart and lib/features/habits/domain/habit_day.dart in parallel; prepare lib/app/l10n/app_en.arb and lib/app/l10n/app_ar.arb in parallel.

### User Story 2

- Add independent rule, query, widget and integration tests in test/unit/features/habits/domain/habit_streak_rules_test.dart, test/unit/features/habits/application/habit_queries_test.dart, test/widget/features/habits/habit_history_view_test.dart, and integration_test/habits_streak_history_test.dart.

### User Story 3

- Add revision, command, persistence, widget and integration tests in the five US3 test files in parallel. Domain revisions, streak calculation, repository and screen changes follow their tested dependencies sequentially.

### User Story 4

- Add the three independent SQL suites in supabase/tests/ and the unit/widget/integration suites in their distinct paths in parallel. Apply migrations sequentially: tables/RLS first, then mutation API.

## Implementation Strategy

1. **MVP**: Complete Setup, Foundational and US1; demonstrate local-preview creation and today's completion/undo after offline restart.
2. **Incremental**: Add US2 history/streak, then US3 schedule edits, inactive reminder and deletion; run each story's independent tests.
3. **Account integrity**: Add US4 cloud storage, SQL boundary, complete sync and visible conflicts; run account and replay checks.
4. **004 closure**: Pass the five-target, localization, accessibility, security and SC evidence in Phase 7. Public account-based release remains gated by the separate Auth feature and initial account synchronization; actual reminder delivery remains in Notifications.


