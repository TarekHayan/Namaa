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
