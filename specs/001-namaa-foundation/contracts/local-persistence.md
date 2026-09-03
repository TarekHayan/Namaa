# Local Persistence Contract

## Encryption and Secret Handling

1. Every account-scoped row is in the encrypted local database.
2. The encryption key comes from Credential Vault before database opening and is never stored in a
   preference, table, log, or failure record.
3. If key access fails, emit a blocking recoverable failure; do not create an unencrypted
   replacement database.

## Transaction Guarantees

- A local change and its required pending synchronization operation commit together.
- A failed transaction changes neither visible local state nor the outbox.
- An acknowledged operation cannot return to pending.
- A retry preserves operation ID.

## Migration Guarantees

- Migrations run automatically before account data is served.
- Before a destructive step, the migration path preserves recoverable prior state.
- A failed migration retains prior data and writes a non-secret Migration Journal outcome.
- The user-visible result is recoverable failure, never a silent reset.
