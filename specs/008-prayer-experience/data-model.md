# Data Model: Prayer Experience

Design date: 2026-10-29. Planned names/fields; no schema applied by this document.

## Identity and vocabulary

- PrayerName: fajr, dhuhr, asr, maghrib, isha, in this stable order.
- PrayerStatus: pending, completed_on_time, completed_late, missed.
- PrayerLocalDate: strictly validated Gregorian YYYY-MM-DD in the selected city's IANA zone.
- Report identity: (account_id, local_date, prayer_name). report_id = UUIDv5(namespace9d63d7a6-bb43-4b93-b2a1-c1d22c68b008, UTF8(local_date + '/' + prayer_name)).
- Shared reward: (account_id, source='prayer_done', source_id=report_id). Owner is part of every lookup/key, never inferred from an entity ID.
- Missing report is a virtual pending state. An explicit reset is a persisted pending report, not deletion.
- All version instants are UTC with microsecond precision preserved consistently across codecs/SQLite/SQL. Do not rely on JSON map ordering or local date-time strings for comparisons.

## Encrypted local schema8

### prayer_device_preferences

One row per owner in the current installation's encrypted database. The physical installation is implicit; no device identifier needs to leave the device.

| Field | Constraint/purpose |
| --- | --- |
| account_id | Primary key; closed preview or resolved real owner. |
| provider, provider_city_id | Stable search provenance; not inferred from display name. |
| city_name, country_code, country_name, admin_name | Display/disambiguation; nonempty city and country; optional admin. |
| latitude, longitude | Finite numeric values in [-90,90]/[-180,180]; zero valid. |
| time_zone_id | Known IANA entry in bundled zone database. |
| calculation_method | One of seven approved preset keys. |
| revision | Increasing local integer for stale-search/save guards. |
| updated_at | UTC save instant. |

Atomic replacement after confirmation; no outbox, remote table or sync conflict. A failed replacement retains the previous row. Each owner has independent preferences; logging out never deletes them. City lookup candidates/query history are not persisted as account state.

### prayer_reports

| Field | Constraint/purpose |
| --- | --- |
| account_id, local_date, prayer_name | Composite primary key. Index account/date supports one-day reads. |
| report_id | Deterministic UUID text; unique per owner; match derived identity. |
| status | Four-state enum; no time-driven transition. |
| reported_completion_at | Nullable UTC; required for either completed status, null for pending/missed. |
| recorded_zone_id, recorded_offset_minutes | Context sampled when this report version was submitted; not recomputed on receiving device. |
| created_at, updated_at | UTC; updated_at is monotonic for local edits of a record. |
| last_acknowledged_updated_at | Nullable server-confirmed base, distinct from the last local edit. |
| canonical_reward_confirmed_at | Nullable local-only UTC settlement marker, set atomically when a server award is received; never part of the synchronized report payload. Preview awards are final locally by preview scope, without fabricating server confirmation. |

Index (account_id,updated_at,report_id) for bounded reads. Ordinary corrections preserve identity/date and original reward. Report state can be any of the four states after an explicit action; equality is a no-op unless context meaningfully changes.

Local command transaction: fresh owner/day/context validation → read current report/base → write new report → insert first local reward if eligible and absent → append immutable outbox operation. Never read the record outside this transaction and then overwrite a newer copy. Do not coalesce away an earlier eligible completion when a later reset is queued.

### Existing tables reused

- pending_changes: entity_type='prayer_report', entity_id=report_id, stable operation_id, typed semantic payload, base_updated_at from last acknowledged version. Preserve order/lineage and immutable snapshots.
- conflict_records: Prayer active/retained snapshots with server-compatible deterministic ID. No foreign owner payload may enter the review list.
- xp_awards: same composite owner/source/source_id key. Add prayer_done support in shared XpAward; Task compatibility policy remains20.
- foundation migration journal: preserve rollback/recovery behavior.

The shared model is named XpAward and validates known source/policy pairs; TaskCompletionAward can remain a compatibility wrapper while existing callers migrate. Readers must not throw when prayer_done exists. Task-specific remote fetch remains filtered to task_done; Prayer has its own source reader.

## Remote schema migration0015

### prayer_reports

Owner UUID references auth.users; date as SQL date; prayer/status checked text; report_id UUID with deterministic-identity validation; UTC version/completion/context fields matching local semantics. Primary key(owner,local_date,prayer_name), unique(owner,report_id); owner/version/report index.

### prayer_operation_receipts

Primary key(owner,operation_id); request fingerprint, report identity, active outcome, optional retained outcome/conflict ID, canonical award snapshot, applied_at. Replaying identical content returns the same receipt; reusing ID with different content is rejected. Receipts stay internal to RPC; no direct client mutation.

### prayer_conflicts

Owner/report identity, stable conflict_id, both semantic versions, chosen active version, detected_at. Read-only owner RLS permits download and cross-device review; mutation only from the RPC. Same conflict found through inbound/outbound must have one identity.

### xp_awards

Reuse existing UUID source_id column and source='prayer_done'; no separate prayer balance. Insert-only canonical amount derived from the eligible submitted report status,10/5. Server-committed first eligible award wins even if that incoming report loses newest-version selection to a later reset. Newer corrections never rewrite the award.

Cloud device preferences, daily schedule rows and global Prayer streak rows are deliberately absent. The encrypted device database additionally stores a complete annual AlAdhan timetable keyed by owner, selected city coordinates/zone/method and Gregorian year; a malformed or partial response cannot replace it.

## Reward lifecycle

1. First local explicit on-time/late action creates a provisional local award10/5 atomically with the report/outbox.
2. A second local correction/reset does not change it.
3. Server serializes operations for the account/report and inserts the first eligible canonical reward. Different offline devices may have estimated different amounts; first server commit defines the one canonical award.
4. Reconciliation replaces only a provisional replica with the returned canonical award. This is settlement of one award, not a second award or a reward for correcting a report.
5. Pending/missed operations do not create awards; they also do not revoke an existing one.
6. Unsent eligible completion operations survive later resets/restarts. A report's current pending state does not erase completion-event evidence in the outbox/receipt.
7. In preview, the local ledger is the sole durable authority; no server settlement or network upload occurs.

Report UI remains saved/offline independent of reward synchronization. A provisional XP indication belongs in sync/reward feedback; never call it a second final reward.

## Memory-only values

- CityCandidate: provider identity, localized fallback name, country/admin, coordinates and zone; tied to search locale/query/owner generation.
- PrayerCalculationContext: owner, preference revision, zone, city civil date, method, standard Asr and fixed calculation-policy version.
- PrayerSchedule: immutable D/D+1 instants; per-field availability/failure; sunrise/night fractions; provenance. No stored completion flags.
- PrayerDaySnapshot: city context/date, five report references, completed count0…5, schedule health and current next/following prayer.
- PrayerAvailability: setupRequired, loading, available, partial/unavailable, recoverable error. Schedule and reports have independent health.
- PrayerActionFeedback: per-prayer pending/saved/failed plus captured date/context; late results cannot cross owner generations.
- TodayPrayerReference: mapped read-only snapshot with explicit prayer date/zone; no Prayer repository/database dependency in Today presentation.

The in-memory projection is bounded to current/next civil days per active context. The durable annual timetable covers the selected Gregorian year, with next year prefetched for at least twelve months of offline coverage after initial download. Tick changes countdown only; it does not read all historical reports, persist schedules or make network calls.

## Date and transition rules

At action submission sample now once, resolve current city date and capture report identity. A new request targeting an already previous/future day is rejected with refresh feedback. A valid accepted action that completes across midnight stays attached to its captured date. Account replacement invalidates uncommitted work and discards old UI emissions.

City change refreshes the local date query; it never moves old rows. Two devices with different city dates can display different days while sharing the same owner/date/prayer records.

Every explicit status may transition to any other status; missing→pending is a no-op unless an explicit reset/version is needed. Timers, next-prayer selection and date rollover never write statuses.

## Migration integrity

- Upgrade true historical local schemas v1…v8 to v9 before opening owner features; v8→v9 adds only the encrypted annual timetable.
- Add the two Prayer tables/indexes; preserve existing tasks, habit counters/history, maps/links, XP, outbox/base metadata and conflicts.
- Remove unused task_records.completion_xp and dependent generated mapper writes. Check actual physical existence before dropping: newest table declarations used by early upgrade paths may never create it.
- Keep existing v7 base_updated_at upgrade guards working for every older starting version.
- Use rollback/recoverable journal behavior; an injected failure must leave the old database readable.
- Test fresh v9, each historical path including an installed v8, restart after upgrade and deliberate migration failure/recovery. Changing only a target version number is not a historical-schema fixture.
