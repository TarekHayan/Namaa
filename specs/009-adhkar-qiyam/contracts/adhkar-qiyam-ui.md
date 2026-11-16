# Adhkar and Qiyam UI and navigation contract

References: [spec](../spec.md) FR-018…021, prototype `AdhkarView.tsx` and `QiyamView.tsx`, and the current Namaa theme and shared widgets.

## Routes and shell

- **Routes.** `/adhkar` and `/qiyam` are new top-level sibling routes in `app_router.dart`. They sit behind the same account gate and preview behavior as `/prayer`.
- **Navigation sections.** `TodayNavigationSection` gains `adhkar` and `qiyam`, and both highlight **Track** in the bottom bar and the sidebar.
  - The screens open with `go`. There is no stacked route and no app-bar back arrow.
  - Device back returns Home.
  - Opening one from an overlay closes the overlay first.
- **Entry points.**
  - **Track hub:** the Adhkar and Qiyam tiles become active, with live subtitles: "Morning 3/10 · Evening 0/9" and "Last third 02:41" or "Recorded".
  - **Home quick hubs:** the Adhkar and Qiyam hubs open the real screens.
  - **Home focus/reflection card:** its Adhkar rows open the screens.

  Quran and Focus stay "coming soon".

## Adhkar screen (prototype order)

1. **Heading.** The title and subtitle, the **Adhkar streak** chip (FR-006b), and the Morning / Evening / My Adhkar segmented switch (sun, moon and bookmark icons).
   - The switch opens on the current period. It never opens on My Adhkar by itself.
   - If there is no schedule, an inline notice links to the Prayer location setup.
2. **Progress card.** "Morning (x / N)", a progress bar and the percentage.
   - When the list is outside its time, a notice reads: "Its time starts at {time}".
3. **Item cards,** one per catalog item, in order:
   - the number badge;
   - the "Virtue and source" toggle, which expands the Arabic virtue and reference (labels in the app language);
   - the reset button, with a tooltip;
   - the Arabic text in Amiri, in both app languages (no translation in v1). A Quran item shows its preface line (the isti'adha) apart from the verses, the verses in a font that renders the Uthmani script, and its surah and verse numbers;
   - the count/target ("Target 2 / 3");
   - the large count button: "Tap to count (n)", then "Completed".
     - Its semantic label is "Count, 2 of 3".
     - It is disabled when the item is complete or the list is not countable.
4. **Completed set.** A celebration toast and the XP feedback. A second award is never shown.

## My Adhkar tab (Story 5)

A personal collection with two levels inside the Adhkar page: the **group list** and an opened **group**. Opening a group replaces the list in place, with a "back to groups" control in the tab itself (no app-bar back arrow; device back returns to the group list first, then Home).

1. **Header line.** "Your own supplications and adhkar" with a short note that they are not part of the reviewed lists.
2. **Group list.**
   - A **Create a group** button, disabled at 100 groups with the reason.
   - Group rows, oldest first: the name (direction from the text) and "n entries". An overflow menu with **Rename** and **Delete**.
   - Delete asks for confirmation in the page itself, stating how many entries will be deleted and that entries also in other groups stay there.
   - Create and rename use a small sheet (dialog on desktop) with the name field (counter to 60).
3. **Empty state** (no groups). One sentence on what the tab is for, with examples of groups («الفجر», «رمضان», «أدعية الكرب»), and the Create a group button.
4. **Opened group.** The group name as the heading, an **Add** button (disabled at 1000 entries, with the reason), an empty state when the group has no entries, and the entry cards in the order they were added to the group.
5. **Entry cards**, in the catalog's card style:
   - the text in Amiri, selectable, with `TextDirection` taken from the text itself so mixed Arabic and Latin text stays readable;
   - the source, when present, below it in the secondary style, selectable, with its own direction (a link is plain text and is never opened);
   - when the entry is in other groups too, a small line with their names;
   - an overflow menu with **Edit**, **Copy** (the text, plus the source on a new line when present) and **Delete**. Delete asks for confirmation in the page itself and says the entry leaves all its groups.
   - No number badge, no counter, no target, no reset and no celebration.
6. **Add / edit sheet.** A bottom sheet on phone and a dialog on desktop, with two fields, the text (multi-line, counter to 2000) and the source (optional, counter to 500, hint "a book, a scholar or a link"), and the group choice (chips of the live groups, multi-select, the opened group preselected). Save is disabled until the text is valid and at least one group is selected. Errors are inline and localized.
7. **No locked state.** My Adhkar has no time window, so it stays fully usable when the Prayer schedule is unavailable.

## Qiyam screen (prototype order)

1. **Heading.** The title and subtitle, a chip with the last third of the night (or the unavailable reason with a Prayer-setup link), and the **Qiyam streak** chip.
2. **Tracker card.** "Did you pray Qiyam tonight?", the "Best time" note, and the **Yes (+30 XP)** and **No** buttons.
   - When the answer is Yes, the details form shows:
     - the rak'ah chips 2/4/8/11, default 4;
     - the start and end time pickers;
     - the Witr checkbox, default on;
     - the note field (500 characters, with a counter).
   - The tracker is read-only when the night is not the current one, which only happens if it is reopened after Maghrib from a stale state.
3. **Supplications card.** The two supplications from the catalog, in Amiri, each with its source.
4. **History section** (added in the prototype's style).
   - Past nights, newest first, 30 per page. Each shows "Prayed · 4 rak'ahs · Witr" or "Not recorded" (for no row), or "Did not pray" (for an explicit No).
   - It is read-only, and never uses the word "missed".

## Conflicts

When either domain has retained conflict records for the owner, a compact "Sync differences" row opens a read-only list, styled like Prayer's conflict view, with both versions and their times. No resolution actions are offered. This matches 008.

## Accessibility and layout

- **Layout.** RTL and LTR from ARB strings, light and dark themes, 320–1200 px widths, and 100–200% text scale with no clipping. The phone layout is a single column. On desktop, cards are capped at a readable width and the Qiyam history sits in a side column at ≥ 1024 px.
- **Keyboard.** The keyboard reaches every control. Space or Enter on the focused count button counts once. Key-repeat counts each repeat, but never beyond the target.
- **Screen readers.** They announce the count changes and the completion of a set.
- **Strings.** Every string lives in `app_ar.arb` and `app_en.arb` (line-based edits only). The adhkar, supplication and source texts come from the reviewed catalog, not from ARB files.
