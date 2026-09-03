# Synchronization Contract

## Dispatch Lifecycle

~~~text
local change + operation ID
          |
          v
durable local transaction
          |
          v
pending outbox operation
          |
          +-- offline/recoverable failure --> pending with retry metadata
          |
          +-- acknowledgement -------------> acknowledged (terminal)
          |
          +-- version conflict ------------> retained Conflict Record
~~~

## Idempotency

- Operation ID identifies exactly one logical cloud effect.
- A retry after interruption uses the unchanged operation ID.
- Repeated operation ID is a repeat of the same effect, not a second mutation.
- The local coordinator persists acknowledgement before completion.

## Conflict Rule

For distinct timestamps on the same record:

1. The newest timestamp becomes active locally.
2. The non-winning version remains a visible Conflict Record.
3. The outcome records that a conflict occurred.

Equal timestamps preserve both candidates and return recoverable conflict until a separately
approved tie-breaker exists.

## Environment Rule

- Automated tests use Firebase Auth and Firestore emulators under one demo project ID.
- Emulator state is reset between tests.
- Device integration uses an isolated non-production Firebase project.
- Automated tests never use production Firebase.
