# Dashboard / Today 006 — implementation evidence

**Baseline checked:** 2026-10-22 on `namaa/006-today-dashboard` at `033da906f02da55661798bfc6fb1990783d6e2f1`. This is the existing code baseline, not a commit containing 006 implementation. Phase 1 only prepares test fixtures and this ledger; no runtime behavior or acceptance result is claimed.

## Boundaries

- Tasks 003 owns Task records, ordering, completion and overdue rules. Habits 004 owns schedules, day completions and streaks. The shared XP ledger owns awards. Today will read those authorities and call their commands; it must not add a competing writer, history, or sync mechanism.
- Local preview keeps two existing identities: Tasks, Mind Maps and XP use `kTasksPreviewAccountId` (`00000000-0000-4000-8000-000000000003`); Habits uses `kHabitsPreviewAccountId` (`00000000-0000-4000-8000-000000000004`). They are intentionally distinct and must not be merged or migrated. Real account mode binds the three owners to the same resolved account. Unknown/signed-out real sessions display no prior owner's data.
- No production records are seeded by Phase 1. `test/support/today_fixtures.dart` creates in-memory domain values and controlled streams for tests only. Existing preview and encrypted database contents are not changed.

## Functional requirement ledger

Every requirement is **unverified** until an executed check is recorded with its result and evidence. Planned proof is from the specification and quickstart, not an executed outcome.

| ID | Planned proof | Status |
|---|---|---|
| FR-001 | Direct preview root, owner areas and preferences without sign-in | Unverified |
| FR-002 | Scheduled-today Task fixture including completed rows and exclusions | Unverified |
| FR-003 | Owner Habit due/retained-completion and streak comparison | Unverified |
| FR-004 | Independent ratios, rounding, empty and unavailable states | Unverified |
| FR-005 | Actual award ledger at local-day boundaries; deleted/reopened Tasks | Unverified |
| FR-006 | Task completion/reopen owner command, map link and single award | Unverified |
| FR-007 | Habit current-day complete/undo and stale-day rejection | Unverified |
| FR-008 | Existing owner creation flows, navigation and read-only opening | Unverified |
| FR-009 | Timed/untimed agenda, equal-time order and saved duration | Unverified |
| FR-010 | At most three eligible Do First Tasks, today/overdue only | Unverified |
| FR-011 | Overdue count and identity equality with Tasks owner | Unverified |
| FR-012 | Midnight, resume, timezone and date-sensitive command guards | Phase 5 targeted pass; final acceptance pending |
| FR-013 | Local and synchronized owner changes visible within two seconds | Phase 5 targeted pass for local arrival; final acceptance pending |
| FR-014 | Offline save/restart/sync, failure handling and deduplication | Phase 5 targeted pass; final acceptance pending |
| FR-015 | Real/preview scope isolation and delayed account switching | Phase 5 targeted pass; final acceptance pending |
| FR-016 | Independent loading/empty/available/unavailable/retry states | Phase 5 targeted pass; final acceptance pending |
| FR-017 | No fabricated future-domain metrics or active controls | Unverified |
| FR-018 | Arabic/English, RTL, semantics and keyboard/touch access | Unverified |
| FR-019 | Owner authority, no Today store or parallel sync/writer | Unverified |
| FR-020 | Functional prototype structure and five-target parity | Unverified |

## Acceptance measurements

No acceptance criterion has been executed or passed in Phase 1. Record device, build/commit, fixture, method, measured result and link/log before changing a status.

| ID | Required measurement/evidence | Status |
|---|---|---|
| SC-001 | Exact owner equality over mixed dates/deletions/schedule edits/map links/empty day; Tasks 4/10 and Habits 2/5 each 40%; Do First scope and actual XP | Unverified |
| SC-002 | 500 Tasks, 100 Habits, 200 awards; initial view and local action visible within 2 s on one mobile and one desktop target | Unverified |
| SC-003 | Ten offline action journeys across restart and later sync; one lifetime Task award, no Habit XP; ten read-only refreshes with zero business/pending writes | Unverified |
| SC-004 | Foreground midnight within 1 min, resume/timezone within 2 s; reject stale-day Habit action and preserve history | Unverified |
| SC-005 | Each failed/hung source shows recovery within 10 s; other sections remain usable; recovery within 2 s; zero foreign account/preview values | Unverified |
| SC-006 | Arabic and English mobile/desktop journeys; equivalent owner/offline behavior on Android, iOS, Windows, macOS, Linux; touch and keyboard journeys each within 3 min | Unverified |
| SC-007 | Two devices, same-account sync on matching and differing local dates; matching owner state and no duplicate awards/map-linked counts | Unverified |

## Phase 1 checks

- `dart format` completed for `test/support/today_fixtures.dart` and `test/unit/features/today/today_fixtures_test.dart`.
- Targeted `dart analyze` on those two files: **No issues found**.
- A direct Dart runtime smoke check instantiated the owner aggregates and confirmed the fixture's Tasks 4/10, Habits 2/5, and delayed session lookup after an A-to-B switch. It exited successfully. The temporary smoke script was removed.
- The first focused Flutter invocation could not access the SDK lockfile in the restricted workspace environment. Running only `test/unit/features/today/today_fixtures_test.dart` with SDK lockfile access exposed an asynchronous stream-delivery expectation in the test; the fake/test were corrected and the same file was rerun: **3/3 tests passed**. This is fixture verification, not a Today acceptance result.
- Existing encrypted database and preview records were not opened or modified by these checks. Runtime source files were not changed.

## Phase 2 foundation checks

- Implemented T003–T010 only: in-memory scope, calendar and owner reference values; independent section health; read-only owner/calendar ports; a device calendar adapter; closed composition-owned preview/account resolver; and an owner-boundary scanner. No schema, cloud endpoint, business writer, or existing preview data was changed.
- Before implementation, the new calendar and scope tests failed to compile because their intended adapters were absent. After implementation, the focused `test/unit/features/today`, `test/unit/app/composition/today_scope_resolver_test.dart` and `test/architecture/today_boundaries_test.dart` run passed **20/20 tests**. The existing `test/architecture/domain_dependency_test.dart` passed **6/6 tests**. After strengthening the award-write negative control, `test/architecture/today_boundaries_test.dart` passed **4/4** on its focused rerun.
- `dart analyze` on the new Today source, resolver and focused tests reported **No issues found**. `dart format` completed for the same Dart files.
- Tests cover both existing preview IDs, equal real-account owners, signed-out/unknown clearing, mismatched context rejection, delayed initial lookup, local date/offset changes, half-open XP intervals, 23/25-hour days, source status invariants and package/relative import bypass controls.
- These are foundation checks, not end-to-end acceptance: SC-001–SC-007 remain **unverified**. Phase 3 and later owner/UI/device work is still required.

## Phase 3 read-only Today checkpoint

- Implemented T011–T025 on `namaa/006-today-dashboard`: independent Task and Habit summaries, actual award-day XP, owner overdue and Do First reads, source-specific loading/error/retry states, localized Today view and preferences, and a scoped Today root. The view links to the existing owner screens. It does not introduce Today writes, storage, sync, active completion controls or Auth UI.
- Focused projection, adapter, Cubit, architecture and widget tests passed. The root widget tests passed **2/2** after switching owner navigation to a route push so Back returns to Today; the preference widget test passed **1/1**. Composition/router/localization tests passed **20/20**, and the strengthened Do First projection test passed **4/4**. These are targeted local tests, not a full device matrix.
- `integration_test/today_dashboard_test.dart` passed **1/1 on Windows** against an encrypted Foundation database. Its mixed-date fixture showed **4/10 Tasks** and **2/5 eligible Habits** completed, actual ledger XP, both existing preview identities, unchanged summaries after restart, and no additional Task, Habit, completion, award or pending-operation rows after ten read-only refreshes.
- Targeted `dart analyze` of the changed Today/app source and tests reported **No issues found** with exit code 0. `git diff --check` passed. The SDK telemetry directory was redirected into the workspace for analysis because the sandbox could not update its default roaming-profile telemetry file; this did not change the analysis result.
- This checkpoint verifies the read-only Phase 3 slice only. SC-001–SC-007 remain **unverified** as complete acceptance criteria: later phases add owner actions, calendar lifecycle, broad source recovery and cross-device checks. In particular, the Windows fixture above does not establish mobile performance, all five platforms, two-device synchronization or the full mixed map-linked equality journey.

## Phase 4 owner actions and creation checkpoint

- Implemented T026–T044 on `namaa/006-today-dashboard`. Today now sends complete/reopen and complete/undo requests to the existing Task and Habit owner commands, using the displayed local date and bound owner. The owner commands reread fresh records inside local transactions and reject stale dates, changed accounts, deleted or rescheduled records and unsafe no-ops before writing. Task completion still owns its lifetime XP award; Today creates no award or outbox of its own.
- The Today view exposes item-specific, localized actions with pending, rejected and uncertain-save feedback. Repeated taps on a pending or uncertain item are suppressed, confirmed owner emissions remain authoritative, and an obsolete callback after a scope change is ignored. A manual refresh preserves a failed source as stale and leaves its actions disabled until a fresh owner emission arrives.
- Quick creation uses the existing Task and Habit editors through validated route intents without account or business payloads. The Task form defaults to the device date when it opens; cancel or rebuild does not create an owner record. Normal owner navigation remains available.
- Focused Task and Habit command tests passed **18/18** after adding stale-day, fresh reschedule, delayed-read rollover, account-switch, retained-completion undo and concurrent complete/undo checks. The two Today bridge files passed **4/4** including rejected owner/day and successful owner writes. Today action Cubit tests passed **4/4** including duplicate taps, obsolete results, source failure, rejected writes, uncertain writes and unchanged XP. Architecture and creation-route/owner-screen tests passed **26/26**. Focused XP and map-link plus Today bridge/action regressions passed **21/21**. These counts describe overlapping targeted runs, not unique test totals.
- On Windows, `integration_test/today_dashboard_test.dart` passed its targeted ten offline complete/reopen/undo cycles against the encrypted Foundation database, including a database close/reopen after cycle five: one Task lifetime award, one Habit day row and zero Habit XP awards. `integration_test/mind_maps_task_link_test.dart` passed its targeted Today action on one Task linked in two maps with one lifetime Task award. Both tests ran locally with `flutter test --no-pub -d windows`; these are Windows-only focused checks, not a five-device gate.
- `flutter gen-l10n` completed. `dart format` processed the 44 changed/new Dart files. Targeted `dart analyze` on those files reported **No issues found**. `git diff --check` exited successfully. A dependency scanner initially found two presentation imports of the app routing layer; the shared intent enum moved to `core/application/navigation`, and the scanner plus affected route/owner tests passed on rerun.
- Phase 4's independent owner-action checkpoint is implemented and locally checked. SC-001–SC-007 remain **unverified as complete acceptance criteria**. In particular, foreground time/zone recovery, two-device synchronization, mobile performance, five-platform parity and final CI belong to later phases. No full device workflow was started for this phase.

## Phase 5 lifecycle, recovery and isolated device sync checkpoint

- Implemented T045–T056 on `namaa/006-today-dashboard` in the Phase 5 working tree. A foreground timer samples the date and offset at most every 30 seconds while the screen is active, and the screen resamples immediately on resume. Source events and date-sensitive actions also resample. Only a date/offset change advances the projection revision; confirmed records are reprojected without rewriting their recorded dates. Pausing, replacing or disposing the view cancels its timer.
- Task, Habit and XP reads have independent first-response deadlines of at most 10 seconds. A failed attempt is canceled and revisioned so its late callbacks cannot restore it. A quiet healthy stream stays available; a failed source retains only explicitly outdated same-day values, disables its actions, and can be retried without restarting the other sources. Habit metadata and day records form one confirmed pair; error, closure or synchronous subscription failure disposes both watches. Synchronous scope invalidation clears all values and pending action messages. Root and owner-route identity lookups have a bounded 10-second recovery path.
- Focused `flutter test --no-pub` for `test/unit/features/today`, `test/widget/app/today_route_test.dart`, `test/widget/app/app_router_test.dart` and `test/widget/features/today/today_screen_test.dart`: **49/49 passed**. These include injected 30-second foreground ticks, midnight/offset/23-hour-day projection, pending action dismissal, Task/Habit/XP hangs, either hung Habit constituent, stream error/closure/retry/old attempt, A-to-B delayed account lookup, old pending action, signed-out clearing, bounded unresolved lookup and English outdated/retry semantics. The deadline tests use a deterministic 20 ms test deadline and assert the production constructor's maximum of 10 seconds; they do not wait ten wall-clock seconds for each source.
- Windows encrypted database: `integration_test/today_dashboard_test.dart` **2/2 passed** after adding source interruption/recovery and date/offset changes. Ten offline complete/reopen/undo cycles survived database reopening with one lifetime Task award, one Habit day record and no Habit XP. The mixed preview fixture still showed Tasks **4/10** and Habits **2/5**. Ten read-only refreshes, restart, recovery and reprojection left Task, Habit, Habit-day, award and pending-operation row counts unchanged. The recorded Task and Habit dates remained intact.
- Staging `integration_test/today_sync_test.dart` passed first on Windows with two separate authenticated clients and encrypted stores, then in a **two-device-session run** using **Windows desktop (writer A)** and **Pixel 7 Android 17 API 37 emulator (reader B)**. The distinct runtimes used one isolated Supabase test account and run ID `8ea95e0e-327c-433f-b750-198bc1b39173` on UTC date `2026-10-22`; a second test account checked isolation. Windows A passed **1/1**; Android B passed **1/1** on the same remote Task/Habit/award records, including the final Android rerun with account-isolation assertions. The Android store began independently, imported the completed Task and Habit day plus the actual immutable award, and Today showed one instance of each. Remote award count for the run's Task was one; the foreign account saw zero matching Tasks, Habits, Habit days or awards. Reprojecting Android to the next local day with UTC offset **−120 minutes** removed those records from today's counts/XP while the stored Task date and Habit-day key remained unchanged.
- The two-device test observes the Task, Habit-day and award owner streams separately from Today. For each source, the elapsed time from its confirmed local watch emission to the corresponding Today state emission was asserted **under 2 seconds** on Android. This bound covers local arrival-to-view propagation; it deliberately excludes the full network download and bulk reconciliation, which were not required to finish within two seconds. The test used existing owner outbox dispatch, conflict handling, remote readers and reconciliation; it added no Today cloud writer or synchronization queue. Isolated staging fixtures from the successful run and earlier diagnostic attempts remain in the non-production project because authenticated clients cannot delete the RPC-owned rows; no production account was used.
- `dart analyze` on the affected Today/app sources, tests and both integration tests reported **No issues found**. `flutter gen-l10n` regenerated Arabic and English strings. `git diff --check` is the final whitespace gate. The full Android/iOS/Windows/macOS/Linux CI matrix and complete SC-001–SC-007 acceptance remain separate later gates; this Phase 5 result does not claim those criteria or feature 006 closed.
