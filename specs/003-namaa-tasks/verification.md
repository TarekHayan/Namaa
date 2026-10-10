# Namaa Tasks Verification

**Branch:** `namaa/003-tasks`
**Last updated:** 2026-10-10

## Phase 2 — Foundational

### Test-first evidence

The Phase 2 tests were written and run before the production schema/router:

- `flutter test test/unit/core/data/local/tasks_migration_test.dart` — **expected FAIL**: the current schema was still v2, so no v3 Task/XP migration ran.
- `flutter test test/unit/core/data/sync/entity_dispatch_router_test.dart` — **expected FAIL**: `entity_dispatch_router.dart` and its entity constants did not exist.
- `supabase test db` — **expected FAIL**: the Task tables and `apply_task_change` RPC did not exist. The pre-existing Foundation pgTAP file still passed.

These failures were caused by the planned missing implementation, not by Docker or configuration.

### Implementation and generated-schema checks

- `dart run build_runner build --delete-conflicting-outputs` — **PASS**; regenerated `foundation_database.g.dart`. The installed build runner reported that `--delete-conflicting-outputs` is obsolete and ignored it, then completed successfully.
- Generated-schema and upgrade inspection — **PASS**: `task_records` and `xp_awards` exist; Task uses the `(account_id, task_id)` key; XP awards use `(account_id, source, source_id)`; fresh databases and v2→v3 upgrades both create all six account-scoped Task query indexes.
- `supabase db reset --local` — **PASS**; applied migrations `0001` through `0004` to the local Docker stack. No production backend or credential was used.

### Green verification evidence

- Focused Phase 2 plus Foundation regression command:
  `flutter test test/unit/core/data/local/tasks_migration_test.dart test/unit/core/data/sync/entity_dispatch_router_test.dart test/unit/core/data/local/foundation_migration_test.dart test/unit/core/data/local/encrypted_local_store_test.dart test/unit/core/data/cloud/supabase_sync_adapter_test.dart test/unit/core/data/sync/synchronization_coordinator_test.dart`
  — **PASS, 35 tests**.
- `flutter analyze` — **PASS, no issues found**.
- `flutter test` — **PASS, 133 tests**.
- `flutter test integration_test/foundation_migration_test.dart -d windows` — **PASS, 1 Windows integration test**; encrypted upgrade/failure/recovery remained operational.
- `supabase test db` — **PASS, 3 files / 55 pgTAP assertions**. This includes the unchanged Foundation ownership suite plus Task owner isolation, denied direct mutations, internal receipts, replay-safe create/update/delete, durable tombstones, and no stale resurrection.
- `git diff --check` — **PASS**; no whitespace errors.

### Phase 2 outcome

- Encrypted local persistence upgrades additively from Foundation v2 to v3 while retaining preferences, probe records, and outbox operations. An injected failed upgrade preserves v2 data and is recoverable.
- Account-scoped local Task aggregates and immutable-key XP award rows are available for later stories. No Task product behavior or XP-award effect is implemented yet.
- Supabase Task rows, XP awards, internal operation receipts, RLS/grants, authenticated owner-derived mutation RPC, timestamp conflict evidence, and replay-safe tombstones are operational on the local stack.
- `foundation_record` and `task` dispatch to separate adapters; unsupported entity types return a recoverable failure and are never acknowledged.
- Existing Foundation probe behavior and tests remain green.

**External blockers:** None for Phase 2. User-facing Tasks and the separate sign-in release prerequisite remain intentionally outside this phase.

## Phase 3A — US1 test-first contracts

### Authored tests

- T013–T021 now cover the Task aggregate/defaults/tombstone, account-scoped commands, encrypted Drift transaction and restart behavior, Supabase mapping and complete pagination, inbound reconciliation/conflicts, Cubit projections, responsive widget behavior, authenticated offline two-client synchronization, and the Tasks ownership boundary.
- The tests use deterministic accounts, clocks, IDs, fake cloud gateways, encrypted temporary databases, and local/nonproduction configuration only.
- `dart format` — **PASS, 9 Phase 3A files formatted**.
- `git diff --check` — **PASS** before task-status/documentation updates.

### Expected Red evidence

- Focused Task-model command:
  `flutter test --no-pub test/unit/features/tasks/domain/task_model_test.dart`
  — **expected FAIL** because `lib/features/tasks/domain/task.dart` and `checklist_item.dart` are intentionally absent until T022.
- Phase 3A unit/widget/architecture command covering T013–T019 and T021 — **expected FAIL** only at the planned missing `lib/features/tasks/{domain,application,data,presentation}` production units from T022–T040. The architecture test independently confirms that T022 has not created the canonical Task owner yet.
- `flutter test --no-pub integration_test/tasks_offline_sync_test.dart -d windows`
  — **expected FAIL** at Windows compilation because the planned Task commands, repository, adapters, reconciliation, and sync service do not exist yet.

These are the required test-first failures, not environment, credential, Docker, or production-Supabase failures. No US1 production behavior was implemented in Phase 3A.

## Phase 3B — US1 domain and application core

### Implemented scope

- T022 adds the account-owned Task aggregate and Task-owned ChecklistItem value, including creation defaults, UTC version/tombstone fields, immutable reward snapshot, and persisted-state restoration without reapplying creation defaults.
- T023 adds validation and pure Today/Urgent/All/Completed/category/matrix projections over the same canonical Task instances.
- T024 adds an infrastructure-neutral, account-scoped Task repository port and atomic-write request; no Drift, Supabase, or Flutter type crosses the boundary.
- T025 adds signed-in create/edit/move/delete commands, local collision-resistant Task/operation IDs, typed localized failures, ownership hiding, and repository-first local writes without a network dependency.
- T026 adds stable Task JSON encoding/decoding for calendar dates, local wall-clock times, UTC versions/deadlines, timezone offset context, checklist ordering, completion state, and tombstones.

### Verification evidence

- Focused Phase 3B command:
  `flutter test --no-pub test/unit/features/tasks/domain/task_model_test.dart test/unit/features/tasks/application/task_commands_test.dart test/architecture/tasks_boundary_test.dart`
  — **PASS, 26 tests**.
- `dart analyze lib/features/tasks` — **PASS, no issues found**.
- `dart analyze lib/core/domain/failures/app_failure.dart` — **PASS, no issues found**.
- `git diff --check` — **PASS** before task-status/documentation updates.

The still-red Phase 3A tests for Drift, Supabase, reconciliation, Cubit, UI, and end-to-end synchronization intentionally target T027–T040 and are outside Phase 3B.

## Phase 3C — US1 persistence and synchronization

### Implemented scope

- T027 persists canonical account-scoped Tasks in the encrypted Drift v3 table and commits each Task mutation with its Foundation outbox entry in one transaction. Reads include tombstones by identity, active watches exclude them, retries preserve operation IDs, and a colliding operation rolls back without a partial Task.
- T028 maps Task outbox operations to the authenticated `apply_task_change` RPC without sending owner authority. Acknowledgements, replay, active/retained conflict evidence, UTC versions, and unsupported entity failures are mapped through Foundation sync outcomes.
- T029 downloads every authenticated Task page, includes tombstones, overlays authoritative row identity/version/deletion fields, and rejects a row whose owner differs from the active account.
- T030 reconciles inbound records by UTC version, imports missing Tasks, retains the loser in Foundation conflict storage, preserves both equal-timestamp versions without a tie-breaker, and never mutates another account partition.
- T031 coordinates outbox upload followed by complete inbound reconciliation on sign-in, reconnect, and Tasks entry. Concurrent triggers share one pass; initial ready/failure state is explicit and later offline failures do not erase an already-ready local state.
- T032 registers the Task repository, gateway, outbound adapter, reader, reconciler, sync service, and Foundation/Task entity router in the composition root, with safe-fail Task ports in unconfigured mode and service/database disposal.
- Local Task edits now advance the aggregate version monotonically even when the injected/device clock has not advanced, preventing equal-timestamp conflicts between consecutive offline edits on one device.

### Verification evidence

- Focused Phase 3C unit and composition suite — **PASS, 40 tests** covering Drift transactions/restart/account isolation, Supabase mapping/pagination, reconciliation, commands, entity routing, and dependency registration.
- Focused Foundation regressions — **PASS, 44 tests** covering encrypted storage, outbox/conflict finalization, Foundation Supabase mapping, coordinator behavior, and value invariants.
- `flutter test --no-pub integration_test/tasks_offline_sync_test.dart -d windows` — **PASS**: offline create/edit/delete survived restart, synchronized through stable operation IDs, converged to a second client, retained the deletion tombstone, and exposed no data to another account.
- `supabase test db` — **PASS, 3 files / 55 pgTAP assertions** for Foundation/Task account isolation, RLS, durable operation receipts, replay safety, conflicts, and tombstones.
- `dart analyze lib/features/tasks lib/app/composition` — **PASS, no issues found**.

Presentation, localization, routing, and app-shell work remains intentionally deferred to T033–T040. Therefore the full Phase 3A test collection is not expected to be green until those production units exist.

## Phase 3D — US1 presentation and app integration

### Implemented scope

- T033–T034 add immutable Task presentation states and a repository-backed TasksCubit for account-local observation, filters, list/matrix projections, local-first commands, synchronization status, conflicts, and lifecycle handling. The repository projection remains the canonical Task collection.
- T035–T036 add responsive list and matrix views, Today/Urgent/All/Completed/category controls, recoverable conflict feedback, and localized create/edit forms for the specified Task fields, scheduling, deadlines, categories, quadrants, and checklist steps.
- T037–T038 add matching English and Arabic Task strings, regenerate Flutter localization output, and verify Arabic right-to-left rendering.
- T039 guards `/tasks` with the Foundation account session, displays a localized signed-out state, and prevents signed-out Task data access.
- T040 wires Task dependency registration, navigation, route-owned Cubit disposal, theme/locale inheritance, and application lifecycle behavior into the existing Foundation shell.
- Presentation depends on a feature-owned localization contract; the app-layer adapter supplies generated Flutter localizations without introducing an inward architecture dependency.
- The delegated Antigravity UI implementation was reviewed and corrected for scheduling controls, bounded responsive matrix layout, editor action visibility, localized failures, and the project architecture boundary before acceptance.

### Verification evidence

- `flutter analyze` — **PASS, no issues found**.
- Focused architecture, routing, composition, Cubit, and widget verification — **PASS, 24 tests** after the final localization-boundary correction.
- Focused Phase 3D suite — **PASS, 33 tests** during implementation review.
- `flutter test --no-pub` — **PASS, 195 tests** across the full project suite.
- `git diff --check` — **PASS** before task-status and verification updates.

T033–T040 are complete. The explicit T041 US1 quickstart and Foundation-regression closure record follows below; Phase 3D alone did not claim public release readiness or deliver the separately planned sign-in flow.

## T041 — US1 closure verification

### Executed gates

- T013–T019 and T021 focused command — **PASS, 60 tests**. This covers Task identity/defaults/validation/tombstones, account-scoped commands, encrypted Drift persistence and restart, Supabase mapping and pagination, reconciliation/conflicts, Cubit projections, responsive UI, Arabic RTL, signed-out guarding, and the Tasks architecture boundary.
- T020 Windows integration test — **PASS, 1 test**. Offline create/edit/delete survived an encrypted restart, reused stable operation IDs, synchronized to a second simulated client, retained deletion tombstones, and exposed no data to a different account.
- Focused Foundation regression command — **PASS, 70 tests**. Foundation migration, encrypted storage, outbox/conflict finalization, Supabase adapter, synchronization coordinator, composition, shell routing, localization/RTL, theme selection, and Cubit lifecycle remain intact.
- `flutter analyze` — **PASS, no issues found**.
- `supabase test db` — **PASS, 3 files / 55 pgTAP assertions**. Foundation and Task owner isolation, RLS, operation receipts, replay integrity, conflict handling, and tombstones remain enforced on the local nonproduction stack.
- `git diff --check` — **PASS** before this documentation update.

The Windows integration run emitted Drift's debug-only multiple-database warning while intentionally simulating two local clients. Each client used the test harness lifecycle and the scenario completed successfully; no production failure or data-integrity assertion occurred.

### US1 quickstart coverage

- **Scenario A — PASS for US1 scope:** title-only defaults, blank-title rejection, supported field editing, canonical list/matrix and Today/Urgent/All/Completed/category projections, immediate local visibility, and encrypted restart persistence are verified. The overdue projection belongs to US3 and is not claimed here.
- **Scenario C — PASS for US1 scope:** offline Task mutation, restart, reconnect, second-client convergence, stable retry identity, remote tombstone import, newest-version conflict behavior, and recoverable equal-timestamp conflicts are covered by T015–T020. Checklist edits and XP repetition belong to US2/US3.
- **Scenario D — PASS:** local account partitions and Supabase RLS prevent a second account from accessing the first account's Task data, tombstones, or operation receipts.
- **Scenario E — PASS for the internal US1 checkpoint:** mobile/desktop responsive widget layouts, English/Arabic localization, RTL, guarded routing, and Windows persistence/sync integration are verified. Native Android, iOS, macOS, and Linux execution remains part of the existing five-target CI release gate.
- **Scenario B — deferred by design:** checklist mutation, completion, history, and one-time XP behavior are specified for US2/US3 and are not part of T041.

### Outcome

T041 and the internal US1 checkpoint are complete. Task CRUD, local-first persistence, list/matrix presentation, account isolation, and synchronization are independently verified with an injected authenticated session.

US1 is **not user-release-ready** yet. The separately planned user-facing sign-in path and successful five-target CI gate remain release prerequisites, and US2/US3 behavior is not claimed by this checkpoint.
