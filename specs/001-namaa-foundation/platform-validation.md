# Platform Validation Record: Namaa Foundation

**Feature**: [001-namaa-foundation](spec.md) | **Created**: 2026-09-03

This record proves or disproves target capability for Android, iOS, Windows, macOS, and Linux
before production lock-in (Constitution III; research decision 5). A failed adapter capability
blocks production lock-in but does not alter Domain/Application contracts.

Status legend: PASS (verified with evidence), PENDING (not yet executed in this environment),
FAIL (verified unsupported/broken with evidence).

## Package Compatibility Record (T001/T008)

Versions resolved by `flutter pub get` on 2026-09-03 (Flutter 3.41.8 / Dart 3.11.5, Windows
development host). "Declared platforms" are read from each resolved package's `pubspec.yaml`.

| Package | Resolved | Declared Flutter platforms | Notes |
|---|---|---|---|
| flutter_bloc 9.1.1 | ^9.1.1 | all (pure Dart) | Presentation state pattern. |
| get_it 9.2.1 / injectable 3.0.0 | ^9.2.1 / ^3.0.0 | all (pure Dart) | Composition root. |
| go_router 17.5.0 | ^17.5.0 | all | Routing. |
| drift 2.34.4 / drift_flutter 0.3.1 | ^2.34.4 / ^0.3.1 | all (Dart build hooks) | drift_flutter bundles sqlite3 via hooks on Android, iOS, macOS, Linux, Windows. |
| sqlite3 3.5.2 (transitive) | via drift_flutter | Android, iOS, macOS, Linux, Windows | Encryption selected through build hooks `source: sqlite3mc` (SQLite3MultipleCiphers, MIT, SQLCipher-compatible `PRAGMA key`). `sqlcipher_flutter_libs`/`sqlite3_flutter_libs` 0.7.0+eol are retired no-op stubs and are NOT used. |
| firebase_core 4.14.0 | ^4.14.0 | android, ios, macos, web, **windows** (CAPI) | **No Linux plugin declared.** |
| firebase_auth 6.6.1 | ^6.6.1 | android, ios, macos, web, **windows** (CAPI) | **No Linux plugin declared.** |
| cloud_firestore 6.9.0 | ^6.9.0 | android, ios, macos, web, **windows** (CAPI) | **No Linux plugin declared.** |
| flutter_secure_storage 11.0.0 | ^11.0.0 | android, ios, macos, linux, windows, web | Full five-target coverage via federated platform packages. |
| flutter_localizations / intl | sdk / ^0.20.2 | all | ARB/gen_l10n localization. |
| freezed 3.2.5 / json_serializable 6.14.1 | dev | all (pure Dart codegen) | Immutable value types and payload serialization. |
| bloc_test 10.0.0 / build_runner 2.15.1 / drift_dev 2.34.0 / injectable_generator 3.0.2 | dev | all | Test and build tooling. |

Key T008 findings:

1. `flutter pub get` succeeds with the full Foundation dependency set.
2. Desktop Firebase (Windows) is declared by current FlutterFire CAPI plugins; Linux has **no
   Firebase plugin at all**. This is the anticipated research decision 5 risk: Linux cloud
   capability must come from a separately approved adapter or stay behind the Cloud Session /
   Cloud Sync ports, unimplemented on Linux, and Linux cloud sync stays PENDING/FAIL until then.
3. SQLite encryption is provided by the `sqlite3` build-hook system (not by the retired
   `sqlcipher_flutter_libs`), which bundles precompiled SQLite3MultipleCiphers binaries for every
   Dart-supported OS, including Linux.

## Dependency Resolution and Static Analysis (T008)

| Check | Command | Result | Date |
|---|---|---|---|
| Dependency resolution | `flutter pub get` | PASS | 2026-09-03 |
| Static analysis | `flutter analyze` | PASS (0 issues) | 2026-09-03 |
| Starter app remains buildable/testable | `flutter test` (starter counter widget test) | PASS (1 test) | 2026-09-03 |
| Native Windows compile of dependency set | `flutter build windows --debug` | PENDING — no Visual Studio toolchain on this host (`flutter doctor`: Visual Studio ✗, Android toolchain ✓). Command to re-run on a VS-equipped host recorded below. | 2026-09-03 |

## Target Capability Matrix

For each target: clean launch; encrypted database open/restart; protected-vault
read/write/delete; Firebase initialization; emulator connection; non-production device
integration; offline operation followed by reconnect retry.

### Android

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Firebase initialization | PENDING | |
| Emulator connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### iOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Firebase initialization | PENDING | |
| Emulator connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### Windows

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Firebase initialization | PENDING | |
| Emulator connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### macOS

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Firebase initialization | PENDING | |
| Emulator connectivity | PENDING | |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

### Linux

| Check | Status | Evidence |
|---|---|---|
| Clean root-route launch | PENDING | |
| Encrypted database open/restart | PENDING | |
| Credential vault read/write/delete | PENDING | |
| Firebase initialization | FAIL (declared) | No firebase_core/firebase_auth/cloud_firestore Linux plugin exists in resolved 4.x/6.x packages. |
| Emulator connectivity | PENDING | Requires a Firebase Linux adapter decision. |
| Non-production device integration | PENDING | |
| Offline commit + reconnect retry | PENDING | |

## Environment Constraints of This Implementation Run

- Implementation host: Windows 10 development machine with Flutter 3.41.8 stable; Android
  SDK 36 toolchain and Chrome available; **no Visual Studio toolchain**, so native Windows
  compilation cannot be exercised here. Re-run on a VS-equipped host with:
  `flutter build windows --debug` (validates sqlite3mc hook binaries and the FlutterFire
  Windows CAPI plugins compiling together).
- Host-verifiable checks (`flutter analyze`, `flutter test` unit/widget/architecture suites with
  the hooks-bundled encrypted SQLite and test doubles) are executed and recorded here.
- Checks requiring physical/emulated targets (Android/iOS devices, macOS/Linux builds) or a
  running Firebase Emulator Suite are recorded as PENDING with the exact command to run, because
  this environment cannot execute them. PENDING is not PASS; production lock-in stays blocked
  until each cell is verified (Constitution III).
