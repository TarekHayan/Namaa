# Tasks: Adhkar and Qiyam (009)

**Branch**: `namaa/009-adhkar-qiyam`

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/) and [quickstart.md](quickstart.md).

**Tests**: Included. The constitution (VIII) and the spec require unit, widget, migration, SQL and device evidence.

**Organization**: 102 tasks in 8 phases (Phase 6b added on 2026-11-15; My Adhkar reshape T100–T102 added on 2026-11-16). Each task names its exact paths, the tasks it depends on, and a completion condition you can check.

## Instructions for the implementing model

1. **Scope.** Work only on the phase or tasks the product owner asked for. Before editing, read the task's contract and the current target files.
2. **Read first.** Once per session, read `AGENTS.md`, `.specify/memory/constitution.md`, the spec and the plan. The contracts define behavior; this file defines order.
3. **Order.** Start a task only after its **Depends** tasks and the previous phase's checkpoint are done.
   - `[P]` means the listed files can be worked on independently once the prerequisites are done.
   - `[P]` never permits overlapping work on the migration, the ARB files, the composition, generated code or `verification.md`.
4. **Tests first.** For a test task, write the named cases before the implementation and confirm they fail. Never weaken an assertion to get to green.
5. **Domain rules.** Domain and application code import no Flutter, Drift, Supabase or uuid implementation.
   - Use `AppResult`/`AppFailure`, Cubits, the encrypted DB, the outbox and router, the shared XP ledger, and the shared widgets.
   - Mirror the 008 Prayer patterns. Do not copy Prayer's business rules.
6. **Strings.** Every user-facing string goes in `lib/app/l10n/app_ar.arb` and `app_en.arb`. Edit them line by line; never re-serialize them. Religious text comes only from the reviewed catalog.
7. **Marking done.** Mark a task `[x]` only when its **Done** condition is true and its focused test passes. Record commands and results in `specs/009-adhkar-qiyam/verification.md` at each checkpoint.
8. **Approval needed for:**
   - pushing migrations 0016 and 0017 to staging;
   - adding Quran text (Ayat al-Kursi or the Mu'awwidhat);
   - committing, pushing or merging.

   Production is never touched.

## Fixed implementation facts

| Topic | Required decision |
|---|---|
| Adhkar day | Starts at Fajr in the saved Prayer location's zone. It is identified by the civil date of that Fajr. Without a schedule, it is the device's civil date. |
| Periods | Morning can be counted from Fajr until Maghrib; Evening from Maghrib until the next Fajr. Outside its period a list is read-only; reset is still allowed. Without a schedule, both lists are countable and a setup prompt shows. |
| Qiyam night | Night D starts at Maghrib on D. A record belongs to the most recent night that has started, and only that night is editable. Without a schedule, before 12:00 local time means the previous date's night. |
| Qiyam fields | `rakahs` must be one of 2/4/8/11, and only when performed (default 4). `witr` defaults to true when performed. `start_time`/`end_time` use `HH:mm` and are optional. `note` is "≤ 500 characters". When not performed, every detail is cleared. |
| XP | `adhkar_set_done` 15, once per owner, day and list. `qiyam_done` 30, once per owner and night. The server derives the award. The local award is provisional until settled. Awards are never revoked. Task 20 and Prayer 10/5 stay unchanged. |
| Identity | `UUIDv5(NS009, …)`: `'adhkar-item/'+day+'/'+itemId`, `'qiyam/'+nightDate`, `'adhkar/'+day+'/'+list`. `NS009` is fixed once in T010 and shared with SQL: `70ca78e3-a267-4a2f-883f-1e0dea2df0c3`. |
| Sync | One record per item per day, and one per night. Typed RPCs with receipts. Newest wins; an equal-timestamp tie is broken by the semantic key; the losing version is kept as a visible conflict. The server rejects a day more than 2 days ahead. |
| Streaks | Derived, never stored. Adhkar: a day counts when both lists are complete. Qiyam: consecutive nights performed. The current day or night does not break the streak before it ends. The walk is capped at 3,650 days. |
| Content | `assets/religious/adhkar_catalog_v1.json` with IDs m1…m10 and e1…e9. An item ships only when it is marked approved by the product owner in `content-sources.md`. Text is shown in Amiri. |
| UI | Routes `/adhkar` and `/qiyam`. Sections highlight Track. No stacked pages, no back arrow; device back goes Home. Groups follow the prototype order. No notifications. |

## Format

`- [ ] Tnnn [P?] [USn?] Action with exact path`, followed by **Depends** and **Done**.

---

## Phase 1: Setup

**Goal**: Verified inputs, a reviewed content draft, and the font, with no behavior change.

**Checkpoint**: The baseline is recorded, the content draft is ready for the owner's review, and the font asset is adopted.

- [x] T001 Create specs/009-adhkar-qiyam/verification.md with the baseline: branch, local schema v9, migrations 0001–0015, and empty SC-001…SC-008 sections.
  - **Depends**: None.
  - **Done**: Existing evidence is kept apart from 009 evidence; every SC is marked pending.
- [x] T002 [P] Create specs/009-adhkar-qiyam/content-sources.md from prototype/src/data/adhkarData.ts and the two Qiyam supplications in prototype/src/views/QiyamView.tsx.
  - **Depends**: T001.
  - **Done**: Each item has:
    - its ID, list, target, Arabic text and English translation;
    - its virtue and reference in AR/EN;
    - a comparison of the text against Hisn al-Muslim;
    - its hadith number and grading checked on dorar.net and sunnah.com, with links;
    - its discrepancies;
    - the translation's license source;
    - `Status: pending owner review`.

    m9's reference mismatch, the grading of "Hasbiyallah ×7" (Abu Dawud 5081), and the open question on Ayat al-Kursi and the Mu'awwidhat are written as explicit decisions for the owner.
- [x] T003 [P] Add Amiri Regular and its OFL license under assets/fonts/amiri/ and register the family `Amiri` in pubspec.yaml.
  - **Depends**: T001.
  - **Done**: The archive checksum and license are recorded in verification.md, no other font or package changes, and `flutter pub get` resolves.

---

## Phase 2: Foundational (blocks every story)

**Goal**: Shared values, the Prayer boundaries port, the XP sources, local schema v10, migration 0016, and the catalog loader.

**Checkpoint**: `flutter test` and `supabase test db` are green, and the v10 migration passes every historical fixture.

### Catalog and identity

- [x] T004 [P] Write tests in test/unit/features/adhkar/domain/adhkar_catalog_test.dart.
  - **Depends**: T002.
  - **Done**: They fail for each of these: duplicate IDs, duplicate positions in a list, target < 1, blank text or reference, an unknown list, and an item not marked approved, which must be excluded.
- [x] T005 [P] Implement lib/features/adhkar/domain/adhkar_catalog.dart (`AdhkarCatalog`, `DhikrItem`, `AdhkarList`, `QiyamSupplication`, plus validation).
  - **Depends**: T004.
  - **Done**: T004 passes, with no Flutter imports.
- [x] T006 Create assets/religious/adhkar_catalog_v1.json from content-sources.md, and register it in pubspec.yaml.
  - **Seed note (Phase 2 review):** the same change that ships the approved asset also generates the `adhkar_catalog_items` seed rows in migration 0016 from that asset (IDs, lists, positions and targets only, approved items), so the server can never award or accept counts for items the client does not ship. `test/unit/features/adhkar/data/catalog_seed_sync_test.dart` pins the asset and the seed together.
  - **Depends**: T002, T005.
  - **Done**:
    - `catalog_version` is 1.
    - Only items the owner has marked approved carry `"approved": true`.
    - The texts match content-sources.md byte for byte.
- [x] T007 [P] Write tests in test/unit/features/adhkar/data/asset_adhkar_catalog_test.dart.
  - **Depends**: T005.
  - **Done**: They cover:
    - the real asset loads, with only approved items visible;
    - a malformed JSON returns `contentUnavailable` instead of throwing;
    - the version is exposed.
- [x] T008 Implement lib/features/adhkar/application/adhkar_catalog_port.dart and lib/features/adhkar/data/asset_adhkar_catalog.dart.
  - **Depends**: T006, T007.
  - **Done**: T007 passes, and the catalog is cached per version.
- [x] T009 [P] Write identity vectors in test/fixtures/adhkar_qiyam/identity_vectors.json, with tests in test/unit/features/adhkar/data/adhkar_identity_test.dart and test/unit/features/qiyam/data/qiyam_identity_test.dart.
  - **Depends**: T001.
  - **Done**: The vectors cover the item, night and set source IDs, plus conflict IDs for reversed arrival order.
- [x] T010 Implement lib/features/adhkar/data/uuid_adhkar_identity.dart and lib/features/qiyam/data/uuid_qiyam_identity.dart with one fixed `NS009` namespace constant.
  - **Depends**: T009.
  - **Done**: T009 passes, and the namespace is written into research.md R6 and the fixed facts above.

### Prayer boundaries port

- [x] T011 [P] Write tests in test/unit/features/prayer/application/prayer_day_boundaries_test.dart.
  - **Depends**: T001.
  - **Done**: They cover:
    - an available date returns Fajr, Maghrib and the next Fajr from the annual cache;
    - the calculator fallback;
    - `setupRequired` when there are no preferences;
    - `unavailable` when any instant is missing (high latitude);
    - `changes` fires when the location or method changes;
    - no network call per request.
- [x] T012 Implement lib/features/prayer/application/prayer_day_boundaries.dart and lib/features/prayer/data/prayer_day_boundaries_reader.dart, reusing the existing annual schedule and calculator ports.
  - **Depends**: T011.
  - **Done**: T011 passes, and the Prayer screen's behavior is unchanged (the existing Prayer tests stay green).

### XP sources

- [x] T013 [P] Extend the tests in test/unit/features/xp/ (create xp_award_sources_test.dart).
  - **Depends**: T001.
  - **Done**:
    - `adhkar_set_done` is accepted only with 15, and `qiyam_done` only with 30.
    - `fromStored` accepts both.
    - `task_done` 20 and `prayer_done` 10/5 stay unchanged.
- [x] T014 Update lib/features/xp/domain/xp_award.dart with `kAdhkarSetDoneAwardSource` and `kQiyamDoneAwardSource`.
  - **Depends**: T013.
  - **Done**: T013 passes, and lib/features/today/data/xp_today_adapter.dart totals the new sources without double counting.

### Local schema v10

- [x] T015 Extend test/unit/core/data/local/ with adhkar_qiyam_migration_test.dart and update test/fixtures/prayer/migrations/schema_versions.json to include v10.
  - **Depends**: T001.
  - **Done**:
    - Every historical v1…v9 path upgrades to v10.
    - All existing rows survive.
    - A fresh v10 database is created correctly.
    - An injected migration failure leaves v9 readable.
    - A restart after the upgrade works.
- [x] T016 Add `AdhkarItemCounts` and `QiyamNights` to lib/core/data/local/foundation_database.dart, set `kFoundationSchemaVersion = 10`, add the migration step, and regenerate foundation_database.g.dart.
  - **Depends**: T015.
  - **Done**:
    - The columns, keys and indexes match data-model.md. They include "0 ≤ count ≤ target", "rakahs: null when performed is false; otherwise one of 2, 4, 8, 11" and "note ≤ 500 characters".
    - T015 passes.
    - The existing migration tests pass.

### Remote migration 0016

- [x] T017 [P] Write supabase/tests/adhkar_account_isolation_test.sql, adhkar_operation_integrity_test.sql, adhkar_conflict_integrity_test.sql and adhkar_xp_integrity_test.sql.
  - **Depends**: T010.
  - **Done**: They cover every Adhkar proof in contracts/adhkar-qiyam-sync.md and fail before 0016 exists.
- [x] T018 [P] Write supabase/tests/qiyam_account_isolation_test.sql, qiyam_operation_integrity_test.sql, qiyam_conflict_integrity_test.sql and qiyam_xp_integrity_test.sql.
  - **Depends**: T010.
  - **Done**: They cover every Qiyam proof in the sync contract.
- [x] T019 Create supabase/migrations/0016_adhkar_qiyam.sql. It contains:
  - the catalog seed for v1 (IDs, lists, positions and targets only);
  - the record, receipt and conflict tables;
  - `apply_adhkar_item_change_v1` and `apply_qiyam_night_change_v1`;
  - RLS and grants;
  - the award inserts.
  - **Depends**: T017, T018.
  - **Done**:
    - `supabase test db` is green, including the 0003–0015 tests.
    - There are no direct client writes and no anonymous execution.
    - Days more than 2 days ahead are rejected.

**Checkpoint 2**: Record the commands and results in verification.md.

---

## Phase 3: User Story 1 — Recite Morning and Evening Adhkar with a counter (P1, MVP)

**Goal**: A working, offline Adhkar screen with the time rules, counters, reset, set completion with XP, and the streak.

**Independent test**: Offline, complete every Morning item, restart, and confirm the counts, the completion and the single 15 XP award (quickstart scenarios 1–6).

- [x] T020 [P] [US1] Write tests in test/unit/features/adhkar/domain/adhkar_clock_test.dart.
  - **Depends**: T005.
  - **Done**: The vectors cover:
    - before Fajr, which belongs to the previous day's Evening;
    - Fajr to Maghrib, which is Morning;
    - Maghrib to midnight, then midnight to Fajr, both on the same day;
    - no schedule, which is `unrestricted` on the calendar day;
    - a DST shift;
    - the next boundary instant.
- [x] T021 [US1] Implement lib/features/adhkar/domain/adhkar_clock.dart.
  - **Depends**: T020.
  - **Done**: T020 passes, and the code is pure Dart.
- [x] T022 [P] [US1] Write tests in test/unit/features/adhkar/domain/adhkar_streak_test.dart.
  - **Depends**: T005.
  - **Done**: They cover:
    - 3 complete days, then today Morning only, which gives 3, and 4 once Evening is done;
    - a gap resets the count;
    - one list only does not count;
    - the walk caps at 3,650 days;
    - a catalog version change keeps past days valid.
- [x] T023 [US1] Implement lib/features/adhkar/domain/adhkar_streak.dart.
  - **Depends**: T022.
  - **Done**: T022 passes.
- [x] T024 [P] [US1] Write tests in test/unit/features/adhkar/data/drift_adhkar_repository_test.dart.
  - **Depends**: T016, T014.
  - **Done**: In one transaction:
    - an increment writes count + 1, the provisional set award on completion, and the outbox entry;
    - incrementing at the target is a no-op;
    - a reset writes 0 and leaves the award;
    - a rollback on failure leaves nothing behind;
    - reads are isolated per owner;
    - the streak query works.
- [x] T025 [US1] Implement lib/features/adhkar/application/adhkar_repository.dart and lib/core/data/local/adhkar_unit_of_work.dart, and lib/features/adhkar/data/drift_adhkar_repository.dart.
  - **Depends**: T024.
  - **Done**: T024 passes, and the outbox entity type is `adhkar_item`.
- [x] T026 [P] [US1] Write tests in test/unit/features/adhkar/application/adhkar_commands_test.dart.
  - **Depends**: T021, T025.
  - **Done**: They cover:
    - `dayChanged`;
    - `outsidePeriod(startsAt)`;
    - `atTarget`;
    - `incremented(setCompleted)`;
    - a reset allowed outside the period but rejected on another day;
    - `now` sampled once per command.
- [x] T027 [US1] Implement lib/features/adhkar/application/adhkar_times_port.dart and lib/features/adhkar/application/adhkar_commands.dart (`IncrementDhikr`, `ResetDhikr`).
  - **Depends**: T026.
  - **Done**: T026 passes.
- [x] T028 [US1] Implement lib/app/composition/prayer_adhkar_times_adapter.dart, which maps `PrayerDayBoundaries` to `AdhkarTimesPort`.
  - **Depends**: T012, T027.
  - **Done**: An adapter test in test/unit/app/composition/prayer_adhkar_times_adapter_test.dart passes for the available, setupRequired and unavailable cases.
- [x] T029 [P] [US1] Write tests in test/unit/features/adhkar/presentation/adhkar_cubit_test.dart.
  - **Depends**: T027.
  - **Done**: They cover:
    - the initial tab follows the period;
    - one boundary timer, plus a refresh on resume;
    - a celebration event on set completion, emitted once;
    - stale-owner results dropped;
    - pending, saved and failed feedback for each item.
- [x] T030 [US1] Implement lib/features/adhkar/presentation/adhkar_cubit.dart and adhkar_state.dart.
  - **Depends**: T029.
  - **Done**: T029 passes.
- [x] T031 [US1] Add the Adhkar strings to lib/app/l10n/app_ar.arb and app_en.arb, and create lib/app/l10n/adhkar_strings_adapter.dart.
  - **Depends**: T030.
  - **Done**: The strings cover:
    - the title and subtitle, and the Morning and Evening tabs;
    - progress "x / N" and the percentage, with plurals;
    - "Its time starts at {time}", and the setup prompt;
    - "Virtue and source", "Virtue:" and "Source:";
    - reset, target, "Tap to count ({n})", "Completed", and the semantic label "Count, {count} of {target}";
    - the streak, the celebration, and content unavailable.
- [x] T032 [P] [US1] Write widget tests in test/widget/features/adhkar/adhkar_screen_test.dart.
  - **Depends**: T031.
  - **Done**: They cover:
    - the prototype order (heading and switch, progress, cards);
    - the count button disables at the target and outside the period;
    - reset;
    - the virtue toggle;
    - English translation only in EN;
    - Amiri on the Arabic text;
    - the keyboard (Space/Enter);
    - semantics;
    - AR/EN, light/dark, 320 px and 200%, with no overflow.
- [x] T033 [US1] Implement lib/features/adhkar/presentation/adhkar_screen.dart, plus widgets/adhkar_header.dart, adhkar_progress_card.dart and dhikr_item_card.dart.
  - **Depends**: T032.
  - **Done**: T032 passes. It uses the shared components and theme colors, with no new UI kit.
- [x] T034 [US1] Register the Adhkar catalog, repository, commands, adapter and Cubit in lib/app/composition/configure_dependencies.dart, and preview owners in lib/app/composition/adhkar_preview_adapters.dart.
  - **Depends**: T028, T033.
  - **Done**: Debug preview counts locally with no upload, and the existing DI tests pass.
- [x] T035 [US1] Add the `/adhkar` route in lib/app/routing/app_router.dart and the `adhkar` section in lib/features/today/presentation/widgets/today_navigation_sidebar.dart and today_navigation_shell.dart, highlighting Track.
  - **Depends**: T034.
  - **Done**: A widget test in test/widget/app/app_router_test.dart checks:
    - the route opens with `go`;
    - there is no back arrow;
    - device back goes Home;
    - leaving an overlay first closes it.
- [x] T036 [US1] Write integration_test/adhkar_qiyam_flow_test.dart (Adhkar part): a Morning journey with a fake clock across Fajr and Maghrib, restart persistence, and one award.
  - **Depends**: T035.
  - **Done**: It passes on Windows locally (`flutter test integration_test/adhkar_qiyam_flow_test.dart -d windows`).

**Checkpoint US1**: Quickstart scenarios 1–6 pass, and the results are recorded in verification.md.

---

## Phase 4: User Story 2 — Log tonight's Qiyam (P1)

**Goal**: The Qiyam screen with the last third of the night, Yes/No, the details, the supplications, and a single 30 XP award.

**Independent test**: With a saved location, mark Yes with 4 rak'ahs and Witr, then restart. The record and the award persist, and the last third equals the Prayer screen's value (quickstart scenarios 7–9).

- [x] T037 [P] [US2] Write tests in test/unit/features/qiyam/domain/qiyam_night_test.dart.
  - **Depends**: T001.
  - **Done**: The vectors cover:
    - 03:00 and 10:00 Thursday, which give Wednesday's night;
    - 20:00 Thursday, which gives Thursday's night;
    - the no-schedule rule at 11:59 and 12:00;
    - the last third equal to `PrayerScheduleProjection.from(today: D, tomorrow: D+1)`;
    - a DST shift.
- [x] T038 [US2] Implement lib/features/qiyam/domain/qiyam_night.dart and qiyam_night_record.dart (with validation).
  - **Depends**: T037.
  - **Done**: T037 passes. The validation enforces "rakahs: null when performed is false; otherwise one of 2, 4, 8, 11", `HH:mm` times, "note ≤ 500 characters", and cleared details for "No".
- [x] T039 [P] [US2] Write tests in test/unit/features/qiyam/data/drift_qiyam_repository_test.dart.
  - **Depends**: T016, T014.
  - **Done**: In one transaction:
    - an upsert, plus the provisional award on the first `performed = true`, plus the outbox entry;
    - Yes → No → Yes keeps one award;
    - a rollback on failure;
    - owner isolation.
- [x] T040 [US2] Implement lib/features/qiyam/application/qiyam_repository.dart, lib/core/data/local/qiyam_unit_of_work.dart and lib/features/qiyam/data/drift_qiyam_repository.dart.
  - **Depends**: T039.
  - **Done**: T039 passes, and the outbox entity type is `qiyam_night`.
- [x] T041 [P] [US2] Write tests in test/unit/features/qiyam/application/save_qiyam_night_test.dart.
  - **Depends**: T038, T040.
  - **Done**: They cover:
    - `nightChanged`;
    - each validation failure;
    - `saved(firstPerformed)`;
    - no command path that writes a previous night.
- [x] T042 [US2] Implement lib/features/qiyam/application/qiyam_night_port.dart and lib/features/qiyam/application/save_qiyam_night.dart.
  - **Depends**: T041.
  - **Done**: T041 passes.
- [x] T043 [US2] Implement lib/app/composition/prayer_qiyam_night_adapter.dart, which maps `PrayerDayBoundaries` to `QiyamNightPort`, with the last third computed from the shared projection.
  - **Depends**: T012, T042.
  - **Done**: The adapter test in test/unit/app/composition/prayer_qiyam_night_adapter_test.dart shows the same last third as the Prayer screen (SC-005).
- [x] T044 [P] [US2] Write tests in test/unit/features/qiyam/presentation/qiyam_cubit_test.dart.
  - **Depends**: T042.
  - **Done**: They cover:
    - the defaults (4 rak'ahs, Witr on) on Yes;
    - the note debounced by 400 ms and flushed on leaving;
    - a refresh at Maghrib and on resume;
    - the stale-owner guard;
    - a celebration only on the first Yes.
- [x] T045 [US2] Implement lib/features/qiyam/presentation/qiyam_cubit.dart and qiyam_state.dart.
  - **Depends**: T044.
  - **Done**: T044 passes.
- [x] T046 [US2] Add the Qiyam strings to lib/app/l10n/app_ar.arb and app_en.arb, and create lib/app/l10n/qiyam_strings_adapter.dart.
  - **Depends**: T045.
  - **Done**: The strings cover:
    - the title and subtitle, the last third, and the unavailable message with its setup link;
    - "Did you pray Qiyam tonight?", the best-time note, and "Yes (+30 XP)" / "No";
    - the rak'ahs label with plurals, start and end, Witr, and the notes placeholder and counter;
    - the supplications title.

    None of them uses the word "missed".
- [x] T047 [P] [US2] Write widget tests in test/widget/features/qiyam/qiyam_screen_test.dart.
  - **Depends**: T046.
  - **Done**: They cover:
    - the prototype order (heading, tracker and form, supplications);
    - the Yes form appearing;
    - the rak'ah chips;
    - times that cross midnight;
    - the 500-character counter;
    - read-only when the night is not current;
    - the supplications in Amiri with their sources;
    - AR/EN, light/dark, 320 px and 200%;
    - the keyboard and semantics.
- [x] T048 [US2] Implement lib/features/qiyam/presentation/qiyam_screen.dart, plus widgets/qiyam_header.dart, qiyam_tracker_card.dart and qiyam_supplications_card.dart.
  - **Depends**: T047.
  - **Done**: T047 passes.
- [x] T049 [US2] Register the Qiyam services and Cubit in lib/app/composition/configure_dependencies.dart and lib/app/composition/qiyam_preview_adapters.dart. Add the `/qiyam` route and the `qiyam` shell section, and activate the Qiyam entry points (Track tile, Home hub, sidebar). Add the approved supplications s1 and s2 to `qiyam_supplications` in assets/religious/adhkar_catalog_v1.json, extracted by script from content-sources.md (byte for byte).
  - **Depends**: T043, T048, T035.
  - **Done**: The router and shell tests in test/widget/app/app_router_test.dart are extended and pass, and preview stays local-only.
- [x] T050 [US2] Extend integration_test/adhkar_qiyam_flow_test.dart with Qiyam:
  - a fake clock at 03:00 Thursday, then 10:00, checking that the record is on Wednesday night and editable, and read-only after Maghrib;
  - Yes → No → Yes giving one award;
  - restart persistence.
  - **Depends**: T049.
  - **Done**: It passes on Windows locally.

**Checkpoint US2**: Quickstart scenarios 7–9 pass, and the results are recorded.

---

## Phase 5: User Story 3 — Qiyam streak and history (P2)

**Goal**: A Qiyam streak and a paged, read-only history.

**Independent test**: Seed three consecutive performed nights to get a streak of 3 and three history entries. Remove the middle night and the streak resets.

- [x] T051 [P] [US3] Write tests in test/unit/features/qiyam/domain/qiyam_streak_test.dart.
  - **Depends**: T038.
  - **Done**: They cover:
    - consecutive nights;
    - a gap;
    - an explicit No breaking the streak;
    - an unanswered current night not breaking it;
    - the 3,650 cap;
    - a time-zone change.
- [x] T052 [US3] Implement lib/features/qiyam/domain/qiyam_streak.dart, and the streak and paged-history queries (30 per page) in drift_qiyam_repository.dart.
  - **Depends**: T051, T040.
  - **Done**: T051 passes, and the repository tests are extended for paging.
- [x] T053 [US3] Extend QiyamCubit with the streak and paged history.
  - **Depends**: T052, T045.
  - **Done**: The Cubit tests are extended and pass.
- [x] T054 [US3] Add the strings for "Qiyam streak", "Prayed · {n} rak'ahs · Witr", "Did not pray", "Not recorded" and "Load more" to both ARB files, and add lib/features/qiyam/presentation/widgets/qiyam_history_section.dart and the streak chip.
  - **Depends**: T053.
  - **Done**:
    - The widget tests in test/widget/features/qiyam/qiyam_history_test.dart pass: newest first, read-only, "missed" never shown, and a side column at ≥ 1024 px.
    - The streak stays separate from the Habit and Prayer streaks.

**Checkpoint US3**: SC-007 is recorded for the Qiyam streak.

---

## Phase 6: User Story 4 — Home, Track and cross-device sync (P2)

**Goal**: Live Home and Track entries, plus account sync with receipts, conflicts and canonical awards.

**Independent test**:
1. Complete Morning offline on device A, then reconnect.
2. Device B shows the same completion and a single award.
3. Qiyam marked on B appears on A (quickstart scenarios 10–13).

### Home and Track

- [x] T055 [P] [US4] Write tests in test/unit/features/today/data/adhkar_qiyam_today_adapter_test.dart.
  - **Depends**: T030, T045.
  - **Done**: They cover Morning x/N, Evening x/N, the period, tonight's Qiyam state and both streaks, through application APIs only.
- [x] T056 [US4] Implement lib/features/today/application/today_adhkar_qiyam_port.dart, lib/features/today/domain/today_adhkar_qiyam_reference.dart and lib/features/today/data/adhkar_qiyam_today_adapter.dart.
  - **Depends**: T055.
  - **Done**: T055 passes.
- [x] T057 [US4] Replace the sample Adhkar/Qiyam values in lib/features/today/presentation/widgets/today_focus_reflection_card.dart and today_progress_hero.dart with the port's values. Activate the Adhkar and Qiyam tiles in prayer_track_hub.dart and today_quick_hubs.dart.
  - **Depends**: T056, T049.
  - **Done**:
    - The widget tests in test/widget/features/today/ are updated: the values equal the screens, and tapping opens the real routes.
    - Quran and Focus stay "coming soon".
    - Any remaining sample value keeps its provenance label.
- [x] T058 [US4] Update the Home dashboard composition in lib/features/today/presentation/today_dashboard_view.dart and its Cubit wiring to watch `TodayAdhkarQiyamPort`, with the independent source-recovery pattern.
  - **Depends**: T057.
  - **Done**: A slow or failed Adhkar source never blocks the other Home sections. The existing Today tests pass.

### Sync

- [x] T059 [P] [US4] Write tests in test/unit/features/adhkar/data/supabase_adhkar_sync_adapter_test.dart.
  - **Depends**: T019, T025.
  - **Done**: They cover:
    - the typed RPC argument mapping;
    - the outcome mapping (receipt, active, retained, conflictId, canonicalAward);
    - local finalization in one transaction before ACK;
    - a failure leaving the operation pending;
    - an old response not overwriting a newer local version.
- [x] T060 [US4] Implement lib/features/adhkar/data/supabase_adhkar_sync_adapter.dart and register `adhkar_item` in lib/core/data/sync/entity_dispatch_router.dart through composition.
  - **Depends**: T059.
  - **Done**: T059 passes.
- [x] T061 [P] [US4] Write tests in test/unit/features/qiyam/data/supabase_qiyam_sync_adapter_test.dart, the same cases for `qiyam_night`.
  - **Depends**: T019, T040.
  - **Done**: The tests fail before T062.
- [x] T062 [US4] Implement lib/features/qiyam/data/supabase_qiyam_sync_adapter.dart and register `qiyam_night`.
  - **Depends**: T061.
  - **Done**: T061 passes.
- [x] T063 [P] [US4] Write tests in test/unit/features/adhkar/data/adhkar_inbound_synchronizer_test.dart and test/unit/features/qiyam/data/qiyam_inbound_synchronizer_test.dart.
  - **Depends**: T060, T062.
  - **Done**: They cover:
    - keyset pages;
    - a failed page retried without advancing;
    - award settlement by (source, sourceId), replacing the provisional award once;
    - conflicts upserted by stable ID;
    - the owner validated.
- [x] T064 [US4] Implement lib/features/adhkar/data/adhkar_inbound_synchronizer.dart, lib/features/adhkar/data/supabase_adhkar_reader.dart, lib/features/qiyam/data/qiyam_inbound_synchronizer.dart and lib/features/qiyam/data/supabase_qiyam_reader.dart, wired into the existing synchronization runner.
  - **Depends**: T063.
  - **Done**: T063 passes, and the catalog table is read once per version.
- [x] T065 [US4] Add the read-only "Sync differences" list: lib/features/adhkar/presentation/adhkar_conflicts_view.dart and lib/features/qiyam/presentation/qiyam_conflicts_view.dart, with their strings.
  - **Depends**: T064.
  - **Done**: The widget tests in test/widget/features/adhkar/adhkar_conflicts_test.dart and test/widget/features/qiyam/qiyam_conflicts_test.dart show both versions, with no resolve action and no foreign-owner data.
- [x] T066 [US4] Write integration_test/adhkar_qiyam_offline_sync_test.dart: two encrypted stores against the local Supabase stack (staging when hosted), run-tagged operation IDs and random past days. It covers:
  - different items completing the set, with one award;
  - the same item on both stores, giving one visible conflict;
  - Yes → No → Yes, with one award;
  - a lost ACK and restart;
  - a duplicate inbound record;
  - owner B isolated.
  - **Depends**: T064, T065.
  - **Done**: It passes on Windows against the local stack.
- [x] T067 [US4] Write integration_test/adhkar_qiyam_localized_route_test.dart:
  - Track to Adhkar and Qiyam, and Home to both, in AR/EN with touch and keyboard;
  - no back arrow, and device back goes Home;
  - the Home values equal the screens.
  - **Depends**: T058.
  - **Done**: It passes on Windows.

**Checkpoint US4**: Quickstart scenarios 10–13 pass, and the results are recorded.

---

## Phase 6b: Catalog revision and User Story 5 — My Adhkar (P2)

Added on 2026-11-15 after the owner's content review (spec.md, Session 2026-11-15; research R13, R14). Task IDs continue after T079 so the existing IDs stay stable.

### Catalog revision (owner decisions D3, D4, D6 and the Hisn al-Muslim additions)

- [x] T080 Revise the catalog model and parser in lib/features/adhkar/domain/adhkar_catalog.dart to the Arabic-only shape in data-model.md.
  - Remove `translation_en`, `virtue_en`, `reference_en` and `source_en`; make `virtue_ar` nullable.
  - Add `kind` (`dhikr` or `quran`); for `quran` require `surah`, `ayah_from` and `ayah_to`, and allow `preface_ar`. Add the top-level `attribution`.
  - Update every fixture and test that builds a catalog (adhkar_commands_test.dart, adhkar_qiyam_supplications_adapter_test.dart and the catalog tests), with placeholder text only.
  - Update the item card: no English translation line; a Quran item shows its preface apart from the verses, the verses in the Quran font (T081), and its surah and verse numbers.
  - **Depends**: none (code only).
  - **Done**: The catalog, command, adapter and Adhkar widget tests pass; no real religious text is added.
- [x] T081 Bundle the KFGQPC Uthmanic Hafs font at assets/fonts/kfgqpc_hafs/, taken unmodified from a Quran Foundation documented font URL, register the family in pubspec.yaml, add the Quran Foundation credit to the app's credits, and record the source URL, the SHA-256 and the credit wording in verification.md. If the only documented file is a web format Flutter cannot load (for example WOFF2), stop and report it instead of converting the file: converting is a modification the owner must approve.
  - **Depends**: none (owner decision 2026-11-16).
  - **Done**: A widget test renders a placeholder Quran item with the family, and the attribution shows in the app's credits.
- [x] T082 The agent adds review entries to content-sources.md for every item the owner approves on the second review page: the Hisn al-Muslim additions, the Quran items (the KFGQPC QPC Hafs text verbatim, attribution, counts, placement, preface and basmala decisions) and the full s2 text. The owner confirms the final list.
  - **Depends**: the owner's second review.
  - **Done**: Every shipped item has an entry marked approved by the owner, with its final ID, list, position and target.
- **T006 note (2026-11-15):** T006 now also depends on T080 and T082, and builds the asset in the revised shape.

### User Story 5 — My Adhkar

**Goal**: A third Adhkar tab, «أذكاري», where the user builds a personal collection over time: named groups holding entries of text and an optional source, an entry possibly in several groups, synced, with no counter, no XP and no streak.

**Independent test**: Spec Story 5: offline, create a group, save a supplication with a source link, restart, edit it, add it to a second group, delete the first group; then create a group and an entry on device A and confirm them on device B.

**Reshape (owner decisions, 2026-11-16).** T083–T090 were built for the first shape (target, note, daily counter). The owner then chose groups, and a collection with no counter: each entry is the text and an optional free-text source, and a link is never opened. T100–T102 reshape the same local core (schema v11 is unreleased, so it changes in place, with no v12): they add groups and remove the target, the note, the counter, the count table, the count IDs, the clamp, the day guard and the locked state. T091–T099 follow the new shape.

- [x] T083 [P] [US5] Write tests in test/unit/features/adhkar/domain/my_dhikr_test.dart: text trimmed and 1–1000 characters, target 1–1000 (default 1), note ≤ 300, the 100-item limit, the target-lowering clamp, and that a deleted item stays deleted.
  - **Depends**: none.
  - **Done**: They fail before T084.
- [x] T084 [US5] Implement lib/features/adhkar/domain/my_dhikr.dart (the item, its draft validation and the count rules).
  - **Depends**: T083.
  - **Done**: T083 passes; the file imports domain code only.
- [x] T085 [P] [US5] Add `MyAdhkarIdentityPort` in lib/features/adhkar/application/ and its implementation in lib/features/adhkar/data/uuid_my_adhkar_identity.dart: UUIDv4 item IDs and `UUIDv5(NS009, 'my-adhkar/' + itemId + '/' + day)` count IDs. Extend test/fixtures/adhkar_qiyam/identity_vectors.json and add test/unit/features/adhkar/data/my_adhkar_identity_test.dart.
  - **Depends**: none.
  - **Done**: The count-ID vectors match the SQL helper added in T091.
- [x] T086 [US5] Local schema v11 in lib/core/data/local/foundation_database.dart: the `my_adhkar_items` and `my_adhkar_counts` tables and indexes from data-model.md, an additive v10→v11 migration, `kFoundationSchemaVersion = 11`, regenerated code, and migration tests (fresh v11, v10→v11 keeping Adhkar and Qiyam rows, every older path, and the failure/recovery case).
  - **Depends**: none.
  - **Done**: The migration tests pass, and AGENTS.md's schema number is updated in the same change.
- [x] T087 [P] [US5] Write tests in test/unit/features/adhkar/data/drift_my_adhkar_repository_test.dart: add, edit, delete, increment and reset; the limit; the clamp written in the same transaction as the edit; a deleted item hidden from `watchItems`; outbox entries of type `my_adhkar_item` and `my_adhkar_count`; owner isolation; and no `xp_awards` row ever written.
  - **Depends**: T084, T086.
  - **Done**: They fail before T088.
- [x] T088 [US5] Implement lib/features/adhkar/application/my_adhkar_repository.dart and lib/features/adhkar/data/drift_my_adhkar_repository.dart.
  - **Depends**: T087.
  - **Done**: T087 passes.
- [x] T089 [P] [US5] Write tests in test/unit/features/adhkar/application/my_adhkar_commands_test.dart: `AddMyDhikr`, `EditMyDhikr`, `DeleteMyDhikr`, `IncrementMyDhikr` and `ResetMyDhikr`, covering the day guard, the locked state, `itemDeleted`, `limitReached`, validation failures, and that no command touches the XP ledger.
  - **Depends**: T084, T085.
  - **Done**: They fail before T090.
- [x] T090 [US5] Implement lib/features/adhkar/application/my_adhkar_commands.dart.
  - **Depends**: T089, T088.
  - **Done**: T089 passes, and test/architecture/adhkar_qiyam_boundaries_test.dart gains a rule (with a negative control) that no `my_adhkar_*` file imports lib/features/xp/.
- [x] T100 [US5] Reshape the domain and identity, test-first (spec FR-022…FR-029, data-model.md "My Adhkar"):
  - In lib/features/adhkar/domain/my_dhikr.dart and its test: the entry has `text` (1–2000 code points after trimming) and `source` (optional, ≤ 500 code points after trimming, blank stored as null) and a non-empty `groupIds`; add `MyAdhkarGroup` (name 1–60 code points after trimming, tombstone final); limits 1000 live entries and 100 live groups.
  - Remove `target`, `note`, the count rules and the clamp. Count every length with `runes.length`.
  - `MyAdhkarIdentityPort`: `newItemId()` and `newGroupId()` (UUIDv4). Remove `countRecordId` and the `my-adhkar/` vectors from test/fixtures/adhkar_qiyam/identity_vectors.json and my_adhkar_identity_test.dart.
  - **Depends**: T084, T085.
  - **Done**: The new tests fail first, then pass; a supplementary-plane character counts as one; no count code is left in the domain.
- [x] T101 [US5] Reshape storage in schema v11, test-first: in lib/core/data/local/foundation_database.dart, `my_adhkar_items` gets `source` and loses `target` and `note`; drop `my_adhkar_counts`; add `my_adhkar_groups` and `my_adhkar_item_groups` with their indexes (data-model.md); regenerate. Update the v10→v11 migration test and test/unit/features/adhkar/data/drift_my_adhkar_repository_test.dart:
  - group create, rename and delete; the delete cascade (an entry only in that group is deleted, an entry also in a live group stays); the group delete appends exactly ONE outbox entry;
  - membership written with the entry in one transaction, `added_at` kept for a kept group;
  - `watchGroups` (with entry counts) and `watchGroupItems` order;
  - the edit guarded on `deleted_at IS NULL` and the prior `updated_at`;
  - outbox types `my_adhkar_group` and `my_adhkar_item` only; owner isolation; no `xp_awards` row.
  - **Depends**: T086, T088, T100.
  - **Done**: The tests pass, and nothing references `my_adhkar_counts` or `my_adhkar_count`.
- [x] T102 [US5] Reshape the commands, test-first: my_adhkar_commands.dart and its tests get `CreateMyAdhkarGroup`, `RenameMyAdhkarGroup`, `DeleteMyAdhkarGroup` and `previewDeleteMyAdhkarGroup`, and `AddMyDhikr`, `EditMyDhikr(owner, itemId, draft)` and `DeleteMyDhikr` with the group set (`groupDeleted`, `groupLimitReached`, `limitReached`, `itemDeleted`, empty set rejected). Remove `IncrementMyDhikr`, `ResetMyDhikr`, the day guard, the locked state and the dependency on the Adhkar times port. Edit reads, checks and writes in one transaction; delete uses a monotonic `updated_at`.
  - **Depends**: T090, T101.
  - **Done**: The tests pass, and the architecture no-XP rule still passes.
- [x] T091 [US5] Write supabase/migrations/0017_my_adhkar.sql (`my_adhkar_groups`, `my_adhkar_items`, `my_adhkar_item_groups`, receipts, conflicts, `apply_my_adhkar_group_change_v1`, `apply_my_adhkar_item_change_v1` with `p_group_ids`, the server-side group delete cascade, RLS and grants, per contracts/adhkar-qiyam-sync.md; no count table or RPC) and pgTAP tests supabase/tests/my_adhkar_account_isolation_test.sql, my_adhkar_operation_integrity_test.sql and my_adhkar_conflict_integrity_test.sql.
  - **Depends**: T100.
  - **Done**: `supabase test db` passes on the local stack, including both limits, code-point lengths, the final delete against older and newer edits, the group delete cascade, `group_deleted`, `group_missing`, and zero `xp_awards` rows. Nothing is pushed to staging.
- [x] T092 [P] [US5] Write tests in test/unit/features/adhkar/data/supabase_my_adhkar_sync_adapter_test.dart for the two entity types (group, then entry with `group_ids`): argument mapping, outcome mapping, finalization in one transaction before ACK, `group_deleted` applied as the entry's deletion, `group_missing` left pending, failures left pending, and an old response never overwriting newer local work.
  - **Depends**: T091, T101.
  - **Done**: They fail before T093.
- [x] T093 [US5] Implement lib/features/adhkar/data/supabase_my_adhkar_gateway.dart and supabase_my_adhkar_sync_adapter.dart, and register `my_adhkar_group` and `my_adhkar_item` in `EntityDispatchRouter` through composition, keeping the outbox's chronological order across both types (no groups-first reordering).
  - **Depends**: T092.
  - **Done**: T092 passes; the existing router tests are unchanged.
- [x] T094 [P] [US5] Write tests in test/unit/features/adhkar/data/my_adhkar_inbound_test.dart: keyset pages for groups, entries (with their group sets) and conflicts; a server group-delete cascade applied locally; a failed page retried without advancing; the owner validated; tombstones applied; pending local work kept.
  - **Depends**: T093.
  - **Done**: They fail before T095.
- [x] T095 [US5] Implement the My Adhkar reader and reconciler, and run them inside `AdhkarSyncService` / `AdhkarInboundSynchronizer`, so a failure stays isolated as in Phase 6.
  - **Depends**: T094.
  - **Done**: T094 passes, and the Phase 6 isolation test still passes.
- [x] T096 [P] [US5] Write tests in test/unit/features/adhkar/presentation/my_adhkar_cubit_test.dart, then implement `MyAdhkarCubit`, composed beside `AdhkarCubit`: load the groups, open and close a group, create, rename and delete a group (with the preview count), add, edit (including the group set) and delete an entry, the limits, owner change, and no celebration or streak change. It works the same when the Prayer schedule is unavailable.
  - **Depends**: T102.
  - **Done**: The tests pass.
- [x] T097 [US5] Build the My Adhkar tab per contracts/adhkar-qiyam-ui.md (third segment, header note, group list, create/rename sheet, in-page group delete confirmation with the count, opened group with its back control, empty states, entry cards with selectable text and source and their other groups, overflow menu with Edit, Copy and Delete, the two-field add/edit sheet with the group chips, in-page delete confirmation; no counter and no locked state), with the strings added to app_ar.arb and app_en.arb line by line. Write test/widget/features/adhkar/my_adhkar_tab_test.dart: AR/EN, light/dark, 320 px, 200% text scale, mixed-direction text, a link source shown as plain text, an entry with no source, the 1000-entry and 100-group states, device back from an opened group, and the validation errors.
  - **Depends**: T096.
  - **Done**: The widget tests pass with no overflow, and no URL-launching package is added.
- [x] T098 [US5] Add My Adhkar conflicts (groups and entries) to the Adhkar "Sync differences" list (both versions, long text shortened, no resolve action), with a widget test in test/widget/features/adhkar/adhkar_conflicts_test.dart.
  - **Depends**: T095.
  - **Done**: The test shows both versions and no foreign-owner data.
- [x] T099 [US5] Extend integration_test/adhkar_qiyam_offline_sync_test.dart with My Adhkar on the local stack: both devices create groups and add entries, one entry in two groups, a group deleted on A while B adds to it offline (B's version kept as a conflict, an entry in another group kept), a concurrent edit gives one visible conflict, a delete stays final against a newer edit, owner B is isolated, and no `xp_awards` row is written.
  - **Depends**: T093, T095.
  - **Done**: It passes on Windows against the local stack, run twice without a reset.

**Checkpoint US5**: Spec Story 5's scenarios pass, and the results are recorded in verification.md.

---

## Phase 6c: Adhkar section redesign (owner, 2026-11-17)

**Goal**: The whole Adhkar section matches the Claude Design canvas the owner approved on 2026-11-17 (contracts/adhkar-qiyam-ui.md, "Adhkar screen (approved design, 2026-11-17)"): Morning and Evening are read one item per page in a reader with auto-advance, and the Adhkar page, «أذكاري» and the sync differences take the new look. Behavior, storage, sync and XP are unchanged.

**Independent test**: On a phone, open Adhkar, start Morning, count an item to its target and see the auto slide, swipe back, jump from the list sheet, close the reader; open «أذكاري», create a group, add, copy and delete an entry; open the sync differences page.

- [x] T103 [US1] Build the Adhkar page in the new design: the title and tabs, the Morning/Evening progress card with ring, the time-window line, the streak row, the main button («ابدأ», «متابعة من الذكر n», the finished state with «قراءة القائمة مرة أخرى»), the setup notice, and the sync differences row. Widget tests: AR/EN, light/dark, 320 px, 200% text, each state.
  - **Depends**: T035.
  - **Done**: The tests pass with no overflow; the old list of item cards is no longer shown.
- [x] T104 [US1] Build the reader inside `/adhkar` (contract item 2): one item per page, the count button with its ring, the done bar and the auto slide (about 600 ms hold), swipe both ways, the list sheet and jump, the reset dialog, the locked banners, the completion state, the error state, the wide layout with previous/next buttons and Space/Enter/arrow keys, and device back. It uses the existing `AdhkarCubit` commands; no new storage. Widget tests for each interaction, both directions, and no second award.
  - **Depends**: T103.
  - **Done**: The tests pass, `dhikr_item_card.dart` is removed if nothing else uses it, and the existing Adhkar cubit tests still pass.
- [x] T105 [US5] Restyle «أذكاري» to the canvas (group list, empty and limit states, row and entry menus, opened group, sheets and dialogs, in-place delete confirmations, copy toast) without changing its behavior; leaving the tab closes an open group. Update test/widget/features/adhkar/my_adhkar_tab_test.dart.
  - **Depends**: T103.
  - **Done**: The tests pass, including device back order and 320 px at 200% text.
- [x] T106 [US4] Turn the sync differences into the read-only page inside `/adhkar` from the canvas (stacked on phone, side by side on desktop, text cut to three lines, «محذوف», the footer), opened from the row on the Adhkar page. Update test/widget/features/adhkar/adhkar_conflicts_test.dart and the router test for device back.
  - **Depends**: T103.
  - **Done**: The tests pass and show no foreign-owner data.

- [x] T107 [US2] [US3] Rebuild the Qiyam screen in the approved design (contracts/adhkar-qiyam-ui.md, "Qiyam screen (approved design, 2026-11-18)"), from the shared components in lib/app/widgets/: the heading chips, the tonight tracker and its answered switch, the one-time points badge, the autosaved details form, the collapsible supplications, the paged history with read-only night details, the states, and the sync differences page. Behavior, storage, sync and XP are unchanged. Widget tests: AR/EN, light/dark, 320 px at 200% text, each state, one award across Yes → No → Yes, and device back.
  - **Depends**: T049, T106.
  - **Done**: The tests pass with no overflow, and the old Qiyam widgets that nothing uses are removed.

**Checkpoint 6c**: `flutter analyze` and the full `flutter test` pass, and the owner checks the section on the phone (CPH2481) and on Windows.

---

## Phase 7: Polish, verification and handoff

- [x] T068 [P] Add test/architecture/adhkar_qiyam_boundaries_test.dart.
  - **Depends**: T064.
  - **Done**:
    - Adhkar and Qiyam do not import each other.
    - Neither imports Prayer data; they use only `PrayerDayBoundaries` through composition.
    - Today reaches them only through application ports.
    - The client secret scan still passes.
- [x] T069 [P] Add the three integration files to the `prayer` suite in .github/scripts/run-android-integration.sh and to the `prayer` group in .github/scripts/run-ios-integration-group.sh as suites `adhkar-qiyam-flow`, `adhkar-qiyam-offline-sync` and `adhkar-qiyam-localized-route`.
  - **Depends**: T066, T067.
  - **Done**: The tests in .github/scripts/tests/test_mobile_runners.py and test_ios_groups_and_pub_get.py are extended and pass.
- [x] T070 Add the three files to the Linux, Windows and macOS lists in .github/workflows/foundation-ci.yml, and add `'specs/009-adhkar-qiyam/**'` to the `pull_request` paths.
  - **Depends**: T069.
  - **Done**: The CI script tests pass, and the five-target gate still depends on every job.
- [x] T071 [P] Run the format, analyze and full `flutter test` commands and `supabase test db`, and record the exact commands and results in verification.md.
  - **Depends**: T068, T070.
  - **Done**: All green. Any failure is fixed at its specific cause.
- [x] T072 [P] Dependency and manifest audit.
  - **Depends**: T071.
  - **Done**: No new package, no notification permission or plugin (FR-015), and only Amiri added under assets. Recorded in verification.md.
- [x] T073 The owner reviews and approves specs/009-adhkar-qiyam/content-sources.md, and T006 is re-checked against it.
  - **Depends**: T002, T006.
  - **Done**:
    - Every shipped item is marked approved by the product owner.
    - Rejected items are absent from the asset.
    - The decisions on m9, "Hasbiyallah ×7", the translations and Ayat al-Kursi/Mu'awwidhat are recorded.
    - SC-002 is recorded.
- [ ] T074 Measure SC-001 on a named phone and desktop: the count latency and the 30-second Qiyam journey.
  - **Depends**: T071.
  - **Done**: The real device, OS, build and timings are recorded, with no estimates.
- [ ] T075 The product owner checks the screens on the phone (CPH2481) and on Windows: AR/EN, light/dark, tashkeel rendering, and prototype order.
  - **Depends**: T074.
  - **Done**: The owner's reported result is recorded for SC-006. Nothing is claimed without it.
- [x] T076 With the owner's approval, push 0016 and 0017 to the isolated staging project (never production), then run the hosted offline-sync entry through CI.
  - **Depends**: T070, T073.
  - **Done**: The staging migration is recorded, and the hosted result is recorded with the run URL.
- [x] T077 Update the status table in AGENTS.md for 009 and finalize verification.md, quickstart.md and the task states.
  - **Depends**: T075, T076.
  - **Done**: Every SC links to its evidence. Any unrun item stays unchecked. This is done before the final gate run, so the closing docs do not restart CI.
- [ ] T078 Run the full PR-to-develop gate on the final head, and record the run URL and SHA in verification.md.
  - **Depends**: T077.
  - **Done**: Every job is green. Same-head reruns are made only for infrastructure failures, after reading the logs.
- [x] T079 Audit tasks.md against FR-001…FR-021 and SC-001…SC-008, and report the closure recommendation.
  - **Depends**: T078.
  - **Done**: The report names any remaining blocker. Merging happens only on the owner's go.

---

## Dependencies and execution order

```text
Phase 1 (T001–T003)
  └─> Phase 2 (T004–T019): catalog, identity, Prayer port, XP, v10, 0016
        ├─> US1 (T020–T036)  MVP
        ├─> US2 (T037–T050)  needs T035 for the shell section
        │     └─> US3 (T051–T054)
        └─> US4 (T055–T067)  needs US1 + US2 (adapters and Cubits) and T019
              └─> Phase 6b (T080–T102): catalog revision, then US5 My Adhkar
                    └─> Phase 7 (T068–T079)
```

- US1 and US2 are independent after Phase 2, except that T049 reuses the shell work from T035.
- US3 depends only on US2.
- US4 integrates every story.
- Phase 6b: T080–T082 revise the catalog and gate T006; US5 (T083–T102) needs US1's Adhkar screen and Phase 6's sync service, and is otherwise independent.

## Parallel opportunities

- **Phase 1:** T002 and T003 run in parallel after T001.
- **Phase 2:**
  - T004, T009, T011, T013 and T015 run in parallel, because they touch separate files.
  - T017 and T018 run in parallel.
  - T019 waits for both.
- **US1:** T020, T022 and T024 run in parallel (domain versus data). Then T026, then T029.
- **US2:** T037 and T039 run in parallel. Then T041, then T044.
- **US4:** T055, T059 and T061 run in parallel. Then T063.
- **Phase 6b:** T080, T081 and T082 run in parallel. In US5, T083, T085 and T086 run in parallel, then T087 and T089, then T091, then T092.
- **Phase 7:** T068 and T069 run in parallel. Then T071 and T072 run in parallel.

## Implementation strategy

1. **MVP:** Phases 1–2 plus US1. That gives offline Adhkar with times, counters, XP and the streak. It can be demonstrated on its own, and the owner's content review (T073) can run alongside the code work.
2. **Add US2,** offline Qiyam logging. Together with US1, that covers the owner's chosen P1 scope.
3. **Add US3** for the streak and history, then **US4** for Home, Track and sync.
4. **Close:** run the Phase 7 gates. The content approval, staging push and merge each need the owner's explicit go.

## Counts

- **Setup:** 3 tasks.
- **Foundational:** 16.
- **US1:** 17.
- **US2:** 14.
- **US3:** 4.
- **US4:** 13.
- **Catalog revision:** 3.
- **US5:** 20.
- **Polish:** 12.

The total is 102 tasks.
