# Implementation Plan: Dashboard / Today

**Branch**: `namaa/006-today-dashboard` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Clarified 006 specification; Namaa Constitution v2.0.1; existing Foundation, Tasks 003, Habits 004 and Mind Maps 005 implementations; Namaa plan and adjacent prototype as bounded behavioral references.

## Summary

Build Today as the main daily entry in the existing Flutter app: independent Task and Habit progress, actual daily XP, timed/untimed agenda, up to three eligible urgent-and-important Tasks, overdue navigation and existing owner creation flows. Derive everything from the existing encrypted local owner streams through explicit application ports; keep owner commands, streaks, rewards and synchronization authoritative.

Preserve existing preview data with an explicit mapping of its two owner IDs. Add small owner-side transaction/date guards to prevent stale-day or deleted-item actions. Keep independent recovery states and identity generations so one source cannot block the screen or expose a prior account. Public Auth, future domain cards, combined scores and final visual redesign remain outside 006.

This workflow delivers design documents only. It does not implement the feature, generate tasks.md, change CI, commit or push.

## Technical Context

**Language/Version**: Dart SDK ^3.11.5; Flutter 3.41.8 pinned in existing CI.

**Primary Dependencies**: Existing flutter_bloc ^9.1.1, Drift ^2.34.4/drift_flutter ^0.3.1, sqlite3 ^3.5.2 with sqlite3mc encryption, supabase_flutter ^2.17.2, get_it/injectable, go_router, intl and ARB/gen_l10n. Stock Flutter layout, semantics, focus and lifecycle APIs; Dart timers/streams. No new dependency or upgrade.

**Storage**: Existing encrypted Foundation database and Tasks/Habits/XP tables only. Today projections, source health, pending UI intents and scope generations are memory-only. No schema bump, migration, cloud table, RPC, new outbox type or daily history store.

**Testing**: Pure projection tests; owner command transaction/calendar/race regressions; owner-adapter stream tests; Cubit source health/identity/date tests; root route/creation intent/preferences tests; AR/EN/RTL/accessibility widgets; offline/restart/sync and cross-domain device integration; measured mobile/desktop acceptance.

**Target Platform**: Android, iOS, Windows, macOS and Linux.

**Project Type**: One existing Flutter mobile/desktop application with an existing Supabase backend.

**Performance Goals**: With 500 local Tasks, 100 Habits and 200 awards, initial projection and confirmed local action visible within two seconds on a tested mobile and desktop target. Owner/local-sync arrivals and resume refresh within two seconds; foreground day rollover within one minute. Nonresponding source shows recovery within ten seconds.

**Constraints**: Offline viewing/actions; account isolation and preserved preview records; no public sign-in; no duplicate business/sync authority; correct local-calendar boundaries and actual award instants; Arabic/English/RTL, touch/pointer/keyboard; functional UI now, final design later. Full CI remains PR-to-develop/manual, not feature-push driven.

**Scale/Scope**: One current-day view over implemented productivity owners; two progress ratios, one actual-XP total, full today's agenda and maximum three priority references, overdue count and owner links. Existing owner's history may exceed the acceptance fixture; no product storage limit is introduced.

## Constitution Check

*GATE: evaluated before Phase 0 and rechecked after Phase 1 design.*

| Principle | Pre-research check | Post-design check |
|---|---|---|
| I. Flutter parity | Shared Flutter daily behavior on five targets. PASS. | Same models/ports/commands and compact integration suite across five targets; layout/input adapt only. PASS. |
| II. Ownership and architecture | Today derives owner data, no owner replacement. PASS. | Named Task/Habit/XP bridges import owner application/domain only; owner route intents stay in app composition. PASS. |
| III. Local-first durability | Existing encrypted owner records remain canonical. PASS. | Local watches and transactional owner saves; no network wait, schema or duplicate persistence. PASS. |
| IV. Account/sync integrity | Existing account and conflict boundaries apply. PASS. | Closed preview mapping, same-account real scope, generation clearing, existing idempotent sync and reward authority. PASS. |
| V. Sacred/finance invariants | No Quran/Finance mutation or fabricated daily obligations. PASS. | Future domain cards/weights omitted; no religious timing or financial calculation. PASS. |
| VI. State/XP authority | Cubit for UI, owner streak/rewards unchanged. PASS. | HabitQueries supplies streak; existing ledger supplies XP; completion UoW remains sole Task award path. PASS. |
| VII. Arabic/RTL | Existing localization pipeline applies. PASS. | Today strings adapter/ARBs, locale-aware numbers/dates and mobile/desktop accessible journeys. PASS. |
| VIII. Evidence/simplicity | Reuse verified owners; no package/framework invention. PASS. | Source-backed guard gaps bounded to owner commands; meaningful focused verification and final merge gate. PASS. |
| IX. Protected local data | Existing encrypted DB and credential vault retained. PASS. | Memory-only Today state; no secrets or real-account/preview cache mixing. PASS. |

**Pre-research result:** PASS. Both product clarifications are approved; no constitutional exception is required.

**Post-design result:** PASS. Research resolved preview identity, source observation, navigation and async command safety without a new store or service. Owner hardening is required for FR-012/014; it is not deferred behind a UI precheck.

## Phase 0: Research

[research.md](research.md) records decisions, rationale, alternatives and source paths for owner ports; Task membership/ordering/overdue; Habit eligibility/streak; actual XP; two-ID preview binding; transactional day/identity guards; calendar/source recovery; navigation and incremental verification. All technical unknowns are resolved. No additional product decision is required.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md): memory-only scope/calendar, owner reference projections, independent progress, XP intervals, section availability and command state.
- [contracts/today-owner-integration.md](contracts/today-owner-integration.md): narrow read/write ports, canonical queries, owner command safeguards, preview/account boundaries and sync effects.
- [contracts/today-interactions.md](contracts/today-interactions.md): root/owner navigation, creation intents, sections, action feedback, localized accessible controls and preferences.
- [contracts/today-lifecycle-recovery.md](contracts/today-lifecycle-recovery.md): clock/resume rules, independent source deadlines, retry generations, identity clearing and consistency.
- [quickstart.md](quickstart.md): post-implementation runnable validation, fixtures, timing/evidence and affected test commands.

### Implementation approach for later task generation

1. Define pure Today projection DTOs/rules and the three ports; encode both approved clarifications in fixtures.
2. Harden Task/Habit owner commands for fresh transactional reads, optional displayed-date preconditions, final session/day validation and no-write rejection. Regress existing callers and award behavior before adding UI actions.
3. Add the three owner adapters and composition-owned scope mapping; subscribe locally and use existing owner sync after successful saves.
4. Build TodayCubit source health/date/scope generations and per-item desired-state action handling; test delayed and obsolete events.
5. Wire root into existing Foundation bootstrap/session gate, owner entry intents and small app-owned preference controls; build functional responsive Today widgets and ARB strings.
6. Integrate focused owner/routing tests and compact device journeys; measure exact success criteria and add Today suite selections to existing CI harness. Run the complete required gate before merge.

This is sequencing guidance for speckit-tasks, not an implementation task list.

### Verification coverage

| Requirements | Planned proof |
|---|---|
| FR-001, FR-008 | Root preview/bootstrap and account gates, owner intent consumed once, existing editors, cancel without writes, preferences. |
| FR-002, FR-004, FR-009, FR-010, FR-011 | Full canonical Task fixture, separate ratios, completed denominator, agenda ties/untimed, Do First scope/order/limit, owner overdue equivalence. |
| FR-003, FR-007 | Owner Habit query/streak equality, retained completion then unscheduled undo, transaction/race and day rejection, no Habit XP. |
| FR-005, FR-006 | Actual ledger boundaries, deleted/reopened Task awards, single lifetime reward, linked-map identity and owner action tests. |
| FR-012, FR-013 | Injected clock/offset/resume; pending reads crossing midnight; local owner/inbound arrivals; changed overdue instant without row update. |
| FR-014, FR-015, FR-016 | Offline/restart, failing saves, partial/hanging sources, retry, late emissions, account switch and preserved distinct preview owners. |
| FR-017, FR-019, FR-020 | Architecture scan; zero read-only writes; absent future metrics; functional five-target integration. |
| FR-018 | AR/EN formatting/RTL, semantics, visible focus, text scale, narrow layouts, pointer/touch/keyboard. |

SC-001 through SC-007 have explicit fixture/evidence instructions in quickstart.md. Successful unit/widget tests do not replace measured performance, target or two-device evidence.

## Project Structure

### Documentation

~~~text
specs/006-today-dashboard/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── contracts/
    ├── today-owner-integration.md
    ├── today-interactions.md
    └── today-lifecycle-recovery.md
~~~

tasks.md is generated only by the later speckit-tasks workflow.

### Source Code (planned changes; existing files remain authoritative)

~~~text
lib/
├── app/
│   ├── app.dart                         # root Today within Foundation bootstrap; preferences
│   ├── routing/app_router.dart          # scoped Today root and owner entry intents
│   ├── composition/                     # Today wiring and closed owner-ID bindings
│   └── l10n/                            # Today strings adapter + AR/EN ARBs
└── features/
    ├── today/
    │   ├── domain/                      # scope/calendar values, DTOs, pure projections
    │   ├── application/                 # Task/Habit/XP ports and Today actions
    │   ├── data/                        # three named owner application adapters
    │   └── presentation/                # Cubit/state, Today screen/sections/strings
    ├── tasks/
    │   └── application/                 # optional Today date guard + transaction use
    └── habits/
        ├── application/                 # expected-day guard + transaction port
        └── data/drift_habit_repository.dart # owner transaction implementation
test/
├── architecture/today_boundaries_test.dart
├── unit/features/today/                  # rules, adapters, Cubit/clock/actions
├── unit/features/tasks/                  # completion transaction/day regressions
├── unit/features/habits/                 # completion/undo transaction/day regressions
├── unit/app/composition/                 # preview/account wiring
└── widget/                              # Today + root/owner intents/RTL/preferences
integration_test/
├── today_dashboard_test.dart             # compact local/owner/offline/RTL route journey
└── today_sync_test.dart                  # same-account convergence/date projections
.github/workflows/foundation-ci.yml       # 006 paths/suite registration; unchanged trigger policy
.github/scripts/                         # existing runners: bounded Today suite mapping
~~~

Names for new test files are planned; quickstart commands apply once implementation creates them. Adapters may be split into small files within these folders, with no generic dashboard framework.

**Structure Decision:** Extend feature-first Clean Architecture in the existing app. Today owns its derived display, availability and input intent only. Tasks/Habits own transactional changes; XP owns awards; app composition owns session binding/navigation. No Supabase migration, alternate database, Auth flow or design system is added.

## Complexity Tracking

No constitutional violation or exception. The three owner adapters and small calendar seam have immediate uses in isolation, recovery and date validation; no speculative shared layer is introduced.
