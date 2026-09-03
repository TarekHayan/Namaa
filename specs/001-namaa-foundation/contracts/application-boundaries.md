# Application Boundary Contracts

Concrete Firebase, Drift, secure-storage, and platform implementations remain outside Domain code.

## Local Store Port

| Operation | Input | Outcome |
|---|---|---|
| read preference | key | supported preference or fallback |
| save preference | validated key/value | durable local result |
| commit local change | record change plus pending change | atomic durable result |
| read pending changes | account scope | ordered pending operations |
| acknowledge change | operation ID and acknowledgement | durable acknowledged state |
| record conflict | two versions of one record | visible conflict record |
| run migration | target schema version | completed or recoverable failure |

Commit is atomic: a visible local state change cannot exist without its required pending change.

## Cloud Session Port

| Operation | Outcome |
|---|---|
| initialize cloud environment | ready, recoverable failure, or configuration failure |
| observe session state | session snapshot without Firebase SDK types |
| obtain authorized sync context | non-secret context or recoverable failure |

This contract defines no authentication UI or account workflow.

## Cloud Sync Port

| Operation | Input | Outcome |
|---|---|---|
| dispatch change | stable operation ID and account-scoped change | acknowledgement, recoverable failure, or remote version |
| obtain remote version | entity identity | absent, version, or recoverable failure |

Repeated dispatch of the same operation ID is one logical effect. Firebase SDK types do not cross
this boundary.

## Credential Vault Port

| Operation | Outcome |
|---|---|
| read protected secret | secret, controlled absence, or failure |
| write protected secret | durable protected result |
| delete protected secret | durable deletion result |

Only keys and credentials use this port. They are never logged or serialized into Failure State.

## Presentation State Contract

| State | Required content |
|---|---|
| startup | bootstrap progress without product data |
| ready | locale, theme, root-route readiness |
| recoverable failure | localized message key and retry availability |
| blocking failure | safe diagnostic outcome with no secret |

Cubits call application use cases; they do not access Drift, Firebase, or secure storage directly.
