# Platform Validation Record: Namaa Foundation

**Feature**: [001-namaa-foundation](spec.md) | **Created**: 2026-09-03 |
**Updated**: 2026-09-05 (Supabase direction, Constitution v2.0.0)

This record proves or disproves target capability for Android, iOS, Windows, macOS, and Linux
before production lock-in (Constitution III; research decision 5). A failed adapter capability
blocks production lock-in but does not alter Domain/Application contracts.

Status legend: PASS (verified with evidence), PENDING (not yet executed in this environment),
FAIL (verified unsupported/broken with evidence).

## Package Compatibility Record (T001/T008)

Versions resolved by `flutter pub get` on 2026-09-05 (Flutter 3.41.8 / Dart 3.11.5, Windows
development host) after replacing Firebase with Supabase (T001). "Declared platforms" are read
from each resolved package's `pubspec.yaml`.

| Package | Resolved | Declared Flutter platforms | Notes |
|---|---|---|---|
| flutter_bloc 9.1.1 | ^9.1.1 | all (pure Dart) | Presentation state pattern. |
| get_it 9.2.1 / injectable 3.0.0 | ^9.2.1 / ^3.0.0 | all (pure Dart) | Composition root. |
| go_router 17.5.0 | ^17.5.0 | all | Routing. |
| drift 2.34.4 / drift_flutter 0.3.1 | ^2.34.4 / ^0.3.1 | all (Dart build hooks) | drift_flutter bundles sqlite3 via hooks on Android, iOS, macOS, Linux, Windows. |
| sqlite3 3.x (transitive) | via drift_flutter | Android, iOS, macOS, Linux, Windows | Encryption selected through build hooks `source: sqlite3mc` (SQLite3MultipleCiphers, MIT, SQLCipher-compatible `PRAGMA key`). `sqlcipher_flutter_libs`/`sqlite3_flutter_libs` 0.7.0+eol are retired no-op stubs and are NOT used. |
| supabase_flutter 2.17.2 | ^2.17.2 | android, ios, macos, web, windows, **linux** | Declares all five required targets (plus web). Linux Auth/Data API/session/sync transport remains a mandatory empirical proof before production lock-in (research decision 5); "declared" is not "verified". |
| flutter_secure_storage 11.0.0 | ^11.0.0 | android, ios, macos, linux, windows, web | Full five-target coverage via federated platform packages. |
| flutter_localizations / intl | sdk / ^0.20.2 | all | ARB/gen_l10n localization. |
| freezed 3.2.5 / json_serializable 6.14.1 | dev | all (pure Dart codegen) | Immutable value types and payload serialization. |
| bloc_test 10.0.0 / build_runner 2.15.1 / drift_dev 2.34.0 / injectable_generator 3.0.2 | dev | all | Test and build tooling. |

Key T001/T008 findings:

1. `flutter pub get` succeeds with the Foundation dependency set after replacing
   `cloud_firestore`/`firebase_auth`/`firebase_core` with `supabase_flutter ^2.17.2` (T001).
2. `supabase_flutter` declares Android, iOS, macOS, Windows, and Linux plugins. Unlike the
   retired Firebase direction, Linux is declared; the Linux end-to-end proof (Auth, Data API,
   session, sync transport) is still a required production-lock-in gate, not an assumed
   capability.
3. SQLite encryption is provided by the `sqlite3` build-hook system (not by the retired
   `sqlcipher_flutter_libs`), which bundles precompiled SQLite3MultipleCiphers binaries for every
   Dart-supported OS, including Linux.

## Dependency Resolution and Static Analysis (T008)

| Check | Command | Result | Date |
|---|---|---|---|
| Dependency resolution (Supabase set) | `flutter pub get` | PASS | 2026-09-05 |
| Static analysis | `flutter analyze` | PASS (0 issues) | 2026-09-05 |
| Localization generation | `flutter gen-l10n` | PASS (ar/en generated) | 2026-09-05 |
| Starter test entry point | `flutter test` | PASS (1 test) | 2026-09-05 |
| Native Windows compile of dependency set | `flutter build windows --debug` | PENDING — no Visual Studio toolchain on this host (`flutter doctor`: Visual Studio ✗, Android toolchain ✓). Command to re-run on a VS-equipped host recorded below. | 2026-09-05 |

## Target Capability Matrix

For each target: clean launch; encrypted database open/restart; protected-vault
read/write/delete; Supabase initialization; local-stack connection; non-production device
integration; offline operation followed by reconnect retry.

### Android

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | Deferred to US2/US3 root-route validation |
| Encrypted database open/restart | PASS | `integration_test/foundation_offline_test.dart` passes across 10 consecutive offline restarts on Android (2026-09-07) |
| Credential vault read/write/delete | PASS | Proven in host unit suite and in integration tests on Android via `SecureCredentialVault` (2026-09-07) |
| Supabase initialization | PASS | `integration_test/foundation_supabase_test.dart` passes on Android (2026-09-07) |
| Local stack connectivity | PASS | Loopback local stack URL boundary confirmed on Android; RLS isolation verified via `npx supabase test db` (2026-09-07) |
| Non-production device integration | PASS | Automated tests reject production configuration and resolve non-production environments on Android (2026-09-07) |
| Offline commit + reconnect retry | PASS | `integration_test/foundation_sync_test.dart` passes retry and conflict retention on Android (2026-09-07) |


### iOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Supabase initialization | PENDING | |
| Local stack connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### Windows

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Supabase initialization | PENDING | |
| Local stack connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### macOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Supabase initialization | PENDING | |
| Local stack connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### Linux

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Supabase initialization | PENDING (declared) | supabase_flutter 2.17.2 declares a Linux plugin; end-to-end Auth/Data API/session/sync proof still required. |
| Local stack connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

## Environment Constraints of This Implementation Run

- Implementation host: Windows 10 development machine with Flutter 3.41.8 stable; Android
  SDK 36 toolchain and Chrome available; **no Visual Studio toolchain**, so native Windows
  compilation cannot be exercised here. Re-run on a VS-equipped host with:
  `flutter build windows --debug` (validates sqlite3mc hook binaries and the supabase_flutter
  Windows plugin compiling together).
- Host-verifiable checks (`flutter analyze`, `flutter test` unit/widget/architecture suites with
  the hooks-bundled encrypted SQLite and test doubles, `flutter gen-l10n`) are executed and
  recorded here.
- Checks requiring physical/emulated targets (Android/iOS devices, macOS/Linux builds), a running
  local Supabase Docker stack, or an isolated non-production Supabase project are recorded as
  PENDING with the exact command to run, because this environment cannot execute them now.
  PENDING is not PASS; production lock-in stays blocked until each cell is verified
  (Constitution III).

## US1 Implementation Evidence (T029–T039, recorded 2026-09-06)

Implemented adapters and infrastructure (all on the Windows host, Flutter 3.41.8):

- **T029** `lib/core/platform/secure_credential_vault.dart` — Credential Vault over
  `flutter_secure_storage` via an injectable `SecureKeyValueStore`; failure summaries are fixed and
  secret-free (proven by a leaking-store test). Unit-tested on host.
- **T030** `lib/core/data/local/foundation_database.dart` — encrypted Drift database
  (`sqlite3mc` via build hooks, `PRAGMA key` raw hex key), Foundation tables, automatic migration
  journal (started/completed/failed/recovered) with post-mortem `failed` rows written through a raw
  sqlite3 connection, and a subsequent clean upgrade marking the attempt `recovered`. Unit-tested
  on host: wrong-key rejection, upgrade data preservation, injected-failure retention.
- **T031** `lib/core/data/local/drift_local_store.dart` — atomic local-record/outbox commit,
  pending-only reads, terminal acknowledgement, recoverable-failure persistence, conflict records.
  Unit-tested on host.
- **T032** `lib/core/data/cloud/supabase/supabase_environment.dart` + `supabase_client_factory.dart`
  — publishable-key-only validation (rejects `sb_secret_`, `service_role` literal and
  base64-encoded JWT role claims), loopback-only local stack, injected non-production URL/key.
  Unit-tested on host.
- **T033** `lib/core/data/cloud/supabase/supabase_session_adapter.dart` +
  `supabase_sync_adapter.dart` — session snapshots without SDK types; idempotent dispatch via
  remote `operation_id`, remote-newer conflict detection. Written; SDK-level behavior requires a
  running stack (PENDING below).
- **T034** `supabase/migrations/0001_foundation_probe.sql` — probe table, RLS enabled, least-
  privilege grants (anon: none; authenticated: 4 row ops), owner policies bound to `auth.uid()`;
  caller-supplied owner values rejected by `with check`. Written.
- **T035** `lib/core/data/sync/synchronization_coordinator.dart` — durable outbox engine behind
  `PendingSynchronizationEngine` (core/application); terminal acks, same-ID retries, conflict
  retention, equal-timestamp recovery. Unit-tested on host.
- **T036** `lib/core/data/sync/synchronization_runner.dart` — connectivity-triggered retry
  orchestration. **T037** composition now wires real adapters for `test`/`local`/`nonProduction`
  (safe-fail doubles remain for `unconfigured`). **T038** `SynchronizationCubit` maps pass outcomes
  to localized status states; unit-tested on host.

Host verification (2026-09-06): `flutter analyze` PASS (0 issues); `flutter test` PASS (67/67,
including 21 new US1 unit tests); `dart format` clean; drift codegen via `build_runner` with
`store_date_time_values_as_text` build option.

### US1 Validation Execution (T039, executed 2026-09-07)

The local Supabase Docker stack was started and verified. User Story 1 automated validation commands from `quickstart.md` were executed and passed without contacting production:

1. **Static Analysis**: `flutter analyze` — PASS (0 issues found).
2. **Unit, Widget, and Architecture Tests (T019–T023)**: `flutter test` — PASS (67/67 passed).
3. **Database Authorization and RLS (T024)**: `npx supabase test db` — PASS (8/8 tests passed in `supabase/tests/foundation_account_isolation_test.sql`, proving owner account allowed and different account denied for read/write/delete operations).
4. **Target Device Integration Tests (T025–T028)**: `flutter test integration_test` — PASS on Android target (7/7 tests passed):
   - `foundation_offline_test.dart` (T025): Survives 10 consecutive offline restarts with encrypted database.
   - `foundation_sync_test.dart` (T026): Reconnect/retry with idempotent operation ID and version conflict retention.
   - `foundation_migration_test.dart` (T027): Encrypted database migration data preservation and failed migration journal recovery.
   - `foundation_supabase_test.dart` (T028): Local Supabase stack URL boundary and rejection of production configuration.

Checkpoint achieved: All User Story 1 tasks (T019–T039) are complete and validated against the local stack.

## US2 Localization Validation (T040–T048, executed 2026-10-04)

- `flutter gen-l10n` generated the Foundation Arabic and English localization output from the
  version-controlled ARB resources.
- `flutter analyze` passed with zero issues.
- `flutter test` passed with 107 tests, including the locale preference, LocaleCubit, and root
  directionality suites.
- `flutter test -d windows test/widget/app/localization_and_directionality_test.dart` passed all
  five cases: Arabic RTL text, English LTR text, the Thmanyah Sans root font, live locale switching,
  and restoration after an application restart.
- `flutter test -d emulator-5554 test/widget/app/localization_and_directionality_test.dart` passed
  the same five cases on an Android 17 (API 37) emulator.

### T048 Platform Evidence — PASS

T040–T042 pass on both a mobile target (Android) and a desktop target (Windows). T048 is complete.

## US3 Routing, Theme, and Platform Validation (T049–T059, executed 2026-10-05)

- `flutter analyze` — PASS (zero issues).
- `flutter test --no-pub --reporter compact` — PASS (119 tests), including T049–T052 and
  capability-reporting failure coverage.
- `flutter test -d windows --no-pub --reporter expanded integration_test/foundation_platform_test.dart`
  — PASS (2/2).
- `flutter test -d emulator-5554 --no-pub --reporter expanded integration_test/foundation_platform_test.dart`
  — PASS (2/2).

The same integration test on Windows and Android verifies the registered root launch, handled
unknown-route boundary, light/dark/system appearance selection, encrypted local-store open/read,
OS-protected credential-vault read/write/delete, publishable-key-only Supabase initialization, and
offline-to-online connectivity transitions. Capability availability is derived from executable
adapter probes; a failed or absent probe is reported unavailable. No product-domain route or
platform-specific business rule was added.

### T059 Platform Evidence — PASS

T049–T053 pass on both a mobile target (Android) and a desktop target (Windows). T059 is complete.
