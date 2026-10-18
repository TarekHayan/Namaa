# Habits 004 Quickstart Validation

This is a run guide for validating the later implementation of 004. No Habit code or tests are created by the planning phase. Read spec.md, data-model.md, and contracts/ before evaluating results.

## Prerequisites

- Flutter/Dart matching the repository and a configured target device. The CI workflow pins Flutter 3.41.8.
- Dependencies resolved with flutter pub get.
- A local Supabase stack for automated database tests. Never point automated tests at production.
- For authenticated device checks, an isolated non-production Supabase project with two test accounts. The existing non-release local preview can exercise Habits before the separate Auth UI is available.

## Shared checks

From the repository root after implementation:

~~~text
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --no-pub
supabase start
supabase test db
~~~

Expected: analysis and tests pass; SQL tests prove owner-only access, replay-safe operations, and denial of direct client writes. A failed or unavailable local Supabase stack is an environment issue, not a passing database result.

## Local preview walk-through

On an available debug device, run the app using the existing preview boundary. For Windows:

~~~text
flutter run -d windows --dart-define=NAMAA_TASKS_PREVIEW=true
~~~

The preview remains disabled in release builds. Expected checks:

1. Open Habits, create a habit named Read with today and one other weekday selected, and another daily habit. A blank name or empty weekday selection is rejected in the current language.
2. On a due day, complete Read. Its state and streak update without waiting for network. Repeated taps do not create a second day.
3. Undo today's completion. Earlier completed dates remain visible but cannot be edited.
4. Edit weekdays so today becomes selected or unselected. Due state changes immediately. If completion was earned before removing today, it remains visible and in the streak; after undo, it cannot be re-completed while today is unselected.
5. Save a reminder time. The value is retained but clearly marked inactive; no notification permission or delivery is claimed.
6. Delete one Habit after confirmation. It and its history leave active views; the other Habit and Tasks remain unchanged.
7. Restart offline and verify the last confirmed state. Simulate a local save failure and verify a localized failure with prior state available.

## Automated feature scenarios

The later implementation should add focused tests covering:

| Area | Required proof |
|---|---|
| Domain | Selected-day streak, pending current day, missed closed day, same-day schedule edit, earned-while-due preservation, undo, multiple Habits, no XP. |
| Local migration | Encrypted v3→v4 upgrade retains Foundation/Task/XP data; injected failure preserves prior data and recoverable journal. |
| Local commands | Atomic Habit or HabitDay row + outbox, account isolation, duplicate date prevention, local save rollback. |
| Cloud SQL | RLS owner/other-account checks, no direct writes, receipt replay, same-date uniqueness, parent tombstone/day race, conflict loser retention. |
| Synchronization | Two devices complete different days offline; same date merges once; complete/undo conflict; full inbound pagination; account change mid-sync. |
| UI | Session-gated route, preview, create/edit/delete, inactive reminder, Arabic/English RTL, keyboard/focus, mobile/desktop layout. |

The planned integration entry points are integration_test/habits_offline_sync_test.dart, integration_test/habits_streak_history_test.dart, integration_test/habits_edit_delete_test.dart, and integration_test/habits_localized_route_test.dart. Once implemented, run each with flutter test --no-pub -d windows on a configured Windows host, or use the equivalent target in CI. The Android script discovers integration tests; add these entries explicitly to Linux, Windows, macOS, and the iOS matrix in .github/workflows/foundation-ci.yml. Add specs/004-habits/** and the feature branch to the workflow triggers so planning/code changes are gated.

## Release boundary

A passing local preview proves the Habit behavior, not public account onboarding. Public account-based release still requires the separately delivered Auth flow and successful initial account sync. Actual reminder delivery belongs to the later Notifications feature. Before release, require the existing aggregate CI gate to pass Android, iOS, Windows, macOS, Linux, quality, and local Supabase database security; authenticated device checks use only the isolated non-production project.

