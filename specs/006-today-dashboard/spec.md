# Feature Specification: Dashboard / Today

**Feature Branch**: namaa/006-today-dashboard

**Created**: 2026-10-22

**Status**: Draft

**Input**: Start the next feature in the Namaa plan after closing Mind Maps 005. Follow the planned order, retain direct development-preview access without sign-in, and defer final visual design and public authentication.

**Sources**: Namaa plan §§3, 7, 18–22, 24, 26–28; Constitution v2.0.1; the adjacent prototype's HomeView, daily calculations in AppContext, timelineEngine and rebuild contract; approved Tasks 003, Habits 004 and Mind Maps 005 specifications and current domain behavior.

**Scope**: Provide a usable current-day overview of the implemented productivity features: Tasks, Habits, their existing progress, the existing XP awards, and navigation to Tasks, Habits and Mind Maps. Prayer, Quran, Dhikr, Qiyam, Pomodoro, Finance, expanded Gamification, Notifications and Analytics remain in their later planned features. Their absence must not appear as an uncompleted daily obligation.

## Clarifications

### Session 2026-10-22

- Q: Should Today show separate Task and Habit progress percentages or one combined percentage? → A: Show a separate percentage for each area, with no combined percentage in 006.
- Q: Should Do First include urgent-and-important Tasks from all dates, or only today's and overdue Tasks? → A: Include only incomplete urgent-and-important Tasks scheduled today or overdue; exclude future-only Tasks that are not overdue.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Understand today's work and progress (Priority: P1)

As a user, I can open Today and see the current date, today's tasks, due habits, their completion progress and XP actually earned today, so I know my current state without opening each area separately.

**Why this priority**: A truthful overview is the smallest useful Dashboard experience and the central daily flow described by the plan.

**Independent Test**: In the development preview, prepare tasks for yesterday, today and tomorrow, completed and incomplete work, and habits with different schedules. Open Today offline and compare its lists, counts, percentages, streaks and XP with the owning areas.

**Acceptance Scenarios**:

1. **Given** the normal development preview, **When** the user opens the application, **Then** Today is available as the main daily view without signing in, and Tasks, Habits, Mind Maps and existing preferences remain reachable.
2. **Given** ten nondeleted tasks scheduled today, four completed, **When** Today is displayed, **Then** its task summary shows four of ten completed and 40%, its task list distinguishes open and completed items, and other scheduled dates are excluded from this denominator.
3. **Given** five habits eligible today and two completed, **When** Today is displayed, **Then** it shows two of five completed and 40%, and each habit's streak agrees with Habits.
4. **Given** a habit completed while due today and then edited to remove today's weekday, **When** Today refreshes, **Then** the retained completion remains visible and included in today's habit progress. An unscheduled habit without a retained completion does not appear as due or missed.
5. **Given** a task completed yesterday but reopened and completed again today, **When** the user checks today's XP, **Then** that task adds no new XP today; the display follows the original recorded award rather than its current completion state.
6. **Given** no tasks scheduled today, no eligible habits and no XP awards today, **When** Today opens, **Then** it shows explanatory empty states, zero XP and zero counts without claiming 100% completion or displaying an invalid percentage.
7. **Given** a later feature has not been implemented, **When** Today opens, **Then** it supplies no invented activity, time, balance, reward or completion requirement for that feature.

---

### User Story 2 - Act from Today without duplicating work (Priority: P1)

As a user, I can complete or reopen a task, complete or undo a due habit, and open the existing creation flows from Today, so the overview is useful for daily actions and stays consistent with the rest of Namaa.

**Why this priority**: Actions must affect the real Task or Habit and preserve the completion, streak and reward rules already approved for those features.

**Independent Test**: Create a Task and Habit through Today, complete them from Today, inspect the owning areas and a linked Mind Map, reopen or undo them, restart offline, and verify the same records and the existing reward limits.

**Acceptance Scenarios**:

1. **Given** a task scheduled today, **When** the user completes it from Today, **Then** Tasks and any linked Mind Map reflect that same Task's completion; only its first lifetime completion earns its configured XP.
2. **Given** a task already rewarded, **When** the user reopens and completes it repeatedly from Today or Tasks, **Then** its displayed state stays consistent everywhere and no additional Task reward is created.
3. **Given** a due habit, **When** the user completes or undoes it from Today, **Then** its current-day state, summary and streak agree with Habits, without awarding Habit XP.
4. **Given** a retained completion for a habit no longer scheduled today, **When** the user undoes it today, **Then** the completion is undone under Habits rules and the habit leaves today's eligible set until scheduled again. Today does not offer a new completion while it remains unscheduled.
5. **Given** Today, **When** the user creates a Task or Habit through its quick action, **Then** the existing owner form validates and saves it once, the Task defaults to today's date, and the overview reflects the saved result. Cancelling creates nothing.
6. **Given** an action whose local save fails, **When** the failure is reported, **Then** the user sees a localized recovery message, the last confirmed state remains available, and Today does not show a successful completion or reward that was not saved.
7. **Given** rapid repeated taps or an item deleted in another area, **When** the action is resolved, **Then** the existing owner rules prevent duplicate effects or resurrection, and Today displays the current result or an understandable unavailable state.

---

### User Story 3 - Keep a trustworthy view across time and connectivity (Priority: P1)

As a user, I can return to Today after a restart, midnight, an account change or a lost connection and still see the right day and the right person's data, so I can trust the overview.

**Why this priority**: A daily view becomes misleading if its date is stale, if one unavailable source blocks everything, or if it exposes the previous account.

**Independent Test**: Exercise an offline restart, local midnight, resume after a date or time-zone change, one unavailable source, recovery, and a switch between two account fixtures and the separate preview identity.

**Acceptance Scenarios**:

1. **Given** available local data and no connection, **When** Today opens or the app restarts, **Then** the same confirmed Task and Habit state is usable without waiting for cloud access.
2. **Given** Today remains open across local midnight, **When** the next day begins, **Then** its displayed date and eligible items refresh within one minute, prior completion records stay intact, and due unfinished tasks may move into the existing overdue view.
3. **Given** the app resumes after midnight or a time-zone change, **When** Today becomes active, **Then** it recalculates the current local day before accepting a date-sensitive Habit action and does not rewrite previously recorded Habit dates.
4. **Given** a Task or Habit changes in its owning area or arrives through existing synchronization, **When** that change is locally available, **Then** Today reflects it without a manual app restart and without creating a separate conflict or business record.
5. **Given** one source cannot load, **When** Today opens, **Then** that section reports an unavailable state with a retry action within ten seconds, while available sections remain usable; an unavailable value is not presented as zero or as confirmed empty.
6. **Given** a recoverable source failure and previously confirmed values, **When** those values remain visible, **Then** the section clearly marks them as outdated and disables actions that cannot be safely validated until recovery.
7. **Given** a switch of account or a resolved sign-out in account mode, **When** the identity boundary changes, **Then** old lists, counts and XP are cleared before the next account's content is shown; preview content and real-account content remain separate.

---

### User Story 4 - Find the next action and move to its owner (Priority: P2)

As a user, I can scan today's timed tasks, see important or overdue work, and open the relevant area, so I can decide what to do next without turning Today into another task-management system.

**Why this priority**: The prototype provides a daily timeline, Do First preview and quick navigation; this slice adapts those flows to the features already implemented.

**Independent Test**: Prepare timed, untimed, completed, overdue and future Tasks, including urgent/important Tasks and a Task linked from two maps. Review the agenda and priority preview, verify that Do First includes only today's or overdue urgent-and-important Tasks, follow the links, and verify the same identities and statuses.

**Acceptance Scenarios**:

1. **Given** tasks scheduled today with and without times, **When** the agenda is displayed, **Then** timed items appear chronologically with their saved times and estimated durations, while untimed items are visibly separate and are not assigned an invented time.
2. **Given** two tasks with the same time or overlapping estimated durations, **When** the agenda refreshes, **Then** both remain individually reachable in a stable order; Today does not silently reschedule them or assert that the user has started either task.
3. **Given** a task whose only elapsed value is its time or estimated duration today, **When** its time passes, **Then** Today does not label it overdue or complete it automatically. A passed scheduled date or target deadline uses the approved Tasks overdue rule.
4. **Given** incomplete urgent-and-important Tasks on different dates, **When** the user views Do First, **Then** at most three Tasks scheduled today or overdue appear in the same relative order as Tasks, with their dates visible; Tasks that are neither scheduled today nor overdue are excluded, and opening the matrix provides access to the remaining work.
5. **Given** overdue tasks, **When** the user opens the overdue summary, **Then** the owner view identifies the same incomplete Tasks; completed or deleted tasks are excluded.
6. **Given** a Task linked to multiple Mind Map nodes, **When** Today lists and counts Tasks, **Then** it counts the Task once, independent of its number of map links.
7. **Given** Today, **When** the user opens Tasks, Habits or Mind Maps and returns, **Then** the selected owner area is usable and Today reflects any saved changes without resetting owner data.

### Edge Cases

- A Task scheduled today may also have an already-passed deadline: its overdue label and today's schedule membership are separate; references to that Task must not double-count it within one summary.
- A future-scheduled Task with an already-passed target deadline is overdue under Tasks rules and may appear in Do First if urgent and important. A future-scheduled Task without an overdue condition is excluded; neither enters today's scheduled-Task progress.
- A Task completed on a different date can count toward its scheduled day's Task progress, while XP earned today uses its actual award time. These are deliberately different questions.
- Deleting a Task removes it from Task lists and their denominators but does not reverse an already-earned reward.
- Deleted Habits and their records are excluded from active Today lists under Habits rules; deleting a Habit does not mutate another Habit or Task.
- An incomplete current Habit day does not prematurely break an existing streak; a same-day schedule change follows the retained-completion behavior in Story 1.
- The day changes while a completion is being attempted: the action is checked against the current identity and local day before saving, rather than silently completing yesterday.
- A future feature, a configured feature with no records, a loading source and a failed source are distinguishable states.
- Changing the language, text size or theme does not reset the day, lists or completion records.
- Long Arabic titles, mixed Arabic/English text, missing optional times and narrow layouts remain readable and actionable.
- Repeatedly opening or refreshing Today does not create Task, Habit, completion or XP records.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Today MUST provide the normal development-preview daily entry experience, display the current local calendar date, and keep the existing Tasks, Habits, Mind Maps and preference controls reachable without requiring public sign-in.
- **FR-002**: Today's Task summary MUST count all nondeleted Tasks scheduled for the current local date, including completed Tasks. Its completed count MUST include the completed subset only; its open and completed lists MUST distinguish those states. Tasks scheduled for other dates MUST NOT change this denominator.
- **FR-003**: Today's Habit summary MUST include nondeleted Habits currently due today and Habits with a retained completion earned while due today. It MUST display each eligible Habit once, its current-day completion state and its owner-calculated streak. An unscheduled Habit with no current retained completion MUST NOT appear as due or missed.
- **FR-004**: Task and Habit progress MUST be shown as two independent summaries, each with its own completed count, eligible count and percentage, using the nearest whole percent of completed divided by eligible. There MUST NOT be a combined Task/Habit percentage in 006. A zero denominator MUST show zero items and an explanatory no-items state without claiming completion. A section with unknown or failed data MUST NOT show a calculated zero. Feature 006 MUST NOT introduce a blended overall-life score or redistribute the prototype's religious-activity weights.
- **FR-005**: Today's XP MUST be the sum of actual awards recorded for the current account whose award times fall within the device's current local calendar day. It MUST NOT be estimated from the number of currently completed Tasks, and MUST preserve the shared reward authority's deduplication and deletion behavior. New reward types, levels and daily XP targets are outside 006.
- **FR-006**: Users MUST be able to complete and reopen today's Tasks from Today using the same Task identity and approved completion rules. Changes MUST be reflected in Tasks and linked Mind Maps; the first lifetime completion is the only Task reward.
- **FR-007**: Users MUST be able to complete a due current Habit day and undo a recorded current-day completion from Today under Habits 004 rules. Today MUST NOT allow past-day editing, a new unscheduled completion, a new Habit XP award or an independent streak.
- **FR-008**: Today MUST offer quick access to the existing Task and Habit creation flows and to Tasks, Habits and Mind Maps. Owner validation, defaults, cancellation, completion, editing and deletion rules MUST remain authoritative. Viewing Today MUST NOT create or alter those records.
- **FR-009**: Today's agenda MUST show its scheduled Tasks once each: timed Tasks in ascending saved local time and untimed Tasks separately. Equal times MUST retain the same relative order as Tasks. The agenda MUST show saved estimated duration when available, never invent a scheduled time, never reschedule an item and never infer actual activity or completion from its clock.
- **FR-010**: The Do First preview MUST contain at most three nondeleted incomplete urgent-and-important Tasks that are scheduled for the current local date or are overdue under FR-011, preserving their relative order in Tasks. Tasks that are neither scheduled today nor overdue MUST be excluded. The preview MUST show each Task's date and provide access to the Task matrix. An overdue Task scheduled for another date MUST NOT enter today's scheduled-Task progress.
- **FR-011**: Today MUST expose an overdue count and access to the existing overdue Tasks view. An incomplete Task is overdue if its scheduled date or target deadline has passed; elapsed time or estimated duration today alone MUST NOT make it overdue. Completed or deleted Tasks MUST NOT count as overdue.
- **FR-012**: Today MUST refresh its local date and date-based projections within one minute of a foreground date change and within two seconds of resume with locally available data. Date-sensitive actions MUST revalidate the current day and identity before saving. Recorded Habit dates and schedules MUST remain governed by Habits, without retrospective rewriting.
- **FR-013**: Saved changes made in Tasks, Habits or a linked Mind Map, and changes received through existing account synchronization, MUST update the locally available Today view within two seconds without restarting the app. A linked Task MUST count once regardless of its number of map links.
- **FR-014**: Core viewing and supported actions MUST remain usable offline using confirmed local data. Actions MUST persist through their owning features before being reported as successful; local failures MUST provide localized recovery and preserve the last confirmed state. Pending synchronization, repeated delivery and rapid actions MUST NOT duplicate records or rewards.
- **FR-015**: Every displayed list, count, streak and award MUST belong to the current resolved account or separate preview identity. Changing identity MUST remove the old content before displaying the next identity's content. Unresolved or signed-out account mode MUST NOT expose another identity's cached data. Existing protected local-data rules remain in force.
- **FR-016**: Every source section MUST distinguish loading, confirmed empty, available and unavailable data. A load without a usable response MUST expose a localized retry state within ten seconds. A failed source MUST NOT block available sections; retained values MUST be marked outdated and unsafe actions disabled until they can be validated.
- **FR-017**: Unimplemented domains MUST NOT be represented by fabricated records, zero-valued live metrics, active-looking controls or incomplete obligations. Their detailed cards, prayer-based scheduling and contribution to an overall score belong to the owning future features. They may be omitted or explicitly marked as planned without actionable controls.
- **FR-018**: User-facing labels, dates, counts, percentages, feedback and navigation MUST support Arabic and English with correct directionality. Completion and navigation controls MUST have meaningful accessible labels, visible focus and touch/pointer/keyboard access; state MUST NOT depend on color alone.
- **FR-019**: Tasks, Habits, Mind Maps and the shared XP capability MUST retain ownership of their canonical records and rules. Today MUST derive its view from those authorities and MUST NOT store a second canonical Task, Habit, streak, reward, conflict or daily-completion history. It MUST NOT implement a parallel account-sync mechanism.
- **FR-020**: The functional structure MUST follow the prototype's daily summary, quick actions, agenda, priority preview and owner navigation, adapted to the implemented domains and approved owner rules. Behavior MUST be equivalent on Android, iOS, Windows, macOS and Linux. Final colors, typography, design system and screen composition remain in the later UI refinement phase.

### Key Entities

- **Today View**: A view for one resolved identity and one device-local calendar day, derived from the owning features; it is not an independent daily business record.
- **Today's Task Summary**: Distinct nondeleted Tasks scheduled for that day, their open/completed state and the resulting completion ratio.
- **Today's Habit Summary**: Habits due that day plus retained eligible completions, with owner-calculated completion and individual streaks.
- **Agenda Item**: A reference to one Task, including its saved date, optional time, estimated duration and authoritative completion state.
- **Priority and Overdue Preview**: References to the existing Task subsets. Do First is restricted to incomplete urgent-and-important Tasks scheduled today or overdue; the separate overdue summary follows Tasks' overdue rules regardless of quadrant.
- **Daily XP Summary**: The sum of existing account-owned reward awards falling within the viewed local day, without a second award record.
- **Section Availability**: Whether one owner source is loading, available, confirmed empty or unavailable, including whether a visible prior value is outdated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For acceptance fixtures covering mixed dates, completion states, deleted records, schedule edits, linked Tasks and zero-item days, 100% of Today lists, counts, percentages, streaks and XP totals match their owning records and the rules above. The ten-Task/four-completed and five-Habit/two-completed examples each display 40% independently, with no combined percentage. Do First includes only eligible urgent-and-important Tasks scheduled today or overdue, excludes future-only Tasks without an overdue condition, and does not change today's scheduled-Task denominator.
- **SC-002**: With 500 locally available Tasks, 100 Habits and 200 reward awards, the initial daily view and the visible result of a supported local action appear within two seconds on a tested mobile and desktop target; opening Today does not wait for connectivity.
- **SC-003**: Ten offline completion/reopen or completion/undo journeys within the same local date preserve the owning records and matching Today state before and after restart and later synchronization. Repeated Task completion leaves one lifetime reward, Habit actions add no XP, and ten read-only Today refreshes add no business records.
- **SC-004**: In each foreground-midnight, resume-after-midnight and changed-time-zone scenario, Today selects the correct local date within the stated one-minute/two-second limits, rejects a stale-day Habit action, and leaves previously recorded dates and history unchanged.
- **SC-005**: A failed or nonresponding Task, Habit or XP source produces a visible recovery state within ten seconds while other available sections remain usable; recovery restores the correct values within two seconds after confirmed local data becomes available. Account-switch and preview-isolation scenarios display zero records or totals belonging to another identity.
- **SC-006**: Primary Today journeys pass in Arabic and English on a tested mobile and desktop target, with equivalent owner-state and offline behavior verified on all five required targets. A touch walkthrough and a keyboard-only walkthrough can each open Today, identify both progress summaries, complete a Task and Habit, and open their owner areas within three minutes through labeled visible controls.
- **SC-007**: After existing synchronization delivers the same account's changes to two devices viewing the same local date, both Today views match the synchronized Task, Habit and reward state without duplicate awards or map-linked Task counts. Devices on different local dates display the corresponding date-specific projections while preserving the same underlying records.

## Assumptions

- Feature 006 is Dashboard / Today, the next item after Mind Maps in Namaa plan §§24 and 27. It does not pull later domains forward or add public registration/sign-in.
- The existing prototype is a behavioral reference for the daily overview and navigation. Its fixed 10:00 time for untimed Tasks, clock-based overdue labels, XP estimates and all-domain weighted score do not override the approved Task, Habit and shared reward rules.
- Approved for 006: Task and Habit progress remain separate, with no combined Task/Habit percentage.
- Scope default for 006: display actual recorded daily XP. A combined all-domain progress score, the prototype's 1000-XP daily target, levels and prayer-driven timeline wait for their owning planned features; no replacement weighting formula is invented.
- A day follows the viewing device's local calendar. Task schedule dates and recorded Habit dates keep their approved domain meaning. An XP award instant is grouped into the viewing device's current local day; changing zones may change that grouping without changing the original award.
- A retained completion earned while the Habit was due remains eligible in today's Habit summary after a same-day schedule edit. Undoing it while the Habit is unscheduled removes it from that summary until scheduled again.
- Approved for 006: Do First contains up to three incomplete urgent-and-important Tasks scheduled today or overdue, replacing the prototype's unrestricted date scope. Future-only Tasks without an overdue condition remain available in Tasks. This does not redefine today's scheduled Task set or the existing overdue rule.
- Dependencies are the verified Foundation identity/local-data boundaries, Tasks 003 completion and reward behavior, Habits 004 schedule/day/streak behavior, Mind Maps 005 shared Task links, and the current preference/navigation experience.
- The preview remains local, durable and isolated from real account data. Account-mode aggregation uses existing identity and synchronization boundaries for verification; a user-facing account release still depends on the later Auth feature.
- Core behavior and accessible mobile/desktop use are in scope; final visual redesign, aggregate-history storage, dashboard customization, charts, notifications and new religious or financial logic are not.
