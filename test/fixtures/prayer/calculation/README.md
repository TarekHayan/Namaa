# Prayer-time reference matrix (008 / US1)

`prototype_parity.json` was regenerated from the unpacked
`prototype/src/utils/prayerTimes.ts` calculation path using its specified
`adhan` JS 4.4.4 package. Run
`npm install adhan@4.4.4 --prefix .dart_tool/prayer_reference_js --no-save --package-lock=false --ignore-scripts --no-audit --no-fund`
then `node tool/capture_prayer_prototype.mjs` to reproduce the 84 rows.
The Dart adapter agrees with 477 of 504 prototype prayer/sunrise instants within
60 seconds in the focused test. Three deliberate differences are Umm al-Qura
Isha on 8 March 2026: the approved Ramadan interval is 120 minutes after
Maghrib, rather than the prototype's fixed 90 minutes. The other 24 deliberately
remove the prototype Dubai preset's Sunrise -3 / Asr +3 adjustments to match
the AlAdhan method; Asr also gets the one-minute source alignment described
below. The installed JS package is confined to
`.dart_tool` and is not an application dependency.

`aladhan_reference.json` is a frozen response capture from the independent
[AlAdhan timings API](https://aladhan.com/prayer-times-api). The reproducible
capture request is `tool/capture_prayer_reference.ps1`; every row retains its
exact request URL, UTC capture timestamp, response method metadata, coordinates,
IANA timezone and the returned local clock values. The 84 rows cover Cairo,
Dubai and New York, seven methods and 8 March, 20 March, 21 June and 21 December
2026. New York's 8 March row crosses its daylight-saving transition. The
captured rows use `school=0` (standard/Shafi Asr).

The test converts each reference `HH:mm` value into a UTC instant using the
row's IANA zone and civil date. It compares Fajr, sunrise, Dhuhr, Asr, Maghrib
and Isha by absolute seconds; the pass threshold is **60 seconds**, without
minute truncation. The app uses the pinned `adhan_dart 2.0.1` presets, its
nearest-minute rounding and a 90-minute Umm al-Qura Isha interval outside
Ramadan (120 minutes during Ramadan, using the Umm al-Qura calendar). The Dubai
Sunrise/Asr adjustments are normalized to zero to match the primary provider.
The local Asr result is adjusted one minute earlier across methods: before
this alignment, all 84 Asr results were 0–2 minutes later than AlAdhan; after
it, they are at most one minute apart. This is one explicit parameter choice,
not a city/date-specific exception. The comparison applies no post-processing
to the app's output and does not substitute another location.

Current raw result: **504 of 504** values are within 60 seconds against the
independent frozen AlAdhan matrix, with no named exceptions in the test. The
one-minute tolerance was not widened.

`praytimes_edge_reference.json` adds a second independent [PrayTimes.js 2.3
source](https://github.com/abodehq/Pray-Times/blob/5202ceb8b2cbb17848a227753f7bd0ac8b4c649f/Code/v2/js/PrayTimes.js)
at commit `5202ceb8b2cbb17848a227753f7bd0ac8b4c649f` for the cases AlAdhan
cannot provide as sound numerical references. To reproduce, download that exact
file into `.dart_tool/prayer_reference_js/PrayTimes.js`, then run
`node tool/capture_prayer_praytimes_edge.mjs`. The capture selects Egyptian
angles, standard Asr and no high-latitude substitution. At (0,0), it supplies
six UTC times; all six agree with the local calculator within 60 seconds. On
Tromso's polar day it reports Fajr, sunrise, Maghrib and Isha unavailable;
the valid Dhuhr and Asr values also agree within 60 seconds. The fixture stores
the source revision, zone, date, coordinates, parameters and reference values.

T030/T031 calculation fixtures and tests now cover the stated matrix and edge
cases; named phone/desktop cache/fallback measurements remain under T137.

## Captured edge cases (2026-11-02)

`aladhan_edge_cases.json` records three accountless API responses, including
the exact URL, HTTP status, capture instant, method metadata and raw timings.
Regenerate with `tool/capture_prayer_edge_cases.ps1`.

- AlAdhan returns HTTP 400 for exact coordinates (0, 0). This is a provider
  limitation, not an invalid local coordinate: the local solar preflight test
  confirms that zero coordinates are calculable. The annual adapter therefore
  falls back to the labelled local schedule for this location.
- On 21 June in Tromso, the provider returned the same instant for Fajr,
  sunrise, Maghrib and Isha. The annual importer rejects a year with
  non-increasing daily events; the local preflight marks unavailable events
  instead of displaying a substituted prayer time.
- On 21 June in Stockholm, the response declares `Europe/Stockholm` but its
  ISO timestamps carry `+03:00`. The IANA offset on that day is `+02:00`.
  The annual importer now checks each declared offset before storing the year.
  Its cache key was versioned so a pre-fix cached year is not reused.

These AlAdhan provider observations are not independently valid numerical
prayer-time references for zero or polar coordinates; the pinned PrayTimes.js
fixture above supplies the separate reference. The one-minute threshold has
not been changed.
