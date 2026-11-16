# Research: Adhkar and Qiyam

Design date: 2026-11-09. Sources:
- [spec.md](spec.md) and the Constitution v2.0.1;
- `namaa_plan.md` §10, §11, §14 and §20;
- the prototype (`AdhkarView.tsx`, `QiyamView.tsx`, `adhkarData.ts`, `AppContext.tsx`);
- the shipped 008 Prayer, XP, sync and Today code.

Each item below records the decision, the rationale and the alternatives considered.

## R1. Feature ownership: two domains, one spec

- **Decision.** Add two feature folders, `lib/features/adhkar/` and `lib/features/qiyam/`. Each owns its data, rules, Cubit and screen. The app composition layer wires them to Prayer times, XP and Today.
- **Rationale.** The plan treats Dhikr and Qiyam as independent areas (§10 and §11), and Constitution II requires each domain to own its data. The architecture tests already enforce feature isolation.
- **Alternatives.**
  - One combined "devotions" feature. Rejected: it would couple two domains that have different records, streaks and XP.
  - Placing them inside `prayer/`. Rejected: Prayer would become an aggregator of other domains.

## R2. Times come from Prayer through a narrow read port

- **Decision.** Prayer adds one read-only application API, `PrayerDayBoundaries`. For an owner and a civil date in the saved location's zone, it returns:
  - the Fajr and Maghrib instants for that date and the next date;
  - availability (`available`, `setupRequired` or `unavailable`).

  It reuses the encrypted annual timetable and the calculator fallback that 008 already uses. Adhkar and Qiyam each define their own small ports (`AdhkarTimesPort`, `QiyamNightPort`). Composition adapters implement those ports by calling Prayer.
- **The last third of the night.** Qiyam computes it for night D with the same pure function the Prayer screen uses, `PrayerScheduleProjection.from(today: D, tomorrow: D+1)`, so SC-005 holds by construction.
  - The Prayer screen shows the night that starts at today's Maghrib.
  - After midnight, Qiyam asks for D-1 and D. It never asks for today and tomorrow.
- **Alternatives.**
  - Recomputing times inside Adhkar/Qiyam. Rejected: a second calculation could drift from Prayer.
  - Reading `PrayerContextService` only. Rejected: it exposes today and tomorrow, which is wrong for a night in progress after midnight.

## R3. Adhkar day and periods (owner's ruling, 2026-11-09)

- **Decision.** Use a pure domain function `AdhkarClock.resolve(now, boundaries)`. It returns the Adhkar day, the current period and the next boundary instant.
  - **The Adhkar day** is identified by the civil date (in the location's zone) of the Fajr that opened it. A tap at 01:00 on Thursday belongs to Wednesday's day.
  - **The periods** are Morning, from Fajr to Maghrib, and Evening, from Maghrib to the next Fajr.
  - **Without a usable schedule**, the period is `unrestricted` and the day is the device's civil date.
  - **Refresh.** The Cubit schedules one timer to the next boundary, plus a refresh when the app resumes, so FR-006a's live update needs no per-second polling.
- **Time limits are enforced on the client** when a command is submitted, like 008's today-only rule.
  - The server cannot know the device's location.
  - The server accepts a past day, which may arrive later because of offline use.
  - It rejects any day more than two days ahead, as 0015 does.
- **Alternatives.**
  - Calendar-midnight days. Rejected: they contradict the ruling.
  - Hard server validation of periods. Rejected: it needs location on the server.

## R4. Qiyam night attribution and edit window

- **Decision.** A pure function `QiyamNight.resolve(now, boundaries)`.
  - Night D starts at Maghrib on date D. A record belongs to the most recent night that has started. Only that night is editable (FR-011a).
  - **Without a schedule**, a record made before 12:00 local time belongs to the previous date's night; from 12:00 on it belongs to the current date's night.
  - Start and end times are stored as local wall-clock `HH:mm` within that night. An end time earlier than the start time means the prayer crossed midnight.
- **Alternatives.**
  - The record date as the night (the prototype's behavior). Rejected by the owner.
  - Allowing edits to the last 7 nights. Rejected by the owner.

## R5. Adhkar sync granularity: one record per item per day

- **Decision.** Store one versioned record per (owner, Adhkar day, item ID) with an absolute `count` from 0 to the target.
  - Sync follows the 008 pattern: a typed RPC, operation receipts, newest-version-wins, and a visible conflict for divergent versions.
  - Two devices that count different items offline merge with no conflict. Only the same item counted on both devices offline produces a conflict, which stays visible.
- **Rationale.** It satisfies Constitution IV, with no silent discard and a visible losing version. It also gives the best natural merge: device A finishes items 1–5 and device B finishes items 6–10, and the set completes.
- **Alternatives.**
  - One record per list and day. Rejected: concurrent counting would discard a whole device's work as a conflict.
  - Taking the max count, or adding increment events. Rejected: the max silently drops a newer reset, which violates the constitution's newest-wins rule. Increments need a new CRDT protocol, which Constitution VIII forbids as speculative.

## R6. XP authority for Adhkar sets and Qiyam

- **Decision.** Extend the shared `XpAward` and the existing `xp_awards` table with two sources:

  | Source | Amount | `source_id` |
  |---|---|---|
  | `adhkar_set_done` | 15 | `UUIDv5(NS, 'adhkar/' + day + '/' + list)` |
  | `qiyam_done` | 30 | `UUIDv5(NS, 'qiyam/' + nightDate)` |

  `NS` is a new fixed namespace for 009. **Chosen at T010 (2026-11-09) and
  shared verbatim by Dart, SQL and the test vectors:**
  `70ca78e3-a267-4a2f-883f-1e0dea2df0c3`
  (`lib/core/data/sync/adhkar_qiyam_identity_namespace.dart`).
- **Server award.**
  - For Adhkar, the server evaluates set completion after each item upsert, using a seeded catalog of item IDs and targets per catalog version. It inserts the award once (`on conflict do nothing`) when every catalog item of that list and day is at its target in the active versions.
  - For Qiyam, the server awards on the first committed version with `performed = true`.
- **Client award.** As in 008, the client inserts a provisional local award atomically with the change. Settlement replaces it once with the canonical award.
- **Awards are permanent.** Later resets, a change to "No" and conflicts never revoke an award.
- **Alternatives.**
  - The client claims a set-complete operation. Rejected: the client would choose its own XP (Constitution VI).
  - Configurable amounts. These are out of scope, per the spec's assumptions.

## R7. Content: a bundled, reviewed catalog

- **Decision.** Ship the Adhkar and supplication content as a versioned asset, `assets/religious/adhkar_catalog_v1.json`. It holds the item IDs (stable `m1`…`m10` and `e1`…`e9` from the prototype), the list, the order, the target, the Arabic text, the English translation, the virtue (AR/EN) and the reference (AR/EN), plus the two Qiyam supplications with their sources.
  - `specs/009-adhkar-qiyam/content-sources.md` (written during implementation) records each item's primary-source check against the cited hadith collection.
  - The draft for each item compares:
    - the text and tashkeel against Hisn al-Muslim;
    - the hadith number and grading against Dorar (dorar.net) and sunnah.com.
  - **The product owner reviews and approves** each entry (decided 2026-11-09). An item is shipped only once it is marked approved.
  - Items that fail review are removed, never rewritten.
  - **Known points to check:**
    - **m9.** The cited Bukhari 3293 / Muslim 2691 appear to concern the 100-times form, not the 10-times form.
    - **"Hasbiyallah ×7" (Abu Dawud 5081).** Its grading is disputed.
    - **English translations.** They must come from a source whose license allows use, or be our own reviewed translation. Copyrighted editions such as the Darussalam translation are not copied.
    - **Ayat al-Kursi and the Mu'awwidhat.** They are absent from the prototype list. Adding them would bring in Quran text (Constitution V), so it needs an explicit owner decision.
  - The server seed copies only the IDs, lists and targets per catalog version, never the text.
  - A catalog version change keeps past records valid: completion is evaluated against the catalog version recorded with the day's items.
- **Alternatives.**
  - Hard-coded Dart strings. Rejected: harder to review and to diff against sources.
  - Fetching content at runtime. Rejected: the feature must work offline, and Constitution V protects sacred text from runtime changes.

## R8. Arabic display font

- **Decision.** Bundle **Amiri** (SIL Open Font License 1.1), Regular plus Bold if the review needs it. It is the first fallback in the prototype's `--font-quran` stack and renders full tashkeel correctly.
  - Use it only for Adhkar and supplication text.
  - The license file ships in the asset folder.
  - Confirm the archive checksum before adoption.
- **Alternatives.**
  - ThmanyahSans, the existing UI font. Rejected: it is a UI sans font that is weak on dense tashkeel.
  - Amiri Quran. Kept for the later Quran spec, where Quran text needs it.

## R9. Streaks are derived, never stored

- **Decision.** Both streaks come from indexed queries that walk back day by day, with the count of days visited capped at 3,650.
  - **Adhkar:** a day counts when both lists are complete, judged against that day's catalog version. The current day counts only if it is complete; otherwise the walk starts at the previous day.
  - **Qiyam:** count consecutive nights with `performed = true`, starting from the current night if it is performed, otherwise from the previous night.
  - A night recorded as "No" breaks the streak, and so does a night with no record.
  - The UI never shows "missed".
- **Alternatives.** A stored streak counter. Rejected: it creates a second source of truth (Constitution VI).

## R10. Local schema v10 and remote migration 0016

- **Decision.**
  - **Local:** the encrypted Drift schema goes from v9 to v10 with two additive tables, `adhkar_item_counts` and `qiyam_nights` (see [data-model.md](data-model.md)). The upgrade is tested with real historical fixtures.
  - **Remote:** `0016_adhkar_qiyam.sql` adds:
    - the remote tables;
    - a catalog seed;
    - receipts and conflicts;
    - two typed RPCs, `apply_adhkar_item_change_v1` and `apply_qiyam_night_change_v1`;
    - row-level security (RLS) and grants;
    - pgTAP tests.
  - The generic `pending_changes`, `conflict_records` and `xp_awards` tables are reused.
- **Alternatives.** A cloud JSON document per day, as in the prototype's Firestore. Rejected: no RLS-typed integrity and no receipts.

## R11. Navigation and Home

- **Decision.**
  - **Routes:** add the top-level sibling routes `/adhkar` and `/qiyam`.
  - **Track hub:** enable the Adhkar and Qiyam tiles. Quran and Focus stay "coming soon".
  - **Shell:** the new screens open as tab sections that highlight Track, using `go` with no stacking, no app-bar back arrow, and device back to Home.
  - **Home:** replace the sample Adhkar/Qiyam values in `today_focus_reflection_card` and `today_progress_hero` with a `TodayAdhkarQiyamPort` projection: Morning x/N, Evening x/N, and tonight's Qiyam state. Keep the provenance labels for any remaining sample values, and make the quick hubs open the real screens.
- **Alternatives.** Opening the screens as sheets over Home. Rejected: the owner wants a tab model.

## R13. Catalog expansion and Quran text (2026-11-15)

- **Decision.** The owner approved the prototype's 21 entries and asked for the remaining Morning and Evening adhkar of Hisn al-Muslim, plus Ayat al-Kursi and the Mu'awwidhat.
  - Hadith adhkar come from Hisn al-Muslim, through the open-licensed Seen-Arabic dataset, with each grading checked on dorar.net (`content-sources.md`).
  - Quran text: first proposed from Tanzil's Uthmani text. The owner rejected Ayat al-Kursi as rendered: Tanzil marks open tanween with small-meem code points (U+06ED, U+06E2) that only a font built for them shows correctly. On 2026-11-16 the owner chose the KFGQPC Madinah Mushaf text (Hafs, QPC Hafs encoding) with the matching KFGQPC Uthmanic Hafs font, obtained through the Quran Foundation.
  - Licensing: the KFGQPC font forbids reproduction without the Complex's written approval, and the Quran Foundation terms do not by default cover a build-time bundle of its content. On 2026-11-16 the owner registered a Quran Foundation developer app and decided to ship with the Quran Foundation credited, without waiting for a written answer (content-sources.md, "Quran source").
  - The catalog is Arabic only (D3): no translation fields.
- **Alternatives.**
  - Copy the Quran text from the Hisn al-Muslim dataset. Rejected: it mixes imla'i and Uthmani spellings.
  - Ship the expansion as a later catalog version. Rejected by the owner on 2026-11-15.

## R14. My Adhkar (2026-11-15)

- **Decision.** The user's own adhkar live in the Adhkar feature, not a new feature folder, because they share the Adhkar day, clock, counter widgets and sync service.
  - Two record types: the item (text, target, note, tombstone) and the per-day count. Item IDs are random UUIDv4 values, since two devices can add items offline; count IDs are UUIDv5 like the catalog counts.
  - A delete is final, so a tombstone always wins. Newest-wins applies only between live versions.
  - No XP and no streak (owner, 2026-11-15), so the RPCs never touch `xp_awards`, and nothing on the server needs to trust user text.
  - Additive local schema v11 and migration 0017, so the reviewed v10 and 0016 stay unchanged.
  - Defaults the owner can change: 100 items, text ≤ 1000, target 1–1000, note ≤ 300, add-order only.
- **Groups (owner, 2026-11-16).** The user organizes the items in named groups («الفجر», «رمضان», «أدعية الكرب»). Every item is in at least one group and may be in several; deleting a group deletes the items left in no group.
  - A third record type, the group (name, tombstone), with a random UUIDv4 ID.
  - Membership is part of the item's version (`group_ids` in the item change), stored in a join table with the order the item was added to each group. This keeps one item, one counter and one conflict unit, instead of syncing memberships as separate records.
  - The server applies the group delete cascade itself, so other devices converge from server item versions; the client queues only the group delete.
  - v11 is unreleased, so the group tables join v11 in place.
  - Defaults: 30 groups, name ≤ 60 code points. All lengths are counted in code points on both sides.
- **Alternatives.**
  - Mixing user items into the Morning and Evening lists. Rejected by the owner (third tab chosen).
  - A single group per item. Rejected by the owner: one dhikr may belong to several groups.
  - Membership rows as their own sync entity. Rejected: more conflict cases for no user benefit.
  - Folding the text into the count record. Rejected: it would copy the text into every day's row and make edits rewrite history.
  - Amending v10 and 0016. Rejected: both are reviewed and tested; an additive step is safer.

## R12. CI placement

- **Decision.** Add the new integration files to the existing `prayer` Android suite and iOS group (renamed "prayer / religious" only in labels if needed), and to the desktop file lists. Hosted tests use run-tagged operation IDs and random past days, as 008 does.
- **Alternatives.** A new mobile group. Rejected: it adds runner time and iOS flakiness exposure for a small suite.
