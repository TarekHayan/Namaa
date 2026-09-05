# Implementation Baseline: Namaa Foundation — Phase 1

**Recorded**: 2026-09-05 | **Phase**: 1 (Setup and Provider Migration) | **Host**: Windows 10,
Flutter 3.41.8 / Dart 3.11.5, no Visual Studio toolchain

This file records the pre-existing state observed while executing Phase 1 (T001–T008), so later
phases can distinguish Foundation regressions from failures that already existed. Only pre-existing
failures are recorded here; no unrelated code was changed to make them disappear.

## Pre-existing failures / constraints

1. **Native Windows compilation cannot run on this host** — `flutter build windows --debug`
   requires the Visual Studio toolchain, which is absent (`flutter doctor`: Visual Studio ✗,
   Android toolchain ✓). Pre-existing environment constraint, recorded in
   [platform-validation.md](platform-validation.md). Re-run on a VS-equipped host.
2. **Starter app is the default Flutter counter template** — `lib/main.dart` and
   `test/widget_test.dart` are the untouched Flutter starter (counter smoke test). They are
   Foundation-neutral and pass; they are replaced later by T017 (app shell) and its tests, not in
   Phase 1.
3. **Pub outdated notices** — `flutter pub get` reports packages with newer versions incompatible
   with current constraints (e.g. `test_api 0.7.10` vs `0.7.14`). Informational; no test or
   analysis failure results from them.

## Phase 1 verification results

| Check | Command | Result |
|---|---|---|
| Dependency resolution | `flutter pub get` | PASS (Firebase packages removed; `supabase_flutter ^2.17.2` added) |
| Static analysis | `flutter analyze` | PASS (0 issues) |
| Formatting | `dart format .` | PASS (6 files, 3 reformatted) |
| Localization generation | `flutter gen-l10n` | PASS (`app_en`/`app_ar` generated into `lib/app/l10n/generated/`) |
| Test entry points | `flutter test` | PASS (1/1 — starter widget smoke test) |

## Phase 1 checkpoint

The dependency manifest contains no Firebase package (`cloud_firestore`, `firebase_auth`,
`firebase_core` are removed), and the project is ready for Foundation-only source files and the
local Supabase test configuration (`supabase/config.toml`).
