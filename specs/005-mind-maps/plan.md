# Implementation Plan: Namaa Mind Maps

**Branch**: namaa/005-mind-maps | **Date**: 2026-10-18 | **Spec**: specs/005-mind-maps/spec.md

**Input**: Clarified 005 specification; Namaa Constitution v2.0.1; Namaa plan Mind Maps phase; verified Foundation/Tasks 003/Habits 004 implementation and contracts; adjacent prototype as behavioral reference. This step creates design artifacts only; tasks.md and application changes belong to later steps.

## Summary

Build a local-first Mind Maps feature with a searchable map library, editable nodes and connections, five layouts, appearance settings, undo/redo, derived progress, and links to existing Tasks. Preserve separate offline edits by synchronizing maps, nodes, parent slots, and side links independently. Parent slots alone control automatic layout; detaching or reparenting a branch preserves its content. Task completion and one-time XP remain owned by Tasks through an explicit bridge. Reuse Foundation's encrypted Drift store, outbox/conflict records, account-bound Supabase sync, localization, and preview. Keep Auth for the later feature and final colors/composition for UI Refinement.

## Technical Context

**Language/Version**: Dart SDK ^3.11.5; Flutter 3.41.8 pinned in existing CI.

**Primary Dependencies**: Existing flutter_bloc ^9.1.1, Drift ^2.34.4, drift_flutter ^0.3.1, supabase_flutter ^2.17.2, get_it/injectable, go_router, Flutter ARB/gen_l10n, and stock Flutter canvas/interaction widgets. No new package is required by the design.

**Storage**: Additive encrypted Drift/SQLite v4→v5 schema for four owner-qualified map record types plus a minimal Tasks-owned completion-transition field; matching Supabase account rows/RLS/restricted receipt-backed commands; reuse Foundation PendingChanges/ConflictRecords. No separate database or XP ledger.

**Testing**: Pure graph/progress/command unit tests; Drift migration/recovery, repository and reconciliation tests; Task bridge/XP tests; Cubit/widget/routing/RTL tests; local Supabase SQL RLS/replay tests; offline/restart/two-device/account integration and affected-target checks.

**Target Platform**: Android, iOS, Windows, macOS, Linux through the existing Flutter app.

**Project Type**: One Flutter mobile/desktop application with an existing Supabase backend.

**Performance Goals**: Confirmed offline edits visibly reflected within two seconds on a map of at least 50 nodes and 60 connections on one mobile and one desktop target (SC-005). Pan/zoom/fit/select remain usable at that size. No larger capacity claim is invented.

**Constraints**: Local-first and encrypted; per-record newest-version reconciliation with visible loser; account RLS and owner validation; graph acyclic parent structure and unique visible pair; Task/XP single authority; Arabic/English RTL and labeled touch/keyboard controls; debug preview without sign-in; Auth and final visual refinement outside 005. Full five-target CI only on PR to develop or manual trigger.

**Scale/Scope**: Multiple maps per owner; five layouts; four node kinds plus protected central node; parent and visual side relationships; one optional Task link per node and many nodes per Task; 50-node/60-link acceptance case. No approved hard map/node limit.

## Constitution Check

*GATE: Checked before Phase 0 research and again after Phase 1 design.*

| Principle | 005 obligation and result |
|---|---|
| I. Flutter parity | One graph/domain model on five targets; viewport/input adapt by form factor. PASS. |
| II. Feature ownership | Mind Maps owns graph/settings/progress; Tasks owns Task completion/XP; bridge is an application port. PASS. |
| III. Local-first durability | Atomic encrypted v5 local records/outbox, automatic migration and recoverable failure; offline editor. PASS. |
| IV. Account/sync integrity | Owner-scoped RLS/RPC/receipts, per-record convergence, visible losers, tombstone races and preview isolation. PASS. |
| V. Sacred/finance invariants | No Prayer/Quran/Finance data is changed. PASS. |
| VI. State/XP authority | Cubit presents graph; Task service alone completes/reopens linked Tasks and awards once. PASS. |
| VII. Arabic/RTL | ARB Arabic/English, directional layout and touch/keyboard verification. PASS. |
| VIII. Evidence/simplicity | Reuse Foundation/Tasks and stock Flutter widgets; meaningful domain/UI/SQL/device checks; no new package. PASS. |
| IX. Protected local data | Existing encrypted database, OS-protected credentials, publishable client key, account-qualified queries. PASS. |

**Pre-research gate:** PASS. The four user clarifications are explicit in the spec. No constitutional exception or unresolved product decision is required.

## Phase 0: Research

research.md documents record boundaries, graph and layout invariants, Task link/XP authority, additive local/cloud sync, editor/preview approach, and CI trigger. It explains rejected alternatives including a whole-map blob, hidden parent after disconnect, direct Task/XP writes, and feature-push five-target CI. It also identifies the minimal Tasks-owned completion-transition revision needed to honor the reopened/in-progress behavior. No product unknown remains.

## Phase 1: Design and Contracts

- data-model.md defines map, node, parent slot, side link, Task projection, editor history, conflict records, validation/state transitions, v4→v5 migration, and copy/delete semantics.
- contracts/mind-map-interactions.md defines the route, queries, commands, editor controls, layout, progress, localization, preview, and recoverable UI states.
- contracts/task-link.md defines the application bridge to existing Tasks repository/completion/sync services and one-time XP invariant.
- contracts/mind-map-sync-security.md defines local transactions/outbox, paged reconciliation, structural cloud invariants, RLS/RPC/receipts, account switching, and conflict visibility.
- quickstart.md gives runnable post-implementation validation for preview, graph, Tasks, offline/device sync, and CI without including implementation code.

**Post-design constitution gate:** PASS. Node and relationship records converge separately; structural commands prevent cycles and duplicate visible pairs; Task metadata required for linked status remains Tasks-owned; map commands never award XP. Preview is debug-only and uses Tasks' identity. The v5 migration and all owner boundaries have explicit validation. No exception or new package is justified.

**Design sequence for later task generation:** add v5 encrypted schema, Tasks completion-transition migration and recovery tests; implement pure graph rules, map repository and local commands; add owner-only cloud tables/RPC/receipts and SQL security tests; route four entity types through outbound/inbound reconciliation with visible conflicts; build Tasks bridge and verify XP; wire preview/account-gated map list/editor, five layouts, ARB and accessible inputs; extend affected integration tests and PR/manual five-target CI; review offline, account isolation, graph races, RTL and SC-005 performance. This guides the later speckit-tasks workflow and is not a task list.

## Project Structure

### Documentation (this feature)

~~~text
specs/005-mind-maps/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── contracts/
    ├── mind-map-interactions.md
    ├── task-link.md
    └── mind-map-sync-security.md
~~~

tasks.md is produced only by the later speckit-tasks workflow.

### Source Code (repository root; planned changes)

~~~text
lib/
├── app/
│   ├── composition/                 # map local/cloud/preview adapters and Task bridge
│   ├── routing/app_router.dart      # account-gated Mind Maps route
│   ├── app.dart                      # visible feature entry/navigation
│   └── l10n/                        # Arabic/English Mind Maps strings
├── core/data/
│   ├── local/foundation_database.dart  # additive encrypted v5 migration
│   └── sync/entity_dispatch_router.dart # four map entity routes
├── features/
│   ├── mind_maps/
│   │   ├── domain/                  # map, node, relationship, layout/progress rules
│   │   ├── application/             # commands, queries, Task link and sync ports
│   │   ├── data/                    # Drift/Supabase adapters and reconciler
│   │   └── presentation/            # Cubit, map list, editor, canvas and controls
│   └── tasks/                       # minimal Tasks-owned completion-transition revision
supabase/
├── migrations/                      # map tables/RLS/RPC and Task revision column
└── tests/                           # graph invariants, owner, replay, conflicts
test/
├── architecture/                    # domain boundaries
├── unit/                            # graph, migration, repository, sync, Task bridge
└── widget/                          # route, editor, ARB/RTL and keyboard/touch
integration_test/                   # preview, offline/restart, account/platform flows
.github/workflows/foundation-ci.yml # 005 paths and affected target entries; PR/manual only
~~~

**Structure Decision:** Extend the current Flutter/Foundation feature-first layout. Mind Maps owns map data; Tasks owns its small completion revision and all Task/XP effects. Do not create another store, Auth flow, XP owner, or visual-design system.

## Complexity Tracking

No constitutional violation or exception requires a complexity entry.
