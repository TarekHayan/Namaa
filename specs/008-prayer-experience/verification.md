# 008 Prayer Experience — implementation evidence

## Baseline (2026-10-29, before Phase 1)

- Branch: `namaa/008-prayer-experience`.
- Existing tracked edit: `.metadata`; preserved without staging or modification.
- Existing untracked work: the 008 planning directory. Planning/checklist completion is not implementation acceptance.
- Flutter 3.41.8, framework `02085feb3f`; Dart 3.11.5, Windows x64.
- Local schema remains **7** (`kFoundationSchemaVersion` in `lib/core/data/local/foundation_database.dart`). No schema/migration is changed in Phase 1.
- Existing Supabase migrations: 0001–0014, ending in `0014_versioned_sync_rpc.sql`. No database migration or hosted project operation is run in Phase 1.
- Prototype inputs physically present: `prototype/src/views/PrayerView.tsx`, `prototype/src/utils/prayerTimes.ts`, `prototype/src/views/TrackHubView.tsx`, Home/AppContext and the files inventoried in [prototype-reference.md](prototype-reference.md). Existing UI references: `docs/design/colors.md`, `docs/design/app_components.md`.
- Spec requirements checklist: 16 checked, 0 unchecked; read only.
- Existing `.gitignore` and `.dockerignore` cover generated/build/cache files, prototype extraction and local secrets. No ignore-file change needed.
- Baseline `flutter analyze --no-pub`: result recorded in the execution section below.

## Phase 1 package release review (T002)

Downloaded the **exact** pub.dev release archives to a temporary review directory; calculated SHA-256 and matched each release API's `archive_sha256` before extraction. Inspected the extracted pubspec, LICENSE and relevant Dart source (not moving upstream master).

| Release | SDK constraint | License in archive | Verified SHA-256 |
| --- | --- | --- | --- |
| [adhan_dart 2.0.1](https://pub.dev/packages/adhan_dart/versions/2.0.1) | >=2.19.0 <4.0.0 | MIT | `b1a280975b73052eb3b213430adf481f241bfc1cd839b2b0f4368bfe1a1b7ee5` |
| [timezone 0.11.2](https://pub.dev/packages/timezone/versions/0.11.2) | ^3.10.0 | BSD-2-Clause | `9f4e5a1a0e4fef7dd3424842c0575db01bfb7a11730e8d55753fcd5c5c98767b` |
| [uuid 4.6.0](https://pub.dev/packages/uuid/versions/4.6.0) | >=3.0.0 <4.0.0 | MIT | `9b129329f58692f6e6578329498a8fe9fbe98f090beb764ffbb8ee2eadd01dcd` |
| [dio 5.11.1](https://pub.dev/packages/dio/versions/5.11.1) | >=2.18.0 <4.0.0 | MIT | `852ec3b48cc431ac04fff978413c541502b67ffc3e26921e74e3d994694192c1` |

API observations:

- Adhan: `PrayerTimes` has named date/coordinates/calculationParameters arguments and optional precision; seven required presets are in `CalculationMethodParameters`. `lib/src/SolarTime.dart` exists with `SolarTime(DateTime, Coordinates)`, raw sunrise/sunset and `hourAngle(double, bool)`. It is not exported by the public barrel, so the planned future adapter's deep import remains an explicit exact-version coupling. This review does not certify calculation accuracy or high-latitude preflight.
- Timezone: `lib/data/latest_all.dart` embeds **2026e** per its generated header; changelog agrees. README's 2025c statement is stale. `initializeTimeZones()` loads embedded data with no network call. No OS zone plugin is required.
- UUID: `Uuid.v5(namespace, name)` is available; cross-language vectors belong to Phase 2.
- Dio: `CancelToken`, `BaseOptions` connect/receive `Duration` timeouts and typed responses are available. Actual city provider behavior belongs to US1.
- All four libraries provide pure-Dart interfaces compatible with the project's Dart 3.11.5 constraint. This is an archive/API/SDK review, **not** five-target runtime evidence.
- Open-Meteo evaluation/commercial separation follows the reviewed [provider terms](https://open-meteo.com/en/terms); a licensed gateway is not provisioned by this phase. A missing search configuration must not affect saved-city offline use.

## Phase 1 execution and focused checks

| Task | Implementation/evidence |
| --- | --- |
| T001 | Baseline/inventory above recorded; `.metadata` preserved. Baseline `flutter analyze --no-pub` passed with no issues (143.1s). |
| T002 | Release archive hashes/licenses/API review above; `prayer_dependency_adoption_test.dart` exercises raw solar/seven presets/UTC, the published DNS UUIDv5 example and cancellable Dio timeout APIs. This is not the later independent astronomical-reference proof. |
| T003 | `flutter pub get` passed: four exact direct additions plus `dio_web_adapter 2.2.2` transitively; no existing locked dependency/SDK version changed. |
| T004 | `initializePrayerTimeZones()` loads `latest_all` once per isolate. The vendor sets UTC as its initial default; composition must call before zone consumers. Subsequent calls preserve an existing caller-selected local zone and location object identity. Future Prayer adapters resolve city zones explicitly; composition wiring belongs to later tasks. |
| T005 | Main Android manifest contains exactly one INTERNET permission and no new location/background/cleartext permissions. Existing debug/profile INTERNET declarations inspected. Merged release manifest evidence remains for the final target gate. |
| T006 | First search-configuration test run failed as expected because the target implementation file did not exist (red test, exit 1). No assertions were removed to obtain a pass. |
| T007 | Typed evaluation/licensedGateway configuration; release rejects evaluation, unknown mode fails closed, missing/invalid/credential-bearing gateway origins return a recoverable configuration failure with no public fallback. Error text is in both ARBs and generated through `flutter gen-l10n`. No upstream key field, network call or schedule dependency was added. |
| T008 | [guidance-sources.md](guidance-sources.md) maps obligatory counts, recitation, optional suggestions and Jahr/Sirr roles to reviewed primary sources. Final ARB copy acceptance remains T077/T127. |

Focused command results:

- `flutter gen-l10n`: passed; generated files were produced by the generator, not hand-edited.
- `flutter test --no-pub test/unit/features/prayer/data`: **20 passed** (3 dependency adoption, 16 search configuration, 1 timezone initialization). An initial timezone test tried to read the vendor's uninitialized `local` field; corrected the test to initialize first and then verify once-only behavior; production initializer logic did not need changing.
- Static analysis initially identified four redundant default arguments in the new search tests. Removed those arguments, then reran only the affected search file: **16 passed**.
- Final formatting and static-analysis outcome is recorded at the phase checkpoint below.
- Android source XML parsed successfully: INTERNET count 1; local schema still 7; no database operation run.

No full CI/device matrix is required for this setup phase. Network discovery, UI, actual prayer-reference fixtures, migrations and feature acceptance remain later work. Search configuration is intentionally separate from offline calculation; no gateway is claimed deployed.

### Phase 1 checkpoint

**PASS (2026-10-29)**: T001–T008 complete. Final `flutter analyze --no-pub`: no issues (9.2s). `dart format` checked all five new Dart files: 0 changes. All 20 focused tests passed; the final affected-file rerun passed all 16 search tests after lint cleanup. No app code changed after that final validation. T009 onwards remain unchecked and unimplemented. No commit/push or CI run performed.

## SC-001 — scripted journey within 60 seconds

**Pending**: actual city → Prayer → Home journey and recorded timing after implementation. No current Phase 1 acceptance claim.

## SC-002 — calculation/reference agreement within one minute

**Pending**: independent fixtures, preset normalization, raw solar checks and boundary comparison (T030–T032/T058).

## SC-003 — report states, restart and no automatic missed state

**Pending**: durable reporting/state matrix and restart tests (T059/T061/T071/T074).

## SC-004 — synchronization, rewards and owner isolation

**Pending**: SQL/replay/concurrency/device evidence (T096–T100/T117/T118). No hosted migration has been applied for 008.

## SC-005 — responsive/localized accessible input

**Pending**: final AR/EN, themes, sizes, scaling, keyboard and touch evidence (T076/T088/T091/T128).

## SC-006 — measured performance and offline week

**Pending**: named phone/desktop timing and seven-date offline calculation evidence (T056/T125/T126).

## SC-007 — Home equality and device-independent city

**Pending**: projection/calendar/scope/device evidence (T057/T115/T117/T128).

## SC-008 — complete prototype audit

**Pending**: four-group source-to-screen comparison, final attributed strings and real target evidence (T092/T127/T128). This document does not complete the separate 007 audit.

## Final merge/release gates

- Full exact-head Foundation CI, local Supabase security suites and five-target evidence: pending later phases.
- Commercial city-search entitlement/gateway: external release configuration prerequisite, not created or purchased here.
- No commit, push, merge, publication or production migration is implied by completing a phase.
