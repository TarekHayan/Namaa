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
   supabase start
   ~~~

4. For Android device or emulator tests, forward the local Supabase API port through ADB so
   `127.0.0.1:54321` on the device reaches the local stack on the development host. Substitute
   the target's actual device ID; if this host uses a non-default ADB server port, set
   `ANDROID_ADB_SERVER_PORT` before this command and the Flutter test command.

   ~~~powershell
   $adbPath = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
   & $adbPath -s '<device-id>' reverse tcp:54321 tcp:54321
   ~~~

## Automated Validation

~~~powershell
flutter analyze
flutter test
$statusLines = supabase status -o env
$publishableLine = $statusLines | Where-Object { $_ -match '^PUBLISHABLE_KEY=' } | Select-Object -First 1
if (-not $publishableLine) { throw 'The local Supabase publishable key is unavailable.' }
$localPublishableKey = ($publishableLine -replace '^PUBLISHABLE_KEY=', '').Trim()
flutter test --dart-define="NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=$localPublishableKey" integration_test
Remove-Variable localPublishableKey,publishableLine,statusLines
supabase test db
~~~

Select a target with Flutter's `-d <device-id>` option when more than one device is available.
The publishable key above comes from the local stack only; do not print it, save it to a file, or
substitute a hosted project's key.

On Windows, run the integration entry points one at a time if the installed Flutter test runner
stops its debug log reader while launching multiple desktop executables in one invocation:

~~~powershell
$statusLines = supabase status -o env
$publishableLine = $statusLines | Where-Object { $_ -match '^PUBLISHABLE_KEY=' } | Select-Object -First 1
if (-not $publishableLine) { throw 'The local Supabase publishable key is unavailable.' }
$localPublishableKey = ($publishableLine -replace '^PUBLISHABLE_KEY=', '').Trim()
Get-ChildItem integration_test -Filter '*_test.dart' | Sort-Object Name | ForEach-Object {
  flutter test --dart-define="NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=$localPublishableKey" -d windows $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "Integration test failed: $($_.Name)" }
}
Remove-Variable localPublishableKey,publishableLine,statusLines
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
