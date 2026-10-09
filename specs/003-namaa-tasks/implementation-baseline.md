# Namaa Tasks Implementation Baseline

**Captured:** 2026-10-08 (Africa/Cairo)  
**Branch:** `namaa/003-tasks`  
**Starting commit:** `6b4ea7b` (`docs(tasks): prepare Tasks specification plan and execution checklist`)

This record satisfies T001 only. It describes the code that existed before Tasks production work started and records the commands that were actually run. It does not claim that Task persistence, synchronization, or UI already exists.

## Existing Foundation boundaries

| Area | Verified starting point | Evidence |
|---|---|---|
| Local schema | `FoundationDatabase` is schema version 2 and contains Foundation preferences, probe records, the pending-change outbox, conflict records, migration journal, and audit log. There is no Task or XP-award table. | `lib/core/data/local/foundation_database.dart:30`, `lib/core/data/local/foundation_database.dart:38-129` |
| Local product writes | `DriftLocalStore` commits the Foundation probe record and outbox atomically. Acknowledgement/conflict application has explicit handling only for `entityType == 'foundation_record'`; it is not a generic Task repository. | `lib/core/data/local/drift_local_store.dart:37-112`, `lib/core/data/local/drift_local_store.dart:181`, `lib/core/data/local/drift_local_store.dart:311` |
| Cloud adapter | `SupabaseSyncAdapter` targets `foundation_probe` and calls `apply_foundation_change`. It does not route or fetch Task entities. | `lib/core/data/cloud/supabase/supabase_sync_adapter.dart:18`, `lib/core/data/cloud/supabase/supabase_sync_adapter.dart:42`, `lib/core/data/cloud/supabase/supabase_sync_adapter.dart:61` |
| Sync triggers | `SynchronizationRunner` starts one outbound pending-change pass immediately and on an online transition. No inbound Task collection pull exists. | `lib/core/data/sync/synchronization_runner.dart:50-81` |
| Dependency injection | The composition root binds one `CloudSyncPort` to the Foundation probe adapter and registers the existing Foundation use cases/Cubits. | `lib/app/composition/configure_dependencies.dart:93-98`, `lib/app/composition/configure_dependencies.dart:185-224` |
| Routing | The router registers only the Foundation root route `/` plus the localized unknown-route boundary. | `lib/app/routing/app_router.dart:8-30` |

These facts match `specs/003-namaa-tasks/research.md`: Phase 2 must add Task-specific persistence and transport rather than treating the probe paths as product-ready abstractions.

## Toolchain

- Flutter 3.41.8, stable channel.
- Dart 3.11.5.
- Supabase CLI 2.119.0.
- Windows x64 development host.

## Baseline command results

| Command | Result on 2026-10-08 | Status |
|---|---|---|
| `flutter analyze` | Completed with `No issues found!` (initial baseline run: 75.5 seconds). | PASS |
| `flutter test` | Completed with 127 tests and `All tests passed!`. | PASS |
| `supabase test db` | Ran `foundation_account_isolation_test.sql`: 1 file, 12 tests, all successful (`Result: PASS`). | PASS |
| `supabase start` | Started the local Docker-backed stack successfully. The CLI reported only a non-blocking deprecation warning for the local mail configuration. | PASS |

The first attempt was blocked because Docker Desktop was not running. After the user started Docker, the local stack and database suite passed. Only local development credentials were emitted by the CLI; none are recorded here and no production or hosted Supabase credentials were used.

## Phase 1 additions

T002 adds `test/support/tasks_test_support.dart` with deterministic, explicitly non-production account A/B identifiers, a controllable UTC clock with an explicit local-date offset, repeatable Task/operation ID sequences, and a manual offline/online implementation of the existing `ConnectivityPort`. After formatting that file, `flutter analyze` passed again with no issues.

## Boundary for Phase 2

Phase 1 changes no Foundation runtime behavior. The next phase may begin from the documented schema-v2/probe-only baseline with Flutter analysis, all 127 Flutter tests, and all 12 current local Supabase database tests passing.
