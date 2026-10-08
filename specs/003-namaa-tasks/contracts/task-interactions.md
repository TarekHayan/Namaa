# Task Interaction Contract

**Consumers:** Tasks UI now; future Today, Mind Maps, and Analytics through explicit application queries/commands. This is an application behavior contract, not a proposed public HTTP API. See ../data-model.md.

## Commands

All writes require the current authenticated account context and apply to its own local encrypted records first. A command either commits Task state and its pending change atomically or returns a typed failure without partial visible mutation. Network absence is not a write failure.

| Command | Input | Successful observable result |
|---|---|---|
| CreateTask | Nonblank title; optional details/date/time/deadline/category/quadrant/duration | New stable Task ID, defaults where omitted, visible immediately, pending sync |
| EditTask | Task ID and supported fields | Same ID and refreshed views, pending sync |
| Add/Edit/Toggle/RemoveChecklistItem | Task ID and item ID/text/state as relevant | Only that Task's steps change, parent completion unaffected, pending sync |
| MoveTask | Task ID and quadrant | Same Task changes both list and matrix projections |
| CompleteTask | Task ID | Sets completion time if open; creates first award at most once; no checklist precondition |
| ReopenTask | Task ID | Clears current completion time; retains prior award |
| DeleteTask | Task ID | Hides active Task via tombstone; retains award/history of award |

A missing, deleted, or foreign-account Task returns a typed not-found/not-authorized failure without exposing another account's data. Invalid title or checklist text returns validation failure before persistence. Repeated CompleteTask on a completed Task cannot award XP again.

## Queries and presentation state

The application exposes one account-scoped Task source for list filters Today, Urgent, All, Completed/history, category, overdue, and matrix quadrant projections. A task has the same ID, completion, category, and quadrant in every projection. Task state observes local commits without waiting for cloud confirmation. Separate sync status and recoverable conflict information can be shown without replacing the locally available Task list with a network-only state.

For Today/overdue, evaluate dates against the device's current local calendar, and compare targetDeadline according to its saved timezone context. Today's elapsed scheduledTime alone does not mark overdue. Completed Tasks are excluded from overdue and open matrix.

## Navigation, localization, accessibility

Tasks route is registered in the existing app router and guarded by the current account/session state. An initial authenticated sync must finish before Tasks is released to a newly signed-in account; after that, local operations continue offline. A basic sign-in path is an external release prerequisite, not part of this Task contract. User-facing labels, errors, dates, and validation use Arabic and English resources; Arabic layouts follow RTL while values such as times remain readable. Existing light/dark/system theme foundation applies. Layout may adapt between mobile and desktop without changing command/query semantics.

## Verification

Widget and integration checks cover form defaults and validation, all filters and matrix identity, checklist independence, explicit completion, Arabic/English RTL, route guard, offline visible updates, persistence after restart, and equivalence on required platforms. No recurrence, Mind Map, Today, Auth-flow, or new gamification UI is specified here.
