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
