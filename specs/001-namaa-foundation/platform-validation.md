# Platform Validation Record: Namaa Foundation

**Feature**: [001-namaa-foundation](spec.md) | **Created**: 2026-09-03 |
**Updated**: 2026-10-07 (five-target GitHub Actions and isolated non-production validation)

This record proves or disproves target capability for Android, iOS, Windows, macOS, and Linux
before production lock-in (Constitution III; research decision 5). A failed adapter capability
blocks production lock-in but does not alter Domain/Application contracts.

Status legend: PASS (verified with evidence), N/A (not required in that execution environment),
PENDING (required evidence has not been executed), FAIL (verified unsupported/broken with evidence).

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
| supabase_flutter 2.17.2 | ^2.17.2 | android, ios, macos, web, windows, **linux** | Declares all five required targets (plus web). Auth, Data API, session, and sync transport are verified against the isolated non-production project on every required target. |
| flutter_secure_storage 10.3.4 | ^10.3.1 | android, ios, macos, linux, windows, web | Full five-target coverage via federated platform packages; compatible with the Android SDK 36 project build. |
| flutter_localizations / intl | sdk / ^0.20.2 | all | ARB/gen_l10n localization. |
| freezed 3.2.5 / json_serializable 6.14.1 | dev | all (pure Dart codegen) | Immutable value types and payload serialization. |
| bloc_test 10.0.0 / build_runner 2.15.1 / drift_dev 2.34.0 / injectable_generator 3.0.2 | dev | all | Test and build tooling. |

Key T001/T008 findings:

1. `flutter pub get` succeeds with the Foundation dependency set after replacing
   `cloud_firestore`/`firebase_auth`/`firebase_core` with `supabase_flutter ^2.17.2` (T001).
2. `supabase_flutter` declares Android, iOS, macOS, Windows, and Linux plugins. The final CI run
   verifies initialization and isolated non-production Auth/Data API/session/sync transport on
   every required target, including Linux.
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
| Native Windows compile of dependency set | `flutter build windows --debug` | PASS — GitHub Actions Windows runner | 2026-10-05 |

## Target Capability Matrix

GitHub Actions run
[37548647271](https://github.com/TarekHayan/Namaa/actions/runs/37548647271) attempt 2 built and
exercised every required target with Flutter 3.41.8. Protected GitHub secrets supplied only the
isolated non-production endpoint, publishable key, and two test-account credentials.

### Android

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PASS | `foundation_platform_test.dart` passed on the Android emulator. |
| Encrypted database open/restart | PASS | Ten-restart offline and migration/recovery suites passed. |
| Credential vault read/write/delete | PASS | The real Android secure-storage adapter passed the platform probe. |
| Supabase initialization | PASS | The real client/session boundary initialized successfully. |
| Local stack connectivity | PASS | The local Data API request passed through ADB port forwarding; database/RLS tests passed separately. |
| Non-production device integration | PASS | Staging test authenticated two accounts, exercised Data API/session/sync, allowed owner access, denied cross-account read/write, and removed its temporary row. |
| Offline commit + reconnect retry | PASS | Retry/idempotency and conflict-retention integration suites passed. |

### iOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PASS | The iOS simulator platform matrix job passed. |
| Encrypted database open/restart | PASS | Separate migration and ten-restart offline simulator jobs passed. |
| Credential vault read/write/delete | PASS | The real iOS Keychain-backed adapter passed the platform probe. |
| Supabase initialization | PASS | The real client/session boundary initialized successfully. |
| Local stack connectivity | N/A | Automated schema/RLS tests ran against the local stack in the dedicated Linux job; Apple device transport used the approved isolated non-production project. |
| Non-production device integration | PASS | The iOS simulator authenticated two accounts and passed Data API/session/sync plus owner/cross-account isolation checks. |
| Offline commit + reconnect retry | PASS | Retry/idempotency and conflict-retention simulator job passed. |

### Windows

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PASS | Native Windows build and platform suite passed. |
| Encrypted database open/restart | PASS | Migration and ten-restart offline suites passed. |
| Credential vault read/write/delete | PASS | The real Windows protected-storage adapter passed the platform probe. |
| Supabase initialization | PASS | The real client/session boundary initialized successfully. |
| Local stack connectivity | PASS | Local Data API integration passed during the Phase 6 host validation. |
| Non-production device integration | PASS | Staging test authenticated two accounts, exercised Data API/session/sync, allowed owner access, denied cross-account read/write, and removed its temporary row. |
| Offline commit + reconnect retry | PASS | Retry/idempotency and conflict-retention integration suites passed. |

### macOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PASS | Native macOS build and platform suite passed. |
| Encrypted database open/restart | PASS | Migration and ten-restart offline suites passed. |
| Credential vault read/write/delete | PASS | The real macOS Keychain-backed adapter passed without a Keychain Sharing entitlement. |
| Supabase initialization | PASS | The real client/session boundary initialized successfully. |
| Local stack connectivity | N/A | Automated schema/RLS tests ran against the local stack in the dedicated Linux job; macOS device transport used the approved isolated non-production project. |
| Non-production device integration | PASS | Native macOS authenticated two accounts and passed Data API/session/sync plus owner/cross-account isolation checks after enabling outbound client networking. |
| Offline commit + reconnect retry | PASS | Retry/idempotency and conflict-retention integration suites passed. |

### Linux

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PASS | Native Linux build and platform suite passed under Xvfb. |
| Encrypted database open/restart | PASS | Migration and ten-restart offline suites passed. |
| Credential vault read/write/delete | PASS | The real Secret Service adapter passed with an isolated D-Bus/GNOME Keyring session. |
| Supabase initialization | PASS | The real client/session boundary initialized successfully. |
| Local stack connectivity | PASS | The local Supabase Data API request passed on the Linux runner. |
| Non-production device integration | PASS | Staging test authenticated two accounts, exercised Data API/session/sync, allowed owner access, denied cross-account read/write, and removed its temporary row. |
| Offline commit + reconnect retry | PASS | Retry/idempotency and conflict-retention integration suites passed. |

## Execution Environments and Evidence Boundary

- The five-target CI run also passed formatting, analysis, the shared test suite, and 12 local
  database/RLS checks.
- Android and Linux ran against a job-local Supabase stack. The Windows local Data API evidence
  comes from the Phase 6 host run. The dedicated database job proves the version-controlled schema,
  grants, and RLS against a local stack as required for automated Supabase testing.
- Android, iOS, Windows, macOS, and Linux each ran the same device integration test against the
  approved isolated non-production project. The test proves Auth, Data API, session, sync dispatch,
  owner access, cross-account read/write denial, and cleanup without exposing secret or service-role
  material. No production endpoint was contacted.

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
  remote `operation_id`, remote-newer conflict detection. Written and exercised through the
  local-stack validation and five-target isolated non-production device transport.
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
3. **Database Authorization and RLS (T024)**: `supabase test db` — PASS (8/8 tests passed in `supabase/tests/foundation_account_isolation_test.sql`, proving owner account allowed and different account denied for read/write/delete operations).
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

## Phase 6 Release-Gate Revalidation (2026-10-07)

| Required target | Platform/runtime status | Evidence / remaining cloud condition |
|---|---|---|
| Android | PASS | Complete integration suite passed against the local stack and isolated non-production Auth/Data API/session/sync test. |
| Windows | PASS | Native build, all integration entry points, local Data API evidence, and isolated non-production test passed. |
| iOS | PASS | Native simulator matrix and isolated non-production Auth/Data API/session/sync test passed. |
| macOS | PASS | Native build, all integration entry points, protected outbound networking, and isolated non-production test passed. |
| Linux | PASS | Native build, protected vault, local Data API transport, and isolated non-production test passed. |

The five-target Flutter/platform CI gate is complete and green. The shared unit, widget,
architecture, and security suites pass; the local database/RLS suite passes all 12 checks; and the
isolated non-production Auth/Data API/session/sync proof passes on every required target. T064 and
the Foundation production-lock-in verification gate are complete. No production endpoint or
server-side key was used.
