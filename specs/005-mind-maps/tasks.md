---
description: "Dependency-ordered implementation tasks for Namaa Mind Maps 005"
---

# Tasks: Namaa Mind Maps 005

**Input**: specs/005-mind-maps/spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md, and .specify/memory/constitution.md

**Scope**: One Flutter Mind Maps feature on Android, iOS, Windows, macOS, and Linux. Reuse Foundation's encrypted local store and account sync, the existing Tasks preview identity, and Tasks' completion/XP authority. Authentication and final visual redesign remain later features.

## Format: [ID] [P?] [Story] Description

- [P] means the task can run alongside other marked tasks after its phase prerequisites: separate files and no unfinished dependency between them.
- [US1]–[US5] map exactly to the five stories in specs/005-mind-maps/spec.md. Paths are repository relative.
- Tests are explicit because the spec defines independent tests/SC-001–SC-007 and the constitution requires meaningful domain, widget, integration, and security evidence. Add each story's tests before its implementation and observe the missing-behavior failure; make them pass by the story checkpoint.
- A task is complete only when its behavior is implemented and its relevant tests pass. Do not run the five-target CI matrix on every feature-branch push.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ground 005 in the existing Foundation, Tasks, Habits and preview seams without creating a second stack.

- [ ] T001 Record the actual v4 Drift tables/migration, Tasks completion/XP APIs, preview owner identity, route gates, sync dispatch/reconciliation and current CI triggers in specs/005-mind-maps/implementation-baseline.md.
- [ ] T002 Build deterministic owner/map/node/edge/Task IDs, UTC clocks, 50-node/60-link graphs, failing-store and switched-session fixtures in test/support/mind_maps_test_support.dart.

**Checkpoint**: Implementation has reproducible graph/account fixtures and a verified reuse boundary.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add protected, independently addressable graph records before any story writes them. This phase blocks US1–US5.

- [ ] T003 Test additive encrypted v4→v5 upgrade, owner-qualified graph keys/indexes, the Tasks completion-transition baseline, retained Foundation/Task/Habit/XP/outbox data and recoverable migration failure in test/unit/core/data/local/mind_maps_migration_test.dart.
- [ ] T004 Add map, node, parent-slot and side-link tables with owner-qualified identities/indexes plus the Tasks-owned completion-transition column and additive v4→v5 migration in lib/core/data/local/foundation_database.dart.
- [ ] T005 Regenerate Drift schema output in lib/core/data/local/foundation_database.g.dart and make test/unit/core/data/local/mind_maps_migration_test.dart pass without resetting old account data.
- [ ] T006 [P] Define immutable MindMap/settings and MindMapNode identities, validation, versions and tombstones in lib/features/mind_maps/domain/mind_map.dart and lib/features/mind_maps/domain/mind_map_node.dart.
- [ ] T007 [P] Define one ParentSlot per child and canonical unordered SideLink identities, appearance, versions and tombstones in lib/features/mind_maps/domain/map_connection.dart.
- [ ] T008 Encode/decode all four graph record types with stable IDs, settings, Task references, versions and tombstones in lib/features/mind_maps/data/map_payload_codec.dart.

**Checkpoint**: Existing encrypted installations migrate safely; every map element has an independent owner-scoped sync identity.

---

## Phase 3: User Story 1 — Organize maps (P1) 🎯 MVP

**Goal**: Create, find, rename, describe, duplicate, open and confirm-delete maps in the local preview; new maps have a protected central node.

**Independent Test**: In debug preview create two maps, search title/description, rename one, duplicate a seeded map with nodes/connections/Task ID, delete one after confirmation, restart offline and confirm the copy has new map-owned IDs while its Task ID is unchanged. Blank titles fail without modifying saved data.

### Tests for User Story 1 — write first

- [ ] T009 [P] [US1] Test title validation, central-node creation/protection, map settings defaults, copy ID remapping and Task ID preservation in test/unit/features/mind_maps/domain/mind_map_model_test.dart.
- [ ] T010 [P] [US1] Test atomic map+central-node create, rename, duplicate full graph, confirmed tombstone, owner isolation, restart and rollback on failed local save in test/unit/features/mind_maps/data/drift_map_repository_test.dart.
- [ ] T011 [P] [US1] Test empty library versus empty search results, case-insensitive title/description search, counts/progress, create/rename/delete confirmation and localized errors in test/widget/features/mind_maps/map_library_screen_test.dart.
- [ ] T012 [P] [US1] Add a preview create/search/duplicate/delete/offline-restart journey in integration_test/mind_maps_library_test.dart; seed child graph and Task references until US2/US3 editor controls exist.

### Implementation for User Story 1

- [ ] T013 [US1] Define owner-scoped graph reads, atomic local mutation/outbox writes and watch streams in lib/features/mind_maps/application/map_repository.dart.
- [ ] T014 [US1] Implement create, rename, describe, duplicate and delete commands with current-session checks, validation, ID remapping and typed failures in lib/features/mind_maps/application/map_commands.dart.
- [ ] T015 [US1] Persist complete copied graphs and map/central-node commands atomically with PendingChanges and tombstones in lib/features/mind_maps/data/drift_map_repository.dart.
- [ ] T016 [US1] Derive live map search, node/completed counts and whole-percent summaries without a second canonical counter in lib/features/mind_maps/application/map_queries.dart.
- [ ] T017 [P] [US1] Add English map-library, search, create/rename/delete, confirmation and save-failure messages in lib/app/l10n/app_en.arb.
- [ ] T018 [P] [US1] Add matching Arabic map-library, search, create/rename/delete, confirmation and save-failure messages in lib/app/l10n/app_ar.arb.
- [ ] T019 [US1] Regenerate lib/app/l10n/generated/app_localizations.dart and adapt the new messages through lib/app/l10n/mind_maps_strings_adapter.dart and lib/features/mind_maps/presentation/mind_maps_strings.dart.
- [ ] T020 [US1] Implement owner-bound library loading, search, confirmed local commands, account switching and recoverable errors in lib/features/mind_maps/presentation/map_library_cubit.dart and lib/features/mind_maps/presentation/map_library_state.dart.
- [ ] T021 [US1] Build the responsive, accessible map library/create/edit screen and a basic central-node detail view in lib/features/mind_maps/presentation/map_library_screen.dart and lib/features/mind_maps/presentation/map_detail_screen.dart.
- [ ] T022 [US1] Register the local map repository/Cubit using the existing Tasks preview session identity and isolate it from real accounts in lib/app/composition/configure_dependencies.dart.
- [ ] T023 [US1] Add a session-gated /mind-maps route and visible navigation entry, with debug preview entry and release sign-in gate, in lib/app/routing/app_router.dart and lib/app/app.dart.

**Checkpoint**: US1 passes local, widget and preview restart tests without a network or new Auth flow. A copied graph's map-owned IDs are independent even before the full editor is built.

---

## Phase 4: User Story 2 — Build and track an idea graph (P1)

**Goal**: Edit five node kinds, parent branches and visual side links, move and delete nodes safely, derive progress and undo/redo map-owned edits.

**Independent Test**: Add central/main/branch/task/note nodes, connect/disconnect and reparent a branch with descendants, reject cycles/duplicate pairs, change statuses/positions, delete a noncentral parent and restart offline. All child content survives; progress includes the central node; undo/redo never changes a Task.

### Tests for User Story 2 — write first

- [ ] T024 [P] [US2] Test one-parent, self/cycle, canonical side-pair, cross-map and parent/side duplicate rejection plus detach/reparent/delete invariants in test/unit/features/mind_maps/domain/map_graph_rules_test.dart.
- [ ] T025 [P] [US2] Test add/edit/move/delete/reparent/side-link connect/disconnect graph commands, blank node names, central protection, owner checks and failed-save rollback in test/unit/features/mind_maps/application/map_graph_commands_test.dart.
- [ ] T026 [P] [US2] Test central-inclusive counts, unlinked statuses, whole-percent rounding and live-node filtering in test/unit/features/mind_maps/application/map_progress_test.dart.
- [ ] T027 [P] [US2] Test session undo/redo of node, relationship, position and settings commands with stale-version rejection and zero Task/XP writes in test/unit/features/mind_maps/application/map_editor_history_test.dart.
- [ ] T028 [P] [US2] Test labeled node/connection/reparent/delete/status controls, validation and progress updates in test/widget/features/mind_maps/map_editor_screen_test.dart.
- [ ] T029 [P] [US2] Add graph edit, detach/reparent, node delete, undo/redo and offline-restart journey in integration_test/mind_maps_editor_test.dart.

### Implementation for User Story 2

- [ ] T030 [US2] Implement acyclic parent traversal, same-map endpoint checks, unique visible pair and child-detach rules in lib/features/mind_maps/domain/map_graph_rules.dart.
- [ ] T031 [US2] Implement node add/edit/move/status/delete and parent/side-link connect, disconnect and reparent commands in lib/features/mind_maps/application/map_graph_commands.dart.
- [ ] T032 [US2] Extend atomic graph mutations/outbox writes and incident-edge/child-detach tombstones in lib/features/mind_maps/data/drift_map_repository.dart.
- [ ] T033 [US2] Add graph and progress projections, including central node and current live relationships, in lib/features/mind_maps/application/map_queries.dart.
- [ ] T034 [US2] Implement bounded current-session reversible map commands with version checks and no Task/XP snapshots in lib/features/mind_maps/application/map_editor_history.dart.
- [ ] T035 [US2] Add graph selection, confirmed edits, progress, undo/redo and recoverable errors to lib/features/mind_maps/presentation/map_editor_cubit.dart and lib/features/mind_maps/presentation/map_editor_state.dart.
- [ ] T036 [P] [US2] Render nodes and role-distinct connections with selection/focus and repaint-aware edge painting in lib/features/mind_maps/presentation/map_canvas.dart.
- [ ] T037 [P] [US2] Build localized node title/description/kind/status/priority editing and validation in lib/features/mind_maps/presentation/map_node_editor.dart.
- [ ] T038 [US2] Add visible connect/disconnect/reparent/delete, move and undo/redo controls to lib/features/mind_maps/presentation/map_editor_screen.dart and open it from lib/features/mind_maps/presentation/map_detail_screen.dart.
- [ ] T039 [US2] Add Arabic/English node, relationship, status, progress, undo/redo and graph-error strings in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb; regenerate lib/app/l10n/generated/app_localizations.dart and extend lib/app/l10n/mind_maps_strings_adapter.dart.

**Checkpoint**: US2 works offline after restart, preserves child branches and shows correct progress; all required edits have visible labeled controls.

---

## Phase 5: User Story 3 — Work with real Tasks from a map (P1)

**Goal**: Link accessible existing Tasks, complete/reopen through Tasks' authority and show consistent state with exactly one lifetime Task XP award.

**Independent Test**: Link the same Task in two maps, complete from one map, reopen in Tasks, mark in progress, complete from the other map, restart/sync and verify one award. Missing/deleted/foreign Task links reveal no Task details and can be repaired.

### Tests for User Story 3 — write first

- [ ] T040 [P] [US3] Test Tasks-owned completion-transition revision migration and changes only on complete/reopen, not title edits, in test/unit/features/tasks/domain/task_completion_test.dart.
- [ ] T041 [P] [US3] Test Task-link bridge account checks, initial-sync picker gate, multi-node projection, unavailable links, repeated completion/reopening and one lifetime XP award in test/unit/features/mind_maps/application/map_task_link_test.dart.
- [ ] T042 [P] [US3] Test linked completed/open/in-progress/reopened progress, missing/deleted/foreign Task privacy and unlinked task-kind nodes in test/unit/features/mind_maps/application/map_task_progress_test.dart.
- [ ] T043 [P] [US3] Test accessible Task chooser, link/unlink/relink, unavailable badge and complete/reopen states in test/widget/features/mind_maps/map_task_link_test.dart.
- [ ] T044 [P] [US3] Add two-map/one-Task completion, Tasks-area reopening, repeated completion, preview restart and XP ledger journey in integration_test/mind_maps_task_link_test.dart.
- [ ] T045 [P] [US3] Test cloud Task completion-transition field migration, owner isolation and replay with no extra XP in supabase/tests/mind_maps_task_transition_test.sql.

### Implementation for User Story 3

- [ ] T046 [US3] Add Tasks-owned completionChangedAt to Task restore/copy/complete/reopen behavior in lib/features/tasks/domain/task.dart and update lib/features/tasks/application/task_completion_service.dart without changing one-time XP authority.
- [ ] T047 [US3] Persist and restore completionChangedAt through the existing Task local repository in lib/features/tasks/data/drift_task_repository.dart and its Task payload codec in lib/features/tasks/data/task_payload_codec.dart.
- [ ] T048 [US3] Add a nullable/defaulted Tasks completion-transition column and owner-safe Task sync compatibility in supabase/migrations/0008_task_completion_transition.sql.
- [ ] T049 [US3] Carry the Tasks-owned transition revision through outbound/inbound Task sync in lib/features/tasks/data/supabase_task_sync_adapter.dart and lib/features/tasks/data/supabase_task_reader.dart.
- [ ] T050 [US3] Define accessible Task projections and complete/reopen operations behind MapTaskLinkPort in lib/features/mind_maps/application/map_task_link_port.dart.
- [ ] T051 [US3] Implement the bridge with TaskRepository, TaskCompletionService and TaskSyncService, rechecking the owner and gating authenticated picker on initial Task sync, in lib/features/mind_maps/data/tasks_map_link_adapter.dart.
- [ ] T052 [US3] Implement link/unlink/relink commands that validate a new accessible Task but preserve an existing unavailable ID on unrelated map edits in lib/features/mind_maps/application/map_task_link_commands.dart.
- [ ] T053 [US3] Combine live Task streams with map nodes for linked status/progress and generic unavailable projections in lib/features/mind_maps/application/map_queries.dart.
- [ ] T054 [US3] Add accessible Task chooser, unavailable-link repair and complete/reopen actions in lib/features/mind_maps/presentation/map_task_picker.dart and lib/features/mind_maps/presentation/map_editor_screen.dart.
- [ ] T055 [US3] Add Arabic/English linked Task, loading/retry, unavailable, complete/reopen and privacy-safe errors in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb; regenerate lib/app/l10n/generated/app_localizations.dart and extend lib/app/l10n/mind_maps_strings_adapter.dart.
- [ ] T056 [US3] Register Task bridge and preview/real-account sync behavior in lib/app/composition/configure_dependencies.dart and refresh linked views in lib/features/mind_maps/presentation/map_editor_cubit.dart.

**Checkpoint**: US3 passes Task/XP tests and preview journey; map commands never write a Task or XP directly.

---

## Phase 6: User Story 4 — Adjust how a map is viewed (P2)

**Goal**: Offer five layouts, per-map and per-node appearance, and usable pan/zoom/fit/center on touch and pointer/keyboard devices.

**Independent Test**: On a map with branches and side links, apply radial/tree/horizontal/vertical/freeform, change settings and a node style, move a node, navigate the 50-node/60-link graph and reopen. Parent links alone drive automatic layout; side links stay visible; saved settings remain map-scoped.

### Tests for User Story 4 — write first

- [ ] T057 [P] [US4] Test deterministic five-layout placement, forest roots, side-link exclusion, no content loss and RTL horizontal direction in test/unit/features/mind_maps/domain/map_layout_test.dart.
- [ ] T058 [P] [US4] Test map default settings versus existing element styles, node appearance choices and restart persistence in test/unit/features/mind_maps/application/map_settings_test.dart.
- [ ] T059 [P] [US4] Test all five choices, node/settings editors, keyboard focus, visible touch controls, RTL and mixed-direction labels in test/widget/features/mind_maps/map_layout_settings_test.dart.
- [ ] T060 [P] [US4] Add mobile/desktop 50-node/60-link pan/zoom/fit/select/edit timing and offline-restart validation in integration_test/mind_maps_viewport_test.dart.

### Implementation for User Story 4

- [ ] T061 [US4] Implement radial, tree, horizontal, vertical and freeform layout rules over parent slots only, including independent roots and RTL horizontal ordering, in lib/features/mind_maps/domain/map_layout.dart.
- [ ] T062 [US4] Validate and apply map settings/defaults and node appearance without restyling old elements in lib/features/mind_maps/application/map_settings_commands.dart.
- [ ] T063 [US4] Persist layout positions, settings and explicit element styles as map/node/connection mutations with outbox entries in lib/features/mind_maps/data/drift_map_repository.dart.
- [ ] T064 [US4] Add pan/zoom/fit/center controller and visible viewport controls while keeping content coordinates stable in lib/features/mind_maps/presentation/map_canvas.dart.
- [ ] T065 [P] [US4] Build five-layout and map background/default node/connection/spacing controls in lib/features/mind_maps/presentation/map_settings_panel.dart.
- [ ] T066 [US4] Add color, icon, five shape choices and small/medium/large node/text sizing to lib/features/mind_maps/presentation/map_node_editor.dart.
- [ ] T067 [US4] Wire layouts, saved positions, settings and undo/redo through lib/features/mind_maps/presentation/map_editor_cubit.dart and lib/features/mind_maps/presentation/map_editor_screen.dart.
- [ ] T068 [US4] Add Arabic/English layout, appearance, viewport and keyboard semantics strings in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb; regenerate lib/app/l10n/generated/app_localizations.dart and extend lib/app/l10n/mind_maps_strings_adapter.dart.

**Checkpoint**: US4 passes five-layout/appearance/navigation checks on mobile and desktop; SC-005's 50/60 graph remains usable within its two-second visible-response target.

---

## Phase 7: User Story 5 — Continue safely across sessions and devices (P2)

**Goal**: Synchronize all four graph record types with owner security, idempotent receipts and visible same-element conflicts while merging independent node edits.

**Independent Test**: In ten offline/reconnect trials on two devices, edit different nodes of one map and keep both, then edit the same node and review the loser. Exercise reparent/cycle/duplicate-pair and delete/edit races, replay operations, switch accounts mid-sync and verify zero foreign data disclosure. Repeat preview locally without sign-in.

### Tests for User Story 5 — write first

- [ ] T069 [P] [US5] Test owner-only map/node/slot/link/conflict/receipt reads, anonymous denial and direct-write denial in supabase/tests/mind_maps_account_isolation_test.sql.
- [ ] T070 [P] [US5] Test owner-derived mutation receipts/replay, cross-map/foreign endpoints, Task link validation, cycles and duplicate parent/side pairs in supabase/tests/mind_maps_operation_integrity_test.sql.
- [ ] T071 [P] [US5] Test independent-node merge, same-record newest winner/visible loser, equal-time tie, structural collision and map/node deletion races in supabase/tests/mind_maps_conflict_integrity_test.sql.
- [ ] T072 [P] [US5] Test four entity dispatch routes, stable operation IDs, retry/acknowledgement and rejection of unknown types in test/unit/core/data/sync/entity_dispatch_router_test.dart.
- [ ] T073 [P] [US5] Test receipt-aware outbound and complete paginated owner reads, final-page/tombstone handling and foreign-data rejection in test/unit/features/mind_maps/data/supabase_map_adapter_test.dart.
- [ ] T074 [P] [US5] Test per-record atomic winner/loser reconciliation, pending local changes, parent/side invariants and deletion/edit evidence in test/unit/features/mind_maps/data/map_reconciler_test.dart.
- [ ] T075 [P] [US5] Test outbound-before-inbound, changed-session guards after awaits, partial-page failure/retry and truthful initial-ready state in test/unit/features/mind_maps/application/map_sync_service_test.dart.
- [ ] T076 [P] [US5] Test signed-out/preview/account-switch route gates and no stale map/Task/conflict details in test/widget/app/mind_maps_route_test.dart.
- [ ] T077 [P] [US5] Add ten two-device offline/reconnect, independent/same-node, structural/deletion race, duplicate-delivery and account-isolation trials in integration_test/mind_maps_offline_sync_test.dart.

### Implementation for User Story 5

- [ ] T078 [US5] Create owner-keyed map/node/parent-slot/side-link tables, indexes, RLS, SELECT policies and least-privilege grants in supabase/migrations/0009_mind_maps_tables.sql.
- [ ] T079 [US5] Add owner-derived receipt-backed graph mutation RPCs, pinned search_path, structural serialization, cycle/duplicate checks, owner validation for new Task links, preservation of existing unavailable IDs and visible conflict evidence in supabase/migrations/0010_mind_maps_sync_api.sql.
- [ ] T080 [US5] Implement receipt-aware outbound mutation adapter for all four graph entities in lib/features/mind_maps/data/supabase_map_sync_adapter.dart.
- [ ] T081 [US5] Implement full paginated owner map/node/parent/side/tombstone reads and an explicit complete-pass cursor in lib/features/mind_maps/data/supabase_map_reader.dart and lib/features/mind_maps/application/map_remote_reader.dart.
- [ ] T082 [US5] Define four-entity reconciliation and visible conflict ports in lib/features/mind_maps/application/map_reconciliation.dart.
- [ ] T083 [US5] Apply newest active records and nonwinning ConflictRecords atomically per entity, keep independent node edits and enforce map/node tombstone visibility in lib/features/mind_maps/data/map_reconciler.dart.
- [ ] T084 [US5] Implement owner-checked outbound then complete inbound sync with retryable failures and ready only after all four streams in lib/features/mind_maps/application/map_sync_service.dart.
- [ ] T085 [US5] Route map, node, parent-slot and side-link PendingChanges through the cloud adapter without changing Tasks/Habits routing in lib/core/data/sync/entity_dispatch_router.dart.
- [ ] T086 [US5] Register authenticated cloud reader/adapter/reconciler/sync and keep the debug Tasks preview local-only in lib/app/composition/configure_dependencies.dart.
- [ ] T087 [US5] Show truthful syncing, retry and owner-scoped nonwinning version review without stale Task details in lib/features/mind_maps/presentation/map_editor_cubit.dart and lib/features/mind_maps/presentation/map_conflict_view.dart.
- [ ] T088 [US5] Add Arabic/English sync, conflict-review and recoverable failure text in lib/app/l10n/app_ar.arb and lib/app/l10n/app_en.arb; regenerate lib/app/l10n/generated/app_localizations.dart and extend lib/app/l10n/mind_maps_strings_adapter.dart.

**Checkpoint**: US5 passes local/Supabase owner, replay, conflict and two-device trials. No partial page or account switch reports ready or leaks another account's content.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Close quality, security, localization, platform and success-criteria evidence for the complete 005 feature.

- [ ] T089 [P] Add architecture checks that Mind Maps never imports Tasks presentation/storage, writes Task/XP directly or bypasses the Task bridge in test/architecture/mind_maps_boundaries_test.dart.
- [ ] T090 [P] Extend PR-to-develop/manual workflow path filters for specs/005-mind-maps and affected integration entries on Android, iOS, Windows, macOS and Linux without adding a feature-push trigger in .github/workflows/foundation-ci.yml.
- [ ] T091 [P] Test Arabic/English primary flows, RTL/mixed-direction labels, touch/keyboard controls and route behavior on one mobile and one desktop target in integration_test/mind_maps_localized_route_test.dart.
- [ ] T092 Run format, analyze, relevant Flutter/widget/integration suites and local Supabase SQL tests; record exact commands/results and any environment limits in specs/005-mind-maps/verification.md.
- [ ] T093 Run persistence, account sync and Task-link checks across Android, iOS, Windows, macOS and Linux with an isolated nonproduction Supabase project; append actual target results to specs/005-mind-maps/verification.md.
- [ ] T094 Record SC-005's 50-node/60-link offline response timings and SC-007's visible-control touch/keyboard walkthrough results in specs/005-mind-maps/verification.md.
- [ ] T095 Review every FR-001–FR-015 and SC-001–SC-007 against tests/results, document later Auth/public-release and UI Refinement dependencies, and record any unmet criterion in specs/005-mind-maps/verification.md.

**Checkpoint**: Every specification criterion has implementation evidence or an explicit remaining issue. The full device CI matrix runs only at the agreed PR/manual gate.

---

## Dependencies & Execution Order

### Phase dependencies

- Phase 1 → Phase 2 → US1. The encrypted v5 schema and stable graph identities block all story work.
- US2 depends on US1's map repository/list. US3 depends on US2's node editor and Tasks 003. US4 depends on US2's graph/canvas; US3 and US4 may proceed in parallel after US2 where files do not overlap.
- US5 depends on the completed graph records and Task-link contract from US1–US3; its cloud implementation may start after those local contracts stabilize. Phase 8 follows all five stories.
- Within a story, write its tests first and confirm the intended failure, then implement model/rules → repository/services → UI/integration; validate the independent test at its checkpoint.

### Parallel examples

- **US1**: T009–T012 tests use separate files. After model/repository seams exist, T017 English and T018 Arabic ARB edits can run concurrently.
- **US2**: T024–T029 tests use separate files. T036 canvas and T037 node editor can proceed in parallel after graph projection is defined.
- **US3**: T040–T045 tests use separate files. Task transition implementation and the MapTaskLinkPort can be developed separately until bridge integration.
- **US4**: T057–T060 tests use separate files. T065 settings panel can proceed while viewport work is in map_canvas.dart.
- **US5**: T069–T077 tests use separate SQL/Dart/integration files. Cloud migration/API and local reconciler work can proceed in separate files after their contracts are fixed; apply migrations in order.

## Implementation Strategy

1. **MVP**: Complete Phases 1–3 and demonstrate the offline preview map library, protected central node, search/copy/delete and restart persistence.
2. **Core graph**: Complete US2 and validate graph/edit/progress/undo independently without waiting for cloud sync.
3. **Task integration**: Complete US3; prove the same Task and single XP award from two maps before adding view options.
4. **View controls**: Complete US4; validate all five layouts, saved styles and accessible navigation at 50/60 scale.
5. **Account sync and closeout**: Complete US5 and Phase 8, using local Supabase tests and the agreed PR/manual five-target gate. Do not add Auth or final UI redesign to 005.
