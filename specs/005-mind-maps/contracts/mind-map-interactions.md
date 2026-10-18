# Contract: Mind Map interactions

This is the Flutter application/UI contract for `specs/005-mind-maps/spec.md`. All commands take the current session owner as a trusted application input; caller-provided owner IDs never authorize access. Results return a localized success/failure state and confirmed local graph projection, not an optimistic state left visible after a failed save.

## Entry and queries

- The existing app navigation exposes a visible **Mind Maps** entry and an owner-gated route. Debug Tasks preview opens it without login using the Tasks preview identity; release mode follows existing authenticated session gating and does not create an Auth screen.
- `watchMaps(owner, searchText)` returns live maps ordered consistently, with title, description, node count, completed count, and whole-percent progress. Search is case-insensitive over title/description. Empty library and empty results have different localized messages.
- `watchMap(owner, mapId)` returns a live map graph, visible conflict notices, derived Task state, pending/sync/error state, and a recoverable not-found state. Account changes cancel the previous stream and clear editor history.
- `watchTaskChoices(owner)` returns accessible Tasks only. On a real account the chooser shows initial-sync loading/failure/retry until Tasks initial sync completes; preview reads its local Tasks immediately.

## Commands and validation

| Command | Contract |
|---|---|
| `createMap(title, description)` | Trim title; reject blank; atomically create map and central node; open new map after confirmed local save. |
| `renameMap`, `editDescription`, `editSettings` | Change only map record. Layout is one of radial/tree/horizontal/vertical/freeform; appearance defaults apply only to future elements. |
| `duplicateMap(mapId)` | New IDs for map-owned graph; retain Task IDs; do not create/complete/reward Tasks. |
| `deleteMap(mapId)` | Show confirmation; tombstone map and hide graph; cancellation changes nothing. |
| `addNode(kind, title, parent?)` | Validate title and optional live parent; create a visible branch-parent connection when parent supplied. Central node is creation-only. |
| `editNode`, `moveNode`, `setNodeStatus` | Validate finite position/style/status, live node, and owner. For a linked node, `completed` delegates to Task completion; `inProgress` is map-owned only while Task is open. |
| `deleteNode(nodeId)` | Reject central node; remove incident connections, detach children, leave children and Tasks intact. |
| `reparent(childId, parentId)`, `detach(childId)` | Preserve child and descendants; reject self/descendant parent and duplicate visible pair; remove previous parent edge as part of one command. |
| `addSideLink(a,b)`, `removeConnection(a,b)` | Reject self/cross-map/duplicate pair. Removal dispatches by actual role; removing parent edge detaches child, side removal changes only side link. |
| `applyLayout`, `fit`, `center`, `pan`, `zoom` | Automatic layouts use parent slots only and save resulting positions/selection as specified; side links remain visible. Viewport-only navigation does not mutate map data. |
| `linkTask(nodeId, taskId)`, `unlinkTask(nodeId)` | Link one accessible existing Task to node or clear reference; never copy/mutate Task. Missing link stays repairable. |
| `completeLinkedTask`, `reopenLinkedTask` | Delegate through Task bridge, then refresh all linked projections; not part of map undo/redo. |
| `undo`, `redo` | Reapply only current-session map-owned commands if base versions still match. Show a recoverable conflict if another update makes inversion unsafe; never replay Task/XP state. |

All local commands must commit their changed records and pending sync operations atomically before emitting success. Invalid commands leave the confirmed graph unchanged. Network failure does not block local editing. Deletion/edit or concurrent structural conflicts surface a reviewable nonwinning version.

## Editor behavior

Every core action has a labeled visible control or menu item, usable with touch and keyboard. Canvas supports drag reposition, pan, zoom, fit, center, selection, and focus; connection endpoints remain discernible at usable zoom levels. Show all five layout choices. For Arabic, mirror directional placement/affordances where appropriate while preserving graph identity and readable mixed-direction text. Text, validation, failures, status and semantics come from Arabic/English ARB resources. The later UI Refinement phase may change colors and composition without changing this contract.

## Progress and unavailable Tasks

Count all live nodes, including the central node. Count a linked node as completed only if its accessible Task is currently complete; unavailable links count incomplete. Unlinked nodes use map-owned status. A reopened Task resets linked visible completion to not started; users may explicitly set in progress after that transition. Multiple links to one Task update from the same Task stream. Unavailable projections show a generic explanation, no cached title/details, and unlink/relink actions.
