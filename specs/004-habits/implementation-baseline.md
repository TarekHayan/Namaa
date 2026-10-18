# Habits 004 implementation baseline

**Scope:** source inspection for Phase 1 on branch namaa/004-habits. This records the existing integration seams before Habit code is added. It is not evidence that the 004 behavior or five-platform checks pass.

## Verified starting state

| Area | Existing source and behavior | 004 handoff |
|---|---|---|
| Encrypted local database | lib/core/data/local/foundation_database.dart defines kFoundationSchemaVersion = 3. The sqlite3mc-backed encrypted database key comes through the Credential Vault. Current tables are FoundationPreferences, LocalRecords, PendingChanges, ConflictRecords, MigrationJournal, FoundationAuditLog, TaskRecords, and XpAwards. | T003–T005 add HabitRecords and HabitDayRecords and an additive v3→v4 migration. Use accountId in their composite keys; do not change Task/XP records. |
| Migration recovery | FoundationDatabase.openEncrypted opens the encrypted connection before serving data. Its onUpgrade path records a migration journal start/completion, creates v2/v3 tables and indexes, and reports a recoverable failure while retaining prior data. test/unit/core/data/local/tasks_migration_test.dart exercises preservation, failed upgrade and retry. The current testMigrationHook runs for upgrades crossing v2 or v3; v4 tests will need the hook to cover the new step. | Seed a genuine v3 file with Foundation, Task, XP, preference and outbox rows. Inject a v4 failure, assert old rows remain and the journal shows failure, then reopen and assert recovery. |
| Durable local writes | lib/features/tasks/data/drift_task_repository.dart uses one Drift transaction for Task and PendingChange rows. It scopes reads by accountId, uses a stable operationId, and rejects reuse of an operationId for a different logical write. lib/core/data/local/drift_local_store.dart holds the generic pending and conflict records. | Habit and HabitDay each need their own account-keyed version and atomic row/outbox write. A day key is accountId + habitId + immutable localDate, independent of the parent metadata version. |
| Cloud dispatch and reconciliation | lib/core/data/sync/entity_dispatch_router.dart routes foundation_record and task; an unknown type returns a recoverable failure, leaving the operation pending. lib/features/tasks/application/task_sync_service.dart sends outbound first, reads remote data, checks the account again after asynchronous steps, and reports readiness only after inbound work. lib/features/tasks/data/task_reconciler.dart is the product-row reconciliation precedent. | Register habit and habit_day separately. Reconcile active Habit and Day rows, tombstones and conflict evidence after complete owner-scoped pagination. The generic outbox conflict recorder does not itself apply the winning Habit row. |
| Cloud security | supabase/migrations/0003_tasks_tables.sql creates owner-keyed Task/XP/receipt tables, owner SELECT RLS, and revoked direct writes/receipt reads. supabase/migrations/0004_task_sync_api.sql derives owner from auth.uid() in a restricted mutation RPC and retains operation receipts for replay. supabase/tests/tasks_account_isolation_test.sql and tasks_operation_integrity_test.sql are the security-test pattern. | Next migrations are 0006_habits_tables.sql and 0007_habit_sync_api.sql. Test owner-only reads, no direct writes, stable receipts, same-date uniqueness, parent tombstones and conflict retention on the local Supabase stack. |
| Session and preview | lib/app/routing/app_router.dart resolves the account before constructing the Tasks screen and shows a localized signed-out/loading boundary. lib/app/composition/configure_dependencies.dart wires protected storage, account session, Task ports and Cubit. lib/main.dart selects the Tasks preview only when NAMAA_TASKS_PREVIEW is true and the build is not release. lib/app/composition/tasks_preview_adapters.dart uses the separate account 00000000-0000-4000-8000-000000000003 and no cloud pass. | Reuse the session gate and non-release preview boundary for Habits, with a separate preview partition. Release access still needs a real account and full initial synchronization; 004 adds no sign-in screen. |
| Tests and target gate | test/support/tasks_test_support.dart has controllable UTC time, offset, IDs and connectivity. test/support/foundation_test_support.dart provides encrypted temporary database paths. .github/workflows/foundation-ci.yml runs formatting, analysis, Flutter tests and local Supabase SQL tests, with five target jobs and explicit integration lists for desktop/iOS. | Add Habit-specific deterministic fixtures now. Later add Habit tests and extend 004 paths and target lists; local Windows results alone do not establish all five targets. |

## Approved behavior and boundaries

- specs/004-habits/spec.md and data-model.md define Habit metadata with ordered schedule revisions and a separately versioned HabitDay for each account/habit/localDate. The local date and recorded offset stay as captured by the acting device.
- The current streak is derived for one Habit from its effective scheduled days. Unscheduled days are neutral; an unfinished due today does not end the previous streak. A completion earned while due remains eligible after a same-day weekday removal.
- Only today's completion can change. Editing selected weekdays affects today immediately. A saved reminder time remains visibly inactive until the later Notifications feature.
- Local mutation and outbox write commit together. Cloud mutation derives owner from the authenticated session, uses RLS and durable receipts, and retains the nonwinning version visibly under Foundation's timestamp rule. Account switches and incomplete inbound pages cannot report a ready sync state.
- Habit ownership stays inside the Habits feature; Tasks and XP are not changed by completion. Auth UI, actual notification delivery, Today/Dashboard/Analytics aggregation and visual redesign are outside 004.

## Reproducible checks for later phases

Run from the repository root after the relevant code exists:

~~~text
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --no-pub
supabase start
supabase test db
~~~

The local database migration precedent is test/unit/core/data/local/tasks_migration_test.dart; the SQL policy and receipt precedents are supabase/tests/tasks_account_isolation_test.sql and supabase/tests/tasks_operation_integrity_test.sql. Automated Supabase tests use the local stack. Authenticated device checks use only an isolated non-production project. The quickstart in specs/004-habits/quickstart.md defines the 004 acceptance run.
