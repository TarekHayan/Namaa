# Contract: Today Lifecycle, Recovery and Identity

**Scope**: FR-012 through FR-016 and FR-019.

## 1. Projection clock

Use an injected current-calendar reader and a small foreground scheduler, not a stored daily record or new timing package.

- On entry/resume, sample current date, offset and UTC instant before enabling date-sensitive actions. Reproject available local snapshots within two seconds.
- While foreground, compare date/offset at intervals no greater than 30 seconds; refresh a changed day within one minute. Also refresh before actions and after source events.
- Recompute owner overdue results as time advances, including expired target deadlines without a record update. Use the existing owner query; saved agenda time alone never creates overdue status.
- Derive XP day boundaries from separate local calendar midnights, then convert each to UTC. Do not assume 24-hour days.
- Pause/dispose foreground timers when appropriate; resume always recomputes from the current clock. Cancel timers/watches on disposal or scope invalidation; never accumulate duplicate subscriptions.
- A date/zone-boundary change increments projection revision. Reproject healthy raw owner snapshots; discard old-day derived stale values and disable actions until current day is validated.
- Recorded Habit dates, schedule revisions, Task calendar dates and actual award instants are never rewritten by clock refresh.

Platform lifecycle callbacks live in presentation/app integration; domain/application clocks remain infrastructure free. Test midnight, changed offset/timezone, clock jump and delayed reads with fake calendar/scheduler rather than long real waits.

## 2. Independent sources

Tasks, Habits and XP start concurrently for one resolved scope. Habit source internally needs both habit and day emissions. No all-or-nothing Future.wait or cloud readiness barrier.

Each source tracks scope generation, subscription-attempt revision, response deadline, health, confirmed raw snapshot and last applicable derived value.

| Event | Result |
|---|---|
| First usable response | available or confirmed empty; cancel initial deadline. |
| No usable first response by ten seconds | unavailable with localized retry; other sources continue. |
| Stream error or unexpected completion | unavailable, or same-scope/day stale values marked outdated. |
| Successful recovery response | current available/empty values visible within two seconds. |
| Quiet live stream after successful response | Remains healthy; silence is not failure. |
| Retry | Cancel/replace only failed source, new attempt revision/deadline. |
| Late old-attempt response | Ignore; cannot restore or overwrite a newer attempt. |
| Clock change | Reproject healthy confirmed raw snapshots using current date/instant. |
| Scope change | Immediately clear all values/feedback, cancel old work, then subscribe for new scope. |

If a Habit constituent stream fails, do not combine a successful fresh constituent with an unconfirmed failed constituent and call it current. Recovery must establish a usable pair again. Repeated errors cannot produce an unbounded retry loop or accumulating timers.

Unknown is never numerical zero. Stale display is allowed only with an explicit outdated label; unsafe commands for that source are disabled. Fresh Task data does not certify XP availability, and vice versa.

## 3. Identity ordering

Follow existing CloudSessionPort gate patterns. The initial account lookup is revision-protected against newer session events. Identity/mode change:

1. Invalidate old generation synchronously.
2. Clear all Task/Habit/XP values, derived counts and pending messages before rendering the next scope.
3. Cancel old subscriptions, timers and response deadlines.
4. Resolve/validate new bindings; real-account IDs must agree.
5. Start fresh scoped subscriptions with new generation tokens.

No unresolved/signed-out real-account state can reuse an earlier cache. Use bounded localized recovery for unresolved session setup rather than an endless root loading loop. Do not introduce authentication forms or request a new login merely to use development preview.

The two preview owner IDs are an explicit composition binding only. Preserve them without data migration and never permit real-account data to join that scope.

## 4. Action races

Today checks current scope/calendar before dispatch, but the owner command must also validate after awaited reads and inside its local transaction as specified in today-owner-integration.md. These two checks serve different boundaries.

An item action carries scope/projection revisions and desired state. Serialize per entity; avoid stale UI inversions. When the scope/day changes, stop using old callbacks for presentation. If already validly committed, the owner's record remains valid on its recorded date. Do not undo it, assign it to another day, or show old-account feedback.

Observation failure/timeouts do not prove a write failed; do not automatically resend a pending mutation or fabricate success. Refresh owner state and resolve through the owner result/streams. Source retry is read-only.

## 5. Local consistency and synchronization

The latest confirmed local records are authoritative for Today, including while offline. Owner writes and inbound reconciliation update local watches. View/read/retry actions create zero business/pending records.

Each source has its own confirmed revision. Do not claim one atomic cross-source/global snapshot: a Task commit and its XP stream notification may render in successive frames, but both must converge within two seconds after local availability. Never fill the gap with estimated XP or a false failed/zero summary.

Use existing owner synchronization. Cloud unavailability cannot block local rendering or a confirmed local save. Existing pending/conflict feedback remains owned by its feature; Today adds no parallel queue or reconciliation policy.

## 6. Verification obligations

- Initial hanging source and either hanging Habit constituent -> recovery <=10 seconds; healthy sections work.
- Stream error, unexpected done, repeated retry and late old-attempt events.
- Account A -> B -> preview -> unresolved, including a delayed initial lookup, owner emission and command callback; zero foreign content in captured states.
- Midnight foreground <=1 minute, resume/zone refresh <=2 seconds and stale-day save rejected.
- Daylight-saving boundary and exact XP half-open boundaries, without rewriting owner dates.
- Overdue deadline passes with no Task mutation; saved time/duration alone does not mark overdue.
- Owner navigation/edit/inbound updates <=2 seconds; offline restart and ten read-only refreshes.
