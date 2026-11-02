# Prayer-time reference matrix (008 / US1)

`prototype_parity.json` was regenerated from the unpacked
`prototype/src/utils/prayerTimes.ts` calculation path using its specified
`adhan` JS 4.4.4 package. Run
`npm install adhan@4.4.4 --prefix .dart_tool/prayer_reference_js --no-save --package-lock=false --ignore-scripts --no-audit --no-fund`
then `node tool/capture_prayer_prototype.mjs` to reproduce the 84 rows.
The Dart adapter agrees with all 504 prototype prayer/sunrise instants within
60 seconds in the focused test. The installed JS package is confined to
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
nearest-minute rounding and a fixed 90-minute Umm al-Qura Isha interval.
There is no location fallback or manual adjustment of the app's output in the
comparison.

Current raw result: **465 of 504** values are within 60 seconds. The other
**39** are retained as named, non-accepted reference differences in the test:

| Source difference | Affected values | Reason established so far |
| --- | ---: | --- |
| Dubai preset sunrise | 12 | The pinned Adhan preset applies a -3-minute method adjustment, absent from the captured AlAdhan output. |
| Dubai preset Asr | 12 | The pinned Adhan preset applies a +3-minute method adjustment; rounding creates a 3–5-minute observed gap. |
| Umm al-Qura Isha on 8 March | 3 | The product's fixed 90-minute interval differs from AlAdhan's Ramadan 120-minute interval by 30 minutes. |
| New York Asr on 8 and 20 March, six non-Dubai methods | 12 | Two-minute raw algorithm difference remains unexplained and requires an independent second reference. |

The test fails for any *new* difference outside these precisely named fields.
It does **not** turn the 39 known differences into a passing SC-002 result or
increase the one-minute tolerance. SC-002 and T031 stay open until matching
method configuration and a genuinely independent reference can establish
agreement for every required field. Source-attributed zero-coordinate and
polar reference fixtures also remain to be completed before T030 can be checked.
