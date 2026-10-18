# Data Model: Mind Maps 005

All persisted map records are scoped by `ownerId`. In debug preview the owner is the existing Tasks preview identity; in authenticated mode it is the verified Supabase account. IDs are stable UUIDs created locally. Each syncable row carries `updatedAt`, `deletedAt`/tombstone, a stable mutation ID or revision, and the existing Foundation reconciliation metadata. Timestamps choose the active version for the **same record**; equal-time conflicts use the existing deterministic Foundation tie rule and still retain the loser. No Task payload or XP is owned here.

## MindMap

| Field | Rule |
|---|---|
| `ownerId`, `mapId` | Composite local/remote identity; account checks on every query and mutation. |
| `title` | Trimmed, nonblank. Search title/description case-insensitively. |
| `description` | Optional text. |
| `centralNodeId` | Immutable reference to exactly one node created atomically with the map. |
| `settings` | Per-map layout (`radial`, `tree`, `horizontal`, `vertical`, `freeform`), canvas background, default node style, connection style, spacing. Validate supported enum/value ranges. Defaults affect new elements only. |
| `updatedAt`, `deletedAt`, revision | Version and tombstone for sync/conflict handling. |

Creation writes map and central node in one local transaction; failed creation leaves neither. The central node initially carries the map title but later map/title edits do not silently rewrite independently edited node content. Duplication creates new map, node, and relationship IDs in one transaction, remapping internal references; optional Task IDs remain unchanged. Deleting a map writes a map tombstone and hides its owned rows without touching Tasks. Search and list counts operate only on live maps and live nodes.

## MindMapNode

| Field | Rule |
|---|---|
| `ownerId`, `mapId`, `nodeId` | Stable identity; node belongs to one live map. |
| `kind` | `central`, `mainIdea`, `branch`, `task`, `note`; central identity is protected. |
| `title`, `description` | Trimmed nonblank title; optional description. |
| `x`, `y` | Finite saved canvas coordinates; freeform and manual movement use these. |
| `status`, `statusChangedAt` | Map-owned `notStarted`, `inProgress`, `completed` and the time of the last explicit map-status choice; linked Tasks override completed/open projection. |
| `priority`, `appearance` | Low/medium/high; color, icon, five specified shapes, small/medium/large node and text sizes. |
| `taskId` | Optional reference to one accessible existing Task; many nodes may share one Task ID. Never a foreign-key cascade to delete Task. |
| `updatedAt`, `deletedAt`, revision | Independent sync/conflict boundary. |

An unlinked task-kind node remains a map planning item. A linked node still owns its title/notes/style. Its visible completion is derived from the accessible Task: completed Task → completed; open Task → in progress only if the map status was explicitly set to `inProgress` after the Task's most recent completion/reopen transition, otherwise not started. An unavailable Task → unresolved/incomplete and no Task details. A linked node cannot be marked completed by merely changing map status; that command delegates to Tasks. Unlinking returns to the node's saved map status; it never changes the Task. The Tasks-owned link projection therefore needs a durable `completionChangedAt` (or equivalent Tasks-owned transition revision), updated only by completion/reopening. This is an additive Task record change in the same migration; unrelated Task title edits must not reset map progress.

The central node cannot be directly deleted or assigned a parent. Deleting a noncentral node tombstones the node, removes its side links, tombstones its own parent slot, and detaches children by tombstoning their parent slots. The children and their descendants remain live.

## ParentSlot

| Field | Rule |
|---|---|
| `ownerId`, `mapId`, `childNodeId` | Stable composite identity; at most one parent slot per child. |
| `parentNodeId` | Existing, live, distinct node in same owner/map when active. |
| `appearance` | Connection style copied from the map default on first creation; reparenting preserves the chosen style. |
| `updatedAt`, `deletedAt`, revision | Independent structural sync/conflict boundary. |

Creating a child creates a slot; reparenting replaces its parent ID in the same slot and preserves node/descendant IDs and content. Detaching tombstones the slot. A parent cannot be its own descendant. Automatic layout uses only active slots. A side link between the same unordered endpoints must not coexist visibly; validation covers both tables. A conflicting same-child reparent chooses the newest active slot and retains the other for review. On reconnect, structural validation also rejects or reconciles cycles and duplicate cross-role pairs under the same newest-wins/conflict-evidence rule; it never silently drops an operation.

## SideLink

| Field | Rule |
|---|---|
| `ownerId`, `mapId`, `firstNodeId`, `secondNodeId` | Sorted endpoint IDs form a deterministic identity for an unordered pair. Both nodes must be live in same map. |
| `appearance` | Explicit style or the map's default style copied on creation. |
| `updatedAt`, `deletedAt`, revision | Independent sync/conflict boundary. |

No self link and no duplicate visible pair in either direction or across ParentSlot/SideLink. Deleting a side link leaves node positions and parentage unchanged. Side links may form visual cycles and are excluded from layout traversal.

## Derived projections and session state

- **Map summary:** live node count, completed count, and `round(100 × completed / count)`; central node counts, so a valid map has a nonzero denominator. Use accessible live Task state for linked nodes; unavailable links count as incomplete.
- **Task projection:** `available(taskId, title, completed, completionChangedAt)` or `unavailable(taskId)`. The latter never includes foreign or stale Task details. Task picker lists only current-account accessible Tasks; authenticated picker waits for initial Task sync. Existing Tasks without the new transition field initialize it conservatively from their current completion state during migration; the field is then owned by Task completion commands and synchronization.
- **Connection projection:** one visible edge for each live ParentSlot or SideLink after endpoint/map validation; roles are explicit.
- **Editor history:** bounded in-memory reversible map-owned commands for the active editor session. Undo/redo uses current record versions, reports a recoverable conflict if stale, and excludes Task completion/XP. History is cleared on leaving the session or switching account; no requirement to persist it.
- **Conflict record:** reuse Foundation ConflictRecords with owner, entity type/ID, active version, nonwinning payload/version, timestamps, and visibility state. Show an account-scoped review entry for map/node/slot/link conflicts and deletion/edit races; never show another owner's Task details.

## Storage and transitions

Add four owner-qualified encrypted Drift tables in automatic v4→v5 migration with indexes for `ownerId + mapId`, live list/search, and relationship endpoints. Add the minimal Tasks-owned completion-transition field needed above in the same local/cloud migration. Preserve the previous database on migration failure and surface recovery. Add four equivalent Supabase record types with owner RLS, least-privilege grants, stable receipts, and restricted mutation functions. The existing PendingChanges outbox routes map, node, parent slot, and side link operations. Local data and outbox write atomically; remote application reconciles per record and retains conflict evidence atomically.

| Command | Required state | Result |
|---|---|---|
| Create map | Valid title/current owner | Map + central node, one local transaction. |
| Rename/edit settings | Live map | Only map record changes. |
| Add/edit/move node | Live map, valid node fields | One node record changes; add with parent also writes a slot. |
| Reparent/detach | Live endpoints, acyclic, no duplicate pair | One child's ParentSlot changes; descendants unchanged. |
| Add/remove side link | Live distinct endpoints, no visible duplicate | One deterministic SideLink changes. |
| Delete node | Live noncentral node | Node tombstone, incident link tombstones, child detaches atomically. |
| Duplicate map | Live source | New independent map graph; Task IDs refer to original Tasks. |
| Delete map | Confirmed live map | Map tombstone hides owned graph; Tasks untouched. |
| Complete/reopen linked Task | Accessible live Task | Tasks service changes Task/XP; map projection refreshes. |

All commands check current session owner again after asynchronous work, so a logout/account switch cannot apply a stale result. A map tombstone takes precedence over late descendants for visibility; their losing edits remain reviewable. Cloud commands serialize affected structural mutations per owner/map to enforce cycle, duplicate-pair, and same-owner invariants against the current graph. Receipt replay returns the original result without a second effect.
