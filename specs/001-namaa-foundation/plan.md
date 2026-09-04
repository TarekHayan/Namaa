# Implementation Plan: Namaa Foundation

**Branch**: feature/001-namaa-foundation | **Date**: 2026-09-04 | **Spec**:
[spec.md](spec.md)

**Input**: Foundation specification from specs/001-namaa-foundation/spec.md.

## Summary

Establish the Flutter/Dart application foundation for Android, iOS, Windows, macOS, and Linux.
The foundation supplies feature-first Clean Architecture boundaries, BLoC/Cubit presentation
state, dependency injection, encrypted local persistence, a durable custom synchronization outbox,
isolated Supabase infrastructure, application routing, localization and RTL, themes, recoverable
failures, and executable test entry points. It explicitly excludes all product-domain behavior.

The encrypted Drift database is the local source of truth. A custom synchronization boundary reads
durable pending operations, dispatches them through an infrastructure adapter, and records outcomes
idempotently. A version conflict selects the newer timestamp while retaining the non-winning
version as a visible conflict record. Supabase is an adapter behind this boundary, not a Domain
dependency.

## Technical Context

**Language/Version**: Dart SDK ^3.11.5; compatible Flutter SDK

**Primary Dependencies**: Flutter; flutter_bloc; get_it/injectable; Drift/drift_flutter with
SQLite cipher support; supabase_flutter; go_router;
flutter_localizations and intl; Freezed/json_serializable; OS-protected-storage adapter;
flutter_test, bloc_test, and integration_test. Exact versions are selected only after all-target
compatibility proof.

**Storage**: Encrypted Drift/SQLite for account-scoped state, preferences, outbox, conflicts, and
migration outcomes; OS-protected storage for credentials and database-key material. Supabase Auth,
Postgres/Data API, and Realtime where an approved feature needs it are remote infrastructure only.

**Testing**: flutter_test and bloc_test; integration_test; local Supabase stack for automated
Supabase tests; isolated non-production Supabase project for device integration; Supabase CLI
database tests for RLS and grant verification.

**Target Platform**: Android, iOS, Windows, macOS, and Linux

**Project Type**: One Flutter mobile and desktop application

**Performance Goals**: No numeric performance target is approved. Required outcomes are immediate
local update without network, root-route startup on every target, and durable state across ten
offline restarts.

**Constraints**: Offline-first after initial authenticated synchronization; shared business rules;
encrypted account data; OS-protected credentials; no direct Domain dependency on Flutter, Supabase,
persistence, routing, or platform adapters; idempotent retries; automatic migration that retains
prior data and exposes recovery; automated Supabase tests use local services; the client contains
only a Supabase publishable key; exposed account rows require RLS and least-privilege grants.

**Scale/Scope**: Foundation infrastructure only. Excludes Tasks, authentication user flows,
Finance, Quran, Prayer, notifications, and all other product domains.

## Constitution Check

### Pre-Design Gate — PASS

| Constitution obligation | Plan response |
|---|---|
| Flutter parity on five targets | One Flutter application; shared Domain/Application layers; adapters only at outer boundaries. |
| Clean Architecture and ownership | App composition, minimal core contracts, and feature-owned presentation/application/domain/data layers. |
| Durable local-first data | Encrypted Drift database plus durable outbox. |
| Safe synchronization | Stable operation IDs, idempotent retries, timestamp selection, retained conflict records. |
| Protected account data | OS-protected database key and cloud credentials; only Supabase publishable key in the client. |
| Supabase account separation | RLS and least-privilege grants protect every exposed account-data operation. |
| Arabic/English and RTL | ARB/gen_l10n, locale state, and root widget tests. |
| Quality and simplicity | Layered tests, five-target validation, one application, one local database, one composition root. |

**Gate decision**: PASS. Supabase and secure-storage capability on each target is a mandatory
verification gate. Linux Supabase Auth, Data API, session, and sync transport remain an explicit
production-lock-in proof, not an assumed capability.

## Project Structure

### Documentation (this feature)

~~~text
specs/001-namaa-foundation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── application-boundaries.md
│   ├── local-persistence.md
│   ├── synchronization.md
│   └── supabase-security.md
└── tasks.md                 # created later
~~~

### Source Code (repository root)

~~~text
lib/
├── app/
│   ├── composition/         # dependency registration and environment selection
│   ├── routing/             # root registry and guarded route shell
│   ├── l10n/                # ARB resources and generated localization output
│   └── theme/               # light, dark, system configuration
├── core/
│   ├── domain/              # cross-cutting value/failure types; no Flutter or SDK imports
│   ├── application/         # cross-cutting ports and use-case support
│   ├── data/
│   │   ├── local/           # Drift database, migrations, encrypted executor
│   │   ├── sync/            # outbox, retry coordinator, conflict records
│   │   └── cloud/           # Supabase adapters and environment configuration
│   └── platform/            # secure-storage and target-capability adapters
├── features/
│   └── foundation/
│       ├── presentation/    # root diagnostics and Foundation Cubits only
│       ├── application/     # use cases and ports
│       ├── domain/          # Foundation entities and invariants
│       └── data/            # feature-local adapters where needed
└── main.dart                # thin bootstrap

test/
├── unit/
├── widget/
├── architecture/
└── support/

integration_test/
├── foundation_offline_test.dart
├── foundation_sync_test.dart
├── foundation_migration_test.dart
├── foundation_platform_test.dart
└── foundation_supabase_test.dart

supabase/
├── migrations/              # account-table schema, grants, and RLS policies
└── tests/                   # local-stack database authorization checks

android/
ios/
windows/
macos/
linux/
~~~

**Structure Decision**: Use one feature-first Flutter application. App owns composition and
application-wide UI configuration; core owns minimal cross-cutting contracts and infrastructure;
features own product behavior. Imports point inward: presentation → application → domain, while
data/platform implement ports. Foundation presentation is limited to the app shell and diagnosable
recoverable states.

## Complexity Tracking

No constitutional exceptions or extra projects are required.

## Post-Design Constitution Check

**PASS.** The design preserves local ownership, encryption, idempotent outbox semantics, retained
conflict records, Supabase isolation, RLS account separation, and publishable-key-only client
configuration. The custom local-first path remains common to every target; Supabase is not the
offline source of truth. Production lock-in remains blocked until end-to-end Supabase verification,
including the required Linux proof, succeeds.
