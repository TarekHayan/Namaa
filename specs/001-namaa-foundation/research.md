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
infrastructure. Treating a Supabase remote response or Realtime event as the local source of truth
breaks the approved offline-first model. Background synchronization is deferred because lifecycle
policy is not approved.

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

### 4. Supabase is behind application ports

**Decision**: Cloud Session and Cloud Sync ports have Supabase Auth and Postgres/Data API
implementations only in the data/cloud boundary. Automated tests run against the local Supabase
stack; device integration uses an isolated non-production Supabase project. Every exposed
account-data table has Row Level Security, explicit least-privilege grants, and account-isolation
policies before the client can access it.

**Rationale**: This prevents Domain Supabase coupling, permits deterministic test doubles, and
enforces account separation at the remote data boundary. The local Supabase stack is isolated from
production resources.

**Alternatives considered**: Supabase imports in Domain and production Supabase in automated tests
violate the specification. Supabase remote data cannot replace encrypted local persistence.

**Verification**: Run adapter tests against the local stack, reset local data between tests, test
RLS cross-account denial and grant policy behavior, then run separately credentialed device
integration against non-production.

### 5. Target capability is verified before production lock-in

**Decision**: Do not assume that Supabase Flutter or secure storage supports every target. Composition
depends only on ports. Prove initialization, credential protection, Auth, Data API transport, and
local-stack/non-production connectivity on Android, iOS, Windows, macOS, and Linux.

**Rationale**: Flutter and Drift support the required platforms. Supabase's Flutter quickstart
explicitly lists Android, iOS, macOS, and Windows, while package metadata lists Linux. The required
Linux Auth, Data API, session, and sync-transport path must be empirically proven.

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
- [Supabase Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
  [local development](https://supabase.com/docs/guides/local-development), and
  [Supabase Flutter package metadata](https://pub.dev/packages/supabase_flutter).
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
  and [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys).
- Namaa [Constitution](../../.specify/memory/constitution.md) and
  [Foundation specification](spec.md).
