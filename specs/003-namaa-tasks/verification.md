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

## Phase 4A — US2 test-first specification

### Added tests

- T042 specifies explicit completion, reopening, recompletion, repeated-complete idempotency, and the approved rule that incomplete checklist steps do not block parent completion.
- T043 specifies immutable one-time XP identity by `(account, task_done, Task ID)`, first-value retention, ten cycles, account partitioning, deletion retention, and atomic Task+award+outbox rollback.
- T044 specifies authenticated Supabase completion+award atomicity, operation replay, recompletion idempotency, RLS isolation, deletion retention, and invalid-award rollback in 30 pgTAP assertions.
- T045 specifies ten offline completion/reopen cycles with encrypted restart/reconnect and same-account two-client convergence to one Task and one lifetime award. It uses only in-process nonproduction fakes and local temporary databases.

### Expected-red evidence

- Focused T042/T043 Flutter command — **EXPECTED FAIL** because the Phase 4B completion transitions, award value/port, Drift ledger, and transactional completion unit do not exist yet.
- Direct Dart analysis of T045 — **EXPECTED FAIL, 16 diagnostics**, all at the deliberately absent Phase 4B/4C APIs or their planned extensions (`TaskCompletionService`, award ledger/types, completion unit of work, award reader/remote page).
- `supabase test db` — existing Foundation/US1 suites **PASS**; the new T044 file runs all 30 assertions and has **15 expected failures** because `apply_task_change` does not create or atomically validate a first-completion XP award until T051.
- Native Windows execution of T045 was attempted twice but the Flutter runner produced no output and was stopped after waiting; therefore no runtime result is claimed for T045 in 4A. Its compile-time expected-red state is independently recorded above.
- The SQL test plan count was checked against its 30 pgTAP assertions.

### Outcome

T042–T045 are authored before production work and intentionally remain red. No Phase 4 production code or product behavior was implemented. Phase 4B may now implement T046–T050 against these tests; final green verification remains T056.

## Phase 4B — US2 local completion and XP integrity

### Implemented scope

- T046 adds the immutable shared `TaskCompletionAward` value with the fixed `task_done` source, validated UTC timestamp/nonnegative amount, value equality, and unique account/source/Task key. XP owns this value without importing the Tasks domain.
- T047 adds the infrastructure-neutral `AwardLedgerPort` and explicit first-insert outcome; it exposes immutable account-scoped reads without introducing an XP balance or broader gamification behavior.
- T048 implements encrypted Drift award reads, observation, and `INSERT OR IGNORE ... RETURNING` first-write semantics over the existing composite primary key. Later attempts cannot replace the first amount or timestamp, and no delete API exists.
- T049 adds the SDK-free completion transaction request/port and its Drift implementation. Task state, the optional first award, and the existing Task pending change commit in one database transaction; any award or outbox failure rolls back every new effect.
- T050 adds explicit complete/reopen aggregate transitions and an account-scoped application service. It hides missing/foreign/deleted Tasks, rechecks the active account before every result/commit, makes repeated completion/reopening a no-op, advances UTC versions monotonically, preserves checklist state, and registers real plus safe-fail dependencies in the composition root.
- Completion transaction validation requires the queued version and award identity, amount, and timestamp to match the committed Task, preventing a mismatched cross-domain effect.

### Verification evidence

- Focused T042/T043, completion-service, and composition command — **PASS, 27 tests**. This covers completion/reopen/no-op behavior, incomplete-checklist preservation, immutable first values, account partitions, ten cycles, deletion retention, rollback, session changes, and real/safe-fail DI.
- `flutter analyze lib test` — **PASS, no issues found**.
- `flutter test --no-pub` — **PASS, 226 tests** across architecture, Foundation, Tasks, XP, composition, and widget regressions.
- The repository-wide analyzer still sees the intentionally red T045 integration references to the not-yet-implemented T053 award download API. No T051–T055 production behavior is claimed by this checkpoint.
- T044 remains intentionally red until the T051 Supabase migration; Phase 4B does not modify the remote schema or weaken its expected assertions.
- `git diff --check` — **PASS** before task-status and documentation closure.

### Outcome

T046–T050 are complete and locally green. Phase 4B establishes trustworthy offline completion and one lifetime local XP award; remote atomic award creation/import, presentation actions, and the final US2 checkpoint remain T051–T056.

## Phase 4C — US2 remote XP integrity and inbound award synchronization

### Implemented scope

- T051 adds `0005_task_xp_completion.sql`, extending the authenticated Task RPC so an explicit completion, its immutable `task_done` award, and the durable operation receipt commit in one PostgreSQL transaction. It preserves the Task's first stored `completionXp` snapshot, ignores duplicate award keys, awards a losing completion independently of Task version choice, and leaves existing least-privilege grants and owner-scoped RLS intact.
- T052 keeps completion and reopening on the existing Task outbox/RPC path with the same stable operation ID. The adapter validates completion fields, sends no owner authority and no separate reward command, and retains the established acknowledgement/replay/conflict mapping.
- T053 adds complete paginated reads of owner-scoped Task awards, validates owner/source/value/timestamp integrity, deduplicates identical immutable keys, rejects conflicting duplicates, and imports awards through `AwardLedgerPort.applyRemoteAward`. Initial sync cannot become ready until every Task and award page has been downloaded and award merging succeeds; account-switch, pending-change, tombstone, and Task reconciliation behavior remains in place.
- The composition root binds one Supabase reader behind both Task and Task-award application ports and supplies the shared Drift award ledger to `TaskSyncService`; unconfigured mode retains safe-fail behavior.

### Verification evidence

- Focused Supabase adapter/reader, Task sync-service, and composition tests — **PASS, 20 tests** before the added failure-gate assertion; the final full suite below includes that assertion. Coverage includes completion/reopening payloads, stable operation IDs, conflict mapping, complete award pagination, immutable-key deduplication, foreign-owner rejection, account switching, award merging, and real/safe-fail DI.
- `flutter test --no-pub -d windows integration_test/tasks_completion_sync_test.dart` — **PASS, 1 Windows integration test**: ten encrypted offline restart/reconnect completion cycles and two same-account clients converged to one Task and one lifetime award.
- `flutter test --no-pub -d windows integration_test/tasks_offline_sync_test.dart` — **PASS, 1 Windows integration regression** when run separately. A combined two-file Windows invocation passed the first test but the Flutter runner failed to start the second app; the independent rerun passed, so no application regression is recorded.
- `supabase db reset --local` — **PASS** from a clean local database with migrations `0001` through `0005` applied.
- `supabase test db` — **PASS, 4 files / 85 pgTAP assertions**. This includes atomic first award, stored reward snapshot, operation replay, distinct recompletion IDs, invalid-award rollback, delete retention, strict account isolation/RLS, and all Foundation/US1 Supabase regressions.
- `flutter analyze --no-pub` — **PASS, no issues found**.
- `flutter test --no-pub` — **PASS, 230 tests** across the complete non-integration Flutter suite.
- `git diff --check` — **PASS**; only Git's Windows line-ending notices were emitted.

### Outcome

T051–T053 are complete. Remote Task completion and one-time XP creation are atomic and retry-safe, and another device imports the immutable award before initial Task synchronization reports ready. Phase 4C adds no UI, no separate XP outbox operation, and no broader gamification behavior. T054–T056 remain open for presentation actions and the final US2 closure gate.

## Phase 4D — US2 completion presentation

### Implemented scope

- T054 adds explicit complete/reopen actions to `TasksCubit`, observes the account-scoped shared award ledger, and exposes immutable award evidence plus derived Task XP in `TasksReady`. The Cubit never increments an XP counter from an action result; earned XP changes only when the shared award query emits.
- The account change and Cubit disposal paths cancel the award subscription alongside Task and conflict subscriptions, and a failed award observation is surfaced as a recoverable local-data state without replacing already visible Tasks.
- T055 adds localized complete/reopen controls to each Task card and displays the localized completion date and time while the Task is completed. Explicit completion remains enabled with incomplete checklist steps, preserves those steps unchanged, and does not infer parent completion from checklist state.
- English and Arabic ARB resources and the feature-owned localization adapter now provide the completion labels and timestamp message. The existing theme, responsive list/matrix layouts, and RTL direction remain inherited.

### Verification evidence

- The new TDD tests were written before the production surface and initially failed at the deliberately absent Cubit constructor/actions/state and UI controls.
- Focused Cubit and widget command — **PASS, 22 tests**. It verifies complete/reopen behavior, incomplete-checklist preservation, completion timestamp visibility, one retained award, and that XP stays unchanged until the shared award stream emits.
- Focused Phase 4D, completion service, award ledger, composition, and Tasks boundary command — **PASS, 47 tests**.
- `flutter analyze --no-pub` — **PASS, no issues found**.
- `flutter test --no-pub` — **PASS, 233 tests** across the full non-integration suite.
- `git diff --check` — **PASS** before this documentation update; only Git's Windows line-ending notices were emitted.

### Outcome

T054–T055 are complete. Users can explicitly complete or reopen a Task, see its completion timestamp, and the presentation observes one-time XP only from the canonical shared ledger. T056 remains open for the final US2 quickstart, Supabase, integration, and regression closure gate.

## T056 — US2 closure verification

### Executed gates

- T042 and T043 focused command — **PASS, 12 tests**. Explicit completion records UTC time, reopening clears it, recompletion updates it, repeated completion is a no-op, an incomplete checklist does not block completion, and the immutable ledger retains one award through ten cycles, deletion, account partitioning, and rollback cases.
- `supabase test db` — **PASS, 4 files / 85 pgTAP assertions** on the running local, unlinked Supabase stack. T044 verifies authenticated atomic completion plus first award, replay and recompletion idempotency, stored reward snapshot, invalid-award rollback, delete retention, and strict owner/other-account RLS; all Foundation and US1 SQL regressions also pass.
- `flutter test --no-pub -d windows integration_test/tasks_completion_sync_test.dart` — **PASS, 1 integration test**. T045 completed ten encrypted offline restart/reconnect completion cycles and two same-account clients converged to one Task identity and one lifetime award.
- US2 Quickstart-focused completion service, Cubit, and widget command — **PASS, 29 tests**. It covers explicit completion with an unfinished checklist step, visible completion timestamp, All/Completed versus open projections, reopening with the prior award retained, ledger-derived XP with no optimistic counter, localized controls, and account/session failures.
- `flutter test --no-pub` — **PASS, 233 tests** across architecture, Foundation, US1, US2, persistence, synchronization, XP, localization, and widget behavior.
- `flutter test --no-pub -d windows integration_test/tasks_offline_sync_test.dart` — **PASS, 1 US1 regression integration test**. Offline create/edit/delete still survives encrypted restart and converges to a second client with stable operation identity, tombstone retention, and account isolation.
- `flutter analyze --no-pub` — **PASS, no issues found**.
- `git diff --check` — **PASS** after the T056 documentation update; only Git's Windows line-ending notices were emitted.

Both Windows integration scenarios intentionally open multiple encrypted test clients. Drift emitted its debug-only multiple-database warning, but every assertion and teardown completed successfully; no production database sharing or integrity failure was observed.

### US2 Quickstart evidence

- **First explicit completion — PASS:** the Task receives a UTC completion time and exactly one immutable award using its stored reward snapshot.
- **Incomplete checklist preservation — PASS:** explicit parent completion remains available while a step is unfinished, and that step is not auto-completed or separately rewarded.
- **Reopen and recomplete — PASS:** reopening clears the current completion time but retains the first award; a later completion records a new time without another award.
- **Ten-cycle integrity — PASS:** local encrypted persistence, offline restart/reconnect, stable outbox operations, remote replay, and a second same-account client converge to one award.
- **Deletion retention — PASS:** deleting a rewarded Task hides/tombstones the Task while the immutable XP evidence remains.
- **Account ownership — PASS:** local partitions, authenticated RPC checks, grants, and RLS expose zero foreign-account Task or award records.

The checklist add/edit/toggle/remove portion of Quickstart Scenario B belongs to US3 tasks T057–T071 and is not claimed by this US2 checkpoint. T056 verifies only the approved US2 behavior against an existing incomplete checklist value.

### Outcome

T056 and Phase 4 / US2 are complete as an internal feature checkpoint. The one-time Task reward invariant is green locally, remotely, after restart/retry, in presentation state, and across two simulated devices. No broad Gamification behavior was introduced.

This does not declare the complete Tasks feature or user release ready: US3 checklist/history/overdue work, Phase 6 CI/release gates, the separate user-facing Auth prerequisite, and fresh five-target Task results remain open.

## Phase 4 review fixes

- SQL now records the first explicit completion award even when that Task version loses to a newer edit; the newer Task remains active and the loser remains conflict evidence. The stored Task reward snapshot still determines the award amount.
- The shared remote award is the account-wide first-commit record. Inbound synchronization reconciles divergent offline copies by the same immutable key, so two devices show one matching amount and award time.
- The two-client fake gateway now follows the server's Task winner, retained conflict, reward snapshot, and independent award behavior. Windows integration includes losing offline completion and two competing offline completions.
- After resetting the empty local test database, `supabase test db` passed all 4 files and 93 assertions. The focused award-ledger and sync tests passed; `flutter analyze --no-pub` found no issues.
- `flutter test --no-pub -d windows integration_test/tasks_completion_sync_test.dart` passed all 3 scenarios. The full Flutter suite passed on rerun and again with `--concurrency=1` (234 tests). Its first concurrent run had one unisolated failure, which did not recur.
