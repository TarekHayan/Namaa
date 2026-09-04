---

description: "Implementation tasks for the Namaa Foundation"
---

# Tasks: Namaa Foundation

**Input**: Design documents from `/specs/001-namaa-foundation/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), and [quickstart.md](quickstart.md)

**Tests**: Tests are required by FR-017 and the Constitution. Implementer MUST write the listed
tests before their corresponding implementation task and confirm they fail for the expected
reason before changing production code.

**Scope boundary**: These tasks create only the technical foundation. Do not add a Tasks,
authentication UI/flow, Finance, Quran, Prayer, notification, gamification, or other product-domain
feature. Do not add a Supabase secret or service-role key to any client artifact.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: The task can be done in parallel because it changes a different file and has no
  uncompleted prerequisite in this phase.
- **[Story]**: The user story served by the task. Setup, foundational, and polish tasks have no
  story label.

## Phase 1: Setup and Provider Migration

**Purpose**: Prepare an intentionally small Flutter foundation workspace and remove the obsolete
Firebase direction before implementation begins.

- [ ] T001 Replace `cloud_firestore`, `firebase_auth`, and `firebase_core` with `supabase_flutter` in `pubspec.yaml`; retain only Foundation-approved dependencies and run `flutter pub get`.
- [ ] T002 [P] Add ARB generation configuration with Arabic and English support in `l10n.yaml`.
- [ ] T003 [P] Create the initial Foundation domain entry files and types in `lib/core/domain/results/app_result.dart` and `lib/features/foundation/domain/foundation_entities.dart` without adding any product-domain behavior.
- [ ] T004 [P] Create local Supabase configuration in `supabase/config.toml` for Docker-backed automated tests; do not place non-local credentials or production URLs in it.
- [ ] T005 [P] Add test-only environment allow-list helpers in `test/support/test_environment.dart` that distinguish the local Supabase stack and isolated non-production device configuration and reject production hosts.
- [ ] T006 [P] Add deterministic test helpers for clock, connectivity, and temporary encrypted database paths in `test/support/foundation_test_support.dart`.
- [ ] T007 [P] Add the Foundation platform-validation record template in `specs/001-namaa-foundation/platform-validation.md` for Android, iOS, Windows, macOS, and Linux evidence.
- [ ] T008 Run `dart format .`, `flutter analyze`, and the existing test entry points; record only pre-existing failures in `specs/001-namaa-foundation/implementation-baseline.md` without changing unrelated code.

**Checkpoint**: The dependency manifest contains no Firebase package, and the project is ready for
Foundation-only source files and a local Supabase test configuration.

---

## Phase 2: Foundational Boundaries and Bootstrap (Blocking Prerequisites)

**Purpose**: Establish the shared contracts, composition root, and guardrails that every user
story requires. No user-story implementation starts until this phase is complete.

- [ ] T009 [P] Create public, infrastructure-free result and failure types in `lib/core/domain/results/app_result.dart` and `lib/core/domain/failures/app_failure.dart` for recoverable and blocking outcomes with no Flutter, Drift, or Supabase imports.
- [ ] T010 [P] Create the Local Store, Cloud Session, Cloud Sync, Credential Vault, connectivity, and platform-capability ports in `lib/core/application/ports/foundation_ports.dart` according to `contracts/application-boundaries.md`.
- [ ] T011 [P] Create Foundation value types for application preference, local record, pending change, conflict record, migration journal, and failure state in `lib/features/foundation/domain/foundation_entities.dart` with invariants from `data-model.md`.
- [ ] T012 [P] Add architecture import-boundary tests in `test/architecture/domain_dependency_test.dart` that fail on Domain imports of Flutter, Supabase, Drift, routing, notification, or platform adapters.
- [ ] T013 [P] Add unit tests for Foundation value-type validation, pending-change terminal acknowledgement, and equal-timestamp recoverable conflict behavior in `test/unit/features/foundation/domain/foundation_value_types_test.dart`.
- [ ] T014 Create application use cases for bootstrap, preference restoration, local record commit, pending synchronization, retry, conflict recording, and migration recovery in `lib/features/foundation/application/foundation_use_cases.dart`; depend only on the ports from T010.
- [ ] T018 Add dependency-resolution and Cubit-boundary tests in `test/unit/app/composition/configure_dependencies_test.dart` and `test/unit/features/foundation/presentation/foundation_cubits_test.dart` using only fakes for all ports; confirm they fail before implementing T015–T017.
- [ ] T015 Create the application composition entry point in `lib/app/composition/configure_dependencies.dart` and test-double registration surface in `lib/app/composition/unconfigured_adapters.dart`; do not register SDK instances in Domain.
- [ ] T016 Create root bootstrap, failure, locale, theme, and synchronization status Cubit state contracts in `lib/features/foundation/presentation/state/foundation_state.dart` with localized message keys rather than infrastructure error text.
- [ ] T017 Create the minimal app shell and composition bootstrap in `lib/app/app.dart` and `lib/main.dart` so boot errors are represented as safe startup state rather than uncaught exceptions.

**Checkpoint**: Domain imports are clean, the composition root resolves fakes, and a startup failure
is represented by a Cubit state without a product screen.

---

## Phase 3: User Story 1 - Use Namaa Through Connectivity Changes (Priority: P1) 🎯 MVP

**Goal**: A Foundation-owned verification record can change locally while offline, survive restart,
and synchronize safely through isolated Supabase infrastructure after connectivity returns.

**Independent Test**: Run the offline/restart, retry/idempotency, migration, security, and local
Supabase account-isolation suites. They must complete without any product-domain screen or a
production cloud endpoint.

### Tests for User Story 1

- [ ] T019 [P] [US1] Write encrypted Local Store transaction and preference-restoration tests in `test/unit/core/data/local/encrypted_local_store_test.dart`, including the rule that local change and pending operation commit atomically.
- [ ] T020 [P] [US1] Write Credential Vault tests in `test/unit/core/platform/credential_vault_test.dart` proving secrets are not written to preference, failure, or log test doubles.
- [ ] T021 [P] [US1] Write synchronization coordinator unit tests in `test/unit/core/data/sync/synchronization_coordinator_test.dart` for retry with unchanged operation ID, acknowledgement terminality, newest-timestamp selection, retained conflict, and equal-timestamp recovery.
- [ ] T022 [P] [US1] Write migration success and injected-failure preservation tests in `test/unit/core/data/local/foundation_migration_test.dart`.
- [ ] T023 [P] [US1] Write a Supabase-port substitution and publishable-key-only configuration test in `test/unit/core/data/cloud/supabase_boundary_test.dart`; it must fail for secret/service-role key material or a Domain Supabase import.
- [ ] T024 [P] [US1] Write local-stack database authorization tests in `supabase/tests/foundation_account_isolation_test.sql` before T034; the test may initially fail while the Supabase schema and RLS policies are absent, then rerun it after T034 to verify owner account allowed and different account denied for read/write operations.
- [ ] T025 [P] [US1] Write an offline persistence/restart integration test with ten consecutive restarts in `integration_test/foundation_offline_test.dart`.
- [ ] T026 [P] [US1] Write reconnect/retry and conflict-retention integration tests in `integration_test/foundation_sync_test.dart`.
- [ ] T027 [P] [US1] Write encrypted migration/recovery integration coverage in `integration_test/foundation_migration_test.dart`.
- [ ] T028 [P] [US1] Write local Supabase stack and isolated non-production device boundary coverage in `integration_test/foundation_supabase_test.dart`; production configuration must be rejected before a connection is attempted.

### Implementation for User Story 1

- [ ] T029 [US1] Implement the OS-protected Credential Vault adapter in `lib/core/platform/secure_credential_vault.dart` and wire it only through the Credential Vault port.
- [ ] T030 [US1] Implement encrypted Drift database opening, Foundation tables, automatic migration journal, and recoverable migration failure path in `lib/core/data/local/foundation_database.dart`.
- [ ] T031 [US1] Implement the encrypted Local Store adapter, including atomic local-record/outbox commit and durable preference storage, in `lib/core/data/local/drift_local_store.dart`.
- [ ] T032 [US1] Implement environment validation and a publishable-key-only Supabase client factory in `lib/core/data/cloud/supabase/supabase_environment.dart` and `lib/core/data/cloud/supabase/supabase_client_factory.dart`.
- [ ] T033 [US1] Implement Supabase Auth session and cloud-sync adapters behind the ports in `lib/core/data/cloud/supabase/supabase_session_adapter.dart` and `lib/core/data/cloud/supabase/supabase_sync_adapter.dart`; do not implement authentication UI or a product account workflow.
- [ ] T034 [US1] Create the Foundation-only remote probe schema, least-privilege grants, and RLS owner policies in `supabase/migrations/0001_foundation_probe.sql`; enforce remote ownership from the authenticated session rather than a caller-supplied account ID.
- [ ] T035 [US1] Implement the durable outbox, retry coordinator, idempotent acknowledgement, and conflict-record persistence in `lib/core/data/sync/synchronization_coordinator.dart`.
- [ ] T036 [US1] Implement connectivity-triggered retry orchestration and recoverable failure mapping in `lib/core/data/sync/synchronization_runner.dart` without making the UI or Domain depend on network SDK types.
- [ ] T037 [US1] Connect the local store, credential vault, Supabase adapters, and synchronization coordinator only in `lib/app/composition/configure_dependencies.dart` for local, test, and non-production environments.
- [ ] T038 [US1] Implement the Foundation synchronization status and retry Cubit behavior in `lib/features/foundation/presentation/state/synchronization_cubit.dart` using the use cases from T014.
- [ ] T039 [US1] Make T019–T028 pass against the local Supabase stack, then run the User Story 1 validation commands in `quickstart.md` without contacting production.

**Checkpoint**: A Foundation verification record is durable and usable offline; reconnect retries are
idempotent; conflicts retain evidence; local account data is encrypted; and RLS denies another
account access.

---

## Phase 4: User Story 2 - Use Namaa in Arabic or English (Priority: P2)

**Goal**: The app root displays Arabic and English resources, restores a valid saved locale, and
applies Arabic RTL correctly.

**Independent Test**: Launch the app root in Arabic and English, switch locale, restart, and verify
Arabic RTL, English LTR, localized root text, and invalid-preference fallback.

### Tests for User Story 2

- [ ] T040 [P] [US2] Write locale preference use-case and unsupported-value fallback tests in `test/unit/features/foundation/application/locale_preference_test.dart`.
- [ ] T041 [P] [US2] Write locale Cubit state-transition tests in `test/unit/features/foundation/presentation/locale_cubit_test.dart`.
- [ ] T042 [P] [US2] Write app-root Arabic RTL, English LTR, localized-resource, locale-switch, and restart-restoration widget tests in `test/widget/app/localization_and_directionality_test.dart`.

### Implementation for User Story 2

- [ ] T043 [US2] Add Foundation-only Arabic resources in `lib/app/l10n/app_ar.arb` and matching English resources in `lib/app/l10n/app_en.arb`; do not add domain-specific copy.
- [ ] T044 [US2] Configure generated Flutter localization delegates and supported locales in `lib/app/app.dart` using the generated output from `lib/app/l10n/`.
- [ ] T045 [US2] Implement locale preference restoration, validation, persistence, and fallback use cases in `lib/features/foundation/application/locale_preferences.dart`.
- [ ] T046 [US2] Implement `LocaleCubit` and its state in `lib/features/foundation/presentation/state/locale_cubit.dart` without direct database access.
- [ ] T047 [US2] Bind the root locale and Flutter directionality to `LocaleCubit` in `lib/app/app.dart`; do not introduce per-widget manual direction overrides.
- [ ] T048 [US2] Make T040–T042 pass on one mobile and one desktop target and record the evidence in `specs/001-namaa-foundation/platform-validation.md`.

**Checkpoint**: Arabic and English work at the root, Arabic is RTL, and a safe locale fallback
keeps the app launchable.

---

## Phase 5: User Story 3 - Receive a Consistent Foundation on Any Supported Target (Priority: P3)

**Goal**: The app reaches a registered root route and supports light, dark, and system appearance
with shared Foundation contracts across mobile and desktop.

**Independent Test**: On one mobile and one desktop target, launch the registered root route,
exercise all appearance modes, verify unknown-route handling, and confirm no platform-specific
business-rule implementation exists.

### Tests for User Story 3

- [ ] T049 [P] [US3] Write appearance preference restoration and fallback unit tests in `test/unit/features/foundation/application/theme_preference_test.dart`.
- [ ] T050 [P] [US3] Write Theme Cubit transition tests for light, dark, and system modes in `test/unit/features/foundation/presentation/theme_cubit_test.dart`.
- [ ] T051 [P] [US3] Write registered-root-route and handled unknown-route tests in `test/widget/app/app_router_test.dart`.
- [ ] T052 [P] [US3] Write root theme-mode widget tests in `test/widget/app/theme_selection_test.dart`.
- [ ] T053 [P] [US3] Write startup, encrypted-store, credential-vault, Supabase initialization, and offline/reconnect platform-capability integration coverage in `integration_test/foundation_platform_test.dart`.

### Implementation for User Story 3

- [ ] T054 [US3] Define the root route registry and handled unknown-route boundary in `lib/app/routing/app_router.dart` without adding feature routes or product screens.
- [ ] T055 [US3] Implement Foundation theme definitions and system appearance support in `lib/app/theme/app_theme.dart`.
- [ ] T056 [US3] Implement theme preference use cases and `ThemeCubit` in `lib/features/foundation/application/theme_preferences.dart` and `lib/features/foundation/presentation/state/theme_cubit.dart`.
- [ ] T057 [US3] Bind routing, light, dark, and system theme state at the application root in `lib/app/app.dart`.
- [ ] T058 [US3] Implement target-capability reporting at the infrastructure boundary in `lib/core/platform/platform_capability_reporter.dart`; report capability failures without branching Domain business rules.
- [ ] T059 [US3] Make T049–T053 pass on one mobile and one desktop target and record the evidence in `specs/001-namaa-foundation/platform-validation.md`.

**Checkpoint**: The shared root route, routing failure handling, and all appearance modes work on
both form factors without product features or divergent business semantics.

---

## Phase 6: Polish, Security, and Release-Gate Verification

**Purpose**: Complete required cross-cutting validation and preserve explicit evidence before any
later product-domain work is planned.

- [ ] T060 [P] Re-run and extend `test/architecture/domain_dependency_test.dart` to verify that Presentation Cubits also do not import Drift, Supabase, or secure-storage adapters directly.
- [ ] T061 [P] Review `supabase/migrations/0001_foundation_probe.sql` and `supabase/tests/foundation_account_isolation_test.sql` for least-privilege grants, enabled RLS, owner-allowed access, and cross-account denial.
- [ ] T062 [P] Add a client-artifact and configuration scan test in `test/architecture/client_secret_scan_test.dart` that fails for Supabase secret/service-role key patterns in tracked Flutter client files.
- [ ] T063 Run `dart format .`, `flutter analyze`, all unit/widget/architecture tests, `flutter test integration_test`, and `supabase test db` using the local Supabase stack; resolve only Foundation failures.
- [ ] T064 Run the complete quickstart validation matrix on Android, iOS, Windows, macOS, and Linux and record launch, encryption, vault, Supabase Auth/Data API/session/sync, offline/reconnect, locale/RTL, and theme evidence in `specs/001-namaa-foundation/platform-validation.md`.
- [ ] T065 Update `specs/001-namaa-foundation/quickstart.md` only if the implemented commands differ from the documented, verified commands; preserve the local-stack and non-production-only restrictions.
- [ ] T066 Conduct a final Constitution and specification traceability review in `specs/001-namaa-foundation/implementation-review.md`, confirming FR-001–FR-024, AC-001–AC-014, and SC-001–SC-011 or recording a blocking unsupported target capability.

**Checkpoint**: Foundation is complete only when every required target has evidence, all automated
checks pass, no client secret is present, production is never contacted by automated tests, and no
product feature has been introduced.

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1 — Setup**: Starts immediately. T001 must finish before Flutter dependency-dependent
  work; T004 and T005 must finish before local Supabase testing.
- **Phase 2 — Foundational**: Starts after Phase 1. It blocks every user story.
- **Phase 3 — US1 (P1)**: Starts after Phase 2. It is the MVP and establishes verifiable
  persistence and synchronization.
- **Phase 4 — US2 (P2)**: Starts after US1 completes because it uses the shared LocalStore/Drift
  foundation established by US1.
- **Phase 5 — US3 (P3)**: Starts after US2 to preserve the required implementation order and uses
  the same shared LocalStore/Drift foundation established by US1.
- **Phase 6 — Polish**: Starts after the selected user-story work is complete; T064 is a hard
  production-lock-in gate, not a reason to weaken target support.

### User Story Dependencies

- **US1**: Depends on Phase 2; no dependency on US2 or US3.
- **US2**: Depends on Phase 2, the app shell from T017, and the shared LocalStore/Drift foundation
  established by US1.
- **US3**: Is implemented after US2 and depends on Phase 2, the app shell from T017, and the same
  shared LocalStore/Drift foundation established by US1; it has no product-behavior dependency on US2.

### Within User Story 1

1. Complete T019–T028 before T029–T038.
2. Complete T029–T034 before the coordinator in T035.
3. Complete T035–T038 before the verification task T039.

### Within User Story 2

1. Complete T040–T042 before T043–T047.
2. Complete resource and delegate work T043–T044 before binding the Cubit at T047.
3. Run T048 only after all prior US2 tasks pass.

### Within User Story 3

1. Complete T049–T053 before T054–T058.
2. Complete routing/theme implementations T054–T057 before capability evidence T059.

## Parallel Opportunities

- Phase 1: T002–T007 can run in parallel after T001's dependency direction is understood.
- Phase 2: T009–T013 can run in parallel because they use separate contracts, domain files, and
  tests.
- US1: T019–T028 are independent test files and may be assigned in parallel. T029 and T030 may
  begin together only after their tests exist; T032 and T034 may run in parallel with them.
- US2: T040–T042 are parallel test tasks; T043 and T045 may proceed independently after tests.
- US3: T049–T053 are parallel test tasks; T054, T055, and T058 are independent implementation
  files once their tests are in place.
- Polish: T060–T062 are independent reviews/tests and can run in parallel.

## Parallel Example: User Story 1

```text
Task: "T019 encrypted Local Store tests in test/unit/core/data/local/encrypted_local_store_test.dart"
Task: "T021 synchronization tests in test/unit/core/data/sync/synchronization_coordinator_test.dart"
Task: "T024 RLS SQL tests in supabase/tests/foundation_account_isolation_test.sql"
Task: "T025 offline restart tests in integration_test/foundation_offline_test.dart"
```

## Implementation Strategy

### MVP First

1. Finish Phases 1 and 2.
2. Finish all User Story 1 tests before implementation.
3. Complete T029–T038 and validate with T039.
4. Stop and verify the offline/local-first Foundation before starting locale or theme work.

### Incremental Delivery

1. **MVP**: US1 supplies encrypted local-first persistence, safe synchronization boundaries, and
   Supabase account isolation.
2. **Increment 2**: US2 adds app-root Arabic/English localization and RTL.
3. **Increment 3**: US3 adds route and theme consistency across mobile and desktop.
4. **Release gate**: Phase 6 provides the five-target evidence; a failed capability blocks
   production lock-in rather than prompting a new unapproved backend or business-rule variant.

## Task Validation

- **Total tasks**: 66 (T001–T066).
- **User Story 1**: 21 tasks (T019–T039).
- **User Story 2**: 9 tasks (T040–T048).
- **User Story 3**: 11 tasks (T049–T059).
- **Setup/foundational/polish**: 25 tasks (T001–T018, T060–T066).
- Every task uses the required checkbox, sequential ID, applicable `[P]` and `[US#]` labels, and
  at least one exact repository path.
