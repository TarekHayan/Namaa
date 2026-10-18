# Feature Specification: Mind Maps

**Feature Branch**: namaa/005-mind-maps
**Created**: 2026-10-18
**Status**: Draft
**Input**: Begin Mind Maps as the next Namaa feature using Spec Kit. Keep authentication for later, make this feature directly usable in the development preview, and defer the final visual design.
**Sources**: Namaa plan §§6, 18–20, 24, 26–27; Constitution v2.0.1; the adjacent prototype's Mind Maps types, view, editor, and behavior; Tasks 003 specification and interaction contract; Habits 004 preview boundary. The prototype's direct Task and XP writes do not override the approved single Task and XP authorities.

## Clarifications

### Session 2026-10-18

- Q: If different nodes in the same map are edited offline on two devices, should both edits survive synchronization? → A: Yes. Merge edits to different nodes; only competing edits to the same node conflict. For that node, the newest version is active and the other remains reviewable.
- Q: If the connection between a child branch and its parent is removed, should the child remain attached in later layouts? → A: No. Removing that connection detaches the child from its parent; the child remains in the map as an independent node.
- Q: Should a manually added connection between unrelated nodes affect automatic layout? → A: No. It is a visible side link only; automatic layouts follow parent-child relationships.
- Q: Should an existing branch be movable under a different parent without recreating it? → A: Yes. Change its parent directly while preserving the branch's content and descendants, and reject a move that would create a parent-child cycle.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Organize maps (Priority: P1)

As a user, I can create a named mind map, find it later, change its details, copy it, or delete it so I can keep several projects and ideas organized.

**Why this priority**: A persistent map and a way to reopen it are the smallest useful Mind Maps experience.

**Independent Test**: In the local development preview, create two maps, rename one, search by title and description, duplicate the other, delete one after confirmation, restart offline, and verify the remaining maps and their content.

**Acceptance Scenarios**:

1. **Given** no maps, **When** the user saves a nonblank title and optional description, **Then** one map opens with a central node bearing that title, and the map is listed after leaving the editor.
2. **Given** a blank or whitespace-only title, **When** the user tries to create or rename a map, **Then** no change is saved and a localized explanation appears.
3. **Given** several maps, **When** the user searches by text in a title or description, **Then** only matching maps appear; clearing the search restores the list.
4. **Given** a map with nodes, connections, settings, and a Task link, **When** the user duplicates it, **Then** a separately editable copy appears with its own nodes and connections while the Task link still refers to the same real Task.
5. **Given** a map, **When** the user confirms deletion, **Then** that map and its map-owned content disappear without deleting any linked Task; canceling leaves everything unchanged.

---

### User Story 2 - Build and track an idea graph (Priority: P1)

As a user, I can add and arrange main ideas, branches, task-type nodes, and notes, connect them, and mark their progress so the map shows how my work fits together.

**Why this priority**: Nodes, connections, statuses, and progress are the core value in the plan and prototype.

**Independent Test**: Create a map, add each node type, add and remove connections, change a node's content and status, reposition it, and verify the graph and progress after restart.

**Acceptance Scenarios**:

1. **Given** a new map, **When** the user adds a main idea, child branch, task-type node, and note, **Then** each appears as a distinct editable node; a child has a visible connection to its parent.
2. **Given** two different nodes, **When** the user connects and later disconnects them, **Then** only that connection changes. If it was a parent-child connection, the child becomes independent in later layouts. A self-connection or a second connection for the same pair is not created.
3. **Given** an ordinary map node, **When** its status changes among not started, in progress, and completed, **Then** its visible status and the map's completed-node count and percentage update from the current nodes.
4. **Given** a movable node, **When** the user changes its position, **Then** the node and its attached connections use the saved position after reopening the map.
5. **Given** a noncentral node with child branches and other connections, **When** the user deletes it, **Then** its connections are removed, its children remain as independent nodes, and the central node remains available.
6. **Given** a map edit made during the current editor session, **When** the user undoes and redoes it, **Then** the relevant map-owned content returns to the preceding and subsequent state without directly changing a real Task or its XP.
7. **Given** a node title containing only spaces, **When** the user tries to save it, **Then** the old title remains and a localized validation message appears.
8. **Given** an existing branch with descendants, **When** the user moves it under another valid parent, **Then** the old parent connection is replaced, the branch and its descendants keep their content and identity, and the next automatic layout follows the new parent.

---

### User Story 3 - Work with real Tasks from a map (Priority: P1)

As a user, I can link a map node to an existing Task and complete or reopen that Task from either area while seeing one consistent Task state and one lifetime completion reward.

**Why this priority**: The plan explicitly makes a node-to-Task relationship shared, and Tasks 003 defines the authoritative completion and XP rules.

**Independent Test**: Link two nodes in separate maps to the same Task. Complete it from one map, reopen it from Tasks, complete it again from the other map, restart and synchronize, then verify all views and exactly one lifetime Task XP award.

**Acceptance Scenarios**:

1. **Given** an existing Task belonging to the current account, **When** the user links it to a node, **Then** the node identifies the current Task and reflects its completion state without creating a second Task.
2. **Given** an open linked Task, **When** the user completes its linked node, **Then** that Task becomes complete in Tasks and every linked map node; its first completion awards the configured Task XP once.
3. **Given** a linked Task completed earlier, **When** the user reopens it from the map and completes it again from Tasks, **Then** all linked views agree and no second XP award is recorded.
4. **Given** a Task completed or reopened in Tasks, **When** any map containing a linked node is viewed, **Then** its completion and map progress reflect the Task's current state.
5. **Given** a completed Task, **When** the user links it to another node or duplicates its map, **Then** those nodes appear completed without earning additional XP.
6. **Given** a link to a Task that has been deleted or is unavailable to the current account, **When** the map opens, **Then** the node remains, the link is visibly unavailable, Task details are not exposed, and the user can unlink or choose an accessible Task.

---

### User Story 4 - Adjust how a map is viewed (Priority: P2)

As a user, I can switch among map layouts, move around a large map, and change map or node appearance so the graph remains understandable on phone and desktop.

**Why this priority**: The prototype includes several layouts and settings, and a visual graph needs basic navigation to be usable.

**Independent Test**: In a map with several nodes and connections, apply each layout, change appearance settings, manually move a node, zoom and fit the graph on mobile and desktop, then reopen the map and verify saved choices.

**Acceptance Scenarios**:

1. **Given** a multi-node map with both branches and manual side links, **When** the user applies radial, tree, horizontal, vertical, or freeform layout, **Then** parent-child relationships determine automatic placement, side links remain visible without affecting placement, and no node, connection, status, or Task link is lost.
2. **Given** a map, **When** the user changes its background, default node appearance, connection appearance, or spacing, **Then** the saved choices are applied to that map without changing other maps.
3. **Given** a node, **When** the user edits its title, optional description, priority, color, shape, size, text size, or icon, **Then** the node shows the saved choice without changing unrelated nodes.
4. **Given** a large map, **When** the user pans, zooms, centers, or fits the content, **Then** they can reach and identify every node on both touch and pointer/keyboard devices without modifying map content.

---

### User Story 5 - Continue safely across sessions and devices (Priority: P2)

As a user, I can keep editing a map without a connection, reopen it after a restart, and later see the same account's changes on another device without exposing another account's maps.

**Why this priority**: Namaa's approved local-first and account-integrity rules apply to every account-owned feature.

**Independent Test**: Edit maps and linked Task state offline, restart, reconnect two devices under one test account, verify retained content and Task consistency, then verify a different account cannot access either account's maps or links. Repeat the local journey in the separate development preview without signing in.

**Acceptance Scenarios**:

1. **Given** the development preview, **When** the user enters Mind Maps without signing in, **Then** they can use the local feature, link its nodes to existing preview Tasks, and keep all preview data separate from real account data.
2. **Given** a map open offline, **When** the user saves an edit, **Then** it appears immediately and remains after restart without waiting for a network response.
3. **Given** a real account on two devices, **When** the devices reconnect after edits to different nodes in one map, **Then** both edits survive without duplicate maps, nodes, connections, or Task rewards; competing edits to the same node leave a recoverable nonwinning version.
4. **Given** another account or a signed-out session, **When** it attempts to view or change a map or follow a Task link, **Then** no data from the first account is disclosed or modified.

### Edge Cases

- New maps have one central node. It cannot be deleted directly; deleting the entire map is a separate confirmed action.
- A task-type node without a link is a map-owned planning item. It does not create, complete, or award XP for a real Task.
- A linked node may be marked in progress while its Task is open; only completed versus open is shared with Tasks. Completing or reopening the Task from Tasks overrides the linked node's completed/open display.
- A Task may be linked from multiple nodes or maps. Each reads the same Task identity and completion; copying a map never copies the Task.
- An unavailable linked Task remains visibly unresolved and counts as incomplete for map progress until the link is removed or repaired. Another account's Task title or details are never shown.
- Removing a parent-child connection makes the child independent for later layouts without deleting either endpoint. Deleting a node removes its incident connections and detaches its children, but keeps those children and any real linked Tasks.
- A manually added side link does not create parenthood. Even if side links form a cycle, they stay visible and do not change automatic node placement.
- A branch has at most one parent. Moving it under itself or one of its descendants is rejected without changing the graph; its visual side links remain intact when its parent changes.
- Progress is the number of currently completed nodes divided by current nodes, rounded to a whole percent; the central node counts.
- Map appearance defaults affect subsequently added nodes and connections; they do not silently restyle existing elements. Freeform layout preserves manually chosen positions.
- Undo/redo of map-owned edits does not reverse linked Task completion. The user reopens or completes the Task through the normal linked-Task action.
- Failed local saves retain the last confirmed state and show a localized explanation. Competing same-element edits and deletion/edit races retain a visible nonwinning version under the approved conflict rule.
- Offline edits to different nodes of one map must both survive reconciliation. Only competing changes to the same node select the newest active node and retain its nonwinning version for review.
- Arabic, English, long labels, mixed-direction text, large maps, touch gestures, keyboard use, and mobile/desktop switching must keep labels and connections understandable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create, open, rename, describe, duplicate, and delete multiple mind maps. A nonblank title is required. Creation MUST include one central node, and deletion MUST require confirmation and affect only that map's owned data.
- **FR-002**: The map list MUST support case-insensitive searching of titles and descriptions and distinguish no maps from no search results. It MUST show each map's title, current node count, completed-node count, and progress.
- **FR-003**: A map MUST support main idea, branch, task-type, and note nodes. Users MUST be able to add, edit, reposition, and delete noncentral nodes. Each node requires a nonblank title and MAY have a description, priority, status, and appearance choices. The original central node MUST be protected from direct deletion.
- **FR-004**: Users MUST be able to connect and disconnect two distinct nodes in the same map. A child branch MUST connect to its selected parent when created, and MAY later be moved directly to a different parent while preserving its content, identity, and descendants. A branch MUST have at most one parent; self-parenting and descendant-parenting MUST be rejected. Disconnecting a parent-child pair MUST remove the parent relationship, leaving the child independent in later layouts. Manually added links between unrelated nodes MUST remain visual side links and MUST NOT create parenthood. The same pair MUST NOT gain duplicate connections in either direction. Deleting a node MUST remove its incident connections and detach, but not delete, its children.
- **FR-005**: Map-owned nodes MUST support not started, in progress, and completed status. The map's completed count and whole-percent progress MUST be derived from all current nodes, including the central node, using current linked Task completion where applicable. Unavailable linked Tasks MUST NOT be misreported as complete.
- **FR-006**: Users MUST be able to apply radial, tree, horizontal, vertical, and freeform layouts, manually position nodes, and navigate via pan, zoom, center, and fit-to-content. Automatic placement MUST follow parent-child relationships only; visual side links MUST remain visible but MUST NOT influence placement. Applying a layout MUST preserve node identity, content, statuses, links, and connections.
- **FR-007**: Map settings MUST cover canvas background, default node appearance, connection appearance, spacing, and selected layout. Individual nodes MUST support low/medium/high priority; rounded, rectangle, circle, pill, and glass shapes; small/medium/large node and text sizes; and available color and icon choices. Saved choices MUST remain scoped to the edited map or node.
- **FR-008**: The editor MUST offer undo and redo for map-owned node, connection, layout, and settings edits in the current editing session. Linked Task completion is excluded and MUST be changed through the normal Task completion/reopening action; undo/redo MUST NOT replay stale Task state or XP.
- **FR-009**: A map node MAY link to one existing Task accessible to the current account; one Task MAY be linked from multiple nodes or maps. A task-type node without a link remains map-owned and MUST NOT create a Task implicitly. Linking, unlinking, duplication, or map deletion MUST NOT create, delete, or duplicate the real Task.
- **FR-010**: Completing or reopening a linked Task from a map MUST use the same Task behavior as the Tasks area. Completing or reopening in either area MUST update every linked view. The Task domain MUST remain the sole authority for Task completion and the existing one-time Task XP award; map operations MUST NOT award Task XP independently.
- **FR-011**: If a linked Task is missing, deleted, or inaccessible, the node MUST remain available as map content, visibly identify the link as unavailable without revealing foreign-account Task details, avoid changing any Task or XP, and allow unlinking or relinking to an accessible Task.
- **FR-012**: Map creation, editing, duplication, deletion, and link changes MUST persist locally, update visible state promptly, remain usable offline, and synchronize for a real account when connectivity returns. Repeated delivery MUST NOT duplicate maps, nodes, edges, or Task effects. A local save failure MUST preserve a recoverable prior state and explain the failure.
- **FR-013**: Map data and links MUST remain scoped to their account and protected under Foundation rules. Independent offline edits to different nodes in one map MUST both survive synchronization. Competing edits to the same node, and deletion/edit races, MUST follow the approved newest-timestamp active-version rule and retain the nonwinning version as a visible conflict record; no conflicting change may disappear silently.
- **FR-014**: The development preview MUST allow local Mind Maps use without sign-in, including links to existing preview Tasks. Preview data MUST remain separate from authenticated accounts and unavailable in release builds. An account-based public release still requires the separate authentication flow and initial account synchronization; this feature MUST NOT introduce that flow.
- **FR-015**: Mind Maps labels, validation, errors, status, and controls MUST support Arabic and English, correct Arabic right-to-left direction, and usable touch, pointer, and keyboard navigation. Core behavior MUST match across Android, iOS, Windows, macOS, and Linux; final colors and screen composition remain part of the later UI Refinement phase.

### Key Entities

- **Mind Map**: One account-owned visual workspace with title, optional description, central node, settings, nodes, and connections.
- **Mind Map Node**: One map-owned idea, branch, task-type item, or note with identity, title, optional description, position, status, priority, appearance, and optional Task link. A node is never the canonical Task.
- **Mind Map Connection**: One relationship between two nodes in the same map, with appearance, a parent-child or visual-side-link role, and no duplicate for the same pair. Removing a parent-child connection detaches the child; visual side links do not control layout.
- **Map Settings**: Per-map layout and visual preferences, including defaults for new nodes and connections.
- **Task Link**: An explicit reference from one node to one existing Task; Task completion and award remain owned by the Tasks and XP capabilities.
- **Map Conflict Record**: A recoverable nonwinning version of a competing change to the same map element or a deletion/edit race under the approved account conflict rule.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every defined create, edit, duplicate, search, delete, node, connection, branch reparenting, status, layout, and settings scenario produces the expected visible result after one offline restart.
- **SC-002**: In ten scenarios spanning completion and reopening from Tasks and at least two linked map nodes, all views agree after each action and the Task has exactly one lifetime XP award.
- **SC-003**: In ten offline restart and reconnect trials across two devices, changes to different nodes of one map both survive, competing same-node edits expose the nonwinning version for recovery, and no map element is duplicated.
- **SC-004**: Account-isolation checks reveal or change zero maps, nodes, links, or conflict records belonging to a different account; the development preview shows none of the real account's content.
- **SC-005**: On a map of at least 50 nodes and 60 connections, users can pan, zoom, fit, select, and edit a node on one mobile and one desktop target, with each confirmed action visibly reflected within two seconds while offline.
- **SC-006**: Arabic and English primary flows, including right-to-left connections and mixed-direction labels, pass on one mobile and one desktop target; map persistence and account synchronization checks pass on all five required targets.
- **SC-007**: In both touch and keyboard walkthroughs, every step to create a map, add a child and note, link an existing Task, and identify map progress is available through labeled, visible controls without relying on an undocumented gesture.

## Assumptions

- Feature 005 follows closed Tasks 003 and Habits 004 in the Core Productivity phase; Dashboard/Today follows Mind Maps. Authentication remains a later separate feature as the user directed. The development preview supports direct local testing and must expose the existing preview Tasks for link testing; account separation and public-release prerequisites still apply.
- The prototype is the behavioral reference for map operations, node types and statuses, layouts, settings, progress, navigation, and editor undo/redo. Its direct Task and XP mutations are replaced by the approved Tasks 003 behavior while preserving the user-visible completion relationship.
- Duplicating a map creates independent map-owned nodes and connections, while links continue to reference the original real Tasks. It does not duplicate or reward Tasks.
- Linked nodes may have their own map labels and notes; the linked Task identity and completion come from Tasks. A linked node marked in progress keeps its Task open. A Task reopened from Tasks is shown as not started in linked map nodes.
- The first implementation follows functional prototype behavior and a usable editor. Final colors, design system, typography, and screen composition belong to later UI Refinement.
- Creating a real Task from a map, collaborative editing between different accounts, exported images/files, new XP sources for map-only nodes, and Dashboard/Today aggregation are outside this feature.
