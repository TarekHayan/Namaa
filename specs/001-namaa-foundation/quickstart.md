# Foundation Validation Quickstart

This guide validates Foundation after implementation. It does not implement product domains. See
[data-model.md](data-model.md) and [contracts](contracts/) for the planned behavior.

## Prerequisites

- Flutter and Dart compatible with the project SDK constraint.
- Android development environment or emulator; Apple development environment/device or simulator;
  Windows and Linux desktop development environments.
- Supabase CLI and a Docker-compatible runtime for the local Supabase stack and automated tests.
- Access to the isolated non-production Supabase project for device integration.
- OS-protected storage capability available to the selected credential-vault adapter on each target.

## Setup

1. Obtain dependencies:

   ~~~powershell
   flutter pub get
   ~~~

2. Generate declared source artifacts after implementation:

   ~~~powershell
   dart run build_runner build --delete-conflicting-outputs
   ~~~

3. Start the local Supabase stack using the version-controlled Supabase configuration. Automated
   tests must not point to a production Supabase project.

   ~~~powershell
   npx supabase start
   ~~~

## Automated Validation

~~~powershell
flutter analyze
flutter test
flutter test integration_test
npx supabase test db
~~~

The completed suites demonstrate:

- Domain has no direct Flutter, Supabase, Drift, routing, notification, or platform-adapter imports.
- Locale, theme, routing, and recoverable-failure Cubits resolve from composition.
- Arabic is RTL; English is LTR; light, dark, system appearance works.
- Account database data is encrypted; credentials are absent from general preferences.
- A local write persists over ten offline restarts.
- An offline change retries after reconnect with no duplicate logical effect.
- Timestamp conflict retains both versions and selects newest as active.
- Migration preserves data or yields recoverable failure with prior state retained.
- Supabase tests use the local stack only, deny cross-account access through RLS, and do not ship
  secret or service-role keys.

## Target Validation

Run root-route startup, persistence, localization, theme, and synchronization-boundary tests on:

~~~text
Android | iOS | Windows | macOS | Linux
~~~

For each target, record clean launch; encrypted database open/restart; protected-vault
read/write/delete; Supabase initialization, local-stack connection, and non-production device
integration; and an offline operation followed by reconnect retry.

A failed adapter capability on any target blocks production lock-in. Fix it at the infrastructure
boundary without duplicating Domain/Application business rules.

## Expected Result

All validation passes; all five targets meet recorded checks; no automated test contacts production
Supabase; and no product-domain screen or behavior has been added.
