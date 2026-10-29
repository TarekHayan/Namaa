# Prayer prototype reference and scope mapping

Date: 2026-10-29. Source inventory only; this does not certify implemented UI or verified calculation/guidance.

## Sources inspected

| Source | Evidence |
| --- | --- |
| `namaa_plan.md` sections 8, 24, 27 | Prayer is next; schedule and completion separate; no inferred missed prayer; Notifications later. |
| `prototype/src/views/PrayerView.tsx` | Four groups, five prayer cards/actions, status surfaces and responsive structure. |
| `prototype/src/utils/prayerTimes.ts` | Seven methods; five prayer metadata entries; sunrise/night values and tomorrow-aware next/following prayer. |
| `prototype/src/context/AppContext.tsx` | Date-specific reports/reset, 10/5 rewards, profile preferences. Whole-day writes are a limitation, not a sync contract. |
| `prototype/src/views/TrackHubView.tsx` | Prayer, Pomodoro, Quran, Adhkar, Qiyam. Only Prayer becomes implemented in 008. |
| `prototype/src/views/HomeView.tsx` | City, next/following prayer, countdown and link into Prayer. |
| `prototype/src/components/OnboardingModal.tsx`, `prototype/src/views/SettingsView.tsx` | Location label exists but onboarding assigns Cairo coordinates; label alone does not locate a city. |
| `prototype/src/data/initialData.ts`, `prototype/src/types.ts` | Cairo/Egyptian defaults and four report states. |
| `docs/design/colors.md`, `docs/design/app_components.md` | Existing palette, typography/controls, hover/focus and content-first sizing. |

## Layout inventory

Measurements are source references, not a new theme. Adapt through Namaa's existing typography and components.

| Group | Prototype structure | Source spacing and sizes |
| --- | --- | --- |
| Heading | Title/subtitle/city and streak/progress badges | Group spacing 16; radius 32; padding 24 phone / 32 wider; title 18/20; subtitle 12; inner gap 12. |
| Five prayer cards | Icon, name/rak'ahs, time/recitation, guidance, state actions | Vertical gap 12; radius 32; padding 20/24; details gap 14; icon 20; name 16/18; time 14; guidance 11 with relaxed line height. |
| Actions | Below details with separator on phone; inline wider | Gap 8; phone top padding 8; rounded buttons; label 12; green/amber/red selection. Preserve accessible targets even where prototype controls are smaller. |
| Supplementary times | Sunrise, middle of night, last third | One/three columns; gap 12; radius 16; padding 16; labels 11; values 16. |
| Guidance | Heading and Jahr/Sirr panels | Radius 32; padding 24/32; heading 14; inner gap 12; one/two columns; body 12. |

Source layout transitions at 640px. Actual transition must respect available content width and text scaling rather than force overflowing rows. Group order is unchanged across locales; placement follows direction.

## Explicit adaptations

1. Use Namaa's existing colors, font, icon, content-first sizing and controls.
2. Keep persistent desktop sidebar and five phone destinations; replace Prayer placeholders and its Track entry.
3. Require a confirmed manual city and identify method/zone; no silent Cairo fallback, location onboarding or GPS.
4. Expose accessible reset-to-pending: context supports reset but the Prayer list only has three state choices.
5. Clearly mark the global-streak slot coming soon; do not relabel unrelated streak data.
6. Bind Home Prayer values to the new owner while preserving other sample markers and ring.
7. Reconcile separate prayer reports and centralized one-time rewards; do not copy whole-day overwrites or trust client reward amounts.
8. Adhan/notifications and other religious/focus domains remain coming soon.

## Research needed during planning

- Supported city coverage/search, location/time-zone provenance and offline saved-city behavior.
- Calculation-reference compatibility for seven methods, time-zone transitions, night fractions and uncomputable latitudes, before dependency adoption.
- Attributable approved religious sources for metadata/guidance; prototype wording is not source validation.
- Prayer/Home/reward contracts, owner isolation, conflict/base-version/equal-timestamp handling and migrations from every supported prior schema.
- Final prototype comparison and target evidence belong to implementation verification, not this inventory.
