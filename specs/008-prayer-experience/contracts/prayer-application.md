# Prayer application and lifecycle contract

References: [spec](../spec.md), [model](../data-model.md). Names are planned interfaces, not implemented declarations.

## Boundaries and ports

| Port/service | Owning layer and obligations |
| --- | --- |
| CitySearchPort | Prayer application; search(query,locale,cancellation) yields validated candidates or typed failure. No profile/report data sent. |
| PrayerPreferencesPort | Application; watch/read/save owner-local preferences with expected revision. Data adapter uses encrypted DB, never shared preferences/cloud. |
| PrayerScheduleCalculatorPort | Application; calculate(location,zone,civilDate,method) returns immutable field availability/UTC instants. Pure adapter; no network/clock reads inside calculation. |
| PrayerClockPort | Application; nowUtc plus explicit zone-date derivation and injected foreground scheduler/lifecycle refresh. |
| PrayerReportIdentityPort | Application; derive stable date/prayer UUID; the data adapter owns the uuid package import, keeping domain/application infrastructure-free. |
| PrayerRepository | Application; indexed owner/day watch/read and transaction boundary for report/outbox/reward/reconciliation. |
| PrayerReportCommands | Application; desired-state command with owner generation, captured city date/context and operation ID; validates and commits locally. |
| PrayerContextService | Application; combines preferences, date/calculation and report watch for one active owner; shared by Prayer UI and Today bridge. |
| PrayerSyncService | Application; single-flight outbound coordinator then bounded inbound report/reward/conflict readers, owner guard and reconnect retry. |
| PrayerCubit | Presentation; source availability, per-prayer feedback and editor state. No direct DB, provider HTTP or another domain's commands. |

Data adapters may import the shared infrastructure and XP application/domain, not Tasks/Habits storage. Today adapter reads Prayer application projections and maps them into Today-owned DTOs. App composition alone maps preview IDs/session and routes.

## Reporting command

Input: prayerName, desiredStatus, expectedLocalDate, capturedPreferenceRevision, scopeGeneration. The command gets owner from the resolved session/closed preview, never from free-form user input.

1. At submission sample nowUtc once; resolve current city date. Reject mismatching date, absent city, obsolete owner generation or changed editor context with a refreshable failure.
2. Inside transaction read latest report and acknowledged base, preserve report identity, create a monotonic UTC version and completion timestamp where required.
3. Write report, insert first local eligible10/5 award if absent and queue immutable operation. Preview skips cloud dispatch but retains durable local behavior.
4. Same-state no-op does not produce another reward/outbox event. Do not replace queued completion events with later reset snapshots.
5. Commit is the durable-save boundary; UI may show pending work but must not announce success before commit. Rollback leaves all three effects absent.
6. A valid accepted action crossing midnight retains its captured identity. New actions cannot target previous days. Server accepts delayed historic uploads: it does not compare their date to server UTC today.
7. Owner change during preparation/commit uses final session/generation validation; no stale result enters a new owner's UI.

All four desired states are explicit; missed never originates from a timer. Report save is possible when its date context exists but one or more calculated schedule fields are unavailable.

## Schedule and lifecycle

- Initialize timezone database once in composition. Use saved IANA zone explicitly; never mutate timezone global local setting.
- Compute D/D+1 independently for a context; use field-level unavailable results for raw solar failures/substitution.
- Next prayer is the earliest valid future instant at or after now in ordered D/D+1 occurrences. At an exact boundary, advance the countdown target so it never becomes negative; report status is unchanged.
- If an unavailable earlier event prevents proving which prayer is next, show next-prayer unavailable instead of skipping it and claiming a later one.
- Night fractions depend on valid today-Maghrib and tomorrow-Fajr with positive UTC duration.
- Tick each second only while foreground/observed; tick formats remaining duration, not a whole-history read/recalculation. Refresh context on date boundary, preferences change, resume or retry.
- Use independent health for preferences, calculation and reports. A failed calculation must not replace retained reports with zero or clear saved city.
- Cancel old report subscriptions, search requests and timers on owner/context replacement; every async result carries matching generation.
- Clock correction/resume resamples actual UTC once and rebuilds the context; device timezone change refreshes Today independently.

## Current preview/XP composition

Create kPrayerPreviewAccountId isolated from real accounts and existing Task/Habit preview identities. Extend TodayScope with prayerOwnerId; real account mode requires the same owner across sources. Preserve the two existing preview IDs and bind only explicitly enumerated preview ledger owners.

For preview total XP, compose existing Task-owner and Prayer-owner award streams into the Today-owned references; scope the adapter to those two fixed IDs only. Do not loosen the real-account identity guard or copy Prayer awards into the Task owner partition. Account mode reads the single account's generic ledger.

## Failure/privacy contract

Use existing AppResult/AppFailure categories/message keys; local failure is recoverable with retry and no lost prior data. Search/zone/config errors are distinguishable from unconfirmed reports. Diagnostics contain failure class, method/policy version and non-sensitive event type; never query text, city coordinates, credentials, prayer payload or account IDs. No telemetry/analytics system is introduced.

Logout disposes watches and hides owner state; it does not delete encrypted data. Auth UI/account recovery remain outside008.
