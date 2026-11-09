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

## SC-007 — streak values for seeded patterns

**Pending**: not yet verified.

## SC-008 — countable exactly inside the time windows

**Pending**: not yet verified, including across midnight.
