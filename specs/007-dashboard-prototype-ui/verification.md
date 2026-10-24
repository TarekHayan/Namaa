# Verification Evidence: Dashboard Prototype UI 007

This file records evidence as implementation progresses. An unchecked acceptance criterion or a documented gap remains open; this baseline does not claim that the Dashboard is implemented.

## Phase 1 baseline — 2026-10-24

### Reference identity

- Reference archive: `D:/MyWork/My work/Mobile application/Flutter/My projects/namaa/prototype/prototype.zip`
- SHA-256: `D01ACC4D41A0C5A2A675B0C30E8E35972D4F452C3DE252458C4853B4E6F56818`
- Inspected entries: `src/views/HomeView.tsx`, `src/components/Header.tsx`, `src/components/Navbar.tsx`, and `docs/05_UI_AND_DESIGN_SYSTEM.md`.
- Baseline branch: `namaa/007-dashboard-ui`; HEAD `0c08dfe970c492bb6c4dc3b308942f3d18be2f5d`; base `develop` at `0501cf18c90d70a0a9cb944987f1e0e183cc8752`.
- Specification quality gate: `checklists/requirements.md` has 16 checked items and 0 unchecked items.

### Prototype contract inventory

The prototype Home content order is fixed as follows:

| Order | Prototype group | Defining structure |
|---|---|---|
| 1 | Today's progress | Circular gauge, XP/level line, then six metrics: Tasks, Prayer, Quran, Adhkar, Focus, Qiyam. Metrics use three columns on narrow screens and six from the prototype's small breakpoint. |
| 2 | Next prayer | Next-prayer identity/time, location/context, countdown/progress, following-prayer row. |
| 3 | Daily Quran Wird | Wird title, progress, streak/status and reading/destination controls. |
| 4 | Quick hubs | Exactly Prayer, Focus, Quran, Adhkar, Qiyam, Counters, in that order; three columns on narrow screens and six on wider screens. |
| 5 | Daily timeline | Vertical rail/nodes with interactive event cards. |
| 6 | Do First | Up to three urgent-important Tasks and access to the Task owner/matrix. |
| 7 | Finance | Two tiles for spending and savings; one column on narrow screens and two on wider screens. |
| 8 | Counters | Up to four counter tiles; two columns on narrow screens and four on wider screens. |

The prototype Header contains greeting/name, Gregorian and Hijri dates, streak and level badges, language switch, and quick add. Feature 007 overrides only the prototype's generic Islamic-calendar conversion: the Flutter implementation must use the approved, named Umm al-Qura convention from the same `TodayCalendar.localDate` and must expose an unavailable state rather than guess.

The prototype Navbar contains exactly five destinations in this order:

1. Home
2. Tasks
3. Track
4. Finance
5. More

The approved Flutter adaptation uses this order in a phone bottom bar and a larger-layout sidebar. Habits and Mind Maps remain implemented owner destinations under More.

### Current Flutter baseline and gaps

| Area | Current baseline | Gap to 007 |
|---|---|---|
| Home order | `today_dashboard_view.dart` currently composes progress, prayer, Quran, hubs, Tasks/timeline-like content, Do First, Finance, an independent Habits group, Counters-like content, then Explore. | Independent Habits and Explore are extra Home groups. The screen must expose exactly the eight reference groups and move Habits/Mind Maps access to More. |
| Progress | Current hero has a gauge and six positions, but positions are Tasks, Habits, XP, Prayer, Quran, Focus. | Reference positions must be Tasks, Prayer, Quran, Adhkar, Focus, Qiyam; real Task/Habit ratios still appear independently in this group. Unowned ring/level/streak must be explicitly sample. |
| Header | Current AppBar shows Namaa icon, a greeting, Gregorian date, quick add, and Preferences. | Missing verified named Umm al-Qura date, streak/level roles with honest provenance, and a direct language switch. |
| Quick hubs | Current order is Prayer, Focus, Quran, Adhkar, Qiyam, Finance. | Sixth hub must be Counters. Finance remains in its summary and main navigation. |
| Timeline | Current `_tasks` area uses Task-list presentation and separate sample rows rather than the prototype's continuous vertical rail/event-card hierarchy. | Build a single vertical-rail timeline while preserving canonical Task identity/time/order and tagging future-domain entries sample. |
| Do First | Existing `TodayPrioritySection` already consumes the owner projection and its three-item cap. | Restyle into the compact reference card without changing Feature 006 eligibility/order rules. |
| Finance | A sample Finance section exists. | Reduce/align it to the reference two-tile spending/savings composition and preserve visible sample provenance. |
| Counters | Current `_counterPreview` is labelled through Adhkar copy and presents two devotional rows. | Replace it with the reference Counters snippet, at most four clearly sample entries, with no mutation. |
| Phone navigation | Current order is Home, Tasks, Habits, Finance, More. | Replace Habits with Track; place Habits and Mind Maps under More. |
| Sidebar | Current primary list exposes Home, Tasks, Habits, Mind Maps, followed by disabled preview links; it derives a level as `xp ~/ 200 + 1`. | Use the same five main destinations as phone. Remove the unapproved level inference; keep owner links in More. |
| Coming soon | Untracked `today_coming_soon_page.dart` already provides a localized page used by Finance. | Preserve this work and extend it as the common feature-titled destination; it must never imply a saved action. |
| Responsive shell | Current work uses a sidebar at 1100 logical pixels, bottom navigation below it, a constrained scroll, and some width-dependent grids. | Verify/adapt at 320/390/430, tablet and desktop widths plus 150% text, safe areas, keyboard and both directions. |

### Affected test baseline

- `test/widget/features/today/today_screen_test.dart` has pre-existing worktree edits for the newer preview cards and Finance coming-soon route, but still uses direct Home Habits navigation elsewhere.
- `test/widget/features/today/today_accessibility_test.dart` expects a direct Home Habit action, a primary Habits bottom item, and `kTodayHabitsNavigationKey`; these assertions must change only where the approved 007 flow moves completion/navigation to the Habits owner through More.
- `test/widget/features/today/today_actions_test.dart` verifies direct Home Habit completion. Its owner/domain invariant coverage must remain, while the Home presentation expectation becomes read-only.
- `test/widget/features/today/today_dashboard_preview_cards_test.dart` covers four older standalone preview widgets at 320 pixels and 150% text; it does not yet prove the composed eight-group contract or every sample figure.
- `test/widget/app/today_route_test.dart` still expects the independent `kTodayHabitsNavigationKey` on Home.
- `test/widget/app/today_owner_navigation_test.dart` currently covers Task matrix/overdue intents only; it does not yet cover the five main destinations, More owner links, or future placeholders.
- No current test proves the exact eight-group, six-hub, or five-destination order, a named verified Umm al-Qura date, unsupported-date fallback, or the final 320/390/430 responsive contract.

### Preserved pre-existing worktree state

The Phase 1 task did not modify app code, tests, assets, or previously changed design files. Before this task, the worktree already contained:

- Deleted tracked legacy reference files under `docs/design/dashboard_refrence/desktop/`, `mobile/`, `tablet/`, and `serene_verdant_glass/DESIGN.md`.
- Modified `lib/features/today/presentation/today_dashboard_view.dart`.
- Modified `lib/features/today/presentation/widgets/today_bottom_navigation.dart`.
- Modified `test/widget/features/today/today_screen_test.dart`.
- Untracked `lib/features/today/presentation/widgets/today_coming_soon_page.dart`.
- Untracked `specs/007-dashboard-prototype-ui/` planning artifacts.

The branch also contains two existing Dashboard commits above `develop`: `8bc168c feat(ui): enrich today dashboard with brand previews` and `0c08dfe feat(ui): add responsive dashboard navigation`. Later phases must build on and review these changes rather than restore files wholesale or overwrite unrelated user work.

### Phase 1 result

- T001: complete.
- Tests: not run; Phase 1 is a read-only inventory/documentation task.
- App implementation status: unchanged and not yet compliant with the 007 contract.

## Phase 2 foundation — 2026-10-24

- Added matching Arabic and English Dashboard copy for the prototype section/navigation roles, explicit live/sample/loading/empty/stale/unavailable states, the named Umm al-Qura calendar, all twelve Hijri months, contextual coming-soon titles, and return navigation.
- Verified ARB parity across 408 keys. The `dashboardHijriDate` method has the same `day`, `month`, and `year` string parameters in both locales.
- Regenerated `FoundationLocalizations`; the base, Arabic, and English generated outputs expose the new keys and matching Hijri method signature.
- Added `DashboardDisplayValue<T>` with explicit live, sample, loading, empty, stale, and unavailable provenance. It has no serialization or persistence surface.
- Added one constant `DashboardPreviewData.standard` fixture. Its ring, level/streak, Prayer, Quran, Finance, Focus, Qiyam, Adhkar, and four Counter values are all sample-provenance values, use no account/owner identifiers, and keep locale-dependent formatting outside the fixture.
- Preserved and completed the existing coming-soon page with a localized return control, contextual title, localized explanation, and no action that claims to save data.
- Focused validation: `flutter analyze lib/features/today/presentation` and the final `dart analyze lib/features/today/presentation/dashboard_preview_data.dart` passed with no issues after the two reported implementation errors were corrected.
- Focused widget regression: `flutter test test/widget/features/today/today_dashboard_preview_cards_test.dart` passed all four Arabic/English, light/dark, 320-pixel and 150%-text cases.

### Phase 2 result

- T002–T007: complete.
- No database, synchronization, authentication, or owner feature behavior changed.
- Phase 3 and all final acceptance criteria remain open.

## Phase 3 — Prototype Home hierarchy and Umm al-Qura date — 2026-10-24

### Calendar dependency review

- Added `general_datetime_core` `1.0.0`, a pure-Dart package with a BSD-3-Clause license and no runtime dependency chain. The examined source exposes `CalendarSystems.ummAlQura.fromGregorianDay(DateTime)` and has a finite Umm al-Qura table rather than an algorithmic fallback.
- The adapter passes only `TodayCalendar.localDate` to that API as a UTC civil day. It does not read a second clock and it returns `null` for unsupported table dates.
- The selected vectors are `2024-03-10 → 29 Sha'ban 1445`, `2024-03-11 → 1 Ramadan 1445`, and `2024-07-07 → 1 Muharram 1446`. The first Ramadan boundary is corroborated by the Saudi Press Agency's official announcement; the date convention is named on the header as Umm al-Qura. The package's own table provenance is ICU/OpenJDK, so a further official calendar regression audit remains part of final T049 rather than being inferred from this dependency alone.

### Implemented Home contract

- The Home body now has exactly eight ordered keyed groups: Progress, Prayer, Quran, Quick hubs, Timeline, Do First, Finance, and Counters. The independent Home Habits and Explore panels were removed; their owner routes are kept for More in the next navigation story.
- The header shows Namaa identity, Gregorian and named Umm al-Qura dates from the same calendar sample, language choice when `LocaleCubit` is available, quick add, and preferences.
- The progress group keeps real Task, Habit, and XP values separate. Its six prototype metric positions are Tasks, Prayer, Quran, Adhkar, Focus, and Qiyam; future-domain values remain visibly sample-tagged.
- The quick hubs are exactly Prayer, Focus, Quran, Adhkar, Qiyam, and Counters. Finance remains a separate sample summary. The existing agenda and Do First projections continue to use canonical task references and their existing three-item cap.
- Phone and desktop navigation now expose Home, Tasks, Track, Finance, and More. Track and Finance use the honest coming-soon destination; Habits and Mind Maps remain reachable under More. The sidebar no longer derives a user level from XP.

### Focused validation

- `flutter test test/unit/features/today/data/umm_al_qura_today_date_test.dart test/widget/features/today/dashboard_prototype_contract_test.dart` passed.
- `flutter analyze` over the Phase 3 adapter, Dashboard, header, navigation widgets, and contract test passed.
- The widget contract exercises the eight group keys in their on-screen order, confirms no Home Habits/Explore group exists, checks the six hub labels, and checks the five phone destination labels.

### Open after this phase

- Phase 4 owns the final phone/tablet width, safe-area, text-scale, and RTL/LTR checks.
- Phase 5 will complete the per-figure provenance/semantics audit. Phase 6 owns complete routing interaction tests, including every card and More path.

