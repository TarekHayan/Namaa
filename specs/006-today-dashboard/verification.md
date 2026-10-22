# Dashboard / Today 006 — implementation evidence

**Baseline checked:** 2026-10-22 on `namaa/006-today-dashboard` at `033da906f02da55661798bfc6fb1990783d6e2f1`. This is the existing code baseline, not a commit containing 006 implementation. Phase 1 only prepares test fixtures and this ledger; no runtime behavior or acceptance result is claimed.

## Boundaries

- Tasks 003 owns Task records, ordering, completion and overdue rules. Habits 004 owns schedules, day completions and streaks. The shared XP ledger owns awards. Today will read those authorities and call their commands; it must not add a competing writer, history, or sync mechanism.
- Local preview keeps two existing identities: Tasks, Mind Maps and XP use `kTasksPreviewAccountId` (`00000000-0000-4000-8000-000000000003`); Habits uses `kHabitsPreviewAccountId` (`00000000-0000-4000-8000-000000000004`). They are intentionally distinct and must not be merged or migrated. Real account mode binds the three owners to the same resolved account. Unknown/signed-out real sessions display no prior owner's data.
- No production records are seeded by Phase 1. `test/support/today_fixtures.dart` creates in-memory domain values and controlled streams for tests only. Existing preview and encrypted database contents are not changed.

## Functional requirement ledger

Every requirement is **unverified** until an executed check is recorded with its result and evidence. Planned proof is from the specification and quickstart, not an executed outcome.

| ID | Planned proof | Status |
|---|---|---|
| FR-001 | Direct preview root, owner areas and preferences without sign-in | Unverified |
| FR-002 | Scheduled-today Task fixture including completed rows and exclusions | Unverified |
| FR-003 | Owner Habit due/retained-completion and streak comparison | Unverified |
| FR-004 | Independent ratios, rounding, empty and unavailable states | Unverified |
| FR-005 | Actual award ledger at local-day boundaries; deleted/reopened Tasks | Unverified |
| FR-006 | Task completion/reopen owner command, map link and single award | Unverified |
| FR-007 | Habit current-day complete/undo and stale-day rejection | Unverified |
| FR-008 | Existing owner creation flows, navigation and read-only opening | Unverified |
| FR-009 | Timed/untimed agenda, equal-time order and saved duration | Unverified |
| FR-010 | At most three eligible Do First Tasks, today/overdue only | Unverified |
| FR-011 | Overdue count and identity equality with Tasks owner | Unverified |
| FR-012 | Midnight, resume, timezone and date-sensitive command guards | Unverified |
| FR-013 | Local and synchronized owner changes visible within two seconds | Unverified |
| FR-014 | Offline save/restart/sync, failure handling and deduplication | Unverified |
| FR-015 | Real/preview scope isolation and delayed account switching | Unverified |
| FR-016 | Independent loading/empty/available/unavailable/retry states | Unverified |
| FR-017 | No fabricated future-domain metrics or active controls | Unverified |
| FR-018 | Arabic/English, RTL, semantics and keyboard/touch access | Unverified |
| FR-019 | Owner authority, no Today store or parallel sync/writer | Unverified |
| FR-020 | Functional prototype structure and five-target parity | Unverified |

## Acceptance measurements

No acceptance criterion has been executed or passed in Phase 1. Record device, build/commit, fixture, method, measured result and link/log before changing a status.

| ID | Required measurement/evidence | Status |
|---|---|---|
| SC-001 | Exact owner equality over mixed dates/deletions/schedule edits/map links/empty day; Tasks 4/10 and Habits 2/5 each 40%; Do First scope and actual XP | Unverified |
| SC-002 | 500 Tasks, 100 Habits, 200 awards; initial view and local action visible within 2 s on one mobile and one desktop target | Unverified |
| SC-003 | Ten offline action journeys across restart and later sync; one lifetime Task award, no Habit XP; ten read-only refreshes with zero business/pending writes | Unverified |
| SC-004 | Foreground midnight within 1 min, resume/timezone within 2 s; reject stale-day Habit action and preserve history | Unverified |
| SC-005 | Each failed/hung source shows recovery within 10 s; other sections remain usable; recovery within 2 s; zero foreign account/preview values | Unverified |
| SC-006 | Arabic and English mobile/desktop journeys; equivalent owner/offline behavior on Android, iOS, Windows, macOS, Linux; touch and keyboard journeys each within 3 min | Unverified |
| SC-007 | Two devices, same-account sync on matching and differing local dates; matching owner state and no duplicate awards/map-linked counts | Unverified |

## Phase 1 checks

- `dart format` completed for `test/support/today_fixtures.dart` and `test/unit/features/today/today_fixtures_test.dart`.
- Targeted `dart analyze` on those two files: **No issues found**.
- A direct Dart runtime smoke check instantiated the owner aggregates and confirmed the fixture's Tasks 4/10, Habits 2/5, and delayed session lookup after an A-to-B switch. It exited successfully. The temporary smoke script was removed.
- The first focused Flutter invocation could not access the SDK lockfile in the restricted workspace environment. Running only `test/unit/features/today/today_fixtures_test.dart` with SDK lockfile access exposed an asynchronous stream-delivery expectation in the test; the fake/test were corrected and the same file was rerun: **3/3 tests passed**. This is fixture verification, not a Today acceptance result.
- Existing encrypted database and preview records were not opened or modified by these checks. Runtime source files were not changed.

## Phase 2 foundation checks

- Implemented T003–T010 only: in-memory scope, calendar and owner reference values; independent section health; read-only owner/calendar ports; a device calendar adapter; closed composition-owned preview/account resolver; and an owner-boundary scanner. No schema, cloud endpoint, business writer, or existing preview data was changed.
- Before implementation, the new calendar and scope tests failed to compile because their intended adapters were absent. After implementation, the focused `test/unit/features/today`, `test/unit/app/composition/today_scope_resolver_test.dart` and `test/architecture/today_boundaries_test.dart` run passed **20/20 tests**. The existing `test/architecture/domain_dependency_test.dart` passed **6/6 tests**. After strengthening the award-write negative control, `test/architecture/today_boundaries_test.dart` passed **4/4** on its focused rerun.
- `dart analyze` on the new Today source, resolver and focused tests reported **No issues found**. `dart format` completed for the same Dart files.
- Tests cover both existing preview IDs, equal real-account owners, signed-out/unknown clearing, mismatched context rejection, delayed initial lookup, local date/offset changes, half-open XP intervals, 23/25-hour days, source status invariants and package/relative import bypass controls.
- These are foundation checks, not end-to-end acceptance: SC-001–SC-007 remain **unverified**. Phase 3 and later owner/UI/device work is still required.
