# Research: Dashboard Prototype UI 007

## Reference and fidelity

**Decision**: Treat prototype.zip HomeView.tsx, Header.tsx and Navbar.tsx as the composition reference. The approved Namaa palette, ThmanyahSans, icon, user clarifications and Feature 006 data rules take precedence over React sample behavior. Home has exactly eight groups in order: progress, next prayer, Quran Wird, six hubs, timeline, Do First, finance, counters. The quick hubs are Prayer, Focus, Quran, Adhkar, Qiyam, Counters. The five main destinations are Home, Tasks, Track, Finance, More.

**Rationale**: This is the explicit product direction and gives a finite comparison checklist. Existing Today currently adds independent Habits and Explore groups, and its navigation uses Habits instead of Track; those are presentation gaps to correct without removing owner access.

**Alternatives considered**: Retain the extra Today groups or use the deleted docs/design dashboard references. Both would conflict with the current prototype instruction. Copying React logic/business data would bypass existing Flutter authorities.

## Live versus sample data

**Decision**: Build only a presentation projection over TodayState. Task and Habit percentages come independently from TodayTaskSummary and TodayHabitSummary. XP comes from TodayXpSummary. A sample overall ring and unfinished-domain figures stay in one fixed, read-only preview fixture and carry a visible and semantic “sample data” marker at every display site. When a live source is loading, empty, stale or unavailable, use TodaySectionStatus rather than a fake zero. No sample enters a live numerator, denominator, XP total, streak or saved record. The level/streak badges stay sample unless an existing owning authority explicitly supplies a verified value; the current sidebar calculation XP ~/ 200 + 1 is not an approved level authority.

**Rationale**: Existing Today projections already enforce owner/date filtering, deduplication and priority scope. Sample provenance keeps previews honest while preserving the prototype composition.

**Alternatives considered**: A new Dashboard store, blended real progress or deriving level from XP in the view. Each would introduce an unapproved source of truth. Removing future cards would fail the visual contract.

## Navigation and actions

**Decision**: Keep five destinations in the prototype order in both layouts. Use the existing Tasks route and callbacks; put Habits and Mind Maps in More. Route Track, Finance and all unfinished hubs/cards to one localized coming-soon presentation with a distinct feature title. Quick add offers only existing Task/Habit creation flows. Habit progress on Home is read-only; completion/undo remains in Habits. Preserve canonical Task open/completion behavior through existing owner intents.

**Rationale**: Existing owner routes are already account/preview aware. More maintains discoverability without adding primary destinations or extra Home panels.

**Alternatives considered**: Extra tabs or disabled inert links. They conflict with the approved five destinations and “Coming soon” behavior.

## Responsive composition

**Decision**: Use content constraints rather than shrink a desktop grid. Keep the current approximately 1100 logical-pixel sidebar threshold as a starting implementation boundary, then verify tablet/phone behavior at test widths; sidebar above it and safe-area bottom navigation below it. On phone use one scrolling column, approximately three-column hub/metric grids only when labels remain readable, one-column finance, and a two-column counters preview that can collapse further for large text. LayoutBuilder/Wrap may change column count but never order. Keep the prototype's visual roles, vertical rail, clear card boundaries and six-hub order. Respect bottom navigation height with Scaffold/safe-area inset and keyboard behavior.

**Rationale**: The existing view already uses this breakpoint, minimizing routing/layout churn. Adaptive grids satisfy 320px and 150% text without horizontal scrolling.

**Alternatives considered**: Fixed pixel sizes from React or desktop cards scaled down. Both risk overflow, clipped meaning and obscured controls.

## Umm al-Qura date

**Decision**: Convert the already-sampled TodayCalendar.localDate (civil year/month/day) with a finite, offline Umm al-Qura table. Candidate dependency: [general_datetime_core 1.0.0](https://pub.dev/packages/general_datetime_core), whose documented CalendarSystems.ummAlQura.fromGregorianDay API claims AH 1300–1600 coverage and no runtime dependencies. Use a date-only UTC constructor for this conversion, not another clock read. Format the returned fields with ARB month names and visible “Umm al-Qura” wording. Out-of-range or conversion failure shows a localized unavailable state alongside the still-visible Gregorian date.

**Rationale**: Dart intl in this project formats the existing Gregorian date but does not establish a verified Umm al-Qura conversion. Unicode ICU distinguishes [ISLAMIC_UMALQURA](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/IslamicCalendar.CalculationType.html) from generic/civil Islamic calendars. The prototype's generic islamic formatter therefore cannot satisfy SC-007. TodayCalendar.localDate already handles device-local midnight and timezone changes.

**Mandatory adoption gate**: At implementation, resolve and inspect the package/version/license and actual API, pin its version in the lockfile, then compare several month and year boundaries against [KACST's official Umm al-Qura calendar](https://www.ummulqura.org.sa/en), including dates around 1 Muharram and adjacent days, on all affected targets. The package is new and its source is not itself the Saudi official calendar. If reference checks disagree or the package cannot be validated, stop adoption and use a verified finite official month table or obtain a corrected reference before displaying Hijri. Never silently substitute a different algorithm or a guessed date. This is an implementation quality gate, not a new product decision.

**Alternatives considered**: Device locale calendars (inconsistent across devices), intl's generic Islamic calendar (different algorithm), online date API (offline/performance dependence), and hand-written arithmetic approximation (unverified at boundaries).

## Localization and accessibility

**Decision**: Add Arabic/English ARB entries for all new navigation/section labels, sample marker, coming-soon/unavailable states, calendar name and month labels. Use directional Flutter padding/alignment and semantics that state live/sample provenance and current destination. Preserve logical reading order across both directions; adapt text wrapping instead of relying on ellipsis for essential meaning.

**Rationale**: This follows constitution VII and prevents a visually plausible preview from being announced as real account data.

**Alternatives considered**: Hard-coded dual-language strings or color-only distinctions. Neither meets localization/accessibility requirements.

## Verification scope

**Decision**: First validate package/date boundaries, pure presentation provenance, owner route mappings and section order with focused tests. Then test 320/390/430px phones, tablet and desktop, Arabic/English, 150% text, semantics, touch/keyboard flow, offline performance and affected five-target integration before merge. Update old Today UI assertions only where the user explicitly replaced Home Habit action with owner navigation; retain Habit domain/action tests and existing data-integrity checks. Reuse Feature 006's scale fixture rather than creating production seed data.

**Rationale**: The feature changes presentation and routes, not persistence. Relevant tests catch the risks without repeated full-device runs for each edit.

**Alternatives considered**: Rerun every device after every commit or rely on screenshots alone. The first wastes time; the second misses provenance, semantics and owner route regressions.

