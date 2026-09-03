# Tasks: Namaa Foundation

**Input**: Design documents in specs/001-namaa-foundation/

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), and
[quickstart.md](quickstart.md).

**Branch discipline**: Work only on feature/001-namaa-foundation. Do not checkout, merge, commit
to, or push main. Commit only completed logical groups on this feature branch after their specified
checks pass. Stop and report a failed Constitution gate, unsupported platform capability, or
unapproved product behavior instead of improvising a workaround.

**Tests**: Tests are mandatory because FR-017 and the acceptance criteria explicitly require unit,
widget, integration, architecture-boundary, migration, synchronization, and platform verification.
Create the named test first where a task says so; it must fail for the intended missing behavior
before the corresponding implementation is added.

## Format

Each task uses: checkbox, sequential ID, optional parallel marker, optional user-story label, and
an exact target path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Replace starter-app assumptions with safe Foundation scaffolding. No product-domain
screen, authentication flow, or domain behavior may be introduced in this phase.

- [x] T001 Update approved Foundation dependencies and development generators in pubspec.yaml; do not select a package version until its target compatibility is recorded.
- [x] T002 [P] Configure stricter analysis rules and generated-file exclusions in analysis_options.yaml.
- [x] T003 [P] Add Flutter localization generation configuration in l10n.yaml.
- [x] T004 [P] Create Arabic and English resource directories at lib/app/l10n/ and preserve generated output outside manually edited resources.
- [x] T005 Create the feature-first directory skeleton in lib/app/, lib/core/, lib/features/foundation/, test/unit/, test/widget/, test/architecture/, test/support/, and integration_test/.
- [x] T006 [P] Create test environment constants and non-production Firebase environment selection in test/support/test_environment.dart.
- [x] T007 [P] Create a target-capability validation record template in specs/001-namaa-foundation/platform-validation.md for Android, iOS, Windows, macOS, and Linux.
- [x] T008 Run dependency resolution and static analysis from pubspec.yaml and analysis_options.yaml; record any unsupported package/platform result in specs/001-namaa-foundation/platform-validation.md.

**Checkpoint**: The starter application remains buildable, the directory structure exists, and no
production Firebase environment or product feature has been added.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the minimum shared contracts and app composition required before any user-story
increment. All Domain code must remain independent of Flutter, Drift, Firebase, routing, and
platform implementations.

### Tests for Foundational Boundaries

- [ ] T009 [P] Write forbidden-import architecture tests in test/architecture/domain_dependency_test.dart covering lib/core/domain/ and lib/features/foundation/domain/.
- [ ] T010 [P] Write composition smoke tests with test doubles in test/unit/app/composition_test.dart before creating the production composition root.
- [ ] T011 [P] Write app-shell unknown-route failure widget test in test/widget/app/root_route_failure_test.dart before adding the route shell.

### Implementation for Foundational Boundaries

- [ ] T012 Create shared domain failure/result value types with no Flutter or SDK imports in lib/core/domain/failures/app_failure.dart and lib/core/domain/results/result.dart.
- [ ] T013 Create infrastructure-neutral cloud-session, cloud-sync, local-store, and credential-vault port contracts in lib/core/application/ports/.
- [ ] T014 Create Foundation presentation state contracts for startup, ready, recoverable failure, and blocking failure in lib/features/foundation/presentation/state/foundation_state.dart.
- [ ] T015 Create the application dependency-registration entry point in lib/app/composition/configure_dependencies.dart and register test-double seams without resolving concrete Firebase or Drift objects in Domain.
- [ ] T016 Create the root route registry and handled unknown-route boundary in lib/app/routing/app_router.dart.
- [ ] T017 Replace the starter bootstrap with a thin composition-root entry point in lib/main.dart and an app shell boundary in lib/app/app.dart.
- [ ] T018 Make T009-T011 pass using only the contracts and app shell in lib/core/, lib/app/, lib/features/foundation/, and test/.

**Checkpoint**: Architecture tests prevent forbidden Domain dependencies; the composition root
resolves test doubles; an unknown route produces a handled failure state.

---

## Phase 3: User Story 1 - Use Namaa Through Connectivity Changes (Priority: P1) MVP

**Goal**: A Foundation-supported local operation persists immediately without network, survives a
restart, queues a durable synchronization operation, and safely handles acknowledgement, retry,
conflict, migration, Firebase isolation, and encrypted account data.

**Independent Test**: With network disabled, commit a Foundation probe record, restart the
application, read the same record, reconnect to a test cloud adapter, and verify one logical
remote effect. Inject conflicts and migration failures to verify retained evidence and recovery.

### Tests for User Story 1

- [ ] T019 [P] [US1] Write unit tests for Foundation entities, operation-ID immutability, and timestamp conflict selection in test/unit/foundation/domain/foundation_entities_test.dart.
- [ ] T020 [P] [US1] Write encrypted-local-store contract tests, including absent credential and no-unencrypted-fallback cases, in test/unit/core/data/local/encrypted_local_store_test.dart.
- [ ] T021 [P] [US1] Write outbox acknowledgement, retry, and duplicate-dispatch tests in test/unit/core/data/sync/outbox_sync_coordinator_test.dart.
- [ ] T022 [P] [US1] Write migration success and injected-failure recovery tests in test/unit/core/data/local/migration_recovery_test.dart.
- [ ] T023 [P] [US1] Write Firebase-port substitution and emulator-environment tests in test/unit/core/data/cloud/firebase_boundary_test.dart.
- [ ] T024 [P] [US1] Write offline-restart and reconnect integration scenarios in integration_test/foundation_offline_test.dart and integration_test/foundation_sync_test.dart.
- [ ] T025 [P] [US1] Write encrypted-persistence and migration integration scenarios in integration_test/foundation_security_test.dart and integration_test/foundation_migration_test.dart.

### Implementation for User Story 1

- [ ] T026 [P] [US1] Create typed Foundation local-record, pending-change, conflict-record, migration-journal, and preference entities in lib/features/foundation/domain/entities/.
- [ ] T027 [P] [US1] Create Foundation synchronization and persistence use-case contracts in lib/features/foundation/application/use_cases/.
- [ ] T028 [US1] Create the OS-protected credential-vault adapter boundary in lib/core/platform/secure_storage/credential_vault.dart and return controlled failures without exposing secrets.
- [ ] T029 [US1] Configure the encrypted Drift database executor and database-key acquisition in lib/core/data/local/encrypted_app_database.dart; refuse unencrypted fallback.
- [ ] T030 [US1] Define Drift tables and typed data-access objects for preferences, local records, outbox operations, conflict records, and migration journal in lib/core/data/local/schema/ and lib/core/data/local/daos/.
- [ ] T031 [US1] Implement automatic migration execution, migration journaling, prior-state retention, and recoverable migration failure in lib/core/data/local/migrations/.
- [ ] T032 [US1] Implement atomic local-record plus pending-change commits and preference fallback behavior in lib/core/data/local/drift_local_store.dart.
- [ ] T033 [US1] Implement operation-ID-preserving outbox state transitions and acknowledgement persistence in lib/core/data/sync/durable_outbox.dart.
- [ ] T034 [US1] Implement the synchronization coordinator with recoverable retry, acknowledged terminal state, and no duplicate logical dispatch in lib/core/data/sync/sync_coordinator.dart.
- [ ] T035 [US1] Implement timestamp conflict selection, non-winning-version retention, and equal-timestamp recoverable conflict in lib/core/data/sync/conflict_resolver.dart.
- [ ] T036 [US1] Implement Firebase Auth and Cloud Firestore adapters only behind ports in lib/core/data/cloud/firebase/; do not import Firebase from Domain or Cubits.
- [ ] T037 [US1] Add Firebase emulator selection, one demo project ID configuration, emulator reset support, and production-environment rejection to lib/core/data/cloud/firebase/firebase_environment.dart.
- [ ] T038 [US1] Register encrypted storage, local store, sync coordinator, Firebase adapters, emulator/test adapters, and test doubles in lib/app/composition/configure_dependencies.dart.
- [ ] T039 [US1] Implement a Foundation sync-status Cubit that invokes use cases only in lib/features/foundation/presentation/cubit/sync_status_cubit.dart.
- [ ] T040 [US1] Make T019-T025 pass, then run the P1 scenarios in quickstart.md; record all target and Firebase results in specs/001-namaa-foundation/platform-validation.md.

**Checkpoint**: P1 is independently usable and testable offline. It stores account-scoped data
encrypted, survives restart, retries safely, retains conflicts, migrates safely, and does not
couple Domain code to Firebase/Drift.

---

## Phase 4: User Story 2 - Use Namaa in Arabic or English (Priority: P2)

**Goal**: The Foundation app shell switches between Arabic RTL and English LTR, restores a supported
preference safely, and displays localized recoverable failures without adding a product screen.

**Independent Test**: Launch with each locale, change locale, restart, and verify Arabic RTL,
English LTR, localized Foundation text, and fallback for unavailable preferences.

### Tests for User Story 2

- [ ] T041 [P] [US2] Write Arabic RTL, English LTR, locale-switch, and unsupported-locale fallback widget tests in test/widget/app/localization_test.dart.
- [ ] T042 [P] [US2] Write locale-preference persistence and localized-failure Cubit tests in test/unit/foundation/presentation/locale_cubit_test.dart.

### Implementation for User Story 2

- [ ] T043 [P] [US2] Define complete English Foundation resource keys in lib/app/l10n/app_en.arb.
- [ ] T044 [P] [US2] Define equivalent Arabic Foundation resource keys in lib/app/l10n/app_ar.arb.
- [ ] T045 [US2] Configure generated localization delegates and supported Arabic/English locales in l10n.yaml and lib/app/app.dart.
- [ ] T046 [US2] Implement locale preference use cases and locale Cubit in lib/features/foundation/application/use_cases/locale_use_cases.dart and lib/features/foundation/presentation/cubit/locale_cubit.dart.
- [ ] T047 [US2] Bind localized text, recovered locale preference, and Flutter directionality at the app root in lib/app/app.dart.
- [ ] T048 [US2] Make T041-T042 pass and record Arabic RTL/English LTR results in specs/001-namaa-foundation/platform-validation.md.

**Checkpoint**: P2 is independently testable: the app root presents Arabic RTL and English LTR,
restores preferences safely, and emits no hard-coded Foundation text.

---

## Phase 5: User Story 3 - Receive a Consistent Foundation on Any Supported Target (Priority: P3)

**Goal**: The root route starts consistently on all approved platforms while supporting light,
dark, and system themes and retaining shared business semantics behind platform adapters.

**Independent Test**: On a supported target, launch the root route, choose every appearance mode,
restart, and confirm route/navigation and preference restoration. Execute the same suite on all
five targets and report adapter capability results.

### Tests for User Story 3

- [ ] T049 [P] [US3] Write root-route, unknown-route, and theme-mode widget tests in test/widget/app/routing_and_theme_test.dart.
- [ ] T050 [P] [US3] Write theme-preference persistence Cubit tests in test/unit/foundation/presentation/theme_cubit_test.dart.
- [ ] T051 [P] [US3] Write target startup and adapter-capability integration harness in integration_test/foundation_platform_test.dart.
- [ ] T052 [P] [US3] Write isolated non-production Firebase device-integration harness in integration_test/foundation_firebase_test.dart.

### Implementation for User Story 3

- [ ] T053 [P] [US3] Define light and dark ThemeData plus system-mode selection in lib/app/theme/app_theme.dart.
- [ ] T054 [US3] Implement appearance preference use cases and theme Cubit in lib/features/foundation/application/use_cases/theme_use_cases.dart and lib/features/foundation/presentation/cubit/theme_cubit.dart.
- [ ] T055 [US3] Bind theme state and system appearance to the root app shell in lib/app/app.dart.
- [ ] T056 [US3] Add Foundation root route, navigation shell, and route-error state without a product feature screen in lib/app/routing/app_router.dart.
- [ ] T057 [US3] Add platform-capability reporting for encrypted database, credential vault, Firebase initialization, emulator connectivity, and non-production device integration in lib/core/platform/platform_capability_reporter.dart.
- [ ] T058 [US3] Make T049-T052 pass across Android, iOS, Windows, macOS, and Linux; complete specs/001-namaa-foundation/platform-validation.md with pass/fail evidence and block production lock-in on any failure.

**Checkpoint**: P3 is independently testable: all appearance modes work at the root, route failures
are handled, and the five-platform evidence record is complete.

---

## Phase 6: Polish and Cross-Cutting Verification

**Purpose**: Verify the complete Foundation against its specification, contracts, Constitution, and
the lower-experience-agent handoff rules. Do not refactor merely for aesthetics.

- [ ] T059 [P] Run and fix all static-analysis findings from analysis_options.yaml and lib/.
- [ ] T060 [P] Run all unit, widget, architecture, and integration tests from test/ and integration_test/ with Firebase emulators; confirm no test reaches production Firebase.
- [ ] T061 [P] Verify all Local Store, Cloud Session, Cloud Sync, Credential Vault, and presentation-state contracts against specs/001-namaa-foundation/contracts/.
- [ ] T062 Review lib/ against FR-001 through FR-022 and document requirement-to-evidence mapping in specs/001-namaa-foundation/verification-report.md.
- [ ] T063 Review the completed platform evidence and quickstart scenarios in specs/001-namaa-foundation/platform-validation.md and specs/001-namaa-foundation/quickstart.md; block release if any target lacks a verified safe adapter.
- [ ] T064 Confirm scope containment by checking lib/ and integration_test/ for Tasks, authentication UI, Finance, Quran, Prayer, notification, and other product-domain behavior; record the result in specs/001-namaa-foundation/verification-report.md.
- [ ] T065 Perform final Constitution compliance review against .specify/memory/constitution.md and record remaining blockers, if any, in specs/001-namaa-foundation/verification-report.md.

**Checkpoint**: Foundation is ready for review only when every required test passes, all five target
results are recorded, Firebase production isolation is proven, and the verification report contains
no unapproved scope expansion.

---

## Dependencies and Execution Order

### Phase Dependencies

~~~text
Phase 1 Setup
    ↓
Phase 2 Foundational
    ↓
Phase 3 US1: offline persistence and synchronization MVP
    ↓
Phase 4 US2: localization and RTL
    ↓
Phase 5 US3: theme, routing, and platform matrix
    ↓
Phase 6 verification
~~~

US2 and US3 use the completed app composition from Phase 2 and the persistence boundary from US1
to restore preferences. They may be parallelized only after a lead confirms no two tasks edit the
same file; this plan’s safe default for a less-experienced implementation agent is the sequential
order above.

### User Story Dependencies

- **US1 (P1)** depends on Setup and Foundational phases; it is the MVP.
- **US2 (P2)** depends on the shared app shell and local preference store; it does not depend on
  product-domain behavior.
- **US3 (P3)** depends on the shared app shell and local preference store; it does not depend on
  product-domain behavior.

### Parallel Opportunities

- In Setup: T002, T003, T004, T006, and T007 are separate-file tasks after T001 establishes
  dependencies.
- In Foundational tests: T009, T010, and T011 can be written in parallel.
- In US1: T019 through T025 can be written in parallel; T026 and T027 can start together.
- In US2: T041/T042 and T043/T044 can each run in parallel.
- In US3: T049 through T052 can be written in parallel; T053 can proceed independently of T054.
- In final verification: T059, T060, and T061 can run in parallel after US3 completes.

## Parallel Example: User Story 1

~~~text
Parallel test work:
- T019 Foundation entity/conflict unit tests
- T020 encrypted-store contract tests
- T021 outbox retry tests
- T022 migration recovery tests
- T023 Firebase boundary tests
- T024 offline and reconnect integration tests
- T025 persistence-security and migration integration tests

Then sequentially:
T028 → T029 → T030 → T031 → T032 → T033 → T034 → T035 → T036 → T037 → T038 → T039 → T040
~~~

## Implementation Strategy

### MVP First

1. Complete T001 through T018.
2. Complete all US1 test tasks before their implementation tasks.
3. Complete T026 through T040.
4. Stop. Validate the P1 offline/restart/reconnect path with emulators and a test-double cloud
   adapter before proceeding.

### Incremental Delivery

1. US1 delivers encrypted local-first persistence and safe synchronization.
2. US2 adds localized Arabic/English root behavior and RTL.
3. US3 adds themes, routing, and the five-target evidence gate.
4. Phase 6 verifies containment and Constitution compliance before review.

### Lower-Experience Agent Guardrails

- Complete one unchecked task at a time and run its named test/check before the next dependent task.
- Do not change any file outside a task’s stated scope unless a task explicitly requires it.
- Do not replace a failing test with a weaker assertion.
- Do not select an unverified package/platform fallback; record the failure in platform-validation.md
  and stop for review.
- Do not add a product feature to make a Foundation test convenient.
