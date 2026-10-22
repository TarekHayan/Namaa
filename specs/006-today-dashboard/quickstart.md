# Quickstart Validation: Dashboard / Today 006

This guide applies **after implementation**. Planning documents alone do not add Today or the planned tests. Expected behavior is in spec.md, data-model.md and contracts/. No tests, devices or CI results are claimed by this planning step.

## 1. Prerequisites

Use the repository Flutter toolchain (CI pins Flutter 3.41.8) and current dependencies. Run commands from the repository root. Do not upgrade packages, reset the encrypted database or recreate preview data just to validate Today.

~~~powershell
flutter pub get
flutter gen-l10n
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test
~~~

During implementation, test the changed area first. These planned paths become runnable once their corresponding implementation/tests exist:

~~~powershell
flutter test --no-pub test/unit/features/today
flutter test --no-pub test/unit/features/tasks/application/task_completion_service_test.dart test/unit/features/habits/application/habit_commands_test.dart
flutter test --no-pub test/architecture
flutter test --no-pub test/widget/features/today
flutter test --no-pub test/widget/app
~~~

Owner repository/transaction and composition tests must also run when those implementations change. Use existing suites and add meaningful race cases; do not repeatedly rerun all devices after each small commit.

No SQL migration is planned for 006. Existing local security regressions may be checked when the integration gate requires them:

~~~powershell
supabase start
supabase test db
~~~

Automated Supabase checks use the local stack. Device synchronization verification uses an isolated nonproduction project and existing test-session facilities, never production data or an Auth UI feature.

## 2. Direct local preview

~~~powershell
flutter devices
flutter run -d windows --dart-define=NAMAA_TASKS_PREVIEW=true
~~~

Use an available Android/iOS device ID or macos/linux on its host for other targets. Debug currently defaults to preview; the explicit flag makes the run's intent clear. Preview must remain disabled for release builds.

Expected: Foundation initializes, then Today opens directly without login. Tasks, Habits, Maps and language/appearance controls remain reachable. Previously saved Tasks/Maps/XP preview records and Habits preview records remain visible under their existing separate owner IDs; no copying/deletion is necessary.

Switch language and theme, navigate out and back, restart offline. None of these read/navigation actions creates a business or pending record.

## 3. Correctness fixture (SC-001)

Use existing owner forms for a manual sample and deterministic owner fixtures in tests for exact counts. Never add a production Today seed command/store.

Prepare:

- Ten nondeleted Tasks scheduled today, four completed; yesterday/future Tasks and deleted Tasks as exclusions.
- Timed Tasks with distinct times, equal times and overlapping estimates; untimed Tasks.
- Incomplete urgentImportant Tasks today, in the past, future-only, and future-scheduled with an expired deadline; another urgentNotImportant Task.
- Five eligible Habits, two completed. Include a completion earned while due then remove today's weekday; include an unscheduled Habit without completion and a deleted Habit as exclusions.
- A Task linked from two map nodes; an award earned yesterday followed by reopen/recompletion today; an award earned today for a subsequently deleted Task.

Verify:

| Check | Expected |
|---|---|
| Progress | Tasks 4/10 =40%; Habits 2/5 =40%; two independent summaries and no combined score. |
| Task denominator | Includes completed scheduled-today Tasks; excludes other dates and tombstones. |
| Habits | Owner streaks match; retained earned completion remains eligible after schedule edit. |
| Agenda | Each scheduled-today Task once; timed ascending, equal-time owner order; untimed separate, no invented time. |
| Do First | At most three incomplete urgentImportant Tasks, today OR owner-overdue, canonical relative order. |
| Future exception | Future-only excluded; expired-deadline future Task may qualify as overdue without entering today's denominator. |
| Overdue | Same count/identities as owner overdue view; elapsed saved time/duration today alone has no effect. |
| XP | Actual award instants in local day only; deletion preserves award, recompletion adds none. |
| Map link | Task count/state unaffected by number of map links. |
| Empty | Successful zero-item sources explain no items; no 100%/invalid ratio; XP zero only when ledger confirmed. |

Repeat with Arabic/English formatting. Test exact midnight award inclusion/exclusion and a date-boundary daylight-saving fixture using the injected calendar, not a fixed 24-hour interval.

## 4. Actions, cancellation and owner authority (SC-003)

Create a Task and Habit from Today quick actions using existing owner editors. Confirm the new Task defaults to the current date, cancellation creates nothing and rebuild does not reopen the editor.

Within one local date, run ten offline journeys across completion/reopen and Habit complete/undo. Check owner screens and linked Maps after each relevant save. Restart offline, then reconnect through existing sync:

- Same canonical records and completion states.
- One lifetime Task award; no Habit award.
- Undo of an unscheduled retained Habit completion removes it from Today and does not offer a new completion until due.
- Local failure preserves latest confirmed state with localized recovery.
- Rapid taps have one in-flight desired-state action per item; no duplicate award/day/outbox effects.
- Ten read-only Today refreshes produce zero new business/pending rows.

Focused race tests delay the owner read/session check, then cross midnight, change identity, delete/reschedule a Task or edit/delete a Habit. The rejected operation writes nothing and cannot overwrite a newer record or resurrect a deleted item. Existing all-date Tasks/Maps completion still works.

## 5. Clock, isolation and recovery (SC-004, SC-005)

Use deterministic clock/source fakes for repeatable automated cases; use device resume/clock scenarios for platform evidence.

1. Keep Today foreground across midnight: correct date/items within one minute, old history intact.
2. Resume after midnight or timezone/offset change: current projection within two seconds; stale-day Habit save rejected, no silent retargeting.
3. Let a Task deadline pass without modifying its row: owner-overdue projection updates; agenda duration does not imply activity.
4. Fail or never emit Tasks, either Habit constituent, or XP separately: visible retry within ten seconds, other sections usable, no false zeros.
5. After prior success, fail a source: same-day retained values explicitly outdated and unsafe actions disabled. Restore confirmed local data: correct projection within two seconds.
6. Retry repeatedly and deliver old attempt callbacks: no stale overwrite, duplicate listeners or uncontrolled retries.
7. Switch account A -> B -> preview -> unresolved/signed-out account mode, with delayed initial lookup/events/action results: zero foreign rows/counts/XP/feedback in all captured states.
8. Return to a healthy quiet stream: no inactivity timeout merely because no records changed.

The root session/initialization recovery must not become another permanent loading loop.

## 6. Performance and accessible journeys (SC-002, SC-006)

Prepare the scale fixture with **500 locally available Tasks, 100 Habits and 200 actual award rows** through test owner fixtures. Measure on one mobile and one desktop:

- Time from available local root readiness to confirmed Today display <=2 seconds.
- Time from a supported local action to visible confirmed result <=2 seconds.
- Local owner changes/inbound arrivals visible <=2 seconds without manual restart.
- No network wait on the critical path.

Record device/OS, build mode, fixture counts, timing start/end definition and observed timings. Do not substitute a small fixture or a single machine's result for both target classes.

Run Arabic and English primary flows on mobile and desktop, including narrow layout, long/mixed titles, increased text scale, semantics and visible focus. Script a touch journey and keyboard-only journey: open Today, identify both ratios, complete a Task and Habit, visit owners and return. Each completes within three minutes using labeled controls. No external participant recruitment is required.

## 7. Integration and two-device synchronization (SC-007)

Planned local journey:

~~~powershell
flutter test --no-pub -d windows integration_test/today_dashboard_test.dart
~~~

Run equivalent commands on available Android/iOS/macOS/Linux hosts using the existing harness. iOS CI must keep its verified XCTest signing/runner path; do not replace it with an unverified runner while adding Today.

For isolated device synchronization, prepare a local ignored `.env.today.json` using the existing test configuration keys: NAMAA_SUPABASE_URL, NAMAA_SUPABASE_PUBLISHABLE_KEY and NAMAA_STAGING_TEST_USER_A/B_EMAIL/PASSWORD. Use isolated test accounts only; keep passwords out of logs, code, artifacts and commits. This is test harness session setup, not public registration/login.

~~~powershell
flutter test --no-pub -d windows integration_test/today_sync_test.dart --dart-define-from-file=.env.today.json
~~~

The implemented suite must use the existing protected isolated-project configuration and clean up only its own fixture IDs. Do not log the populated defines file. Automated server/RLS regressions remain on the local Supabase stack.

Verify on two device sessions for the same account:

- Same local date: offline actions then synchronization converge once in Today, Tasks, Habits and actual awards; linked Tasks are not duplicated.
- Different local dates/time zones: each device shows its own date-specific projection; stored calendar records and award instants remain unchanged.
- Another account and preview cannot see these records.
- Cloud failure leaves confirmed local data usable and does not create a second Today sync process.

A mocked stream test alone does not satisfy the two-device criterion.

## 8. Evidence and integration gate

During implementation create/update verification.md with actual command/run, commit SHA, target/device/OS, fixture, measured result and remaining limitation for each SC-001..SC-007. Until executed, criteria remain unverified; do not mark them complete from design text.

Register the compact Today suites in existing platform runners and workflow path filters. Keep no push trigger; use affected tests during development and the full required gate before merge to develop. A focused/mobile-only diagnostic run is not the final merge gate. Reuse successes on the same SHA when retrying genuinely failed/cancelled jobs; inspect logs before code changes.
