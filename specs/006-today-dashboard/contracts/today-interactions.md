# Contract: Today Interactions

**Scope**: FR-001/004/008/009/010/011/017/018/020. Functional presentation now; final colors, typography and screen composition later.

## 1. Entry, navigation and bootstrap

- Root `/` presents Today inside the current Foundation startup/recoverable/blocking shells. Do not bootstrap another database, app or session.
- Use a scoped route gate following existing session-revision protection. Resolve the closed TodayScope before business subscriptions; no scope means no cached business content.
- Development preview opens without public sign-in. Account mode uses existing session facilities only.
- Existing `/tasks`, `/habits` and `/mind-maps` remain reachable. Push owner routes where return to Today is required; returning shows current owner data.
- Preserve current global LocaleCubit and ThemeCubit. Provide a small app-owned preference sheet/menu using their existing commands; do not build a separate settings store or import app Cubits into Today domain/application.
- Preserve useful Foundation recovery/diagnostic access in its existing application context. Technical probes do not become daily obligations or product cards.

## 2. Visible content

| Section | Required content |
|---|---|
| Header | Current localized local calendar date; owner navigation and preferences access. |
| Task progress | Completed/eligible and independent rounded whole percentage; explicit open/completed distinction. |
| Habit progress | Completed/eligible and its own percentage; eligible habits with owner streak/current state. |
| XP | Actual earned-today amount; localized unavailable/loading state when not confirmed. |
| Quick actions | Existing new-Task and new-Habit flows. |
| Agenda | Today's Tasks: chronological timed group, separate untimed group, saved duration where present; canonical completion. |
| Do First | At most three incomplete urgentImportant Tasks scheduled today or owner-overdue, owner order, dates visible; matrix link. |
| Overdue | Owner-overdue distinct count and owner overdue-view link. |

Task/Habit confirmed empty shows zero counts and an explanatory no-items state, with no 100% claim or invalid ratio. Never combine the two percentages. A failed source cannot appear as zero. A confirmed empty XP ledger shows zero XP.

Task-derived sections share Task health. Habit/XP failure cannot block healthy Tasks. Retained same-day values explicitly show outdated status and disable unsafe actions for that source. Retry remains keyboard/touch reachable.

Unimplemented feature cards, religious obligations, prayer timetable, financial metrics, score weights, new XP targets/levels and charts are omitted. No active-looking future controls or fabricated zero metrics.

## 3. Owner entry intents

Add a small typed/validated app routing intent, using these existing owner operations:

| Intent | Owner behavior |
|---|---|
| Tasks | Normal owner view. |
| Task matrix | Existing showMatrix behavior. |
| Overdue Tasks | Existing overdue filter/view. |
| New Task | Existing TaskEditor; scheduled date defaults to current local today under owner validation. |
| Habits | Normal owner view. |
| New Habit | Existing HabitEditor and validation. |
| Mind Maps | Existing library/editor navigation. |

Owners consume initial intent once after session/Cubit readiness. A rebuild, locale change, async session callback or back navigation must not reopen an editor or save anything. Malformed intent falls back to the owner default safely; it cannot inject an owner ID or serialized business object.

The new-Task intent defaults the date when its owner form opens, using the current calendar; a form left open across midnight follows its existing explicit selected-date behavior. No silent retargeting of an edited date. Day-sensitive completion/undo from Today is separately guarded at save time.

Today never duplicates editor fields, default rules or save commands. Cancel creates nothing. After save/return the owner stream updates Today. Full editing/deletion remains in owning areas.

## 4. Completion controls and feedback

- Today's scheduled Task rows may complete/reopen the same Task ID. Other-date Do First rows open Tasks; they do not gain a new all-date Today toggle.
- Eligible Habit rows complete when due or undo their current recorded completion. An unscheduled retained completion permits undo only.
- Pending state is item-specific, labeled and disables repeated conflicting submissions. Do not block healthy unrelated sections.
- Local confirmed saves precede success feedback. Task XP follows actual ledger emission; no optimistic award.
- Recoverable failure keeps latest confirmed data and offers a localized explanation/retry when safe.
- A stale-date rejection refreshes Today and asks the user to act on the current day's row; no automatic new-day save.
- Identity changes clear all old item feedback; a late success/failure cannot show a previous account's item.
- No automatic completion/activity inference, invented agenda time or schedule shift from elapsed clock/duration.

## 5. Localization, responsive layout and accessibility

Follow existing ARB/gen_l10n and owner strings-adapter patterns. Add TodayStrings plus an app-level localization adapter; no hardcoded user-facing text or infrastructure in widgets. Localize section labels, empty/loading/stale/errors, controls, date/time/count/percent/XP and semantics.

Use locale-aware formatting and inherited directionality. Support Arabic/English and mixed/long titles, text scaling, narrow mobile and desktop windows. Logical reading/focus order follows header, summaries, quick actions, agenda/priority and navigation. Cards may reflow without changing meaning.

Every completion/navigation/retry/preference control has a meaningful accessible label, visible focus, adequate touch target and pointer/keyboard activation. Completed/pending/error states use text/icons/semantics as well as color. A keyboard-only user can enter/leave owner routes, operate forms and return without a focus trap. Do not introduce an unverified visual-design system.

## 6. Acceptance boundary

Verify touch and keyboard scripted journeys each within three minutes, in Arabic and English on a tested mobile and desktop target. Verify equivalent owner/offline behavior on all five targets. No external user recruitment is required by SC-006; record the scripted journey and actual results. Existing owner validation and localization regressions remain required.
