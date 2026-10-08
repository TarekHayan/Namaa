# Task Synchronization and Security Contract

**Boundary:** Tasks domain calls application ports; data adapters implement encrypted Drift/SQLite and authenticated Supabase interactions. Existing Foundation sync rules and contracts/synchronization.md in feature 001 remain authoritative.

## Local commit and outbound delivery

1. A Task command validates ownership and data, then commits Task aggregate, optional first XP award, and a Foundation PendingChange in one encrypted local transaction.
2. The pending entry has stable operationId, accountId, entityType='task', entityId, operation kind, serialized aggregate/version, and UTC version timestamp. Checklist changes are Task changes; XP award is an effect of first completion, not an independently rewarded checklist operation.
3. Entity-type routing sends Foundation probe entries to the existing probe adapter and Task entries to a Task adapter. Unknown types fail recoverably and must not be acknowledged.
4. Retry reuses the same operationId. Remote application records a durable receipt keyed by authenticated account and operationId; success is acknowledged locally only after remote commit.
5. Deleted Tasks remain remote tombstones, and operation receipts survive deletion, preventing replay resurrection.

## Inbound multi-device reconciliation

After sign-in, initial Task synchronization fetches the authenticated account's Task records, tombstones, and immutable Task awards completely before reporting ready. It runs again on reconnect and Task entry/resume as needed; pages must be completed before marking a pass successful. Apply records to the local account partition without exposing or overwriting another account's partition. Pending local changes must be considered during merge, not discarded merely because a remote snapshot exists.

For competing Task versions, the newer UTC timestamp becomes active and the nonwinning version is retained as a visible Task conflict. Equal timestamps remain unresolved with both versions recoverable; no arbitrary winner is chosen. A deletion tombstone is a competing version under the same policy. Immutable XP awards merge by (accountId, source='task_done', taskId) key, with at most one award per Task lifetime. No clock tie-breaker, field merge, or Realtime requirement is added.

## Cloud transaction and access control

Supabase structures expose account-owned Task rows, XP awards, and operation receipts. Authenticated owner identity is derived from auth context for writes and reads. RLS and callable operations must allow an owner to read/change their own records and deny another account every Task/checklist/award/operation access. The completion operation and first XP award are committed atomically; repeat operationId or repeat award key cannot add another award. The Task domain does not import Supabase types, credentials, or SQL.

## Required security/integrity checks

- Owner account can create/read/edit/delete its own Task and award records; different account can perform none of those operations on them.
- Ten complete/reopen/complete cycles produce exactly one award; deleting rewarded Task leaves that award.
- Ten offline restart/reconnect trials preserve Task/checklist changes and yield no duplicate Task or award.
- Two-device create/edit/delete and initial sign-in pull converge under timestamp rules, including tombstones and retained loser.
- Equal timestamp competition remains recoverable, not silently overwritten.
- Local encrypted storage migration from Foundation v2 to v3 preserves existing data and recovers from failed migration.
- Tests use isolated nonproduction Supabase data and do not access production secrets.
