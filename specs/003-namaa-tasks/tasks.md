---
description: "Dependency-ordered implementation tasks for Namaa Tasks"
---

# Tasks: Namaa Tasks

**Input**: specs/003-namaa-tasks/spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/task-interactions.md, contracts/task-sync-security.md, and .specify/memory/constitution.md.

**Execution rule for a small implementation agent**: Read those sources and the named existing files before each phase. Do only the checked task, preserve unrelated changes, and record the command/result before marking it done. Write each phase's tests first; an initial failure caused by missing planned code/schema is expected, but an environment/configuration failure is not proof of a red test. Do not invent Auth screens, recurrence, Mind Maps, Habits, Today, Realtime, or a new XP system. Use existing packages and Foundation conventions. Do not push to main.

**Test rule**: Every test task below is required by the spec/constitution, not optional. Tests precede the production code they assert. Run focused tests after each implementation step and the named phase checkpoint. Existing Foundation tests must keep passing.

## Format: [ID] [P?] [Story] Description

- **[P]** means the task can run in parallel with other [P] tasks in its own test block (or the two separate ARB files), after preceding phases are complete; it does not waive test-first order.
- **[US1]/[US2]/[US3]** identify spec user stories. Setup, foundation, and final verification tasks have no story label.
- Paths are repository-relative and exact. The named test/production files are to be created if absent; existing files are edited in place.

## Phase 1: Setup (shared preparation)

**Purpose**: Give an implementation agent a verified starting point without changing product behavior.

- [x] T001 Record the existing Foundation schema version, probe-only local/cloud adapters, sync runner triggers, DI/router entry points, active branch, and baseline results for flutter analyze, flutter test, and supabase test db (local stack) in specs/003-namaa-tasks/implementation-baseline.md; cite the exact source files and do not modify Foundation behavior.
- [x] T002 Create deterministic account A/B IDs, UTC clock/local-date, stable Task/operation ID, and offline/online test fixtures in test/support/tasks_test_support.dart; use existing Foundation test conventions and no production credentials.

**Checkpoint**: The agent can name what is already implemented versus what Tasks must add.

---

## Phase 2: Foundational (blocks all Task stories)

**Purpose**: Add data-preserving Task storage and secure/idempotent cloud primitives without pretending Foundation's probe is a generic Task implementation.

**Test-first block — write and run T003–T006 before T007–T011. Missing Task schema/router may make them fail initially.**

- [x] T003 [P] Test encrypted Foundation v2→v3 upgrade, preservation of existing preferences/probe/outbox data, new account-scoped Task/XP tables, and failed-upgrade recovery in test/unit/core/data/local/tasks_migration_test.dart; assert no database reset or plaintext fallback.
- [x] T004 [P] Write local-stack pgTAP checks in supabase/tests/tasks_account_isolation_test.sql: owner may read own Task and XP-award rows while operation receipts stay internal, and change Tasks only via the authorized RPC; direct client writes to Task/award/receipt tables are denied; a different account and anonymous caller cannot read or mutate the owner's rows; spoofed owner is rejected.
- [x] T005 [P] Test stable operation-ID replay, create/update/delete tombstones, deletion retry without resurrection, and receipt survival in supabase/tests/tasks_operation_integrity_test.sql; use authenticated account fixtures and expect the test to fail before the Task RPC exists.
- [x] T006 [P] Test CloudSyncPort dispatch routing for foundation_record→existing probe adapter, task→Task adapter, and unknown type→recoverable non-acknowledged failure in test/unit/core/data/sync/entity_dispatch_router_test.dart; keep probe regression assertions.
- [x] T007 Extend lib/core/data/local/foundation_database.dart to schema v3 with composite account-scoped Task rows and immutable unique XP-award rows from data-model.md, checklist JSON in the Task aggregate, queryable Task fields, and an additive migration using the existing journal/recovery path; do not alter v1/v2 data.
- [x] T008 Create supabase/migrations/0003_tasks_tables.sql for account-owned Task rows, immutable award rows, durable operation receipts, tombstones, owner-derived RLS, and least-privilege grants that deny direct client mutations outside the authorized RPC; satisfy T004 without weakening foundation_probe policies.
- [x] T009 Create supabase/migrations/0004_task_sync_api.sql with authenticated create/update/delete Task application via auth.uid-derived owner checks and a restricted RPC search_path, UTC-version conflict result, durable operation receipt keyed by account+operationId, and replay-safe tombstones; satisfy T005 without adding the US2 award effect yet.
- [x] T010 Implement the tested entity-type CloudSyncPort router in lib/core/data/sync/entity_dispatch_router.dart; keep existing probe requests unchanged and never acknowledge an unknown entity type.
- [x] T011 Regenerate lib/core/data/local/foundation_database.g.dart from T007 with the repository's build_runner workflow; inspect the generated schema and do not hand-edit generated code.
- [x] T012 Run T003–T006 plus existing Foundation migration/probe tests and supabase test db; record exact pass/fail evidence and any external blocker in specs/003-namaa-tasks/verification.md before starting US1.

**Checkpoint**: A Foundation v2 database upgrades safely; local Supabase enforces ownership and durable Task replay; the probe still works. Phase 2 does not claim a user-visible Task feature.

---

## Phase 3: User Story 1 — Capture and organize finite work (P1, internal MVP)

**Goal**: Create, edit, move, filter, and delete a single canonical Task across list/matrix while changes are local-first and account-scoped.

**Independent test**: With an injected signed-in account, create a title-only Task and a detailed Task; edit, move, filter, restart offline, sync to a second client, and delete. IDs and state agree in all views, no network is needed for local edits, and a different account sees nothing. This is an internal MVP, not user release without the separate sign-in prerequisite.

**Test-first block — write and run T013–T021 before T022–T040. Missing production types/widgets may initially fail to compile.**

- [ ] T013 [P] [US1] Test Task identity, seven categories, four quadrants, nonblank trimmed title, required date, today/work/urgent_important/30-minute defaults, optional fields, stable reward snapshot, and tombstone transitions in test/unit/features/tasks/domain/task_model_test.dart.
- [ ] T014 [P] [US1] Test account-scoped create/edit/move/delete commands, localized validation failure keys, unchanged ID, and no write for foreign/missing/deleted Task in test/unit/features/tasks/application/task_commands_test.dart.
- [ ] T015 [P] [US1] Test one encrypted local Task+PendingChange transaction, stable operation IDs, account-isolated reads, restart persistence, rollback on failed write, and deletion tombstones in test/unit/features/tasks/data/drift_task_repository_test.dart; do not use LocalRecords as Task storage.
- [ ] T016 [P] [US1] Test Task outbound RPC mapping, UTC timestamps, conflict/ack result mapping, and account-scoped paginated Task/tombstone fetch in test/unit/features/tasks/data/supabase_task_adapter_test.dart; use a fake gateway, not production Supabase.
- [ ] T017 [P] [US1] Test initial inbound pull, pending-local preservation, newest-timestamp active version, retained visible loser, equal-timestamp recoverable pair, and edit-vs-delete conflict in test/unit/features/tasks/application/task_reconciliation_test.dart.
- [ ] T018 [P] [US1] Test one TasksCubit state source for local updates, Today/Urgent/All/Completed/category filters, open four-quadrant matrix, sync/conflict status, and no duplicate Task identities in test/unit/features/tasks/presentation/tasks_cubit_test.dart.
- [ ] T019 [P] [US1] Widget-test title-only defaults, detailed edit/delete, blank-title message, list/matrix identity, category/filter controls, visible conflict recovery, signed-out Task guard, and mobile/desktop layouts in test/widget/features/tasks/tasks_screen_test.dart.
- [ ] T020 [P] [US1] Add a test-first authenticated offline create/edit/delete→restart→reconnect→second-client scenario with account isolation and tombstone replay in integration_test/tasks_offline_sync_test.dart; use local/nonproduction test configuration only.
- [ ] T021 [P] [US1] Assert lib/features/tasks/domain/ does not import Flutter, Drift, Supabase, presentation, or other feature storage; assert one canonical Task owner in test/architecture/tasks_boundary_test.dart.
- [ ] T022 [US1] Create the Task aggregate and simple ChecklistItem value fields (no checklist commands yet) in lib/features/tasks/domain/task.dart and lib/features/tasks/domain/checklist_item.dart; represent date/time/deadline, account ID, reward snapshot, completion time, version and tombstone exactly as data-model.md.
- [ ] T023 [US1] Implement title/default/enum validation and pure Today/Urgent/All/Completed/category/matrix projections in lib/features/tasks/domain/task_rules.dart; All includes completed, Today/Urgent/matrix exclude them, and no view owns a copy.
- [ ] T024 [US1] Define SDK-free account-scoped Task read/watch/write and inbound-merge ports in lib/features/tasks/application/task_repository.dart; return existing AppResult/failure types and do not expose Drift or Supabase classes.
- [ ] T025 [US1] Implement create/edit/move/delete application commands in lib/features/tasks/application/task_commands.dart; obtain the active account through Foundation's session boundary, generate collision-resistant Task/operation IDs locally with Dart SDK facilities, write locally before sync, and return typed failures.
- [ ] T026 [US1] Implement stable Task aggregate serialization, date/time-zone preservation, checklist JSON, tombstones, and UTC version decoding in lib/features/tasks/data/task_payload_codec.dart; round-trip T013/T015 fixtures without dropping unknown optional values.
- [ ] T027 [US1] Implement account-filtered Drift Task reads/watches and atomic Task+Foundation outbox commits in lib/features/tasks/data/drift_task_repository.dart; use T007 tables, existing encrypted database, and versioned tombstones, not the probe LocalRecords.
- [ ] T028 [US1] Implement Task outbound CloudSyncPort adapter against T009 RPC in lib/features/tasks/data/supabase_task_sync_adapter.dart; preserve operationId on retries and map acknowledgement/conflict/failure without client-side owner authority.
- [ ] T029 [US1] Implement complete account-scoped paginated Task/tombstone reads behind a Task application port in lib/features/tasks/data/supabase_task_reader.dart; never mark initial pull complete after only one page.
- [ ] T030 [US1] Implement account-scoped inbound Task merge and Foundation conflict-record persistence in lib/features/tasks/data/task_reconciler.dart; retain pending local changes, visible nonwinner, and both equal-timestamp versions without inventing a tie-breaker.
- [ ] T031 [US1] Implement initial signed-in Task pull and reconnect/Tasks-entry reconciliation using CloudSessionPort and ConnectivityPort in lib/features/tasks/application/task_sync_service.dart; expose a clear initial-ready/failure state and keep offline operations available after the first successful sync.
- [ ] T032 [US1] Register the real Task repository, remote adapters, Task sync service, and T010 router in lib/app/composition/configure_dependencies.dart; preserve Foundation probe registration, safe-fail test/unconfigured modes, and disposal.
- [ ] T033 [US1] Define immutable loading/ready/sync-failure/conflict Task presentation states in lib/features/tasks/presentation/tasks_state.dart; store no second canonical Task list outside the repository projection.
- [ ] T034 [US1] Implement TasksCubit commands, account-local observation, list/matrix filter selection, and local-first state updates in lib/features/tasks/presentation/tasks_cubit.dart; satisfy T018 without importing data adapters.
- [ ] T035 [US1] Build responsive list/matrix Task views and Today/Urgent/All/Completed/category controls in lib/features/tasks/presentation/tasks_screen.dart; use stable Task IDs, existing theme, and a visible recoverable conflict affordance, not a visual redesign.
- [ ] T036 [US1] Build the create/edit Task form with specified fields/defaults and localized nonblank-title feedback in lib/features/tasks/presentation/task_editor.dart; do not add recurrence or unrelated feature controls.
- [ ] T037 [P] [US1] Add all US1 Task labels, category/quadrant names, validation, sync and guard messages to lib/app/l10n/app_en.arb; follow existing ARB key conventions.
- [ ] T038 [P] [US1] Add the matching Arabic keys/translations to lib/app/l10n/app_ar.arb; verify RTL-friendly wording and regenerate l10n output through the normal Flutter command, not manual edits to generated files.
- [ ] T039 [US1] Register a guarded /tasks route in lib/app/routing/app_router.dart using Foundation's account state; block signed-out data access and show a localized sign-in-required state without inventing an Auth flow.
- [ ] T040 [US1] Wire Tasks navigation, route builder/Cubit lifecycle, and theme/locale inheritance into lib/app/app.dart; preserve the Foundation root, error route, and existing shell tests.
- [ ] T041 [US1] Run T013–T021, focused Foundation regressions, and the US1 quickstart scenario; record result in specs/003-namaa-tasks/verification.md. Do not mark US1 user-release-ready merely because injected-session tests pass.

**Checkpoint**: US1 can be tested independently with a signed-in test session. US2 and US3 are not yet complete.

---

## Phase 4: User Story 2 — Complete a Task once for its reward (P1)

**Goal**: Explicit completion/reopening preserves one lifetime XP award through offline cycles, deletion, retry, and another device.

**Independent test**: Complete→reopen→complete ten times, restart offline and reconnect; exactly one immutable award exists locally/remotely, completion time reflects current state, and deleting the Task leaves its XP.

**Test-first block — write and run T042–T045 before T046–T055.**

- [ ] T042 [P] [US2] Test explicit completion time, reopening clears it, recompletion updates it, incomplete checklist does not block completion, and repeated complete on an already completed Task is not a new event in test/unit/features/tasks/domain/task_completion_test.dart.
- [ ] T043 [P] [US2] Test one award per (account, task_done, Task ID), configured amount snapshot, ten complete/reopen cycles, atomic Task+award+outbox rollback, account partition, and award retention on deletion in test/unit/features/xp/task_award_ledger_test.dart.
- [ ] T044 [P] [US2] Test authenticated remote completion+first-award atomicity, duplicate operation IDs, distinct completion IDs for the same Task, cross-account denial, and delete-after-award retention in supabase/tests/task_xp_integrity_test.sql.
- [ ] T045 [P] [US2] Add ten offline restart/reconnect cycles and same-account two-client completion/reopen tests proving one Task/one award in integration_test/tasks_completion_sync_test.dart; use isolated nonproduction accounts, never production credentials.
- [ ] T046 [US2] Create the immutable TaskCompletionAward value and unique account/source/sourceId key in lib/features/xp/domain/task_completion_award.dart; do not add levels, streaks, or mutable XP balance.
- [ ] T047 [US2] Define the shared XP award/query port and first-insert-only result in lib/features/xp/application/award_ledger.dart; Tasks uses this authority through an explicit application service, not presentation state or a Task-owned XP total.
- [ ] T048 [US2] Implement account-scoped immutable award reads and insert-once operations against T007's encrypted table in lib/features/xp/data/drift_award_ledger.dart; expose transaction participation for T049 and never remove an award on Task deletion.
- [ ] T049 [US2] Define an SDK-free completion unit-of-work port in lib/features/tasks/application/task_completion_unit_of_work.dart and implement it in lib/core/data/local/task_completion_unit_of_work.dart to atomically change Task, insert the first shared XP award, and queue the Task operation; roll back all effects on failure and never insert a second award.
- [ ] T050 [US2] Implement explicit complete/reopen use cases in lib/features/tasks/application/task_completion_service.dart against T049's port and register that port/service in lib/app/composition/configure_dependencies.dart; validate account/Task state, clear or set completedAt, and leave checklist steps unchanged.
- [ ] T051 [US2] Create supabase/migrations/0005_task_xp_completion.sql to extend Task application atomically: server-observed first completion inserts one award using the stored Task reward snapshot; retries and later completions cannot add another; ownership/grants/RLS remain strict.
- [ ] T052 [US2] Update lib/features/tasks/data/supabase_task_sync_adapter.dart to send completion/reopening as Task changes to T051, keep the stable operation ID, and map remote award/conflict outcomes without a separate reward dispatch.
- [ ] T053 [US2] Extend lib/features/tasks/data/supabase_task_reader.dart and lib/features/tasks/application/task_sync_service.dart to fetch all account-scoped award pages and merge them through AwardLedgerPort in lib/features/xp/application/award_ledger.dart (implemented by lib/features/xp/data/drift_award_ledger.dart) by unique key before initial sync reports ready; preserve Task tombstone and pending-change reconciliation.
- [ ] T054 [US2] Add complete/reopen actions and single-award observable state to lib/features/tasks/presentation/tasks_cubit.dart; derive earned XP from the shared award query and never increment a UI counter optimistically.
- [ ] T055 [US2] Add explicit complete/reopen controls and completion timestamp display in lib/features/tasks/presentation/tasks_screen.dart; incomplete checklist items must not block the action, and no checklist auto-completion is added.
- [ ] T056 [US2] Run T042–T045, supabase test db, and US2 quickstart scenario; record one-award evidence and Foundation/US1 regressions in specs/003-namaa-tasks/verification.md.

**Checkpoint**: US2 is independently verifiable on the US1 Task foundation; it does not introduce broad Gamification.

---

## Phase 5: User Story 3 — Break down and review work (P2)

**Goal**: Simple Task-owned checklist steps plus Today/Urgent/All/Completed/history/overdue review, with no automatic parent completion or step XP.

**Independent test**: Add/edit/check/uncheck/remove steps; complete all steps without completing parent; explicitly complete parent with an incomplete step; check views and overdue rules before/after restart.

**Test-first block — write and run T057–T061 before T062–T070.**

- [ ] T057 [P] [US3] Test stable checklist item IDs/order, nonblank text, parent ownership, no independent schedule/category/XP, no parent auto-completion, and explicit parent completion with unfinished steps in test/unit/features/tasks/domain/task_checklist_test.dart.
- [ ] T058 [P] [US3] Test checklist add/edit/check/uncheck/remove commands, only one parent Task outbox change per edit, account isolation, restart round-trip, and deletion tombstone in test/unit/features/tasks/application/task_checklist_commands_test.dart.
- [ ] T059 [P] [US3] Test Completed/history completion dates and overdue when scheduled date or target deadline passed; exclude completed Tasks and elapsed same-day scheduledTime in test/unit/features/tasks/application/task_review_queries_test.dart.
- [ ] T060 [P] [US3] Widget-test checklist controls, no auto parent completion/XP, incomplete-step parent completion, history/overdue filters, date text, and Arabic RTL in test/widget/features/tasks/task_review_screen_test.dart.
- [ ] T061 [P] [US3] Add offline checklist edits→restart→reconnect and history/overdue projection agreement in integration_test/tasks_checklist_history_test.dart; verify one Task identity in list/matrix and no step XP.
- [ ] T062 [US3] Implement pure Task-owned checklist add/edit/toggle/remove rules in lib/features/tasks/domain/task.dart and lib/features/tasks/domain/checklist_item.dart; each mutation versions the parent, with no independent checklist entity or reward.
- [ ] T063 [US3] Add validated, account-scoped checklist commands to lib/features/tasks/application/task_commands.dart; call the existing Task repository/outbox path and never infer parent completion from step states.
- [ ] T064 [US3] Extend lib/features/tasks/data/task_payload_codec.dart and lib/features/tasks/data/drift_task_repository.dart for ordered checklist JSON round-trip and atomic parent Task outbox writes; do not create a separate checklist table or remote operation.
- [ ] T065 [US3] Implement pure Completed/history/overdue Task queries in lib/features/tasks/application/task_review_queries.dart; use saved completion time, local calendar date, deadline timezone context, and the approved overdue rule.
- [ ] T066 [US3] Expose checklist and review-query state/actions from lib/features/tasks/presentation/tasks_cubit.dart; keep list, matrix, history, and overdue derived from the same repository Task identities.
- [ ] T067 [US3] Add simple checklist item editing/checking/removal to lib/features/tasks/presentation/task_editor.dart; no independent date, category, XP, or automatic parent-complete control.
- [ ] T068 [US3] Add Completed/history date and Overdue views to lib/features/tasks/presentation/tasks_screen.dart; preserve prototype list/matrix structure and exclude completed Tasks from overdue/matrix.
- [ ] T069 [P] [US3] Add US3 checklist/history/overdue labels and validation to lib/app/l10n/app_en.arb; use existing localization style.
- [ ] T070 [P] [US3] Add matching Arabic resources to lib/app/l10n/app_ar.arb and regenerate l10n through Flutter; verify RTL layout and readable mixed Arabic/English numbers.
- [ ] T071 [US3] Run T057–T061 and all US1/US2 tests; record checklist, overdue, history, restart, and no-extra-XP evidence in specs/003-namaa-tasks/verification.md.

**Checkpoint**: All three Task stories are functionally testable together.

---

## Phase 6: Polish and cross-cutting release gates

**Purpose**: Verify constitutional Definition of Done and preserve the separate Auth prerequisite.

- [ ] T072 Extend .github/workflows/foundation-ci.yml so Task unit/widget/SQL and Task integration checks run in the existing quality, database-security, Android, iOS, Windows, macOS, and Linux gates; retain Foundation checks and ensure the namaa/003-tasks branch can receive CI results.
- [ ] T073 Execute formatting/code generation, flutter analyze, flutter test, supabase test db, and specs/003-namaa-tasks/quickstart.md scenarios; record commands/results and any failures in specs/003-namaa-tasks/verification.md, without marking failed checks done.
- [ ] T074 Verify the separate basic user-facing sign-in path is present and /tasks waits for a complete initial authenticated Task+award sync before user release; record the external Auth feature/commit evidence or an explicit blocked release gate in specs/003-namaa-tasks/verification.md. Do not implement Auth inside Tasks.
- [ ] T075 Collect green Task persistence/account-sync results for Android, iOS, Windows, macOS, and Linux plus Arabic/English mobile/desktop RTL evidence in specs/003-namaa-tasks/verification.md; preserve failing/missing target results as open blockers rather than declaring the feature complete.

---

## Dependencies and execution order

- **Phase 1 → Phase 2 → US1 → US2 → US3 → Phase 6** is the safe single-agent path.
- Phase 2 supplies the shared v3 storage, account ownership, stable operation receipts, and entity dispatch. No story starts before T012.
- US1 supplies the canonical Task aggregate, repository, Task cloud transport and UI. US2 depends on US1's Task identity/persistence; US3 depends on US1's aggregate and US2's completion/history behavior. They are independently testable *after* their shared prerequisites, not parallel feature branches in this implementation.
- Each test-first block must be committed or otherwise preserved before its production block; the expected initial red state must be due to missing planned behavior. Do not mark a block green until relevant tests pass.
- T074 is an external **release** dependency: a basic Auth UI is separately specified/implemented. This Task list only integrates with its session contract; if it does not exist, leave release blocked and report it.
- An exact equal-timestamp automatic winner is **not** a dependency. Retain both recoverably per Foundation; do not invent a tie-breaker.

### Parallel opportunities (only after prior phase gates)

- Phase 2: T003, T004, T005, T006 use different test files and may be authored in parallel; T008/T009 are sequential migrations, and T010 follows T006.
- US1: T013–T021 are distinct test files and may be authored in parallel; after the production UI labels are known, T037/T038 are independent language files.
- US2: T042–T045 are distinct test files and may be authored in parallel; production work remains dependency-ordered.
- US3: T057–T061 are distinct test files and may be authored in parallel; T069/T070 are independent language files.
- Do not parallel-edit lib/app/composition/configure_dependencies.dart, lib/app/app.dart, lib/app/routing/app_router.dart, lib/features/tasks/presentation/tasks_cubit.dart, or lib/features/tasks/presentation/tasks_screen.dart across phases.

### Parallel example: US1

~~~text
After T012, author T013 task model tests, T015 Drift repository tests,
T017 reconciliation tests, and T019 widget tests in separate files.
Confirm their expected red state. Then implement T022 onward in order.
Only after US1 UI labels are fixed, author T037 English and T038 Arabic
ARB resources in parallel; regenerate once both are complete.
~~~

## Implementation strategy

**Internal MVP:** Finish Phase 1, Phase 2, and US1; validate T041 with an injected authenticated session. This proves Task CRUD and list/matrix without claiming public release. Then complete US2 and US3. User release additionally requires T072–T075, particularly the separately delivered sign-in path and the five-target gate.

**Scope guard:** No broad Gamification, new Auth flow, recurrence, Habits, Mind Maps, Today aggregation, notifications, Finance, Quran, or UI redesign. Future domains consume Task identity/state through the explicit application contract, never a second canonical Task store.
