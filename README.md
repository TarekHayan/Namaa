# namma_project

A new Flutter project.

## Try Tasks without an account

Run `flutter run` in debug mode, then open **Tasks** from the first screen.
The trial uses a separate local identity and keeps tasks in the encrypted
device database. It does not connect to Supabase or synchronize trial data.
Release builds keep the normal account boundary. To exercise that boundary in
a debug run, pass `--dart-define=NAMAA_TASKS_PREVIEW=false`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
