# Contract: Mind Maps ↔ Tasks 003

Mind Maps depends on an application-level `MapTaskLinkPort`; it does not import Tasks presentation or Tasks storage adapters. The bridge adapts the existing `TaskRepository`, `TaskCompletionService`, and `TaskSyncService`. Tasks remains the canonical Task/XP owner.

## Port behavior

| Operation | Required behavior |
|---|---|
| `watchAccessibleTasks(expectedOwner)` | Emit only live Tasks returned for the current owner; cancel/clear on session change. On authenticated first use, run/observe initial Task sync before presenting a complete picker. |
| `readLinkedTask(expectedOwner, taskId)` | Return available Task ID/title/completion/transition revision or unavailable; never return another owner's Task details. |
| `complete(expectedOwner, taskId)` | Call `TaskCompletionService.completeTask(taskId, expectedAccountId: expectedOwner)` and let its atomic Task/XP unit of work decide the first award. Trigger normal Task sync for real accounts; update all map projections from Task repository stream. |
| `reopen(expectedOwner, taskId)` | Call `TaskCompletionService.reopenTask(...)`; trigger normal Task sync and refresh all linked projections. No XP reversal or new award. |

Tasks adds a durable completion-transition timestamp/revision to its own record, updated only on completion/reopening and synchronized with the Task. Existing Task rows migrate to a sensible baseline (`completedAt` for completed rows; creation time for open rows). The map node stores its own `statusChangedAt`; an open linked Task shows `inProgress` only when the user's map status choice follows the latest Task completion transition. This preserves the explicit rule that reopening shows not started while unrelated Task metadata edits do not reset progress. The bridge exposes this Task-owned revision; Mind Maps never writes it.

## Invariants to verify

1. One Task may be linked from multiple nodes and maps. Link/duplicate/unlink/delete cannot create, delete, complete, or award it.
2. Completing from any linked node, reopening from Tasks, and completing again yield the same Task state in every view and one lifetime Task completion award.
3. A task-kind node with no link is map-owned only; completing its map status does not award Task XP.
4. Missing/deleted/foreign Task references show unavailable without leaking title/details; the user can unlink or choose an accessible Task.
5. A preview map can link existing preview Tasks because both share `TasksPreviewSession` identity. Preview never synchronizes to a real account and is disabled in release.
6. A failed or stale-session Task command leaves the linked map view on the confirmed Task state and presents a localized recoverable error.
