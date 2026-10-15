# Implementation Plan: Namaa Tasks

**Branch**: namaa/003-tasks | **Date**: 2026-10-07 | **Spec**: specs/003-namaa-tasks/spec.md

**Input**: The approved feature specification, .specify/memory/constitution.md v2.0.1, namaa_plan.md Phase 3/Tasks/Auth/offline/XP sections, existing Foundation code and contracts, and the verified prototype. This is a design plan only; no application code or tasks.md is created here.

## Summary

Build the first Core Productivity feature as one local-first, account-owned Task aggregate with simple checklist steps; list, matrix, filters, history, overdue, and explicit completion. Reuse the Foundation's encrypted Drift/SQLite, BLoC/Cubit, DI, routing, localization, Supabase boundary, and sync coordinator. Add actual Task persistence, bidirectional account sync, durable deletion/retry handling, and one immutable shared XP award per Task. Preserve the current Foundation probe behavior. Basic user-facing sign-in and initial authenticated sync are release prerequisites outside the Tasks feature.

## Technical Context

**Language/Version**: Dart SDK ^3.11.5 with repository Flutter SDK constraints.

**Primary Dependencies**: flutter_bloc ^9.1.1, Drift ^2.34.4, drift_flutter ^0.3.1, supabase_flutter ^2.17.2, get_it ^9.2.1, injectable ^3.0.0, go_router ^17.5.0, flutter_localizations/intl and existing code generation. Use only dependencies already approved in pubspec.yaml unless a concrete implementation gap is proved.

**Storage**: Existing encrypted Drift/SQLite FoundationDatabase, additive schema v3 for Tasks and XP awards, Foundation outbox/conflicts; authenticated Supabase Task/award/operation records with RLS and tombstones.

**Testing**: Dart/Flutter unit, widget, integration and architecture tests; Drift migration/recovery tests; local Supabase SQL/RLS tests; isolated multi-device/account and five-target CI checks.

**Target Platform**: Android, iOS, Windows, macOS, Linux, using the existing Foundation target projects and CI gate.

**Project Type**: One Flutter mobile/desktop application with Supabase cloud backend.

**Performance Goals**: Local Task actions update visible state without a network round trip. No numeric latency or scale target was approved; do not invent one.

**Constraints**: Domain independent of Flutter/Drift/Supabase; encrypted account-scoped local data; offline writes durable and atomic with outbox and first award; idempotent bidirectional sync; timestamp conflict rule and visible loser; RLS; no product feature outside Tasks.

**Scale/Scope**: Seven categories, four quadrants, list/matrix projections, simple checklist, one Task completion award per lifetime, two-account/two-device and ten-cycle acceptance scenarios. No record-count capacity claim approved.

## Constitution Check

**Pre-research gate (PASS):**

| Constitution rule | Design obligation |
|---|---|
| I. Flutter parity | Shared Dart business logic and five native targets; platform-specific adapters only where necessary. |
| II. Clean boundaries/ownership | Tasks owns Task/checklist; shared XP owns award; domain imports no UI, SQL, or Supabase. |
| III. Local-first durability | Encrypted Drift v3, local atomic command/outbox, data-preserving migration. |
| IV. Account/sync integrity | Account partitioning, auth-derived RLS, stable operation ID, inbound and outbound sync, tombstones, visible conflict; equal timestamps remain recoverable. |
| V. Sacred/finance invariants | No Quran or Finance records touched. |
| VI. Single state/XP authority | Cubit observes application state; one shared award ledger, no duplicate Task copies or balance counters. |
| VII. Arabic/RTL | ARB-backed Arabic/English text and RTL on mobile/desktop. |
| VIII. Quality/simplicity | Required unit/widget/integration/security/platform proof; no recurrence, Realtime, or speculative generic framework. |
| IX. Protected local account data | Existing device-key-backed encryption and strict account-scoped queries. |

There is no justified constitutional exception. The separate Auth UI prerequisite is an explicit release dependency from spec FR-013, not a reason to implement Auth in this feature.

## Phase 0: Research

Decisions and alternatives are recorded in research.md. The source audit established that Foundation's current LocalRecords and Supabase adapter implement only foundation_record/foundation_probe, and its runner only sends pending changes. Therefore Task persistence, Task transport routing, and authenticated inbound reconciliation are required rather than assuming the probe implementation is generic. The approved equal-timestamp conflict behavior is to retain both recoverably; no automatic tie-breaker is introduced.

## Phase 1: Design and Contracts

- data-model.md defines Task/checklist aggregate, shared immutable award, existing outbox/conflict links, remote records, validation and state transitions.
- contracts/task-interactions.md defines commands, projections, route, offline and localization behavior visible to users and future domain consumers.
- contracts/task-sync-security.md defines local atomicity, bidirectional sync, idempotency, RLS and account isolation.
- quickstart.md defines executable validation scenarios and release gates without implementation code.

**Design sequence for the subsequent implementation workflow:** extend the shared encrypted schema and minimal XP authority; implement Task domain/application and local adapters; add Supabase schema/RLS and durable Task operation handling; route Task outbound changes and import account-scoped remote state; wire Cubit, route, localization, and responsive list/matrix UI; verify migration, offline, conflicts, security, XP, and five-platform parity. Tests should be written before their corresponding production behavior per the project's testing discipline. This sequence is guidance for later task generation, not tasks.md.

## Project Structure

### Documentation (this feature)

~~~text
specs/003-namaa-tasks/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    ├── task-interactions.md
    └── task-sync-security.md
~~~

tasks.md belongs to a later speckit-tasks step and is not created by this plan.

### Source Code (repository root; planned changes)

~~~text
lib/
├── app/
│   ├── composition/configure_dependencies.dart  # register feature adapters/services
│   ├── routing/app_router.dart                     # guarded Tasks route
│   └── l10n/                                       # Arabic/English Task strings
├── core/
│   ├── application/ports/                          # narrow shared sync/session contracts
│   └── data/
│       ├── local/foundation_database.dart          # additive encrypted schema migration
│       ├── sync/                                    # entity routing and inbound orchestration
│       └── cloud/supabase/                          # keep existing probe adapter intact
└── features/
    ├── tasks/
    │   ├── domain/                                 # Task aggregate and rules
    │   ├── application/                            # commands, queries, Task ports
    │   ├── data/                                   # Drift/Supabase adapters
    │   └── presentation/                           # Cubit and list/matrix UI
    └── xp/                                         # minimal shared award authority

supabase/
├── migrations/                                     # Task, award, operation RLS schema
└── tests/                                          # owner/other-account SQL tests

test/
├── architecture/                                   # dependency/ownership checks
├── unit/                                           # domain, local, sync, XP tests
└── widget/                                         # Task flows and RTL
integration_test/                                   # offline/restart/account/platform flows
.github/workflows/                                  # extend existing five-target gate
~~~

**Structure Decision:** Add one feature-first Tasks slice and a minimal shared XP boundary to the existing Flutter repository. Extend Foundation interfaces/adapters only where Task-specific evidence requires it; do not create a second app, database, or speculative cross-feature framework.

## Constitution Check After Design

**PASS, subject to implementation verification.** The data model has one canonical Task aggregate and one XP award authority; contracts preserve encryption, account boundaries, RLS, local-first writes, stable retries, inbound convergence, visible nonwinner, and equal-timestamp recovery. UI localization and five-target tests are explicit. No rule conflict or architecture exception was found. The unresolved automatic equal-timestamp tie-breaker remains deliberately out of scope; the approved recoverable behavior is sufficient. Auth sign-in plus initial sync remains a separate release prerequisite, not an implicit Tasks implementation.

## Complexity Tracking

No constitutional violations or exceptions requiring justification.
