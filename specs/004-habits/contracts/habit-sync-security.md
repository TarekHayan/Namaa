# Habit Synchronization and Security Contract

**Scope:** account ownership, durable local writes, remote retry, inbound reconciliation, and deletion for 004. This is the feature contract for implementation; it does not authorize a new authentication flow.

## Local transaction and outbox

1. Resolve the active account before accessing Habits. Every local Habit/HabitDay query includes that account; the preview account is a separate non-release partition.
2. Create, edit, complete, undo, or delete writes the owning record and a Foundation PendingChange in one encrypted transaction. A failed transaction reports failure and preserves the last confirmed state.
3. Pending entries use stable operation IDs, account ID, entity type habit or habit_day, entity key, operation kind, serialized version, and UTC timestamp. Retrying reuses the same operation ID.
4. HabitDay identity is account + Habit ID + immutable local date. Two different dates synchronize independently. Duplicate completion of the same date cannot create two rows.
5. Outbound dispatch registers both entity types in the existing router. An unsupported type remains pending with a recoverable failure rather than being acknowledged.

## Remote mutation boundary

Remote Habit and HabitDay rows are account-owned. Reads allow only the authenticated owner under RLS; direct authenticated writes and receipt reads are denied. Mutation operations derive owner exclusively from the authenticated context, validate payload shape, entity identity, date and parent ownership, then commit a row version and an operation receipt atomically. The receipt is keyed by owner and operation ID and survives tombstones, so a retry returns the original result.

The parent Habit must belong to the same owner as HabitDay. A day mutation for a missing or deleted parent cannot create an active orphan. A day change racing with a parent deletion remains recoverable conflict evidence linked to both identities; it does not silently revive a deleted Habit. Competing Habit metadata update/delete versions use newest UTC timestamp; the nonwinning version is retained. Equal timestamp competition remains unresolved and visible until a separate product rule exists.

## Inbound account reconciliation

After initial sign-in, reconnect, or Habits entry, send pending operations and then read all owner-scoped Habit records, tombstones, and HabitDay pages. Check that the session account has not changed after every asynchronous boundary. Do not report the account's Habit sync as ready until every required page is fetched and applied; a partial page failure leaves a recoverable sync status and existing local data usable.

Apply Habit metadata before day records, but never delete local pending operations merely because the remote snapshot differs. For competing versions of the same entity, newest UTC timestamp is active and the loser is retained in Foundation ConflictRecords. Equal timestamps do not choose an arbitrary winner. A local reconciler applies the winning Habit or HabitDay row atomically with conflict evidence; the generic outbox conflict recorder alone does not update product rows. Parent tombstones hide child history from active queries while retaining records for replay and conflict recovery.

A repeated remote HabitDay row for the same account, Habit ID, and date updates that one local identity. Independent days remain independent. A completion earned while due keeps its recorded eligibility after a same-day schedule edit on any device. The original localDate and offset evidence are preserved across devices.

## Access and integrity checks

- Owner can create/read/edit/delete own Habit metadata and days through approved boundaries; a different account can do none of those operations or view the conflict evidence.
- Direct writes and receipt reads from authenticated/anonymous clients are denied; no secret or service-role key is shipped in a client.
- Replaying the same operation ten times yields one receipt effect. Completing the same day from two devices yields one active HabitDay identity.
- Two devices completing different dates offline retain both dates after sync. Conflicting complete/undo of one date selects the newest version and exposes the loser.
- Habit metadata edit/delete race and HabitDay/delete race retain nonwinning evidence. Tombstones and receipts prevent stale retries from resurrecting hidden history.
- A full inbound pass includes the last page and all tombstones before ready. A failed page, changed session, or local write failure must not expose another account or report false success.
- Local migration from encrypted v3 to v4 preserves prior Foundation, Task, XP, preferences, and outbox data; injected failure is recoverable without destructive reset.
- SQL/RLS tests use the local Supabase stack. Device integration before release uses an isolated non-production project; production secrets are never used.

