# Implementation Plan: Prototype-Aligned Dashboard UI

**Branch**: namaa/007-dashboard-ui | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: The 007 specification and the supplied prototype.zip (HomeView.tsx, Header.tsx, Navbar.tsx).

## Summary

Recompose the existing Today screen to match the prototype's eight Home groups, header roles, and five navigation destinations, while retaining Namaa's palette, ThmanyahSans font, and app icon. Adapt the composition for phone, tablet, and desktop. Existing Today projections remain the only source for real Tasks, Habits, and XP; preview values for unfinished domains are visibly sample data and open a localized coming-soon destination. Convert the same device-local date used by Today to a verified Umm al-Qura date without network access or an invented fallback.

## Technical Context

- **Language/Version**: Flutter/Dart, Dart SDK ^3.11.5; existing CI Flutter 3.41.8.
- **Primary dependencies**: Existing flutter_bloc, go_router, intl, Flutter ARB/gen_l10n, AppColors, ThmanyahSans and icon assets. Candidate pure-Dart general_datetime_core 1.0.0 only for table-based Umm al-Qura conversion, subject to the explicit dependency/reference gate in [research.md](research.md).
- **Storage**: No new tables, migrations, API, or persisted preview state. Read owner Task/Habit/XP projections through TodayCubit and TodayState.
- **Testing**: Focused Dart unit and Flutter widget tests; existing Today and owner navigation regression suites; targeted mobile and desktop walkthroughs, then the established five-target integration gate before merging.
- **Target platform**: Android, iOS, Windows, macOS, Linux; Arabic RTL and English LTR.
- **Project type**: Cross-platform Flutter application; bounded presentation and navigation change.
- **Performance goal**: First readable Dashboard content within two seconds with the existing 500-Task/100-Habit/200-XP local fixture on a phone and desktop, offline; previews add no network wait.
- **Constraints**: Exact prototype content inventory and order; real Task and Habit percentages stay separate; no invented domain records or blended score; phone safe areas, 320 logical-pixel width, 150% text, keyboard/touch/semantics; no public sign-in gate in development preview.
- **Scale/scope**: One Home screen, its header and primary navigation, one shared coming-soon presentation, and localized copy. Owning feature screens and domain rules remain outside scope.

## Constitution Check

*Gate before Phase 0 research; repeated after Phase 1 design.*

| Principle / gate | Decision and evidence | Result |
|---|---|---|
| I. Five-target Flutter parity | One Flutter presentation model, adaptive layout, and pure-Dart date conversion; no target-specific business rule. | Pass |
| II & VI. Feature ownership and state | Consume TodayState projections and existing owner callbacks; Tasks, Habits, and XP remain authoritative. No new reward, streak, or combined real score. | Pass |
| III, IV & IX. Local data, accounts, protection | No persisted state, sync operation, credential, API, or migration. Preview/account identity continues through existing Today scope and owner routes. | Pass |
| V. Sacred and financial records | Quran and Finance are labeled presentation samples; no Quran text, prayer record, ledger, or financial mutation is created. | Pass |
| VII. Arabic-first accessibility | ARB/gen_l10n supplies every label, calendar month, sample marker and unavailable state; RTL/LTR and assistive semantics have explicit tests. | Pass |
| VIII. Small, evidence-driven change | Reuse existing Cubit, projection, theme, routes and tests. A date conversion dependency is justified only by verified offline Umm al-Qura coverage and must pass package/reference checks before adoption. | Pass with verification gate |
| Delivery / Definition of Done | Prototype comparison, real/sample correctness, responsive/accessibility checks, focused automated checks, performance evidence, and affected targets are explicit in [quickstart.md](quickstart.md). | Pass |

**Post-design recheck**: [data-model.md](data-model.md) defines ephemeral presentation values only; [contracts/dashboard-ui.md](contracts/dashboard-ui.md) keeps owner operations and placeholders separate; [contracts/navigation.md](contracts/navigation.md) maps routes without extending domain data. No constitutional exception or new authority is introduced. The Umm al-Qura dependency remains a mandatory implementation verification gate, not permission to display an unverified date.

## Implementation Approach

1. Inventory the prototype Home/Header/Navbar and compare with the current Today widget tree. Use the eight ordered groups and existing Namaa identity tokens as the acceptance baseline. Preserve unrelated uncommitted UI work while editing affected files.
2. Build a small read-only presentation projection from TodayState with explicit live, sample, loading, empty, stale, and unavailable provenance. Retain owner-derived Task/Habit/XP results, priority cap and Task timeline ordering. Keep sample fixtures centralized and presentation-only.
3. Split Home into maintainable section widgets for header, hero, prayer, Quran, hubs, timeline, priority, finance and counters; use width-aware grids/stacking without changing section order. Remove the two extra Home groups while retaining Habits and Mind Maps in phone More and directly in the desktop sidebar.
4. Align the phone bottom navigation to Home, Tasks, Track, Finance, More. Use the desktop sidebar's space to list every current destination directly, with unfinished entries opening a localized coming-soon page. Follow the prototype's 64-pixel desktop header, 16-pixel initial content gap, centered 1024-pixel content well with 24-pixel gutters, and 20-pixel section gaps; use an adaptive date row on compact layouts. Habit completion remains in Habits.
5. Convert TodayCalendar.localDate to Umm al-Qura using a verified finite offline calendar table. Format via localized ARB month names and show the calendar name. On unsupported or failed conversion, keep Gregorian visible and show a localized unavailable state. Never use a separate clock sample or intl's generic Islamic calendar as a silent substitute.
6. Adjust affected 006 UI tests to the newly approved navigation and Habit flow without weakening owner/domain tests. Add focused section-order, provenance, routing, responsive, RTL, semantics, and Hijri boundary tests. Run relevant suites during implementation and the established platform gate before merge.

## Project Structure

### Documentation (this feature)

- specs/007-dashboard-prototype-ui/spec.md: approved behavior and acceptance criteria.
- specs/007-dashboard-prototype-ui/plan.md: implementation approach.
- specs/007-dashboard-prototype-ui/research.md: Phase 0 decisions.
- specs/007-dashboard-prototype-ui/data-model.md: Phase 1 view model.
- specs/007-dashboard-prototype-ui/contracts/: UI and navigation contracts.
- specs/007-dashboard-prototype-ui/quickstart.md: Phase 1 validation guide.
- specs/007-dashboard-prototype-ui/tasks.md: created later by speckit-tasks, not by this plan.

### Source Code (repository root)

- lib/app/l10n/app_ar.arb and app_en.arb: localized copy and Hijri labels.
- lib/app/routing/app_router.dart and owner_entry_intent.dart: current owner routes and entry contracts.
- lib/app/theme/app_colors.dart and app_theme.dart: approved identity.
- lib/features/today/domain/: existing calendar, projections, agenda, priority, section states.
- lib/features/today/data/system_today_calendar.dart: sampled local civil date.
- lib/features/today/presentation/: TodayScreen, TodayState, Dashboard composition, focused section widgets and adaptive navigation.
- test/unit/features/today/: date conversion and projection regressions.
- test/widget/features/today/ and test/widget/app/: section order, preview, responsive layout, accessibility and routes.
- integration_test/: existing target-specific Dashboard journeys.
- assets/images/namaa_icon.png: existing app icon.

**Structure Decision**: Keep the feature-first Today boundary and owner route composition. Introduce only presentation widgets and a narrow calendar conversion adapter where needed; do not build a new Dashboard repository, API, database schema, or cross-domain owner service.

## Complexity Tracking

No constitutional violation is planned. The single proposed date conversion package must pass the verification gate in [research.md](research.md); if it does not, implementation must not claim SC-007 is met or substitute an unverified date.

