# Navigation Contract: Dashboard 007

This is the visible route/action mapping, not a new domain API. Existing app_router.dart and TodayScreen callbacks remain the authority for implemented owners. Any new placeholder is presentation-only.

## Primary navigation

| Position | Label | Phone | Larger layout | Outcome |
|---|---|---|---|---|
| 1 | Home | Bottom item | Sidebar item | Root Today Dashboard, selected when active. |
| 2 | Tasks | Bottom item | Sidebar item | Existing Tasks owner route. |
| 3 | Track | Bottom item | Sidebar item | Localized Track “Coming soon”. |
| 4 | Finance | Bottom item | Sidebar item | Localized Finance “Coming soon”. |
| 5 | More | Bottom item | Sidebar item | Collection with Habits, Mind Maps, Preferences and future entries. |

The visible order and current destination semantics are identical in both layouts. RTL changes direction of reading/padding appropriately, not the identity or logical order of destinations.

## Context controls

| Control | Outcome |
|---|---|
| Header quick add, New Task | Existing Task creation owner intent and form. |
| Header quick add, New Habit | Existing Habit creation owner intent and form, if already supported by the current callbacks. |
| Real timeline Task / Do First Task | Existing Task owner entry or canonical completion callback where that control is shown; identity and status stay intact. |
| Do First matrix access | Existing Task matrix owner intent. |
| Real Habit progress readout | Habits owner route; Home has no Habit complete/undo control. |
| More → Habits | Existing Habits owner route. |
| More → Mind Maps | Existing Mind Maps owner route. |
| More → Preferences | Existing preference sheet/route. |
| Prayer/Quran/Focus/Adhkar/Qiyam/Counters hub | Feature-titled, localized “Coming soon” destination. |
| Preview Prayer/Quran/Finance/Counters card action | Same matching “Coming soon” destination. |
| Track/Finance main destination | Feature-titled, localized “Coming soon” destination. |

## Invariants

1. A visible control must respond and reach its defined owner or placeholder. Do not present disabled, functioning-looking controls with no destination.
2. Coming-soon navigation creates no record, completion, reward, outbox item or fake detail history. Returning leaves existing owner data intact.
3. Implemented owner routes keep current account/preview scope checks; navigation does not bypass them.
4. A sample event has no Task ID and cannot be completed as a Task. A real Task never receives an invented sample time.
5. More may include future links, but it does not add a primary tab or ninth Home group. Habits and Mind Maps must be discoverable from it.
6. The previous Home Habit completion shortcut is intentionally replaced by read-only summary and owner navigation. Existing Habit completion tests remain valid in the owner feature; old Home UI tests are updated to this contract.

