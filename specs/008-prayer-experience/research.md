# Research: Prayer Experience

## Foreground device location update (2026-11-01)

The user replaced manual first-time city entry with automatic device location. `geolocator` supplies the foreground fix on Android, iOS, macOS, Windows and Linux; operating-system permission is requested only from Prayer. AlAdhan's coordinate-based daily endpoint supplies the IANA time zone and its closest calculation method suggestion. Only a supported method is adopted, and the encrypted per-device preference retains coordinates, zone and method for offline operation. A failed permission, disabled location service, imprecise fix or unavailable time-zone response leaves the manual search path visible. No background location or continuous stream is used.

Sources: [geolocator platform/permission guide](https://pub.dev/packages/geolocator), [AlAdhan coordinate API and calculation-method notes](https://aladhan.com/prayer-times-api). AlAdhan explicitly notes that calculated times can differ from a local mosque or government authority's tuned timetable; the selected method and source are displayed for verification.

Date: 2026-10-29. Decisions are design research, not executed implementation evidence. No dependency was installed, migration applied or live-provider response certified during planning.

## 1. Calculation library and preset parity

**Decision**: Pin adhan_dart 2.0.1 (MIT; pure Dart, SDK >=2.19 <4) behind PrayerScheduleCalculatorPort as the offline fallback after annual-cache coverage ends. AlAdhan's annual calendar endpoint supplies the primary schedule; validated whole-year responses are encrypted on device and the next Gregorian year is prefetched. Pin timezone 0.11.2 (BSD-2-Clause; minimum Dart3.10) and embed its full zone database. Existing SDK satisfies the declared constraints; dependency resolution and five-target imports remain adoption gates.

**Rationale**: UTC result instants plus an explicit IANA zone avoid fixed-offset and host-zone errors. The prototype uses Adhan JS; corresponding presets allow traceable parity while a separate reference validates numerical results.

**Alternatives**: Older adhan2.0.0+1 has a local/offset API that is easier to misuse; online daily-times APIs violate saved-city offline calculation; a new astronomical engine is unnecessary.

Sources: [adhan_dart package](https://pub.dev/packages/adhan_dart/versions/2.0.1), [license](https://pub.dev/packages/adhan_dart/license), [PrayerTimes constructor](https://pub.dev/documentation/adhan_dart/latest/adhan_dart/PrayerTimes/PrayerTimes.html), [timezone changelog](https://pub.dev/packages/timezone/changelog), [timezone versions](https://pub.dev/packages/timezone/versions).

Map Egyptian/MWL/UmmAlQura/Dubai/NorthAmerica/Kuwait/Qatar to the seven corresponding CalculationMethodParameters presets. Set standard/Shafi Asr explicitly; keep preset adjustments and nearest-minute rounding. UmmAlQura and Qatar retain the prototype's fixed90-minute Isha preset. Seasonal UmmAlQura Ramadan adjustment is not silently added. Method information identifies this as a calculated preset, not a guarantee of every official/local timetable.

[Preset source](https://raw.githubusercontent.com/prayer-timetable/adhan_dart/master/lib/src/CalculationMethod.dart), [prototype upstream preset source](https://raw.githubusercontent.com/batoulapps/adhan-js/main/src/CalculationMethod.ts). During adoption verify the downloaded2.0.1 archive matches the inspected relevant API; do not assume moving master URLs are immutable release evidence.

## 2. City dates, night fractions and unavailable events

**Decision**: Convert injected nowUtc to the saved IANA location. Pass that city's year/month/day as a UTC date carrier to the calculator, calculate D and D+1 independently, and convert resulting UTC instants back to the city zone. Never call setLocalLocation or use device-local Y/M/D as the city date. Recalculate on city/day/method change, resume and retry; cache D/D+1 by full context, not by UI frame.

The prototype's night interval is today's calculated Maghrib to tomorrow's Fajr. Midpoint = start + elapsedDuration/2; last-third start = start + 2*elapsedDuration/3. Compute elapsed duration in UTC, then display in the city zone, preserving preset adjustments. Future Qiyam's Isha→Fajr reminder window stays a different concept. Avoid adhan_dart neighboring-day convenience fields because source reuses some current-day safe-time values.

Sources: [SunnahTimes upstream](https://github.com/batoulapps/adhan-js/blob/main/src/SunnahTimes.ts), [PrayerTimes source](https://raw.githubusercontent.com/prayer-timetable/adhan_dart/master/lib/src/PrayerTimes.dart).

**Critical limitation**: The library has no HighLatitudeRule.none; even polar unresolved leaves twilight caps active. Choosing defaults alone would silently substitute times.

**Decision**: Isolate a pinned deep import of SolarTime inside the calculation data adapter. Preflight finite raw sunrise/sunset and required Fajr/Isha hour angles; interval-based Isha needs valid sunset rather than an Isha angle. Compare raw results after the documented preset adjustment/rounding to library output. A substituted/uncomputable event becomes unavailable; do not choose another day/location or high-latitude rule. Catch nonfinite conversion errors. Valid unaffected fields may remain visible; dependent night/next-prayer fields remain unavailable when their inputs cannot be established. A failed calculator must never prevent manual reports for a known city-local date.

**Alternatives**: Claiming the default is no-fallback is incorrect; silently enabling a high-latitude rule conflicts with spec; forking the whole package is larger than the present adapter need. Any upgrade requires deep-import compilation and solar fixtures before adoption.

Sources: [HighLatitudeRule](https://raw.githubusercontent.com/prayer-timetable/adhan_dart/master/lib/src/HighLatitudeRule.dart), [CalculationParameters](https://raw.githubusercontent.com/prayer-timetable/adhan_dart/master/lib/src/CalculationParameters.dart), [SolarTime](https://raw.githubusercontent.com/prayer-timetable/adhan_dart/master/lib/src/SolarTime.dart).

timezone0.11.2 changelog records2026e whereas its README still mentions2025c. Record the actual bundled release-header/version during adoption; do not infer data freshness from the README. Unknown zone names are validation failures. No GPS or OS-zone plugin is required.

## 3. Independent calculation acceptance

**Decision**: Commit offline fixtures with coordinates, zone, civil date, exact method parameters, adjustment/rounding, UTC instants, source URL/version, capture date and raw reference response. Use prototype Adhan JS parity plus an independently maintained AlAdhan reference with explicitly matched parameters; never use location-chosen default methods or equate both providers' preset names without comparing definitions.

[AlAdhan API](https://aladhan.com/prayer-times-api) supports an annual calendar with explicit coordinates, method, school and zone. Following the 2026-10-31 user decision it is the application runtime's primary timetable source, with an encrypted annual cache. Presets differ in adjustments; record normalization before comparing the local fallback, including Dubai and fixed-interval Isha. Compare five prayers/sunrise within the spec's one-minute bound. A mismatch blocks acceptance of the local fallback until explained and fixed; do not widen tolerance. Compute/check the night fractions separately against the defined Maghrib→next-Fajr rule.

Matrix: Cairo/Africa-Cairo, Dubai/Asia-Dubai, New York/America-New_York using valid IANA names Africa/Cairo, Asia/Dubai, America/New_York; all7 presets; March/June/September/December representative dates, Cairo and NewYork DST boundary dates, a Ramadan fixed90 case, exact boundary, after-Isha, zero coordinate and Tromso uncomputable twilight/polar dates. No reference numbers are invented in these documents.

## 4. Manual online city search

**Decision**: Open-Meteo geocoding through a cancellable Dio adapter, language ar/en, up to10 candidates. Retain provider ID, country/admin disambiguation, coordinates and IANA zone only after user confirmation. Unknown zone/invalid numeric results cannot replace a saved city. No daily-times downloads or background GPS.

Sources: [geocoding API](https://open-meteo.com/en/docs/geocoding-api), [terms](https://open-meteo.com/en/terms), [pricing](https://open-meteo.com/en/pricing), [data licence](https://open-meteo.com/en/licence), [Dio versions/API](https://pub.dev/packages/dio).

**Rationale**: The provider documents localized names/fallback, coordinates and IANA time zones in one response. No second timezone lookup is needed. Search failure cannot break saved-city use.

**Deployment constraint**: Public free endpoint is for noncommercial use/evaluation, with published limits of fewer than10,000/day,5,000/hour and600/minute and no availability guarantee. Commercial release requires the licensed customer endpoint/entitlement and a configured first-party gateway keeping its key server-side under Constitution IX. This secret placement is Namaa's design, not a provider requirement. No subscription is purchased or gateway claimed deployed by planning. Without commercial search configuration, release search is unavailable with honest feedback; do not silently fall back to the free endpoint. Existing saved-city calculation remains usable.

Attribution to Open-Meteo and GeoNames/CC-BY4 belongs beside search/location information. Actual source coverage/response fixtures are recorded during adapter implementation. Avoid logging city queries, coordinates, credentials or account identifiers in provider diagnostics.

**Alternatives**: Huge bundled city catalog contradicts the approved online-first discovery tradeoff; GPS is outside scope; separate geocoding+timezone services add an unnecessary failure boundary.

Bound requests: trim/validate2…100 characters, 350ms debounce, cancel stale requests, query/owner/locale generation guard, 5s connect and8s receive timeouts; 429 respects Retry-After without retry storms; user-triggered retry for failure. Add Android main INTERNET permission (currently only debug/profile manifests include it); macOS release/debug already permit outgoing network. HTTPS needs no cleartext/ATS exception.

## 5. Durable identity, local migration and owner boundaries

**Decision**: Schema8 adds encrypted prayer_device_preferences and prayer_reports. Installation identity is implicit in the local database; key preferences by owner, do not cloud-sync them. Missing daily rows mean pending; explicit reset is a persisted pending report, not row deletion.

Use UUIDv5 of namespace9d63d7a6-bb43-4b93-b2a1-c1d22c68b008 and UTF8 name YYYY-MM-DD/prayer_name. Owner remains a separate key. SQL recomputes the same ID using schema-qualified uuid-ossp functions; pin uuid4.6.0 and assert cross-language vectors. Existing server xp_awards.source_id is UUID, so no shared-column rewrite or per-device random identity.

[UUID package](https://pub.dev/packages/uuid/versions), [PostgreSQL UUID implementation](https://github.com/postgres/postgres/blob/master/contrib/uuid-ossp/uuid-ossp.c).

Read latest report, validate scope/day, write report+first local award+outbox inside one transaction. Preference edits use one atomic replacement and do not enqueue cloud work. Preserve existing preview owner IDs; give Prayer its own closed preview owner binding and map its XP into Today through an explicit composition bridge.

As requested by the recorded next-migration backlog, v8 also drops unused task_records.completion_xp after removing its code references. Check physical existence: real v3…7 schemas contain it; v1/2 upgrade paths may create Tasks using the newest declaration without it. Test historical fixtures for every v1…7 path rather than pretending modern createAll is a historical schema.

## 6. XP and competing offline devices

**Decision**: Generalize TaskCompletionAward/AwardLedgerPort to shared XpAward with task_done and prayer_done sources, preserving Task wrappers/policy20 and existing Task tests. Reuse xp_awards; no alternate prayer balance.

First eligible completion committed by the server ledger fixes canonical10/5. A local offline award is a provisional replica until confirmed; two disconnected devices may estimate different first amounts and then reconcile to the one server award. Corrections/reset never mutate an already canonical award. Retain award evidence independently of current report state: completion followed by reset before sync must still earn once. This matches the existing Task0011 independent-event behavior.

**Alternatives**: Globally immutable independent offline estimates cannot converge when devices first report5 versus10; client-chosen amounts violate central authority; latest-report-only rewards lose completion→reset evidence.

## 7. Sync protocol and conflict review

**Decision**: Migration0015 implements native typed apply_prayer_report_change_v1 with base version outside payload, strict authenticated owner, explicit operation receipt and per-owner/date/prayer lock (also on first insert). Whole-day snapshots are never mutation units.

Stable operation ID/request hash detects changed-content reuse; same replay returns the original receipt. Base matches/sequential known lineage are uncontested. Divergent versions preserve both; newest UTC timestamp wins and equal-time semantic payloads use a shared deterministic ASCII canonical key. Identical contents are no conflict. Stable conflict IDs are reused by server responses, downloads and local evidence.

The Prayer dispatcher applies the typed server outcome to local report/award/conflicts transactionally, preserving newer pending descendants, then returns DispatchAcknowledged to the existing coordinator. The coordinator owns the outbox ACK. A crash before ACK replays the receipt and idempotent local outcome. No modification to existing generic equal-timestamp retry behavior is required.

Readers separately page reports, prayer_done awards and retained server conflicts. Owner cursor/stream generations reject late replies after account change. Source/receipt IDs, not a generic coordinator counter, drive visible conflict review.

## 8. UI/Home/lifecycle integration

**Decision**: One PrayerContextService exposes owner-scoped immutable snapshots to PrayerCubit and the Today adapter. Today receives a TodayPrayerPort DTO; it never reaches into Prayer storage or replaces its existing calendar. Prayer date uses selected city; Today Task/Habit/XP date continues device-calendar behavior. Snapshots carry explicit prayerLocalDate/zone. Existing XP day aggregation stays based on actual award instant.

Retain the four groups and source measurements from prototype-reference.md, standard navigation shell/sidebar/bottom destinations and shared controls. A small city/method editor and reset affordance are approved adaptations. No fictitious streak: reserve its slot as coming soon. Route callbacks from Home, hubs, sidebar and Track lead to /prayer; unrelated domains remain coming soon.

In memory only: the active today/tomorrow projection, countdown ticks, source health and query generation. The annual timetable and setup are owner-local encrypted data. On resume sample the clock once; refresh date/report query when needed. Dispose all streams/timers on scope replacement and suppress per-second screen-reader announcements.

## 9. Religious copy

**Decision**: Use reviewed bilingual paraphrases with attributable source metadata; do not simply copy hard-coded prototype text or generate rulings. Regular resident counts and recitation labels stay distinguishable from optional guidance; exemptions/travel/jurisprudential customization are outside008.

Primary attributable references inspected:
- [Ibn Baz official archive: prayer/travel counts](https://binbaz.org.sa/fatwas/6628/كيفية-جمع-الصلوات-في-السفر).
- [Ibn Baz official recitation commentary](https://binbaz.org.sa/audios/3884/كتاب-الاذان-باب-الجهر-في-المغرب).
- [Dar al-Ifta: Jahr/Sirr](https://www.dar-alifta.org/ar/Fatwa/Details/21959/كيفية-قضاء-الصلاة-من-حيث-الجهر-بالقراءة-والإسرار-بها).
- [Dar al-Ifta: regular Sunnah](https://dar-alifta.org/ar/fatwa/details/17725/حكم-قضاء-السنن-الرواتب-التابعة-للصلوات-المفروضة-ووقت-قضائها).
- [Ibn Baz: Dhuhr/Asr optional prayers](https://binbaz.org.sa/fatwas/12576/بيان-الراتبة-القبلية-والبعدية-للظهر-ونافلة-العصر).

Content acceptance records each final AR/EN string's source/review, not just a link list. Do not label one optional-practice formulation universal across schools.

## 10. Research resolution

All planning choices have a selected approach and alternatives. Implementation gates still required: release-archive/license/import checks, source-coupled solar preflight/reference evidence, guidance copy review, migration/SQL/device proof and commercially compliant gateway provisioning before a commercial search release. No hidden product choice is delegated to implementation.
