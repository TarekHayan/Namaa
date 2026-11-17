# 009 Adhkar and Qiyam — implementation evidence

This file records 009 evidence only. Evidence from earlier features (001, 003–008)
stays in their own `specs/NNN-*/verification.md` files and is never copied here.

## Baseline (2026-11-09, before Phase 1)

- Branch: `namaa/009-adhkar-qiyam`, head `60a2de4` ("docs(009): specify, clarify,
  plan and break down Adhkar and Qiyam"). Working tree clean.
- Flutter 3.41.8; Dart 3.11.5; Windows x64 host (owner's machine).
- Local schema is **9** (`kFoundationSchemaVersion = 9` in
  `lib/core/data/local/foundation_database.dart:30`). Phase 1 changes no schema.
- Existing Supabase migrations: 0001–0015, ending in
  `0015_prayer_reports_and_rewards.sql`. Phase 1 runs no database operation.
- Prototype inputs physically present (untracked `prototype/` folder):
  `prototype/src/data/adhkarData.ts` and `prototype/src/views/QiyamView.tsx`
  (read in T002).
- Spec requirements checklist (`checklists/requirements.md`): all items checked;
  read-only, not modified.
- No ignore-file change is needed: existing `.gitignore`/`.dockerignore` already
  cover generated, build, prototype-extraction and secret paths.
- Phase 1 makes no behavior change: it records this baseline, prepares the
  content draft for the owner's review (T002), and adopts the Amiri font asset
  (T003).

## T002 — content-sources draft

The draft [content-sources.md](content-sources.md) is complete (2026-11-09) and
**pending owner review**; nothing is approved or shipped from it (T073 gates
T006).

Review method and evidence recorded in the draft itself:
- Arabic texts compared byte-by-byte against حصن المسلم (official text via
  Seen-Arabic/Morning-And-Evening-Adhkar-DB, MIT, Arabic matched the official
  wording and takhreej).
- Every hadith number checked: dorar.net grading quoted verbatim with URLs, and
  sunnah.com pages fetched for identity (first English words quoted). Evening
  e4/e9 verified directly; morning m1–m6 and m7–m10 plus the two Qiyam
  supplications verified through focused dorar/sunnah passes.
- Verified defects recorded as owner decisions D1–D9, notably: m9 mixes the
  ×10 text with the ×100 virtue/references; m7/e7 "حسبي الله ×7" is graded
  موضوع by الألباني with a منكرة زيادة (Ibn Kathir, Arna'ut) on أبو داود 5081;
  m5/e6's أبو داود 5072 is a weak different-wording variant; m3's أبو داود
  number is wrong (5068, not 5071); m10's exact ×100 formula is ابن ماجه 3815;
  the English translation family has no documented license (D3).

## T003 — Amiri font adoption

Adopted from the official upstream release (2026-11-09):

| Item | Value |
| --- | --- |
| Release | [Amiri 1.003](https://github.com/aliftype/amiri/releases/tag/1.003) (`aliftype/amiri`, latest at adoption) |
| Archive | `Amiri-1.003.zip` |
| Archive SHA-256 | `81af0aff7d2086d8af24cea7202f7546130997982534691373485cd96744d05e` |
| Copied font | `Amiri-Regular.ttf`, 437,780 bytes, SHA-256 `cd2550c0f4c05eb341bf97958211aaa39382bca96577ba3a67d4a3b4912c43c0` |
| Copied license | `OFL.txt` (SIL Open Font License 1.1, header verified: "Copyright 2010-2022 The Amiri Project Authors") |
| Registered in | `pubspec.yaml` `flutter.fonts` as family `Amiri` (Regular only) |

- Extraction was done in a temporary directory outside the repository; only
  `Amiri-Regular.ttf` and `OFL.txt` were copied into `assets/fonts/amiri/`.
- No other font, package or dependency changed (T072 will re-audit).
- `python .github/scripts/pub-get-with-retry.py` (= `flutter pub get`)
  resolved successfully after registration; no locked version changed.

## Phase 2 foundational verification (T004–T019, 2026-11-09)

**PASS**. Implemented: the validated catalog model, the fixed NS009 identity
adapters with cross-language RFC 4122 vectors, the read-only Prayer day
boundaries port, the two new server-derived XP sources, local schema v10 with
additive migration, and remote migration 0016 with catalog seed, receipts,
conflicts, typed RPCs and RLS.

- **T004/T005** (catalog): red first (undefined model), then
  `flutter test test/unit/features/adhkar/domain/adhkar_catalog_test.dart` —
  **14 passed**.
- **T009/T010** (identity): `flutter test test/unit/features/adhkar/data/adhkar_identity_test.dart
  test/unit/features/qiyam/data/qiyam_identity_test.dart` — **9 passed**
  (vectors computed with Python uuid5; NS009 =
  `70ca78e3-a267-4a2f-883f-1e0dea2df0c3` recorded in research.md R6 and the
  tasks.md fixed facts).
- **T011/T012** (Prayer boundaries): red first, then
  `flutter test test/unit/features/prayer/application/prayer_day_boundaries_test.dart`
  — **5 passed**; the full prayer unit suite stays green (**78 passed, 1
  skipped**), so the Prayer screen behavior is unchanged.
- **T013/T014** (XP sources): red first (20 undefined-name errors), then
  `flutter test test/unit/features/xp test/unit/features/today/data/xp_today_adapter_test.dart`
  — **18 passed**. `XpAward` accepts `adhkar_set_done` only with 15 and
  `qiyam_done` only with 30; Task 20 and Prayer 10/5 unchanged;
  `XpTodayAdapter` needed no change (generic per-owner pass-through; awards
  stay unique by account/source/source_id).
- **T015/T016** (local v10):
  `flutter test test/unit/core/data/local/` — **50 passed** after:
  - `AdhkarItemCounts` and `QiyamNights` added, `kFoundationSchemaVersion = 10`,
    migration step + 6 indexes, code regenerated with
    `dart run build_runner build --delete-conflicting-outputs` (883 outputs).
  - `test/fixtures/prayer/migrations/schema_versions.json` gained a v10 entry
    (one added line).
  - Version-literal updates in the existing migration tests (v9 → v10):
    prayer_migration_test.dart, habit_counter_migration_test.dart — the same
    kind of update each schema bump requires; no assertion weakened.
  - The fixture manifests include the two new tables so pre-v10 physical
    shapes reconstruct correctly (the same column-drop pattern the prayer
    fixtures already used).
  - `TemporaryDatabasePath.dispose` in test/support now retries briefly and
    leaves a visible warning instead of failing a passing test: on this
    Windows host the background-isolate file lock can outlive `close()` by
    seconds (measured up to 5 s); locked directories are removable the moment
    the test process exits (verified manually). Assertions are unaffected.
- **T017–T019** (remote 0016): red evidence first — with migrations
  0001–0015 only, all 8 new pgTAP files failed because the 0016 functions and
  tables did not exist (`supabase test db`, 2026-11-09). After writing
  `supabase/migrations/0016_adhkar_qiyam.sql` (catalog seed v1 = 19 items,
  record/receipt/conflict tables, `apply_adhkar_item_change_v1`,
  `apply_qiyam_night_change_v1`, sha256 note component in the descriptor,
  RLS with select-only grants, no anon execution) and two test-side fixes
  (pgTAP plan counts, JSON arrow extraction, stale-base conflict scenarios):
  - `supabase test db` — **All tests successful. Files=24, Tests=331,
    Result: PASS** (2026-11-09), including every 0003–0015 suite.
  - The conflict-ID proofs cross-check the shared NS009 construction with
    `extensions.uuid_generate_v5` against `adhkar_record_id_v1` and the
    descriptor builders.

Final Phase 2 gates (2026-11-09):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (10 files formatted first) |
| Analyze | `flutter analyze` | No issues found |
| Dart tests | `flutter test` | **773 passed, 1 skipped** (07:51) |
| SQL | `supabase test db` (Docker Desktop started, `supabase start -x mailpit`) | **PASS — Files=24, Tests=331** |

Deferred from Phase 2 (deliberate):
- **T006–T008** (catalog asset + loader): blocked by design until the owner
  approves content-sources.md (T073). T005's validation model and the loader
  contract tests (T007) are ready to run once the asset exists.
- No push to staging or production; migration 0016 exists locally only.

## Phase 2 review fixes (2026-11-10)

All nine findings from the Phase 2 review of commit `5fd732a` are fixed.
Correctness fixes went failing-test-first; no existing assertion was weakened
or deleted.

1. **Server catalog seed (0016).** The 19-row seed insert was removed from
   `0016_adhkar_qiyam.sql`; the table and constraints stay and the table is
   empty until T006. Guard: `flutter test
   test/unit/features/adhkar/data/catalog_seed_sync_test.dart` — **1 passed**;
   it pins the seed to the approved asset when the asset exists and asserts
   0016 seeds nothing before that. The four Adhkar pgTAP files now seed their
   own fixture rows inside their transactions. tasks.md T006 carries the
   seed-generation note.
2. **Qiyam supplication approval.** Failing test first (unapproved
   supplication still parsed), then the `approved != true` filter now applies
   to `qiyam_supplications` like the items. `flutter test
   test/unit/features/adhkar/domain/adhkar_catalog_test.dart` — **15 passed**.
3. **XP award timestamp window.** pgTAP cases red first (caught: no
   exception × 4), then both RPCs reject (22023) a `p_updated_at` outside
   `[day − 1 day, day + 2 days)` in UTC. `supabase test db` — PASS; the
   contract now states the rule.
4. **Preferences read failure.** Failing test first, then
   `PrayerDayBoundariesReader` returns `Unavailable('prayer.preferencesUnavailable')`
   on an `AppResult` failure; only a successful null yields `SetupRequired`.
   Covered by a dedicated test in `prayer_day_boundaries_test.dart`.
5. **changes() transitions.** Failing test first (all four transitions), then
   `changes` emits on null→value, value→null and value→different, and never
   for the initial observation or repeats. The foreign-owner emission is
   treated as a removed location.
6. **Adhkar descriptor carries catalog_version.** pgTAP case red first
   (arrival order decided the winner), then
   `adhkar_version_descriptor_v1(updated_at, catalog_version, count)` produces
   `<micros>:<catalog_version>:<count>`; both arrival orders converge to
   catalog 2 in the new cases. contracts/adhkar-qiyam-sync.md and
   data-model.md document the shared descriptor format.
7. **dispose throws again.** `TemporaryDatabasePath.dispose` retries for up
   to one second then rethrows (Phase 2 review finding 7), so a real leaked
   handle fails the test. `flutter test test/unit/core/data/local/` —
   **51 passed** with the throwing dispose: no test leaks a handle; the
   earlier deletion failures came from the broken v3–v5 fixture manifests
   (fixed in the Phase 2 work).
8. **Migration hook per step.** Failing test first (the 4-param closure did
   not compile against the 3-param type), then `testMigrationHook(migrator,
   from, to, step)` fires exactly once per executed upgrade step with the
   step identified; the new test asserts `['7>10@8', '7>10@9', '7>10@10']`
   for a v7→v10 upgrade. The six existing hook closures (and the
   integration-test one) gained the `step` parameter; assertions unchanged.
9. **Shared conflict function renamed.** `adhkar_conflict_id_v1` →
   `adhkar_qiyam_conflict_id_v1` (definition, both RPC call sites, revoke and
   grant statements). No test referenced the old name.

Final gates for this fix set (2026-11-10):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Dart tests | `flutter test` | **777 passed, 1 skipped** |
| SQL | `supabase test db` | **PASS — Files=24, Tests=341** |

No push, no staging, no production; 0016 remains local-only. T006 and Phase 3
were not started.

## Phase 3 (US1) — partial, T020–T033 (2026-11-11)

**Implemented**: the AdhkarClock, the derived Adhkar streak, the transactional
count repository and unit of work, the IncrementDhikr/ResetDhikr commands, the
Prayer→Adhkar times adapter, the catalog loader (against the review fixture),
the AdhkarCubit, the ARB strings and the screen with its three widgets.

Owner decisions recorded in this phase:
- **Unavailable schedule** (owner, 2026-11-10): the lists stay visible but
  counting is locked, with a notice; no calendar-day fallback. Only
  `SetupRequired` is unrestricted on the device calendar day (FR-006a).
- **Celebration** persists on the state until the next command starts
  (one-shot per completion); the widget renders it from the state.

Test-first evidence (each pair red before its implementation):

| Task | Proof |
| --- | --- |
| T020/T021 clock | red (48 undefined errors) → `adhkar_clock_test.dart` **8 passed** (before-Fajr previous-day Evening, Fajr–Maghrib Morning, Maghrib→midnight→Fajr one Evening, unrestricted, unavailable lock, DST, next boundary) |
| T022/T023 streak | red → `adhkar_streak_test.dart` **6 passed** (3+partial=3→4, gap, one list, 3650 cap, version change) |
| T024/T025 repository | red (22 errors) → `drift_adhkar_repository_test.dart` **7 passed** (count+1 + provisional award + outbox in one transaction, at-target no-op, reset keeps the award, rollback leaves nothing, owner isolation, completed-days query) |
| T026/T027 commands | red (50 errors) → `adhkar_commands_test.dart` **11 passed** (dayChanged, outsidePeriod(startsAt), atTarget, countingLocked, reset outside the period, reset on another day, one `now` sample, monotonic bump, failure propagation) |
| T028 adapter | red → `prayer_adhkar_times_adapter_test.dart` **6 passed** (mid-day Morning, before-Fajr previous-day request order ['D', 'D-1'], setupRequired unrestricted on the device day, unavailable with no fallback, preferences-read failure, port failure) |
| T007/T008 loader | red → `asset_adhkar_catalog_test.dart` **5 passed** against `test/fixtures/adhkar_qiyam/catalog_fixture.json` (approved-only, malformed → contentUnavailable, invalid → contentUnavailable, cached per version). The real asset path is NOT registered in pubspec.yaml (T006 pending) |
| T029/T030 cubit | red (88 errors) → `adhkar_cubit_test.dart` **9 passed** (tab follows the period, exactly one boundary timer that re-resolves, resume refresh, pending→saved counts, failed feedback, one celebration transition, post-close results dropped) |
| T031 strings | the Adhkar strings appended to both ARB files line by line (no re-serialization); `flutter gen-l10n` passed; `adhkar_strings_adapter.dart` created |
| T032/T033 screen | red → `adhkar_screen_test.dart` **10 passed** (prototype order, disabled at target + outside the period via the Evening switch, tap + reset commands, keyboard, virtue toggle, EN-translation-only + Amiri on the Arabic text, count semantics, one celebration transition, AR/EN × light/dark × 320 px × 200% with no overflow) |

Notes:
- `fake_async` was added to `dev_dependencies` (already a transitive
  `flutter_test` dependency, same resolved version) for the boundary-timer
  test. Flagged for the owner's awareness; no runtime dependency changed.
- The commit-transaction receives the approved item set from the catalog the
  screen shows (set completion and the provisional award are judged against
  that same set).
- Command timestamps are the single real `now` sample (inside the server's
  award window for the current Adhkar day); an unavailable clock state locks
  counting and never guesses a day.

Final gates for this phase (2026-11-11):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Dart tests | `flutter test` | **838 passed, 1 skipped** — All tests passed |
| SQL | `supabase test db` | not run: nothing under `supabase/` changed in this phase |

**Blocked (by design):** T034 (composition registration), T035 (routes and
shell), T036 (integration test) — they need the owner-approved catalog
(T006/T073). The real asset is not shipped; no catalog seed was added to 0016.

## Phase 3 review fixes (2026-11-11)

All nine findings from the Phase 3 review of commit `785bd5c` are fixed.
Correctness fixes went failing-test-first; no existing assertion was weakened
or deleted. The owner's 2026-11-10 decision (unavailable schedule: lists
visible, counting locked, no calendar-day fallback) is confirmed and kept.

1. **Cubit outcome handling.** Failing tests first (pending left dangling on
   early returns), then `_runCommand` handles every outcome: `DayChanged`
   refreshes the clock immediately (re-resolve, re-subscribe to the new day,
   select the period's tab) with no saved flash; `OutsidePeriod` records
   `outsidePeriodStartsAtUtc` with the new `outsidePeriod` item status;
   `CountingLocked` shows the `locked` status; `AtTarget` returns with no
   feedback flash. Unrestricted mode now schedules one timer to the next
   device midnight so the day rolls over while the screen is open.
   `adhkar_cubit_test.dart` — **16 passed**.
2. **The Morning starts-at instant.** Failing command test first (it expected
   the passed Fajr), then the locked list's next start is the clock's next
   boundary: during Evening the Morning start is the NEXT Fajr; during
   Morning the Evening start is Maghrib. The screen passes
   `clock.nextBoundaryUtc` for either locked list. Command test + the screen
   notice test (04:29) both pass.
3. **The streak is judged by counts, not awards.** Failing tests first (the
   reset day still counted; the synced day did not), then
   `fullyCompletedDays` reads one indexed range over `adhkar_item_counts`,
   judges each day against that day's recorded `catalog_version` with the
   approved item sets passed in, walks backward from today with an early
   exit at the first incomplete earlier day (today may be incomplete), and
   keeps the 3,650 cap. A day recorded under a version this device cannot
   judge is reported in `unjudgeable` and never guessed (v1 is the only
   shipped version, so the set is empty today; if a future bump makes old
   days unjudgeable the product owner decides). `drift_adhkar_repository_test.dart`
   — **9 passed**.
4. **Streak refresh gating.** Failing test first (10 non-completing
   increments), then the streak walk runs only on load, on a day change and
   when a command changes a list's completion state — never per tap.
   `adhkar_cubit_test.dart` — 16 passed including the new no-refresh case.
5. **Bad boundaries lock counting.** Failing adapter test first (the
   ArgumentError escaped), then the adapter wraps the scheduled resolution
   and reports the unavailable state for unordered instants or a lapsed
   window. `prayer_adhkar_times_adapter_test.dart` — **7 passed**.
6. **A read failure is never count 0.** Failing command test first, then both
   commands propagate a `readFresh` failure directly instead of continuing
   from zero. `adhkar_commands_test.dart` — **13 passed**.
7. **Domain types in the application layer.** `AdhkarCatalogPort.snapshot`
   returns the domain `AdhkarCatalog`; `AdhkarCatalogItemSnapshot` and
   `AdhkarCatalogSnapshot` are gone; the commands, Cubit and screen use the
   `AdhkarList` enum (no 'morning'/'evening' strings); the loader keeps its
   per-version cache. The domain catalog gained `item(itemId)` and
   `itemsOf(list)` lookups. Test fakes build the catalog through
   `AdhkarCatalog.fromJson` (validation stays mandatory).
8. **Resume keeps the user's tab.** Failing test first, then the period's tab
   is selected only on first load and when the period or the day actually
   changes. `adhkar_cubit_test.dart` — 16 passed.
9. **The duplicated `@override` annotations** on the commands are removed.

Final gates for this fix set (2026-11-11):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Dart tests | `flutter test` | **850 passed, 1 skipped** (05:46, run by the reviewer on the uncommitted fix set, Windows host) |
| SQL | `supabase test db` | not run: nothing under `supabase/` changed in this fix set |

Review follow-ups applied before the commit (2026-11-11, reviewer):
- The Cubit now judges a list's completion BEFORE the command runs, and a
  reset writes 0 into the local counts it compares against, so the streak
  refresh is not lost when the day's counts stream delivers the new row
  before the command returns. Two new tests in `adhkar_cubit_test.dart`
  (completion with the stream first; a reset that breaks a complete set).
  They were written after the fix, so no red run is recorded for them.
- The duplicated `AdhkarCatalog.itemsFor` was removed in favor of `itemsOf`
  (the catalog test now uses `itemsOf`).
- After these follow-ups: `dart format` clean, `flutter analyze` no issues,
  `flutter test test/unit/features/adhkar test/widget/features/adhkar
  test/unit/app/composition` — **116 passed**. The full suite was not re-run
  after these two small changes; its last full run is the 850-pass row above.

## Phase 4 (US2) — partial, T037–T048 (2026-11-11)

Implemented by GLM (`opencode/glm-5.3-flash-free` through OpenCode) from a
written brief, then reviewed, completed and verified by the orchestrator.
The implementer's run stopped at its free usage limit during its final gate
run, so every result below was observed by the orchestrator.

- **T037/T038** — `QiyamNight` (night D from Maghrib D; the most recent
  started night; no-schedule 12:00 rule; unavailable locks recording with no
  fallback, per the owner's 2026-11-10 decision) and `QiyamNightRecord` with
  validation. Tests: `qiyam_night_test.dart`, `qiyam_night_record_test.dart`.
- **T039/T040** — `QiyamRepository`, `DriftQiyamRepository` and
  `DriftQiyamUnitOfWork`: record + first-performed award (30 XP) + outbox
  (`qiyam_night`) in one transaction; Yes → No → Yes keeps one award.
  Tests: `drift_qiyam_repository_test.dart`.
- **T041/T042** — `QiyamNightPort` and `SaveQiyamNight` (nightChanged,
  locked, each validation failure, read failures returned, no path that
  writes a previous night). Tests: `save_qiyam_night_test.dart`.
- **T043** — `PrayerQiyamNightAdapter`: the last third from the shared
  `PrayerScheduleProjection`; unusable boundaries resolve to the locked
  state. Tests: `prayer_qiyam_night_adapter_test.dart`.
- **T044/T045** — `QiyamCubit`/`QiyamState`: defaults on Yes (4 rak'ahs,
  Witr on), 400 ms debounce, one boundary timer plus resume, stale-night
  guard, every command outcome handled, celebration only on the first Yes.
  Tests: `qiyam_cubit_test.dart`.
- **T046** — Qiyam strings added line by line to both ARB files, plus
  `qiyam_strings_adapter.dart`; no string uses "missed".
- **T047/T048** — `QiyamScreen` with the header, tracker and supplications
  widgets in the prototype order; supplications come from the approved
  catalog through `AdhkarQiyamSupplicationsAdapter` (placeholder fixture
  text only; no real content in code or tests). Tests:
  `qiyam_screen_test.dart`, `adhkar_qiyam_supplications_adapter_test.dart`.

Orchestrator review fixes applied before the commit:
- The no-schedule rule now steps back one calendar day instead of
  subtracting 24 hours (a 23-hour day before a daylight-saving change gave
  the wrong night). Added a month-boundary test; a DST-zone case cannot be
  forced from a unit test, so none is claimed.
- Closing the screen with a debounced note still pending now saves it
  instead of dropping it (the screen never called `flushPendingNote`). New
  test "closing the screen with a pending note saves it"; the plain-resume
  test now also asserts the save on close.
- Three analyzer findings fixed (duplicate import, unused import,
  unnecessary parentheses).

Gates (2026-11-11, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Qiyam tests | `flutter test test/unit/features/qiyam test/widget/features/qiyam test/unit/app/composition` | **113 passed** (after the review fixes) |
| Full suite | `flutter test` | **933 passed, 1 skipped, 1 failed** |
| SQL | `supabase test db` | not run: nothing under `supabase/` changed |

The single full-suite failure is
`test/unit/features/prayer/application/prayer_context_service_test.dart`
("cached year wins; after coverage ends offline local fallback is labelled":
expected `2027-01-01`, got `2026-12-31`). Phase 4 does not touch Prayer code.
The test waits on 10 ms ticks with 30 ms real delays, so it is timing-
sensitive under a loaded full run; run alone it passes (`+8: All tests
passed!`). It is recorded here as a flaky pre-existing test, not as a pass.

Blocked: T049 (DI, `/qiyam` route, shell section) and T050 (integration
test) depend on T035, which waits for the owner's content approval (T073).

## SC-001 — counting latency and the 30-second Qiyam journey

**Pending**: measured on a named phone and on desktop. Nothing claimed.

## SC-002 — content matches the documented source review

**Pending**: requires the owner's approval of `content-sources.md` (T073).

## SC-003 — persistence across restart and offline cycles

**Pending**: automated restart/offline cycles not yet run.

## SC-004 — XP awarded exactly once; conflicts stay visible

**Pending**: two-device tests with retries, duplicates and concurrent edits not
yet run.

## SC-005 — Qiyam last-third equals the Prayer screen

**Pending**: not yet verified.

## SC-006 — Home/Track equality and rendering matrix

**Pending**: AR/EN, light/dark, 320 px, 100–200% text scale on phone and desktop
not yet checked.

## Phase 5 (US3) — T051–T054 (2026-11-12)

Qiyam streak and paged history, on top of Phase 4's tracker (commit
418361f). Test-first per task: T051's domain tests were written and run
against a missing module first, then the implementation.

- **T051/T052** — `lib/features/qiyam/domain/qiyam_streak.dart` (pure, zero
  imports) and the repository queries. The walk asks for one night's verdict
  at a time with an early exit at the first night that breaks the run — it
  never reads all 3,650 nights and counts afterwards — and a failed read
  propagates as a failure, never a streak of 0. An unanswered current night
  does not break the run; an explicit "No" is definitive and breaks it even
  tonight; an earlier night with no record breaks it. History: one indexed
  range read per page of 30 nights, newest first, unrecorded nights included
  as entries with no row; `hasMore` ends at the first fully unrecorded
  window. Tests: `qiyam_streak_test.dart` (9), `drift_qiyam_repository_test.dart`
  extended (14 in the file, incl. the 3,650 cap seeded with 3,652 real rows,
  paging through a cursor, per-owner isolation, and a closed-store failure).
- **T053** — `QiyamCubit`: the streak and the first history page load with
  the night; both refresh only on load, a night change, or a save that
  changes the night's performed state — never on note, time or rak'ah edits
  (proven by 10 note edits plus rak'ah/Witr/time edits leaving the query
  counters at 1). `loadMoreHistory()` fetches the next page only (cursor =
  the oldest loaded night; the full history is never held). Stale results
  are discarded by epoch. A streak or history read failure shows as a
  failure and keeps the last good value — never 0 or an empty history.
  Tests: `qiyam_cubit_test.dart` (24).
- **T054** — strings added line by line to both ARB files (Qiyam streak,
  Prayed · {count} rak'ahs · Witr and its Witr-less variant, Did not pray,
  Not recorded, Load more, plus the two failure notices the failure rules
  need) and exposed through `qiyam_strings_adapter.dart`. New
  `qiyam_history_section.dart` (read-only; newest first; Load more hidden
  when the walk ends) and the streak chip in the header; the screen puts the
  history in a side column at ≥ 1024 px and below the supplications on the
  phone. The word "missed" appears nowhere in the Qiyam feature (the only
  repo hits are Prayer's 008 `prayerStatusMissed`). The Qiyam streak stays
  separate from the Adhkar, Habit and Prayer streaks by construction:
  `qiyam_streak.dart` imports nothing and the Qiyam store reads only
  `qiyam_nights`. Tests: `qiyam_history_test.dart` (8), including the
  desktop/phone layout split and the AR streak text.

Owner review points applied: early-exit walk (1); unanswered current night
vs explicit No (2); streak refresh only on load/night change/performed-
changing save (3); 30-per-page indexed paged history, read-only, next page
only (4); read failures shown as failures (5); no "missed" (6); separate
streak (7). T049/T050 stay untouched and no catalog asset was created (8).

Gates (2026-11-12, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Full suite | `flutter test` | **966 passed, 1 skipped, 0 failed** |
| SQL | `supabase test db` | not run: nothing under `supabase/` changed |

## Phase 5 review fixes (2026-11-12)

Four findings on commit e062461, each fixed failing-test-first; no existing
assertion was weakened (the two expectations that changed follow the review's
new rules and say so in their reasons).

1. **A 30-night gap hid all older history** — history now pages by RECORDED
   rows with a keyset on `night_date` (30 rows per page, newest first, one
   indexed range read per page, `before` = the oldest row already shown, and
   the fetch takes one extra row so `hasMore` is true only when an older row
   exists). The fixed 30-night window and its `rows.isNotEmpty` ending are
   gone. "Not recorded" is filled by the Cubit, only for the nights strictly
   BETWEEN two loaded records — never before the newest or after the oldest
   loaded row, and never for a new user. Tests: the 40-night-gap test
   reaches both clusters in one page and the Ramadan shape (full 30-row
   cluster) in exactly one "Load more" (`drift_qiyam_repository_test.dart`);
   the Cubit fills a two-night gap and an across-page gap
   (`qiyam_cubit_test.dart`); a new user sees an empty history with no "Not
   recorded" rows (Cubit + `qiyam_history_test.dart`).
2. **Tonight's "No" must not zero the streak (owner decision, 2026-11-12,
   matching research.md R9)** — the walk starts from the previous night
   whether the current night is unanswered OR an explicit "No" (it stays
   editable until the next Maghrib); any EARLIER "No" or missing record
   still ends the run. Ten performed nights then a No tonight are ten, and
   switching tonight to Yes makes eleven. Tests:
   `qiyam_streak_test.dart` (the old "tonight's No breaks" expectation was
   replaced by this rule) and the mirrored repository test.
3. **The streak walk issued one query per night** — the repository now
   reads descending batches of 60 recorded rows per indexed range read on
   `(account_id, night_date)` and serves the walk from memory; the early
   exit at the first breaking night and the 3,650-night cap are unchanged.
   Test: a 300-night streak measured through a query-counting
   `QueryInterceptor` (`FoundationDatabase.openEncrypted` gained a
   test-only `interceptor` injection point, like `testMigrationHook`):
   before the fix 302 queries, after it at most 8 while the streak value
   stays 300.
4. **The streak refresh compared against the form, not the stored record**
   — `_runSave` now captures `state.record?.performed ?? false` before the
   save, so a Yes that succeeds after a failed Yes (form already saying
   Yes, store still without the row) still refreshes the streak. Answering
   No on an unrecorded night no longer refreshes (the stored "No" changes
   no streak input tonight). Tests: `qiyam_cubit_test.dart` ("a save that
   succeeds after a failed one still refreshes the streak"; the
   performed-state test was rewritten for the stored-record comparison and
   now emits the saved row through the watch like production does).

Gates (2026-11-12, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Full suite | `flutter test` | **973 passed, 1 skipped, 0 failed** |
| SQL | `supabase test db` | not run: nothing under `supabase/` changed |

## Phase 6 (US4) — T055–T056, T059–T065 (2026-11-12)

Home/Track port and cross-device sync. Test-first per task; T057, T058 and
T067 stay open (they depend on T049, blocked by the owner's content
approval), and T066 stays open (Docker unavailable — see below).

- **T055/T056** — `TodayAdhkarQiyamPort` + `TodayAdhkarQiyamReference`
  (Morning x/N, Evening x/N, the period, tonight's state unanswered/yes/no/
  locked, both streaks) and `AdhkarQiyamTodayAdapter` talking to Adhkar/Qiyam
  through their application APIs only (no Drift tables). The Adhkar streak
  composition moved behind `AdhkarStreakService` (application) so Today
  reuses the existing walk instead of re-implementing it. An unavailable
  schedule is exposed honestly: counts 0/0, period null, streaks null (never
  0), tonight locked, and no day or night invented (owner decision,
  2026-11-10). Tests: `adhkar_qiyam_today_adapter_test.dart` (5).
- **T059/T060** — `SupabaseAdhkarSyncAdapter` + `SupabaseAdhkarGatewayImpl`
  over `apply_adhkar_item_change_v1`: the typed arguments map from the
  outbox payload (no owner, record id, list or XP amount); the receipt maps
  receipt/active/retained/conflictId/canonicalAward; `finalizeReceipt` on
  `DriftAdhkarRepository` settles the canonical set award by (source,
  sourceId) — never by item — upserts the conflict evidence by stable id and
  applies the server's active record only when no newer local work is
  pending or acknowledged, in ONE transaction before the coordinator's ACK;
  a failure rolls the whole finalization back and leaves the operation
  pending; an old response rebases the acknowledged base without
  overwriting the newer local version. Tests:
  `supabase_adhkar_sync_adapter_test.dart` (6).
- **T061/T062** — the Qiyam mirror over `apply_qiyam_night_change_v1`
  (`qiyam_remote_models.dart`, `supabase_qiyam_gateway.dart`,
  `supabase_qiyam_sync_adapter.dart`, `finalizeReceipt` on
  `DriftQiyamRepository`; the `qiyam_done` award settles with the night
  record id as its source id). Tests: `supabase_qiyam_sync_adapter_test.dart`
  (5). Both entity types register in `EntityDispatchRouter` through optional
  constructor parameters wired in composition only; the existing router
  tests stay unchanged.
- **T063/T064** — owner-scoped inbound readers with keyset pages ordered by
  `record_id` / `source_id` / `conflict_id` (Adhkar: counts, set awards,
  conflicts; Qiyam: nights, night awards, conflicts), each pass restarting
  from the start of the range and a failed page failing the pass without
  advancing anything; the server catalog is read once per version and cached
  (`AdhkarCatalogCache`); every row's owner is validated. The reconcilers
  apply snapshots atomically in one repository transaction: awards through
  the shared ledger (settling the provisional replica once), conflicts by
  stable id, counts/nights skipping pending descendants and never moving a
  newer acknowledged marker backwards. `AdhkarSyncService` and
  `QiyamSyncService` mirror `PrayerSyncService` (outbound engine first, then
  inbound, stale-owner guards), are domain-scoped, and a failure in them
  never fails or delays another domain — proven by
  `adhkar_sync_service_test.dart`, which runs the real `PrayerSyncService`
  alongside a failing Adhkar reader and shows Prayer still syncing (2
  tests). Tests: `adhkar_inbound_synchronizer_test.dart` (6),
  `qiyam_inbound_synchronizer_test.dart` (3). Wired through composition
  (repositories, gateways, adapters, readers, reconcilers, services) and
  started in `app.dart` next to Prayer's service.
- **T065** — read-only "Sync differences" views for both domains
  (`adhkar_conflicts_view.dart`, `qiyam_conflicts_view.dart`), fed by
  owner-scoped `watchConflicts` streams over `conflict_records` (entity-type
  filtered, newest detection first): both versions shown, no resolve action
  of any kind, no foreign-owner rows ever leave the store, and the Qiyam
  states reuse the history copy so "missed" never appears. Strings added
  line by line to both ARB files. Tests: `adhkar_conflicts_test.dart` (3),
  `qiyam_conflicts_test.dart` (2) — the store runs through `tester.runAsync`
  because the encrypted database lives in a background isolate.
- **T066** — `integration_test/adhkar_qiyam_offline_sync_test.dart` written
  (two encrypted stores, run-tagged operation IDs, a past day inside the
  server window, and the six cases). The local catalog fixture lives in
  `supabase/seed.sql` (catalog version 900 — IDs and targets only, never in
  a migration; the pgTAP tests own version 1 and seed inside their own
  transactions). **Not executed**: Docker Desktop was not running on this
  machine, so `supabase start`, `supabase db reset`, `supabase test db` and
  the Windows integration run could not start. The task stays unticked per
  the owner's instruction; nothing was pointed at staging.

Owner decisions honored: no calendar-day fallback anywhere in the Today port
or sync; tonight's "No" never zeros the streak (the services reuse the
existing walks); no real adhkar, supplication or Quran text anywhere — the
catalog fixture carries IDs and targets only.

Gates (2026-11-12, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Focused suites | `flutter test test/unit/features/today/data test/unit/features/adhkar test/unit/features/qiyam test/widget/features/adhkar test/widget/features/qiyam test/unit/core/data/sync` | **264 passed** |
| Full suite | `flutter test` | **1005 passed, 1 skipped, 0 failed** |
| SQL | `supabase test db` | not run: Docker Desktop unavailable |
| Integration | `flutter test integration_test/adhkar_qiyam_offline_sync_test.dart -d windows` | not run: Docker Desktop unavailable |

## Phase 6 review fixes (2026-11-12)

Four findings on commit e400c66, each fixed failing-test-first; no existing
assertion was weakened.

1. **Today x/N must equal the Adhkar screen (SC-006)** — the Today adapter
   now counts ITEMS exactly like `AdhkarState.completedOf/totalOf` (FR-005):
   completed = items at their target, total = the list's item count — no
   more summed repetitions/targets. A new parity test builds the same
   catalog and counts for the adapter and for `AdhkarState` and asserts
   identical Morning and Evening values (with the concrete numbers pinned:
   2/3 Morning, 1/3 Evening for its fixture). Tests:
   `adhkar_qiyam_today_adapter_test.dart`.
2. **A failed read is never zero progress** — `TodayAdhkarQiyamReference`
   gains `adhkarLoadFailed` / `qiyamLoadFailed`, separate from
   `scheduleUnavailable` (which keeps them false). A failed catalog
   snapshot, counts read or streak read raises `adhkarLoadFailed` (streaks
   stay null); a failed night record or night streak read raises
   `qiyamLoadFailed`. Five new tests, one per failed read.
3. **The "Sync differences" lists show no internal IDs or raw ISO dates** —
   the Adhkar entry title is now the list name plus the item's position
   from the catalog port passed to the view ("Morning adhkar · item 1" /
   "أذكار الصباح · الذكر 1"), falling back to the list name alone for an
   item the catalog does not know; the stored conflict payload now carries
   the list (`AdhkarRemoteModels.conflictPayload`, consumed by
   `_insertConflict` and exposed on `AdhkarConflictEvidence.list`). The
   formatted day/night renders as a secondary line with the app locale
   (`DateFormat.MMMEd`), in both `adhkar_conflicts_view.dart` and
   `qiyam_conflicts_view.dart`. New strings added line by line to both ARB
   files (`adhkarConflictListMorning/Evening`, `adhkarConflictItem`).
   Tests assert the new labels and that "m1" and the raw ISO date never
   appear, plus the unknown-item fallback (4 adhkar + 2 qiyam).
4. **The integration test is rerunnable** —
   `integration_test/adhkar_qiyam_offline_sync_test.dart` always uses a
   run-tagged operation ID and a random past day, on the local stack too
   (the fixed local day and the empty tag are gone); every `updated_at`
   still sits inside its day's server window [day − 1 day, day + 2 days).

Follow-up: `AdhkarCatalogCache` no longer caches an empty catalog read, so
a catalog seeded later is still picked up
(`adhkar_catalog_cache_test.dart`, 2 tests).

Gates (2026-11-12, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean |
| Analyze | `flutter analyze` | No issues found |
| Focused suites | `flutter test test/unit/features/today/data test/unit/features/adhkar test/unit/features/qiyam test/widget/features/adhkar test/widget/features/qiyam` | **259 passed** |
| Full suite | `flutter test` | **1014 passed, 1 skipped, 0 failed** |
| SQL | `supabase test db` | not run: Docker Desktop unavailable |
| Integration | `flutter test integration_test/adhkar_qiyam_offline_sync_test.dart -d windows` | not run: Docker Desktop unavailable (T066 stays unticked) |

## T066 — local-stack run (2026-11-13, Windows host)

The first run of the integration file failed on four test-side mistakes,
fixed in the test only (no production code changed):

1. The duplicate inbound pass asserted `importedConflicts == 0`, but the
   summary counts every conflict the pass applied, as Prayer's does. The
   stable-ID upsert is proven by the local `conflict_records` count staying
   at 1.
2. The final m3 commit passed a null acknowledged base. It now takes both
   preconditions from device A's local row (`expectedCurrentVersion` and
   `acknowledgedBase`), as the Cubit does.
3. The Qiyam Yes → No → Yes commits passed a null acknowledged base after
   acknowledged dispatches. They now pass the acknowledged version.
4. Device B's lost-ACK write claimed a current version it had never pulled.
   It now writes from an empty local row, and the later pull asserts that
   device B's night equals the server's active version, instead of a
   minimum import count.

| Gate | Command | Result |
| --- | --- | --- |
| Reset | `supabase db reset --local` | 0001–0016 applied, `seed.sql` loaded (catalog version 900) |
| SQL | `supabase test db` | **Files=24, Tests=337, PASS** |
| Integration | `flutter test integration_test/adhkar_qiyam_offline_sync_test.dart -d windows --dart-define=NAMAA_SUPABASE_ENV=local --dart-define=NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=<local stack key>` | **+1, all passed** |
| Rerun without reset | same command | **+1, all passed** (run tags and random past days make it rerunnable) |
| Format / analyze | `dart format … integration_test`, `flutter analyze integration_test` | clean, no issues |

Not covered: the hosted (staging) variant, which waits for 0016 on staging
(T076, owner approval).

## SC-007 — streak values for seeded patterns

**Qiyam portion verified 2026-11-12** (US3 checkpoint): seeded patterns
covered by `qiyam_streak_test.dart` and `drift_qiyam_repository_test.dart` —
consecutive nights count (3 stored → 3), a gap or an explicit "No" resets
the walk, an unanswered current night does not break the run behind it, the
3,650-night cap holds with 3,652 seeded rows, and a zone change that skips a
night date breaks at the absent night. The Adhkar portion of SC-007 is
covered by `adhkar_streak_test.dart` and the
`drift_adhkar_repository_test.dart` completion-walk tests (Phase 3); the
full matrix across both streaks is not yet recorded as one scenario run.

## SC-008 — countable exactly inside the time windows

**Pending**: not yet verified, including across midnight.

## Phase 7 (partial) — T068, T071, T072 (2026-11-13)

T068 adds `test/architecture/adhkar_qiyam_boundaries_test.dart` (mirroring
`prayer_boundaries_test.dart` and `today_boundaries_test.dart`, 5 tests).
It enforces, with a negative control per rule and a scan over the current
production code:

1. Adhkar and Qiyam never import each other (either direction, package or
   relative).
2. Neither imports `lib/features/prayer/**` at all — the Prayer day
   boundaries arrive only through ports wired in `lib/app/composition/`.
3. Today reaches Adhkar/Qiyam only through their `application/` and
   `domain/` folders, never `data/` or `presentation/`.
4. The AGENTS.md section 5 layer table for both features: domain imports
   domain only (no Flutter, Drift, Supabase, uuid, timezone, data,
   presentation or application); application never data/presentation and no
   infrastructure packages; data never presentation; presentation never
   data. Project-layer bans match only `lib/` targets, so third-party
   package paths (for example `package:timezone/data/…`) are not
   misread as project layers.
5. Storage stays in `data/`: `FoundationDatabase`, `SupabaseClient` and the
   local Drift getters (`adhkarItemCounts`, `qiyamNights`,
   `conflictRecords`, `xpAwards`) never appear outside `data/`, and the
   remote tables are never written with `.from(...).insert/upsert/update/
   delete` — remote writes go only through the versioned RPC gateways
   (reads stay legal).

The client secret scan still passes (part of the full suite below).
No rule failed on the current code — no import needed moving.

Gates (2026-11-13, Windows host, run once at the end):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (548 files, 0 changed) |
| Analyze | `flutter analyze` | No issues found |
| Full suite | `flutter test` | **1019 passed, 1 skipped, 0 failed** (1014 + the 5 new boundary tests) |
| Reset | `supabase db reset --local` | 0001–0016 applied, `seed.sql` loaded |
| SQL | `supabase test db` | **Files=24, Tests=337, PASS** |

The known-flaky `prayer_context_service_test.dart` "cached year wins…"
did not fail in this run.

## T072 — dependency and manifest audit (2026-11-13)

Compared against `develop` with
`git diff develop -- pubspec.yaml pubspec.lock android ios macos windows
linux`:

1. **New packages: exactly one — `fake_async: ^1.3.1`.** It is a
   **dev-only test dependency** (`pubspec.yaml` `dev_dependencies`;
   `pubspec.lock` moves `fake_async` from `transitive` to
   `direct dev`, same hosted version and hash), added for the Cubit
   timer/stream tests. Kept; nothing runtime-facing was added.
2. **No notification permission and no notification plugin (FR-015)** —
   `android/`, `ios/`, `macos/`, `windows/` and `linux/` are unchanged
   against `develop` (zero new plugins, zero manifest or entitlement
   edits). The registrant files only emit line-ending warnings.
3. **Assets: only the Amiri font and its license** —
   `assets/fonts/amiri/Amiri-Regular.ttf` plus `OFL.txt` (SIL OFL 1.1),
   declared as the `Amiri` font family in `pubspec.yaml` for the reviewed
   adhkar/supplication text (009, R8). No other asset added.

Nothing else appeared in the audited paths; no stop condition triggered.

## Phase 6b part A — T080, T081, T083–T090 (2026-11-16)

### T080 — catalog revision (owner decisions D3/D4, data-model.md revised)

`lib/features/adhkar/domain/adhkar_catalog.dart` now parses the Arabic-only
shape: `translation_en`, `virtue_en`, `reference_en` and `source_en` are
gone, `virtue_ar` is nullable, every item carries `kind` (`dhikr` | `quran`),
a `quran` item requires `surah`, `ayah_from` and `ayah_to` (`from ≤ to`) and
allows `preface_ar`, a `dhikr` item must carry no Quran fields, and the
document requires a non-blank top-level `attribution`. The item card renders
no English line in either language; a Quran item shows its preface apart
from the verses, the verses in the Quran font, and `surah: from–to`.
`QiyamSupplication` (both the catalog and Qiyam domain types) is Arabic-only
and the supplications card drops its locale switch. Fixture and test
catalogs updated with placeholder text only; an unapproved placeholder Quran
item sits in the fixture so the shape exists without moving any pinned
count. Tests: `adhkar_catalog_test.dart` (25), `asset_adhkar_catalog_test`,
`catalog_seed_sync_test`, command/cubit/today-adapter/widget suites.

### T081 — KFGQPC Uthmanic Hafs font

- **Source (documented by the Quran Foundation):**
  `https://api-docs.quran.foundation/docs/tutorials/fonts/font-rendering/`
  ("Font Files & CDN → Unicode Fonts → QPC Hafs / Uthmanic Hafs") lists
  `https://verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/UthmanicHafs1Ver18.ttf`
  (a TrueType file — Flutter loads it directly; no conversion needed).
- **File:** downloaded unmodified to
  `assets/fonts/kfgqpc_hafs/UthmanicHafs1Ver18.ttf`; 242,368 bytes;
  SHA-256 `a0636e68e375af9552470d67773936f54d536e6586ce2608311b2fe7f9cbec3a`;
  TTF magic `00 01 00 00` verified.
- **Registration:** family `KFGQPC HAFS` in `pubspec.yaml`; the verse text
  renders with it (`kQuranFontFamily` in `dhikr_item_card.dart`).
- **Bundling terms:** the same guide allows bundling with an active
  Developer Console account (the owner's app `7b420fdd-d5bc-48e1-a96e-
  d3094e1184f4`) and a reasonably accessible credit; the file ships only as
  an integrated part of the app.
- **Credit wording (shown as an `adhkar_attribution` footer line on the
  Adhkar screen — the app has no separate credits/about surface, so the ARB
  string `quranAttribution` is rendered where the catalog attribution
  belongs):**
  - EN: "Quran text and font: King Fahd Glorious Quran Printing Complex
    (KFGQPC), Madinah Mushaf, Hafs — provided through the Quran
    Foundation."
  - AR: "نص القرآن والخط: مجمع الملك فهد لطباعة المصحف الشريف، مصحف
    المدينة، برواية حفص — من خلال مؤسسة القرآن."
- **Done proof:** the widget test in `adhkar_screen_test.dart` renders a
  placeholder Quran item with the family (preface apart, verses in the
  Quran font, `test surah: 255–255`) and asserts the attribution line.
  The bundled copy should be revisited on new app releases, as the guide
  recommends, since font files can receive corrections.

### T083–T090 — My Adhkar local core (US5, FR-022…FR-027)

Tests were written first and confirmed failing before each implementation.

- **T083/T084** `my_dhikr.dart` (domain only): draft text 1–1000 after
  trimming (stored trimmed), target 1–1000 default 1, note ≤ 300 with a
  blank note normalized to null, `kMyDhikrItemLimit = 100` judging live
  items only, the FR-025 clamp `clampMyDhikrCount`, and a stored item whose
  `copyWith` cannot clear or move the `deletedAt` tombstone (18 tests).
- **T085** `MyAdhkarIdentityPort` + `UuidMyAdhkarIdentity`: UUIDv4 item
  IDs and `UUIDv5(NS009, 'my-adhkar/' + itemId + '/' + day)` count IDs.
  Two new vectors in `identity_vectors.json`, computed with Python's
  independent RFC 4122 implementation; the Dart adapter matches them, and
  they are the same values migration 0017's SQL helper must reproduce
  (`my_adhkar_identity_test.dart`, 4 tests).
- **T086** schema v11 in `foundation_database.dart`: `my_adhkar_items` and
  `my_adhkar_counts` with the data-model indexes (the item text column is
  named `content` in Dart but `text` in SQL), `kFoundationSchemaVersion =
  11`, regenerated code. Migration tests (`adhkar_qiyam_migration_test.dart`
  extended; `prayer_migration_test.dart` and `habit_counter_migration_test.dart`
  re-pinned): fresh v11 columns/indices/nullability, v10→v11 keeping real
  Adhkar and Qiyam rows across a restart, v9/v8/v1–v7 upgrades, the hook
  firing once per step (7→11 runs steps 8/9/10/11), and the v11
  failure/recovery case (journal `failed` then `recovered`). 52 local-store
  tests. AGENTS.md section 5 now says `kFoundationSchemaVersion = 11`.
- **T087/T088** `MyAdhkarRepository` (application port) +
  `DriftMyAdhkarRepository`: `watchItems` (live, oldest first),
  `watchCounts`, `readFresh` (returns the tombstone row), `readCountFresh`,
  `liveItemCount`, `runInTransaction` (a returned failure rolls everything
  back), transactional `insertItem`/`updateItem`/`markDeleted` (delete is a
  no-op on an already deleted item and never moves the tombstone) and
  `commitCount` with the adhkar stale-version backstop. Tests prove: the
  limit counts only live items, the clamp written in the SAME transaction
  as the edit (and a failure after the count write rolls BOTH back), the
  deleted item hidden from `watchItems`, outbox entity types
  `my_adhkar_item`/`my_adhkar_count` with create/update kinds, payloads
  without owner/list/XP fields, owner isolation, and zero `xp_awards` rows
  (9 tests).
- **T089/T090** `MyAdhkarCommands`: `add` (validation → limitReached →
  added), `edit` (validation → itemDeleted → day guard when scheduled →
  clamp in the same transaction; when the schedule is unavailable the edit
  applies and the clamp is skipped because there is no "today" — the screen
  shows min(count, target)), `delete` (tombstone, no-op on deleted),
  `increment`/`reset` (the same day guard as IncrementDhikr, no period
  check, locked when unavailable, `itemDeleted`, at-target no-op, reset
  always persists the 0 row). No command references XP anywhere; the tests
  assert `xp_awards` stays empty after every path (15 tests). The
  architecture test gains rule 6 with negative controls: no `my_adhkar_*`
  file imports `lib/features/xp/` in any layer (the reviewed-catalog set
  award path in the non-My-Adhkar files stays legal).

### Gates (2026-11-16, Windows host)

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (558 files, 0 changed) |
| Analyze | `flutter analyze` | No issues found |
| Focused suites | adhkar unit + composition + today adapter + local store + adhkar/qiyam widgets + boundaries | **260 passed** |
| Full suite | `flutter test` | **1078 passed, 1 skipped, 0 failed** |

The known-flaky `prayer_context_service_test.dart` "cached year wins…"
did not fail in this run. `supabase test db` was not part of part A: the
SQL side (0017 and its pgTAP tests) is T091 in part B.

## Phase 6b part 1 — single-ayah label (2026-11-16)

Review fix on 74c3dce: `DhikrItemCard` rendered "البقرة: 255–255" for a
single-ayah item. It now reads `surah: N` when `ayah_from == ayah_to` and
keeps `surah: from–to` for a range. The widget test renders both forms
(single-ayah item and a 255–256 range) and asserts the range dash never
appears for the single form. The edit/delete write guards (the other
review finding) are delivered with T100–T102 below, as instructed, since
that code is reshaped in the same session.

Gates (2026-11-16, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (558 files) |
| Analyze | `flutter analyze` | No issues found |
| Focused | `flutter test test/widget/features/adhkar/adhkar_screen_test.dart` | **11 passed** |
| Full suite | `flutter test` | **1078 passed, 1 skipped, 0 failed** |

## Phase 6b part 2 — My Adhkar collection and groups local core, T100–T102 (2026-11-16)

The owner reshaped My Adhkar on 2026-11-16 (spec.md Session 2026-11-16,
FR-022…FR-029; data-model.md "My Adhkar"): a personal collection of named
groups and entries made of exactly two fields — text (1–2000 code points
after trimming) and an optional free-text source (≤ 500 code points, plain
text, never opened) — with no target, note, counter, day, reset, day guard
or locked state. Schema v11 is unreleased, so it changed in place with no
v12. Tests were written first and confirmed failing before each task's
implementation.

- **T100** `my_dhikr.dart` reshaped: the entry draft validates text 1–2000
  and source ≤ 500 in code points (`runes.length`) and a non-empty group
  set; `MyAdhkarGroupDraft` validates the 1–60 code-point name; limits are
  1000 live entries and 100 live groups; the stored entry needs at least
  one group while live and may have none once deleted (the cascade);
  neither copy can clear a tombstone; no count code is left in the domain.
  A supplementary-plane character (U+1D400, one code point over two UTF-16
  units) counts as one. `MyAdhkarIdentityPort` becomes `newItemId()` +
  `newGroupId()` (both UUIDv4); the `my-adhkar/` count vectors were removed
  from `identity_vectors.json` and the identity test
  (`my_dhikr_test.dart` 18 tests, `my_adhkar_identity_test.dart` 2 tests —
  25 together).
- **T101** schema v11 reshaped in place: `my_adhkar_items` gains `source`
  and loses `target`/`note`; `my_adhkar_counts` is gone; `my_adhkar_groups`
  and `my_adhkar_item_groups` (with `added_at`) and their five indexes
  added; regenerated; the drift row class for groups is named
  `MyAdhkarGroupRow` so it cannot collide with the domain type. The
  repository port and `DriftMyAdhkarRepository` were reshaped:
  `watchGroups` (live groups oldest first, each with its live-entry count),
  `watchGroupItems` (membership `added_at` order), `readGroupFresh`,
  `liveGroupCount`/`liveEntryCount`, transactional group create/rename
  (the UPDATE guarded on `deleted_at IS NULL` and the prior `updated_at`)
  and the FR-029 `deleteGroupCascade` — group tombstone, memberships
  removed, every entry left with no live group tombstoned with a monotonic
  `updated_at`, and exactly ONE outbox entry (the group; the server applies
  the same cascade itself). Entry `updateItem` is guarded the same way and
  syncs memberships in the same transaction, keeping `added_at` for a kept
  group; `markItemDeleted` uses a monotonic `updated_at`
  (`max(now, prior + 1 microsecond)`), never before `createdAt`; the
  domain tombstone validation now requires UTC only, since a skewed clock
  may place the delete instant before creation while the monotonic
  `updated_at` still carries the version order. Outbox types are
  `my_adhkar_group` and `my_adhkar_item` only; every statement binds its
  inputs as parameters. Tests: `drift_my_adhkar_repository_test.dart`
  (9) and the migration suite re-pinned to the reshaped v11
  (`adhkar_qiyam_migration_test.dart`, `prayer_migration_test.dart`,
  `habit_counter_migration_test.dart` — 52 tests).
- **T102** `my_adhkar_commands.dart` reshaped: `CreateMyAdhkarGroup`,
  `RenameMyAdhkarGroup`, `DeleteMyAdhkarGroup` (one-transaction cascade,
  `previewDeleteGroup` returning the confirmation count), and `AddMyDhikr`,
  `EditMyDhikr(owner, itemId, draft)`, `DeleteMyDhikr` with the group set.
  `IncrementMyDhikr`, `ResetMyDhikr`, the day guard, the locked state and
  the Adhkar times dependency are gone. `groupDeleted` reports a deleted
  group in a draft's set or a rename/delete of a deleted group;
  `groupLimitReached`, `limitReached`, `itemDeleted` and typed validation
  failures are covered; the edit reads, checks and writes in one
  transaction; the delete's tombstone moves forward monotonically and a
  second delete is a no-op. No command references XP anywhere (FR-026) and
  the architecture rule 6 with its negative controls still passes
  (`my_adhkar_commands_test.dart` 14 tests).

Gates (2026-11-16, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (558 files) |
| Analyze | `flutter analyze` | No issues found |
| Focused suites | adhkar unit + local store + boundaries + composition + today adapter + adhkar/qiyam widgets | **299 passed** |
| Full suite | `flutter test` | **1080 passed, 1 skipped, 0 failed** |

The known-flaky `prayer_context_service_test.dart` "cached year wins…"
did not fail. `supabase test db` and the local-stack integration run are
PART 3 (T091–T099) gates and were not run here.

## Phase 6b part 3a — monotonic My Adhkar group delete (2026-11-16)

Review fix on d71a770: `deleteGroupCascade` stamped the group with
`updated_at = deletedAt` (now) and built the outbox row through
`copyWith(updatedAt: deletedAt)`, which threw — and rolled the delete
back — when the device clock sat behind the group's `created_at`, and the
version could go backwards anyway. The fix stamps the group's `updated_at`
and the outbox `version_timestamp` with the same monotonic rule as
`markItemDeleted` (`max(now, prior.updated_at + 1 microsecond)`) and builds
the outbox group directly. Two new tests prove it (one in the drift
repository, one over the commands): a delete issued with the clock one
hour before the group's creation succeeds, its `updated_at` is greater
than the prior version, and exactly one outbox row carries the delete. The
commands-test seed for the 1000-entry limit was also gathered into one
transaction: 999 separate transactions sat at the 30-second test timeout
on Windows (one commit each). One full-suite run showed the known-flaky
`prayer_context_service_test.dart` "cached year wins…" failing
(`flutter test test/unit/features/prayer/application/prayer_context_service_test.dart`
alone: **8 passed** — recorded as flaky, not a pass).

Gates (2026-11-16, Windows host):

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (558 files) |
| Analyze | `flutter analyze` | No issues found |
| Full suite | `flutter test` | **1082 passed, 1 skipped, 0 failed** (after the flaky rerun above) |

## Phase 6b part 3b — My Adhkar sync migration 0017 (T091) (2026-11-17)

`supabase/migrations/0017_my_adhkar.sql`, additive on 0016: the
`my_adhkar_groups`, `my_adhkar_items` and `my_adhkar_item_groups` tables
(the membership join has foreign keys to the owner's entry and group),
`my_adhkar_operation_receipts` and `my_adhkar_conflicts`, RLS and grants as
in 0016 (owner `select` only; no client write, no anon execute), and the two
typed RPCs `apply_my_adhkar_group_change_v1` and
`apply_my_adhkar_item_change_v1` (`p_group_ids uuid[]`). There is no count
table, no count RPC and no `xp_awards` write. An earlier draft of the file
existed untracked; it was rewritten because it (a) rejected a create that
names only deleted groups with `group_missing` instead of `group_deleted`,
(b) validated and fingerprinted `p_group_ids` on a delete although the
contract says a delete ignores them, (c) let an older delete lose to a newer
live edit, which would let a locally deleted entry come back on the next
sync, and (d) treated two deletes with different timestamps as a conflict.

Rules implemented (contracts/adhkar-qiyam-sync.md, "My Adhkar"):

- Idempotent per `(owner, operation_id)`; the fingerprint covers the
  creation instant and the version descriptor (text/source/group hashes,
  group ids sorted) and excludes the base; a reused ID with different
  content is rejected with no side effects.
- Lengths in code points on the trimmed text (text 1–2000, source <= 500
  with blank stored as null, group name 1–60); `updated_at` at most two days
  ahead; duplicate or empty `p_group_ids` on a live entry rejected; an entry
  delete with an empty `p_group_ids` accepted (a delete ignores the set).
- `group_missing` (retryable, nothing written) for a group the account's
  rows do not hold; `group_deleted` (entry stored as deleted, the submitted
  version kept as one conflict) for a create or edit naming only deleted
  groups; `limit_reached` for the 1001st live entry and the 101st live
  group.
- Group delete cascade in the same transaction: entries left with no live
  group are deleted with a strictly greater `updated_at`, the group is
  dropped from every membership, and no per-entry receipt is written.
- A delete is final and wins over a live version whatever the timestamps
  (the stored version still moves forward by at least one microsecond so
  other devices pull it); a later edit or rename of a deleted record,
  newer or older, is kept as a conflict and never applied.
- Newest wins between live versions; the equal-timestamp tie goes to the
  greater byte-ordered descriptor; one stable conflict per pair whatever the
  arrival order.
- One owner-level advisory lock orders every My Adhkar write of an account,
  so the limits, the cascade and the entry-to-group check cannot race.

pgTAP (`my_adhkar_account_isolation_test.sql` 28,
`my_adhkar_operation_integrity_test.sql` 32,
`my_adhkar_conflict_integrity_test.sql` 21) covers every item of the
contract's "My Adhkar" proof line: access control (anon, no claims, foreign
owner, direct writes, RLS), malformed input, both limits, the cascade,
`group_deleted` on an edit and on a create, `group_missing`, deletes that
stay final against older and newer edits, a delete over a newer live edit,
a rename of a deleted group, newest-wins with one stable conflict across
both arrival orders (two owners play the two orders) and the equal-timestamp
tie, replay and reused-ID collision, an entry delete with empty
`p_group_ids`, and zero `xp_awards` rows.

Gates (2026-11-17, Windows host, LOCAL stack only: `supabase db reset
--local`; nothing was pushed or linked, staging and production untouched):

| Gate | Command | Result |
| --- | --- | --- |
| Local schema | `supabase db reset --local` | migrations 0001–0017 and seed applied |
| SQL/RLS | `supabase test db` | **27 files, 418 tests, all passed** (the three My Adhkar files: 81 tests) |

## Phase 6b part 3c — My Adhkar outbound sync (T092–T093) (2026-11-17)

`supabase_my_adhkar_gateway.dart` (the two typed RPCs plus the single-row
fetches for the remote-version lookup; the argument maps live in
`MyAdhkarRpcParams` so they are testable without a network),
`supabase_my_adhkar_sync_adapter.dart` (the dispatcher for both entity
types) and `my_adhkar_remote_models.dart` (receipt, active/retained and
conflict parsing with owner, operation and record identity checks), plus
the local finalization in `drift_my_adhkar_repository.dart`
(`finalizeGroupReceipt`, `finalizeItemReceipt`, read-only conflict evidence
and `watchConflicts`). `my_adhkar_group` and `my_adhkar_item` are registered
in `EntityDispatchRouter` through composition. No ordering code was added:
the sync engine already dispatches pending changes in `created_at` order
(`DriftLocalStore.readPendingChanges`), and the test below proves the order
across both entity types.

Behavior pinned by `supabase_my_adhkar_sync_adapter_test.dart` (23 tests):
the exact RPC arguments for a group, an entry with its sorted `p_group_ids`
and a delete (empty set, no owner, XP, count or day key); receipt parsing of
a server-shaped outcome including `group_deleted` and a kept conflict, and
rejection of a foreign owner or a mismatched identity; finalization in one
repository transaction before `DispatchAcknowledged` (acknowledged version =
the server's active version); a kept membership keeps its local `added_at`;
the server dropping a deleted group from the set is applied locally;
`group_deleted` applied locally as the entry's deletion with the conflict
evidence kept read-only; `group_missing` and any other failure leave the
operation pending (recoverable) with no local write; a receipt that cannot
be settled keeps no evidence; an owner change before finalization fails; an
old response never overwrites newer local work (entry and group); both
entity types reach the adapter through the real router; and through the
real `SynchronizationCoordinator` the dispatch order is group create, entry
create, entry edit, group delete (the cascade queues no entry operation),
while a `group_missing` entry stays pending without blocking the rest.
The existing router tests are unchanged.

Gates (2026-11-17, Windows host). The working tree also holds uncommitted
presentation drafts for T096–T097 (cubit, tab and their tests) that a later
task owns, so format and analyze were run on every directory this part
touches:

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib/features/adhkar/{data,application,domain} lib/core/data/sync lib/app/composition test/unit/features/adhkar/{data,application}` | clean (60 files) |
| Analyze | `dart analyze` on the same directories | No issues found |
| Focused suites | `flutter test test/unit/features/adhkar test/unit/core/data/sync test/architecture` | **232 passed** |

## Phase 6b part 3d — My Adhkar inbound sync (T094–T095) (2026-11-17)

`supabase_my_adhkar_reader.dart` (keyset pages over a `MyAdhkarPageSource`:
`my_adhkar_groups` by `group_id`, `my_adhkar_items` by `item_id` with the
`my_adhkar_item_groups` rows embedded in the same row so a group set always
belongs to its version, and `my_adhkar_conflicts` by `conflict_id`; each
pass restarts from the first key, a page that does not advance, an
oversized page, a foreign owner or an account change fails the pass),
`my_adhkar_reconciler.dart` (one transaction; groups before entries; rows
with pending local work are skipped; conflicts upserted by their stable id)
and `my_adhkar_inbound_synchronizer.dart`, plus
`applyRemoteGroup` / `applyRemoteItem` in the Drift repository (skipped when
a newer server version is already acknowledged, when the same version is
already stored, and when a local tombstone meets a live remote row — a
tombstone never clears; a remote group set never re-links a group deleted
on this device; a kept membership keeps its local `added_at`, a new one
takes the server's). `AdhkarSyncService` runs the My Adhkar import
independently of the Adhkar import: each has its own failure, so one never
stops the other, and the pass reports one recoverable failure when either
failed. Registered through composition. No schema change was needed: the
acknowledged version and the conflict evidence already live in v11.

The PostgREST embed `my_adhkar_items?select=*,my_adhkar_item_groups(...)`
was checked against the local stack with the anon key: the relationship
resolves (permission denied on the table, not `PGRST200`), while a bogus
relationship returns `PGRST200` as a control. No credential was used.

`my_adhkar_inbound_test.dart` (21 tests): keyset cursors for groups,
entries and conflicts (page size 2, an exact multiple ending on an empty
page); group sets and `added_at` read from an entry page; a failed page
fails the read and the retry restarts from the first key; a non-advancing
or oversized page, a foreign owner row and an account change fail the read;
a snapshot of groups, entries and a conflict imported with no outbound
operation queued and no `xp_awards` row; re-import changes nothing; a
failed page applies nothing; a foreign owner fails the pass with nothing
applied; a stale scope fails before anything is applied; a server
group-delete cascade applied locally (the entry left with no live group is
deleted, the entry in another group stays with the smaller set); tombstones
applied and a local tombstone never cleared; pending local work kept; an
older remote version never overwrites a newer acknowledged one; a locally
deleted group is not linked again; `added_at` rules; and the isolation
inside `AdhkarSyncService` (a failing My Adhkar import fails only this pass,
a failing Adhkar import does not stop the My Adhkar import, both succeeding
is a successful pass). The existing `adhkar_sync_service_test.dart` (Phase 6
isolation) is unchanged and passes.

Gates (2026-11-17, Windows host). The working tree also holds uncommitted
presentation drafts for T096–T097 (the cubit, the tab, their tests and
the screen/header/l10n edits); `my_adhkar_tab_test.dart` does not compile yet
(it is owned by T097), so the full suite excludes only that one file:

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib/features/adhkar/{data,application,domain} lib/core/data/sync lib/app/composition test/unit/features/adhkar/{data,application}` | clean (64 files) |
| Analyze | `dart analyze` on the same directories | No issues found |
| Full suite | `flutter test test/unit test/architecture test/widget_test.dart test/widget/{app,testing} test/widget/features/{habits,mind_maps,prayer,qiyam,tasks,today} test/widget/features/adhkar/{adhkar_screen,adhkar_conflicts}_test.dart` | **1133 passed, 1 skipped, 0 failed** |
| SQL/RLS | `supabase test db` (local stack) | **27 files, 418 tests, all passed** |

### Part 3d review fix — inbound group tombstone cascade (2026-11-17)

A group tombstone pulled from another device only upserted the group row, so
an entry that merely lost that group (the server drops the membership but does
not bump the entry's version) kept a stale membership on the receiving device.
`applyRemoteGroup` (and the receipt finalization of a pending group change that
the server answers with a tombstone) now applies the group-delete cascade
locally in the same transaction: the group's memberships go and every live entry
left with no live group gets a tombstone with a monotonic `updated_at`, with no
outbox row and no change to any entry's acknowledged version. A group this
device does not hold yet counts as live; a local tombstone is never cleared by
a receipt, even for the exact version sent. Six new tests in
`my_adhkar_inbound_test.dart` (now 27): the survivor case, the only-in-group
case before the entry's own version arrives (and then converging), an unknown
group counted as live, an already-deleted group, a pending edit of a cascaded
entry whose receipt (deletion or live) never resurrects it, and a pending edit
that keeps a live group.

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format` on `lib/features/adhkar/data`, `test/unit/features/adhkar/data` | clean |
| Analyze | `dart analyze` on adhkar data/application, core sync, composition, adhkar data tests | No issues found |
| Focused suites | `flutter test test/unit/features/adhkar test/unit/core/data/sync` | **226 passed** |

No SQL was touched, so `supabase test db` was not re-run.

### T096 — MyAdhkarCubit (2026-11-17)

`MyAdhkarCubit` (with `MyAdhkarState`, typed `MyAdhkarFailure` and
`MyAdhkarActionResult`) is composed beside `AdhkarCubit`. It is bound to one
owner, has no Adhkar clock, times port, counter, celebration or streak, and
ignores a command while another is in flight. `my_adhkar_cubit_test.dart`
(16 tests, real encrypted store, stepping clock): load (oldest first, counts,
idempotent), open and close a group with the entries carrying their full
group set and following later changes, create/rename/delete a group with the
preview count, an opened group deleted by sync closing by itself, add/edit
(group set and text-only)/delete an entry, typed validation failures that
write nothing, `groupDeleted`/`itemDeleted`, the 100-group and 1000-entry
limits as flags and typed failures (and lifting the flag on a delete), the
in-flight guard, a throwing command releasing the guard, close during a
command, owner isolation, and zero `xp_awards` / Adhkar count rows with only
`my_adhkar_group` and `my_adhkar_item` outbox types.

Two defects in the committed data layer were found by these tests and fixed
(each proven first by a failing test in `drift_my_adhkar_repository_test.dart`):

- `watchGroupItems` returned each entry with only the watched group in
  `groupIds`; the contract says its full group set (needed for the card's
  "also in" line and the edit form). It now reads the memberships.
- The group rename and the entry edit/delete `customUpdate` calls did not
  declare the table they write, so a rename or a text-only edit did not
  re-emit the watching streams (the UI would not refresh). They now declare
  `updates:`.

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (570 files) |
| Analyze | `flutter analyze` (whole tree) | No issues found |
| Focused | `flutter test test/unit/features/adhkar test/architecture` | **257 passed, 0 failed** |

### T097–T098 — My Adhkar tab and conflicts (2026-11-17)

The third Adhkar segment opens `MyAdhkarTab` (header note, group list oldest
first with name and "n entries", Rename/Delete menu, create/rename form, in-page
group delete confirmation with the count and the "entries in other groups stay"
note, empty state with example group names, opened group with a back control in
the tab and no app-bar arrow, Add disabled at 1000 with the reason, entry cards
with selectable Amiri text, selectable plain-text source, the other groups and
an Edit/Copy/Delete menu with an in-page delete confirmation, and the add/edit
form with the group chips). Forms open as a bottom sheet below 720 px and as a
dialog from 720 px. Device back closes an opened group first (a
`BackButtonListener`), then is left to the shell. The text and source fields
carry no `maxLength`: lengths count Unicode code points (Arabic diacritics
included) with a counter and an inline error instead. No counter, target,
time window or locked state, no URL-launching package (asserted against
`pubspec.yaml`), and the schedule notice is hidden on this tab.

`my_adhkar_tab_test.dart` (28 widget tests, in-memory store, real Cubit):
empty state, rows, plural counts in Arabic, create/rename, name and text/source
validation errors (including diacritics counted as code points), a rejected
command shown inline, the delete confirmations with their counts (EN and AR),
the 100-group and 1000-entry disabled states, the opened group, device back from
a group (first closes it, second reaches Home), Amiri/selectable text, mixed
Arabic/Latin direction, a link source as plain text that opens nothing, an entry
with no source, the other-groups line, Copy to the clipboard, the add/edit forms,
sheet versus dialog, and an AR/EN x light/dark x (320 px at 200%, 900 px) matrix
with no overflow. `adhkar_screen_test.dart` gained the three-segment switch with
My Adhkar usable and un-locked when the Prayer schedule is unavailable, and the
320 px / 200% matrix with the third segment. `adhkar_conflicts_test.dart`
gained My Adhkar group and entry conflicts (both versions, long text shortened,
a deleted version, no resolve action, no foreign-owner data, one shared heading)
and the date-shown-once fix for an unloaded catalog.

Two small related fixes, each proven by a test first: a period change no longer
moves the user off My Adhkar (`adhkar_cubit_test.dart`), and the count conflict
card no longer shows the day twice when the catalog is not loaded
(`adhkar_conflicts_test.dart`).

| Gate | Command | Result |
| --- | --- | --- |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | clean (575 files) |
| Analyze | `flutter analyze` (whole tree) | No issues found |
| Focused | `flutter test test/widget/features/adhkar test/unit/features/adhkar/presentation test/architecture` | **128 passed, 0 failed** |

The My Adhkar conflicts list is a widget parameter
(`myAdhkarConflicts`, fed by `DriftMyAdhkarRepository.watchConflicts`);
composing the view into a route belongs to the Adhkar route wiring (T034/T035),
which is still open.
