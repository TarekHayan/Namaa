# Quickstart Validation: Dashboard Prototype UI 007

This is the validation guide for [spec.md](spec.md), [data-model.md](data-model.md), [dashboard UI contract](contracts/dashboard-ui.md) and [navigation contract](contracts/navigation.md). It describes expected checks after implementation; this planning phase does not modify app code or claim that they have passed.

## Prerequisites

Use the repository's Flutter toolchain (current CI pins Flutter 3.41.8), an Android emulator/device and one desktop target for interactive validation, plus macOS/iOS hosts for their target gate. Work from the repository root. Keep existing encrypted preview data. Do not reset or seed a production account. The sibling prototype.zip is the visual reference; compare HomeView.tsx, Header.tsx and Navbar.tsx, not unrelated prototype behavior.

If the candidate Umm al-Qura package is adopted, first inspect its source, version, license, resolved API and lockfile. Verify month/year boundary dates against KACST's official Umm al-Qura calendar before showing a Hijri result. A failed check blocks SC-007; it is not an invitation to use a generic Islamic-calendar fallback.

## Focused automated checks

Run static checks and the changed-area suites first:

~~~powershell
flutter pub get
flutter gen-l10n
flutter analyze
dart format --output=none --set-exit-if-changed lib test integration_test
flutter test --no-pub test/unit/features/today
flutter test --no-pub test/widget/features/today
flutter test --no-pub test/widget/app/today_route_test.dart test/widget/app/today_owner_navigation_test.dart test/widget/app/today_creation_route_test.dart
flutter test --no-pub test/widget/app/localization_and_directionality_test.dart
~~~

The implementation must add focused tests for Hijri conversion (month/year boundaries, unsupported range, local-midnight/offset refresh), eight-section/six-hub/five-destination order, sample semantics and provenance, phone widths/150% text, RTL/LTR and More owner routes. Existing Habit owner/domain completion tests stay intact. Update old Home widget assertions that assumed a Habit tab or direct Home completion only to reflect the approved 007 navigation change.

Do not repeatedly run the whole platform matrix after each small change. Run affected tests first, then the established full platform gate before merge.

## Prototype inventory walkthrough

1. Open Dashboard and scroll top to bottom. Compare with the prototype. There must be exactly eight ordered groups: progress; next prayer; Quran Wird; six hubs; daily timeline; Do First; finance; counters. No independent Habits or Explore Home group.
2. Check header roles: greeting and Namaa icon; same-day Gregorian and named Umm al-Qura date; badges; language switch; quick add. A badge with no verified owner value says sample.
3. Verify six quick hubs in exact order: Prayer, Focus, Quran, Adhkar, Qiyam, Counters. Check that Finance remains in its two-tile section and in primary navigation.
4. Check five primary destinations in order on bottom navigation and sidebar: Home, Tasks, Track, Finance, More.
5. Compare large-screen hierarchy, ring, card surfaces, timeline rail, finance/counter layout with the reference while using the existing Namaa colors/font/icon.

Record any visual mismatch by section and viewport rather than using subjective “close enough” approval.

## Provenance and owner correctness

Prepare known local owner fixtures in a preview/test scope: ten Tasks due today with four complete, five eligible Habits with two complete, and known XP awards. Include an overdue urgent-important Task, a future-only urgent-important Task, untimed/timed Tasks, and empty/unavailable source cases.

Expected:

- Task progress 4/10 = 40% and Habit progress 2/5 = 40% appear independently inside the progress group. Neither is calculated from the sample ring. XP equals actual current-day owner awards.
- Do First shows no more than three incomplete urgent-important Tasks due today or overdue; future-only entries are excluded.
- Real timeline Task identity, schedule, order and completion match Tasks. Untimed Tasks have no invented sample time.
- Prayer, Quran, Finance, Counters and other unfinished-domain figures are individually visible/announced as sample. Opening each action reaches a feature-titled coming-soon page and saves nothing.
- A loading/unavailable source shows its state; stale live data says outdated; confirmed empty Task/Habit denominators do not become 100%. A sample does not become a false live zero.
- Home offers no Habit completion action. More opens Habits; completing there updates Home when returning. More also opens Mind Maps. Tasks opens its existing owner and existing records remain intact.
- Viewing Dashboard or placeholders offline, switching language/theme or changing preview/account scope creates no business record, XP award or pending synchronization item.

## Responsive and accessible walkthrough

For 320, 390 and 430 logical-pixel phones, a tablet width and a desktop width, inspect the complete scroll at normal text and 150% text in Arabic and English. Verify no horizontal scroll, essential-label clipping, overlapping cards or last card hidden under bottom navigation/safe area. Rotate a phone and show a software keyboard. Check logical RTL/LTR order, mixed-direction titles, timeline rail, touch targets, focus indicators, screen-reader sample labels and keyboard navigation.

Time one phone touch journey and one desktop keyboard journey: distinguish live/sample values, open a real Task, visit all five main destinations, find Habits and Mind Maps under More, then return. Each must finish within three minutes without help (SC-005).

## Date and performance evidence

Use a deterministic TodayCalendar.localDate for dates on either side of an official Umm al-Qura month boundary, year boundary and local midnight. Compare output with the official reference on each affected target. Verify Gregorian/Hijri derive from one local date, calendar name is visible, and unsupported dates show “Hijri date unavailable” rather than a guessed result.

Reuse the existing Feature 006 local fixture of 500 Tasks, 100 Habits and 200 XP awards. Measure first readable Dashboard content offline from local root readiness, excluding installation/fixture creation. It must appear within two seconds on one tested phone and desktop. Record device, OS, build mode, input size and measured interval. Preview cards must not wait on a network source. The existing performance entry point is integration_test/today_performance_test.dart; adapt its assertion if necessary rather than introducing a production seed.

## Target gate before merge

Run the existing relevant integration journeys on supported devices (including integration_test/today_dashboard_test.dart) and the repository's normal quality, database/security and Android, iOS, Windows, macOS and Linux gate when the implementation is ready to merge. A presentation-only change does not require a new SQL migration or Supabase deployment. Record genuine target-specific failures and fix their causes; do not dilute an assertion or claim completion based on a partial/mobile-only run.

