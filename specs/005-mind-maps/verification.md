# Mind Maps 005 verification

**Date:** 2026-10-19
**Branch:** `namaa/005-mind-maps`
**State:** Phase 8 local checks are complete; the five-target isolated Supabase gate remains open.

## Checks run

| Command | Target | Result |
|---|---|---|
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Windows host | PASS, 231 files, 0 changes after formatting three pre-existing test files. |
| `flutter analyze --no-pub` | Windows host | PASS, no issues on the final revision. |
| `flutter test --no-pub test/unit/features/mind_maps test/widget/features/mind_maps test/widget/app/mind_maps_route_test.dart test/architecture/mind_maps_boundaries_test.dart test/unit/core/data/sync/entity_dispatch_router_test.dart test/unit/core/data/sync/synchronization_coordinator_test.dart --reporter compact` | Windows host | PASS, 69 tests. |
| `supabase test db` | Local Supabase | PASS, 11 files and 196 SQL assertions. `SUPABASE_TELEMETRY_DISABLED=1` was set for the local CLI environment. |
| `flutter test --no-pub -d windows integration_test/mind_maps_viewport_test.dart --reporter expanded` | Windows desktop | PASS, 50 nodes/60 links and persistence. Timings below. |
| `flutter test --no-pub -d emulator-5554 integration_test/mind_maps_localized_route_test.dart --reporter expanded` | Android 17 emulator | PASS, Arabic phone controls and English keyboard canvas controls. |
| `flutter test --no-pub -d windows integration_test/mind_maps_localized_route_test.dart --reporter expanded` | Windows desktop | PASS. A previous combined run stopped before this test launched because the Windows debug log reader stopped; the standalone rerun passed. |
| `flutter test --no-pub -d windows integration_test/mind_maps_task_link_test.dart integration_test/mind_maps_localized_route_test.dart --reporter expanded` | Windows desktop | Task-link case PASS, including ten complete/reopen journeys and one lifetime XP award; combined command exited nonzero only because the second app launch failed before its test started. The standalone localized rerun passed. |
| `flutter test --no-pub -d emulator-5554 integration_test/mind_maps_localized_route_test.dart integration_test/mind_maps_viewport_test.dart --reporter expanded` | Android 17 emulator | Viewport case PASS with timings below. The earlier localized case exposed a test scrolling/timing problem; its corrected standalone run passed. The combined command itself exited nonzero. |
| `python -c "import yaml; yaml.safe_load(open('.github/workflows/foundation-ci.yml', encoding='utf-8')); print('workflow YAML parsed')"` | Windows host | PASS, workflow YAML parsed. |

The Phase 7 `mind_maps_offline_sync_test.dart` also passed ten two-database Android trials before this phase. That test models the cloud boundary; it does not replace the isolated hosted Supabase trial.

## SC-005: 50 nodes and 60 links, offline response

All values are elapsed milliseconds from action through the next rendered test frame. The Windows and Android runs used encrypted local storage without a network dependency. The acceptance targets are the Android `390×844` viewport and Windows `1200×800` viewport.

| Runtime and viewport | Zoom | Fit | Select | Pan | Edit node | Highest |
|---|---:|---:|---:|---:|---:|---:|
| Android 17 emulator, 390×844 | 698 | 107 | 91 | 116 | 852 | **852** |
| Windows desktop, 1200×800 | 50 | 29 | 33 | 32 | 258 | **258** |
| Android emulator, 1200×800 supplemental layout | 57 | 72 | 142 | 70 | 503 | 503 |
| Windows desktop, 390×844 supplemental layout | 196 | 49 | 49 | 51 | 492 | 492 |

All recorded actions were below the two-second threshold. These are emulator/desktop test measurements, not a claim about all production phones or hardware.

## SC-007: visible-control walkthrough

| Input/target | Observed result |
|---|---|
| Android touch, Arabic, 390×844 | PASS in the localized route test: create a map, add a child and note, choose an existing preview Task through the visible picker, and read the map's completed count. Mixed Arabic/Latin labels and RTL direction were checked. |
| Windows keyboard, English, 1200×800 | PARTIAL: the canvas accepted arrow-key pan and `F` fit, and the map's labeled controls and progress were visible. A complete keyboard-only create/add/link walkthrough still needs an explicit run before SC-007 is closed. |

## Requirement review

| Criterion | Evidence and state |
|---|---|
| FR-001 | Map library integration and repository tests cover create, rename, description, copy, confirmed delete and central node. Covered locally. |
| FR-002 | Library query/widget tests cover search, empty states and derived counts. Covered locally. |
| FR-003 | Graph command, editor and repository tests cover node kinds, validation, edits, movement and central-node protection. Covered locally. |
| FR-004 | Graph rule/command tests and SQL integrity tests cover parent slots, detach/reparent, cycle rejection, side links and duplicate-pair rejection. Covered locally. |
| FR-005 | Progress/Task projection tests cover three statuses, central count and unavailable links. Covered locally. |
| FR-006 | Layout and viewport tests cover five layouts, navigation and side-link-neutral placement. Covered locally; device parity is pending. |
| FR-007 | Settings/model/widget tests cover map defaults and node appearance. Covered locally. |
| FR-008 | Editor-history tests cover undo/redo and exclude Task/XP effects. Covered locally. |
| FR-009 | Task-link integration and bridge tests cover shared Task identity without copying or rewarding it. Covered locally. |
| FR-010 | Ten complete/reopen journeys now check both linked maps after each transition and one lifetime XP award. Covered locally. |
| FR-011 | Task-link widget/port tests cover unavailable links and privacy-safe repair. Covered locally. |
| FR-012 | Encrypted Drift restart tests, outbox replay tests and local two-device trials cover offline durability and retry. Hosted device synchronization remains pending. |
| FR-013 | SQL owner/RLS/conflict tests and local reconciler tests pass. Hosted account checks remain pending. |
| FR-014 | Preview route/account isolation tests pass without sign-in; release Auth remains a later feature. Covered for the current preview. |
| FR-015 | Arabic/English Android and Windows route tests pass. iOS, macOS and Linux checks and a full keyboard walkthrough remain pending. |
| SC-001 | Library/editor/viewport integration tests restart encrypted storage after representative map, graph, layout and appearance changes. An exhaustive per-scenario restart walkthrough is still pending. |
| SC-002 | Ten alternate map/Tasks completion and reopening journeys pass for two linked maps; one XP award persists after restart. Covered locally. |
| SC-003 | Ten two-database offline/reconnect trials pass with simulated delivery. Hosted two-device convergence remains pending. |
| SC-004 | Local SQL RLS/account tests and route-switch tests reveal no foreign data. Hosted account isolation remains pending. |
| SC-005 | Android and Windows measurements above are all under two seconds. Met on the tested targets. |
| SC-006 | Arabic/English primary routes pass on Android and Windows. Five-target persistence and hosted sync gate remains pending. |
| SC-007 | Android touch flow passes; complete keyboard-only workflow remains pending. |

## Remaining gate and later features

- **T093 remains open.** The new `mind_maps_staging_sync_test.dart` and local persistence/Task-link entries are wired into Android, iOS, Windows, macOS and Linux CI. The workflow still runs only on a PR to `develop` or manual dispatch. Results cannot be claimed until this branch's Phase 8 changes are available to CI, migrations `0009` and `0010` are deployed to the isolated nonproduction project, and the five-target gate actually runs. Local host access here provides Android and Windows only.
- SC-001's exhaustive restart walkthrough, SC-003/004 hosted-device evidence, SC-006 five-target evidence and SC-007's complete keyboard-only walkthrough are not yet acceptance-complete.
- Public account entry/initial sync depends on the later **Auth** feature. Final colors, typography and screen composition depend on **UI Refinement**. Neither dependency is implemented by 005.
