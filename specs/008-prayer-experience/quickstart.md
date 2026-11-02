# Quickstart validation: Prayer Experience

These are post-implementation commands/scenarios. Planned Prayer files, suite mappings and schema do not exist merely because this guide names them. Run from the repository root. No tests or cloud changes are performed by planning.

## Prerequisites and setup

- Flutter3.41.8/Dart compatible with ^3.11.5; platform toolchains for Android/iOS/Windows/macOS/Linux.
- Dependency adoption records exact adhan_dart2.0.1, timezone0.11.2, uuid4.6.0 and Dio5.11.1 versions/licenses plus solar preflight/reference evidence.
- Docker/Supabase CLI for isolated automated SQL/cloud tests. Never reset a production/linked project as a local-test shortcut.
- Real-device account synchronization uses the existing isolated non-production project/test users through protected configuration; no service-role secret in app/test logs.
- Debug/profile preview is local and public-login-free. First city search needs internet; saved-city schedules do not.
- Commercial search uses a configured licensed gateway; see contracts/prayer-ui-city.md. Do not commit keys or put a paid provider key in dart-defines.

After implementation:

~~~powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
~~~

Review dependency resolution/lockfile and generated changes; package metadata is not proof of native-target verification.

## Local focused checks

Planned directories/files must be created by implementation before these commands are used:

~~~powershell
flutter test test/unit/features/prayer test/widget/features/prayer test/architecture/prayer_boundaries_test.dart
flutter test test/unit/core/data/local/prayer_migration_test.dart
flutter test test/unit/features/xp test/widget/features/today test/widget/app
~~~

Run targeted affected XP/Task/composition tests if renamed/shared types touch their callers. Do not repeat unrelated successful device suites for formatting-only or documentation-only commits.

On Windows Flutter may need SDK-cache write access outside the workspace; do not interpret a launcher waiting on its cache lock as a failed app test.

## Local database and security

~~~powershell
supabase start
supabase migration up --local
supabase test db
~~~

Expected: migration0015 applied locally; anon/foreign-owner denial; native typed RPC; stable UUID vectors; no ordinary-edit false conflict; equal-time conflict retained visibly; first10/5 once-only award; invalid operation reuse rejected; losing completion followed by reset still awards once.

Real historical v1…v7→v9 and installed v8→v9 fixtures must preserve existing records, base_updated_at, counters/maps/links/XP/conflicts and remove physical unused completion_xp only when present. The v9 cache must be created without changing Prayer reports. Include failed-upgrade rollback/journal recovery. A new database opened with a lower version argument is insufficient migration evidence.

## Open the feature preview

~~~powershell
flutter run -d windows --dart-define=NAMAA_TASKS_PREVIEW=true --dart-define=NAMAA_DEVICE_PREVIEW=false
~~~

Use flutter devices to select an Android/iOS target. Profile performance builds retain preview only with the explicit preview define; release never bypasses the real session boundary.

1. Open Track→Prayer, Home prayer card/hub, desktop direct Prayer entry. No sign-up prompt in development preview.
2. With no saved location, open Prayer and grant the foreground location request. Verify the measured coordinates and zone appear, and that the timetable identifies AlAdhan or the local fallback. If permission is denied or the fix is unavailable, verify the manual city option remains usable.
3. Test the manual fallback by searching Cairo in Arabic and English; confirm country/admin, coordinates/zone validity, method and attribution. Cancel another search: prior choice persists. Returning to a manually chosen city must not silently replace it with the device location.
4. Inspect all four ordered groups, the five cards, separate information cards and reviewed guidance. Streak/other religious features say coming soon.
5. Mark one prayer on time and another late; progress2/5 and local first awards10+5. Correct/reset them: counts follow state; awarded points stay fixed.
6. Restart offline and advance the injected date through seven days. New schedules calculate from saved city; old records stay attached to their dates, never auto-missed.
7. Try new-city search offline, throttled, no results and malformed zone fixtures. Existing city/report operations remain available.
8. Change device city/method, resume after midnight/DST and test after-Isha next-day context. Home and Prayer agree while Task/Habit calendar remains device-local.

## Focused device tests

After native feature tests are implemented:

~~~powershell
flutter test -d windows integration_test/prayer_schedule_test.dart
flutter test -d windows integration_test/prayer_reports_test.dart
flutter test -d windows integration_test/prayer_offline_sync_test.dart
flutter test -d windows integration_test/prayer_localized_route_test.dart
~~~

Run affected files individually on Android/macOS/Linux. iOS uses the existing XCTest group runner, not a replacement ad-hoc driver; add a prayer group and four suite names to both group/suite mappings and validate their runner tests. Desktop/local SQL integration must use the local Supabase stack; isolated staging device evidence remains a release gate.

Add prayer as Android suite and iOS group during implementation. Only then is this focused CI command valid:

~~~powershell
gh workflow run foundation-ci.yml --ref namaa/008-prayer-experience -f mobile_only=true -f android_suites='["prayer"]' -f ios_groups='["prayer"]'
~~~

A mobile_only run never satisfies the complete merge gate. Keep the current PR-to-develop/manual policy; no ordinary feature-push trigger is added. Full quality/database plus five-target/group gate is run before merge on the exact final head. Re-run only failed infrastructure jobs on the same head when appropriate; read logs before changing application code.

## Required evidence by success criterion

| Criterion | Evidence |
| --- | --- |
| SC-001 | Timestamped scripted phone touch and desktop keyboard city→five-times→Home journey≤60s; no human recruitment threshold added. |
| SC-002 | Versioned reference fixture matrix: Cairo/Dubai/NewYork,7methods,seasons,DST,zero coordinate,polar case; five times/sunrise≤1min; separate night formula proof. Record raw reference metadata and normalization; do not invent numbers or relax tolerances. |
| SC-003 | Full status matrix; pending after elapsed time/midnight; retained old days; complete/reset offline restart. |
| SC-004 | Two-device same-account independent/differing reports,10replays,lost ACK/equal tie,first5vs10 settlement and fresh-device conflict visibility. |
| SC-005 | Arabic/English × light/dark ×100%/150% at320/390/430/768/1200; readable text/actions, touch/focus/semantics and no horizontal page overflow. |
| SC-006 | Named phone and desktop, device/OS/build mode/data size; offline readable≤2s/status≤1s;18,300-report fixture; seven dates/resume/DST. Record actual elapsed measurements, not a simulated width as a physical phone. |
| SC-007 | Separate-city devices and differing civil dates; Home/Prayer agree per device; no city overwrite or unlabelled sample fallback; shared XP and old productivity owners unchanged. |
| SC-008 | Captured four-group prototype comparison, source-guidance review and exact justified adaptations; final audit signed off in feature verification. |

For a physical Android profile measurement use the existing integration driver and implemented benchmark entry:

~~~powershell
flutter drive --profile -d YOUR_PHONE_ID --driver=test_driver/integration_test.dart --target=integration_test/prayer_schedule_test.dart --dart-define=NAMAA_TASKS_PREVIEW=true --dart-define=NAMAA_DEVICE_PREVIEW=false
~~~

Replace YOUR_PHONE_ID with a connected device ID. A debug emulator result can validate functionality but must not be relabelled as a physical-phone profile result.

## Offline/concurrency sequence

- DeviceA Cairo; deviceB NewYork. Changing A does not alter B. Reports remain owner/date/prayer identities, even when current local dates differ.
- A completes Fajr late offline then resets; B reports the same identity on time offline. Synchronize repeatedly. One canonical first server award5or10 is retained, both report versions preserved when competing, final active status follows version rules, and no further correction produces XP.
- Edit different prayers and prove both survive. Repeat same request ID10times and deliberately reuse it with changed content (rejected).
- Drop ACK after server commit; restart and replay. Old receipt must not overwrite a newer local descendant.
- Make equal version timestamps with different statuses and reversed arrivals. SQL and Dart choose the same winner and conflict ID; a newly joined device downloads the retained evidence.
- Switch account during search/read/reconciliation. Old events cannot enter new owner's UI or storage.
Record implementation outcomes in verification.md when available, with failures left open. Planning artifacts are not a completion claim for008 or007's remaining audit.
