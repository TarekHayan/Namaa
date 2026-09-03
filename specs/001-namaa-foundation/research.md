# Research: Namaa Foundation

## Decisions

### 1. Encrypted Drift/SQLite is the local source of truth

**Decision**: Persist Foundation data in Drift/SQLite with native database encryption. Obtain the
database key only through an OS-protected-storage adapter; never place keys or credentials in
preferences, database tables, logs, or failure records.

**Rationale**: Drift supports Android, iOS, Windows, macOS, and Linux; its encryption guidance
supports encrypted native databases including desktop.

**Alternatives considered**: Unencrypted SQLite violates the approved protection rule. A cloud
cache cannot provide the required desktop parity. Separate databases per domain are premature;
one encrypted database with feature-owned tables is sufficient.

**Verification**: Build/open encrypted databases and run restart/migration recovery tests on all
five targets.

### 2. A durable custom outbox supplies synchronization

**Decision**: A transaction changes local state and creates a stable-ID pending operation. The
synchronization coordinator dispatches only after local commit, records acknowledgements durably,
retries recoverable failures, and never replays an acknowledged operation.

**Rationale**: This supports immediate offline interaction, restart/reconnect safety, and
idempotent effects across every target.

**Alternatives considered**: Direct cloud writes from Cubits block offline use and couple UI to
infrastructure. Firestore cache cannot be the synchronization engine because official offline
persistence is documented for Android and Apple only. Background synchronization is deferred
because lifecycle policy is not approved.

**Verification**: Simulate offline commit, restart, reconnect, retry, and acknowledgement on each
target; prove one logical remote effect per operation ID.

### 3. Timestamp conflict selection retains evidence

**Decision**: For a conflict, the newest timestamp selects the active version and the non-winning
version is a visible conflict record. Equal timestamps remain a recoverable conflict until a
tie-breaker is separately approved.

**Rationale**: This is the recorded product-owner decision and prevents silent data loss.

**Alternatives considered**: Deleting the non-winning value violates the Constitution. Local-wins,
remote-wins, and a conflict UI are not approved for Foundation.

**Verification**: Test both ordering cases, duplicate receipt, equal timestamp, and restart before
acknowledgement.

### 4. Firebase is behind application ports

**Decision**: Cloud Session and Cloud Sync ports have Firebase Auth/Cloud Firestore implementations
only in the data/cloud boundary. Tests use Auth and Firestore emulators with one demo project ID;
device integration uses an isolated non-production Firebase project.

**Rationale**: This prevents Domain Firebase coupling and permits deterministic test doubles.
Firebase recommends demo projects where possible to avoid accidental live-resource use.

**Alternatives considered**: Firebase imports in Domain and production Firebase in automated tests
violate the specification. Firebase cache cannot replace encrypted local persistence.

**Verification**: Run adapter tests against emulators, reset emulator state between tests, then run
separately credentialed device integration against non-production.

### 5. Target capability is verified before production lock-in

**Decision**: Do not assume that FlutterFire or secure storage supports every target. Composition
depends only on ports. Prove initialization, credential protection, Auth, Firestore transport, and
emulator/non-production connectivity on Android, iOS, Windows, macOS, and Linux.

**Rationale**: Flutter and Drift support the required platforms. Current Firebase setup
documentation emphasizes Android, Apple, and web while release notes reference Windows; Linux
must be empirically proven rather than inferred.

**Alternatives considered**: Reducing platform scope contradicts the approved matrix. Selecting an
unapproved fallback cloud backend now is premature.

**Verification**: Record a pass/fail matrix. A missing safe adapter blocks production lock-in but
does not alter Domain/Application contracts.

### 6. ARB/gen_l10n supplies locale and directionality

**Decision**: Use Arabic and English ARB resources, locally persist locale preference, and let
Flutter localization delegates set app-root directionality.

**Rationale**: Flutter localization delegates establish RTL/LTR behavior consistently without
per-widget direction hacks.

**Alternatives considered**: Hard-coded strings violate the Constitution; manually forcing each
widget direction risks inconsistency.

**Verification**: Test Arabic RTL, English LTR, fallback behavior, and restart restoration.

### 7. Composition and root state remain minimal

**Decision**: One get_it/injectable composition root registers Foundation dependencies. BLoC/Cubit
represents only startup, locale, theme, recoverable failure, and sync status. Later features own
their Cubits and registrations.

**Rationale**: This meets the selected direction without a global business-state store or hidden
service-locator dependencies.

**Alternatives considered**: Domain entities accessing a service locator hide dependencies. A
global catch-all Cubit breaks feature ownership.

**Verification**: Resolve the graph using test adapters and deny forbidden imports from Domain.

## Sources Consulted

- [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms) and
  [desktop support](https://docs.flutter.dev/platform-integration/desktop).
- [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).
- [Drift](https://pub.dev/packages/drift), [drift_flutter](https://pub.dev/packages/drift_flutter),
  and [encryption guidance](https://drift.simonbinder.eu/platforms/encryption/).
- [Firestore offline behavior](https://firebase.google.com/docs/firestore/manage-data/enable-offline),
  [Firestore Emulator Suite](https://firebase.google.com/docs/emulator-suite/connect_firestore),
  and [Authentication Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth).
- [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup) and
  [FlutterFire release notes](https://firebase.google.com/support/release-notes/flutter).
- Namaa [Constitution](../../.specify/memory/constitution.md) and
  [Foundation specification](spec.md).
