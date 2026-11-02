# Implementation Plan: Prayer Experience

**Branch**: `namaa/008-prayer-experience` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Clarified 008 specification; Constitution v2.0.1; Namaa Plan; [prototype-reference.md](prototype-reference.md); current Foundation, Tasks, Habits, Maps, Today and XP implementations.

## Summary

Implement the next Namaa domain with the prototype's four ordered Prayer groups and current Namaa colors, ThmanyahSans, icon and shared controls. Manually search for a city online, persist its coordinates/IANA zone per owner on this installation, download and encrypt an AlAdhan annual timetable, and maintain today's deliberate reports. Read cached times offline; use the local calculator with a visible source label beyond cached coverage. Replace Home's sample Prayer card/metric with an explicit Prayer-owned projection.

Add per-prayer synchronization and immutable first-completion rewards using the existing encrypted store/outbox/central ledger. Preserve independent device cities and the existing device calendar for Tasks/Habits. No public Auth, notification delivery, history editor or new streak algorithm.

This command produces design artifacts only; dependency adoption, migrations, app code, tests and CI changes belong to implementation.

## Technical Context

**Language/Version**: Dart ^3.11.5; Flutter 3.41.8 pinned in current CI.

**Primary Dependencies**: Existing flutter_bloc, Drift/sqlite3mc, Supabase Flutter, get_it/injectable, go_router, intl and ARB/gen_l10n. Planned exact additions: adhan_dart 2.0.1 (MIT), timezone 0.11.2 (BSD-2-Clause), uuid 4.6.0 (MIT), Dio 5.11.1 (MIT). Verify release archives/licenses, dependency resolution and five-target imports before committing adoption. No SDK/package-wide upgrade.

**Storage**: Encrypted Foundation schema 7→9; owner-local Prayer device preferences, validated annual timetable per owner/context/year, per-date/prayer reports, shared XP ledger/outbox/conflicts. Supabase migration 0015 adds Prayer reports, receipts/conflicts and native typed RPC; UUIDv5 extension availability is explicitly checked. No cloud preference or schedule table.

**Testing**: Calculation/reference/zone fixtures; command transactions; actual historical-schema upgrades v1…v7; SQL RLS/replay/conflict/reward tests; adapter/Cubit/lifecycle tests; bilingual/theme/150% responsive widgets; focused five-target device integration, named phone/desktop timing and source-to-screen comparison.

**Target Platform**: Android, iOS, Windows, macOS, Linux. No web scope added.

**Project Type**: Existing Flutter mobile/desktop application and Supabase backend.

**Performance Goals**: Saved offline Prayer readable ≤2s; local report visible ≤1s; scripted city→Prayer→Home journey ≤60s. Foreground countdown ticks each second; timetable reads occur on day/preferences change or recovery, not per tick. Seven consecutive cached offline dates need no daily-times service.

**Constraints**: Foreground device location with explicit OS permission and manual city fallback; saved coordinates/zone and annual table survive offline restart; device-independent choices; today-only edits; manual states; never infer missed; one first 10/5 reward; protected owners/preview; no hidden high-latitude fallback; no daily network calculation; no commercial key in client.

**Scale/Scope**: Five logical reports/day/owner, one device preference/owner/installation, at most 10 city results per search, retained history without product deletion cap. Validate an 18,300-report fixture covering at least ten years with indexed day reads; no whole-history projection per tick. Sync uses bounded pages. Existing unrelated sync optimization backlog is not silently included.

## Constitution Check

*GATE evaluated before research and after design. PASS means compliant design, not verified implementation.*

| Principle | Before research | After design |
| --- | --- | --- |
| I. Five-target parity | PASS: shared feature behavior. | PASS: pure-Dart math/zone adapters and five-target import/device checks; platform input adapts only. |
| II. Explicit ownership | PASS: Prayer owns its data. | PASS: application ports, composition-owned routes and Today bridge; Home owns no Prayer rows. |
| III. Durable/local-first | PASS: reuse encrypted runtime. | PASS: v8 report migration and v9 annual-cache migration; transaction writes report+reward+outbox; saved schedules read locally with labelled fallback. |
| IV. Safe synchronization | PASS: account/date/prayer identity. | PASS: typed base version, receipts, per-entity locks, visible preserved conflicts, fixed identity and late-result guards. |
| V. Sacred/financial invariants | PASS: no Quran/Finance edits. | PASS: attributable guidance review, explicit calculation policy, no invented missed state or high-latitude time. |
| VI. Central state/XP | PASS: Cubit and one reward authority. | PASS: generalize Task-only ledger type, keep Task20, add prayer_done10/5; server freezes first committed eligible award. |
| VII. Arabic/accessibility | PASS: existing language pipeline. | PASS: ARBs/plurals, zone-aware formatting, RTL/LTR, focus, 320px/150% layouts. |
| VIII. Evidence/simplicity | PASS: prototype inventory available. | PASS: four dependencies have immediate uses; bounded source-coupled solar preflight documented; no background location or scheduling system. |
| IX. Protected data | PASS: encrypted store/vault retained. | PASS: owner-local preferences are encrypted; no production provider secret in app; preview isolated. |

No exception required. Package/platform adoption, reference fixtures, guidance review and commercial search configuration are implementation/release gates, never claimed as completed by these documents.

## Phase 0: Research

[research.md](research.md) resolves API timetable/local fallback policy, explicit IANA dates, online city provider/terms, device-local preference ownership, v8/v9 migrations, UUID identity, reward authority/concurrency, resolved Prayer conflicts, Home/navigation and verification.

Key decisions:
- Use explicit city date D and D+1, independently computed, then UTC→IANA conversion; do not change global device time zone.
- Preserve prototype method presets with standard/Shafi Asr; fixed90-minute Umm al-Qura/Qatar Isha behavior is labelled as the selected calculation preset, not a claim of every official seasonal timetable.
- Deep-import only the pinned raw SolarTime API inside the data adapter to reject substituted/uncomputable twilight results. No speculative fork or alternate-location fallback.
- Open-Meteo geocoding for noncommercial development; licensed configurable first-party gateway required before commercial search deployment. Saved-city use stays offline regardless of provider availability.
- First server-committed eligible award is canonical. Offline local award is provisional until sync and may reconcile once against a concurrent device's canonical award.
- Keep the generic coordinator's current behavior for other domains; Prayer finalizes its resolved report/reward/conflict result idempotently before returning an acknowledgement.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md): durable schema, identities, immutable rewards, report lifecycle and memory projections.
- [contracts/prayer-application.md](contracts/prayer-application.md): application ports, commands, day guards and lifecycle.
- [contracts/prayer-sync.md](contracts/prayer-sync.md): typed RPC, receipts, reward race, visible conflict protocol and paginated readers.
- [contracts/prayer-ui-city.md](contracts/prayer-ui-city.md): city search boundary, UI groups, routes, Home projection and deferred affordances.
- [quickstart.md](quickstart.md): post-implementation validation commands, fixtures and evidence.

### Implementation sequencing for later task generation

1. Adopt/pin calculation, zone, UUID and HTTP dependencies behind adapters; capture independent reference and prototype fixtures; validate solar preflight and time-zone behavior.
2. Generalize the shared XP model without changing Task semantics; introduce Prayer domain values/ports/commands and deterministic identity.
3. Add v8 report tables/migration (including planned unused Task XP-column cleanup), v9 annual-cache table, real old-schema fixtures and atomic local report/reward/outbox operations.
4. Add migration0015, strict RPC/locks/receipts/RLS, Prayer dispatch/reconciliation and shared-ledger award reading.
5. Wire preview/account ownership and a shared Prayer read model; extend Today projection and routes while preserving existing source/date boundaries.
6. Build the prototype-aligned Prayer groups, city/method editor, ARB copy and conflict review with current shared components; validate both input styles.
7. Add focused Prayer suites to current grouped CI runners, measure SC-001…008, compare prototype, review and run the complete merge gate.

This is sequencing guidance, not tasks.md. Neither new CI runs nor application changes are performed by planning.

### Verification mapping

| Requirements | Proof |
| --- | --- |
| FR-001…007,026 | Setup/search failure fixtures, seven presets, independent reference ≤1min, zero coordinates, explicit city zones, D/D+1, DST and seven offline dates. |
| FR-008…012,015 | Four-state matrix, local-first transaction/rollback, current-day capture, midnight race, first reward10/5 frozen and complete→reset before sync. |
| FR-013…014 | Real v1…7→8 migration, RLS/anon denial, operation collision, two-device pending bases, different-prayer merge, equal tie evidence, stale receipt and owner switch. |
| FR-016…018 | Home/Prayer snapshot equality, separate device/city calendars, generic XP, sample provenance preserved. |
| FR-019…025,027…028 | Four-group prototype inventory, all route entries, independent devices, 320…1200px, AR/EN/themes/text scale, guidance attribution and coming-soon states. |

SC-006 uses named phone and desktop target/build evidence. No passing widget suite substitutes for five-target integration or source/reference validation.

## Project Structure

### Documentation

~~~text
specs/008-prayer-experience/
├── spec.md
├── prototype-reference.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── contracts/
    ├── prayer-application.md
    ├── prayer-sync.md
    └── prayer-ui-city.md
~~~

### Source Code (planned)

~~~text
lib/features/prayer/
├── domain/          # city/date/method/report/schedule/projection values
├── application/     # preferences/search/calculation/repository ports, commands, sync
├── data/            # Dio search, timezone+Adhan adapter, Drift, Supabase, codec
└── presentation/    # Cubit/state, screen/groups, city editor, strings/conflict view
lib/features/xp/     # shared XpAward and compatible task award wrapper/policy
lib/features/today/
├── application/today_prayer_port.dart
├── data/prayer_today_adapter.dart
└── presentation/    # real Prayer card/metric and independent source health
lib/app/
├── composition/    # prayer_preview_adapters, owner binding, dependencies
├── routing/        # /prayer account gate, prayer intents, Track wiring
├── l10n/           # AR/EN prayer strings and adapter
└── widgets/        # reuse existing controls; no separate UI kit
lib/core/data/
├── local/foundation_database.dart  # v8 reports, v9 annual timetable and generated code
└── sync/entity_dispatch_router.dart
supabase/migrations/0015_prayer_reports_and_rewards.sql
supabase/tests/     # prayer account/RPC/conflict/reward integrity
test/fixtures/prayer/  # reference provenance + historical DB fixtures
test/unit/features/prayer/
test/unit/core/data/local/
test/widget/features/prayer/
test/widget/features/today/
test/architecture/prayer_boundaries_test.dart
integration_test/
├── prayer_schedule_test.dart
├── prayer_reports_test.dart
├── prayer_offline_sync_test.dart
└── prayer_localized_route_test.dart
.github/scripts/   # current Android/iOS suite/group mapping and runner tests
.github/workflows/foundation-ci.yml
android/app/src/main/AndroidManifest.xml  # release INTERNET permission for city search
~~~

Names are planned; test commands become runnable only after implementation. Existing Task/Habit/Map data and the unrelated .metadata edit are preserved.

**Structure Decision**: Extend the existing feature-first app. Shared infrastructure changes are bounded to the real second XP source, Prayer dispatch and the next local migration. No account Auth UI, alternative database, periodic location service or scheduling framework.

## Complexity Tracking

No constitutional violations. SolarTime deep import is a documented dependency coupling required to prevent the library's otherwise hidden high-latitude substitution; exact pin, fixture comparison and upgrade gates constrain it. The licensed search gateway is a commercial-deployment boundary, not an invented already-running service.
