# 005 implementation baseline (Phase 1)

Verified against the code on branch `namaa/005-mind-maps` before changing application behavior. This is a map of existing seams for later phases, not a new storage or authentication design. The current code has no Mind Maps tables, routes, commands, or cloud adapter.

## Encrypted local store and migration

| Existing seam | Verified behavior | Reuse for 005 |
|---|---|---|
| `lib/core/data/local/foundation_database.dart` | `kFoundationSchemaVersion` is **4**. Composition obtains the key from the credential vault and passes it to `FoundationDatabase.openEncrypted`; the SQLite connection uses sqlite3mc/SQLCipher-compatible keying. The migration journal records start, completion, failed attempt, and later recovery without resetting prior data. | Add a data-preserving v4→v5 step and migration/recovery test. Keep one encrypted database. |
| `FoundationPreferences`, `LocalRecords`, `FoundationAuditLog`, `MigrationJournal` | Foundation preferences, probe records, audit and migration history have their own tables. | Retain all rows through v5. |
| `PendingChanges`, `ConflictRecords` | Pending operations carry stable operation ID, owner, entity type/ID, kind, payload, UTC version and retry state. Conflicts retain active and nonwinning payloads by owner and entity. | Queue graph changes atomically with local records; reuse visible conflict storage. |
| `TaskRecords`, `XpAwards` | Tasks have composite `(accountId, taskId)` keys. XP awards use `(accountId, source, sourceId)` to prevent another lifetime award for the same source. | Add only the Tasks-owned completion-transition field required by the 005 link projection; do not make a second XP ledger. |
| `HabitRecords`, `HabitDayRecords` | v4 added owner-qualified Habit metadata and independently versioned date-keyed day rows. Upgrade creates tables/indexes without dropping prior data. | Follow the additive migration and independent-record pattern for maps, nodes, parent slots and side links. |

The existing migration test patterns are in `test/unit/core/data/local/habits_migration_test.dart`, `tasks_migration_test.dart`, and `foundation_migration_test.dart`. The current `testMigrationHook` can inject a failure to verify rollback/recovery; Phase 2 extends that evidence for v5.

## Tasks completion and XP authority

- `lib/features/tasks/application/task_repository.dart` exposes account-qualified `readTask`, `watchTasks`, `commitTask`, inbound application and transaction boundaries. Task identity and completion are not map-owned.
- `lib/features/tasks/application/task_completion_service.dart` exposes `completeTask(taskId, expectedAccountId: ...)` and `reopenTask(...)`. It obtains/rechecks the active session owner, rejects missing/deleted/foreign Tasks, and treats repeated completion/reopening as a no-op.
- `lib/core/data/local/task_completion_unit_of_work.dart` commits the Task version, pending change and first XP award in a Drift transaction. `lib/features/xp/` owns the award ledger; a map action must call the Task service rather than write either table.
- `lib/features/tasks/application/task_sync_service.dart` sends outbound changes, reads the complete Task and award snapshots, reconciles inbound, rechecks owner after asynchronous boundaries, and exposes `TaskSyncSnapshot.initialSyncComplete`. The future map Task chooser must wait for that real-account initial sync; the preview reads local Tasks directly.

## Preview, routing and composition

- `lib/main.dart` defaults `NAMAA_TASKS_PREVIEW` to debug mode and chooses the real Foundation environment in release. `lib/app/composition/configure_dependencies.dart` also rejects `tasksPreview` in release.
- `lib/app/composition/tasks_preview_adapters.dart` provides the local-only owner `00000000-0000-4000-8000-000000000003` through `TasksPreviewSession`. Its synchronization adapter acknowledges no remote work. Mind Maps must share this owner so its nodes can link existing preview Tasks without sign-in.
- `lib/app/composition/habits_preview_adapters.dart` has a **different** preview owner ending `0004`; using it for Mind Maps would make preview Task links unavailable.
- `lib/app/routing/app_router.dart` currently registers `/tasks` and `/habits`. Its route gate resolves the session before building account-owned UI, shows a loading indicator or a localized signed-out state, and guards an asynchronous initial lookup against session revisions. `lib/app/app.dart` provides the visible navigation entries. Phase 3 adds a map entry and route using the existing preview/session boundary; it does not add Auth screens.
- `lib/app/composition/configure_dependencies.dart` opens the encrypted database, registers local repositories, chooses Tasks preview or real Supabase session, and registers cloud/sync adapters only for real accounts. The safe-fail branch keeps a recoverable app state if vault, database, migration or cloud setup fails.

## Current synchronization seams

- `lib/core/data/sync/entity_dispatch_router.dart` currently routes `foundation_record`, `task`, `habit`, and `habit_day`. An unsupported type fails recoverably and is **not** acknowledged. Phase 7 adds four Mind Maps entity routes without repurposing another domain's adapter.
- `lib/features/habits/data/drift_habit_repository.dart` is the closest local pattern: owner-qualified reads, graph-independent row/outbox transactions, and typed failures.
- `lib/features/habits/data/supabase_habit_reader.dart` reads complete owner pages with cursor validation. `lib/features/habits/application/habit_sync_service.dart` runs outbound before inbound and rechecks the owner after awaits. `lib/features/habits/data/habit_reconciler.dart` commits active/nonwinning versions together and preserves deletion-race evidence. Mind Maps needs four independent record streams to keep edits to different nodes.
- `supabase/migrations/0003_tasks_tables.sql`–`0007_habit_sync_api.sql` contain the current account tables, RLS and receipt-backed RPC precedent. The next migration numbers are `0008` onward. SQL tests live in `supabase/tests/` and must use the local Supabase stack.

## Verification and workflow boundary

`.github/workflows/foundation-ci.yml` currently triggers on **manual dispatch** or a pull request to `develop`, with no push trigger. It pins Flutter 3.41.8 and Supabase CLI 2.119.0; quality and local Supabase SQL jobs run alongside Android, iOS, Windows, macOS and Linux integration jobs. Its path filter includes 003/004 specs but not `specs/005-mind-maps/**` yet. Phase 8 extends the path filter and affected integration entries while preserving those triggers.

Useful focused commands after a later code change are `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, `flutter test --no-pub`, and `supabase test db` after `supabase start`. Full device integration belongs at the agreed PR-to-`develop` or manual gate; Phase 1 changes only this document, test fixtures and task checkboxes.
