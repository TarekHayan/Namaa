# Feature Specification: Prayer Experience

**Feature Branch**: `namaa/008-prayer-experience`

**Created**: 2026-10-29

**Status**: Clarified — ready for planning

**Input**: User description: "شوف الجزء القادم ف ال namaa plan و ال prototype عشان ال ui"

## Clarifications

### Session 2026-11-01

- The user now wants the Prayer screen to use the device's current location instead of requiring typed city search. On first setup it requests foreground location permission, obtains coordinates and their time zone, and saves them on this device. A saved device location refreshes on later Prayer visits when it materially changes; a manually selected city is not overridden. Manual city selection remains available when permission, location services, accuracy or network lookup fails. No background tracking is introduced.
- Prayer times use the measured coordinates and the selected calculation method. The API's location-based method suggestion is used on first setup; a previously chosen method remains under the user's control. The screen identifies whether displayed times came from the annual AlAdhan table or the local fallback.

### Session 2026-10-29

- Q: If the city changes on the phone, should it also change on the desktop? → A: Each device retains its own selected city; changing one device does not change another device's city. Prayer reports still synchronize between devices.
- Q: If a prayer earns 5 XP as late and is then corrected to on time, should its reward stay 5 or become 10? → A: The first eligible completion fixes the reward: 10 XP on time or 5 XP late. Later correction or reset does not change the awarded points.
- Q: May users record or correct previous days in 008? → A: Recording and correction are limited to the current day. Previous records are retained; the history interface and previous-day editing are deferred.
- Q: May first-time discovery of a new city require internet access? → A: Yes. Search for a new city requires internet; after saving it, its location/time-zone data supports fully offline prayer calculation, including subsequent days.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See real prayer times for a chosen city (Priority: P1)

As a user, I allow foreground location once and see today's five prayer times, the next prayer and its remaining time for my coordinates. I can choose a city manually if location is unavailable, and a saved location works offline.

**Why this priority**: The location and date must be clear before a prayer schedule can be trusted.

**Independent Test**: Choose a supported city, open Prayer and Home, disconnect and restart; both screens show the same real schedule for that city and date.

**Acceptance Scenarios**:

1. **Given** no saved location, **When** Prayer opens, **Then** it requests foreground location permission and never silently assigns Cairo or another location. A manual city option remains visible.
2. **Given** a supported city is selected and saved, **When** the schedule appears, **Then** city, calculation method, civil date and applicable time zone identify it, and the choice survives an offline restart.
3. **Given** a valid selected city, **When** the schedule loads, **Then** Fajr, Dhuhr, Asr, Maghrib and Isha appear in order, followed by sunrise, middle of the night and start of its last third.
4. **Given** Isha has begun today, **When** Home shows the next prayer, **Then** it shows tomorrow's Fajr and following prayer, with a non-negative countdown and clear day context.
5. **Given** midnight, a daylight-saving change, app resume or changed city/method, **When** the screen becomes current, **Then** affected times, date labels and countdown refresh without changing saved prayer reports.
6. **Given** a valid time cannot be calculated, **When** the screen opens, **Then** the unavailable value is explained with a recovery action, without a guessed time presented as real.
7. **Given** two devices with different selected cities, **When** one device changes city, **Then** the other keeps its own city and schedule; both still share reports identified by owner/date/prayer.
8. **Given** no location has been saved and the device is offline or location permission is denied, **When** automatic location fails, **Then** the reason and manual city option are visible; no default location is silently assigned.
9. **Given** a city has been saved and its annual timetable downloaded, **When** several days pass offline or the app restarts, **Then** it reads the saved timetable without downloading daily times again.
10. **Given** the saved annual timetable no longer covers the displayed day and there is no internet, **When** Prayer opens, **Then** a local calculation uses the saved city, zone and method and clearly identifies itself as the fallback source.

---

### User Story 2 - Record today's prayers deliberately (Priority: P1)

As a user, I mark each of today's prayers as completed on time, completed late or explicitly missed, and can correct the choice or reset it to unconfirmed. Reports survive restart and lack of internet.

**Why this priority**: Recording a religious practice must reflect the user's own confirmation and preserve it durably.

**Independent Test**: Apply all four states, correct/reset them, restart offline and verify the five records and daily completed count.

**Acceptance Scenarios**:

1. **Given** a new day without reports, **When** any scheduled time passes, **Then** its prayers remain pending/unconfirmed with 0/5 completed; none becomes missed automatically.
2. **Given** a pending prayer, **When** on time or late is selected, **Then** the chosen state appears and the completed count increases once; missed does not count as completed.
3. **Given** a recorded prayer, **When** corrected or reset to pending, **Then** only that prayer changes and progress reflects the resulting states without duplicate records.
4. **Given** repeated submission/retry, **When** the action finishes, **Then** the report and any eligible reward are applied once.
5. **Given** an unconfirmed prayer through midnight, **When** a new day starts, **Then** the old record stays unconfirmed and the new day's records are separate.
6. **Given** a saved on-time/late report, **When** the city or method changes, **Then** its user-reported classification is retained rather than judged again from the clock.
7. **Given** a late completion already earned 5 XP, **When** corrected to on time, **Then** the prayer status and progress change but its reward stays 5 XP; likewise, correcting an awarded on-time completion to late or resetting it leaves its original 10 XP unchanged.
8. **Given** a previous day's prayer was never reported, **When** today's screen opens, **Then** 008 offers no backdated entry or history-editing route, and the retained previous record remains unconfirmed rather than becoming missed.

---

### User Story 3 - Use the prototype's Prayer screen across devices (Priority: P2)

As a user, I reach Prayer through the existing navigation and use its familiar cards on phone and desktop, in readable Arabic or English with Namaa's approved appearance.

**Why this priority**: The feature needs usable presentation matching the supplied prototype from its first implementation.

**Independent Test**: Compare the four screen groups to the prototype and exercise city selection, all state actions and return navigation in both languages/themes, including touch and keyboard operation.

**Acceptance Scenarios**:

1. **Given** Prayer opens, **When** displayed, **Then** its groups are heading/location/daily progress, five prayer cards, three supplementary-time cards, and the Jahr/Sirr explanation, in that order.
2. **Given** a prayer card, **When** displayed, **Then** it contains name, time, obligatory rak'ah count, recitation label, short guidance and on-time/late/missed actions, with selected-state text/icon and color cues.
3. **Given** a narrow screen or enlarged text, **When** labels wrap, **Then** cards grow and actions stack/wrap without clipped content, overlap or horizontal page scrolling.
4. **Given** a desktop, **When** Prayer opens, **Then** the persistent sidebar remains, details/actions share wider rows when they fit, and hover/focus feedback matches the app.
5. **Given** Track on phone, Home's prayer card/quick hub or desktop's Prayer entry, **When** opened, **Then** all lead to the same Prayer experience with working return navigation.
6. **Given** a planned-domain entry or the prototype's global-streak slot, **When** visible, **Then** it is clearly coming soon without invented records or an unrelated Habit/global streak.

---

### User Story 4 - Keep Prayer, Home and rewards consistent across devices (Priority: P2)

As an account user, I synchronize prayer reports safely while Home reflects the Prayer-owned schedule and progress. Development preview stays separately usable without public sign-in.

**Why this priority**: Independent devices must agree without losing reports or awarding a prayer twice.

**Independent Test**: With two isolated stores for one account, report different prayers offline, then edit the same prayer divergently; reconnect with repeated deliveries and verify merging, conflict visibility, progress and reward uniqueness.

**Acceptance Scenarios**:

1. **Given** different prayers edited on two devices offline, **When** synchronized, **Then** both survive without a false conflict from sharing a day.
2. **Given** divergent reports for the same prayer/date from the same base, **When** synchronized, **Then** newest timestamp selects the active report and the other stays visible for review; differing equal-timestamp content is also retained with a deterministic active result.
3. **Given** a normal sequential edit or inbound update without competing local work, **When** synchronized, **Then** it creates no false conflict.
4. **Given** one eligible reward already exists for a prayer/date, **When** completion is corrected, reset, repeated or replayed from another device, **Then** no second award is granted.
5. **Given** Prayer data is available, **When** Home opens, **Then** it shows the same city, next/following prayer and completed count, while other unimplemented-domain figures remain sample-labelled.
6. **Given** preview or another account is opened, **When** records are read, **Then** no previous owner's reports, preferences, conflicts or rewards appear.

### Edge Cases

- No selected city, cancelled selection, unsupported city or failed search: retain the last valid choice; never pair a new label with old coordinates/times.
- City time zone differs from the device's: clearly label the selected city's date/zone and use it consistently.
- Devices select cities with different civil dates: each displays its own city-local day and reads the shared reports for that date; synchronization never relabels a report to the receiving device's current day.
- Exact prayer-time boundary, after Isha, civil midnight, month/year boundary, app sleep/resume, clock correction and daylight-saving transition.
- Uncomputable/high-latitude times: explain unavailable fields without a fabricated fallback; manual reporting remains independent once a valid prayer-day context exists.
- Saved-city calculation works offline even if city search is unavailable; searching for a new city requires connectivity and must say so. An unavailable search never disables the saved city's calculation or prayer reporting.
- Long names/guidance, mixed-direction times, 150% text, minimum phone width, safe-area insets, keyboard focus and repeated taps.
- A date changes while an action is pending: retain the explicitly targeted date/prayer rather than applying it to the newly visible day.
- Preference-save failure preserves the previous confirmed preference; historical reports never migrate dates after a city/method change.
- Conflicting reset/completion, equal timestamps, duplicate delivery and owner change during work preserve reports and reward uniqueness.
- Persistence or upgrade failure preserves recoverable prior data and does not claim unsaved actions are durably saved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Prayer MUST be a bounded feature comprising schedule, today's manual reports, prototype-derived UI, Home integration, persistence and synchronization. Public sign-in/registration stays deferred; isolated development preview MUST open directly.
- **FR-002**: First setup MUST request foreground device location permission, resolve measured coordinates and their IANA time zone, and save that context locally for offline use. It MUST reject unavailable or grossly imprecise fixes and MUST NOT perform background tracking. Manual city search remains an explicit fallback; it requires connectivity for a new city and discloses that requirement.
- **FR-003**: Schedule preferences MUST be retained independently per owner on each device, identify coordinates, time zone and method, and MUST NOT overwrite another device's schedule preferences through synchronization. Prayer reports remain synchronized account data. Supported methods MUST match the prototype: Egyptian, Muslim World League, Umm al-Qura, Dubai, North America, Kuwait and Qatar. Automatic first setup uses a supported method suggested by the location-based provider (otherwise Muslim World League); the user can change it independently of location.
- **FR-004**: New city selection MUST be confirmed before replacing a valid choice. Search/loading/validation/no-results/offline/unavailable/saved states MUST be distinguishable. Failed or cancelled search MUST retain the saved city and its working schedule. Without a saved city, offline search MUST explain the connectivity requirement rather than invent a location.
- **FR-005**: Times MUST use the chosen city's civil date/time zone and method. AlAdhan's annual timetable for the chosen coordinates, zone and method is the primary source; a complete year is retained locally. If a date is not covered and the service is unavailable, the verified on-device calculator is an explicitly identified fallback. A city label MUST NOT substitute for actual location; zero-valued coordinates MUST NOT trigger a Cairo fallback.
- **FR-006**: Exactly five obligatory prayers MUST appear in Fajr, Dhuhr, Asr, Maghrib, Isha order. Sunrise, middle of night and start of last third MUST be separate informational values, not additional obligatory completions.
- **FR-007**: Next/following prayer, their dates and non-negative remaining time MUST derive from the same schedule, including tomorrow after Isha. They MUST refresh at time boundaries, preference changes and app resume.
- **FR-008**: Each owner/date/prayer MUST have one report with pending, completed on time, completed late or missed state. Pending means unconfirmed; only an explicit user choice can record missed. Time passage, notification or absence of interaction MUST NOT infer religious failure.
- **FR-009**: Users MUST set, correct and reset today's reports. On-time/late are manual reports, not judgments inferred from tapping time. Historical reports MUST be retained; previous/future-day editing and a standalone history browser are outside 008.
- **FR-010**: Daily progress MUST equal distinct on-time plus late prayers divided by five. Pending/missed do not count, and no prayer contributes twice.
- **FR-011**: Report actions MUST update visible and durable local state without waiting for connectivity. Failure feedback MUST distinguish saved from unsaved work and allow retry without duplication.
- **FR-012**: The prayer date MUST follow the selected city's zone. A city/date change MUST NOT move historical reports. An action already in progress MUST remain attached to its captured date/prayer.
- **FR-013**: Synchronization MUST merge independent prayer/date edits, compare the last acknowledged base for competing writes, preserve divergent versions for review and select newest timestamp. Differing equal-timestamp content MUST have a deterministic active outcome with visible preserved evidence. Sequential edits and uncontested inbound changes MUST NOT create false conflicts.
- **FR-014**: Reports, preferences, pending work, visible conflicts and reward identities MUST remain owner-isolated and locally protected. Preview MUST stay separate; upgrades MUST preserve all existing domain records.
- **FR-015**: Rewards MUST use the centralized authority. Following prototype defaults, the first eligible completion of a prayer/date grants 10 XP on time or 5 XP late; pending/missed grants none. A prayer/date receives at most one award: later correction, reset or repeat does not add, subtract or replace it. Account reward amounts MUST NOT be trusted from an editable device value.
- **FR-016**: Prayer MUST own its schedule, reports and daily progress. Home MUST consume these rather than maintain duplicate prayer history or infer completion from card visits.
- **FR-017**: Home's prayer card MUST replace sample city/times/countdown with real Prayer data and open Prayer; its prayer progress metric MUST show the real count. Before setup or on failure, Home MUST show the same honest setup/unavailable state instead of live-looking sample times.
- **FR-018**: Home MUST preserve separate Task/Habit ratios. The overall sample ring and other unimplemented-domain values MUST retain sample labels; 008 introduces no new blended-progress formula.
- **FR-019**: The screen MUST preserve the prototype's four ordered groups: heading/location/progress, five prayer cards, three supplementary-time cards, and two-part Jahr/Sirr explanation. Cards MUST retain all name/time/rak'ah/recitation/guidance/state roles.
- **FR-020**: The prototype's global-streak slot MUST be clearly coming soon, not reuse a Habit/global streak or invent Prayer streaks. Streak algorithms, achievements and reward customization remain in the later motivation feature.
- **FR-021**: Presentation MUST use Namaa's approved light/dark colors, primary font and app identity; buttons, selectors, typography, feedback, surfaces and hover/focus states MUST match the existing shared visual conventions.
- **FR-022**: Phone retains five main bottom destinations with Prayer accessible through Track and prayer entry points. Desktop retains the persistent sidebar and direct Prayer entry. Other planned religious/focus destinations MUST remain clearly coming soon.
- **FR-023**: Layout MUST follow the prototype's compact heading, rounded spaced cards and adaptive action rows. Content MUST grow/wrap with text and accessibility scaling rather than overlap controls or be hidden by fixed heights.
- **FR-024**: Arabic/English MUST cover names, states, plurals/counts, times/dates, city/method selection, guidance, errors and accessibility labels. Both themes MUST support RTL/LTR, mixed-direction times, visible keyboard focus and state cues beyond color on mobile/desktop.
- **FR-025**: Recitation/rak'ah/guidance copy MUST be verified against an attributable approved reference before acceptance. The prototype is a presentation reference, not sufficient validation for religious instruction. No Quran text or new religious ruling is generated in 008.
- **FR-026**: Saved-city schedules and reports MUST be usable after offline restart and on subsequent days. The saved annual timetable MUST cover its complete Gregorian year, remain owner/context-isolated and survive restart. A partial or invalid download MUST NOT replace valid cached times. When its coverage ends without internet, saved location/time-zone data MUST enable a clearly labelled local calculation. Daily display MUST NOT require a new search or a daily download. Unavailable schedule fields MUST stay distinct from unconfirmed reports.
- **FR-027**: Adhan playback, notification permissions, scheduling/delivery and device-specific notification preferences are deferred to Notifications. Any exposed affordance MUST explicitly say coming soon and MUST NOT claim an active reminder.
- **FR-028**: Quran, Dhikr, Qiyam tracking/reminders, Pomodoro, background location tracking, new general Settings, religious exemptions/travel adjustments and advanced calculation adjustments are outside 008. Future domains may consume Prayer boundaries without taking ownership of the schedule.

### Key Entities *(include if feature involves data)*

- **Prayer Preferences**: Owner/device-scoped confirmed city/country, coordinates, time-zone identity and method, retained locally rather than synchronized to other devices. These determine calculation context, not reported completion.
- **Daily Prayer Schedule**: City-local date/context with five times, sunrise, next-day boundaries, night fractions, field availability and explicit API-cache or local-fallback provenance; not a completion record.
- **Annual Prayer Timetable**: Encrypted owner/device/context/year cache of a validated complete AlAdhan response. Its validity is by covered dates and selected city coordinates, zone and method, not an arbitrary elapsed-time promise.
- **Prayer Report**: One owner/date/prayer, its status, reported completion time when applicable, original date/zone context and version. Different prayers can reconcile independently.
- **Prayer Reward Identity**: Unique owner/date/prayer relationship to one centralized reward, distinct from current report status and preserved across correction/replay.
- **Prayer Guidance**: Reviewed bilingual names, rak'ah counts, recitation descriptions and explanatory copy with attributable source.
- **Prayer Conflict**: Competing synchronized report versions and active/non-winning outcome, visible to their owner. Device-local schedule preferences do not create cross-device conflicts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A scripted first-use journey selects a city, identifies method/date, opens all five times and returns Home within 60 seconds, using phone touch and desktop keyboard input.
- **SC-002**: A documented matrix covering at least three cities with distinct zones, all seven methods, representative season dates and an applicable daylight-saving transition agrees with the chosen independent reference within one minute for the five times and sunrise. Night fractions match the documented reference rule; unsupported fields are explicitly unavailable.
- **SC-003**: All four-state transitions keep correct 0/5 through 5/5 completed counts, survive offline restart, and produce zero automatic missed reports.
- **SC-004**: Ten replays/reconnects of one operation produce one report and at most one reward. Two-device scenarios retain independent edits, expose same-prayer/date conflicts and leak zero records across owners.
- **SC-005**: At 320, 390, 430, 768 and 1200 logical-pixel widths, Arabic/English, both themes and 100%/150% text, all four groups and five prayer actions stay operable with zero clipped primary text, overlap or horizontal page overflow.
- **SC-006**: On named phone/desktop test targets, saved Prayer content becomes readable offline within two seconds, a saved status action appears within one second, and midnight/resume selects the correct prayer/day without changing saved reports. Advancing through seven consecutive cached dates offline reads the saved year's schedules without contacting city search or a daily-times service; advancing beyond coverage offline uses an explicitly labelled local fallback.
- **SC-007**: On each device, Prayer and Home agree on city, next/following prayer and count in every setup/change/unavailable/offline fixture. A city change leaves the other device's selection unchanged; differing city-local dates read the correct shared reports without relabelling them. Real Prayer values have no sample marker; remaining sample-domain values keep theirs.
- **SC-008**: A recorded prototype comparison accounts for every group, card field and action. Differences are limited to the explicitly documented identity, navigation, integrity, setup and deferred-feature adaptations.

## Assumptions

- Prayer is next after Core Productivity in Namaa Plan sections 8, 24 and 27. The remaining final prototype audit of 007 stays an existing follow-up; starting 008 does not complete it.
- User decisions, 2026-10-29: manual city selection saved for offline use; Adhan and notifications deferred to their later phase.
- User decision, 2026-10-31: use an AlAdhan annual timetable as the primary schedule, keep it on-device for offline use, and fall back to local calculation after the saved year's coverage ends without internet.
- Namaa's existing colors, ThmanyahSans primary font, icon and shared controls take precedence over the prototype's selectable fonts/themes.
- Parity does not copy the prototype's silent Cairo assumption, unrelated global streak, whole-day overwrites or editable reward authority.
- No GPS is required. The user approved online search for new cities and fully offline calculation after saving a city, including subsequent dates. Search-provider coverage, location/time-zone provenance, limits and failure behavior must be documented in planning; a bundled offline city catalog is not required in 008.
- Selected city/time-zone/method preferences remain owner-isolated on each device and do not synchronize. They do not change the system time zone. Prayer reports and rewards synchronize by owner/date/prayer. Notification enablement will also be device-specific later.
- User confirmed that status recording/correction is limited to today. Retained dates support later history/analytics; history UI and previous-day editing are deferred.
- User confirmed that the first eligible completion fixes the one-time reward at 10 XP on time or 5 XP late; later correction/reset leaves the award unchanged.
- Night fractions follow the verified calculation reference selected during planning; no alternate high-latitude fallback is silently invented.
- Existing account infrastructure can test synchronization with isolated accounts while development preview remains available without public login.
