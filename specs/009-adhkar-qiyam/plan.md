# Implementation Plan: Adhkar and Qiyam

**Branch**: `namaa/009-adhkar-qiyam` | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

**Input**: the clarified 009 specification; Constitution v2.0.1; `namaa_plan.md` §10, §11, §14 and §20; the prototype's `AdhkarView`, `QiyamView`, `adhkarData` and `AppContext`; and the shipped 008 Prayer, XP, sync, Today and navigation code.

## Summary

Add two new local-first domains, **Adhkar** (Morning and Evening lists with tap counters) and **Qiyam** (a nightly record with details). Both take their timing from the 008 Prayer schedule, through one new read-only Prayer port.

- **Adhkar timing** follows the product owner's ruling:
  - The Adhkar day starts at Fajr.
  - Morning can be counted from Fajr to Maghrib, and Evening from Maghrib to the next Fajr.
  - Outside its time, a list is read-only.
  - Without a schedule, both lists stay open and the day follows the calendar.
- **Qiyam** records belong to the night that started at the most recent Maghrib, and only that night is editable.
- **Rewards and streaks.**
  - XP comes from the shared, server-authoritative ledger: 15 per completed Adhkar list per day, and 30 per Qiyam night. Each is awarded once and never revoked.
  - Both streaks are derived on demand.
- **Content.** The reviewed adhkar and supplications ship as a versioned asset displayed in Amiri.
- **Sync.** It uses migration 0016 with typed RPCs, receipts, newest-wins and visible conflicts, as 008 does.
- **Home and Track** show live progress and open the real screens.

This command produces design artifacts only.

## Technical Context

**Language/Version**: Dart ^3.11.5; Flutter 3.41.8, as pinned in CI.

**Primary Dependencies**: the existing flutter_bloc, Drift/sqlite3mc, supabase_flutter, get_it, go_router, intl, uuid 4.6.0 and ARB/gen_l10n. No new package. One new font asset, Amiri (OFL-1.1), with its license file shipped and its checksum verified before adoption.

**Storage**: the encrypted Drift schema goes v9→v10 with `adhkar_item_counts` and `qiyam_nights`, reusing the outbox, conflicts and xp_awards. Supabase migration 0016 adds the catalog seed, the record tables, receipts, conflicts, two RPCs, RLS and grants. The adhkar catalog is a bundled JSON asset.

**Testing**:
- **Unit:** the clock, night and streak rules; commands and transactions; catalog validation; real v1…v9→v10 migration fixtures.
- **SQL:** pgTAP for access, validation, convergence, conflicts, set-completion and Qiyam awards, and replay.
- **Cubit and widget:** AR/EN, light/dark, 320–1200 px and 100–200% text scale.
- **Integration:** three device files run across five targets inside the existing `prayer` CI groups.

**Target Platform**: Android, iOS, Windows, macOS and Linux.

**Project Type**: the existing Flutter mobile/desktop app with its Supabase backend.

**Performance Goals**:
- A count shows ≤ 100 ms after the tap (SC-001).
- An offline screen is readable ≤ 2 s after opening.
- There is no per-second polling: one timer to the next Fajr or Maghrib boundary, plus a refresh on resume.
- Streak walks are capped at 3,650 days and use indexed reads.

**Constraints**:
- Every action is local-first and works offline.
- Time windows are enforced at submission, on the client.
- The server rejects days more than two days ahead.
- No notifications.
- No generated religious text.
- Only the current night is editable.
- Awards are permanent.
- Debug preview stays local-only.

**Scale/Scope**:
- Per owner per day: at most 19 item records.
- Per owner per night: one Qiyam record.
- History is unbounded but read in pages of 30.
- Sync pages are bounded per pass.

## Constitution Check

*Gate result before research and after design. PASS means the design complies; it does not mean the implementation is verified.*

| Principle | Before research | After design |
|---|---|---|
| I. Five-target parity | PASS: shared behavior, with no platform API beyond what Prayer already uses. | PASS: pure-Dart rules; integration on all five targets through the existing groups. |
| II. Explicit ownership | PASS: two owning domains. | PASS: separate `adhkar/` and `qiyam/` features; a Prayer read port; a Today bridge through application ports; architecture tests extended. |
| III. Durable/local-first | PASS: encrypted store. | PASS: additive v10 migration with rollback; atomic record + award + outbox transactions; offline catalog. |
| IV. Safe synchronization | PASS: per-owner identities. | PASS: per-item and per-night records, receipts, identity locks, newest-wins, visible conflicts, RLS-only access. |
| V. Sacred/financial invariants | PASS: no Quran or Finance change. | PASS: reviewed, sourced adhkar content with no generation or rewriting; items that fail review are removed. |
| VI. Central state/XP | PASS: Cubits and the shared ledger. | PASS: two new server-derived sources, insert-only; streaks derived per domain, never merged. |
| VII. Arabic/accessibility | PASS: ARB pipeline. | PASS: AR/EN strings, RTL, semantic count labels, keyboard counting, 320 px and 200%. |
| VIII. Evidence/simplicity | PASS: prototype parity scope. | PASS: no new package; one font with a present use; no notification framework; no CRDT. |
| IX. Protected data | PASS: encrypted store. | PASS: new tables are encrypted at rest; no secret in the client; preview is isolated. |

No exception is required. The content source review, the font license check and the staging push of 0016 are implementation and release gates that need the owner's approval. They are not claimed here.

## Phase 0: Research

[research.md](research.md), R1–R12, covers:
- the feature ownership split;
- the Prayer boundaries port;
- Adhkar day and period resolution;
- Qiyam night attribution;
- per-item sync granularity;
- the server-derived XP sources;
- the catalog asset and its review;
- the Amiri font;
- derived streaks;
- migrations v10 and 0016;
- navigation and the Home bridge;
- CI placement.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md): identities, catalog, local v10 tables, remote 0016, transitions and migration integrity.
- [contracts/adhkar-qiyam-application.md](contracts/adhkar-qiyam-application.md): the Prayer read port, the Adhkar and Qiyam commands and guards, the Cubits, and the Today bridge.
- [contracts/adhkar-qiyam-sync.md](contracts/adhkar-qiyam-sync.md): the RPCs, transactions, awards, finalization, readers and required proofs.
- [contracts/adhkar-qiyam-ui.md](contracts/adhkar-qiyam-ui.md): routes, shell sections, entry points, screen structure, conflicts and accessibility.
- [quickstart.md](quickstart.md): the validation commands and scenarios.

### Implementation sequencing (input for tasks.md)

1. Content: build the catalog asset from the prototype and write `content-sources.md` as a review document. Adopt Amiri with its license.
2. Domain: `AdhkarClock`, `QiyamNight`, the catalog model, the streak walks and the XP sources (`XpAward` validation), test-first.
3. Data: the v10 tables and migration with historical fixtures; the transactional repositories; the Prayer `PrayerDayBoundaries` port and its adapters.
4. Cloud: migration 0016, the pgTAP tests, the dispatchers, inbound readers and settlement.
5. Presentation: the Cubits and both screens (prototype order), the conflict list, and the ARB strings.
6. Integration: the routes and shell sections; Track hub and Home wiring through `TodayAdhkarQiyamPort`; the preview adapters.
7. Verification: the integration files added to the CI groups; the SC-001…008 evidence; the owner's device checks; the full gate on the final head.

### Verification mapping

| Requirements | Proof |
|---|---|
| FR-001…005, 019…021 | Catalog validation; the widget matrix; screen-reader labels; keyboard counting. |
| FR-006, 006a, 006b | `AdhkarClock` vectors across Fajr, Maghrib and midnight, and with no schedule; streak patterns; the live boundary-timer test. |
| FR-007, 010 | Command/transaction tests and pgTAP award idempotency; two-device integration. |
| FR-008, 011, 011a, 012…014 | `QiyamNight` vectors; equality with the Prayer projection; the edit guard; history paging; streak patterns. |
| FR-015 | No notification dependency or permission is added (dependency and manifest audit). |
| FR-016, 017 | Offline/restart integration; pgTAP convergence and conflicts; hosted two-device sync. |
| FR-018 | Route, shell and Today bridge widget tests; the localized route integration test. |

## Project Structure

### Documentation

```text
specs/009-adhkar-qiyam/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── content-sources.md        # written during implementation (FR-002)
├── checklists/requirements.md
└── contracts/
    ├── adhkar-qiyam-application.md
    ├── adhkar-qiyam-sync.md
    └── adhkar-qiyam-ui.md
```

### Source code (planned)

```text
assets/religious/adhkar_catalog_v1.json
assets/fonts/amiri/ (Amiri-Regular.ttf, OFL.txt)
lib/features/adhkar/
├── domain/        # catalog, AdhkarClock, item count, streak
├── application/   # ports, Increment/Reset commands, sync service
├── data/          # asset catalog, Drift repository, Supabase gateway/reader
└── presentation/  # AdhkarCubit/state, AdhkarScreen, item card, conflicts view
lib/features/qiyam/
├── domain/        # QiyamNight, night record, streak
├── application/   # ports, SaveQiyamNight, sync service
├── data/          # Drift repository, Supabase gateway/reader
└── presentation/  # QiyamCubit/state, QiyamScreen, history, conflicts view
lib/features/prayer/application/prayer_day_boundaries.dart   # new read port
lib/features/prayer/data/                                    # its implementation
lib/features/xp/domain/xp_award.dart                         # + adhkar_set_done 15, qiyam_done 30
lib/features/today/
├── application/today_adhkar_qiyam_port.dart
├── data/adhkar_qiyam_today_adapter.dart
└── presentation/  # real Adhkar/Qiyam values; active Track tiles and quick hubs
lib/app/
├── composition/   # DI, preview adapters, Prayer→Adhkar/Qiyam time adapters
├── routing/       # /adhkar, /qiyam
└── l10n/          # AR/EN strings
lib/core/data/local/foundation_database.dart   # v10 + generated code
lib/core/data/sync/entity_dispatch_router.dart # adhkar_item, qiyam_night
supabase/migrations/0016_adhkar_qiyam.sql
supabase/tests/adhkar_*_test.sql, qiyam_*_test.sql
test/unit/features/{adhkar,qiyam}/, test/widget/features/{adhkar,qiyam}/
test/architecture/adhkar_qiyam_boundaries_test.dart
integration_test/adhkar_qiyam_{flow,offline_sync,localized_route}_test.dart
.github/scripts/ and .github/workflows/foundation-ci.yml   # files added to the prayer groups
```

**Structure Decision**: extend the existing feature-first app with two new feature folders. Shared changes are bounded:
- one Prayer read port;
- two XP sources;
- one local migration and one remote migration;
- two dispatcher registrations;
- the Today bridge;
- the routes.

No authentication UI, notifications, Quran work or new sync protocol.

## Complexity Tracking

No constitutional violations. One new font asset is justified by the dense tashkeel in the adhkar text; the prototype already relies on the same font stack.
