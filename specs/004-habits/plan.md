# Implementation Plan: Namaa Habits

**Branch**: codex/004-habits | **Date**: 2026-10-16 | **Spec**: specs/004-habits/spec.md

**Input**: Approved feature specification and five 2026-10-16 clarifications; Namaa Constitution v2.0.1; namaa_plan.md Phase 3/Habits/Notifications/Auth/offline sections; verified Foundation and Tasks 003 code and contracts. This phase produces design artifacts only; tasks.md and application code belong to later steps.

## Summary

Build Habits as a separate local-first, account-owned feature. Users create multiple named weekday schedules, complete or undo only today, review read-only history, and see one derived streak per Habit. Weekday edits affect today immediately; a completion earned while due remains in the streak after that weekday is removed. Save an optional reminder time but show it inactive until the later Notifications feature. Reuse Foundation's encrypted storage, session boundary, outbox/conflict records, Supabase account security, localization, routing, and five-target CI. Keep Habit metadata/schedule revisions separate from date-keyed HabitDay records so independent offline days converge without overwriting each other. Auth UI remains a separate later feature and public-release prerequisite.

## Technical Context

**Language/Version**: Dart SDK ^3.11.5; Flutter 3.41.8 is pinned in the existing CI workflow.

**Primary Dependencies**: Existing flutter_bloc ^9.1.1, Drift ^2.34.4, drift_flutter ^0.3.1, supabase_flutter ^2.17.2, get_it ^9.2.1, injectable ^3.0.0, go_router ^17.5.0, flutter_localizations/intl, and current code generation. No new package is needed for saved inactive reminder data.

**Storage**: Additive encrypted Drift/SQLite schema v4 for account-scoped Habit and HabitDay rows; reuse Foundation PendingChanges and ConflictRecords. Add owner-scoped Supabase Habit/Day rows, durable operation receipts, RLS, and authenticated mutation boundaries. No Task or XP schema change.

**Testing**: Pure Dart domain/use-case tests; Flutter Cubit, widget, routing, and integration tests; encrypted v3→v4 migration/recovery tests; local Supabase SQL/RLS/replay tests; offline/reconnect, two-account/two-device, Arabic/English RTL, and five-target CI verification.

**Target Platform**: Android, iOS, Windows, macOS, Linux using the existing Flutter projects.

**Project Type**: One Flutter mobile/desktop application with an existing Supabase backend.

**Performance Goals**: Habit commands update visible local state without a network round trip. User validation targets the spec's three-minute create/complete/streak goal. No unapproved numeric latency or record-capacity target is invented.

**Constraints**: Domain independent of UI, SQL, and Supabase; encrypted account-scoped local state; atomic local mutation/outbox; idempotent retry; newest-timestamp conflict and visible loser; no duplicate HabitDay; local-date stability; account RLS; Auth and notification delivery outside 004.

**Scale/Scope**: One Habit aggregate with schedule revisions, one independently versioned row per acted-on local date, multiple Habits/account, four user journeys, ten-trial integrity scenarios. No approved maximum number of Habits or retention cap.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | 004 obligation and result |
|---|---|
| I. Flutter parity | Shared Habit rules on all five targets; only presentation form factor differs. PASS. |
| II. Clean boundaries/ownership | Habits owns metadata, days, and streak projection; future Today/Analytics consume application contracts. PASS. |
| III. Local-first durability | Additive encrypted v4 migration, atomic local/outbox writes, offline use, recoverable failure. PASS. |
| IV. Account/sync integrity | Session-derived owner, RLS, complete inbound, stable receipts, tombstones, visible conflicts, equal-time recovery. PASS. |
| V. Sacred/finance invariants | No Prayer/Quran/Finance record is changed. PASS. |
| VI. Single state/XP authority | Habit streak derived only from Habit-owned data; Cubit presents it; no Habit XP award. PASS. |
| VII. Arabic/RTL | ARB-backed Arabic/English UI, RTL, dates and weekday labels on mobile and desktop. PASS. |
| VIII. Evidence/simplicity | Reuse verified ports and packages; meaningful domain/widget/integration/SQL/target tests; no speculative framework. PASS. |
| IX. Protected local data | Reuse vault-keyed encrypted database and account-scoped queries; no client secret. PASS. |

**Pre-research gate:** PASS. No constitutional exception is required. Auth UI and notification delivery are explicitly separate product phases; the release prerequisite remains visible rather than hidden.

## Phase 0: Research

research.md resolves the planning unknowns: separate date-keyed HabitDay identity versus a whole-Habit history snapshot; schedule revision ordering and same-day completion evidence; immutable local dates; additive v3→v4 migration; Habit/Day sync routing and parent deletion races; inactive reminder and non-release preview boundaries. It records decisions, rationale, and rejected alternatives. No NEEDS CLARIFICATION remains.

## Phase 1: Design and Contracts

- data-model.md defines Habit, owned schedule revisions, independent HabitDay rows, derived due/streak rules, tombstones, account keys, and proposed local/remote structures.
- contracts/habit-interactions.md defines commands, account checks, due-today/history projections, inactive reminder display, route, localization, and recoverable UI states.
- contracts/habit-sync-security.md defines atomic local writes, outbound/inbound sync, replay receipts, owner-derived cloud access, RLS, conflicts, deletion, and integrity checks.
- quickstart.md defines runnable validation paths and expected outcomes without implementation code.

**Post-design constitution gate:** PASS. The designs keep one Habit authority, preserve account security and encrypted local data, avoid actual notification delivery, and require complete five-target evidence. A HabitDay/parent deletion race is explicitly recoverable rather than silently dropped. No exception or new package is justified.

**Design sequence for the later task-generation workflow:** extend encrypted schema and migration tests; implement pure Habit rules/commands and independent day persistence; add owner-only cloud tables, receipt-backed mutations and SQL tests; register Habit/Day outbound routing and complete inbound reconciliation; wire session-gated Habits UI/Cubit, local preview, ARB strings and responsive layouts; extend integration/CI matrices; verify offline, conflicts, account isolation, RTL, and five targets. This is guidance for speckit-tasks, not tasks.md.

## Project Structure

### Documentation (this feature)

~~~text
specs/004-habits/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── contracts/
    ├── habit-interactions.md
    └── habit-sync-security.md
~~~

tasks.md belongs to a later speckit-tasks step and is not created here.

### Source Code (repository root; planned changes)

~~~text
lib/
├── app/
│   ├── composition/             # register Habit local/cloud/preview adapters
│   ├── routing/app_router.dart   # account-gated /habits route
│   ├── app.dart                   # Habits entry/navigation and feature scope
│   └── l10n/                     # Arabic/English Habit messages
├── core/data/
│   ├── local/foundation_database.dart  # additive encrypted v4 migration
│   └── sync/entity_dispatch_router.dart # habit and habit_day routes
└── features/habits/
    ├── domain/                  # Habit, HabitDay, schedule/streak rules
    ├── application/             # commands, queries, repository/sync ports
    ├── data/                    # Drift and Supabase adapters/reconciler
    └── presentation/            # Cubit, editor, list/history UI

supabase/
├── migrations/                  # next Habit tables/RLS and mutation API
└── tests/                       # owner, replay, conflict, tombstone checks

test/
├── architecture/                # ownership/dependency boundaries
├── unit/                        # rules, migration, repository, sync
└── widget/                      # route, Habit flows, localization/RTL

integration_test/                # offline/restart, preview, account/platform flows
.github/workflows/foundation-ci.yml  # 004 path and five-target test entries
~~~

**Structure Decision:** Add one Habits feature slice to the existing Flutter application. Extend Foundation dispatch and encrypted schema only where the Habit/Day records need them. Do not add a second store, an XP owner, an Auth screen, or notification delivery.

## Complexity Tracking

No constitutional violation or exception requires a complexity entry.

