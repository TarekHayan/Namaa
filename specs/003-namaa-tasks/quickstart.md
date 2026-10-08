# Tasks Quickstart: Validation Guide

This guide describes how to prove feature 003 after implementation. It does not claim the Task code or tests exist yet. Read data-model.md and contracts/ first. Use an isolated nonproduction Supabase project/local stack and two newly created test accounts; never use production credentials.

## Prerequisites

- Flutter/Dart toolchain and the platform SDK/toolchain for each chosen target; the existing Foundation five-platform CI supplies targets unavailable on one developer's host.
- Dependencies restored for the repository.
- Local Supabase CLI/stack for database policy tests; valid nonproduction configuration for device sync checks.
- A basic user-facing sign-in path supplied by the separate Auth prerequisite. Do not call Tasks release-ready without this and initial authenticated Task sync.

## Baseline commands

From the repository root, after Task implementation and generated code are added:

~~~powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
supabase start
supabase db reset
supabase test db
~~~

The app must start on Android, iOS, Windows, macOS, and Linux through their existing platform projects. Run target-specific integration tests on their native CI runners; local Windows alone does not establish macOS/Linux/iOS success. Reuse the Foundation five-target workflow gate and extend it for Task-specific checks.

## Scenario A: Local behavior and views

Sign in to account A and complete its initial sync. Offline, create a Task without changing defaults. Verify today's date, work, urgent/important, 30 minutes, stable ID, and immediate visible list/matrix state. Enter a blank title and confirm validation rejects it without a persisted row. Change date, time, deadline, category, quadrant, and duration; verify the same Task appears correctly in Today, Urgent, All, Completed, category, matrix, and overdue projections. An elapsed time today alone must not mark it overdue. Restart the app offline; the saved state must match.

## Scenario B: Checklist and completion integrity

Add, edit, check, uncheck, and remove several simple steps. Confirm no step has its own schedule/category/XP and no other Task changes. Complete every step: parent stays open and receives no XP. Reopen a step; explicitly complete the parent with that step incomplete. Parent completes, records completion time, and grants the first Task XP award. Verify it remains in All and moves to Completed/history while leaving Today/Urgent and matrix. Reopen parent and confirm completion time clears while award remains. Repeat complete/reopen/complete 10 times; exactly one Task award exists. Delete the Task and confirm its earned award remains.

## Scenario C: Offline, restart, and cross-device sync

On device A, make Task and checklist edits offline, restart offline, then reconnect. Repeat 10 trials with stable Task IDs and no duplicate awards. On device B signed in to the same account, complete initial sync and verify the changes. Edit and delete on one device and confirm the other device imports the new version and tombstone. Force a newer/older competing edit and confirm newest timestamp is active and the losing version remains visible. Force equal timestamps and confirm both versions remain recoverable without a fabricated winner. Verify a failed or retried outbound operation reuses its operation ID.

## Scenario D: Account isolation

Sign out of A and sign in to account B on the same device. B must not see A's local Task/checklist/award data. In Supabase policy tests, A can access own rows and callable operations; B cannot read or change A's Task, checklist payload, XP award, or operation receipt. Repeat after initial sync and reconnect. Use only isolated test credentials.

## Scenario E: Language, routing, and platform gate

Open Tasks from the registered route on one mobile and one desktop target in Arabic and English. Verify list/matrix, labels, validation, date presentation, and Arabic RTL remain usable. A signed-out route must lead to the separate sign-in path; after initial sync, local Task actions remain available offline. Run persistence and account-sync integration checks on Android, iOS, Windows, macOS, and Linux CI targets. Match spec success criteria SC-001 through SC-006 before release.

## Expected result

All checks pass; Foundation probe behavior and existing tests remain intact; no recurrence, Habits, Mind Maps, Today-domain feature, or Auth implementation is introduced under Tasks. The separate Auth prerequisite and five-target CI result are explicit release gates.
