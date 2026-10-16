# Feature Specification: Habits

**Feature Branch**: namaa/004-habits

**Created**: 2026-10-16

**Status**: Draft; ready for planning

**Input**: User description: Work on 004 in the Namaa plan, follow the plan order, and add authentication later.

**Sources**: namaa_plan.md §§5, 14–16, 18–20, 24, 26–27; Namaa Constitution v2.0.1; completed Tasks 003 specification. Prototype personal counters are not a verified Habit domain.

## Clarifications

### Session 2026-10-16

- Q: Should 004 deliver Habit reminders or save the choice for later Notifications? → A: Save the reminder time in 004 and show it as inactive until the Notifications feature enables delivery.
- Q: Do unscheduled weekdays break a Habit streak? → A: No. Only a scheduled day that ends without completion breaks the streak; unscheduled days are neutral.
- Q: Can users record or correct Habit completion on earlier dates in 004? → A: No. Only the current day's completion can be changed; earlier dates are read-only.
- Q: When do edits to selected weekdays take effect? → A: Immediately today; any completion already recorded today remains saved.
- Q: Does a completion still count in the streak if its weekday is removed later that day? → A: Yes. It was earned while the day was scheduled, so it remains in the streak.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create and complete recurring habits (Priority: P1)

As a user, I can create several habits with names and selected weekdays, see which are due today, and complete each due habit. This helps me follow recurring behavior separately from finite tasks.

**Why this priority**: A schedule and daily completion are the smallest useful Habit experience in the plan.

**Independent Test**: Create two habits with different weekdays, complete one on a scheduled day, restart, and verify that only its current day shows completion.

**Acceptance Scenarios**:

1. **Given** no habits, **When** the user saves a nonblank name and at least one weekday, **Then** one habit appears with that schedule and no completed days.
2. **Given** several habits, **When** the user opens Habits, **Then** habits due on the current local calendar day and their individual completion states are identifiable.
3. **Given** a habit due today, **When** the user completes it, **Then** today's state changes immediately and remains complete after restart.
4. **Given** a completed habit due today, **When** the user undoes completion, **Then** today's state becomes incomplete and that habit's streak is recalculated.
5. **Given** a blank name or no selected weekday, **When** the user tries to save, **Then** no habit is created and a localized message explains the missing value.

---

### User Story 2 - Track each habit's streak (Priority: P2)

As a user, I can see each habit's current streak and completed scheduled dates without mixing its progress with another habit or a Task.

**Why this priority**: The plan explicitly assigns an individual streak to every habit.

**Independent Test**: Create a Monday/Wednesday habit and a daily habit; complete and miss selected days; verify both streaks and histories independently.

**Acceptance Scenarios**:

1. **Given** a Monday/Wednesday habit, **When** Monday and Wednesday are completed, **Then** its streak is two; Tuesday neither adds to nor breaks it.
2. **Given** a scheduled day is missed, **When** that day ends, **Then** its current streak becomes zero without changing other habits' streaks.
3. **Given** today's scheduled day is incomplete but still in progress, **When** the user views the habit, **Then** the streak earned through the previous scheduled day remains visible.
4. **Given** today's completion is submitted twice or received from two devices, **When** history is reconciled, **Then** that day is counted once.
5. **Given** completed scheduled days, **When** the user opens the habit's history, **Then** those dates and its current streak are visible.

---

### User Story 3 - Edit or remove a habit (Priority: P2)

As a user, I can change a habit's name, selected weekdays, or optional reminder choice, and delete a habit I no longer follow, without rewriting past completion history.

**Why this priority**: Habits change over time, but past streaks must retain the meaning of the schedule active then.

**Independent Test**: Complete a day, edit the name and weekdays, verify history against the former schedule, then delete the habit and check another habit remains intact.

**Acceptance Scenarios**:

1. **Given** a habit with history, **When** the user edits its name or weekdays, **Then** the new name and today's due state update immediately, and any completion already recorded today remains attached to that habit.
2. **Given** a schedule edit, **When** the user views older dates, **Then** streak calculation uses the schedule effective on those dates.
3. **Given** today was completed while scheduled, **When** the user removes today from the selected weekdays, **Then** the completion remains visible and counts in the streak; no new completion can be made while today is unscheduled.
4. **Given** a habit, **When** the user confirms deletion, **Then** that habit and its owned history leave active views without changing other habits or Tasks.
5. **Given** an optional reminder choice, **When** the user edits or removes it, **Then** the saved choice updates and is not shown as active before delivery is available.

---

### User Story 4 - Continue habits across interruptions (Priority: P2)

As a user, I can use habits offline and later see changes on my other devices under the same account, without duplicate days or silently lost edits.

**Why this priority**: Local-first use, safe synchronization, and account separation are Namaa product rules.

**Independent Test**: Create and complete offline, restart offline, reconnect, inspect another device, and test duplicate delivery, conflicting edits, and another account's access.

**Acceptance Scenarios**:

1. **Given** a disconnected device, **When** the user creates, edits, completes, or deletes a habit, **Then** the result appears immediately and survives offline restart.
2. **Given** offline changes, **When** the account reconnects, **Then** changes appear on its other device without duplicate habits or completed days.
3. **Given** concurrent edits to one habit, **When** they reconcile, **Then** the approved account conflict rule chooses the active version and retains the other version visibly for recovery.
4. **Given** two accounts, **When** either opens Habits, **Then** it cannot see or change the other's habits, history, or conflict records.
5. **Given** a local save fails, **When** the user changes a habit, **Then** the user sees a localized failure and the last confirmed habit state remains available for recovery.

### Edge Cases

- A seven-day habit can complete once per local calendar day, never once per tap or retry.
- An unscheduled day is not missed and cannot gain a new completion in this version. A completion earned earlier today while scheduled is retained after a same-day schedule edit.
- A schedule edit changes today's due state immediately. A completion recorded while today was scheduled remains in history and in the streak even if today is then removed from the selected weekdays.
- An action uses the acting device's local calendar date. Changing device time zone or syncing to a device in another zone does not rewrite a previously recorded date or its effective schedule; repeated completion for the same habit and recorded date is still one day.
- A habit with no completions has a zero streak. Deleting one habit does not affect another streak.
- Deletion racing with an offline edit follows the approved conflict rule; neither change is silently discarded.
- A saved reminder choice is visibly inactive until notification delivery is available and enabled on that device.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create and retain multiple habits. Each habit MUST have a nonblank name and at least one selected weekday.
- **FR-002**: The Habits area MUST show each habit's weekdays, whether it is due on the current local calendar day, and that day's completion state. An unscheduled day MUST NOT gain a new completion or be treated as missed; a completion recorded before today's schedule edit remains saved.
- **FR-003**: A habit MUST have at most one completion per local calendar date. Users MUST be able to complete a due current day and undo a recorded current-day completion, including after a same-day schedule edit removes that weekday. An unscheduled day cannot gain a new completion. Earlier history MUST be reviewable and read-only.
- **FR-004**: Every habit MUST have its own current streak. It counts consecutive scheduled days completed under the schedule effective when each day was due. Unscheduled days neither add nor break it. A completion recorded while today was scheduled remains eligible for the streak if today is removed from the schedule later that day. A missed scheduled day breaks the streak after that day ends; an incomplete current day does not yet break the prior streak.
- **FR-005**: Users MUST be able to review each habit's completed scheduled dates and current streak. The Habit domain MUST own its history and streak; no other domain may own a second canonical copy.
- **FR-006**: Users MUST be able to edit name, weekdays, and optional reminder choice. Schedule changes MUST take effect immediately, update today's due state, and preserve any completion already recorded today and the prior schedule for earlier dates.
- **FR-007**: Users MUST be able to delete a habit after confirmation. Deletion MUST remove its active state and owned history without changing other habits, Tasks, or separately owned data.
- **FR-008**: A habit MAY hold a reminder choice including a time. Until the later Notifications feature provides delivery, the Habits experience MUST identify that reminder as inactive and MUST NOT promise an alert. Enablement and delivery MUST remain device-specific.
- **FR-009**: Habit creation, editing, completion, undo, and deletion MUST update visible state and persist locally without waiting for connectivity; pending account synchronization MUST retry safely. If a local save fails, the user MUST receive a localized failure and the last confirmed state MUST remain recoverable.
- **FR-010**: Authenticated Habit data and history MUST remain scoped to their account across devices. Another account MUST be denied access; repeated synchronization MUST NOT duplicate a habit or completed day.
- **FR-011**: Conflicting offline edits or deletion racing with an edit MUST follow Foundation's approved rule: the newest timestamp selects the active version and the nonwinning version remains a visible conflict record.
- **FR-012**: Later Today, Dashboard, and Analytics features MUST consume Habit state through explicit domain relationships, never a second canonical Habit store. Habit completion MUST NOT award XP in 004 because the plan defines no Habit XP award.
- **FR-013**: Habit text, validation, history, and reminder status MUST support Arabic and English with correct Arabic RTL. Habit rules MUST be equivalent on Android, iOS, Windows, macOS, and Linux.
- **FR-014**: Locally stored Habit account data MUST remain protected under Foundation rules. User-facing authentication and initial synchronization remain a separate prerequisite for account-based public release; 004 MUST NOT add an authentication flow.

### Key Entities

- **Habit**: One recurring behavior owned by an account, identified by name and selected weekdays, with an optional reminder choice.
- **Habit Schedule Revision**: The weekdays effective for one habit during a period, retained so a same-day edit does not erase earlier completion or rewrite past streak meaning.
- **Habit Day**: One local calendar date for one habit, with its due state, any recorded completion, and whether that completion was earned while scheduled; a same-day schedule edit does not erase that fact.
- **Habit Conflict Record**: A recoverable nonwinning version of a synchronized habit change under Foundation rules.
- **Habit Reminder Choice**: An optional time or preference on a Habit, distinct from device-specific notification enablement and delivery.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every defined creation, edit, completion, undo, deletion, and validation scenario shows the retained result after one restart.
- **SC-002**: In ten trials covering daily, alternate-day, missed-day, and edited schedules, including removal of an already completed weekday, each displayed streak follows the applicable schedule and preserves a completion earned before its weekday was removed; other streaks remain unchanged.
- **SC-003**: Ten repeated taps or synchronization deliveries for one habit and date result in exactly one completed Habit day.
- **SC-004**: In ten offline restart and reconnection trials, Habit changes remain locally usable and appear on another device of the same account without duplicates or silent conflict loss.
- **SC-005**: Account-isolation checks show zero habits, completed days, or conflict records belonging to another account that can be viewed or changed.
- **SC-006**: Arabic and English primary Habit flows pass on one mobile and one desktop target; persistence and account synchronization checks pass on all five required targets.
- **SC-007**: In user validation, at least 90% of participants can create and complete a due habit and correctly identify its streak without assistance within three minutes.

## Assumptions

- Feature 004 follows Tasks 003 in Phase 3 of the Namaa plan; Mind Maps and Dashboard/Today follow it. Authentication is deferred as a separate feature, while account safety and public-release prerequisites remain in force.
- Approved for 004: a streak follows selected weekdays rather than every calendar day; unscheduled days are neutral and a scheduled day breaks the streak only after it ends without completion.
- A Habit day uses the local calendar date on the device where completion is recorded; that recorded date remains stable after travel or cross-device synchronization.
- Approved for 004: only today's completion can be changed. Earlier history is visible but read-only; retroactive backfilling is outside scope.
- Approved for 004: weekday schedule edits change today's due state immediately. A completion earned before today is removed from the selected weekdays remains saved and counts in the streak; it may still be undone today, but a new completion requires today to be selected again.
- The prototype's personal habit counters do not establish scheduling, completion, or streak rules for this Habit domain.
- Approved for 004: the optional reminder time belongs to the Habit and is saved now; the Habits experience shows it as inactive until the later Notifications feature provides scheduling, permissions, and delivery. A synced reminder choice does not enable notifications on another device.
- No Habit XP award, shared streak, Task recurrence, Today aggregation, broad notification settings, or visual redesign is introduced in 004.

