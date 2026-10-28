# namma_project

A new Flutter project.

## Try Tasks and Habits without an account

Run `flutter run` in debug mode, then open **Tasks** or **Habits** from the
first screen. Each trial uses a separate local identity and keeps its data in
the encrypted device database. It does not connect to Supabase or synchronize
trial data.
Release builds keep the normal account boundary. To exercise that boundary in
a debug run, pass `--dart-define=NAMAA_TASKS_PREVIEW=false`.

## Preview screen sizes

Run `flutter run` in debug mode. The Device Preview toolbar lets you switch
between phone, tablet, and desktop sizes, rotate the device, and change text
scale while using the app. It is off in release builds. To hide it during a
debug run, pass `--dart-define=NAMAA_DEVICE_PREVIEW=false`.

## Continuous integration

CI runs when a finished feature's pull request targets `develop`. Every run
is the full check: analysis, unit and widget tests, Supabase database and RLS
tests, Android, Linux, Windows, macOS, and five iOS simulator groups
(foundation, tasks, habits, mind-maps, today). The **Foundation and Task
five-target gate** passes only when all of them pass.

Before opening the pull request, run `flutter analyze` and `flutter test`
locally (about 6 minutes); they catch most problems without waiting for CI.

Each iOS group builds the app once and then runs every file in the group,
even after one fails, so a run lists all failing files at once. If a job
fails because of the runner (a lost connection or a stalled download), use
**Re-run failed jobs** on the run instead of rerunning everything. To rerun
one iOS file, run **Foundation CI** manually with `mobile_only` on,
`ios_groups` set (for example `["today"]`), and `ios_suites` set to the
file's suite name (for example `today-dashboard`).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
