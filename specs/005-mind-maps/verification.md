# Mind Maps 005 verification

**Date:** 2026-10-21
**Branch:** `namaa/005-ci-fixes`
**State:** SC-001 and SC-003 are verified locally and against the isolated hosted project. Do not merge until SC-006 passes on the final PR head.

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
| `flutter test --no-pub test/unit/features/mind_maps/application/map_settings_test.dart --reporter expanded` | Windows host | PASS, 2 tests: map/node/connection appearance and each of five layouts survive encrypted offline restart without changing graph identity. |
| `flutter test --no-pub -d windows integration_test/mind_maps_library_test.dart --reporter expanded` | Windows desktop | PASS, renamed map, duplicate graph and Task link, deletion, and title/description search remain visible after offline restart. |
| `flutter test --no-pub -d windows integration_test/mind_maps_editor_test.dart --reporter expanded` | Windows desktop | PASS, moved branch and descendants, detached branch, three statuses, side link, movement and deletion remain correct after offline restart. |
| Targeted rerun of `mind_maps_editor_test.dart` and `mind_maps_viewport_test.dart` after the visible-canvas assertions | Windows desktop | PASS, the reopened graph renders the surviving nodes and omits the deleted node; the edited title appears on the reopened 50-node canvas. |
| Coordinated `flutter test --no-pub -d windows` and `flutter drive -d emulator-5554` on `mind_maps_two_device_staging_test.dart` | Windows desktop and Android 17 emulator, same isolated staging account | PASS, ten of ten hosted offline restart/reconnect trials on both devices. Independent edits to two nodes merged, the nonwinning same-node title remained reviewable as a conflict, and each trial retained exactly four remote nodes without duplicates. |

The Phase 7 `mind_maps_offline_sync_test.dart` also passed ten two-database Android trials before this phase. That test models the cloud boundary; it does not replace the isolated hosted Supabase trial.

## PR CI follow-up

The first full PR run, [39312996337](https://github.com/TarekHayan/Namaa/actions/runs/39312996337), completed on 2026-10-19 with quality, database security, macOS, and 18 iOS simulator entries successful, including Mind Maps staging sync. The run did not pass its five-target gate:

- Windows and Linux reached the new hosted Mind Maps test before the staging database had migrations `0008`–`0010`; both reported missing `apply_mind_map_change`. Those migrations were then applied to the linked isolated `namaa_satging` project and confirmed in its migration history.
- Android was cancelled at the job's 60-minute limit after its first APK installed, before reporting a test result. A prior Android gate succeeded; this run provides no Android pass.
- The iOS Habits streak/history entry failed to establish a debug connection on two simulator startup attempts. Its test body did not start.
- The iOS Mind Maps localized route found the Save text but its tap was blocked while the text input overlay was active. The route test now completes text input, waits for layout to settle, and taps a stable Save control key. The changed files passed direct Dart analysis and the Windows localized route integration test. iOS still requires a successful CI rerun.

T093 remains open until the corrected PR run reports successful persistence, account sync, and Task-link coverage on all five targets.

The second full run, [39330762994](https://github.com/TarekHayan/Namaa/actions/runs/39330762994), passed quality, database security, Windows, Linux, macOS, and 19 of 20 iOS simulator entries. The iOS Mind Maps localized route failed with two layout overflows while the native keyboard was open: the test had forced a `390×844` physical view and pixel ratio 1 on the simulator. The test now keeps the device's native dimensions on iOS/Android and explicitly unfocuses after text entry; its Windows integration rerun passed. Android again reached the first APK installation but produced no test result before the 60-minute job limit. Its CI suite is now split into two feature groups, uses the device integration driver, and bounds each attempt so a startup stall is diagnosed and retried once. These changes still need CI confirmation.

The third run, [39413071704](https://github.com/TarekHayan/Namaa/actions/runs/39413071704), confirmed both Android shards now start and execute tests. The Habits/Mind Maps shard reached the library deletion flow, where an active search keyboard covered the Delete control and the follow-up confirmation dialog never appeared. The test now unfocuses after clearing search and settles scrolling before tapping Delete. The focused library integration test passed on Windows and on the local Android emulator (`flutter test --no-pub -d emulator-5554 integration_test/mind_maps_library_test.dart --reporter expanded`). The iOS editor job failed before its test body started because the simulator log reader could not establish a debug connection; [rerunning only that job](https://github.com/TarekHayan/Namaa/actions/runs/39413071704/job/118760229498) succeeded. The original run's remaining 25 jobs passed, while the Android Habits/Mind Maps shard and dependent gate failed. The corrected Android test has not yet been run on CI at the new commit, so T093 remains open.

The fourth run, [39466663938](https://github.com/TarekHayan/Namaa/actions/runs/39466663938), passed quality, database security, Windows, Linux, and all 20 iOS simulator entries. Both Android shards stopped before executing a test: the hosted runner's Java `25.0.4.1` could not run this project's Gradle `8.14` build. The Android workflow now selects Temurin JDK 21, which supports the project's Java and Kotlin 17 targets. The failed Android `assembleDebug` build step passed locally with OpenJDK `21.0.10` and Gradle `8.14` (`BUILD SUCCESSFUL`, 293 tasks). The macOS job was cancelled before any steps or logs were available, so it provides no test result; only this job was rerun in attempt 2. The five-target gate remains open pending a clean rerun on the updated branch.

The fifth run, [39489378940](https://github.com/TarekHayan/Namaa/actions/runs/39489378940), used the JDK 21 workflow. Quality, database security, both Android shards, Windows, Linux, and macOS passed. Its iOS `tasks-checklist-history` job failed before the test started when Flutter's simulator log reader lost the debug connection twice; the application had built successfully. [Rerunning only that job](https://github.com/TarekHayan/Namaa/actions/runs/39489378940/job/118903688426) on the same commit passed on its first attempt (`All tests passed`). This supports a runner-specific startup failure rather than a checklist behavior regression. The run was cancelled with seven Mind Maps iOS jobs still incomplete, so the five-target gate remains open.

The seven Mind Maps iOS simulator jobs were rerun on the same commit in [attempt 4](https://github.com/TarekHayan/Namaa/actions/runs/39489378940/attempts/4) and all passed. The final acceptance changes below still need a full PR run on their own head commit before T093 and SC-006 can close.

The next PR run, [39579607239](https://github.com/TarekHayan/Namaa/actions/runs/39579607239), passed quality, database security, Linux and iOS offline, but its Android Habits/Mind Maps shard found a real small-screen overflow in the Arabic map creation dialog while the keyboard was open. The other unfinished jobs were cancelled, so they provide no result for this head. A focused `320×640` widget test with simulated keyboard insets reproduced a 24-pixel overflow before the fix, then passed after the dialog content became scrollable; it also saved and displayed the Arabic map. All three map-library widget tests and the targeted Android localized-route `flutter drive` run passed locally after the fix. The new head still needs the complete five-target gate.

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
| Windows keyboard, English, 1200×800 | PASS in the localized route test: Tab and Enter reached the visible controls to create and open a map, open the editor, add a child and a note, choose an existing Task, and read the completed count; arrow keys chose the note type and controlled canvas pan, and `F` fit the canvas. The targeted Windows keyboard-only test passed without pointer taps. |

## SC-001: offline restart scenario audit

| Scenario group | Restart evidence | Visible-result check |
|---|---|---|
| Create, rename, description search, duplicate and confirmed delete | `mind_maps_library_test.dart` closes and reopens the encrypted database, keeps the renamed map and independent copied graph with its Task ID, and keeps the deletion absent. | Rebuilt library screen shows the renamed map and copied map; searching the saved description filters the list. Blank-title feedback is covered by `map_library_screen_test.dart`. |
| Node types, connections, detach, reparent, statuses, move, delete and undo/redo | `mind_maps_editor_test.dart` reopens the graph with preserved parent slots, side link, node positions, three statuses and completed count; removed node stays absent. The Task-type path is covered by `mind_maps_task_link_test.dart`. | PASS: the reopened graph renders the surviving nodes and omits the deleted node. Editor and graph widget tests cover the visible controls, validation and progress. |
| Shared Task and XP | `mind_maps_task_link_test.dart` reopens two maps linked to one Task after ten completion/reopening journeys and confirms one lifetime award. | Map/Task widget tests show the current linked status and unavailable-link repair controls. |
| Five layouts, settings and appearance | `map_settings_test.dart` reopens encrypted storage after each layout and checks graph identity, spacing, colors, shapes and connection styling. `mind_maps_viewport_test.dart` reopens a 50-node/60-link graph. | PASS: settings widgets expose all five choices, and the reopened large canvas renders the edited node title. |

SC-001 passes on the tested preview and Windows target: every scenario group has durable restart evidence plus a visible-result assertion in the integration or focused widget layer.

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
| FR-013 | SQL owner/RLS/conflict tests, local reconciler tests, and isolated-hosted account read/write denial checks pass. |
| FR-014 | Preview route/account isolation tests pass without sign-in; release Auth remains a later feature. Covered for the current preview. |
| FR-015 | Arabic/English Android and Windows route tests and the full Windows keyboard walkthrough pass. Remaining iOS entries and final five-target gate are pending. |
| SC-001 | PASS: library/editor/viewport integration tests and focused settings tests restart encrypted storage after rename, description search, duplicate, delete, graph edits, reparenting, statuses, all five layouts and appearance changes. The library and canvas render the expected saved results. See the scenario audit above. |
| SC-002 | Ten alternate map/Tasks completion and reopening journeys pass for two linked maps; one XP award persists after restart. Covered locally. |
| SC-003 | PASS: ten of ten hosted trials on an Android 17 emulator and Windows desktop with separate encrypted local databases, offline restart on each trial, same-account Supabase reconnection, independent-node merge, retained nonwinning same-node conflict, and four unique remote nodes. Both target processes exited successfully. |
| SC-004 | Isolated-hosted test with two authenticated accounts returned zero foreign map/node/parent/side/conflict rows and rejected foreign mutation of all four graph record types and conflict deletion. The local repository test kept the debug preview identity separate from the real account in both directions; route-switch tests clear stale private UI. Targeted Windows staging and repository tests passed. |
| SC-005 | Android and Windows measurements above are all under two seconds. Met on the tested targets. |
| SC-006 | Arabic/English primary routes pass on Android and Windows. Five-target persistence and hosted sync gate remains pending. |
| SC-007 | Android touch flow and Windows keyboard-only create/add/link/progress walkthrough pass through visible controls. |

## Remaining gate and later features

- **T093 remains open.** The new `mind_maps_staging_sync_test.dart` and local persistence/Task-link entries are wired into Android, iOS, Windows, macOS and Linux CI. Migrations `0008`–`0010` are deployed to the isolated nonproduction project. The workflow runs on PRs to `develop` or manual dispatch. The five-target gate needs a clean rerun after the iOS and Android CI fixes above; local host access here provides Android and Windows only.
- SC-006's new-head five-target gate remains open. SC-001 and SC-003 are verified above.
- Public account entry/initial sync depends on the later **Auth** feature. Final colors, typography and screen composition depend on **UI Refinement**. Neither dependency is implemented by 005.
