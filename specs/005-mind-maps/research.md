# Research: Mind Maps 005

**Sources**: `specs/005-mind-maps/spec.md`, `specs/003-namaa-tasks/`, `specs/004-habits/`, `.specify/memory/constitution.md`, the existing Flutter/Foundation implementation, and the adjacent prototype. This document resolves design choices; it does not authorize code changes.

## 1. Record boundaries and offline convergence

**Decision:** Persist an account-owned map, each node, each child's parent slot, and each unordered visual side link as independently versioned records. The parent slot has a stable identity based on the child ID; a side link has a stable identity based on its sorted endpoint IDs. A node edit never rewrites the whole map or a connection. Keep one map-owned settings document in the map record.

**Rationale:** Two devices can edit different nodes without competing on a single map blob. Reparenting or detaching a child changes only its parent slot, preserving content and descendants. A single parent slot makes the at-most-one-parent rule explicit. Stable identities and operation IDs make replay idempotent. Existing Foundation outbox/conflict and Habits reconciliation patterns can be extended with these entity types. Drift transactions support atomic local graph edits and outbox writes ([Drift transactions](https://drift.simonbinder.eu/dart_api/transactions/)).

**Alternatives considered:** One serialized map blob would lose independent node edits. Embedding `parentId` on the node would make a structural edit conflict with a content edit. One generic edge row keyed by node pair would complicate concurrent reparenting because two separate pairs could each claim to be the child's parent. Separate parent slots and side links make the invariant clearer.

## 2. Graph integrity and layout

**Decision:** Parent slots alone drive automatic radial, tree, horizontal, and vertical placement. Freeform uses saved node coordinates. Side links render over the positions and never influence placement. All create, detach, reparent, link, unlink, and delete commands validate same-map endpoints, no self-link, no ancestor cycle, and no duplicate visible pair across both roles. Reparenting replaces the one parent slot atomically. Node deletion tombstones the node and incident relationships while detaching its children in one local transaction; the matching cloud command enforces the same invariant in one transaction.

**Rationale:** This matches the four clarifications and avoids hidden parentage. The prototype currently uses all edges for layout and leaves a hidden parent after disconnect; those behaviors are intentionally corrected. Concurrent structural operations require server-side validation/serialization for the affected map and conflict evidence rather than trusting only the client graph.

**Alternatives considered:** Letting side links participate in layout makes cycles and unexpected movement possible. Keeping a deleted parent reference is contrary to the visible graph. Repairing graph invariants only on the client cannot protect two reconnecting devices.

## 3. Task link and XP authority

**Decision:** A node stores an optional Task ID, never a copy of a Task or its XP. A Mind Maps application port reads accessible Tasks through the Tasks repository and changes completion only through `TaskCompletionService`; a real-account command also starts/observes `TaskSyncService` like the Tasks area. The map derives linked completion from the current Task projection. Add a minimal Tasks-owned completion-transition timestamp/revision, changed only by completing or reopening, so an open Task can show a later explicitly chosen map `inProgress` status while reopening resets linked nodes to `notStarted` without unrelated Task edits resetting them. The chooser waits for initial Task sync for authenticated accounts; preview uses existing local Tasks directly.

**Rationale:** Tasks 003 already owns completion, the one-time XP award, and account checks. One Task can appear in many map nodes without duplicate reward. Missing, deleted, or foreign Tasks resolve to an unavailable projection that reveals no title/details. The Mind Maps preview must use the same preview account identity as Tasks (`TasksPreviewSession`, not the separate Habits preview identity).

**Alternatives considered:** Direct Task/XP writes in the adjacent prototype violate the constitution and can double-award. Copying Task state into a node becomes stale; a second completion service creates another authority. Using generic Task `updatedAt` to detect reopening would also reset map progress after unrelated title edits.

## 4. Local storage and cloud synchronization

**Decision:** Add an automatic encrypted Drift schema v4→v5 migration and owner-qualified map/node/parent/side tables, plus matching Supabase rows, RLS, restricted receipt-backed mutation RPCs, and four dispatch/reconciliation routes. Each local command commits its data changes and pending operation in one transaction, then updates the UI from local state. Send operations with stable IDs; ingest complete paged account snapshots/tombstones, compare per-record versions, retain nonwinning payloads in visible conflict records, and only mark initial sync complete after all record types reconcile. Map tombstones hide descendants; late child edits become reviewable conflicts and never resurrect the map. Node tombstones hide incident relations; deletion/edit races preserve the loser.

**Rationale:** This extends the existing Foundation/Habits pattern without a second database. Independent record versions give the requested same-map merge. Server operations derive owner from `auth.uid()`, use least-privilege grants/RLS, reject foreign endpoints and Task IDs, pin `search_path` for privileged functions, and return stable receipts. These requirements follow [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) and [database function guidance](https://supabase.com/docs/guides/database/functions). Drift's migration tooling supports additive schema verification ([Drift migrations](https://drift.simonbinder.eu/migrations/)).

**Alternatives considered:** Direct client table writes bypass the established receipt/invariant boundary. Per-device-only storage cannot satisfy account sync. A full delete cascade without tombstone/conflict evidence could silently discard offline edits.

## 5. Editor, preview, and platform behavior

**Decision:** Build a Flutter `flutter_bloc` feature with map list and editor. Use stock Flutter interaction primitives: `InteractiveViewer` for pan/zoom/fit and a repaint-aware connection painter; provide visible labeled controls for every required action, touch/pointer/keyboard focus, and ARB Arabic/English strings. Keep undo/redo as current-editor-session map-owned commands with version checks; never snapshot or replay real Task/XP state. The existing debug-only Tasks preview permits entry without sign-in and remains isolated from real accounts. Auth stays later; final branding and screen composition stay in UI Refinement.

**Rationale:** [InteractiveViewer](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html) provides the needed viewport controls and [CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html) supports efficient connection rendering and semantics. Existing app routing/composition already gates Tasks and Habits and can add Mind Maps without a new dependency. The prototype has five layout types even though its settings picker currently exposes four; the new UI must expose all five required layouts.

**Alternatives considered:** Gesture-only actions fail the touch/keyboard walkthrough. Adding a third-party canvas package or a new design system now has no verified need. Treating preview as production auth would violate the release boundary.

## 6. Validation and CI trigger

**Decision:** Verify pure graph/progress rules, repository/migration/reconciliation, Task bridge and XP, widget access/RTL, SQL RLS/replay, and offline/device flows. Extend `.github/workflows/foundation-ci.yml` for 005 paths and relevant five-target checks while preserving its existing PR-to-`develop` and manual triggers; no CI run for each feature-branch push.

**Rationale:** The constitution requires evidence on affected targets. The user explicitly chose the full target matrix before merge to `develop` or by manual trigger, after prior long runs on every push.

**Alternatives considered:** A screen-only test cannot prove restart, account isolation, or reconciliation. Triggering the full matrix on every branch push contradicts the agreed workflow.

**Open product decisions:** None. Performance is checked against SC-005 (50 nodes/60 links and visible response within two seconds), without inventing a larger capacity guarantee.
