# Tasks: Prototype-Aligned Dashboard UI 007

**Input**: Design documents in specs/007-dashboard-prototype-ui/: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/dashboard-ui.md](contracts/dashboard-ui.md), [contracts/navigation.md](contracts/navigation.md), and [quickstart.md](quickstart.md).

**Tests**: The specification explicitly requires visual, automated, accessibility, date, performance, and target verification. Test tasks below are therefore part of the feature. Write focused assertions before the implementation they cover; keep existing owner/domain invariants.

**Task format**: [P] means safe to work alongside other marked tasks after their stated prerequisites are complete; [USn] maps to a user story. Paths are repository-relative. Do not restore or overwrite unrelated working-tree changes. The current Today UI and tests already have uncommitted edits, so inspect their diffs before editing.

## Phase 1: Setup

**Purpose**: Establish a precise baseline for the supplied reference and current worktree.

- [X] T001 Inventory prototype.zip HomeView.tsx, Header.tsx, and Navbar.tsx against lib/features/today/presentation/today_dashboard_view.dart, lib/features/today/presentation/widgets/today_bottom_navigation.dart, lib/features/today/presentation/widgets/today_navigation_sidebar.dart, and affected tests; record the eight sections, six hubs, five destinations, current gaps, and pre-existing worktree edits in specs/007-dashboard-prototype-ui/verification.md.

**Checkpoint**: Prototype inventory and preserved-work baseline are recorded before implementation.

## Phase 2: Foundational

**Purpose**: Supply localized, explicitly tagged presentation values and one honest placeholder used by all stories. No new persisted owner state.

- [X] T002 [P] Add Arabic ARB keys for prototype-only labels, Track/Counters, sample and stale/unavailable wording, named Umm al-Qura calendar, twelve Hijri months, and contextual placeholder titles in lib/app/l10n/app_ar.arb.
- [X] T003 [P] Add matching English ARB keys and placeholder metadata with identical parameter shapes in lib/app/l10n/app_en.arb.
- [X] T004 Generate Flutter localizations after T002–T003 and verify key/parameter parity in lib/app/l10n/generated/app_localizations.dart, lib/app/l10n/generated/app_localizations_ar.dart, and lib/app/l10n/generated/app_localizations_en.dart.
- [X] T005 [P] Define a small immutable display-value provenance type for live, sample, loading, empty, stale, and unavailable states without persistence in lib/features/today/presentation/dashboard_display_value.dart.
- [X] T006 Build one immutable, presentation-only fixture for ring, unowned badges, prayer, Quran, Finance, Focus, Qiyam, Adhkar, and up to four Counters, using T005 provenance and no owner IDs, in lib/features/today/presentation/dashboard_preview_data.dart.
- [X] T007 Complete the existing localized, feature-titled coming-soon destination with return navigation and no fake saved action in lib/features/today/presentation/widgets/today_coming_soon_page.dart; preserve any uncommitted implementation already in that file.

**Checkpoint**: The shared presentation boundary is ready; no sample can masquerade as a real owner value.

## Phase 3: User Story 1 — Recognize the prototype Home screen (P1, MVP)

**Goal**: Match the prototype's eight-section hierarchy, header, six hubs, and five navigation labels using Namaa identity.

**Independent test**: Side-by-side comparison with HomeView/Header/Navbar on a large screen, plus a widget assertion of section/hub/navigation order; verify Gregorian and named Umm al-Qura dates agree for one injected local date.

### Tests

- [ ] T008 [P] [US1] Add failing widget assertions for exactly eight Home groups in order, six hub labels in order, five main labels in order, and no extra Habits/Explore group in test/widget/features/today/dashboard_prototype_contract_test.dart.
- [ ] T009 [P] [US1] Validate the proposed offline calendar package's source, license, supported dates, actual API, and several KACST month/year-boundary reference vectors; only then add the vetted version to pubspec.yaml and pubspec.lock and record evidence or a blocked adoption in specs/007-dashboard-prototype-ui/verification.md.
- [ ] T010 [US1] Add failing tests for official boundary vectors, unsupported dates, local-midnight/offset refresh, and no guessed fallback in test/unit/features/today/data/umm_al_qura_today_date_test.dart using the vetted reference from T009.

### Implementation

- [ ] T011 [US1] Implement a pure date-only adapter from TodayCalendar.localDate to verified Umm al-Qura fields or unavailable, without a second clock read or network access, in lib/features/today/data/umm_al_qura_today_date.dart.
- [ ] T012 [US1] Build the prototype-role greeting/header with Namaa icon, same-sample Gregorian/Hijri date, calendar name, sample-tagged unowned badges, existing LocaleCubit language switch, and existing quick-add callbacks in lib/features/today/presentation/widgets/today_dashboard_header.dart.
- [ ] T013 [US1] Build the progress hero with circular sample gauge, clearly tagged level/status, real XP, separate real Task/Habit ratios, and six prototype metric positions in lib/features/today/presentation/widgets/today_progress_hero.dart.
- [ ] T014 [P] [US1] Adapt the next-prayer card to the prototype's next/following-prayer, location, time, countdown and sample roles in lib/features/today/presentation/widgets/today_prayer_card.dart.
- [ ] T015 [P] [US1] Adapt the Quran Wird card to the prototype's title, progress and reading affordance with sample status in lib/features/today/presentation/widgets/today_quran_card.dart.
- [ ] T016 [P] [US1] Build the six quick hubs in the exact Prayer, Focus, Quran, Adhkar, Qiyam, Counters order in lib/features/today/presentation/widgets/today_quick_hubs.dart.
- [ ] T017 [P] [US1] Build the vertical-rail timeline from existing TodayAgenda Task references plus separately tagged sample events, preserving real Task time/order/status, in lib/features/today/presentation/widgets/today_timeline_section.dart.
- [ ] T018 [P] [US1] Adapt the compact Do First card and matrix affordance around the existing three-item TodayPriority projection in lib/features/today/presentation/widgets/today_priority_section.dart.
- [ ] T019 [P] [US1] Adapt the Finance summary to the prototype's two spending/savings tiles with sample amounts and destination in lib/features/today/presentation/widgets/today_finance_card.dart.
- [ ] T020 [P] [US1] Build the prototype's compact sample Counters snippet with at most four entries in lib/features/today/presentation/widgets/today_counters_card.dart.
- [ ] T021 [US1] Compose T012–T020 into exactly eight ordered Home groups using existing AppColors, ThmanyahSans and assets/images/namaa_icon.png; remove extra Home-only Habits/Explore panels without removing owner navigation in lib/features/today/presentation/today_dashboard_view.dart.
- [ ] T022 [US1] Align visible labels and positions to Home, Tasks, Track, Finance, More in lib/features/today/presentation/widgets/today_bottom_navigation.dart and lib/features/today/presentation/widgets/today_navigation_sidebar.dart; preserve callbacks for US4 routing.
- [ ] T023 [US1] Run the focused US1 widget/date tests and record a side-by-side large-screen prototype comparison plus unresolved mismatches in specs/007-dashboard-prototype-ui/verification.md.

**Checkpoint**: The reference inventory is recognizable and US1 passes independently; owner features are not redesigned.

## Phase 4: User Story 2 — Comfortable phone Dashboard (P1)

**Goal**: Keep the same content readable and reachable at phone, tablet, and desktop widths in both directions.

**Independent test**: Inspect the complete screen at 320/390/430 logical pixels and 150% text in Arabic and English; bottom navigation never hides the last card.

### Tests

- [ ] T024 [US2] Add failing viewport, text-scale, safe-area, keyboard/focus and RTL/LTR overflow assertions in test/widget/features/today/today_accessibility_test.dart.

### Implementation

- [ ] T025 [US2] Refine the Dashboard shell to a readable single-column phone scroll, constrained large-screen content and bottom-inset clearance without changing section order in lib/features/today/presentation/today_dashboard_view.dart.
- [ ] T026 [P] [US2] Make progress/hub grids and Finance/Counters tiles wrap or reduce columns based on available width and 150% text while retaining item order in lib/features/today/presentation/widgets/today_progress_hero.dart, lib/features/today/presentation/widgets/today_quick_hubs.dart, lib/features/today/presentation/widgets/today_finance_card.dart, and lib/features/today/presentation/widgets/today_counters_card.dart.
- [ ] T027 [P] [US2] Make long bilingual header text, mixed-direction titles and the timeline rail use directional layout and readable wrapping in lib/features/today/presentation/widgets/today_dashboard_header.dart and lib/features/today/presentation/widgets/today_timeline_section.dart.
- [ ] T028 [US2] Ensure persistent phone navigation respects gesture/safe areas, touch targets, visible focus and selected state beyond color in lib/features/today/presentation/widgets/today_bottom_navigation.dart.
- [ ] T029 [US2] Run the focused responsive/accessibility widget checks and document 320/390/430 phone, tablet and desktop observations at normal/150% text in both languages in specs/007-dashboard-prototype-ui/verification.md.

**Checkpoint**: US2 independently meets the phone and accessibility layout contract.

## Phase 5: User Story 3 — Distinguish live information from previews (P1)

**Goal**: Real Task/Habit/XP values remain owner-accurate and independent while every future-domain figure is clearly sample.

**Independent test**: Load known owner fixtures offline and inspect every figure, empty/loading/stale state and sample destination without any new owner record.

### Tests

- [ ] T030 [P] [US3] Add failing widget tests that inventory every sample figure and semantics label and verify no preview action claims a save in test/widget/features/today/today_dashboard_preview_cards_test.dart.
- [ ] T031 [P] [US3] Add failing 10-Task/5-Habit/XP fixture checks for independent ratios, zero-denominator, loading, stale, unavailable and scope changes in test/widget/features/today/today_screen_test.dart.

### Implementation

- [ ] T032 [US3] Map TodayState's owner Task/Habit/XP sections and their available/empty/stale/unavailable statuses to T005 display provenance without a blended score or fake zero in lib/features/today/presentation/dashboard_presentation.dart.
- [ ] T033 [P] [US3] Apply visible and semantic sample markers to ring, unowned level/streak and six metrics, while showing independent owner Task/Habit/XP states, in lib/features/today/presentation/widgets/today_progress_hero.dart.
- [ ] T034 [P] [US3] Apply per-figure sample labels and non-saving preview behavior to prayer, Quran, finance, counters and sample timeline events in lib/features/today/presentation/widgets/today_prayer_card.dart, lib/features/today/presentation/widgets/today_quran_card.dart, lib/features/today/presentation/widgets/today_finance_card.dart, lib/features/today/presentation/widgets/today_counters_card.dart, and lib/features/today/presentation/widgets/today_timeline_section.dart.
- [ ] T035 [US3] Bind the presentation projection without writing data; retain owner Task/Habit/XP isolation, TodayPriority's due/overdue three-item cap and live-source recovery in lib/features/today/presentation/today_dashboard_view.dart.
- [ ] T036 [US3] Run the US3 widget and existing Today projection tests; record fixture values, provenance audit, offline read-only behavior, and any unresolved source states in specs/007-dashboard-prototype-ui/verification.md.

**Checkpoint**: US3 passes with correct owner numbers and 100% of future figures marked sample.

## Phase 6: User Story 4 — Reach implemented work (P2)

**Goal**: Every visible control opens the correct existing owner or a matching coming-soon destination; Habits and Mind Maps live under More.

**Independent test**: Exercise header, timeline, Do First, each hub, Finance, Counters and both navigation layouts, then confirm owner records stay intact.

### Tests

- [ ] T037 [P] [US4] Add failing owner/placeholder route tests for five main destinations, More → Habits/Mind Maps, each hub and preview card in test/widget/app/today_owner_navigation_test.dart and test/widget/features/today/dashboard_navigation_test.dart.
- [ ] T038 [P] [US4] Add failing quick-add cancellation, existing Task opening/completion, and read-only Home Habit assertions in test/widget/app/today_creation_route_test.dart and test/widget/features/today/today_actions_test.dart.

### Implementation

- [ ] T039 [P] [US4] Wire phone Home/Tasks/Track/Finance/More to the existing owner callbacks or T007 coming-soon page; put Habits and Mind Maps inside More in lib/features/today/presentation/widgets/today_bottom_navigation.dart.
- [ ] T040 [P] [US4] Wire the same five destinations and More owner links in the desktop sidebar, removing the unapproved XP-to-level inference, in lib/features/today/presentation/widgets/today_navigation_sidebar.dart.
- [ ] T041 [US4] Connect the header/hub/card callbacks and existing owner routes from TodayScreen without bypassing app_router.dart account/preview gates in lib/features/today/presentation/today_screen.dart and lib/features/today/presentation/today_dashboard_view.dart.
- [ ] T042 [US4] Keep quick add on current Task/Habit forms, real timeline/Do First Task actions on canonical Task callbacks, and Home Habit progress read-only with owner navigation in lib/features/today/presentation/widgets/today_dashboard_header.dart, lib/features/today/presentation/widgets/today_timeline_section.dart, and lib/features/today/presentation/widgets/today_priority_section.dart.
- [ ] T043 [US4] Replace superseded Home Habit-tab/completion assertions with More → Habits owner-flow checks while retaining Habit domain/action assertions in test/widget/features/today/today_actions_test.dart and test/widget/features/today/today_accessibility_test.dart.
- [ ] T044 [US4] Run the focused route/creation/action suites and document phone touch and desktop keyboard journeys, including all five destinations and both More owner links, in specs/007-dashboard-prototype-ui/verification.md.

**Checkpoint**: Every visible action has an honest destination and existing owner data survives round trips.

## Phase 7: Polish and cross-cutting verification

**Purpose**: Close the explicit success criteria and the constitution's UI/target gates without repetitive full-device runs after each edit.

- [ ] T045 [P] Extend Arabic/English theme, directionality, semantic labels, focus order and 150% text regressions for the final Dashboard in test/widget/app/localization_and_directionality_test.dart.
- [ ] T046 [P] Update the existing Dashboard integration journey to assert preview entry without public sign-in, no sample-induced mutation, owner Task/Habit/Map access and offline return in integration_test/today_dashboard_test.dart.
- [ ] T047 [P] Reuse the 500-Task/100-Habit/200-XP fixture to measure first readable Dashboard content under two seconds offline on a phone and desktop in integration_test/today_performance_test.dart; record device/build/timing evidence in specs/007-dashboard-prototype-ui/verification.md.
- [ ] T048 Run flutter analyze, formatting, focused suites and the repository's established quality/database plus Android, iOS, Windows, macOS and Linux integration gate before merge; record real results, failures and platform coverage in specs/007-dashboard-prototype-ui/verification.md.
- [ ] T049 Compare the final UI with prototype.zip and audit FR-001–FR-015/SC-001–SC-008, the three-minute touch/keyboard journeys, Umm al-Qura reference vectors and constitution compliance; record evidence or unresolved blockers without claiming completion in specs/007-dashboard-prototype-ui/verification.md.

## Dependencies and execution order

- Phase 1 → Phase 2 → US1 → US2/US3/US4 → Polish. The three later stories use the US1 composed shell but each has its own independent acceptance test.
- Within Foundation: T004 depends on T002–T003; T006 depends on T005; T007 needs the localized copy generated by T004.
- Within US1: T010 depends on vetted vectors from T009; T011 depends on T009–T010; T012 depends on T011; T013 depends on T006; T021 depends on T012–T020; T023 depends on T021–T022 and tests. T008 can start while the calendar gate is checked.
- Within US2: T024 precedes the corresponding layout work; T025 precedes final shell verification; T026 and T027 use different widget files and can proceed together; T028 precedes T029.
- Within US3: T030–T031 precede the corresponding provenance work. T032 precedes binding in T035; T033 and T034 can proceed together after the shared value contract is ready; T036 closes the story.
- Within US4: T037–T038 precede route/action wiring. T039 and T040 can proceed together; T041–T043 follow their relevant navigation and test changes; T044 closes the story.
- T045–T047 can run on distinct test files after all stories, but T048–T049 require their results. No full five-target run is required after every ordinary branch commit; run the final gate before merge.

## Parallel execution examples

- **Foundation**: T002 Arabic ARB, T003 English ARB, and T005 display provenance touch different files; then generate localization and build the fixture.
- **US1**: After shared contracts exist, T014 prayer, T015 Quran, T016 hubs, T017 timeline, T018 priority, T019 Finance and T020 Counters can be built in separate files before T021 composes them.
- **US2**: T026 adaptive grids and T027 directional header/timeline touch separate widget sets after T024 defines expected layouts.
- **US3**: T030 sample-card tests and T031 owner/section-state tests use different files; T033 hero and T034 preview cards can then be refined separately.
- **US4**: T039 bottom navigation and T040 sidebar are separate files; their behavior is integrated by T041.

## Implementation strategy

1. **MVP**: Complete Setup, Foundation and US1, then compare the large-screen Home with the prototype and run US1 tests. This proves visual inventory and the verified date without claiming mobile/owner readiness.
2. Complete US2 for phone usability, US3 for trustworthy values, then US4 for all owner/placeholder routes. Each phase has a focused checkpoint.
3. Finish Polish with real mobile/desktop evidence and one final target gate before integration. Never mark a task complete based only on a rendering screenshot or a partial platform run.

