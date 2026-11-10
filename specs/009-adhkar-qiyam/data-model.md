# Data Model: Adhkar and Qiyam

Design date: 2026-11-09. This document lists planned names and fields; no schema has been applied yet. The decisions behind it are in [research.md](research.md).

## Vocabulary and identity

- **AdhkarList**: `morning` or `evening`.
- **AdhkarPeriod**: `morning` (Fajr→Maghrib), `evening` (Maghrib→next Fajr) or `unrestricted` (no Prayer schedule).
- **AdhkarDay**: a strict Gregorian `YYYY-MM-DD`, the civil date of the opening Fajr in the location's zone. Without a schedule it is the device's civil date.
- **QiyamNightDate**: a strict `YYYY-MM-DD`. Night D starts at Maghrib on D.
- **Catalog identity**:
  - `catalog_version` is a positive integer; v1 is the first reviewed catalog.
  - `item_id` is a stable text ID (`m1`…`m10` for Morning, `e1`…`e9` for Evening).
  - IDs are never reused for different text.
- **Record IDs**: UUIDv5 under a new fixed 009 namespace, `NS009`, chosen at implementation and shared by Dart, SQL and the test vectors:
  - Adhkar item record: `UUIDv5(NS009, 'adhkar-item/' + day + '/' + itemId)`.
  - Qiyam night record: `UUIDv5(NS009, 'qiyam/' + nightDate)`.
  - Adhkar set award `source_id`: `UUIDv5(NS009, 'adhkar/' + day + '/' + list)`.
  - Qiyam award `source_id`: the Qiyam night record ID.
  - Conflict ID: `UUIDv5(NS009, 'conflict/' + recordId + '/' + lowDescriptor + '/' + highDescriptor)`, built the same way as in 008. The descriptors are canonical ASCII shared by Dart and SQL: Adhkar `<updated_at micros>:<catalog_version>:<count>`; Qiyam `<updated_at micros>:<performed>|<rakahs>|<witr>|<start>|<end>|<note-sha256>|<zone>|<offset>`. They are ordered byte-wise before hashing, so the ID is stable whatever the arrival order was.
- **Timestamps**: every version instant is UTC with microsecond precision. The owner is part of every key and is never inferred from an entity ID.

## Reference content (asset, not user data)

`assets/religious/adhkar_catalog_v1.json`:

| Field | Rule |
|---|---|
| catalog_version | 1 |
| items[] | `item_id`, `list`, `position` (1-based, unique per list), `target` (≥1), `text_ar`, `translation_en`, `virtue_ar`, `virtue_en`, `reference_ar`, `reference_en` |
| qiyam_supplications[] | `id`, `text_ar`, `source_ar`, `source_en` |

- The catalog is validated on load: unique IDs and positions, targets ≥ 1, and non-blank text and references.
- An invalid catalog leaves the feature in a recoverable "content unavailable" state, and the app does not crash.
- Each text must match `content-sources.md`.

## Encrypted local schema v10 (additive on v9)

### adhkar_item_counts

| Field | Constraint / purpose |
|---|---|
| account_id, adhkar_day, item_id | Composite primary key. |
| record_id | Deterministic UUID; unique per owner. |
| catalog_version | The catalog the count was made against. |
| list | `morning` or `evening`, copied from the catalog for indexed reads. |
| count | 0 ≤ count ≤ the catalog target for that version. |
| created_at, updated_at | UTC; `updated_at` increases monotonically for local edits. |
| last_acknowledged_updated_at | Nullable; the server-confirmed base. |

- **Indexes:**
  - `(account_id, adhkar_day, list)` for the day screen and set completion;
  - `(account_id, updated_at, record_id)` for bounded sync reads.
- **No row means a count of 0.** A reset to 0 is a persisted row, so a stale count cannot come back on retry.
- **Increment command.** In one transaction:
  1. Re-validate the owner, the day and the period.
  2. Read the current row.
  3. Reject the change if the count is already at the target.
  4. Write `count + 1`.
  5. If the list is now complete for the day and the set award is missing, insert the provisional set award.
  6. Append the outbox operation.
- **Reset command.** It writes `count = 0` and an outbox operation, and never touches the award.

### qiyam_nights

| Field | Constraint / purpose |
|---|---|
| account_id, night_date | Composite primary key. |
| record_id | Deterministic UUID. |
| performed | Boolean. "No row" means not recorded; `false` means the explicit "No". |
| rakahs | Null when `performed` is false; otherwise one of 2, 4, 8 or 11. |
| witr | Boolean; false when not performed. |
| start_time, end_time | Nullable local wall-clock `HH:mm`, only when performed. An end earlier than the start crosses midnight. |
| note | Nullable, ≤ 500 characters, only when performed. |
| recorded_zone_id, recorded_offset_minutes | Context captured at submission. |
| created_at, updated_at, last_acknowledged_updated_at | As above. |

- **Indexes:** `(account_id, night_date DESC)` for history and the streak, and `(account_id, updated_at, record_id)` for sync.
- **Save command.** One transaction that re-validates the current night, upserts the record, inserts the provisional award on the first `performed = true` if the award is missing, and appends the outbox operation.
  - Changing to "No" clears the detail fields.
  - It never revokes the award.

### Reused tables

- **pending_changes**: entity types `adhkar_item` and `qiyam_night`, a stable `operation_id`, a typed semantic payload and `base_updated_at`.
- **conflict_records**: the retained versions, under the deterministic conflict ID.
- **xp_awards**: the new sources `adhkar_set_done` (15) and `qiyam_done` (30). `XpAward` validation and `fromStored` must accept them. Existing Task and Prayer awards stay unchanged.
- **The migration journal and its rollback behavior** are reused.

## Remote schema, migration 0016

- **`adhkar_catalog_items`**: `(catalog_version, item_id)` primary key, plus list, position and target. It is seeded by the migration, holds no text, is read-only to authenticated users and receives no client writes.
- **`adhkar_item_counts`**: the owner (references `auth.users`), the date, the item ID, the record UUID (with its identity checked), the catalog version (foreign key to the catalog), the list and the count (checked against the target), plus UTC version fields.
  - Primary key `(owner, adhkar_day, item_id)`.
  - Unique `(owner, record_id)`.
- **`qiyam_nights`**: the owner, the night date, the record UUID and the Qiyam fields, with check constraints mirroring the local rules: rakahs in (2, 4, 8, 11) exactly when performed; note ≤ 500; times matching `^[0-2][0-9]:[0-5][0-9]$` with hour < 24.
- **`adhkar_operation_receipts`** and **`qiyam_operation_receipts`**: primary key `(owner, operation_id)`, plus a fingerprint, the outcome and `applied_at`. They are internal to the RPCs.
- **`adhkar_conflicts`** and **`qiyam_conflicts`**: the stable conflict ID, both versions and the active choice. Owners can read them; only the RPCs write them.
- **xp_awards**: reused with the two new sources, insert-only.

RLS limits every exposed row to `auth.uid()`. There is no direct client INSERT, UPDATE or DELETE. Anonymous and public users get no execute rights.

## Derived and memory-only values

- **AdhkarClockState**: the Adhkar day, the period, the next boundary instant, and whether a schedule is available.
- **AdhkarListView**: the ordered items with count and target, the completed count, the percentage, `countable`, and when the list's period starts if it is not countable.
- **AdhkarStreak** (an integer): see research R9.
- **QiyamNightView**: the night date, the last-third instant (or the reason it is unavailable), the record (or not recorded), and `editable`, which is true only for the current night.
- **QiyamHistoryEntry**: the night date and its recorded details, newest first. Pages hold 30 nights each.
- **QiyamStreak** (an integer): see research R9.
- **TodayAdhkarQiyamReference**: Morning x/N, Evening x/N, the Adhkar period, tonight's Qiyam state, and both streaks. It is read-only; Today never touches Adhkar or Qiyam storage.

## State transitions

- **Adhkar item:** count k → k+1 when k < target and the period is countable; any k → 0 on reset. There is no transition driven by a timer, and the day change never writes rows.
- **Adhkar set:** complete whenever every item in the list for that day and catalog version is at its target. The award is inserted on the first completion and is permanent.
- **Qiyam night:** not recorded → performed or not performed. Either can switch to the other, and details can change while the night is current. Earlier nights are frozen in the UI. The award is inserted on the first `performed = true` and is permanent.

## Migration integrity

- Upgrade every real historical local schema (v1…v9) to v10. Existing Task, Habit, Map and Prayer rows, the XP ledger, the outbox and conflicts are preserved.
- A deliberately failed migration leaves the v9 database readable through the journal and recovery path.
- Test a fresh v10 database, each historical path, a restart after the upgrade, and the failure/recovery case.
