# Tasks: Phase 0 Research

**Feature:** 003 Namaa Tasks
**Sources:** specs/003-namaa-tasks/spec.md; .specify/memory/constitution.md; namaa_plan.md (Phase 3, Tasks, Auth, data ownership, offline/sync, XP); the existing Foundation code and contracts; prototype/src/types.ts, prototype/src/views/TasksView.tsx, prototype/src/context/AppContext.tsx, prototype/src/data/initialData.ts. These are project evidence, not new product requirements.

## Decision 1: Extend the existing Flutter Foundation

**Decision:** Implement Tasks as a feature-first Clean Architecture slice under lib/features/tasks/{domain,application,data,presentation}. Reuse Foundation's encrypted database, account session port, sync coordinator, BLoC/Cubit, get_it, go_router, ARB localization, and platform setup. Domain types and rules have no Flutter, Drift, or Supabase imports.

**Rationale:** The constitution mandates these boundaries and the Foundation already provides them. The prototype provides Task behavior but not a Flutter architecture.

**Alternatives considered:** A separate app/database or direct widgets-to-Supabase calls would duplicate state, weaken offline behavior, and violate the constitution.

## Decision 2: One Task aggregate owns checklist steps

**Decision:** A Task is the sync and conflict unit. Checklist steps are ordered, simple child values with stable item IDs, text, and completed state; store them within the Task aggregate payload while keeping filterable Task fields as columns. Their mutation changes the Task version and produces one Task outbox operation.

**Rationale:** The approved clarifications give checklist items no independent schedule, category, XP, or parent-completion effect. Aggregate storage keeps parent and steps atomic across offline changes.

**Alternatives considered:** Independent checklist rows and cloud entities would add foreign-key, tombstone, and conflict machinery without a current product need. This is a design choice; it does not prevent a later data-preserving migration.

## Decision 3: Account-scoped local storage and schema migration

**Decision:** Extend FoundationDatabase from schema v2 to v3 with account-scoped Tasks and an immutable XP-award ledger, preserving existing Foundation rows through a tested migration. Use the same encrypted Drift/SQLite storage. Each local Task edit, award effect when applicable, and pending sync operation commit in one transaction. A signed-out or different account must not see a previous account's Tasks.

**Rationale:** Foundation's LocalRecords implementation only handles probe records; it cannot be assumed to persist Tasks. Foundation encryption, migration journal, and account context are existing approved mechanisms.

**Alternatives considered:** Reusing LocalRecords for Task JSON would make Task queries and account boundaries opaque. A second database would duplicate key and migration lifecycle.

## Decision 4: Task-level reward snapshot and shared XP authority

**Decision:** Persist a Task's configured completion XP at creation, matching the prototype's task-level reward snapshot. Until a shared configurable setting is introduced, use the verified prototype default of 20 XP; do not build settings UI here. On the first explicit Task completion, a minimal shared XP capability writes an immutable award with a unique (account, source='task_done', taskId) key in the same local transaction. Reopening, recompleting, deletion, retries, and future Mind Map links cannot create another award. XP balance is derived from awards rather than separately mutated by the Tasks feature.

**Rationale:** spec FR-007 and FR-008, plan XP ownership, prototype task_done_<id> deduplication and default 20. The prototype's separate fallback values are inconsistent; a single stored Task reward avoids that ambiguity.

**Alternatives considered:** A Task-owned mutable XP total duplicates canonical finance/gamification state. Crediting every completion violates the spec. Implementing levels or achievement systems now expands scope.

## Decision 5: Durable Task sync, including inbound changes

**Decision:** Keep Foundation's outbox and retry/coordinator semantics, but add a Task-specific cloud adapter and entity-type dispatch without changing probe behavior. Add an authenticated inbound Task/award fetch-and-merge path for initial sync, reconnect, and return to Tasks. Fetch includes deleted Task tombstones and stable award keys; bounded pages may be used, with no speculative Realtime requirement. Preserve the same operation ID on retries. Remote transaction/application records operation IDs durably, including deletions, before acknowledging them.

**Rationale:** Existing Supabase adapter only knows foundation_probe and apply_foundation_change; the current runner sends pending changes but does not import remote Tasks. Multi-device Tasks need both directions and deletion replay safety.

**Alternatives considered:** Treating the existing probe transport as generic would fail. Push-only sync cannot show another device's edits. Realtime is optional and not required by the verified sources.

## Decision 6: Conflict policy follows Foundation exactly

**Decision:** For competing Task aggregate versions, use the approved newest-UTC-timestamp active version and retain the nonwinning version in a visible conflict record. Equal timestamps retain both as recoverable unresolved state; no tie-breaker is invented. XP awards converge independently by immutable deduplication key. Task deletion is a versioned tombstone and competes under the same Task conflict rule.

**Rationale:** Constitution and Foundation sync contract already establish this policy, including the equal-timestamp exception. The Tasks spec requires losing-version visibility.

**Alternatives considered:** Silent overwrite, server-authoritative merge, or field-level checklist merge would contradict or extend existing policy. A deterministic equal-timestamp winner remains unresolved and is not introduced here.

## Decision 7: Supabase ownership and atomic completion

**Decision:** Add account-owned Task rows, XP awards, and an operation receipt ledger protected by RLS; derive owner identity from the authenticated context rather than trusting a client owner field. Task completion and first award must be atomic remotely and idempotent by operation and award keys. Cross-account reads/writes are denied for rows and callable operations. Keep domain interfaces independent of Supabase.

**Rationale:** Foundation's authenticated owner/RLS contract and Task account/XP integrity criteria. Existing foundation_probe is only a test model and its operation ID stored on the row is not durable enough for replay after delete.

**Alternatives considered:** Client-side-only XP deduplication fails across devices; public direct table writes without an atomic boundary risk partial completion and inconsistent rewards.

## Decision 8: UI, authentication prerequisite, and verification

**Decision:** Use a TasksCubit (or focused Cubits if state boundaries warrant) whose state comes from Task application queries, not duplicate list/matrix stores. Add guarded Tasks navigation under the existing router, use Arabic/English ARB resources, correct RTL, and existing theme. A basic user-facing sign-in path and completed initial authenticated sync are external release prerequisites; this plan only defines the integration point and does not implement Auth as a Tasks subfeature. Verify unit, widget, integration, database security, migration, offline, and five-platform scenarios against the spec.

**Rationale:** Spec FR-005, FR-013 to FR-015 and SC-001 to SC-006; Foundation architecture and successful five-target gate. The verified prototype includes completed Tasks under All while Today/Urgent and matrix exclude them. No detailed new visual design is approved.

**Alternatives considered:** Implementing Auth UI inside Tasks or blocking every local action on connectivity would expand scope or break offline-first.

## Open boundary, not silently resolved

A deterministic winner for exact equal Task timestamps is not approved. Preserve both versions as recoverable unresolved, consistent with Foundation. No further product-owner decision is required to plan or implement the stated feature; choosing an automatic tie-breaker later would require approval. No numeric latency, record-count, or minimum OS targets were specified, so this plan does not invent them.
