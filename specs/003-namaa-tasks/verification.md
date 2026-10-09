# Namaa Tasks Verification

**Branch:** `namaa/003-tasks`
**Last updated:** 2026-10-09

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