# Prayer UI, navigation and city-search contract

## City discovery boundary

Noncommercial development adapter:
GET https://geocoding-api.open-meteo.com/v1/search?name={query}&count=10&language={ar|en}&format=json

Normalized result:
- results[]: provider, providerCityId, cityName, countryCode, countryName, optional adminName, latitude, longitude, timeZoneId.
- attribution[]: Open-Meteo, GeoNames, CC-BY4 source links.
- absent/empty provider results becomes noResults, not a failed saved preference.
- response names are supplied by the provider with its documented fallback; do not generate a new translation on device.

Input2…100 trimmed characters;350ms debounce; cancel stale query/locale/owner responses. Validate finite coordinates and supported zone before showing a selectable candidate. Country/admin context disambiguates duplicate names. Editing query or tapping a candidate is not saving; explicit confirmation performs one atomic replacement.

States: idle, searching, results, noResults, offline, throttled(retryAfter), invalidResponse, unavailable, saving, saved. Preserve prior confirmed city on every cancellation/failure. First-use offline explains internet is required for discovery; saved-city use has no search dependency.

Commercial configuration uses a planned first-party endpoint:
GET {configuredGatewayOrigin}/v1/cities/search?query={query}&language={ar|en}
with the same normalized response. Gateway pins the upstream allowlist, holds its licensed key server-side, enforces request/result and abuse limits, and strips raw queries/coordinates from logs. Provisioning/licensing is a commercial-release prerequisite, not performed by this planning command. No free-endpoint fallback in commercial mode. Saved-city use remains available when gateway/configuration/search is unavailable.

Attribution is available in the picker and beside saved-location information. Add Android release INTERNET permission and verify merged manifest; existing macOS network.client entitlement is retained. No GPS/background location permission, ATS or cleartext exception.

## Prayer layout contract

Keep the existing navigation frame and these four ordered groups:

1. Compact header: title, subtitle, confirmed city, civil date/zone/method context, progress completed/5 and a clearly coming-soon streak slot. City/method change affordance opens a bounded editor.
2. Five cards in canonical order: icon tile, name, rak'ah badge, calculated time or unavailable label, recitation description, reviewed short guidance; on-time, late, missed actions and reset-to-pending affordance. Selected state has semantic label/icon as well as color.
3. Sunrise/middle-of-night/last-third cards: one column on narrow phone, three only when content fits. No completion action or reward on these values.
4. Jahr/Sirr heading and two guidance panels, stacked/wide adaptation.

Use prototype-reference.md measurements and approved AppColors/AppTypography/ThmanyahSans. Reuse AppButton, AppSelectField, AppStatusView and AppHoverSurface; accessible controls may exceed prototype mini-button dimensions. Minimum touch target48 logical pixels; text scaling remains additive to responsive typography. No ellipsis for primary content, fixed card height, decorative icon overlap or horizontally scrolling whole page.

On compact devices, details precede wrapped/stacked actions with separator. Wide rows align actions beside details when all labels fit. Do not reuse a raw 640px breakpoint when150% Arabic would overflow. Preserve content order and directional alignment.

Schedule loading/setup/partial failure and report loading/failure remain independent. A calculated-time error cannot make completed count look0/5. If no city/date context exists, reports are unavailable until setup rather than silently assigned Cairo.

## Navigation contract

- Add /prayer with existing resolved-owner gate and preview mapping; no public login UI.
- Home prayer card, Prayer quick hub, desktop direct Prayer row and Track hub Prayer entry all use one onPrayer route callback.
- Phone Track stays destination index2 in the existing five-entry bottom bar. Prayer/Track highlight it; desktop retains the current persistent sidebar, direct Prayer row and current breakpoint/width.
- Add a bounded Track hub matching the prototype entries Prayer, Focus, Quran, Adhkar, Qiyam. Only Prayer opens a real owner route; other entries stay labelled coming soon.
- Thread callbacks through app-owned routing and TodayNavigationShell; do not call another feature's repository from the sidebar.
- Preserve existing navigation/action keys and add stable prayer_ keys for screen, setup, city search/confirm, five status controls, reset and conflict review.
- Back/Home retain the selected city and reports. Account switch clears visible old state before the new owner subscription begins.

## Home projection

TodayPrayerPort emits a Today-owned immutable DTO from Prayer application snapshots:
owner/context generation, city label, prayerLocalDate, zone/method, next/following prayer instants/names, remaining time inputs, completed count and separate schedule/report availability.

TodayCubit observes it independently with bounded initial recovery deadline and retry. Add prayerOwnerId to TodayScope through the composition resolver. Existing Task/Habit dates and XP UTC day bounds stay tied to SystemTodayCalendar; never replace them with the selected city zone. If city day/zone differs, label it on the Prayer card and metric.

Replace only Prayer's hard-coded preview sources:
- TodayPrayerCard's sample city/times and negative-prefixed sample countdown;
- TodayProgressHero's Prayer4/5 sample tile;
- TodayQuickHubs' all-coming-soon treatment of Prayer.

Live Prayer has no sample badge. Setup/unavailable is honest, never a default sample value. Overall sample ring, unimplemented domains, Task/Habit ratios and actual shared XP remain semantically unchanged.

## Conflict and reward feedback

Show owner-only conflict evidence through the shared conflict store, with prayer/date and both localized statuses; provide normal current-day status correction, not a new past-day editor. An equal-time tie is presented as synchronization evidence, not an app judgment about prayer quality.

A saved report may have queued synchronization. Local first-award estimate is provisional until server confirmation; settle concurrent-device5/10 differences to the one central award, then keep it fixed through report corrections/reset. No repeated celebration or duplicate reward on replay.

## Accessibility/content acceptance

Arabic/English ARBs include state actions, count plurals, setup/error messages, method/zone labels, guidance and semantics. Times use locale-aware formatting and stable mixed-direction isolation. Keyboard reaches city edit/search/results/confirm, all state controls, reset and return navigation with visible focus. Countdown ticks do not become per-second screen-reader announcements.

Both themes and100%/150% text cover320/390/430/768/1200px. Inspect actual device pointer/touch/keyboard behavior and record final prototype comparison. Guidance strings include reviewed source metadata from research.md; no new ruling or Quran content is generated.
