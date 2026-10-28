# UI Contract: Dashboard Home 007

This contract is the observable Flutter UI boundary for [spec.md](../spec.md). The supplied prototype.zip HomeView/Header/Navbar fixes section inventory, order and visual role; existing Namaa colors, font, icon and approved product rules fix identity and behavior.

## Home content inventory

| Order | Group | Required visible structure | Value provenance |
|---|---|---|---|
| 1 | Today's progress | Prominent circular gauge; XP/status and level; six compact metric positions: Tasks, Prayer, Quran, Adhkar, Focus, Qiyam. Independent real Task and Habit progress within the same group. | Gauge and unowned metrics/level sample; Tasks/Habits/XP only owner-derived. |
| 2 | Next prayer | Primary next-prayer emphasis, city/location and time context, remaining-time treatment, following-prayer row. | Sample until Prayer owner exists. |
| 3 | Quran Wird | Portion title, progress treatment and reading/destination affordance. | Sample until Quran owner exists. |
| 4 | Quick hubs | Exactly Prayer, Focus, Quran, Adhkar, Qiyam, Counters in that order. | Navigation only; unfinished destinations say coming soon. |
| 5 | Daily timeline | Vertical rail, timed event cards, untimed Task area, sample future-domain events if shown. | Real Task identity/time/state retained; future events tagged sample. |
| 6 | Do First | Compact urgent-important Task preview, maximum three, with Task/matrix access. | Real owner Tasks only: due today or overdue, incomplete. |
| 7 | Finance | Two-tile spending/savings composition and destination. | Sample figures until Finance owner exists. |
| 8 | Counters | Compact preview, at most four counters and destination. | Sample figures and no real increment. |

An independent Habits list or Explore panel must not appear as a ninth Home group. Habits and Mind Maps remain reachable through More. A group with no real owner result shows its own loading/empty/unavailable state; it does not disappear in a way that changes the eight-group hierarchy.

## Header and identity

- Greeting and product identification use the existing Namaa app icon, without replacing the greeting.
- Show the Gregorian civil date and the corresponding verified Umm al-Qura date from the same TodayCalendar.localDate. Name the Hijri convention. If conversion is unsupported/invalid, Gregorian stays visible with a localized unavailable label.
- Keep compact status badges, language switch and quick add in their prototype roles. Any unowned status badge is visibly and semantically sample.
- Quick add exposes only supported owner creation flows; cancellation creates nothing.

## Sample and live semantics

- Every sample number has nearby visible “sample data” wording and an accessibility label that includes its sample status. A generic screen-wide disclaimer alone is insufficient.
- Real Task/Habit progress is never merged. If denominator is zero, show an empty state, not 100%. XP zero appears as confirmed live zero only when its source confirmed it.
- Stale live data is marked outdated with existing retry behavior. Loading/unavailable is not rendered as a live zero or substituted sample.
- Sample controls route to matching coming-soon pages and never claim they saved reading, financial, counter, prayer or focus state.
- No sample datum enters an owner callback, persistence, sync queue, Task/Habit denominator or XP calculation.

## Layout and interaction

- Preserve section order and content on all widths. Larger screens use the sidebar; phones use persistent bottom navigation. Tablet arrangement may adapt while retaining all five destinations.
- At 320, 390 and 430 logical-pixel phone widths and 150% text, no horizontal scrolling, clipped essential label, overlapped card or inaccessible last card. Grids may wrap/collapse while maintaining item order. The bottom control respects safe area and does not cover content.
- Arabic uses RTL directional padding, alignment, timeline rail and icon affordances; English uses LTR. Mixed-direction titles remain readable.
- Touch targets, visible keyboard focus, semantic roles/labels, logical focus order, and selected navigation state must be usable without relying on color alone.
- Theme/locale changes do not alter content inventory or live/sample classification.

## Acceptance evidence

Automated widget tests assert the eight group keys/order, six hub order, five destination order, provenance labels, owner projections, responsive overflow and RTL/LTR. A side-by-side prototype review checks visual hierarchy. Phone touch and desktop keyboard walkthroughs exercise all destinations and owner access within the success criterion's three-minute window. See [quickstart.md](../quickstart.md).

