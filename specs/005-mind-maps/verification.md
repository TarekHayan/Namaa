# Mind Maps 005 verification

**Date:** 2026-10-21
**Branch:** `namaa/005-ci-fixes`
**State:** Feature acceptance evidence and the focused Android/iOS runner repairs are verified. The complete workflow gate must pass on the final PR head before merge; focused runs do not satisfy that gate.

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

The following run, [39584622160](https://github.com/TarekHayan/Namaa/actions/runs/39584622160), passed quality and database security but its Android Habits/Mind Maps shard stopped before launching an emulator: Supabase's unused mail-capture container could not bind the runner's occupied POP3 port `54326`. This is a CI setup collision, not an integration-test result. The Android matrix now starts Supabase without the mail-capture service; the installed CLI's `start --help` confirms the `mailpit` exclusion, and the workflow YAML parses. Android and the cancelled platform jobs require a new run on this change.

The next run, [39585513665](https://github.com/TarekHayan/Namaa/actions/runs/39585513665), passed Android Supabase startup. In the Foundation/Tasks shard, `foundation_migration_test.dart` and `foundation_offline_test.dart` passed, then the emulator went offline while the driver connected to `foundation_platform_test.dart`, before its test body began (`Service has disappeared`, `adb: device offline`). The run was cancelled at the user's request; its unfinished jobs provide no acceptance result. The Android runner script now retries a lost device or debug service once only before the Flutter driver connects. It also uses explicit test lists, excluding `mind_maps_two_device_staging_test.dart`, which requires coordinated Windows and Android roles and cannot run in the single-emulator CI shard. `bash -n` and a local stubbed run of both shards passed: 21 intended test files ran, the simulated pre-start disconnect retried once in each shard, and the coordinated test was never selected. These are runner-script checks, not an Android device or five-target CI pass. T093 and SC-006 remain open.

### Mobile runner repair after 39588950642

Run [39588950642](https://github.com/TarekHayan/Namaa/actions/runs/39588950642) on `85cc2d6` passed quality, database security, Windows, Linux, macOS, Android Habits/Mind Maps, and 17 of 20 iOS entries. Android Foundation/Tasks built and installed the migration test but could not connect its driver to the VM service; the timeout's forced termination returned `137`, which the runner had not recognized as a pre-test timeout. No Foundation/Tasks test body ran in that job. The three iOS failures (`habits-edit-delete`, `habits-localized-route`, `mind-maps-localized-route`) built successfully but waited until both startup deadlines; the log-reader messages appeared during timeout cleanup, so those messages alone do not identify the original startup cause.

Android now connects directly to the VM service without DDS or a paused startup, recognizes both timeout statuses, and retries only before the driver connects. iOS now runs the selected Dart entry point through the public `FLTIntegrationTestRunner` XCTest bridge. Its native assertion requires at least one Dart test result and fails on every reported Dart failure; the process wrapper also requires a nonempty, successful `.xcresult` summary. This removes the external debugger-discovery prerequisite from iOS acceptance execution. Eight local runner-control tests passed, covering pre-test forced termination, refusal to retry a real test failure or a timeout after connection, propagation of Xcode failures, and rejection of empty/partial native results. The workflow YAML, shell syntax, and all 20 iOS suite-to-file mappings were checked. These are local runner checks; mobile device confirmation and SC-006 remain pending.

Manual `mobile_only` workflow runs can select Android/iOS suite arrays for focused verification. Other platforms and the final gate are skipped in that mode; only a complete run can satisfy SC-006.

Focused run [39608159074](https://github.com/TarekHayan/Namaa/actions/runs/39608159074) on `186bd0e` passed the entire Android Foundation/Tasks shard. All three iOS native builds and launches worked; their entry points completed their user journeys but failed Flutter's end-of-test semantics-handle check when native accessibility became active during the first test. The native bootstrap now enables the platform semantics fixture before testWidgets records its baseline, while retaining the normal per-test handle disposal checks. A focused widget test confirmed that a native accessibility callback does not change the baseline and that an explicitly created test handle is still counted until disposal. Native builds now target only the active simulator architecture. The remaining iOS confirmation is pending; no final gate is claimed for the focused run.

Focused run [39610974586](https://github.com/TarekHayan/Namaa/actions/runs/39610974586) on `73ce341` passed all three previously failing iOS entries: `habits-edit-delete`, `habits-localized-route`, and `mind-maps-localized-route`. Each job produced a successful native result bundle and reported `iOS XCTest verified: 1/1 native tests passed`; the native case asserts the success of every Dart result in its entry point. Android and desktop jobs were deliberately skipped in this iOS-only run.

### Completed T093 feature evidence; final workflow gate still required

The native XCTest step in focused run [39629487680](https://github.com/TarekHayan/Namaa/actions/runs/39629487680) on `8ef9843` completed successfully after the signing and entitlements fix. The unchanged `foundation_platform_test.dart` exercises real encrypted local storage, real Keychain read/write/delete, connectivity/session adapters, and root appearance/language/routing. The native bridge requires every Dart result to succeed, and the process wrapper also requires a nonempty successful XCTest result bundle. This confirms the repaired iOS platform entry on the Intel-hosted simulator; workflow cache cleanup was still running when the successful step was inspected. Local checks parsed both entitlement plists and validated all three build-configuration links and workflow signing flags. The complete final workflow gate on the PR head remains required before merge.

The Intel diagnostic run [39625364514](https://github.com/TarekHayan/Namaa/actions/runs/39625364514) acquired a runner, booted the simulator, built the application and executed XCTest. Its recorded failure is the first real Keychain read in `foundation_platform_test.dart:56`, returning `foundation.vault.recoverable`; Xcode returned 65 before a cancellation request during cleanup. The unsigned native XCTest build is a concrete configuration defect for testing protected storage. The iOS build configurations now reference the plugin-documented Keychain entitlements, without adding a shared access group, and XCTest builds use ad-hoc simulator signing instead of `CODE_SIGNING_ALLOWED=NO`. The real read/write/delete assertions remain unchanged. A focused platform rerun must verify this candidate fix before the final complete gate.

The replacement platform-only run 39624162612 remained queued without any assigned runner or executed steps. The iOS job now requests the documented `macos-26-intel` standard runner pool instead of the ARM `macos-latest` pool to attempt execution without that pool's capacity delay. This changes the simulator host architecture, not the test assertions or gate requirements. A successful result on the new host must be recorded as Intel-hosted simulator evidence; it does not prove that the earlier ARM XCTest failure is resolved. The complete final workflow must still pass on the selected configuration before merge.

Diagnostic run [39622729802](https://github.com/TarekHayan/Namaa/actions/runs/39622729802) was cancelled while booting its iPhone simulator, before XCTest started. The older diagnostic run 39621401857 was rerun as attempt 2 during the new run, and both shared the focused-mobile concurrency group with automatic cancellation enabled. This overlap is consistent with concurrency cancellation; the job log reports only cancellation, so it does not establish a simulator or product failure. Focused runs now include their workflow run ID in the concurrency group to prevent a rerun of an older diagnostic from cancelling a different diagnostic. Complete runs retain their existing supersession behavior. The platform test still requires execution.

The complete run [39617334877](https://github.com/TarekHayan/Namaa/actions/runs/39617334877) on `ce0493d` passed quality, database security, both Android shards, Windows, Linux, macOS, and several iOS entries. Its iOS `platform` entry returned XCTest exit status `65`, while quiet Xcode output omitted the underlying test failure; the other unfinished iOS entries were subsequently cancelled or still finishing. This is not a passing final gate. The iOS runner now reads and prints native failure details from the result bundle before propagating the original nonzero exit status; seven focused runner-control tests passed, including failure detail reporting and rejection of unreadable result bundles. Focused mobile reruns use a separate concurrency group so they cannot cancel a complete run still finishing. The `platform` entry requires a diagnostic rerun before any product or test behavior is changed.

Run [39588950642](https://github.com/TarekHayan/Namaa/actions/runs/39588950642) passed the Mind Maps persistence, Task-link, and hosted account-sync entries on Android, iOS, Windows, macOS, and Linux. Its unrelated Foundation/Tasks Android startup and three iOS startup failures were then repaired and verified in the focused runs above. `git diff 85cc2d6..73ce341 -- lib integration_test android macos windows linux supabase` is empty; subsequent changes concern runner infrastructure and native test initialization. T093's target checks and recorded results are complete. This combined evidence does not claim a complete workflow pass on the latest head: a final full run remains the merge prerequisite.

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
| FR-006 | Layout and viewport tests cover five layouts, navigation and side-link-neutral placement. The viewport entry passed on all five targets in run 39588950642. |
| FR-007 | Settings/model/widget tests cover map defaults and node appearance. Covered locally. |
| FR-008 | Editor-history tests cover undo/redo and exclude Task/XP effects. Covered locally. |
| FR-009 | Task-link integration and bridge tests cover shared Task identity without copying or rewarding it. Covered locally. |
| FR-010 | Ten complete/reopen journeys now check both linked maps after each transition and one lifetime XP award. Covered locally. |
| FR-011 | Task-link widget/port tests cover unavailable links and privacy-safe repair. Covered locally. |
| FR-012 | Encrypted Drift restart tests, outbox replay tests and local two-device trials cover offline durability and retry. The hosted Mind Maps sync entry passed on all five targets in run 39588950642; ten coordinated hosted two-device trials also passed as recorded above. |
| FR-013 | SQL owner/RLS/conflict tests, local reconciler tests, and isolated-hosted account read/write denial checks pass. |
| FR-014 | Preview route/account isolation tests pass without sign-in; release Auth remains a later feature. Covered for the current preview. |
| FR-015 | Arabic/English Android and Windows route tests and the full Windows keyboard walkthrough pass. The corrected native iOS route entry passed in run 39610974586. The final complete workflow gate remains pending. |
| SC-001 | PASS: library/editor/viewport integration tests and focused settings tests restart encrypted storage after rename, description search, duplicate, delete, graph edits, reparenting, statuses, all five layouts and appearance changes. The library and canvas render the expected saved results. See the scenario audit above. |
| SC-002 | Ten alternate map/Tasks completion and reopening journeys pass for two linked maps; one XP award persists after restart. Covered locally. |
| SC-003 | PASS: ten of ten hosted trials on an Android 17 emulator and Windows desktop with separate encrypted local databases, offline restart on each trial, same-account Supabase reconnection, independent-node merge, retained nonwinning same-node conflict, and four unique remote nodes. Both target processes exited successfully. |
| SC-004 | Isolated-hosted test with two authenticated accounts returned zero foreign map/node/parent/side/conflict rows and rejected foreign mutation of all four graph record types and conflict deletion. The local repository test kept the debug preview identity separate from the real account in both directions; route-switch tests clear stale private UI. Targeted Windows staging and repository tests passed. |
| SC-005 | Android and Windows measurements above are all under two seconds. Met on the tested targets. |
| SC-006 | Arabic/English primary routes pass on Android, Windows, and the corrected native iOS runner. Mind Maps persistence, Task-link, and hosted sync passed on all five targets in run 39588950642. A final complete workflow run on the latest head is still required before merge. |
| SC-007 | Android touch flow and Windows keyboard-only create/add/link/progress walkthrough pass through visible controls. |

## Remaining gate and later features

- **T093 target evidence is complete.** Actual cross-platform feature results and the focused mobile runner repairs are recorded above. Migrations `0008`–`0010` are deployed to the isolated nonproduction project.
- **Merge remains blocked on the final complete workflow gate.** Manual `mobile_only` runs deliberately skip this gate. A normal complete run must pass quality, database security, both Android suites, all 20 iOS entries, Windows, macOS, and Linux on the final PR head. The successful final run and merge are recorded in PR #7's checks/history without creating a documentation-only commit that would invalidate that head.
- Public account entry/initial sync depends on the later **Auth** feature. Final colors, typography and screen composition depend on **UI Refinement**. Neither dependency is implemented by 005.
