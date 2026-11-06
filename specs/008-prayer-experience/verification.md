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
| T005 | Main Android manifest contains exactly one INTERNET permission. Foreground fine/coarse location permissions were added later for T138; no background location or cleartext permission was added. Existing debug/profile INTERNET declarations inspected. Merged release manifest evidence remains for the final target gate. |
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

**PASS (2026-10-29)**: T001–T008 complete. Final `flutter analyze --no-pub`: no issues (9.2s). `dart format` checked all five new Dart files: 0 changes. All 20 focused tests passed; the final affected-file rerun passed all 16 search tests after lint cleanup. No app code changed after that final validation. At this checkpoint T009 onwards were pending. No commit/push or CI run was performed for this checkpoint.

## Phase 2 foundational verification

**PASS (2026-10-29)**: T009–T029 complete. Pure Prayer values and application ports, deterministic UUIDv5 identity, semantic conflict versioning, shared Task/Prayer XP ledger compatibility, local schema version 8, device-local encrypted city preference storage, and indexed owner/day report reads are implemented. Generated Drift code was regenerated with `dart run build_runner build --delete-conflicting-outputs`.

The migration suite reconstructs historical physical schemas for versions 1–7, seeds existing records, verifies each upgrade to version 8 and restart, and exercises rollback followed by recovery. Preference tests cover owner and installation separation, restart, revision guards and absence of cloud outbox changes. XP tests cover mixed Task/Prayer awards, historical Task rows and Today projection. Identity and conflict fixtures assert stable cross-device wire values. The architecture test checks Prayer and Today boundaries.

- Focused Phase 2 suite (`flutter test --no-pub test/unit/core/data/local test/unit/features/prayer test/unit/features/xp test/unit/features/today/data/xp_today_adapter_test.dart test/unit/features/tasks test/architecture/prayer_boundaries_test.dart`): **193 passed**.
- After the final timezone-initializer and preference-test adjustments, the affected preferences, migration, Today XP and architecture files were rerun: **17 passed**.
- Full `flutter analyze --no-pub`: **no issues**. Formatting and `git diff --check` passed.

These are foundational checks. City search, prayer-time calculations, UI, report commands, remote synchronization, SQL security and full acceptance criteria remain in later phases.

## SC-001 — scripted journey within 60 seconds

**Pending**: actual city → Prayer → Home journey and recorded timing on a target device. The Phase 3 Windows integration test exercises the underlying saved-city, schedule and Home projection, but does not time the complete user interface journey.

## SC-002 — calculation/reference agreement within one minute

**SC-002 passed in automated evidence**: the frozen independent AlAdhan matrix has 84 city/method/date rows and 504 prayer/sunrise values. After the documented Ramadan interval, Dubai offset and Asr calibrations, the pinned on-device calculator agrees within 60 seconds on all **504/504** values; the test allows no named exception. Of the corresponding values from the unpacked prototype's `adhan` JS 4.4.4 calculation, 477 match within 60 seconds; 27 intentional differences are the three Umm al-Qura Ramadan Isha results and 24 Dubai Sunrise/Asr values normalized to AlAdhan. Independent PrayTimes.js edge fixtures verify six values at (0,0) and unavailable polar twilight alongside valid Dhuhr/Asr. The projection tests verify the UTC Maghrib→next-Fajr midpoint and final-third rule. Prototype parity is not independent validation. Named phone/desktop cache and fallback measurements remain a separate T137 gate.

**2026-11-02 edge capture and corrections:** `aladhan_edge_cases.json` now freezes accountless API responses for (0,0), Tromso polar day and Stockholm summer twilight with exact requests and capture timestamps. AlAdhan returned HTTP 400 for (0,0), identical substituted solar times in Tromso, and `+03:00` ISO offsets under `Europe/Stockholm` on 21 June (IANA offset `+02:00`). The annual importer now rejects a year whose declared timestamp offset disagrees with the selected IANA zone; its cache context version invalidates previously stored years that lacked this validation. When an otherwise accepted year includes an unobservable solar event, the read model marks that prayer unavailable instead of exposing the provider's substitute. The projection no longer skips an unavailable Isha to claim tomorrow's Fajr as next. These safeguards did not resolve the local-calculator/reference discrepancies, and AlAdhan's zero-coordinate rejection cannot serve as a numerical reference for T030.

Focused evidence for this correction: annual adapter and solar tests **11/11 passed**; DST/solar/projection tests **13/13 passed** including a red-then-green test for the skipped-Isha defect; city/search/context/editor/route/Home tests **19/19 passed**. Targeted `dart analyze` on the changed source and tests reported **no issues**. A new Windows device rerun stopped at the NuGet acquisition step before executing the test; the existing earlier Windows offline result below remains the last actual Windows device evidence, not a fresh post-correction result. A subsequent unqualified integration invocation selected Android and was stopped during Gradle assembly, so it is not counted as an executed journey.

On 2026-11-03, the opt-in live Cairo annual-calendar test passed **1/1** after the offset guard was added: it fetched the real 2026 provider response, accepted Fajr/Maghrib on 1 November and read the same day from the encrypted cache with network disabled. The expanded next-prayer boundary test passed **4/4**. This confirms the guard does not reject that Cairo year; it does not certify every city or resolve SC-002.

On 2026-11-03, after the user's Ramadan decision, the local Umm al-Qura adapter uses the Umm al-Qura calendar to select 120 minutes after Maghrib in Ramadan and 90 minutes outside it; Qatar stays at 90. The focused calculator suite passed **3/3**, including the frozen AlAdhan 84-row comparison. This removes the three Ramadan Isha discrepancies; Dubai preset and New York Asr differences still block the one-minute acceptance threshold.

On 2026-11-03, comparing the frozen Dubai method showed the pinned local preset's Sunrise -3 and Asr +3 adjustments were absent from AlAdhan. The fallback now zeroes only those two adjustments; the remaining 14 independent mismatches are New York Asr on the two March dates across all seven methods. The calculator and solar-preflight tests passed **9/9** after this change. This is a later measurement than the earlier 3/3 result above and still does not close SC-002.

On 2026-11-03, inspecting all 84 Asr pairs found the local result 0–2 minutes later than AlAdhan for every city/method/date. A single -1-minute Asr adjustment brings each pair within 60 seconds, without a New York- or date-specific exception. The calculator suite passed **3/3** after this final calibration; T030/T031 remain open for the unverified edge reference cases.

On 2026-11-03, a pinned [PrayTimes.js 2.3 source](https://github.com/abodehq/Pray-Times/blob/5202ceb8b2cbb17848a227753f7bd0ac8b4c649f/Code/v2/js/PrayTimes.js) supplied the missing independent (0,0) and Tromso references. It revealed that Asr remains computable on Tromso's polar day even without sunrise/sunset. The solar preflight now checks Asr's own reachable angle and keeps unobservable twilight unavailable. Calculator and preflight tests passed **11/11** after this correction, including D/D+1 and edge-fixture comparison. T030–T036 are checked; this final result supersedes the earlier pending notes in this chronological section.

**2026-10-31 source change**: AlAdhan's annual calendar is now the primary schedule, with complete-year response validation, encrypted owner/context cache and explicit local fallback beyond coverage. The frozen comparison remains relevant to the local fallback and is still blocked. Mocked annual responses prove parsing, caching, owner separation and offline restart; a live annual endpoint capture and named-device check remain T137.

**2026-11-01 location correction**: The user's screenshot selected the Open-Meteo result “مصر، مصر”, whose coordinates are 27.00°N, 30.00°E; that is not Cairo or the user's measured position. Prayer now requests a foreground device fix on first setup, resolves its IANA zone and a supported method suggestion through AlAdhan, and saves it per owner/device. Denial or an unavailable/imprecise fix leaves manual city search available. The Prayer header now uses bounded semantic text styles, shows coordinates for device location and displays API/local source above the five times; Home localizes the device-location label.

The live accountless AlAdhan calendar for Cairo (30.0444, 31.2357; Egyptian method 5; 2026-11-01) returned Fajr 04:41 and Maghrib 17:08 Africa/Cairo. Its 365-day response was accepted by the encrypted annual adapter and read again offline in the opt-in live test. A separate provider request failed transiently, so the adapter now retries 5xx/429/network timeouts; the retry path and location success/denial/imprecise-fix cases passed focused tests. This confirms the API payload path, not the named-phone visual or end-to-end location-permission gate still required by T137.

Focused follow-up: 10 affected location/annual/Home tests passed with the live API gate enabled; the additional return-visit test and temporary zone-service retry test passed. `dart analyze` reported no issues on the touched Dart files. Windows Release preview built successfully; a separate Debug build reached the final link step but could not replace the user's currently running `namma_project.exe` (`LNK1168`), so it did not indicate a source or plugin compilation failure. Actual OS permission behavior and rendered dimensions still need a named-device check.

Final targeted rerun for the location correction: `flutter test --no-pub test/unit/features/prayer/data/geolocator_prayer_location_test.dart test/unit/features/prayer/data/aladhan_annual_schedule_test.dart test/widget/features/prayer/prayer_auto_location_test.dart test/widget/features/prayer/prayer_city_editor_test.dart` passed 10/10. Focused `dart analyze` on the changed location/editor/screen files reported no issues. The editor now labels a saved device fix in the current locale, and the quickstart includes first-use permission and manual-fallback checks. This is automated evidence only; the named-device permission and visual check remains T137.

The 1920×1080 widget layout check now asserts bounded heading/location text sizes and no framework layout exception on a saved device fix; its three focused widget cases passed. It is a synthetic viewport, not a physical-device rendering claim.

**2026-11-01 user device check:** The user reports trying the current Prayer location/timetable flow on a real mobile phone and says it works. This is positive phone runtime evidence for the foreground location path; the report did not identify the phone/OS, measured coordinates, displayed source/times, or an offline restart. It therefore does not yet establish the phone/desktop offline-cache and fallback measurements required by T137 or the independent local-calculation threshold in SC-002.

Focused source/migration/context/Prayer route/city editor/Home card run: **22 tests passed**. After adding the Home fallback label and next-year prefetch guard, the two directly affected files were rerun: **4 tests passed**. Focused `flutter analyze --no-pub` reported **no issues**. The test doubles deliberately do not establish actual AlAdhan availability or full-year response shape in this environment; T137 and the remaining Phase 3 gates stay open.

**Phase 3 US1 follow-up (2026-11-03):** The city-search cubit now has fake-clock coverage for the exact 350 ms debounce and tests for invalid length, locale/owner cancellation, late replies, empty/offline/throttled results and retry. The editor tests cover keyboard selection, explicit save, phone sheet clearance, offline first use, failed save preserving the prior city, and account-owner replacement. Owner replacement resets the old query and candidate in the UI. The context tests cover independent setup/report/schedule health, one-second projection with no extra calculation/report read, midnight refresh, obsolete annual/report replies, and owner isolation. Today tests verify an exact Prayer owner, independent retry and a different Prayer city date that leaves Task date unchanged; Home tests cover real times and honest setup/unavailable states. The AR/EN Umm al-Qura method label was corrected to mention the 120-minute Ramadan interval and generated through `flutter gen-l10n`.

Focused results on the final affected files: city-search cubit **7/7**, city editor **6/6**, context service **8/8**, Today cubit **3/3**, Home Prayer card **3/3**, and Prayer route **2/2** passed when run individually or in the combined run. The combined 29-case run initially had one test-fixture generation index failure after adding the 101-character rejection case; that single test was corrected and passed on rerun. Targeted `dart analyze` for the changed Prayer/Today source and tests reported **no issues**. The final `flutter test --no-pub -d windows integration_test/prayer_schedule_test.dart --dart-define=PRAYER_TEST_TARGET=Windows-x64-2026-11-03` passed **1/1** on Windows x64 after an 86.1-second build. It verified encrypted saved-city restart, seven injected offline dates with no HTTP, D/D+1, city/method change, DST and Home equality; the test printed `PRAYER_OFFLINE_SEVEN_DAY_MS target=Windows-x64-2026-11-03 elapsed=206`. The first attempt stalled before test execution while CMake downloaded NuGet. Downloading the exact required NuGet 6.0.0 executable into ignored build cache and verifying its SHA-256 against CMake's pinned hash allowed the targeted rerun to build and pass. T058 is complete. The named phone/desktop **annual-cache and fallback measurements** in T137 remain open; this local-only journey does not exercise the cached AlAdhan year.

## SC-003 — report states, restart and no automatic missed state

**PASS for US2 local behavior (2026-11-01)**: the complete 4×4 state matrix is explicit; same-state and missing→pending are no-ops; prior/future submissions and stale owner/preference scopes are rejected. An action accepted before midnight retains its captured city date, while merely crossing midnight writes no `missed` report. The encrypted integration journey completed late→on-time→pending, ten same-state replays and a database close/reopen with one durable report and one immutable first reward.

This checkpoint covers the local/preview behavior owned by Phase 4. Account cloud replay and two-device conflict settlement remain intentionally pending under SC-004/US4.

## SC-004 — synchronization, rewards and owner isolation

**Pending**: SQL/replay/concurrency/device evidence (T096–T100/T117/T118). No hosted migration has been applied for 008.

## SC-005 — responsive/localized accessible input

**Phase 5 automated evidence complete; target acceptance pending**: AR/EN, light/dark, 320/390/430/768/1200 logical-pixel widths, 100%/150% text, keyboard and touch paths passed the focused widget and Windows integration checks below. Named phone/desktop visual and accessibility acceptance remains T128.

## SC-006 — measured performance and offline week

**Pending**: measured phone and desktop performance against the target thresholds (T125/T126). The Windows integration test calculated seven injected dates under an HTTP override that throws on any request, compared Prayer and Home each day, verified encrypted restart, midnight, New York DST and city/method switch. Its named local calculation hook reported 245 ms for this Windows run (`PRAYER_OFFLINE_SEVEN_DAY_MS target=unspecified`); this is not a UI latency or cross-device acceptance measurement.

## SC-007 — Home equality and device-independent city

**Pending**: final device independence and five-target evidence (T115/T117/T128). Phase 3 unit/widget and Windows integration checks establish matching owner/city/day/next instant between the Prayer context and Home adapter on one installation, with an owner mismatch guard. They do not establish two-device behavior.

## Phase 3 US1 checkpoint (2026-10-31)

Implemented manual city discovery through bounded provider search, explicit local city/method confirmation, city-zone calculation with day + next day projection, setup/partial/unavailable health, a read-only Prayer screen, a dedicated owner-gated route, and a live Prayer card on Home. The Home metric reads the report count when available and shows unknown otherwise; it does not invent completion. The existing Task/Habit/Map owners are retained. AR/EN date and time formatting use the selected UI language and the city time zone.

Focused outcomes: `flutter gen-l10n` passed; focused calculator (including 84-row prototype parity), solar, search, context, route, city editor and Home tests passed during implementation. After the last edits, the changed date adapter test passed, the Home Prayer widget tests passed (2 tests), the city editor/route tests passed (3 tests), the Windows offline integration journey passed, and a broad `flutter analyze --no-pub` over app/Prayer/Today and affected tests reported **no issues**. The Windows integration build completed in 50.2 seconds and its test passed. These checks do not complete the entire Phase 3 task list: T030/T031 and the more exhaustive city-search, lifecycle, editor, route and device cases remain open. Reports/actions, visual parity and account sync belong to later phases.

## Phase 4 US2 checkpoint (2026-11-01)

**PASS**: today's five Prayer reports now use explicit pending/on-time/late/missed commands, a fresh-read version guard and one encrypted transaction for report, first reward and optional outbox operation. Preview persists the report and reward without outbound work. The first eligible reward is frozen at 5 or 10 XP across corrections, reset and restart; a stale concurrent writer cannot replace a fresher row or its acknowledged sync base. Schedule unavailability does not erase report controls or counts.

Prayer preview now owns a separate fixed identity. Today's preview XP bridge watches only the fixed Task and Prayer partitions, maps them into the existing strict Today projection without copying stored rows, and never includes Habit/foreign owners. Real account mode remains a single-owner ledger.

Verification outcomes after the final US2 edits:

- Report commands/day guards/context/transaction/status-widget/preview bridge: **22 passed** in the first focused run; the expanded transaction/repository rerun passed **7/7**, including 10→late/reset staying 10 and stale-write rejection.
- Preview composition, Today scope/lifecycle/actions and Prayer route: **23 passed**. One earlier command included a nonexistent `prayer_screen_test.dart` path; it was removed and the exact valid set reran green. This was an invocation error, not a product test failure.
- Shared XP, existing Task award/completion compatibility, Today XP and Prayer architecture: **25 passed**; Task's 20 XP policy remains unchanged.
- `integration_test/prayer_reports_test.dart` on the Flutter tester: **1 passed**. It uses the encrypted database, performs late/correction/reset, ten replays, restart, injected local-write rollback, preview zero-outbox and midnight no-auto-missed checks.
- Full `dart analyze`: **no issues**. AR/EN generated localization files were regenerated by `flutter gen-l10n` before the checkpoint.

The Windows device invocation reached the native build but could not obtain `NuGet.exe` in this environment, so it is not claimed as a Windows device result. The same integration file passed through Flutter's host tester. Phone/desktop visual and interaction acceptance remains in the later responsive/device gates, and Phase 3's independent calculator/reference work remains open.

## SC-008 — complete prototype audit

**Phase 5 implementation checkpoint (2026-11-02): PASS, T075–T094.** The four ordered groups, five prayer cards and status controls, three independent supplementary values, two Jahr/Sirr panels and the Track/Prayer routes are present. The city editor uses a phone sheet or desktop dialog; the global streak is labeled coming soon. The Prayer cards use an icon tile, obligatory-rak'ah badge, time, recitation/guidance and explicit status controls. The shared `AppButton` now exposes selected-state semantics directly, so screen readers receive the actual selected label. The UI keeps saved reports visible during schedule recovery.

Source-to-rendered-layout comparison against `prototype/src/views/PrayerView.tsx` and [prototype-reference.md](prototype-reference.md):

| Group | Source reference | Implemented and measured in widget tree |
| --- | --- | --- |
| Heading | Radius 32; inset 24 phone/32 wide | Same radius and responsive insets; location, city date/zone/method, completed/5 and coming-soon streak. |
| Five cards | Gap 12; radius 32; inset 20/24 | Same dimensions; status-tinted surfaces, icon tile, rak'ah badge, full content; actions stack under a separator when width or text scaling requires. |
| Supplementary values | One/three columns; gap 12; radius 16; inset 16 | Same dimensions and order; independent unavailable values; no report or reward action. |
| Guidance | Radius 32; inset 24/32; one/two panels | Same dimensions; Jahr/Sirr panels and attribution remain readable with scaled text. |

The source-layout contract test asserts group ordering, role inventory and the rendered widget padding/radius at 390px Arabic and 1200px English. The 40-case responsive test checks 320/390/430/768/1200px × Arabic/English × light/dark × 100%/150% text, safe-area clearance, long city/guidance wrapping, no framework overflow, and at least 48×48 logical-pixel action targets. This is measured widget geometry, not a photographic visual sign-off. The user deferred the named-device trial; phone and desktop captures plus any visual corrections are explicitly part of T128.

Final focused results after the Phase 5 layout and semantics changes:

- `flutter test --no-pub test/widget/features/prayer`: **63 passed**.
- `flutter test --no-pub test/widget/app/prayer_route_test.dart test/widget/features/today/dashboard_navigation_test.dart test/widget/features/today/today_navigation_shell_test.dart test/widget/features/today/today_prayer_card_test.dart`: **17 passed**.
- `flutter test --no-pub -d windows integration_test/prayer_localized_route_test.dart`: **4 passed** on Windows. Arabic and English touch/keyboard journeys use the production Home-to-Prayer router and navigation shell, select Cairo, record all five statuses, reset one, return Home, reopen Prayer, restart the encrypted database and verify the retained city and reports. Preview creates no outbox rows.
- The first unqualified integration invocation selected Android and stalled during `assembleDebug`; it was cancelled before tests ran. The explicit Windows run above is the completed device result. `dart analyze lib/app/widgets/app_button.dart lib/features/prayer/presentation test/widget/features/prayer integration_test/prayer_localized_route_test.dart`: **no issues**. `git diff --check`: passed.

FR-019…025/027…028 audit: FR-019/020/021/022/023/024 are covered by the source-layout, navigation, responsive, semantics and localization checks above. FR-025 has a role-to-primary-source map in [guidance-sources.md](guidance-sources.md); the final line-by-line AR/EN editorial audit remains T127. FR-027 keeps Adhan and notifications out of this screen; FR-028 shows Focus, Quran, Adhkar and Qiyam as coming soon without inventing stored progress. Actual target screenshots, final religious-copy sign-off and cross-device acceptance remain T127/T128 and later phases. This checkpoint does not complete the separate 007 audit.

## Phase 6 — account synchronization checkpoint (2026-11-02)

**Implemented, T095–T118:** Local migration 0015 adds owner-scoped Prayer reports, retained conflicts and durable operation receipts. The typed RPC validates the report identity and version, serializes first inserts and concurrent writes, records a conflict only for a divergent stale base, and fixes the first eligible server award at 10 or 5 XP. The client now routes Prayer outbox operations to the RPC, settles each canonical receipt in the encrypted database before ACK, imports complete owner-scoped keyset pages, and rolls back inbound work if the account scope becomes stale. The Prayer screen exposes read-only retained evidence; Home reads the real owner report count, keeps device city preferences independent, and labels local Prayer XP awaiting server confirmation. Saving a Prayer status triggers a sync attempt; local saves remain available offline.

**Observed local results:**

- Migration 0015 applied to the local Supabase stack. The four Prayer pgTAP files passed **36/36** after the final SQL function update. They cover ownership/RLS, operation replay and validation, base-version conflicts, equal-time tie identity, and one canonical reward. No hosted project migration was run.
- Focused Prayer receipt, reconciliation, payload and conflict widget tests passed **9/9** after the rollback and stale-page fixes. The reconciliation test verifies that a changed owner scope aborts and rolls back an award already imported in that transaction.
- `integration_test/prayer_offline_sync_test.dart` passed **1/1** against local Supabase using two independent encrypted stores, three same-owner authenticated clients and a separate second owner. It exercised different prayers/dates, independently saved Cairo/London preferences, one-row pages for reports/awards/conflicts, concurrent equal-time edits, a first 5-versus-10 award, ten lost-ACK replays, retained evidence download, reset, encrypted restart and account-switch denial. It was run through a temporary host-test copy because direct Android/Windows invocations had stalled before test execution. The temporary copy was removed after the run; this result is local host execution, not a phone/device result. The Drift multiple-database debug warning comes from the two deliberately separate encrypted test paths.
- Focused Home adapter/card tests passed **3/3** for independent device city, real completed/5 and provisional Prayer XP labeling. Prayer status-action tests passed **5/5** and the existing Prayer route tests passed **2/2** after sync wiring. `flutter gen-l10n` and `git diff --check` passed. Broad and targeted analyzer invocations stalled without a diagnostic result and were cancelled; passing compilation of the focused tests is the available Dart check here, not an analyzer pass.
- The Prayer/Today architecture suite and affected Track/Prayer navigation tests passed **5/5**. The inbound synchronization now crosses an application port; the Track hub lives with Today navigation, and the architecture check distinguishes owner-scoped Supabase SELECTs from direct table writes.

**Open, T119–T120:** The user deferred the actual non-production device trial. No Android/iOS/desktop two-device result, hosted Supabase deployment, or final Phase 6 acceptance is claimed. The local evidence above is recorded now; T120 remains open until the required T119 device evidence is obtained. No production data was touched.

## Final merge/release gates

### Phase 7 checkpoint (2026-11-03)

The Foundation runner now selects all four Prayer integration entry points on Android and iOS, and includes them in the Linux, Windows and macOS full-run lists. The iOS selection rejects unknown or empty suite names before launching XCTest; its per-file build, simulator reset and native-result requirement are unchanged. The full Android/iOS matrices include Prayer, `specs/008-prayer-experience/**` triggers PR-to-`develop` validation, and the existing five-target gate still requires every job to succeed. There is no feature-branch push trigger; `mobile_only` remains a focused diagnostic run, not a merge gate. Windows and macOS use the isolated non-production Supabase configuration for the Prayer sync entry point; Linux and Android use the local stack. The iOS group supplies the same isolated environment only to that sync entry point. This is runner wiring, not a claimed five-target pass.

Focused runner evidence: `python -m unittest discover -s .github/scripts/tests -p test_mobile_runners.py` **17/17 passed** and `python -m unittest discover -s .github/scripts/tests -p test_ios_groups_and_pub_get.py` **13/13 passed**. Bash syntax check passed for both mobile shell runners; Python YAML parsing found all eight expected workflow jobs. An initial desktop-registration test counted the same file path in both the list and its staging-specific conditional; the assertion was corrected to inspect each desktop job separately, then the complete focused file passed. No CI job or device trial was launched by these checks.

After the hosted/local test-environment split, the focused `IosGroupRunnerTest` passed **8/8** and `dart analyze integration_test/prayer_offline_sync_test.dart` reported **no issues**. `dart format --output=none --set-exit-if-changed integration_test/prayer_offline_sync_test.dart` found zero changes. Dart's telemetry tried to write outside the workspace on its first invocation; rerunning with `APPDATA` redirected to a temporary writable directory produced the successful analysis/format results. These checks validate code structure, not a hosted Supabase run.

Search release audit (T124): `PrayerSearchConfiguration.resolve` disables the evaluation endpoint in release, requires a credential-free HTTPS gateway origin for `licensedGateway`, and returns the recoverable `prayerSearchUnavailable` state for missing/invalid configuration. `DioCitySearch` does not attach an upstream paid key or log the query/coordinates; the UI exposes the unavailable state and provider attribution in both locales. **Commercial new-city search is release-blocked until a licensed entitlement and first-party gateway are provisioned and verified.** No provider subscription, gateway deployment or paid key is present or claimed here. Saved-city offline schedules remain independent of search configuration.

Religious copy audit (T127): all 16 currently shipped AR/EN guidance and boundary keys are present and nonempty. The resident obligatory-rak'ah badge maps to R1; recitation rows to R2; Jahr/Sirr definitions and nonjudgment scope to R3; Fajr/Maghrib/Isha optional suggestions to R4; Dhuhr/Asr distinctions to R5 in [guidance-sources.md](guidance-sources.md). The AR/EN phrasing preserves the source map's resident/optional distinction, does not assert a universal Asr Sunnah, does not prescribe Witr or invent Quran text, and labels the Prayer streak as coming soon. The screen displays the source name and separate city/time attribution. Final named-device rendering and interaction evidence is still T128.

Outstanding Phase 7 acceptance: T119–T120 remain open because hosted two-device sync has not been run; migration 0015 is confirmed locally only and must reach the isolated test project before hosted sync checks. The existing schedule test prints a seven-day local calculation duration, but has no 18,300-report fixture or UI latency measurement. Therefore T125–T126 remain open. T128 needs named phone/desktop captures and timed journeys, and T129–T134 retain their dependency on those results and the exact-head full gate. No merge readiness is asserted.

- Full exact-head Foundation CI, local Supabase security suites and five-target evidence: pending later phases.
- Commercial city-search entitlement/gateway: external release configuration prerequisite, not created or purchased here.
- No commit, push, merge, publication or production migration is implied by completing a phase.

### Review closeout pass (2026-11-04)

A review of the uncommitted Phase 6/7 work found and fixed the following. The previous session had ended mid-phase and its analyzer runs had stalled.

- **Build blocker fixed:** `PrayerSyncSummary.inbound` referenced the data-layer `PrayerReconciliationSummary`, which was not imported, so the app did not compile. It now uses the port's `PrayerInboundSummary`. Two unbraced `if` statements in `prayer_inbound_synchronizer.dart` were also fixed; CI's `flutter analyze` treats infos as fatal.
- **`.metadata` restored:** The working tree had dropped the ios/linux/macos/web/windows migration entries. They were restored from HEAD, as T129 requires.
- **Architecture (pre-existing from 8f164a2):** `domain_dependency_test` failed because Prayer presentation imported `data/adhan_prayer_calculator.dart` and the `app/l10n` helper imported `data/prayer_timezone_initializer.dart`. The method list now lives in `domain/prayer_calculation_methods.dart`. The l10n helper loads the IANA database through the `timezone` package. `app/l10n/` helpers are classified as view resources alongside `app/l10n/generated/`.
- **Behavior:**
  - The Prayer route creates its conflict watch once instead of on every rebuild.
  - The city search field restarts whenever its cubit is replaced.
  - The RPC receipt returns the stored server `detected_at`, so conflict times match the inbound pull.
  - The RPC rejects a completion instant outside `[local_date − 1 day, local_date + 2 days)` and any `local_date` more than 2 days after the server's current date. Delayed offline delivery stays valid.
  - The reconciler reads the owner's local reports in one query instead of one SELECT per remote row. The full-pass restart from T107 is unchanged.
- **Results:**
  - `flutter analyze`: no issues.
  - `flutter test`: **760/760** passed.
  - `supabase db reset --local && supabase test db`: **251/251** passed across 16 files, including 3 new Prayer cases (completion before/after its day, receipt `detected_at`).
  - `flutter test -d windows integration_test/prayer_offline_sync_test.dart` against local Supabase: **1/1** passed. It ran directly on Windows this time, without the earlier host-test copy.
- **T126 desktop measurement:** `integration_test/prayer_schedule_test.dart` now seeds the SC-006 fixture: 3,660 days × 5 = **18,300 reports**. On Windows 10 Pro 19045, debug build, local encrypted store, it measured `PRAYER_HISTORY_FIXTURE reports=18300 cold_readable_ms=106 action_visible_ms=194` and `PRAYER_OFFLINE_SEVEN_DAY_MS elapsed=60`, against limits of ≤2000 ms readable and ≤1000 ms action. The seven offline dates ran under an HTTP override that fails any request. Limits are asserted whenever `PRAYER_TEST_TARGET` names a device. Debug mode is slower than profile, so a profile run can only be faster.
- **Not covered here:** named-phone measurement (T125), hosted staging sync (T119–T120), visual/timed journeys (T128), the five-target runs and the exact-head gate (T131/T133). Migration 0015 has still only been applied locally. The staging migration list could not be read (login-role connection timeout).
- **Known limitation:** the Home "pending sync" XP suffix only considers today's Prayer reports. Unconfirmed awards from earlier days still count in the total but are not labeled.

### Prayer UI rebuilt against the prototype (2026-11-05)

The user reported, from a Windows desktop screenshot, that the Prayer screen did not match the prototype. The recitation line rendered as large red text with a yellow underline. Cause: the Prayer route had no `Scaffold`/`Material` ancestor inside the navigation shell, so unstyled text fell back to Flutter's debug style. The widget tests had not caught it because they wrap the screen in a `Scaffold`. `PrayerScreen` now owns its `Scaffold`, like every other feature route.

The four groups were rebuilt against `prototype/src/views/PrayerView.tsx`:

- **Heading:** title, subtitle with location pin, streak badge (coming soon) and an "n/5 Complete (p%)" badge.
- **Cards:** state-tinted icon box, name with rak'ahs pill, and "time • recitation" on one line, with the sunnah note below.
- **Actions:** filled when selected. "On time" and "late" have labels; "missed" is an icon button with a tooltip. They sit inline on wide layouts and below a separator on phones.
- **Supplementary times:** centered tiles.
- **Jahr/Sirr guide:** an accent-bordered panel.

Retained adaptations:
- **Religious copy:** stays the source-mapped T127 wording. The prototype's unreviewed per-prayer recitation notes were not copied.
- **Accessible reset-to-pending:** an icon button.
- **Context line:** date/zone/method in one line, plus a 40px minimum action target.
- **Quiet location:** after the user's phone review, a granted device location is re-checked quietly on each visit, with no persistent header button. The "use my location" action and city/method search moved into one settings sheet, opened from an icon beside the title.
- **Source label:** shown only for the local fallback.

Rendered captures with the real fonts were inspected at 1180 px (Arabic dark, English light) and 390 px (Arabic dark, English light with a device location). These are host renders, not physical-device evidence for T128. Prayer widget and unit tests, Today widget tests and the architecture suites passed **243/243**, including a new assertion that a saved device location shows no on-screen location button but offers it in the settings sheet.

### T125 physical-phone measurement (2026-11-05)

Ran `flutter drive --profile -d UGGAHM8PC6WGJZNF --driver=test_driver/integration_test.dart --target=integration_test/prayer_schedule_test.dart --dart-define=PRAYER_TEST_TARGET=CPH2481-android15-profile` on a physical **CPH2481, Android 15, profile build**, with the encrypted local store and the 18,300-report history fixture. Result: **2/2 passed**.

Measurements:
- `PRAYER_HISTORY_FIXTURE reports=18300 cold_readable_ms=16 action_visible_ms=10`
- `PRAYER_OFFLINE_SEVEN_DAY_MS elapsed=11`

Both are against the ≤2000 ms readable and ≤1000 ms action limits, which were enforced because the target is named. The seven offline dates ran with every HTTP request failing.

Scope: these times measure the data path from an encrypted reopen to the first readable day snapshot, and from a local status write to the visible day count. They are not a frame-render timing of the full route. The manual offline/permission/visual phone checks remain under T137/T128.

### Hands-on phone check (2026-11-05, user-run)

The user ran `flutter run --profile -d UGGAHM8PC6WGJZNF --dart-define=NAMAA_TASKS_PREVIEW=true --dart-define=NAMAA_DEVICE_PREVIEW=false` on the CPH2481 (Android 15) and sent three screenshots (Arabic, dark theme):

- **Granted location:** the header shows "موقعي الحالي", Thursday 5 November 2026, `Africa/Cairo`, Egyptian General Authority method. There is no on-screen location button; only the settings (tune) icon sits beside the title.
- **Times:** Fajr 4:44 AM and Dhuhr 11:39 AM, which are plausible for Cairo on that date with the Egyptian method. A comparison against the mosque timetable or AlAdhan has not been recorded yet.
- **Offline:** with airplane mode on, the same schedule and statuses were still rendered.
- **Home agreement:** the Home "Prayers" tile shows 5/5, matching the Prayer header's "5/5 complete (100%)" badge. The hero shows "awaiting sync confirmation" because the local preview has no server, which is expected.
- **Visual note:** on this phone width, the reset button on a completed card wraps onto its own second row under the three status buttons.

Still open under T128/T137: the settings-sheet flow, denied permission falling back to manual search, English and light-theme phone captures, a desktop capture, and the timetable comparison.

**Fix (2026-11-06):** on phones, `PrayerStatusActions(fillWidth: true)` lays the controls out in one row. "On time" and "late" share the width, and their labels scale down if needed. They are followed by the missed and reset icons, so reset no longer wraps onto its own line. With text scale above 1.3, or on wide layouts, the controls keep the wrapping layout. A new widget test pins all four controls to one row at a 300 dp width in Arabic and English. Prayer widget/unit tests and the architecture suites passed (196, 1 skipped). This still needs a look on the phone.

### Phone bottom navigation fix (2026-11-06, user-reported)

From the phone review: "المالية الشخصية" wrapped onto two lines in the bottom bar, and taps sometimes landed on the wrong tab.

- **Label:** the bar now uses the prototype's short `navFinance` label ("المالية" / "Finance") through `dashboardNavFinance`. The tooltip keeps the full name.
- **Highlight:** Finance now has its own `TodayNavigationSection.finance`, so it highlights tab 3. Before, it highlighted "More".
- **No stacking:** a tab opened from another pushed tab (Track, Finance, preview) replaces it instead of stacking on top. Back now returns to the starting page, and re-tapping Finance does nothing.
- **Sidebar:** the wide sidebar highlights Finance too.

A new shell widget test covers the highlight, the replacement, and back. `flutter analyze` reports only the existing `lib/main.dart` warning. The full suite ran 761 passed, 1 skipped, and 1 failure, which was the dashboard contract test's old label; that test has been updated and the Today widget tests now pass 49/49. Still to check on the phone.

**Follow-up (2026-11-06, user direction): tab navigation, no back stack.** The user wants sections to behave as tabs. Switching sections must not pile pages up, there should be no top back arrow, and the bar or sidebar is the way to move.

- **Switching sections:** Home now switches with `GoRouter.go` instead of `push`, the same as the feature shells, so Tasks, Habits, Mind Maps and Prayer open as the only page.
- **Track, Finance and previews:** these open as a single page over the current section. A second one replaces the first, and choosing any destination closes it first.
- **No back arrows:** `TodayComingSoonPage(showBack: false)` inside the shell, and `PrayerTrackHub` lost its back button.
- **Device back button:** from any section it goes to Home; on Home it leaves the app.

Tests:
- The tests that tapped the back arrow now use the device back.
- New shell tests check: no back arrow; Finance → Tasks leaves Tasks as the only page; back from Track goes Home.
- `flutter analyze`: only the existing `lib/main.dart` warning.
- Full `flutter test`: **763 passed, 1 skipped**.
- Still needs a phone check.

## Closeout checks and pre-gate audit (2026-11-06)

### T129 — owner/secret/architecture/migration

- **Migration upgrades:** `flutter test test/unit/core/data/local/prayer_migration_test.dart` passed **10/10**. This covers the fresh v8 database, the real v1…v7 → v9 and installed v8 → v9 upgrades that preserve records, and the failed v8 upgrade that rolls back and records recovery later.
- **Architecture and boundaries:** the architecture suites pass inside the full run below; they cover owner/preview isolation, Prayer/Today boundaries and the no-direct-XP-write rules. The isolation tests themselves sit in the Prayer unit suites in the same run.
- **Secret scan:** the branch diff against `main` was searched for service-role keys, JWTs, `sk_live`, private keys and inline API secrets. The only hits are the existing secret-guard implementation and its synthetic test fixtures; no real credential appears. Prayer code has no `print`/`debugPrint`/`log` call that could leak a payload, query or key. `gitleaks` is not installed on this host, so that scan stays with the CI gate.
- **Android release permission:** the main manifest declares `INTERNET`, `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- **`.metadata`:** identical to `main` (`git diff main -- .metadata` is empty).

### T130 — format, analysis, suites

- `dart format --output=none --set-exit-if-changed lib test integration_test`: 448 files, 0 changed.
- `flutter analyze`: one warning, `lib/main.dart:28` `unused_local_variable`. It comes from the user's uncommitted local DevicePreview toggle; the committed tree is analyzer-clean.
- `flutter test` (full suite, which includes the Prayer, XP, Today, app and architecture tests): **763 passed, 1 skipped**.
- `supabase test db` against local Docker with migration 0015: **251/251** in 16 files, PASS.
- No device suite was repeated: since the last device runs there have been only presentation/navigation changes, which the widget tests cover.

### Requirement coverage

All 28 FRs have their owner tasks complete except two:
- **FR-014** owns T129, which is closed by the checks above.
- **FR-028** owns T134, this audit.

All 8 SCs: SC-002, SC-003, SC-004 and SC-006 are complete. SC-001, SC-005, SC-007 and SC-008 still wait on **T128**, the hands-on phone/desktop journey.

### Remaining blockers before 008 can close

1. **T128 / T137 (user, on device):**
   - the settings sheet;
   - denied permission → manual search;
   - English and light-theme phone captures, and a desktop capture;
   - the timetable compared with AlAdhan or a mosque;
   - the ≤60 s scripted journey;
   - a recheck of the new tab navigation and the one-row status actions.
2. **T119 / T120 (needs explicit approval):** migration 0015 on the isolated staging project, then the two-device sync run.
3. **T131:** iOS, macOS and Linux cannot run on this Windows host. Android (CPH2481) and Windows have passed; the other three come from the CI gate.
4. **T133 (needs push approval):** the full PR-to-develop gate on the final head.
5. **T132 / T134:** final doc/task-state pass and closure recommendation after items 1–4. The pre-gate pass is recorded here.

**Release-only prerequisite:** none from city search. Search was removed on 2026-11-06 (see below), so no geocoding licence is needed.

### Migration 0015 on the isolated staging project (2026-11-06, user-approved)

The user explicitly approved applying 0015 to staging. The linked project is `namaa_satging` (`qfjwybbmqhpxxikubhuh`, eu-west-1), the same isolated staging project used by 004–007. The production project (`Namaa Project`) was not touched.

1. **Restore.** Staging had been paused (`INACTIVE`) by the free tier. The user restored it from the dashboard, and the CLI then reported `ACTIVE_HEALTHY`.
2. **Before.** `supabase migration list --linked` showed 0001–0014 applied remotely, with only 0015 missing.
3. **Dry run.** `supabase db push --linked --dry-run` listed only `0015_prayer_reports_and_rewards.sql`, with no seeds and no roles.
4. **Push.** `supabase db push --linked` applied 0015, and the list now shows 0015 both locally and remotely.
5. **Read-only verification query:**
   - `prayer_reports`, `prayer_conflicts` and `prayer_operation_receipts` exist, all with RLS enabled;
   - `apply_prayer_report_change_v1` is `SECURITY DEFINER`;
   - `anon` cannot execute it;
   - `prayer_reports` has 0 rows.

T119/T120 are not done yet. The hosted two-device sync entry needs the two staging test accounts, which come from repository secrets, so it runs through the Foundation CI workflow. That needs the branch pushed first.

### User hands-on round 2 (2026-11-06)

**Physical phone (CPH2481, Cairo, Egyptian method).** The user compared the five times with the local mosque timetable and found them within 1–2 minutes for most prayers. Printed mosque timetables often add a precautionary minute or two. The ≤1-minute SC-002 check against an independent calculation reference stays the automated 504/504 matrix.

**Android emulator, light theme, Arabic.** The emulator's default GPS fix is Mountain View, CA, so it resolved to `America/Los_Angeles` with the North America method. Times on Thursday 5 November 2026:
- Fajr 5:34 AM
- Dhuhr 11:53 AM
- Asr 2:45 PM
- Isha 6:20 PM
- next-day Fajr 5:35 AM

These are consistent with Mountain View after the 1 November DST end (PST, solar noon ≈ 11:52). With the clock about 5:57 PM, Home showed Isha as the next prayer, a 23-minute countdown, and Fajr as the following prayer. That is correct, because Maghrib had passed.

The Home header shows Friday 6 November while Prayer shows Thursday 5 November. The emulator's system zone is not the GPS zone, and per FR-012/SC-007 the Prayer day follows the location's zone while the Home/Task/Habit calendar stays device-local. This is intended behaviour.

The phone status actions render on one row, and the Finance tab label fits on one line.

**Manual city and English UI (emulator).** The user opened the settings sheet, chose New York manually, and switched the app to English.

- The header shows `America/New_York` and North America.
- Fajr 5:14 AM and Dhuhr 11:40 AM are consistent with New York's solar noon on 5 November 2026 (EST).
- The English cards, the rak'ahs pill wrapping, the one-row actions ("On time", "Completed late", missed), and the English bottom bar all render without clipping.

This covers the settings-sheet flow and the English capture.

**Observed (fixed below):** the saved city name stayed in the language it was searched in. The English screen shows "نيويورك، الولايات المتحدة الأمريكية", because `PrayerCity` stores a single `name`/`countryName` returned by the provider for the search locale. Re-selecting the city while in English shows the English name.

**Denied permission.** The user ran these checks with location permission off for the app. Setup fell back to manual city search, which then saved New York. This covers the denied → manual path on the emulator.

**Fix (2026-11-06, user-requested): the city name follows the app language.**
- `CitySearchPort.lookup` fetches the same provider city by id in a given language. The evaluation provider uses Open-Meteo `/v1/get?id=…&language=…`. The licensed gateway and the unavailable adapter return null, since that contract has no lookup route yet.
- `PrayerCityNameLocalizer` replaces only the saved display names (city, country, admin), as a new preference revision. Coordinates, zone and method are kept, so times do not change. The annual-cache key excludes names, so nothing is re-downloaded.
- The Prayer screen attempts this quietly, once per city and language per visit. Offline, unsupported, device-location and already-matching cases save nothing.
- New unit tests cover the lookup request and the localizer. A screen test checks that an English app renames a city saved as القاهرة to Cairo.
- `dart format` changed 0 of 450 files, `flutter analyze` reported no issues, and the full `flutter test` run gave **767 passed, 1 skipped**.
- Home shows the new name after a Prayer visit in the new language.

### Scope change: location only, city search removed (2026-11-06, user decision)

The user decided that prayer times come only from the device location and that users do not need city search. Its commercial licensing cost was not worth it.

**Removed:**
- `CitySearchPort`, `DioCitySearch` and `PrayerSearchConfiguration`;
- `CitySearchCubit`/`CitySearchState` and `PrayerCityEditor`;
- the same-day `PrayerCityNameLocalizer`, which is no longer needed;
- the preview search adapter and its DI registration;
- nine search strings per language;
- the `test/fixtures/prayer/cities` fixtures and five search test files.

**Setup without a location:**
- shows the reason;
- shows **Try again**;
- for denied permission or disabled services, shows **Open settings**: `openAppSettings` or `openLocationSettings` through the new `PrayerDeviceLocationPort.openSettings`;
- retries once by itself when the app resumes from settings;
- never assigns a default location.

**Settings sheet:** the new `PrayerSettingsSheet` has **Update my location**, the calculation method with **Save**/**Cancel**, and the AlAdhan attribution.

A city saved manually before this change still displays and calculates. Its settings sheet offers only the device location.

**Docs:** spec (new 2026-11-06 clarification, US1/AS1/AS8, edge cases, FR-002, FR-004, SC-001, assumptions), quickstart and tasks (scope note and T140) are updated.

**Checks:**
- `flutter analyze`: no issues.
- `flutter test`: **729 passed, 1 skipped**. The count is lower than the previous 767 because the deleted search tests are gone.
- Widget tests cover the new paths: denied → open settings → resume retry → saved, and a settings sheet with the method and no search.
- `flutter test -d windows integration_test/prayer_localized_route_test.dart`: **4/4**, AR/EN × touch/keyboard, with the device location saved.
