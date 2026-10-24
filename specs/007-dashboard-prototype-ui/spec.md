# Feature Specification: Prototype-Aligned Dashboard UI

**Feature Branch**: `namaa/007-dashboard-ui`

**Created**: 2026-10-24

**Status**: Draft

**Input**: Design the Dashboard first, follow the supplied `prototype.zip` rather than inventing a new layout, use Namaa's existing colors, primary font, and app icon, and give phones a deliberate, polished layout.

**Visual reference**: `../../../prototype/prototype.zip`, specifically `src/views/HomeView.tsx`, `src/components/Header.tsx`, and `src/components/Navbar.tsx`. The archive describes the desired screen; it does not authorize its unrelated product behavior or authentication flow. Namaa plan §21–22 and Feature 006 define the existing data and behavior boundaries.

**Scope**: Refine the Home/Dashboard screen and its directly visible header and navigation. The Dashboard must retain the prototype's content inventory, hierarchy, section order, and intended controls. The first pass does not redesign the owning Tasks, Habits, Mind Maps, Prayer, Quran, Focus, Finance, or More screens. It does not add authentication or new domain records.

## Clarifications

### Session 2026-10-24

- Q: How should the prototype's overall progress ring coexist with the approved independent Task and Habit progress from Feature 006? → A: Keep the prototype's ring and metric presentation with clearly identified sample figures where needed; keep the real Task and Habit percentages separate. Do not invent or calculate a blended real percentage.
- Q: Which visual identity should this pass use? → A: Use the palette, primary font, and app icon already present in Namaa, while following the supplied prototype's structure and composition.
- Q: How should primary navigation adapt to the phone? → A: Keep the sidebar on larger layouts and place the navigation at the bottom on phones, as previously approved by the product owner; retain the prototype's five-destination order.
- Q: How should unfinished destinations behave? → A: Example figures are allowed on the Dashboard if unmistakably labeled as sample data; opening an unfinished feature shows a “Coming soon” destination. This does not make the example figures real account data.
- Q: Should users still complete Habits directly on the Dashboard despite the prototype having no such control? → A: No. Show only the separate real Habit progress summary on the Dashboard; users complete Habits in the Habits owner screen.
- Q: Where should the implemented Habits and Mind Maps be reached without adding primary tabs beyond the prototype's five? → A: Both are reachable from More.
- Q: Should the prototype's Hijri date beside the Gregorian date be live or deferred? → A: Show a real, verified Hijri date beside the Gregorian date now; do not display a fabricated Hijri date.
- Q: Which Hijri calendar defines the displayed date across devices? → A: Use Umm al-Qura for every user and identify the calendar by name.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Recognize the prototype's Home screen (Priority: P1)

As a user familiar with the supplied prototype, I open Namaa and find the same Dashboard sections, in the same order, with the same information hierarchy and navigation choices, so the implemented app feels like the approved reference.

**Why this priority**: Fidelity to the supplied prototype is the explicit direction for this UI phase. A differently composed dashboard would fail even if it used the right colors.

**Independent Test**: Compare the Dashboard on a large screen with the supplied `HomeView`, `Header`, and `Navbar`; record the presence, order, and visual role of every listed element. No owner feature needs a new design for this comparison.

**Acceptance Scenarios**:

1. **Given** the Dashboard is opened, **When** the user scrolls from top to bottom, **Then** it shows the prototype's eight content groups in order: today's progress, next prayer, daily Quran portion, six quick-access hubs, daily timeline, urgent-and-important Tasks, financial summary, and counters snippet. No extra Dashboard panel is inserted between these groups.
2. **Given** the top of the screen is visible, **When** the user scans the header, **Then** the current local Gregorian date and corresponding Umm al-Qura Hijri date, compact status badges, language switch, and quick-add affordance appear in the same relative roles as the prototype; the existing Namaa icon is used for product identification without replacing the greeting. The Hijri calendar is named, and a badge without a live owner is visibly marked as sample.
3. **Given** the progress region is visible, **When** the user scans it, **Then** it has the prototype's prominent circular gauge, XP/status line, level indication, and compact metric badges. Any example-only gauge or badge is visibly marked as sample data; the real Task and Habit completion percentages are presented independently.
4. **Given** the quick-access region is visible, **When** the user scans it, **Then** it contains exactly the prototype's six destinations in the prototype order: Prayer, Focus, Quran, Adhkar, Qiyam, and Counters. Finance remains in its own summary section and in navigation, rather than replacing Counters in this grid.
5. **Given** the primary navigation is visible, **When** the user scans it, **Then** its five prototype destinations are Home, Tasks, Track, Finance, and More, in that order, with the active destination distinguishable without relying on color alone.

---

### User Story 2 - Use a phone-sized Dashboard comfortably (Priority: P1)

As a phone user, I can scan and open the prototype's information without a squeezed desktop layout, clipped text, obstructed content, or hard-to-reach controls.

**Why this priority**: The user explicitly requested a professional mobile composition, not merely a smaller desktop screenshot.

**Independent Test**: Walk through the entire Dashboard on narrow and standard phones in Arabic and English, at normal and enlarged text sizes, using touch and screen-reader labels. Compare element order and content with the large-screen view.

**Acceptance Scenarios**:

1. **Given** a narrow phone, **When** the Dashboard opens, **Then** it uses a single readable vertical flow of the prototype's sections, while the progress badges and quick hubs form compact grids that fit the available width without horizontal scrolling.
2. **Given** a phone safe area or on-screen system bar, **When** the user reaches the last section, **Then** the last card and its controls remain fully visible above the persistent bottom navigation.
3. **Given** an Arabic locale, **When** the phone layout is shown, **Then** reading order, edge spacing, navigation affordances, timeline rail, and directional controls follow right-to-left presentation; English follows left-to-right presentation.
4. **Given** a long title or enlarged text, **When** a prayer, Quran, timeline, Task, metric, or navigation item is shown, **Then** essential content remains readable through wrapping or a purposeful compact layout rather than overflowing or silently replacing meaning with an ellipsis.
5. **Given** a phone user interacting with a visible control, **When** they tap it, **Then** the touch target is comfortably usable, visibly responds, and reaches its intended destination or the explicit “Coming soon” page.

---

### User Story 3 - Distinguish live information from previews (Priority: P1)

As a user testing features before authentication and before all modules are complete, I can tell which Dashboard values reflect my actual work and which illustrate future features, so I do not mistake a preview for my records.

**Why this priority**: The user approved sample numbers on the Dashboard, but the existing daily overview must stay trustworthy.

**Independent Test**: Populate Tasks and Habits with known records, leave future modules unimplemented, open the Dashboard offline, and check the labels, values, and destination for every preview card and control.

**Acceptance Scenarios**:

1. **Given** real Task, Habit, and XP data, **When** the Dashboard is displayed, **Then** any live values match their owning areas; Task and Habit progress are separate and no example number changes either percentage or XP.
2. **Given** Prayer, Quran, Focus, Finance, or Counters is not implemented, **When** its prototype card, badge, or timeline example is displayed, **Then** its figures carry an accessible, visible sample-data label and its interactive destination states “Coming soon.”
3. **Given** a preview card is opened, **When** the user reaches its destination, **Then** the destination does not present a fake detail history or pretend that a sample action was saved.
4. **Given** one live source is loading, empty, outdated, or unavailable, **When** the Dashboard updates, **Then** that section communicates its state without changing a sample into a supposed live zero or blocking other sections.
5. **Given** development preview access, **When** the user opens and leaves the Dashboard, **Then** no public sign-in is required and existing account or preview records remain unchanged by viewing sample content.

---

### User Story 4 - Reach implemented work through the prototype's controls (Priority: P2)

As a user, I can follow the prototype's visible Task and navigation controls to existing work, while future feature controls lead to a clear placeholder, so the Dashboard remains useful without inventing new flows.

**Why this priority**: The prototype contains navigation and a small number of contextual actions; they must have honest destinations in this incremental product.

**Independent Test**: Open each header, quick hub, timeline, priority, finance, counter, and navigation control, then return to Home and check that existing Task, Habit, and Mind Map records are intact and reachable.

**Acceptance Scenarios**:

1. **Given** an implemented Task appears in the daily timeline or urgent-and-important preview, **When** the user opens it or its owner view, **Then** the same Task appears with the same completion state and date; the Dashboard does not create a duplicate Task.
2. **Given** Tasks, Habits, and Mind Maps are already implemented, **When** the user selects Tasks or opens More, **Then** Tasks opens from its primary destination and both Habits and Mind Maps are reachable from More, without extra Home cards or primary tabs.
3. **Given** a due Habit, **When** the user views its Dashboard progress and wants to complete it, **Then** the Dashboard directs them to the Habits owner screen and does not offer a Habit completion control on Home.
4. **Given** an unfinished quick hub or future-data card, **When** the user opens it, **Then** it reaches the matching “Coming soon” destination rather than a functioning-looking but inert control.
5. **Given** a visible quick-add affordance, **When** the user chooses a supported existing creation flow, **Then** it opens that feature's current form; unsupported creation is not offered as a working action.

### Edge Cases

- A day with no scheduled Tasks or eligible Habits shows the approved empty state and does not imply 100% real completion; a sample gauge remains clearly identified as an example.
- A future feature preview may be present even while offline; it never waits on a non-existent data source or claims to have synchronized.
- A timed Task, an untimed Task, and a sample future activity remain distinguishable in the timeline. A sample time is never attached to a real untimed Task.
- The last card remains reachable with gesture navigation, display cutouts, a software keyboard, and text enlargement.
- Long Arabic and English labels, mixed-direction titles, and a small viewport do not make the five navigation destinations or six quick hubs ambiguous.
- Theme and locale changes preserve the approved section order and data/sample distinction.
- If a verified Umm al-Qura conversion cannot be obtained for the current local date, the header shows an explicit date-unavailable state rather than a guessed Hijri value; the Gregorian date remains visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Dashboard MUST follow the supplied prototype's eight Home content groups and vertical section order. The counters snippet MUST use clearly labeled sample values while its owner feature is unfinished. The Dashboard MUST NOT add unrelated sections or substitute one prototype quick hub for another.
- **FR-002**: The directly visible header MUST retain the prototype's greeting/date, status-badge, language-switch, and quick-add hierarchy, and use Namaa's existing app icon. It MUST show the current local Gregorian date and its corresponding Umm al-Qura Hijri date, identify the Hijri calendar by name, and never show an illustrative Hijri date. A status badge without a verified live value MUST be labeled sample. It MUST NOT require authentication to inspect the development preview.
- **FR-003**: The visual treatment MUST use Namaa's already approved color palette and primary font. Layout, spacing, surfaces, corner treatment, icon hierarchy, and emphasis MUST otherwise follow the supplied prototype rather than an independently invented dashboard style.
- **FR-004**: The progress region MUST show a circular gauge, XP/status line, level indication, and six compact metric positions following the prototype composition. Example-only values MUST have a visible and accessible sample-data indication. Actual Task and Habit percentages MUST appear as independent values within this region, with no newly calculated blended real percentage or additional Home section. Habit progress is read-only on Home and leads to the Habits owner screen for completion.
- **FR-005**: The next-prayer preview MUST retain the prototype's next-prayer emphasis, location/time context, remaining-time treatment, following-prayer row, and route to its owning destination; until that owner exists, all prayer values MUST be labeled as sample and the destination MUST say “Coming soon.”
- **FR-006**: The daily Quran preview MUST retain the prototype's title, progress treatment, and reading/destination affordances; while Quran functionality is unfinished, preview figures MUST be labeled sample and controls MUST lead to “Coming soon” without claiming a saved reading action.
- **FR-007**: The quick-access area MUST show six prototype destinations in order: Prayer, Focus, Quran, Adhkar, Qiyam, and Counters. Each destination MUST either open an implemented owner or explicitly identify itself as coming soon.
- **FR-008**: The daily timeline MUST preserve the prototype's vertical-rail and event-card presentation. Real Tasks MUST keep their approved dates, times, order, and completion state; future-domain example events MUST be marked sample and MUST NOT alter Task scheduling or completion.
- **FR-009**: The urgent-and-important preview MUST preserve the prototype's compact card and matrix access while obeying Feature 006's approved scope of at most three incomplete Tasks scheduled today or overdue. It MUST show real Task identity and status.
- **FR-010**: The financial summary MUST preserve the prototype's two-tile spending/savings composition and finance destination. Until Finance is implemented, amounts and progress MUST be visibly marked sample and lead to “Coming soon.”
- **FR-011**: The counters snippet MUST follow the prototype's compact counters-card layout and preview limit. Until Counters is implemented, counts and controls MUST be visibly sample and MUST NOT change a real counter.
- **FR-012**: Primary navigation MUST present the prototype's five destinations—Home, Tasks, Track, Finance, More—in that order. On phones it MUST be a persistent bottom control that respects safe areas; on larger screens it MUST use the previously approved sidebar arrangement with those same destinations and no additional primary destination. More MUST retain access to the implemented Habits and Mind Maps owner screens.
- **FR-013**: The Dashboard MUST remain usable at phone, tablet, and desktop widths without horizontal scrolling or obscured content. The phone composition MUST deliberately stack the prototype's cards, adapt its compact grids, and preserve readable text and reachable controls.
- **FR-014**: Every user-facing label and sample/coming-soon state MUST be available in Arabic and English. Directional layout, navigation, timeline, focus order, and control labels MUST be correct in both directions and usable by touch, keyboard, and assistive technology.
- **FR-015**: This UI pass MUST preserve the existing owner data and approved Task, Habit, XP, preview-identity, and offline rules. The earlier Habit completion shortcut on Today is intentionally replaced by owner-screen navigation under the clarified prototype layout; Habit completion behavior itself MUST remain available in Habits. The UI pass MUST NOT add a new data source, business record, reward rule, blended metric, account flow, or design work for an owning feature's separate screen.

### Key Entities

- **Dashboard section**: One of the ordered visual groups in the supplied Home reference, with a defined information role and optional navigation target.
- **Live summary**: A value derived from an already implemented owning feature, with its current availability and date context.
- **Sample preview**: A visibly labeled illustrative value for an unfinished feature, never treated as a live record or as input to real progress.
- **Navigation destination**: A prototype control's target, classified as an implemented owner or a “Coming soon” placeholder.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A side-by-side review against the supplied Home, Header, and Navbar finds all eight Home groups in the prototype order, the six quick hubs in order, and all five primary navigation destinations in order, with no extra Home group.
- **SC-002**: At 320, 390, and 430 logical-pixel phone widths, plus tablet and desktop widths, the entire Dashboard can be viewed without horizontal scrolling, clipped essential labels, overlapping cards, or content hidden by bottom navigation; the same remains true with text enlarged to at least 150%.
- **SC-003**: In Arabic and English, 100% of inspected future-domain figures are visibly identified as sample and 100% of their controls open an explicit “Coming soon” destination; none changes a real Task, Habit, XP, or future-domain record.
- **SC-004**: With known Task, Habit, and XP fixtures, 100% of live Dashboard values match their owning areas, Task and Habit percentages remain separate, and no sample value contributes to them.
- **SC-005**: In a touch walkthrough on a phone and a keyboard-only walkthrough on a desktop, users can identify real versus sample content, open an implemented Task route, reach all five primary destinations, and find Habits and Mind Maps through More within three minutes without assistance.
- **SC-006**: The Dashboard's section order, five primary destinations, and readable controls remain equivalent in Arabic right-to-left and English left-to-right layouts, including at 150% text size.
- **SC-007**: Across a set of month-boundary, year-boundary, and local-midnight dates, 100% of displayed Hijri dates match Umm al-Qura for the displayed Gregorian local date, the calendar name is visible, and an unavailable conversion never appears as a guessed date.
- **SC-008**: With the same locally available fixture of 500 Tasks, 100 Habits, and 200 XP awards used for Feature 006, the Dashboard's first readable content appears within two seconds on a tested phone and desktop while offline; unfinished-feature previews do not delay that content.

## Assumptions

- This feature is the first screen in the later UI-refinement phase. Subsequent screens will receive their own design work; this specification does not silently redesign them.
- The supplied archive is the visual reference for Home, Header, and Navbar. Its business data, global progress weighting, authentication, and unimplemented feature logic do not override the approved Namaa domain rules.
- The previous approved Feature 006 decision remains in force: real Task and Habit progress are separate. The ring and planned-domain badges may illustrate the prototype using visibly marked sample numbers until all contributing domains exist.
- The user explicitly approved illustrative Dashboard values for unfinished features and “Coming soon” on their owning pages. This visual-preview exception supersedes Feature 006's earlier restriction on fabricated Dashboard display only; it does not authorize fabricated stored records, a real combined score, or invented actions.
- Existing Tasks, Habits, Mind Maps, XP, preferences, and preview access stay available. Changes to their business rules, storage, or synchronization are outside this UI feature.
- The product owner explicitly chose prototype fidelity over Feature 006's Habit completion control on Today. Its independent Habit summary stays visible on Home, while completing/undoing Habits takes place in Habits. This is a presentation-flow change, not a change to Habit records or rules.
- The exact Namaa palette, primary font, and app icon already present in the project are the identity source; no new color system, font, or logo is selected in this feature.
- Umm al-Qura is the approved display convention for the Hijri date on every device, independent of the user's location; religious observance decisions remain outside this Dashboard UI scope.
