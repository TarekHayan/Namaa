# Habit Interaction Contract

**Consumers:** Habits UI in 004; later Today, Dashboard, and Analytics through explicit Habits application queries. No Task data or public HTTP API is added. See ../data-model.md.

## Commands

Every command resolves the current session account, checks an optional expected account from the screen, and commits locally before reporting success. A command either persists its own record and pending synchronization operation together or returns a typed failure with the last confirmed state intact. Network absence is not a local write failure.

| Command | Input | Observable result |
|---|---|---|
| CreateHabit | Nonblank name, at least one weekday, optional reminder minute | New stable Habit ID and initial schedule revision; appears immediately with streak zero. |
| EditHabit | Habit ID, supported name/weekdays/reminder changes | Same Habit ID. Name and due-today state update immediately. A weekday change adds a schedule revision; existing completion is retained. |
| CompleteHabitToday | Habit ID and current device-local date | Requires today to be selected and not already complete; creates/updates that HabitDay exactly once and recalculates its streak. |
| UndoHabitToday | Habit ID and current device-local date | Clears an existing current-day completion and recalculates streak, even if today was removed from weekdays after completion. |
| DeleteHabit | Habit ID and explicit confirmation | Hides Habit and owned history from active views through a tombstone; other Habits and Tasks are unchanged. |

A missing, deleted, or foreign-account Habit returns a typed not-found/not-authorized failure without leaking another account's data. Blank name, empty weekday set, or invalid reminder minute returns validation failure. Completing an unscheduled or prior date is rejected. Repeat completion when already complete has no new day or reward effect. Undo of an incomplete day is a no-op or a typed validation response, never a second day. No command awards XP.

## Queries and presentation

- Account-scoped list of active Habits with name, selected weekdays, current due state, today's completion, and each independent current streak.
- One Habit history query returns its recorded completed dates and schedule changes, without allowing earlier dates to be edited in 004.
- A Habit reminder time is displayed as saved but inactive. The screen must not imply that an alert is scheduled or permission granted.
- A Habit query is the canonical source for later Today/Dashboard/Analytics consumption. Consumers receive projections or explicit application events, not direct Habit storage access.
- Local committed state is visible without waiting for a cloud pass. Loading, empty, validation failure, local save failure, sync status, and recoverable conflict states must be distinguishable.

A same-day weekday edit updates due-today immediately. If today was completed while due and then removed from the schedule, the completion stays visible and in the streak. The user may undo it today; no new completion is allowed until today is selected again. Closed days are read-only. Unselected days neither count nor break the streak.

## Navigation, localization, accessibility

Register /habits in the existing router behind the current account/session gate. A signed-out or unresolved session cannot construct account-scoped Habit repositories. The existing non-release preview account may enter Habits to test 004 before the separate Auth feature; release builds require the real account boundary and initial synchronization before account-based public release.

Use Arabic and English ARB-backed labels, validation, dates, weekday names, streak wording, and inactive-reminder status. Arabic layout and navigation follow RTL; times and mixed numerals remain readable. Focus order, hit targets, semantic labels for completion/undo, and keyboard operation must work on mobile and desktop. Responsive presentation may differ by form factor without changing Habit rules.

## Verification

Widget/integration checks exercise creation validation, multiple Habits, due-today changes, completion/undo, individual streak/history, same-day schedule edits, saved inactive reminder, deletion confirmation, offline restart, account switch/route guard, localized failures, Arabic/English RTL, and keyboard access. See ../quickstart.md for runnable checks.

