# Habits 004 verification

Checked: 2026-10-18. Branch: namaa/004-habits. Status: implementation ready to merge; SC-007 remains unmeasured and is tracked as a pre-release follow-up in [issue #3](https://github.com/TarekHayan/Namaa/issues/3).

## Local checks

| Check | Command / scope | Result |
|---|---|---|
| Formatting | dart format --output=none --set-exit-if-changed lib test integration_test | Pass: 165 files, 0 changes after the staging test addition. |
| Static analysis | flutter analyze --no-pub | Pass: no issues after the staging test addition. |
| Unit, widget and architecture | flutter test --no-pub --reporter compact | Pass: 318 tests, including Habit ownership and XP boundary checks. |
| Windows offline/reconnect | flutter test --no-pub -d windows integration_test/habits_offline_sync_test.dart --reporter expanded | Pass: 3 tests, including ten replay/restart trials. Remote gateway in this test is simulated. |
| Windows streak/history | Same command with habits_streak_history_test.dart | Pass: 1 test. |
| Windows edit/delete | Same command with habits_edit_delete_test.dart | Pass: 1 test after waiting for confirmed persistence. |
| Windows Arabic/English route | Same command with habits_localized_route_test.dart | Pass: 1 test; covers RTL and mobile/desktop layout sizes. |
| Windows authenticated Habit sync | foundation_staging_supabase_test.dart filtered to the staging Habits case, with six staging dart-defines from the ignored local secrets file | Pass: two independent sessions of one owner, encrypted local outbox, receipt replay, remote read and reconciliation to a second encrypted database, another account's isolation, then tombstone propagation and retained conflict evidence. |
| Local SQL | supabase test db | Environment limit: local Postgres at 127.0.0.1:54322 refused the connection because Docker is not running. SQL passed in the final five-target CI run. |
| 2026-10-18 preview route fix | flutter test --no-pub test/widget/app/habits_route_test.dart --reporter compact | Pass: 4 tests, including an initially unknown session settling instead of remaining on the loading screen. |
| 2026-10-18 focused analysis | flutter analyze --no-pub lib/main.dart lib/app/routing/app_router.dart test/widget/app/habits_route_test.dart | Pass: no issues in the three affected Dart files. |

Windows is the locally available native target. Android, iOS, macOS and Linux require their CI runners. All authenticated checks use the isolated non-production project; no production credentials were used.

## Staging database and five-target evidence

On 2026-10-17 the isolated staging project was linked after Supabase CLI login. Its manually provisioned Foundation 0001 migration was recorded as applied. A dry run listed only 0002–0007; those six migrations were then applied with vault updates skipped. A subsequent migration list showed local and remote versions 0001–0007 aligned. The authenticated Windows Habit sync test passed against this project.

The CI workflow lists all four Habit integration entry points on Linux, Windows, macOS and iOS; Android discovers every integration_test/*_test.dart. The staging Supabase entry includes a real authenticated Habit case on every target. [Run 39066867051](https://github.com/TarekHayan/Namaa/actions/runs/39066867051) passed all 20 jobs on commit `e86793e`: quality and shared tests, SQL/RLS, Android, Windows, macOS, Linux, all iOS simulator entries, and the five-target aggregate gate. This verifies encrypted persistence, account sync against the isolated non-production project, ownership isolation, Arabic/English primary routes, and Habit streak/edit/delete flows across the target matrix. T074 is complete. Earlier Phase 7 runs exposed asynchronous UI assertions; the final run includes their fixes.

## Requirements review

| Requirement | Evidence / remaining check |
|---|---|
| FR-001–FR-003 | Domain/command/repository tests, widget controls, encrypted restart and Windows journey. |
| FR-004–FR-005 | Ten schedule cases, account-scoped query tests, history widget and Windows history journey. |
| FR-006–FR-008 | Same-day revision tests, delete/restart journey, inactive reminder wording; delivery is deferred. |
| FR-009 | Atomic local/outbox and rollback tests, offline/reconnect journeys. |
| FR-010–FR-011 | SQL RLS/replay/conflict suites, sync/reconciler tests, simulated two-device trials and live authenticated account sync on all five CI targets. |
| FR-012 | Architecture test blocks direct Habit storage use by Tasks/Today/Dashboard/Analytics and Habit XP awards. |
| FR-013 | Arabic/English widget and route tests passed in the final five-target matrix. |
| FR-014 | Encrypted v3→v4 migration and account isolation tests; Auth/initial account sync are separate release prerequisites. |
| SC-001–SC-003 | Restart, streak and ten-replay tests pass. |
| SC-004–SC-005 | Ten simulated reconnect trials, real SQL owner-isolation checks and live authenticated two-device sync passed across all five targets. |
| SC-006 | Mobile/desktop layout and Arabic/English route checks passed in the five-target CI matrix. |
| SC-007 | Pending human validation in [issue #3](https://github.com/TarekHayan/Namaa/issues/3). No participants are currently available. Participant count: 0; success rate: not measured. |

## Three-minute comprehension check (SC-007)

Give each participant an unassisted fresh preview account. Start a three-minute timer and ask them to create a due-today Habit, complete it, and identify the displayed streak. Record participant count, number completing all three actions correctly within the limit, success rate, and repeated confusion. Pass only if at least 90% succeed. Automated widget tests do not substitute for this check.

## Release boundary

The product owner requested closing the 004 implementation branch before participants are available. This closes the implemented feature work, not SC-007: [issue #3](https://github.com/TarekHayan/Namaa/issues/3) remains open and the criterion must be measured and passed before an account-based release. Public account-based release also depends on the later Auth feature and successful initial account synchronization. Saving a reminder time is implemented; device notification permission, scheduling and delivery belong to the later Notifications feature.
