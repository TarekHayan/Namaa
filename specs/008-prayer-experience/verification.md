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

**Blocked**: the frozen independent AlAdhan matrix has 84 city/method/date rows and 504 prayer/sunrise values. The pinned on-device calculator agrees within 60 seconds on 465 values; 39 exceed the limit. Their exact classes and source links are in `test/fixtures/prayer/calculation/README.md`. The test rejects any additional mismatch but does not count these 39 as accepted. All 504 corresponding values from the unpacked prototype's `adhan` JS 4.4.4 calculation matched the Dart adapter within 60 seconds; this is prototype parity, not independent validation. Source-attributed zero-coordinate/polar fixtures remain pending (T030–T031).

**2026-10-31 source change**: AlAdhan's annual calendar is now the primary schedule, with complete-year response validation, encrypted owner/context cache and explicit local fallback beyond coverage. The frozen comparison remains relevant to the local fallback and is still blocked. Mocked annual responses prove parsing, caching, owner separation and offline restart; a live annual endpoint capture and named-device check remain T137.

**2026-11-01 location correction**: The user's screenshot selected the Open-Meteo result “مصر، مصر”, whose coordinates are 27.00°N, 30.00°E; that is not Cairo or the user's measured position. Prayer now requests a foreground device fix on first setup, resolves its IANA zone and a supported method suggestion through AlAdhan, and saves it per owner/device. Denial or an unavailable/imprecise fix leaves manual city search available. The Prayer header now uses bounded semantic text styles, shows coordinates for device location and displays API/local source above the five times; Home localizes the device-location label.

The live accountless AlAdhan calendar for Cairo (30.0444, 31.2357; Egyptian method 5; 2026-11-01) returned Fajr 04:41 and Maghrib 17:08 Africa/Cairo. Its 365-day response was accepted by the encrypted annual adapter and read again offline in the opt-in live test. A separate provider request failed transiently, so the adapter now retries 5xx/429/network timeouts; the retry path and location success/denial/imprecise-fix cases passed focused tests. This confirms the API payload path, not the named-phone visual or end-to-end location-permission gate still required by T137.

Focused follow-up: 10 affected location/annual/Home tests passed with the live API gate enabled; the additional return-visit test and temporary zone-service retry test passed. `dart analyze` reported no issues on the touched Dart files. Windows Release preview built successfully; a separate Debug build reached the final link step but could not replace the user's currently running `namma_project.exe` (`LNK1168`), so it did not indicate a source or plugin compilation failure. Actual OS permission behavior and rendered dimensions still need a named-device check.

Final targeted rerun for the location correction: `flutter test --no-pub test/unit/features/prayer/data/geolocator_prayer_location_test.dart test/unit/features/prayer/data/aladhan_annual_schedule_test.dart test/widget/features/prayer/prayer_auto_location_test.dart test/widget/features/prayer/prayer_city_editor_test.dart` passed 10/10. Focused `dart analyze` on the changed location/editor/screen files reported no issues. The editor now labels a saved device fix in the current locale, and the quickstart includes first-use permission and manual-fallback checks. This is automated evidence only; the named-device permission and visual check remains T137.

The 1920×1080 widget layout check now asserts bounded heading/location text sizes and no framework layout exception on a saved device fix; its three focused widget cases passed. It is a synthetic viewport, not a physical-device rendering claim.

**2026-11-01 user device check:** The user reports trying the current Prayer location/timetable flow on a real mobile phone and says it works. This is positive phone runtime evidence for the foreground location path; the report did not identify the phone/OS, measured coordinates, displayed source/times, or an offline restart. It therefore does not yet establish the phone/desktop offline-cache and fallback measurements required by T137 or the independent local-calculation threshold in SC-002.

Focused source/migration/context/Prayer route/city editor/Home card run: **22 tests passed**. After adding the Home fallback label and next-year prefetch guard, the two directly affected files were rerun: **4 tests passed**. Focused `flutter analyze --no-pub` reported **no issues**. The test doubles deliberately do not establish actual AlAdhan availability or full-year response shape in this environment; T137 and the remaining Phase 3 gates stay open.

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

## Final merge/release gates

- Full exact-head Foundation CI, local Supabase security suites and five-target evidence: pending later phases.
- Commercial city-search entitlement/gateway: external release configuration prerequisite, not created or purchased here.
- No commit, push, merge, publication or production migration is implied by completing a phase.
