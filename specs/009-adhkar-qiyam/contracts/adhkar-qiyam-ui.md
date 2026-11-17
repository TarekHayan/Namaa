# Adhkar and Qiyam UI and navigation contract

References: [spec](../spec.md) FR-018…021, prototype `AdhkarView.tsx` and `QiyamView.tsx`, and the current Namaa theme and shared widgets.

## Routes and shell

- **Routes.** `/adhkar` and `/qiyam` are new top-level sibling routes in `app_router.dart`. They sit behind the same account gate and preview behavior as `/prayer`.
- **Navigation sections.** `TodayNavigationSection` gains `adhkar` and `qiyam`. On a phone both highlight **Track** in the bottom bar; on desktop the sidebar selects their own item, as Prayer does (approved design, 2026-11-17).
  - The screens open with `go`. There is no stacked route and no app-bar back arrow.
  - Device back returns Home.
  - Opening one from an overlay closes the overlay first.
- **Entry points.**
  - **Track hub:** the Adhkar and Qiyam tiles become active, with live subtitles: "Morning 3/10 · Evening 0/9" and "Last third 02:41" or "Recorded".
  - **Home quick hubs:** the Adhkar and Qiyam hubs open the real screens.
  - **Home focus/reflection card:** its Adhkar rows open the screens.

  Quran and Focus stay "coming soon".

## Adhkar screen (approved design, 2026-11-17)

The owner approved a Claude Design canvas for the whole section on 2026-11-17 ("Namaa Adhkar reader", pages 1 and 2). It replaces the prototype's list of item cards. The canvas is the reference for layout, sizes, colors and states; its HTML sources are kept locally (not in git). The app uses its real fonts (Thmanyah Sans, Amiri, KFGQPC Uthmanic Hafs) where the canvas fell back to web fonts, and Quran verse-end markers come from the KFGQPC font inside the catalog text, not from drawn circles.

1. **Adhkar page.**
   - The title «الأذكار», the subtitle, and the Morning / Evening / My Adhkar tabs. The tabs open on the current period, never on My Adhkar by themselves; switching tabs changes only the content below.
   - For Morning and Evening: a progress card with a ring and percentage, "Morning (x / N)", the time-window line, the streak row, and the main button: «ابدأ», «متابعة من الذكر n» (the first item not done), or, when the list is done today, the finished state with «قراءة القائمة مرة أخرى» (opens item 1).
   - With no Prayer schedule, the setup notice and the «إعداد موقع الصلاة» button; the reader still opens, locked.
   - A compact «اختلافات المزامنة» row at the bottom, only when conflicts exist.
2. **Reader** (one item per page, opened from the main button; full screen inside `/adhkar`, no shell).
   - Top bar: the list button (opens the list sheet), the list title, and a close (×) button that returns to the Adhkar page on the same tab. A thin progress bar for the whole list under it.
   - The page: the optional preface line (accent), the text (Quran font for Quran items, Amiri otherwise; the text area scrolls while the counter stays fixed), the reference line (accent), and a collapsible «فضل الذكر» when the item has a virtue.
   - Under a divider: the repetition chip («ثلاث مرات») and the position «n | N».
   - The bottom bar: the large round count button with its progress ring, the reset button (with a confirmation dialog), and an empty slot reserved for a later audio button.
   - Each tap counts once, up to the target. At the target the number becomes a check and a «تمّ الذكر · التالي» bar shows for about 600 ms, then the page slides to the next item (the next page enters from the left in Arabic and from the right in English). The last item opens the completion state («اكتملت الأذكار!», «+15 نقطة», «العودة إلى الأذكار»).
   - Swipe moves between items at any time, both ways, stopping at the first and last item. Counts are kept per item.
   - The list sheet shows every item with its first words, its count and a done mark; tapping a row jumps to it.
   - Locked (outside the window, or no schedule): the text stays readable and swipe works; the count and reset buttons are disabled, a lock replaces the number, and a banner gives the reason (with the setup button for the no-schedule case). It unlocks by itself when the window opens.
   - Content unavailable: the error state with a retry button.
   - Desktop (wide): a centered column of at most 720 px, round previous/next buttons beside it, Space or Enter counts, and the arrow keys move (in Arabic the left arrow goes to the next item).
   - Semantic label of the count button: "Count, 2 of 3". A second award is never shown.
3. **Device back** closes the topmost layer first (reset dialog, list sheet, reader, then the sync page), then goes Home.

## My Adhkar tab (Story 5)

A personal collection with two levels inside the Adhkar page: the **group list** and an opened **group**. Its look follows the approved design (2026-11-17, canvas page 2); the behavior below is unchanged. Leaving the tab closes an open group. Device back closes an open sheet, then an in-place confirmation, then the group, then goes Home. Opening a group replaces the list in place, with a "back to groups" control in the tab itself (no app-bar back arrow; device back returns to the group list first, then Home).

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
   - an overflow menu with **Edit**, **Copy** (the text, plus the source on a new line when present) and **Delete**. Delete turns the card into a confirmation in place and says the entry leaves all its groups. Copy shows a «تم النسخ» toast.
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

When either domain has retained conflict records for the owner, a compact "Sync differences" row on the Adhkar page opens a read-only page inside `/adhkar` (approved design, 2026-11-17): each entry has its title («أذكار الصباح · الذكر 8», «أذكاري · مجموعة», «أذكاري · ذكر») and both versions, stacked on phone and side by side on desktop, each with its time and value (a count, a group name, or a dhikr's text cut to three lines, or «محذوف»), and the footer «للعرض فقط؛ لا يوجد إجراء.». No resolution actions are offered. Device back returns to the Adhkar page.

## Accessibility and layout

- **Layout.** RTL and LTR from ARB strings, light and dark themes, 320–1200 px widths, and 100–200% text scale with no clipping. The phone layout is a single column. On desktop, cards are capped at a readable width and the Qiyam history sits in a side column at ≥ 1024 px.
- **Keyboard.** The keyboard reaches every control. Space or Enter on the focused count button counts once. Key-repeat counts each repeat, but never beyond the target.
- **Screen readers.** They announce the count changes and the completion of a set.
- **Strings.** Every string lives in `app_ar.arb` and `app_en.arb` (line-based edits only). The adhkar, supplication and source texts come from the reviewed catalog, not from ARB files.
