# Contract: Mind Map local persistence and account synchronization

## Local mutation and inbound flow

1. Resolve the current Foundation session owner. All Drift reads/writes include owner and map scope; account switch invalidates pending UI commands.
2. In one encrypted Drift transaction validate graph invariants, write changed map/node/parent/side records and tombstones, and queue stable-ID PendingChanges operations. A failed transaction keeps the previous confirmed state.
3. Show local state immediately. Retry the existing Foundation outbox without waiting for connectivity; duplicate delivery of an operation returns the original receipt.
4. For a real account, fetch **all pages** of maps, nodes, parent slots and side links plus tombstones and conflict evidence. Reconcile each record independently, applying active winner and visible loser in one local transaction. Initial map sync is complete only after all four streams succeed; a partial failure remains retryable.
5. Before applying async responses, recheck the session owner. Preview uses only the local Tasks preview identity and no cloud adapter.

## Cloud authorization and graph invariants

- Supabase rows use composite account ownership and RLS. A signed-in user can read only their own rows/conflicts/receipts; signed-out access is denied. Client gets publishable key only. Direct table mutation grants are restricted; authenticated RPC commands derive owner from `auth.uid()` and never trust a supplied owner.
- Privileged functions pin `search_path`, restrict execution grants, and validate referenced map/nodes belong to that owner. A **new** Task link requires an accessible owner Task; editing or copying a node that already holds an unavailable Task ID may preserve that ID without exposing Task details. Structural commands serialize changes for one owner/map in a transaction, enforce at most one parent per child, reject self/ancestor cycles, and prevent a visible duplicate pair across parent and side roles.
- Stable record identities: map ID, node ID, parent slot by child ID, and unordered side pair by sorted endpoints. Stable mutation receipts make replay idempotent. Concurrent same-record edits use newest-timestamp active version and retain the other, including equal-time ties and deletion/edit races.
- Map tombstone hides all descendants; a later node/relationship edit becomes reviewable conflict evidence and cannot resurrect it. Node tombstone hides incident edges; child detaches remain explicit. Server and local reconciliation verify endpoint/owner integrity before showing edges.
- A competing reparent of the same child conflicts on one ParentSlot; independent node edits still merge. Concurrent side/parent creation for the same pair is resolved under the structural transaction and loser retained visibly, never left as two rendered edges.

## Verification boundary

Local Supabase SQL tests cover owner RLS, signed-out denial, foreign endpoint/Task rejection, cycle and duplicate pair rejection, receipt replay, equal-time conflicts, map/node deletion races, and no cross-account conflict disclosure. Flutter integration tests cover encrypted v4→v5 migration/recovery, offline restart, two-device independent-node edits, same-node loser visibility, task link/XP consistency, and preview/account isolation. The existing five-target CI workflow remains triggered by PR to `develop` or manually, not by every feature-branch push.
