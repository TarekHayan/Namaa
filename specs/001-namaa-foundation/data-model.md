# Data Model: Namaa Foundation

## Ownership Rules

- The Foundation owns only cross-cutting configuration, persistence, synchronization, conflict,
  and failure records. It defines no product-domain data.
- A later feature owns its tables, entities, invariants, and migrations. Foundation services use
  them only through explicit contracts.
- Account-scoped database rows are encrypted at rest. Credential secrets and database key material
  never appear in these entities.

## Entities

### Application Preference

| Field | Purpose | Validation |
|---|---|---|
| preference key | Stable identifier for Foundation setting | Unique and Foundation-owned |
| value | Serialized non-secret setting | Valid for preference key |
| updated at | Last local change | Required UTC instant |

Initial keys are locale and appearance mode. Locale is Arabic or English; appearance is light,
dark, or system. Invalid values fall back to a supported locale and system appearance.

### Local Record

| Field | Purpose | Validation |
|---|---|---|
| record ID | Foundation persisted-record identifier | Unique, non-empty |
| account ID | Account owner | Required when account-scoped |
| payload | Test/probe payload only | Encrypted at rest; not product schema |
| version timestamp | Change-ordering input | Required UTC instant |
| sync state | Local-only, pending, acknowledged, conflict | Valid transition only |
| updated at | Audit timestamp | Required UTC instant |

Local Record is a Foundation verification entity, not a generic product-data container.

### Pending Change

| Field | Purpose | Validation |
|---|---|---|
| operation ID | Idempotency key for one remote effect | Globally unique and immutable |
| account ID | Owning account | Required |
| entity type and ID | Target record identity | Required; maps to owning feature |
| operation kind | Create, update, or delete intent | Explicit value |
| serialized change | Cloud-adapter input | Encrypted at rest |
| created at | Queue audit/order | Required UTC instant |
| attempt count | Retry observability | Non-negative |
| last failure | Recoverable failure summary | Contains no secret |
| acknowledgement ID | Remote acknowledgement | Immutable after acknowledgement |

State transitions:

~~~text
pending -> dispatching -> acknowledged
                    \\-> pending (recoverable failure)
                    \\-> conflict (remote version conflict)
~~~

An acknowledged operation is never dispatched again. A retry retains the same operation ID.

### Conflict Record

| Field | Purpose | Validation |
|---|---|---|
| conflict ID | Stable conflict identifier | Unique |
| account ID | Owning account | Required |
| entity type and ID | Conflicting record identity | Required |
| active version | Newest timestamp candidate | Required |
| retained version | Non-winning candidate | Required |
| local timestamp | Local ordering value | Required UTC instant |
| remote timestamp | Remote ordering value | Required UTC instant |
| status | Open or resolved | Open when created |
| detected at | Audit timestamp | Required UTC instant |

Distinct timestamps choose the newest candidate as active. Equal timestamps remain an open,
recoverable conflict until a tie-breaker is approved.

### Migration Journal

| Field | Purpose | Validation |
|---|---|---|
| migration version | Schema version attempted | Monotonic |
| status | Started, completed, failed, recovered | Valid lifecycle transition |
| timestamps | Start/completion audit | UTC instants |
| recovery detail | Non-secret recovery description | Present after failure/recovery |

A schema upgrade runs automatically. Failure retains prior database state and makes recovery visible;
it never silently resets account data.

### Failure State

| Field | Purpose | Validation |
|---|---|---|
| failure category | Persistence, migration, network, cloud, routing, configuration | Public category only |
| recoverability | Recoverable or blocking | Explicit |
| user message key | Localized message reference | Arabic and English resource exists |
| technical cause | Diagnostic data | No secret/credential |
| occurred at | Audit time | Required UTC instant |

## Relationships

~~~text
Application Preference ── owned by ── Foundation
Local Record ── may create ── Pending Change
Pending Change ── may produce ── Conflict Record
Migration Journal ── governs ── local database schema
Failure State ── describes ── Foundation boundary outcome
~~~

Credentials and database key material are outside this schema and belong to the OS-protected
storage adapter.
