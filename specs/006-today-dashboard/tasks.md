---
description: "Dependency-ordered implementation tasks for Dashboard / Today 006"
---

# Tasks: Dashboard / Today 006

**Branch**: `namaa/006-today-dashboard`
**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md) and all three [contracts](contracts/).
**Governance**: Namaa Constitution v2.0.1; approved separate progress percentages and today-or-overdue Do First scope.

**Tests**: Included because the specification explicitly defines independently testable journeys, race/recovery scenarios and measured acceptance criteria, reinforced by the constitution. Write new behavioral tests before their implementation and verify that the missing behavior is actually detected; use existing suites rather than duplicate them. No tests/CI are executed by generating this file.

**Organization**: Two shared phases, then one independently verifiable increment per user story in priority order, then cross-cutting acceptance. All tasks start unchecked. New file names follow the planned feature-first layout; paths are repository-relative.

## Format and execution rules

- Task lines use `- [ ] Tnnn [P?] [USn?] Description with file path`.
- The `[P]` marker permits work on disjoint files only after its listed prerequisites. It is not authorization to spawn agents, commit, push or launch full CI.
- Read the referenced source/contracts before each change; preserve unrelated work and existing local preview data.
- No dependency upgrade, schema migration, public Auth flow, new reward writer, Today persistence/sync or final visual design is planned.
- Complete each phase's focused checks before treating its checkpoint as passed. Record actual results in verification.md; unexecuted native/timing/two-device cases remain unverified.
- Full CI stays at authorized integration/PR-to-develop or manual runs, not every feature push. On the same head, inspect failures and rerun only affected failed/cancelled jobs where appropriate.
- The read-only MVP deliberately has no enabled completion/creation action until Phase 4 hardens owner commands. Shared read ports become action-capable in that phase, so no unsafe placeholder write path is required.

## Path conventions

- Product: `lib/features/today/{domain,application,data,presentation}/`.
- Wiring/navigation/localization: `lib/app/`.
- Existing owners: `lib/features/tasks/`, `lib/features/habits/`, `lib/features/xp/`; existing completion UoW at `lib/core/data/local/task_completion_unit_of_work.dart` remains authoritative.
- Tests: `test/{support,architecture,unit,widget}/` and `integration_test/`.
- Evidence: `specs/006-today-dashboard/verification.md` (created during implementation, not claimed by this task-generation step).

## Phase 1: Setup (Shared Infrastructure)

**Goal**: Prepare reusable owner fixtures and an honest evidence baseline without changing runtime behavior.

**Independent test / checkpoint**: Existing preview/database data remains untouched; fixtures use existing owner types and every SC starts unverified.

- [X] T001 Create the implementation evidence ledger in `specs/006-today-dashboard/verification.md`, recording the current branch/SHA, FR-001..FR-020 and SC-001..SC-007, owner/preview boundaries and pending measurements; mark every unexecuted acceptance criterion unverified.
- [X] T002 Add deterministic existing-owner fixtures and small delayed-session/stream fakes in `test/support/today_fixtures.dart` for mixed dates, completed/deleted Tasks, retained Habit completions, actual awards, two accounts and the existing distinct preview IDs; keep fixture writes test-only.

**Checkpoint**: Fixtures and an unverified evidence baseline are ready; runtime behavior is unchanged.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Goal**: Establish the shared memory-only scope, calendar, source values and integration boundaries used by all stories.

**Independent test / checkpoint**: Scope binding and calendar tests pass; no new dependency, database schema, cloud endpoint or business writer is introduced.

**Blocking gate**: Finish T001–T010 before starting any story. This gate establishes contracts and isolation; owner mutation hardening belongs to US2 and must precede enabling actions.

- [X] T003 Define infrastructure-free immutable scope/calendar/reference values in `lib/features/today/domain/today_scope.dart`, `lib/features/today/domain/today_calendar.dart` and `lib/features/today/domain/today_models.dart`, preserving calendar dates, award instants, owner order and explicit per-source owner IDs.
- [X] T004 [P] Define memory-only loading/empty/available/unavailable/stale values in `lib/features/today/domain/today_section.dart`, with confirmed-value versus unknown distinction and no persisted Today history.
- [X] T005 Define the three owner read ports in `lib/features/today/application/today_tasks_port.dart`, `today_habits_port.dart` and `today_xp_port.dart`, plus the injected calendar reader in `lib/features/today/application/today_calendar_port.dart`; specify snapshot reprojection on clock changes and stream error/closure behavior without SDK types. Add guarded write capabilities only in Phase 4.
- [X] T006 [P] Add calendar adapter tests in `test/unit/features/today/data/system_today_calendar_test.dart` for local-date keys, offset changes, half-open XP boundaries and unequal-length calendar days using deterministic clocks; never equate next midnight with start plus 24 hours.
- [X] T007 Implement the calendar reader in `lib/features/today/data/system_today_calendar.dart` with independent local-midnight conversions to UTC and injectable time/calendar sampling; keep platform lifecycle outside domain/application.
- [X] T008 [P] Add scope binding tests in `test/unit/app/composition/today_scope_resolver_test.dart` for both durable preview IDs, equal real-account owner IDs, unknown/sign-out and rejection of arbitrary/mismatched real-account bindings.
- [X] T009 Implement closed scope resolution in `lib/app/composition/today_scope_resolver.dart` using existing preview sessions/constants and the real CloudSessionPort; preserve trial records without migration, copying or deletion.
- [X] T010 Add the negative-control and repository boundary scanner in `test/architecture/today_boundaries_test.dart`: only the three named Today owner adapters may import owner application/domain, and no Today code may import owner presentation/data, access tables or write awards; include relative-import bypass controls.

**Checkpoint**: Shared contracts, calendar and scope boundaries are ready; user-story implementation may begin.

---

## Phase 3: User Story 1 — Understand today's work and progress (P1, MVP)

**Goal**: Open Today directly and read truthful current-day Task/Habit summaries and actual XP, with owner navigation and preferences.

**Independent test / checkpoint**: Offline mixed-date fixtures show Tasks 4/10=40% and Habits 2/5=40% independently; retained Habit completion/streak and ledger XP match owners, empty/unavailable differ, existing preview records survive and no sign-in is requested.

### Tests and implementation

Test tasks appear before their corresponding implementation. Tasks with a test-first change inside the same task state that order explicitly.

- [X] T011 [P] [US1] Add summary/projection tests in `test/unit/features/today/domain/today_projection_test.dart` for completed-inclusive Task membership, nondeleted IDs, retained eligible Habits, independent nearest-whole percentages, zero denominators and actual award-day inclusion including deleted/reopened Tasks.
- [X] T012 [P] [US1] Add Task/XP read bridge tests in `test/unit/features/today/data/tasks_today_adapter_test.dart` and `test/unit/features/today/data/xp_today_adapter_test.dart` for account filtering, canonical order, full Task emissions and award reconciliation without estimated rewards.
- [X] T013 [P] [US1] Add Habit bridge tests in `test/unit/features/today/data/habits_today_adapter_test.dart` for both required constituent emissions, due-or-earned-retained eligibility, deleted/unscheduled exclusions and exact owner currentStreak.
- [X] T014 [P] [US1] Add read-view/Cubit/root tests in `test/unit/features/today/presentation/today_cubit_test.dart`, `test/widget/features/today/today_screen_test.dart` and `test/widget/app/today_route_test.dart` for independent sections, unknown-not-zero, direct preview, startup/recovery shells, baseline account clearing and owner/preferences reachability.
- [X] T015 [P] [US1] Add the read-only offline/restart journey in `integration_test/today_dashboard_test.dart` using encrypted owner fixtures, both existing preview IDs, mixed-date summaries and ten refreshes with zero Task/Habit/award/pending writes; leave later action/navigation journeys for their story tests.
- [X] T016 [US1] Implement independent summaries and actual daily award aggregation in `lib/features/today/domain/today_projection.dart`, retaining completed scheduled-today Tasks, eligible Habit references, null empty percentages and existing award keys; do not calculate a second streak or combined score.
- [X] T017 [P] [US1] Implement the read side of `lib/features/today/data/tasks_today_adapter.dart` via TaskRepository.watchTasks and owner TaskReviewQueries, preserving saved date/time/duration, owner sequence and current overdue membership; never use TaskRules.today as the denominator.
- [X] T018 [P] [US1] Implement the read side of `lib/features/today/data/habits_today_adapter.dart` via account-scoped habit/day watches and HabitQueries.today, emitting confirmed snapshots only after both constituents are usable and forwarding source failures.
- [X] T019 [P] [US1] Implement `lib/features/today/data/xp_today_adapter.dart` via existing AwardLedgerPort.watchAwards; expose actual UTC awards for the bound XP owner without current-Task joins, writes or a new read API.
- [X] T020 [US1] Implement `lib/features/today/presentation/today_state.dart` and the read-only TodayCubit in `lib/features/today/presentation/today_cubit.dart`, with independent subscriptions/initial response deadlines, confirmed values, source errors and baseline scope-generation clearing. No all-sources loading barrier or enabled mutation controls.
- [X] T021 [US1] Add TodayStrings in `lib/features/today/presentation/today_strings.dart`, its adapter in `lib/app/l10n/today_localization_adapter.dart` and localized read/navigation/preferences resources in `lib/app/l10n/app_ar.arb` and `lib/app/l10n/app_en.arb`; format date/count/percent/XP through the existing localization pipeline.
- [X] T022 [US1] Build the read-only responsive view in `lib/features/today/presentation/today_screen.dart` and `widgets/today_summary_section.dart`, `widgets/today_task_list.dart`, `widgets/today_habit_list.dart`: independent ratios, open/completed labels, owner streaks, actual XP and section-specific empty/loading/failure states; omit future-domain metrics and controls.
- [X] T023 [US1] Write preference interaction tests first in `test/widget/app/today_preferences_test.dart`, then provide the small app-owned language/appearance sheet in `lib/app/preferences/app_preferences_sheet.dart` using existing LocaleCubit/ThemeCubit, localized labels and focus-safe controls; preserve current preference persistence.
- [X] T024 [US1] Extend `test/unit/app/composition/configure_dependencies_test.dart` first for read-port/calendar/scoped-Cubit registration and preview/account bindings, then wire them in `lib/app/composition/configure_dependencies.dart` using the existing owner/database/session instances.
- [X] T025 [US1] Make Today the scoped ready root in `lib/app/app.dart` and `lib/app/routing/app_router.dart`, keeping Foundation startup/failure recovery, existing owner routes and preferences accessible; key the scope and reject stale initial session resolutions without adding Auth UI.

**Checkpoint**: US1 can be validated against its independent fixture after the tasks above pass. Earlier stories must keep working; the full feature is not closed until Phase 7.

---

## Phase 4: User Story 2 — Act from Today without duplicating work (P1)

**Goal**: Complete/reopen today's real Tasks, complete/undo current Habits and reuse owner creation forms with durable single-authority effects.

**Independent test / checkpoint**: Create via existing forms, complete/reopen/undo offline and inspect owners/linked Maps; repeated Task completion retains one lifetime award, Habits add no XP, stale/deleted/rescheduled actions write nothing and cancel creates nothing.

### Tests and implementation

Test tasks appear before their corresponding implementation. Tasks with a test-first change inside the same task state that order explicitly.

- [X] T026 [P] [US2] Extend `test/unit/features/tasks/application/task_completion_service_test.dart` for optional expected-day validation, midnight/account changes during delayed reads, concurrent reschedule/edit/delete, validated no-ops and unchanged all-date callers; assert zero rejected Task/award/outbox effects.
- [X] T027 [P] [US2] Extend `test/unit/features/habits/application/habit_commands_test.dart` for displayed-day mismatch and rollover during reads, fresh parent/schedule/day checks, retained-completion undo, complete-versus-undo races, identity changes and zero rejected writes.
- [X] T028 [P] [US2] Extend `test/unit/features/habits/data/drift_habit_repository_test.dart` for rollback-on-failed-result, serialized fresh reads with day+outbox writes and no partial commit; verify nested same-database transaction behavior needed by owner commands.
- [X] T029 [P] [US2] Add desired-state dispatch and pending/result tests in `test/unit/features/today/application/today_actions_test.dart` and `test/unit/features/today/presentation/today_actions_cubit_test.dart` for per-item serialization, source-disabled actions, no optimistic XP, local failure, uncertain outcomes and obsolete callbacks.
- [X] T030 [P] [US2] Add completion/create/cancel/one-shot intent widget tests in `test/widget/features/today/today_actions_test.dart` and `test/widget/app/today_creation_route_test.dart`; extend `integration_test/today_dashboard_test.dart` with ten same-day offline action/restart journeys, one Task linked in two maps, single lifetime XP and no Habit XP before enabling the UI.
- [X] T031 [US2] Harden `lib/features/tasks/application/task_completion_service.dart` with optional expectedLocalDate/injected current date and fresh Task read plus validation inside TaskRepository.runInTransaction before the existing completion UoW; recheck session/day before writing, validate no-ops and preserve all-date Tasks/Maps callers.
- [X] T032 [US2] Add rollback-on-failure runInTransaction to `lib/features/habits/application/habit_repository.dart` and `lib/features/habits/data/drift_habit_repository.dart`; update the HabitRepository fakes in `test/widget/features/habits/habit_history_view_test.dart`, `habit_edit_delete_test.dart` and `habits_screen_test.dart` so existing owner suites compile and keep their semantics.
- [X] T033 [US2] Harden completeHabitToday/undoHabitToday in `lib/features/habits/application/habit_commands.dart` with optional expectedLocalDate and fresh parent/day reads inside the owner transaction; recheck calendar/session, prevent stale schedule/day overwrite and preserve retained undo, recorded dates/offsets and no-write failures.
- [X] T034 [US2] Add guarded desired-state action capabilities to `lib/features/today/application/today_tasks_port.dart` and `today_habits_port.dart`, and implement `lib/features/today/application/today_actions.dart` with expected owner/day and entity ID. Keep persistence, eligibility and rewards in owners; add no Today outbox or reward command.
- [X] T035 [P] [US2] Connect the Task write bridge in `lib/features/today/data/tasks_today_adapter.dart` to guarded TaskCompletionService and existing TaskSyncService after local success, without awaiting connectivity; extend its bridge tests before the write implementation.
- [X] T036 [P] [US2] Connect the Habit write bridge in `lib/features/today/data/habits_today_adapter.dart` to guarded HabitCommands and existing HabitSyncService; retain unscheduled completion undo and remove its eligibility after the owner emission, with bridge tests written first.
- [X] T037 [US2] Implement per-item desired-state pending handling and failure feedback in `lib/features/today/presentation/today_cubit.dart` and `today_state.dart`: revalidate displayed scope/day, suppress duplicate taps, preserve latest confirmed concurrent state and ignore obsolete results; never replay a write because an observer timed out.
- [X] T038 [US2] Add action/pending/stale-date/local-save failure and semantic resources in `lib/features/today/presentation/today_strings.dart`, `lib/app/l10n/today_localization_adapter.dart`, `lib/app/l10n/app_ar.arb` and `app_en.arb`, reusing existing owner failure meanings.
- [X] T039 [US2] Enable labeled complete/reopen and Habit complete/undo controls in `lib/features/today/presentation/widgets/today_task_list.dart` and `today_habit_list.dart`; disable only unsafe/pending controls and show success only after owner persistence, without optimistic rewards or all-date priority toggles.
- [X] T040 [US2] Define validated one-shot owner entry intents in `lib/app/routing/owner_entry_intent.dart` and route transport/consumption in `lib/app/routing/app_router.dart`; reject arbitrary owners/business payloads and keep normal Tasks/Habits/Maps navigation.
- [X] T041 [P] [US2] Consume new-Task intent once after owner readiness in `lib/features/tasks/presentation/tasks_screen.dart` using existing TaskEditor in `lib/features/tasks/presentation/task_editor.dart`; default to current date when the form opens, preserve explicit selections across midnight and create nothing on cancel/rebuild.
- [X] T042 [P] [US2] Consume new-Habit intent once after owner readiness in `lib/features/habits/presentation/habits_screen.dart` using existing `lib/features/habits/presentation/habit_editor.dart`; preserve owner validation and cancel behavior without duplicating a form.
- [X] T043 [US2] Wire new-Task/new-Habit quick actions in `lib/features/today/presentation/today_screen.dart` and app-owned navigation callbacks in `lib/app/routing/app_router.dart`; return to the same current Today scope and reflect saved owner records once.
- [X] T044 [US2] Complete guarded command/calendar/action dependency wiring in `lib/app/composition/configure_dependencies.dart`; run affected owner, bridge, creation and offline tests including existing Task/XP/Maps completion regressions, and record results/remaining criteria in `specs/006-today-dashboard/verification.md`.

**Checkpoint**: US2 can be validated against its independent fixture after the tasks above pass. Earlier stories must keep working; the full feature is not closed until Phase 7.

---

## Phase 5: User Story 3 — Keep a trustworthy view across time and connectivity (P1)

**Goal**: Maintain the correct local day and identity through foreground/resume, partial source failures, retry, offline restart and existing synchronization.

**Independent test / checkpoint**: With fake clocks and delayed sources, refresh foreground day <=1 minute/resume <=2 seconds, reject stale-day saves, recover a hung source <=10 seconds without blocking others and show zero foreign values; verify real two-device convergence and date-specific views.

### Tests and implementation

Test tasks appear before their corresponding implementation. Tasks with a test-first change inside the same task state that order explicitly.

- [x] T045 [P] [US3] Add deterministic lifecycle/zone tests in `test/unit/features/today/presentation/today_lifecycle_test.dart` for foreground checks <=30 seconds, midnight, resume, clock/offset changes, DST boundaries, stale action callbacks and unchanged recorded owner dates.
- [x] T046 [P] [US3] Add recovery tests in `test/unit/features/today/presentation/today_recovery_test.dart` for each hanging source and Habit constituent, <=10-second initial deadline, errors/done, marked same-day stale values, safe retries, old-attempt emissions and healthy quiet streams.
- [x] T047 [P] [US3] Extend `test/widget/app/today_route_test.dart` for delayed initial lookup and A -> B -> preview -> unresolved/sign-out transitions, including pending actions/old stream callbacks; capture zero foreign lists/counts/XP/feedback and a bounded session-recovery state.
- [x] T048 [P] [US3] Add actual owner-sync acceptance scenarios in `integration_test/today_sync_test.dart` for isolated account sessions on two devices, same-date convergence, different date/zone projection, account isolation and actual award reconciliation; extend `integration_test/today_dashboard_test.dart` for offline restart/lifecycle/failure journeys before lifecycle hardening.
- [x] T049 [US3] Implement clock reprojection and a cancelable injected foreground scheduler in `lib/features/today/presentation/today_cubit.dart`, using `lib/features/today/application/today_calendar_port.dart` and `lib/features/today/data/system_today_calendar.dart`; resample on entry/resume/source events/before actions, compare date/offset <=30 seconds and preserve owner calendar records.
- [x] T050 [US3] Finish per-source attempt/deadline/retry/stale handling in `lib/features/today/presentation/today_cubit.dart` and `today_state.dart`, retaining same-scope/day confirmed data only, rejecting late attempts, handling unexpected closure and never treating quiet healthy streams as failed.
- [x] T051 [US3] Harden paired Habit snapshot failure/recovery and subscription disposal in `lib/features/today/data/habits_today_adapter.dart`; extend `tasks_today_adapter.dart` and `xp_today_adapter.dart` disposal/error paths only where the recovery tests expose a gap, with no cloud observation loop.
- [x] T052 [US3] Complete synchronous scope invalidation and revision-protected root/session resolution in `lib/app/routing/app_router.dart` and `lib/features/today/presentation/today_cubit.dart`, clearing all old values and pending messages before new bindings and bounding unresolved-session recovery.
- [x] T053 [US3] Connect WidgetsBindingObserver foreground/pause/resume/dispose callbacks in `lib/features/today/presentation/today_screen.dart` to the Cubit lifecycle, cancel replaced work and revalidate current date before date-sensitive interactions.
- [x] T054 [US3] Finish localized loading/unavailable/outdated/retry semantics and disabled unsafe actions in `lib/features/today/presentation/widgets/today_summary_section.dart`, `today_task_list.dart`, `today_habit_list.dart`, `lib/app/l10n/app_ar.arb`, `app_en.arb` and `today_localization_adapter.dart`; leave healthy sources usable.
- [x] T055 [US3] Run the targeted lifecycle, partial-failure, account-switch and offline/restart scenarios from `integration_test/today_dashboard_test.dart` and the new unit/widget tests; record measured recovery/update bounds, zero-write refreshes and unchanged history in `specs/006-today-dashboard/verification.md`.
- [x] T056 [US3] Execute `integration_test/today_sync_test.dart` against existing isolated test-session facilities on two device sessions; record actual devices, same/different local-date convergence, <=2-second local-arrival updates and zero duplicates/foreign data in `specs/006-today-dashboard/verification.md`. Missing device/credential evidence remains unverified, never a mocked pass.

**Checkpoint**: US3 can be validated against its independent fixture after the tasks above pass. Earlier stories must keep working; the full feature is not closed until Phase 7.

---

## Phase 6: User Story 4 — Find the next action and move to its owner (P2)

**Goal**: Show a truthful timed/untimed agenda, bounded Do First preview and owner-equivalent overdue navigation.

**Independent test / checkpoint**: Mixed-date timed/untimed/tied/overlapping fixtures retain owner order and identity; Do First contains only up to three incomplete urgentImportant Tasks today or overdue; future-only Tasks are excluded, expired-deadline future Tasks qualify without changing today's denominator, and links open the correct owner view.

### Tests and implementation

Test tasks appear before their corresponding implementation. Tasks with a test-first change inside the same task state that order explicitly.

- [ ] T057 [P] [US4] Add agenda/priority projection tests in `test/unit/features/today/domain/today_agenda_test.dart` and `today_priority_test.dart` for canonical tie order, untimed separation, max-three eligibility, future-deadline exception, overdue equivalence, deleted/completed exclusions and map-link deduplication.
- [ ] T058 [P] [US4] Add agenda/priority/overdue widget tests in `test/widget/features/today/today_agenda_priority_test.dart` for saved times/durations/dates, no invented activity/time, source-health consistency, visible labels and navigation-only other-date references.
- [ ] T059 [P] [US4] Add matrix/overdue entry and return-navigation scenarios in `test/widget/app/today_owner_navigation_test.dart` and `integration_test/today_dashboard_test.dart`, proving one-shot intent consumption and current owner data after edits or map-linked Task completion.
- [ ] T060 [P] [US4] Implement stable timed/untimed agenda projection in `lib/features/today/domain/today_agenda.dart` from distinct scheduled-today Task references, retaining saved estimates/completion and never rescheduling overlaps or assigning missing times.
- [ ] T061 [P] [US4] Implement Do First/overdue projection in `lib/features/today/domain/today_priority.dart`, using current owner overdue flags and canonical order: incomplete urgentImportant AND (today OR overdue), at most three; keep all-date overdue count separate from today's denominator.
- [ ] T062 [US4] Build agenda presentation in `lib/features/today/presentation/widgets/today_agenda_section.dart` with timed/untimed groups, saved duration, completion distinction and accessible references to the same owner Tasks.
- [ ] T063 [US4] Build the bounded priority/overdue widgets in `lib/features/today/presentation/widgets/today_priority_section.dart` and `today_overdue_section.dart`, showing dates, matrix/overdue links, shared Task health and navigation-only other-date entries.
- [ ] T064 [US4] Implement matrix/overdue intent handling in `lib/app/routing/app_router.dart` and `lib/features/tasks/presentation/tasks_screen.dart` using existing TasksCubit showMatrix/filter commands; preserve normal owner editing and return navigation instead of copying owner filters into Today UI.
- [ ] T065 [US4] Integrate agenda/priority/overdue into `lib/features/today/presentation/today_screen.dart` and `today_cubit.dart`, including current-instant overdue refresh without record changes; add AR/EN strings in `lib/app/l10n/app_ar.arb`, `app_en.arb`, `today_localization_adapter.dart` and `lib/features/today/presentation/today_strings.dart`, then validate the story independently.

**Checkpoint**: US4 can be validated against its independent fixture after the tasks above pass. Earlier stories must keep working; the full feature is not closed until Phase 7.

---

## Phase 7: Polish & Cross-Cutting Verification

**Goal**: Produce measured acceptance evidence, complete five-target verification and preserve the existing efficient CI policy.

**Independent test / checkpoint**: Every SC has actual evidence, architecture/localization/owner regressions pass and the complete required CI gate succeeds on the final integration SHA. A focused diagnostic run is not the closing gate.

- [ ] T066 [P] Add the test-only scale/timing scenario in `integration_test/today_performance_test.dart` with exactly 500 local Tasks, 100 Habits and 200 actual awards, owner-derived fixtures and explicit first-render/local-action timing boundaries; keep production Today free of seeding/benchmark controls.
- [ ] T067 Measure the scale scenario on one mobile and one desktop target, recording device/OS/build mode, fixture counts, start/end definitions and <=2-second initial/action/update results in `specs/006-today-dashboard/verification.md`; optimize only an observed bottleneck and rerun the affected measurement.
- [ ] T068 Execute Arabic/English touch and keyboard-only journeys on mobile/desktop per `specs/006-today-dashboard/quickstart.md`, including <=3-minute scripted flows, semantics/focus, long mixed titles, narrow layout and increased text scale; record outcomes and fix concrete failures in `lib/features/today/presentation/` and `lib/app/l10n/`.
- [ ] T069 [P] Extend the runner-selection/setup regression tests in `.github/scripts/tests/test_mobile_runners.py` and `.github/scripts/tests/test_ci_setup.py` for the planned Today suite names before changing CI registration; preserve existing negative controls and verified native harness assertions.
- [ ] T070 Register compact Today dashboard/sync suites and the 006 document path in `.github/workflows/foundation-ci.yml`, `.github/scripts/run-android-integration.sh` and `.github/scripts/run-ios-integration.py`, plus existing desktop test lists, then run T069's affected checks. Preserve PR-to-develop/manual triggers, focused selection, XCTest signing, port safeguards and full foundation-gate; add no push trigger or performance job matrix.
- [ ] T071 Audit Today against all nine constitutional principles and run meaningful boundaries/client-secret checks in `test/architecture/today_boundaries_test.dart`, `domain_dependency_test.dart` and `client_secret_scan_test.dart`; verify existing encrypted owner storage, no duplicate writers/sync and no future-domain fabricated obligations.
- [ ] T072 Run localization generation, format verification, static analysis and the affected Today/owner/composition/widget regressions specified in `specs/006-today-dashboard/quickstart.md`; record commands/results in `specs/006-today-dashboard/verification.md` and stop optional repeated tests once the changed risks are covered.
- [ ] T073 Reconcile SC-001..SC-007 evidence and runnable paths in `specs/006-today-dashboard/verification.md` and `quickstart.md` before final integration, including two-device results, ten offline journeys, zero-write refreshes and mobile/desktop measurements; leave missing criteria pending instead of weakening them.
- [ ] T074 At the authorized integration stage, run/verify the complete existing required gate from `.github/workflows/foundation-ci.yml` on the final 006 head: quality, database/RLS, both Android groups, all required iOS suites including Today, Windows/macOS/Linux and foundation-gate; read failure logs and retry only failed/cancelled jobs on the same SHA when appropriate.
- [ ] T075 Complete the acceptance/closure review in `specs/006-today-dashboard/verification.md` and `tasks.md` using actual same-head check URLs/SHA and all story checkpoints; require every acceptance criterion and final gate to pass before closing. Preserve final check evidence without a documentation-only commit/retest loop, and perform push/merge only when authorized for 006.

**Checkpoint**: All story and acceptance evidence is verified, with the full required same-head gate; closing or merging still follows the user's integration authorization.

---

## Dependencies & Execution Order

### Phase and story graph

~~~text
Phase 1: T001-T002
    |
Phase 2: T003-T010 (shared blocking gate)
    |
US1 / Phase 3: T011-T025 (read-only MVP)
    |------------------------------|
US2 / Phase 4: T026-T044         US4 projection/test work may start
    |                           after US1, on disjoint files
US3 / Phase 5: T045-T056            |
    |------------------------------|
US4 / Phase 6: T057-T065 (integrate owner intents/UI after US2/US3)
    |
Phase 7: T066-T075 (acceptance and final integration gate)
~~~

Default delivery is sequential Phases 1 through 7. US3's pending-action and two-device journeys require US2. US4's pure projection/test work depends only on the shared contracts/US1; its final route/UI integration depends on US2's entry intents and US3's current-clock/source-health behavior. No story is falsely described as independent of these shared capabilities; each has its own runnable acceptance fixture once prerequisites are met.

### Task prerequisites and safe parallel cohorts

| Cohort / task | Prerequisite and ordering constraint |
|---|---|
| T001, T002 | Setup; separate evidence and fixture files. |
| T003 and T004 | After Setup; plain values and generic source-health value are disjoint. |
| T005 | After T003/T004; define the actual source/calendar interfaces. |
| T006 -> T007 | Calendar tests before system reader implementation; after T005. |
| T008 -> T009 | Scope tests before resolver implementation; after T003. This pair can proceed alongside T006/T007. |
| T010 | After contracts exist; scanner must recognize only named bridges and reject bypass fixtures. |
| T011-T015 | After all shared tasks; five independent test files/groups can be authored in parallel. Existing fixtures are read-only inputs. |
| T016 | After projection tests; establish independent summary rules. |
| T017, T018, T019 | After their read bridge tests and shared ports; three disjoint adapters can proceed in parallel. |
| T020 | After T016-T019; compose independent confirmed sources, baseline deadline/error handling and scope clearing. |
| T021 -> T022 | Localization/strings before localized summary/list widgets. |
| T023 | Preference tests before small app sheet; serialize with any ARB/app edits. |
| T024 -> T025 | Composition tests/wiring before root hookup; root tests already authored in T014. |
| T026-T030 | After US1; separate owner, transaction, action and route/integration tests. |
| T031 | Task command tests first; existing owner transaction and completion UoW remain the write authority. |
| T032 -> T033 | Habit rollback primitive/fakes before guarded Habit commands. T031 may run alongside this pair on disjoint files. |
| T034 | Guarded owner methods ready before exposing Today command capabilities. |
| T035, T036 | After T031-T034 and bridge tests; Task/Habit write adapters are independent. |
| T037 -> T038 -> T039 | Action state, localized feedback and row controls; serialize shared Cubit/strings/widget edits. |
| T040 -> T041 / T042 -> T043 | Typed routing intent first; Task and Habit owner consumption can proceed in parallel, then quick-action integration. |
| T044 | All US2 pieces ready; final composition and affected cross-domain checks. |
| T045-T048 | After US2; independent lifecycle, recovery, identity and sync test groups. |
| T049 -> T050 -> T051 -> T052 -> T053 -> T054 | Serialize lifecycle/recovery/invalidation/UI edits; these tasks overlap shared files and are not independent. |
| T055, T056 | After US3 implementation; focused local cases first and actual isolated two-device evidence, without a broad new CI run. |
| T057-T059 | US4 acceptance tests; after shared/US1 contracts, with route integration evaluated after US2/US3. |
| T060, T061 | Projection tests first; separate agenda and priority files can be implemented in parallel. |
| T062, T063 | After their projections, strings contract and widget tests; separate widgets, then serialize integration in T064/T065. |
| T064 -> T065 | Owner intent handling followed by localized final screen/Cubit integration; no concurrent app-router/ARB edits. |
| T066, T069 | After all stories; independent performance test and runner-regression test authoring. |
| T067 | After T066; actual mobile/desktop measurements. |
| T068 | Stable final UI; avoid competing for the same physical devices while measuring T067. |
| T070 | After T069; implement suite registration and run affected runner checks. |
| T071 -> T072 -> T073 | Architecture/security audit, static/relevant regressions, then reconcile evidence before final integration SHA. |
| T074 -> T075 | Full gate on final authorized head, then acceptance/closure audit. No head-changing documentation-only retest cycle. |

[P] is conditional on these prerequisites; it never permits simultaneous edits to the same file. Shared ARBs, app_router.dart, configure_dependencies.dart, TodayCubit and verification.md are integration points and must be edited sequentially.

## Parallel Examples by User Story

### US1

- After T005 and the test cohort, implement T017 (Task reader), T018 (Habit reader) and T019 (XP reader) on their separate adapter files.
- T011 projection tests and T013 Habit bridge tests use different files and can be authored together.
- Integrate once in T020/T024/T025; do not have multiple workers modify the Cubit or root simultaneously.

### US2

- Author T026 Task guard tests, T027 Habit command tests and T028 Habit repository rollback tests in parallel.
- After guarded owners and T034, T035 and T036 can implement separate write bridges.
- After T040, T041 and T042 can consume owner intents independently; T043 owns the shared routing integration.

### US3

- Author T045 lifecycle tests and T046 recovery tests in parallel; T047 covers the root gate separately.
- Keep implementation T049-T054 sequential because lifecycle, source health and identity share the same state/route files.
- Run device validation only once the corresponding implementation is ready; evidence writes remain sequential.

### US4

- Author T057 pure projections and T058 widget expectations in parallel.
- Implement T060 agenda rules and T061 priority rules on separate files, then T062/T063 widgets after their respective prerequisites.
- Integrate routes, strings and the screen in T064/T065 sequentially.

These are scheduling options, not a request to spawn agents.

## Requirement and Acceptance Traceability

| Requirement | Primary implementation / proof |
|---|---|
| FR-001 | T008-T009, T014, T023-T025: gated root/direct preview, preserved owner navigation/preferences. |
| FR-002 | T011-T012, T016-T017, T020-T022: completed-inclusive scheduled-day Task set. |
| FR-003 | T011, T013, T016, T018, T022: eligible Habits and owner streaks, retained completion. |
| FR-004 | T011, T016, T021-T022: separate rounded ratios, explicit empty/unknown. |
| FR-005 | T011-T012, T016, T019: actual ledger/time boundaries, deletion/reopen/reconciliation. |
| FR-006 | T026, T029-T031, T034-T035, T037-T039, T044: same Task and one lifetime XP. |
| FR-007 | T027-T028, T032-T033, T036-T039: current-day Habit complete/retained undo, no XP. |
| FR-008 | T030, T040-T043: existing owner forms, date defaults, cancel and one-shot intents. |
| FR-009 | T057-T058, T060, T062, T065: timed/untimed agenda, stable saved values. |
| FR-010 | T057-T059, T061, T063-T065: today-or-overdue urgentImportant limit/order/date/matrix. |
| FR-011 | T017, T045, T049, T057, T061, T063-T065: owner-equivalent overdue and advancing instant. |
| FR-012 | T006-T007, T026-T027, T031-T033, T045, T049, T053, T055: calendar/resume and owner save guards. |
| FR-013 | T015, T017-T020, T030, T048, T055-T056, T059: owner/linked Map/inbound updates and deduplication. |
| FR-014 | T015, T026-T044, T048, T055-T056: offline durability, atomic saves and safe failure/retry. |
| FR-015 | T008-T010, T014, T024-T025, T029, T047, T052, T056: scope binding, clearing and late callbacks. |
| FR-016 | T004, T013-T014, T020, T046, T050-T054: independent loading/empty/stale/recovery/deadlines. |
| FR-017 | T022, T065, T071: no future obligations, fake metrics or new score/targets. |
| FR-018 | T021-T023, T030, T038-T039, T054, T058, T062-T065, T068: AR/EN, RTL, semantics/focus/input. |
| FR-019 | T003-T010, T017-T019, T031-T036, T048, T071: owner boundaries, zero duplicate storage/sync/history. |
| FR-020 | T022, T039, T043, T062-T065, T068-T070, T074-T075: functional overview/five-target parity, visual refinement deferred. |

| Success criterion | Evidence tasks / exact acceptance |
|---|---|
| SC-001 | T011-T019, T025, T057-T065: fixture matches owners 100%, both 40% examples, retained eligibility, agenda/priority/overdue/XP. |
| SC-002 | T066-T067: 500 Tasks/100 Habits/200 awards, <=2-second initial/action display on an actual mobile and desktop. |
| SC-003 | T015, T026-T044, T055: ten same-date offline action/restart/sync journeys, one lifetime Task award/no Habit XP, ten refreshes with zero business writes. |
| SC-004 | T006-T007, T026-T027, T045, T049, T053, T055: foreground <=1 minute, resume <=2 seconds, zones, stale-day rejection and history stability. |
| SC-005 | T014, T046-T047, T050-T055: failed/hanging source <=10 seconds, recovery <=2 seconds, healthy sections usable, zero foreign content. |
| SC-006 | T030, T054, T058-T059, T068, T070, T074: actual AR/EN mobile/desktop, touch/keyboard <=3-minute journeys, five-target owner/offline parity. |
| SC-007 | T048, T056, T070, T074: actual isolated two-device same/different-date convergence, no duplicate awards/map-linked counts and unchanged underlying dates. |

## Implementation Strategy

### MVP first

Complete Phases 1-2, then US1 (T011-T025). Demonstrate direct offline preview with two truthful progress summaries, owner Habit streaks, actual daily XP, owner links and preferences. This read-only checkpoint is useful for immediate trial and deliberately does not claim that actions, lifecycle acceptance or the whole feature are finished.

### Incremental delivery

1. US1: read-only Today and source ownership.
2. US2: transactional owner actions and existing creation forms.
3. US3: full lifecycle/recovery/identity and two-device evidence.
4. US4: agenda, priority and precise owner navigation.
5. Phase 7: measured performance/accessibility, registered platform suites and final complete gate.

At every checkpoint run the smallest meaningful affected checks and record evidence. A phase commit/push is a separate authorized action; it does not imply a five-device run. Full CI is reserved for the approved integration gate or a necessary explicit diagnostic run.

### Definition of completion

All 75 tasks are specific implementation/validation work, not evidence that execution has happened. Every story checkpoint, all seven success criteria, relevant owner/localization/security regressions and the final same-head required gate must pass before closing 006. Missing native/device/credential/timing evidence stays pending with its exact limitation. Do not weaken assertions, silently waive a criterion, add Auth or a second database, or launch automatic repeated CI from this task list.
