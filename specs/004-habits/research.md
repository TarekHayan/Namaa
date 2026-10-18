# Habits 004 — Phase 0 Research

**Inputs:** spec.md, Namaa Constitution v2.0.1, Namaa plan §§5, 14–16, 18–20, 24, and the verified Foundation/Tasks 003 source. These are design decisions for planning, not implementation.

## Decision 1 — Reuse the locked Foundation stack

**Decision:** Build Habits in the existing Flutter/Dart feature structure with Cubit, encrypted Drift/SQLite, Foundation account/session and outbox, Supabase Postgres/Data API, and ARB localization. No new package or notification plugin is needed in 004.

**Rationale:** The codebase already has these boundaries in lib/features/tasks, lib/core/data/local/foundation_database.dart, and lib/core/data/sync. Constitution II, III, VI, VII, and IX require them. Habit reminder delivery is explicitly deferred.

**Alternatives considered:** A second database or a generic cross-feature framework would duplicate verified infrastructure. Adding notification delivery now contradicts the approved 004 boundary.

## Decision 2 — Separate Habit metadata from independent day records

**Decision:** One account-owned Habit aggregate holds name, reminder time, and ordered schedule revisions from which current weekdays are derived. A separate HabitDay record is identified by account, habit ID, and stable local calendar date. A day row represents completion or undo, with version, completion instant, and whether completion was earned while due. Streak is derived, never a separately editable balance.

**Rationale:** A whole-Habit snapshot of all days would make two offline completions on different dates compete under newest-version selection. Separate day identities let those dates converge independently. The existing Task aggregate can remain unchanged.

**Alternatives considered:** Embedding every day in Habit JSON is smaller initially but can hide an unrelated completion in a visible aggregate conflict; a generic event store is unnecessary for the approved scope.

## Decision 3 — Schedule revisions and same-day edits

**Decision:** Each weekday edit creates a versioned revision with stable identity, UTC edit instant, and the acting device's local effective date. The newest active revision changes today's due state immediately. Historical revisions remain for earlier dates. If a completion was recorded while due before today's edit removes that weekday, HabitDay retains earned-while-due status and remains eligible for the streak. If it is undone later today while no longer due, it cannot be re-completed until today is selected again.

**Rationale:** This directly implements the five approved clarifications in spec.md. A date-only revision cannot order two edits on the same day; the edit instant and stable revision identity can.

**Alternatives considered:** Starting edits tomorrow contradicts the product decision. Recomputing past due state solely from current weekdays would rewrite history. A mutable stored streak risks divergence.

## Decision 4 — Calendar and streak projection

**Decision:** Record an action against the acting device's local YYYY-MM-DD date and keep that date immutable after travel or sync. Current due state uses the viewing device's local date and latest active schedule. For historical missed days, use the schedule effective at that day's close; a completed day earned while due remains eligible even if the weekday was later removed that day. Walk eligible scheduled days backward: an unfinished current day is pending; a completed eligible day adds one; a missed closed day ends the current streak. Other weekdays are neutral.

**Rationale:** The spec anchors actions to device-local dates, counts scheduled days, and prevents same-day schedule edits from erasing earned progress. Tasks 003 already serializes calendar dates separately from UTC versions in lib/features/tasks/data/task_payload_codec.dart.

**Alternatives considered:** Count every calendar day (rejected by user); recalculate old dates under the latest schedule (rewrites history); store a mutable streak counter (creates another authority).

## Decision 5 — Local persistence and failure safety

**Decision:** Add an additive encrypted database v3→v4 migration for Habit and HabitDay rows with account-scoped keys/indexes. Persist each local mutation and its stable-ID PendingChange atomically; use the existing protected database key and migration journal. A failed save leaves the last confirmed state recoverable and returns a localized failure.

**Rationale:** lib/core/data/local/foundation_database.dart is v3 and lib/features/tasks/data/drift_task_repository.dart is the working transaction precedent. The generic Foundation outbox and conflict tables already exist. test/unit/core/data/local/tasks_migration_test.dart provides a recovery precedent.

**Alternatives considered:** A second local store or unencrypted preferences would violate Constitution III and IX. Applying UI state as durable before a successful transaction would falsely report success.

## Decision 6 — Cloud synchronization, conflicts, and deletion

**Decision:** Add Habit-owned remote Habit and HabitDay records, owner-derived mutation boundaries, durable operation receipts, owner-only read grants/RLS, and complete paginated inbound reads. Register habit and habit_day in the entity dispatch router. Keep UTC newest-version selection and visible nonwinning conflict for competing versions; equal timestamps remain unresolved and recoverable. Habit tombstones hide owned days from active views and keep replay identity. A day update that races with a parent deletion must be retained as recoverable conflict evidence, not silently resurrect a deleted parent. A competing newer Habit metadata edit versus Habit tombstone follows the existing newest-version rule.

**Rationale:** supabase/migrations/0003_tasks_tables.sql and 0004_task_sync_api.sql, lib/features/tasks/data/task_reconciler.dart, and lib/features/tasks/application/task_sync_service.dart prove the pattern. lib/core/data/local/drift_local_store.dart does not apply active Habit rows after conflict by itself, so Habit reconciliation must do so.

**Alternatives considered:** Direct client writes or client-supplied owner IDs fail the account boundary. Physical deletion before sync can allow stale replay to recreate data. Whole-Habit day merging risks losing independent dates. Realtime is not required.

## Decision 7 — Reminder, Auth, UI, and verification boundaries

**Decision:** Save a local wall-clock reminder time with the Habit and show it inactive. No notification permissions, scheduling, or delivery in 004. Reuse the current session-gated route pattern and the existing non-release local preview account so Habits can be exercised before the separate Auth feature. Add Habit Cubit/UI, Arabic/English resources, responsive layout, and five-target checks. Update CI paths and explicit platform test lists for 004.

**Rationale:** The user approved reminder deferral and Auth later. lib/app/routing/app_router.dart, lib/app/app.dart, lib/app/composition/configure_dependencies.dart, lib/main.dart, and .github/workflows/foundation-ci.yml contain the current patterns. The preview account must remain separate from authenticated account data and disabled in release builds.

**Alternatives considered:** Adding an Auth flow or actual reminders inside Habits changes approved scope. Reusing Tasks presentation/domain types would blur data ownership.

## Resolved planning unknowns

- HabitDay is a separate sync identity; schedule revisions stay within the Habit aggregate with visible conflict handling.
- Local date is immutable per action, while due-today is evaluated in the current viewing device's calendar.
- Additive schema migration advances from v3 to v4; no existing Task/XP data is changed.
- Habit deletion uses a parent tombstone and hides owned history; cross-entity racing day edits remain recoverable conflict evidence.
- No NEEDS CLARIFICATION remains for Phase 1 design.

