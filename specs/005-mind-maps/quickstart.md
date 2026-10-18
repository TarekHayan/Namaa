# Quickstart validation: Mind Maps 005

This is a runnable validation guide for the **future implementation**. The plan artifacts alone do not make these flows available yet. Use `specs/005-mind-maps/spec.md`, `data-model.md`, and the three `contracts/` files for expected behavior. No production account or production Supabase project is needed for local SQL tests.

## Prerequisites and basic checks

From the repository root, use the project's pinned Flutter toolchain and dependencies:

~~~powershell
flutter pub get
flutter analyze
flutter test --no-pub
~~~

Run the existing local Supabase stack and its database tests when the Mind Maps migrations/tests have been implemented:

~~~powershell
supabase start
supabase test db
~~~

Use an isolated nonproduction Supabase project only for authenticated device synchronization. The full five-target CI matrix remains a manual run or a PR-to-`develop` gate, not a feature-branch push gate. `dart format --output=none --set-exit-if-changed lib test integration_test` checks formatting without changing files.

## Local preview without signing in

On Windows, for example:

~~~powershell
flutter run -d windows --dart-define=NAMAA_TASKS_PREVIEW=true
~~~

Open Tasks and create a preview Task. Open Mind Maps from the visible app entry. Create two maps; each starts with a central node. Add a main idea, branch, note, and task-kind node; link one node to the existing preview Task. Rename/search/duplicate/delete a map. Restart offline: the surviving map and graph remain, the duplicate has independent map-owned elements, and both linked nodes refer to the same Task. Confirm preview remains unavailable in release configuration.

## Graph and editor walkthrough

Create a 50-node/60-connection map including parent branches and visual side links. Reparent a branch with descendants, then detach it. Both operations preserve descendant content; detached branches remain independent when applying radial, tree, horizontal, and vertical layouts. Add a side-link cycle: it stays visible but does not affect layout. Apply freeform and move nodes. Pan, zoom, fit, center, select, and edit a node on one mobile and one desktop target; each confirmed offline action should appear within the SC-005 two-second threshold. Check self-link, duplicate-pair, descendant-parent, blank-title, and central-delete rejection. Use undo/redo for map-owned edits and verify a linked Task's completion is not undone.

Use only labeled visible controls for the SC-007 touch and keyboard walkthrough: create map, add child and note, link Task, identify progress. Repeat primary flows in Arabic and English, checking RTL and mixed-direction labels.

## Task authority and reward

Link the same Task from two nodes in separate maps. Complete from Mind Maps, reopen in Tasks, set one linked node in progress, then complete again from Tasks. Every linked view follows the same Task completion state. Reopening displays not started until in progress is explicitly chosen again. The Task completion XP award exists exactly once for the Task lifetime. Linking/unlinking/duplicating/deleting maps and completing an unlinked task-kind node add no Task XP. Delete or make a linked Task unavailable: the node remains, shows no Task details, counts incomplete, and offers unlink/relink.

## Offline, sync, and account separation

For an isolated test account, finish initial account sync, then edit different nodes of one map offline on two devices. Reconnect: both edits survive. Repeat with competing edits to the same node: newest active version displays, losing version is reviewable. Try concurrent reparent/side-link and deletion/edit cases: visible graph invariants hold and the loser remains reviewable. Retry outbound operations; no duplicate elements or XP appear. Switch to a second account and signed-out state: zero foreign maps, nodes, links, Task details, or conflicts appear. Preview data remains separate from both real accounts.

Run the affected integration tests on Android, iOS, Windows, macOS, and Linux before merging to `develop`. Record the actual test command/results and any target limitation in the implementation review; the planning stage claims no device execution.
