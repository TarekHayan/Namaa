# Data Model: Dashboard Prototype UI 007

This feature defines transient presentation values. It adds no database, cloud table, account record, or owner mutation. The existing TodayState, TodayTaskSummary, TodayHabitSummary, TodayXpSummary, TodayAgenda, TodayPriority, TodayCalendar and TodaySection remain authoritative inputs.

## Dashboard presentation snapshot

| Field | Type / source | Rule |
|---|---|---|
| localDate | TodayCalendar.localDate | One sampled device-local civil date drives Gregorian text, Hijri conversion, Task/Habit membership and day transitions. |
| tasks | TodaySection<TodayTaskSummary> | Owner-filtered, scheduled-today projection; preserve status and null percentage for empty denominator. |
| habits | TodaySection<TodayHabitSummary> | Owner-filtered eligible Habits; read-only on Home. Preserve status and null percentage for empty denominator. |
| xp | TodaySection<TodayXpSummary> | Only owner award totals for the current local day. |
| timeline | TodayAgenda plus tagged preview entries | Real timed and untimed Tasks retain identity, time, order and completion. Future-domain examples carry sample provenance. |
| doFirst | TodayTaskSummary.doFirst | At most three incomplete urgent-important Tasks due today or overdue, ordered by the existing owner projection. |
| hijriDate | verified conversion result or unavailable | Derived from localDate, with Umm al-Qura convention, never from a second clock sample. |
| sections | fixed ordered section descriptors | Progress, Prayer, Quran, Quick Hubs, Timeline, Do First, Finance, Counters. No extra Home group. |

The snapshot is scoped to TodayState.scope and regenerated on state/calendar changes; it is not cached across account/preview identity changes as account data. Rendering samples never emits an owner operation.

## Value provenance

A displayed value has exactly one provenance:

- **Live**: derived from a confirmed owner projection and shown with its actual value/date. It may carry the existing TodaySectionStatus of available, empty or stale. Stale values retain a visible outdated indicator.
- **Sample**: immutable illustrative copy/figure for a feature without an owner. It must show localized, visible and semantic sample wording next to the displayed figure. It cannot be passed into TodayProjection, XP, completion or storage.
- **Unavailable/loading**: no confirmed value. Show a localized loading, retry or unavailable state; do not display an apparent live zero.
- **Empty**: a confirmed owner result with no eligible items. Use an honest no-items message; never convert a null Task/Habit percentage to 100%.

The sample overall ring, unowned level/streak and Prayer/Quran/Adhkar/Focus/Qiyam/Finance/Counters numbers use Sample provenance. Task progress, Habit progress and XP use Live provenance only when their owner source confirms them. Task and Habit percentages are independent readouts inside the progress group; the six prototype metric positions remain Tasks, Prayer, Quran, Adhkar, Focus and Qiyam.

## Sample preview

| Field | Constraint |
|---|---|
| featureId | Stable identifier of unfinished destination, e.g. prayer, focus, quran, adhkar, qiyam, finance, counters. |
| localizedLabel | ARB-backed label; no hard-coded user-facing copy. |
| displayValue | Fixed example only; never loaded as an owner record. |
| sampleMarker | Visible and semantic, inseparable from displayValue. |
| destination | Matching localized coming-soon title. |
| action | Navigation only; no saved completion, counter increment, financial change or Quran reading record. |

Preview entries are read-only constants (or equivalent presentation fixtures), not seeded rows. The counter snippet shows at most four illustrative items, each visibly sample. A sample timeline item has its own sample marker and cannot use a real Task ID or completion control.

## Hijri display result

| Field | Constraint |
|---|---|
| inputCivilDate | The year/month/day of TodayCalendar.localDate. |
| calendar | Umm al-Qura, identified visibly in Arabic/English. |
| result | Supported valid Hijri day, month and year from the verified conversion table, or unavailable. |
| formatting | Localized month name and numerals; Gregorian remains visible. |
| failure | Unsupported date or conversion error maps to localized “Hijri date unavailable”; never to a guessed date. |

Month/year rollover and a local-midnight/timezone change cause a new result from the new localDate. There is no network fetch or persisted Hijri value.

## Navigation destination

| Destination | Kind | Resolution |
|---|---|---|
| Home | Current screen | Return to root Dashboard. |
| Tasks | Implemented owner | Existing Tasks route and owner entry intents. |
| Track | Unfinished | Localized coming-soon destination. |
| Finance | Unfinished | Localized coming-soon destination. |
| More | Navigation collection | Habits, Mind Maps, Preferences and relevant future entries. |
| Habits / Mind Maps | Implemented owners | Existing owner callbacks/routes from More. |
| Future quick hubs/cards | Unfinished | Matching coming-soon destination. |

No new route may bypass the existing owner scope/session boundary. Visible selected state must follow the destination and be perceivable beyond color.

## State transitions

- TodayState loading to available/empty: replace only corresponding section's loading state with owner result; samples remain tagged and do not block first content.
- Available to stale/unavailable: show stale/retry or unavailable state without replacing it with a sample or apparent live zero.
- Local date/offset changes: refresh Today projections and Hijri from one new TodayCalendar sample; discard old-day view values in accordance with existing lifecycle behavior.
- Preview/account identity changes: existing TodayScope isolates live values; sample constants remain unowned and do not leak user records.
- Coming-soon open/return: navigation only; no mutation.
- Habit completion: only in the Habits owner screen; returning Home reads the updated owner projection.

