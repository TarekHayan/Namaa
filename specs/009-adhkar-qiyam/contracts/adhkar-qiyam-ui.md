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

1. **Header line.** "Your own adhkar" with a short note that they are not part of the reviewed lists and earn no XP. An **Add** button, disabled at 100 items with the reason.
2. **Empty state.** One sentence on what the tab is for, and the Add button.
3. **Item cards**, oldest first, in the same card style as the catalog items:
   - the user's text in Amiri, with `TextDirection` taken from the text itself so mixed Arabic and Latin text stays readable;
   - the note, when present, in the secondary style;
   - count/target, the count button and reset, with the same semantics labels;
   - an overflow menu with **Edit** and **Delete**. Delete asks for confirmation in the page itself.
   - No number badge, no "Virtue and source" toggle and no completion celebration.
4. **Add / edit sheet.** A bottom sheet on phone and a dialog on desktop, with the text field (counter to 1000), the target field (1–1000, default 1) and the note field (counter to 300). Save is disabled until the text is valid. Errors are inline and localized.
5. **Locked state.** When the schedule is unavailable, the cards stay visible, counting is disabled, and the same notice as the other tabs shows.

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
