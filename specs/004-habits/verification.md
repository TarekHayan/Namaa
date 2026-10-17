# Habits 004 verification

Checked: 2026-10-17. Branch: namaa/004-habits. Status: Phase 7 technical checks in progress; 004 is not closed.

## Local checks

| Check | Command / scope | Result |
|---|---|---|
| Formatting | dart format --output=none --set-exit-if-changed lib test integration_test | Pass: 165 files, 0 changes. |
| Static analysis | flutter analyze --no-pub | Pass: no issues. |
| Unit, widget and architecture | flutter test --no-pub --reporter compact | Pass: 318 tests, including Habit ownership and XP boundary checks. |
| Windows offline/reconnect | flutter test --no-pub -d windows integration_test/habits_offline_sync_test.dart --reporter expanded | Pass: 3 tests, including ten replay/restart trials. Remote gateway is simulated. |
| Windows streak/history | Same command with habits_streak_history_test.dart | Pass: 1 test. |
| Windows edit/delete | Same command with habits_edit_delete_test.dart | Pass: 1 test. |
| Windows Arabic/English route | Same command with habits_localized_route_test.dart | Pass: 1 test; covers RTL and mobile/desktop layout sizes. |
| Local SQL | supabase test db | Environment limit: local Postgres at 127.0.0.1:54322 refused the connection because Docker is not running. SQL passed in prior CI; final-commit recheck is pending. |

Windows is the locally available native target. Android, iOS, macOS and Linux require their CI runners. These checks used no production project or credentials.

## Five-target and account evidence

The CI workflow now lists all four Habit integration entry points on Linux, Windows, macOS and iOS; the Android script discovers every integration_test/*_test.dart. The last Phase 6 CI run ([run 39052613021](https://github.com/TarekHayan/Namaa/actions/runs/39052613021)) passed quality, Supabase SQL/RLS, Linux, Windows, macOS and every iOS job then listed. Android was canceled during its rerun after a first-attempt timeout in the Foundation migration test, so the five-target gate did not pass. That run preceded the new streak/history and edit/delete entries. A final-commit run must pass before T074 or T076 can close.

The device tests cover encrypted persistence, Habit state/reconciliation and localized routes. The two-device Habit test uses a deterministic in-process remote gateway; the SQL suite checks real Postgres owner isolation and mutation receipts; the existing foundation_staging_supabase_test.dart checks authenticated session/Data API access against the isolated non-production project on target devices. A live authenticated Habit-to-Habit device sync against that project has not yet been demonstrated and remains a T074 evidence gap.

## Requirements review

| Requirement | Evidence / remaining check |
|---|---|
| FR-001–FR-003 | Domain/command/repository tests, widget controls, encrypted restart and Windows journey. |
| FR-004–FR-005 | Ten schedule cases, account-scoped query tests, history widget and Windows history journey. |
| FR-006–FR-008 | Same-day revision tests, delete/restart journey, inactive reminder wording; delivery is deferred. |
| FR-009 | Atomic local/outbox and rollback tests, offline/reconnect journeys. |
| FR-010–FR-011 | SQL RLS/replay/conflict suites, sync/reconciler tests and simulated two-device journey. Live authenticated Habit sync remains open. |
| FR-012 | Architecture test blocks direct Habit storage use by Tasks/Today/Dashboard/Analytics and Habit XP awards. |
| FR-013 | Arabic/English widget and route tests; final five-target matrix is pending. |
| FR-014 | Encrypted v3→v4 migration and account isolation tests; Auth/initial account sync are separate release prerequisites. |
| SC-001–SC-003 | Restart, streak and ten-replay tests pass. |
| SC-004–SC-005 | Simulated ten-trial reconnect plus real SQL owner-isolation checks pass; live authenticated cross-device Habit check remains open. |
| SC-006 | Windows mobile/desktop layout and language checks pass; five-target CI and live Habit account sync remain open. |
| SC-007 | Pending human validation. No participants are currently available. Participant count: 0; success rate: not measured. |

## Three-minute comprehension check (SC-007)

Give each participant an unassisted fresh preview account. Start a three-minute timer and ask them to create a due-today Habit, complete it, and identify the displayed streak. Record participant count, number completing all three actions correctly within the limit, success rate, and repeated confusion. Pass only if at least 90% succeed. Automated widget tests do not substitute for this check.

## Release boundary

Do not mark 004 complete until the final CI gate, live authenticated Habit device sync evidence, and SC-007 are satisfied. Public account-based release also depends on the later Auth feature and successful initial account synchronization. Saving a reminder time is implemented; device notification permission, scheduling and delivery belong to the later Notifications feature.
