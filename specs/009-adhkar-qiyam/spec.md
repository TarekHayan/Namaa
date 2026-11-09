# Feature Specification: Adhkar and Qiyam

**Feature Branch**: `namaa/009-adhkar-qiyam`

**Created**: 2026-11-09

**Status**: Draft

**Input**: User description: "نبدأ ع الشغل الجديد Phase 4 --- Religious Experience اقرأ من ال plan و prototype". In English: start Phase 4, Religious Experience, working from the plan and the prototype.

## Clarifications

### Session 2026-11-09

- Q: A Qiyam logged at 03:00 on Thursday belongs to which night? → A: To Wednesday night. A night starts at Maghrib (from the location's Prayer schedule). A record belongs to the most recent night that has started. So 03:00 or 10:00 on Thursday both go to Wednesday night, and 20:00 on Thursday goes to Thursday night.
- Q: Can a past night's Qiyam be recorded or edited? → A: Only the current night, meaning the most recent night that has started. Recording last night therefore stays possible until today's Maghrib. Older nights are read-only in history, as in Prayer 008.
- Q: Do users see their past Adhkar days? → A: Only as one number: an Adhkar streak of consecutive days on which **both** Morning and Evening were completed. There is no Adhkar history list.
- Q: Who approves the religious content? → A: The product owner reviews and approves every adhkar and supplication text, its reference and its grading in `content-sources.md` before it ships. The agent prepares the file and the source comparison but does not approve it.
- Q: Are Qiyam reminders part of 009? → A: No. They move to the Notifications phase with Adhan and the other reminders. 009 sends no notifications.
- Q: When do the Adhkar reset, and do the time rules apply? → A: The product owner gave the ruling: Morning Adhkar start after Fajr, and Evening Adhkar start at sunset (Maghrib). Applied from the location's Prayer schedule:
  - The Adhkar day starts at Fajr.
  - The Morning list can be counted from Fajr until Maghrib.
  - The Evening list can be counted from Maghrib until the next Fajr. Evening counting after midnight still belongs to the same Adhkar day.
  - Outside its time, a list stays visible but read-only, with "its time starts at …".
  - Adhkar opens on the list whose time it is now.
  - When no Prayer schedule is available, both lists stay open, the day runs midnight to midnight on the device clock, and a prompt offers the Prayer location setup.

**Scope note**: Phase 4 of `namaa_plan.md` covers Prayer, Quran (Reader, Wird, Audio, Memorization, Bookmarks/History), Dhikr and Qiyam. Prayer shipped in 008. On 2026-11-09 the product owner chose to build **Morning/Evening Adhkar and Qiyam** next, as one feature. Quran follows in separate later specs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Recite the Morning and Evening Adhkar with a counter (Priority: P1)

The user opens Adhkar and picks Morning or Evening. They go through a fixed, sourced list of adhkar.

Each item shows:
- its Arabic text;
- its English translation when the app language is English;
- its target count and current count;
- an expandable "Virtue and source" panel.

A large tap target adds one to the count. When the count reaches the target, the item shows as completed and stops counting. The user can reset a single item.

A progress bar shows completed items out of total, and a percentage, for the selected list. When every item in a list is complete, the day's set is complete and earns its XP once. An Adhkar streak shows how many consecutive days both lists were completed.

**Why this priority**: Adhkar is the daily core of this feature. It delivers value on its own, offline, with no other domain needed.

**Independent Test**: Open Adhkar offline, complete every Morning item, restart the app, and confirm the counts, completion and single XP award persist.

**Acceptance Scenarios**:

1. **Given** Adhkar opens for the first time today, **When** the user views Morning, **Then** all Morning items show in their fixed order, each at count 0 with its target, and progress reads 0 of N (0%).
2. **Given** an item with target 3 at count 2, **When** the user taps count, **Then** the count becomes 3, the item shows completed, and further taps do not change it.
3. **Given** a partially counted item, **When** the user resets it, **Then** its count returns to 0, it is no longer completed, and list progress updates.
4. **Given** the last incomplete Morning item, **When** its target is reached, **Then** the Morning set is complete, a celebration shows, and the Morning XP is awarded exactly once for that day.
5. **Given** the Morning set was completed and XP awarded, **When** the user resets an item and completes it again the same day, **Then** no second award is made.
6. **Given** counts were recorded today, **When** the app is closed and reopened offline, **Then** every count and completion is unchanged.
7. **Given** a new Adhkar day begins, **When** Adhkar opens, **Then** both lists start at 0 for the new day, and the previous day's completion is kept for the Adhkar streak. The new day starts at Fajr (FR-006).
8. **Given** both lists were completed on each of the last 3 Adhkar days, and only Morning is done today, **When** Adhkar shows, **Then** the Adhkar streak reads 3. It becomes 4 when Evening is completed today, and it resets to 0 if today ends without both lists done.
9. **Given** a Prayer schedule and the time is 21:00, **When** Adhkar opens, **Then** Evening is selected. Morning is viewable but read-only, with "its time starts at Fajr (05:xx)".
10. **Given** no Prayer location, **When** Adhkar opens, **Then** both lists are countable, and a prompt offers to set up the Prayer location so the Adhkar times apply.
11. **Given** the user expands "Virtue and source" on an item, **When** shown, **Then** the virtue text and the hadith/book reference appear in the app language.

---

### User Story 2 - Log tonight's Qiyam (Priority: P1)

The user opens Qiyam and sees two things:
- the start of the last third of the night, taken from their Prayer schedule (location and method);
- a short "best time for Qiyam" note.

They answer "Did you pray Qiyam?" with Yes or No.

When the answer is Yes, they can also record:
- rak'ahs, chosen from 2, 4, 8 or 11;
- whether Witr was included;
- optional start and end times;
- an optional short note.

Marking Yes the first time for a night earns the Qiyam XP once.

The page also shows a short list of authentic supplications for Witr and Sujood, each with its source.

**Why this priority**: Qiyam logging is the second half of the owner's chosen scope. It is independent of Adhkar and reuses the existing Prayer schedule.

**Independent Test**: With a saved Prayer location, open Qiyam, mark Yes with 4 rak'ahs and Witr, and restart. The record and the single XP award must persist, and the last-third time must match the Prayer screen.

**Acceptance Scenarios**:

1. **Given** a valid Prayer schedule, **When** Qiyam opens, **Then** the start of the last third of the night shows, and it is the same value the Prayer screen shows for that night.
2. **Given** Prayer has no usable location or time, **When** Qiyam opens, **Then** the last-third value is explained as unavailable, with a way to set up Prayer location. Logging Qiyam still works.
3. **Given** no answer yet for this night, **When** the user marks Yes, **Then** the details form appears with the default 4 rak'ahs and Witr checked, the record is saved, and the Qiyam XP is awarded once.
4. **Given** Yes is recorded, **When** the user changes rak'ahs, Witr, times or notes, **Then** each change is saved without a second XP award.
5. **Given** Yes is recorded, **When** the user changes it to No, **Then** the night is recorded as not performed, the details are cleared, and the XP already awarded stays. No shaming or "missed" wording is used.
6. **Given** an end time earlier than the start time, **When** entered, **Then** it is accepted as crossing midnight, because Qiyam can run past 00:00.
7. **Given** a Qiyam answer, **When** saved, **Then** it belongs to the most recent night that has started at Maghrib. A log made at 03:00 or 10:00 on Thursday belongs to Wednesday night (FR-011).

---

### User Story 3 - Qiyam streak and history (Priority: P2)

The user sees their current Qiyam streak and a history of past nights. Each night shows performed or not answered, plus rak'ahs and Witr when recorded.

**Why this priority**: The plan requires a Qiyam streak and history. Both depend on Story 2's records.

**Independent Test**: Seed Yes records on three consecutive nights, then confirm streak 3 and three history entries. Remove the middle night and confirm the streak resets accordingly.

**Acceptance Scenarios**:

1. **Given** Yes on the last N consecutive nights including the current or previous night, **When** Qiyam opens, **Then** the streak shows N.
2. **Given** a night with no Yes between two Yes nights, **When** the streak is computed, **Then** it counts only from the most recent unbroken run.
3. **Given** tonight is not answered yet, **When** the streak shows, **Then** it still counts the run that ended last night. An unanswered current night does not break it until that night is over.
4. **Given** a night before the current one, **When** it is opened in history, **Then** it is read-only, and no control lets the user add or change it.
5. **Given** history is opened, **When** shown, **Then** nights appear newest first with their recorded details. Unanswered nights read as "not recorded", never as "missed".
6. **Given** the Qiyam streak, **When** compared with Habit or Prayer progress, **Then** it stays separate and is never merged with another domain's streak.

---

### User Story 4 - Reach Adhkar and Qiyam from Home and Track, synced across devices (Priority: P2)

Today the Track hub tiles and the Home "Daily Adhkar & Sunan" card are placeholders. With this feature:
- Home and the Track hub show real progress: Morning x/N, Evening x/N, and tonight's Qiyam state.
- Tapping a tile or card opens the real Adhkar or Qiyam screen, using the existing tab-style navigation.
- A signed-in account's Adhkar and Qiyam records sync to its other devices, and work offline in between.

**Why this priority**: Reaching the feature from the dashboard and keeping one account consistent makes it a real product area. The core value still works locally without it.

**Independent Test**:
1. Complete Morning Adhkar on device A offline and reconnect.
2. On device B, confirm the same Morning completion, Home progress and a single XP award.
3. Mark Qiyam on B and confirm it on A.

**Acceptance Scenarios**:

1. **Given** Morning progress 5 of 10, **When** Home shows, **Then** its Adhkar card shows Morning 5/10, matching the Adhkar screen.
2. **Given** the Track hub on phone or the desktop sidebar entry, **When** Adhkar or Qiyam is chosen, **Then** that screen opens as a tab with no stacked back arrow. Device back returns Home.
3. **Given** the same account on two devices offline, **When** both count the same item and reconnect, **Then** both converge to one result. A differing version is kept as a visible conflict record, never silently dropped, and XP is awarded once per set and day.
4. **Given** a retried or duplicated sync delivery, **When** applied, **Then** no count, record or XP is duplicated.
5. **Given** a second account on the same device, **When** it opens Adhkar or Qiyam, **Then** it never sees the first account's records.

---

### Edge Cases

- **The time changes while the screen is open** (for example, Maghrib arrives). The list's countable state updates without restarting.
- **Day changes mid-session.** A tap targets the item and day that were shown. It does not silently apply to the new day.
- **Rapid tapping.** Every tap is counted until the target. No count passes the target.
- **Prayer schedule unavailable** (no location, or high latitude with no computable night). Qiyam still logs; only the last-third hint is unavailable.
- **Clock or time-zone change.** Records keep the day or night they were made for. Display follows the rule in Q1/Q3.
- **Content update.** If a future app version changes the adhkar list, already recorded days keep their counts by stable item identity. Removed items are not shown as incomplete.
- **Text scale up to 200% and narrow phones (320 px).** Arabic text wraps without clipping, and the count button stays reachable.
- **Debug preview mode (no account).** Adhkar and Qiyam work locally without cloud sync, as Tasks, Habits and Prayer do.

## Requirements *(mandatory)*

### Functional Requirements

**Adhkar**

- **FR-001**: The system MUST provide two fixed lists, Morning and Evening, from a reviewed, sourced set. Each item has:
  - a stable identity;
  - Arabic text;
  - an English translation;
  - a target count;
  - a virtue text in Arabic and English;
  - a hadith/book reference in Arabic and English.
- **FR-002**: Adhkar Arabic text and references MUST come from a documented source review, like Prayer's guidance-sources review in 008. Text MUST NOT be generated or paraphrased by the app.
- **FR-003**: Users MUST be able to increment an item by one, up to its target, and to reset a single item to 0.
- **FR-004**: An item MUST show completed exactly when its count equals its target.
- **FR-005**: Each list MUST show completed items out of total, and a percentage, for the current Adhkar day.
- **FR-006**: Counts MUST belong to an Adhkar day and start at 0 on a new day. Past days' completion MUST be retained.
  - With a Prayer schedule, the Adhkar day runs from Fajr to the next Fajr.
  - Without one, it runs from midnight to midnight on the device clock.
- **FR-006a**: With a Prayer schedule:
  - The Morning list MUST be countable only from Fajr until Maghrib.
  - The Evening list MUST be countable only from Maghrib until the next Fajr.
  - Outside its time, a list MUST stay viewable but read-only, and show when its time starts.
  - Adhkar MUST open on the list whose time it is now.
  - Without a schedule, both lists MUST stay countable, with a prompt to set up the Prayer location.
- **FR-006b**: The system MUST show an Adhkar streak.
  - It counts consecutive Adhkar days on which both Morning and Evening were completed.
  - The current day does not break it before the day ends.
  - It MUST stay specific to Adhkar.
  - No Adhkar history list is shown.
- **FR-007**: Completing all items of a list for a day MUST award that list's XP (Morning 15, Evening 15) exactly once per list per day. Later resets or re-completions MUST NOT award again or revoke the award.

**Qiyam**

- **FR-008**: Qiyam MUST show the start of the last third of the night, computed from the user's Prayer schedule. It MUST be the same value the Prayer screen shows. When it is unavailable, the screen MUST say so and offer the Prayer location setup.
- **FR-009**: Users MUST be able to record, per night:
  - performed (Yes) or not performed (No);
  - when Yes: rak'ahs (2, 4, 8 or 11; default 4), Witr included (default yes), and optional start time, end time and note (up to 500 characters).
- **FR-010**: The first Yes for a night MUST award the Qiyam XP (30) exactly once. Edits, changing to No and back, and resyncs MUST NOT award again or revoke the award.
- **FR-011**: Each Qiyam record MUST belong to one night. Night D starts at Maghrib on date D (from the location's Prayer schedule), and a record belongs to the most recent night that has started. Without a schedule, a record made before 12:00 local time belongs to the previous date's night; otherwise it belongs to the current date's night.
- **FR-011a**: Recording and editing MUST be limited to the current night. Earlier nights MUST be read-only in history, with no backdated entry.
- **FR-012**: The system MUST compute a Qiyam streak of consecutive performed nights. The current unanswered night MUST NOT break it before the night ends. The streak MUST stay specific to Qiyam.
- **FR-013**: Users MUST be able to view Qiyam history, newest first, with each night's recorded details. Nights with no record MUST read as "not recorded", never "missed".
- **FR-014**: The Qiyam screen MUST show the prototype's authentic supplications (Witr/Sujood), each with its source, under the same source review as FR-002.
- **FR-015**: This feature MUST NOT send notifications. Qiyam reminders, which may only fall between Isha and Fajr, are deferred to the Notifications phase.

**Shared**

- **FR-016**: Every action MUST apply and persist locally first, work fully offline, and survive restart.
- **FR-017**: A signed-in account's Adhkar counts and Qiyam records MUST sync to its other devices.
  - Retries and duplicates MUST be idempotent.
  - Conflicting versions MUST keep the newest as active and the other as a visible conflict record.
  - Records MUST be isolated per account.
- **FR-018**: Home's Adhkar card and the Track hub MUST show live Morning, Evening and tonight's Qiyam progress, and MUST open the real screens. Navigation MUST follow the existing tab model: no stacked pages, no app-bar back arrow, and device back returns Home.
- **FR-019**: All user-facing text MUST be localized in Arabic and English, with correct RTL layout. Adhkar and supplication Arabic text MUST display in the app's Quran/Arabic display font.
- **FR-020**: The screens MUST keep the prototype's structure.
  - **Adhkar:** a heading with a Morning/Evening switch, then a progress card, then the item cards (number, virtue toggle, reset, text, count/target, count button).
  - **Qiyam:** a heading with the last-third time, then the Yes/No tracker with the details form, then the supplications card.
  - The streak and history (Story 3) are added in the prototype's visual language.
- **FR-021**: The screens MUST be usable by touch and keyboard, expose meaningful screen-reader labels (for example "Count, 2 of 3"), and adapt to phone and desktop widths in light and dark themes.

### Key Entities

- **Dhikr item** (reference content, not user data): stable ID, list (Morning or Evening), order, Arabic text, English translation, target count, virtue (AR/EN), reference (AR/EN).
- **Adhkar day progress**: the owner, the Adhkar day, and per item ID the current count. Completion is derived as count = target.
- **Adhkar set completion**: the owner, the day and the list. It records whether XP was awarded, and it is the idempotency anchor for the award.
- **Qiyam night record**: the owner and the night. Performed yes or no; rak'ahs; Witr; optional start, end and note; when it was updated; whether XP was awarded.
- **Adhkar streak** (derived): computed from per-day set completions and never stored as a separate truth.
- **Qiyam streak / history** (derived): computed from the night records and never stored as a separate truth.
- **Conflict record**: a non-winning version of a synchronized Adhkar day progress or Qiyam night, kept visible.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can complete a full Morning list of 10 items, from opening Adhkar to "set complete", using only taps, with each count registering within 100 ms of the tap. In a scripted journey, a user records tonight's Qiyam (Yes, rak'ahs, Witr) in under 30 seconds.
- **SC-002**: 100% of displayed adhkar and supplication texts and references match the documented source review, with zero app-generated religious text.
- **SC-003**: Across 10 automated restart and offline cycles, 100% of counts, completions and Qiyam records persist unchanged.
- **SC-004**: In two-device tests with retries, duplicates and concurrent edits, XP for each Adhkar set and day and each Qiyam night is awarded exactly once (0 duplicates). No record is lost silently; every non-winning version is visible as a conflict.
- **SC-005**: The Qiyam last-third time equals the Prayer screen's value for the same night in 100% of tested locations and methods.
- **SC-006**: Home and Track progress match the Adhkar and Qiyam screens in 100% of checked states. Both screens render without clipping at 320 px, 100–200% text scale, AR/EN and light/dark, on a named phone and on desktop.
- **SC-007**: Adhkar and Qiyam streak values are correct for every seeded pattern (consecutive, gap, unanswered current night, history across a time-zone change).
- **SC-008**: Morning and Evening are countable exactly inside their Fajr–Maghrib and Maghrib–Fajr times, in 100% of tested locations and methods, including across midnight.

## Assumptions

- **Source content.** The prototype's 10 Morning and 9 Evening adhkar, with their virtues and references, and its two Qiyam supplications, are the starting content. They are kept only after a source review documented in the spec folder. Items that fail review are removed rather than rewritten.
- **XP values.** The XP values follow the prototype defaults (Morning 15, Evening 15, Qiyam 30) and use the centralized XP authority from earlier features. They are not user-configurable in this feature.
- **Adhkar streak.** The plan names streaks only for Qiyam and Quran Wird. The Adhkar streak was added by the product owner on 2026-11-09. It is a number only, with no history list.
- **No editing of the lists.** Users cannot add, edit or reorder adhkar. Custom counters (the prototype's "Counters" page) are a separate area and out of scope.
- **Qiyam rak'ahs.** The prototype's options 2, 4, 8 and 11 are kept. A free-number input is out of scope.
- **Prayer is a dependency.** The last third and the Isha–Fajr window come from the existing Prayer schedule (008). Qiyam does not ask for location itself.
- **Out of scope:**
  - associating Qiyam with a Task;
  - achievements and badges;
  - the Analytics view;
  - Quran (Reader, Wird, Audio, Memorization, Bookmarks/History).
- **Authentication.** It uses the existing account boundary and debug preview behavior. Building authentication (proposed spec "auth") is not part of this feature.
