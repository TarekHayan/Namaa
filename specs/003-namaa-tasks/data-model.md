# Tasks Data Model

**Scope:** design contracts for feature 003, not a migration or implementation. Foundation v2 remains intact; the proposed additive Task migration is v3. See research.md for rationale and contracts/ for behavior at boundaries.

## Task (Tasks-owned aggregate)

| Field | Meaning and validation |
|---|---|
| id | Stable locally generated identifier; never recycled. |
| accountId | Authenticated owner partition, obtained from Foundation session; never accepted as cloud authority from client payload. |
| title | Trimmed, nonblank user text. |
| description | Optional user text. |
| scheduledDate | Required calendar date; new form defaults to device-local today. Store as date, not an inferred UTC instant. |
| scheduledTime | Optional local wall-clock time; does not alone make today's task overdue. |
| targetDeadline | Optional target date/time; overdue when passed according to approved date/deadline rule. Preserve enough timezone context to compare consistently across devices. |
| category | One of work, study, personal, health, spiritual, finance, other; default work. |
| quadrant | One of urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important; default urgent_important. |
| estimatedDurationMinutes | Positive duration when set; creation default 30. |
| checklistItems | Ordered Task-owned values described below; no independent canonical row or sync operation. |
| completedAt | Nullable UTC instant. Null means open; explicit completion sets it, explicit reopening clears it. |
| completionXp | Nonnegative reward snapshot configured for this Task; initial default 20 from verified prototype data when no shared setting is available. |
| createdAt, updatedAt | UTC instants. updatedAt is the Task version timestamp used by Foundation conflict handling. |
| deletedAt | Nullable UTC tombstone instant; deleting hides the active Task but retains sync identity. |

The Task row is scoped by (accountId, id). A local Task mutation writes the Task aggregate and a PendingChange together. Operations carry stable operationId and the version timestamp. A deletion produces a tombstone, not an ID reuse or immediate cloud erase. Checklist JSON is part of the versioned aggregate. Local query columns include date, category, quadrant, completedAt, updatedAt, and deletedAt so the views do not depend on network fetches or an unindexed JSON scan.

### Task state transitions

| Action | Result | XP effect |
|---|---|---|
| Create | Open Task, defaults unless user selected different supported values | None |
| Edit fields/checklist/move quadrant | Same Task ID, new version | None |
| Explicit complete when open | completedAt set | Insert first Task award if absent |
| Complete when already complete | No new completion event | None |
| Reopen | completedAt cleared | Existing award retained |
| Complete again | completedAt set anew | No new award |
| Delete | Versioned tombstone; not in active lists | Existing award retained |

Completing all checklist items alone has no parent transition. Incomplete items never block explicit parent completion.

## ChecklistItem (Task-owned value)

| Field | Meaning |
|---|---|
| id | Stable within the parent Task, permitting edit/reorder and deterministic display. |
| text | Nonblank step text. |
| completed | Boolean step state. |
| order | Stable order within parent. |

It has no independent account, schedule, category, XP, route, or outbox entry. Deleting the Task follows the parent tombstone. The Task ID plus item ID identifies an item.

## TaskCompletionAward (shared XP-owned)

| Field | Meaning |
|---|---|
| accountId | Authenticated owner partition. |
| source | Fixed source key task_done. |
| sourceId | Task ID; key remains valid after Task deletion. |
| amount | Task's completionXp snapshot on first explicit completion. |
| awardedAt | UTC first-award instant. |

Uniqueness is (accountId, source, sourceId). Award is immutable and never deleted on Task reopen/deletion. Derived XP sums this shared ledger; the Task domain does not maintain a second balance. Local Task completion and first award insert are atomic. Remote application of the same operation creates at most one award even on retry or another device.

## TaskPendingChange (Foundation-owned outbox entry)

Existing PendingChanges fields identify operationId, accountId, entityType='task', entityId, operation kind, serialized aggregate/change, and version timestamp. Its local write is atomic with Task/award effects. The existing coordinator retains retry, ack, and conflict behavior; Task transport must understand this entity type. No separate checklist or XP outbox operations are required for a Task completion.

## TaskConflictRecord (Foundation-owned conflict entry)

Retains the nonwinning Task aggregate and metadata, linked to accountId and Task ID, for visible review. Newest timestamp selects active version. Equal timestamps do not silently select either competing version; both remain recoverable unresolved. A tombstone can be active or nonwinning under the same policy. Award ledger merging is by immutable key, not mutable Task conflict choice.

## Remote records and ownership

The remote Task record carries account owner, Task ID, aggregate fields/payload, version timestamp, and tombstone. Remote XP award uses the immutable key above. A durable Task operation receipt stores (account, operationId) and result even when a Task is deleted, so retries are idempotent. Supabase policy and callable-operation checks derive account ownership from the authenticated session; a client-provided accountId is not authorization. Initial and incremental reconciliation fetch account-scoped Task records including tombstones and Task awards; pages must be complete before initial sync is considered complete.

## Derived projections (not canonical data)

- Today: open Tasks whose scheduledDate is today under the chosen local calendar.
- Urgent: open Tasks in urgent_important or urgent_not_important quadrants, matching the prototype.
- All: all nondeleted Tasks, including completed ones, matching the prototype; category filter narrows the same query/projection.
- Completed/history: completed, nondeleted Tasks with completion time.
- Matrix: same open, nondeleted Task identities grouped by quadrant.
- Overdue: open, nondeleted Task where scheduledDate is earlier than today or targetDeadline has passed; scheduledTime passing today alone does not qualify.

These are views of the Task aggregate, not separately persisted copies. No recurrence, habit, Mind Map, or Today-domain model is introduced.
