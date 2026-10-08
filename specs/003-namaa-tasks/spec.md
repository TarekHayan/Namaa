# Feature Specification: Tasks

**Feature Branch**: `namaa/003-tasks`

**Created**: 2026-10-07

**Status**: Ready for planning

**Input**: User description: "Continue Phase 3 — Core Productivity in the Namaa Project Plan."

**Sources**: `namaa_plan.md` §§4, 14, 18–20, 24, 26–27; Namaa Constitution v2.0.1; `../prototype/src/types.ts` (`Task`, `TaskCategory`, `EisenhowerQuadrant`); `../prototype/src/views/TasksView.tsx`; `../prototype/src/components/QuickAddModal.tsx`; `../prototype/src/context/AppContext.tsx` (task operations and XP deduplication); `../prototype/docs/02_DATA_MODEL.md`, `03_BUSINESS_LOGIC.md`, `09_REBUILD_CONTRACT.md`, `10_VERIFICATION_GAPS.md`; completed Foundation 001 contracts and verification.

## Clarifications

### Session 2026-10-07

- Q: Are checklist items simple steps within a Task, or independent Tasks with their own scheduling and XP? → A: Simple steps with text and completion state only; no independent schedule, category, or XP.
- Q: Does completing every checklist item complete the parent Task and award XP automatically? → A: No. The Task remains incomplete until the user explicitly completes it; checklist progress alone awards no XP.
- Q: Can the user explicitly complete a Task while some checklist items remain incomplete? → A: Yes. Checklist progress does not block explicit Task completion or its one-time XP award.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture and organize finite work (Priority: P1)

As a user, I can create and edit a task, place it in an Eisenhower quadrant and category, and find it in the Tasks list or matrix so that my work is organized for the day.

**Why this priority**: The project plan names Tasks as the first product domain after Foundation.

**Independent Test**: Create a task from the Tasks area with only a title; then create a detailed task, edit its supported fields, change its quadrant, filter the list, and verify that the list and matrix show the same task data.

**Acceptance Scenarios**:

1. **Given** an empty Tasks area, **When** the user enters a nonblank title and saves, **Then** one incomplete task appears immediately with today's date and the prototype's default category, quadrant, and estimated duration.
2. **Given** a task, **When** the user edits its title, description, date, time, deadline, category, quadrant, or estimated duration, **Then** all Tasks views show the updated values for the same task.
3. **Given** tasks in several quadrants and categories, **When** the user switches between list and matrix or applies a supported filter, **Then** each task appears in the matching result without creating a copy.
4. **Given** a task, **When** the user deletes it, **Then** it is absent from task views and a repeated delivery of the same deletion does not recreate it.
5. **Given** a blank or whitespace-only title, **When** the user tries to save, **Then** no task is created and the user receives a localized validation response.

---

### User Story 2 - Complete a task once for its reward (Priority: P1)

As a user, I can complete and reopen a task while its configured completion XP is awarded only for the first completion, so progress remains trustworthy.

**Why this priority**: One-time Task XP is an explicit product rule and must survive offline retries and multiple devices.

**Independent Test**: Complete a task, reopen it, complete it again, restart offline, then synchronize the same account on another device; verify one task and one XP award.

**Acceptance Scenarios**:

1. **Given** an incomplete task, **When** the user completes it, **Then** the task shows completed with a completion time and one configured XP award is recorded.
2. **Given** a completed task, **When** the user reopens it, **Then** the task shows incomplete and no additional XP is awarded or the prior award silently duplicated.
3. **Given** that task reopened, **When** the user completes it again, **Then** it shows the new completion time while its lifetime XP award count remains one.
4. **Given** a completion queued offline, **When** synchronization retries or another device receives it, **Then** neither the task nor its XP award is duplicated.
5. **Given** a Task with incomplete checklist items, **When** the user explicitly completes the Task, **Then** the Task completes and receives its one-time XP award while the checklist items keep their existing states.
6. **Given** a Task that already earned XP, **When** the user deletes it, **Then** the Task disappears but its earned XP remains unchanged.

---

### User Story 3 - Break down and review work (Priority: P2)

As a user, I can keep checklist items within a task and review today's, urgent, overdue, and completed work so I can act on what needs attention and see what I finished.

**Why this priority**: The project plan explicitly includes checklist/subtasks and history/overdue views; the prototype already has list, urgent, completed, category, and matrix views.

**Independent Test**: Create tasks on different dates, in different quadrants, with checklist items; change checklist progress and completion; verify the appropriate views and history after a restart.

**Acceptance Scenarios**:

1. **Given** a task, **When** the user adds, edits, marks, unmarks, or removes a checklist item, **Then** that task's checklist reflects the change and other tasks remain unchanged.
2. **Given** every checklist item is marked complete, **When** the user has not explicitly completed the parent task, **Then** that task remains incomplete and no Task XP is awarded.
3. **Given** tasks for today and other dates, **When** the user selects Today or All, **Then** the matching tasks are shown according to their dates and completion state.
4. **Given** tasks in urgent quadrants, **When** the user selects Urgent, **Then** only tasks from those quadrants are shown.
5. **Given** completed tasks, **When** the user opens completed/history, **Then** the tasks and their completion dates can be reviewed.
6. **Given** incomplete work whose scheduled date or target deadline has passed, **When** the user opens overdue, **Then** those tasks are shown; a task whose only elapsed value is its time on today's date is not shown as overdue.

### Edge Cases

- A task with optional fields left blank remains valid when its title is nonblank.
- Completing and reopening a task while offline preserves both the current completion state and the single lifetime reward after restart and synchronization.
- Two devices changing the same task while offline follow Foundation's approved conflict rule: the newest timestamp is active and the other version remains a visible conflict record.
- A deletion racing with an offline edit must not silently discard the nonwinning change; the Foundation conflict record rule applies.
- Checklist changes and task deletion are durable and retry safe; deleting a task also removes its owned checklist data without deleting data owned by another domain.
- Arabic titles and descriptions display correctly right-to-left; English content and mixed numbers remain readable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Tasks area MUST let users create, edit, complete, reopen, and delete finite tasks. Task recurrence is outside this specification because the source leaves its behavior unverified.
- **FR-002**: A task MUST have a nonblank title. Each task MUST have a date; supported optional or user-selected information MUST include description, time, deadline, category, Eisenhower quadrant, and estimated duration.
- **FR-003**: For a task created without changing the prototype form defaults, the date MUST be today, category `work`, quadrant `urgent_important`, and estimated duration 30 minutes. Users MUST be able to change supported values.
- **FR-004**: Supported categories MUST be work, study, personal, health, spiritual, finance, and other. Supported quadrants MUST be urgent/important, not urgent/important, urgent/not important, and not urgent/not important, matching the verified prototype model.
- **FR-005**: The Tasks area MUST provide a list and four-quadrant matrix. The list MUST support the prototype's Today, Urgent, All, and Completed filters and category filtering. Moving a task between quadrants MUST update the same task in both views.
- **FR-006**: Task completion MUST record a completion time; reopening MUST clear the current completion time. Completed work MUST remain reviewable through history as required by the plan.
- **FR-007**: The configured completion XP for a task MUST be awarded on its first completion only. Reopening, recompleting, restarting, synchronization retries, and completing from a future Mind Map link MUST NOT award it again. Deleting a rewarded Task MUST NOT reverse its earned XP. The reward MUST have one authoritative record owned by the shared XP capability.
- **FR-008**: A task MAY contain checklist items as approved in the plan. Each item MUST be a simple step with text and completion state, owned by one Task; it MUST NOT have an independent schedule, category, or XP. Users MUST be able to add, edit, mark, unmark, and remove items without changing another Task's checklist. Completing every checklist item MUST NOT complete the parent Task or award Task XP; only the user's explicit Task completion action does so. Incomplete checklist items MUST NOT block explicit Task completion or its one-time XP award.
- **FR-009**: Users MUST be able to review overdue tasks. An incomplete task is overdue when its scheduled date or target deadline has passed; an elapsed time on today's date alone MUST NOT make it overdue. Completed tasks MUST NOT appear in overdue.
- **FR-010**: The Tasks domain MUST own canonical task and checklist data. Today, Mind Maps, Analytics, and other areas MUST consume Task state through explicit relationships or application services and MUST NOT keep an independent canonical Task copy.
- **FR-011**: Task changes, checklist changes, and Task completion rewards MUST apply locally, persist, and update the visible state without waiting for connectivity; required account synchronization MUST queue and retry safely under the Foundation rules.
- **FR-012**: For an authenticated account, Task data MUST remain account scoped across devices. Cloud access MUST deny a different account, and offline conflicts MUST follow Foundation's newest-timestamp active version with the nonwinning version retained visibly.
- **FR-013**: A basic user-facing sign-in path and initial authenticated synchronization MUST be available before Tasks is released to users. Thereafter, Task operations MUST remain usable offline under the Foundation contract. Task data persisted on device MUST remain protected at rest, and the domain MUST use the existing Foundation account and synchronization boundaries. The sign-in flow itself is a separate prerequisite, not a Task feature in this specification.
- **FR-014**: User-facing Task text and validation MUST support Arabic and English, with correct RTL for Arabic. Task behavior MUST be equivalent across Android, iOS, Windows, macOS, and Linux, while presentation MAY adapt to device form factor.
- **FR-015**: The first Task UI MUST follow the prototype's general list/matrix behavior and structure. Detailed visual redesign belongs to the later UI Refinement phase.

### Key Entities

- **Task**: One finite item of work with identity, title, optional details and schedule, category, quadrant, estimated duration, completion state and time, configured XP reward, and creation time. The Tasks domain owns it.
- **Checklist Item**: One simple step belonging to one Task, with text and completion state but no independent schedule, category, or XP. Its lifecycle follows that Task.
- **Task Completion Award**: The shared XP capability's one-time award for a Task identity. It records that the first completion was rewarded and prevents any repeat award.
- **Task Conflict Record**: A retained nonwinning version when two synchronized edits conflict, governed by Foundation rules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In every acceptance scenario for task creation, editing, filters, checklist changes, completion, reopening, and deletion, the visible result matches the saved Task state after a restart.
- **SC-002**: In 10 repeated complete → reopen → complete cycles, the task produces exactly one lifetime XP award.
- **SC-003**: In 10 offline restart and reconnect trials, Task and checklist changes remain available locally and synchronize without duplicate Tasks or XP awards.
- **SC-004**: In account-isolation checks, another account can read or modify zero Tasks, checklist items, or Task reward records belonging to the first account.
- **SC-005**: Arabic and English Task flows pass on one mobile and one desktop target; task persistence and account synchronization checks pass on all five required targets.
- **SC-006**: List, matrix, category, completed/history, and overdue views agree on Task identity and state in every defined test case.

## Assumptions

- Foundation 001 is closed: GitHub Actions run 37548647271, attempt 2, passed the five-target gate. The Tasks feature reuses its local persistence, protected storage, localization, account session, and synchronization contracts.
- The approved project plan extends the prototype with task editing, checklist/subtasks, and history/overdue review. The prototype Task type does not contain checklist items and its visible Tasks view does not define a dedicated overdue/history policy; these extensions must not be treated as already verified prototype behavior.
- The verified prototype creation forms use today's date, `work`, `urgent_important`, and 30 minutes as defaults. The task's XP value comes from the configured Task-completion reward; this specification does not invent a new amount.
- The prototype exposes task operations and one-time XP deduplication. The implementation must preserve that behavior through Namaa's approved shared XP authority; broader levels, achievements, and celebrations remain in Phase 7.
- Habit creation, Mind Map editing, Today aggregation, notification delivery, and full account-management flows are separate specifications. This Task specification only establishes Task-owned data and the explicit contracts those later areas consume.

## Approved Decisions

- 2026-10-07: An incomplete task is overdue when its scheduled date or target deadline has passed. Its elapsed same-day time alone does not make it overdue.
- 2026-10-07: A basic user-facing sign-in path and initial authenticated synchronization must precede Tasks release. Authentication-flow details are outside this Task specification.
