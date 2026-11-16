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

`assets/religious/adhkar_catalog_v1.json` (revised 2026-11-15: Arabic only, owner decision D3; Quran items, D4):

| Field | Rule |
|---|---|
| catalog_version | 1 |
| items[] | `item_id`, `list`, `position` (1-based, unique per list), `target` (≥1), `kind` (`dhikr` or `quran`), `text_ar`, `virtue_ar` (nullable), `reference_ar`; for `kind = quran` also `surah`, `ayah_from`, `ayah_to` and `preface_ar` (nullable, for example the isti'adha, shown apart from the verse text) |
| qiyam_supplications[] | `id`, `text_ar`, `source_ar` |
| attribution | The attribution line for the Quran text (KFGQPC Madinah Mushaf, Hafs, through the Quran Foundation), crediting the Quran Foundation. |

- Item IDs added after the prototype's `m1…m10` and `e1…e9` continue those series (`m11…`, `e10…`); a Quran item uses the same series. The approved list and order are fixed in `content-sources.md`.
- The UI labels follow the app language; the content fields are Arabic only.

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

## My Adhkar (Story 5, added 2026-11-15; reshaped 2026-11-16)

A personal collection: groups, and entries made of a text and an optional source. There is no target, counter, day or count record.

### Identity

- **My Adhkar group ID** and **entry ID**: random UUIDv4 values created on the device that creates them. They never change and are never reused.
- **Conflict ID**: built as above, with these descriptors:
  - group: `<updated_at micros>:<deleted>|<name-sha256>`;
  - entry: `<updated_at micros>:<deleted>|<text-sha256>|<source-sha256>|<sorted-group-ids-sha256>`.

### Encrypted local schema v11 (additive on v10)

v11 is not released yet (it exists only on the 009 branch), so it is changed in place to this shape, with no v12. The `my_adhkar_counts` table and the `target` and `note` columns of the first v11 draft are removed.

All lengths are counted in Unicode code points, on the device and on the server.

#### my_adhkar_groups

| Field | Constraint / purpose |
|---|---|
| account_id, group_id | Composite primary key. |
| name | 1–60 characters after trimming; never blank. Not unique. |
| created_at | UTC; the display order of the groups (oldest first). |
| updated_at, last_acknowledged_updated_at | As for the other records. |
| deleted_at | Nullable. Set once on delete and never cleared. |

- **Index:** `(account_id, deleted_at, created_at)` for the group list, and `(account_id, updated_at, group_id)` for sync.
- **Create command.** One transaction: re-validate the owner, check fewer than 100 live groups, insert the row, append the outbox operation.
- **Rename command.** Updates the name and appends the outbox operation. A deleted group returns `groupDeleted`.
- **Delete command.** One transaction (FR-029):
  1. set the group's `deleted_at`;
  2. remove the group from every live entry's membership;
  3. set `deleted_at` on every live entry left with no live group;
  4. append ONE outbox operation, for the group only.

  The server applies the same cascade itself (contracts/adhkar-qiyam-sync.md), so the cascaded entry changes are not queued; other devices receive them as server entry versions.

#### my_adhkar_items (the entries)

| Field | Constraint / purpose |
|---|---|
| account_id, item_id | Composite primary key. |
| text | 1–2000 characters after trimming; never blank. |
| source | Nullable; ≤ 500 characters after trimming; blank is stored as null. Plain text, never opened. |
| created_at | UTC; when the entry was created. |
| updated_at, last_acknowledged_updated_at | As for the other records. |
| deleted_at | Nullable. Set once on delete and never cleared: the tombstone keeps the entry from coming back on sync. |

- **Index:** `(account_id, deleted_at, created_at)` and `(account_id, updated_at, item_id)` for sync.
- **Add command.** One transaction: re-validate the owner, check fewer than 1000 live entries, check at least one group is chosen and every chosen group is live, insert the row and its memberships, append the outbox operation.
- **Edit command.** Updates the text, the source or the group set (at least one live group), guarded so it never writes over a deleted entry.
- **Delete command.** Sets `deleted_at` (with a monotonic `updated_at`) and appends the outbox operation.

#### my_adhkar_item_groups

| Field | Constraint / purpose |
|---|---|
| account_id, item_id, group_id | Composite primary key. The entry and the group belong to the same owner. |
| added_at | UTC; the order of the entry inside that group (oldest first). Kept when the entry is saved again with the same group. |

- **Index:** `(account_id, group_id, added_at)` for the group view.
- The membership set is part of the entry's version: it is written in the same transaction as the entry row, and it syncs inside the entry change (`group_ids`), not as a separate entity.
- Entity types in `pending_changes`: `my_adhkar_group` and `my_adhkar_item`. Group operations are dispatched before entry operations.

### Remote schema, migration 0017

- **`my_adhkar_groups`**: the owner, `group_id` (uuid), the name with the same checks, `created_at`, `updated_at` and `deleted_at`. Primary key `(owner, group_id)`. At most 100 live groups per owner.
- **`my_adhkar_items`**: the owner, `item_id` (uuid), the text and source with the same checks, `created_at`, `updated_at` and `deleted_at`. Primary key `(owner, item_id)`. At most 1000 live entries per owner.
- **`my_adhkar_item_groups`**: the owner, `item_id`, `group_id` and `added_at`, with foreign keys to the owner's entry and group. Primary key `(owner, item_id, group_id)`.
- **Receipts and conflicts**: `my_adhkar_operation_receipts` and `my_adhkar_conflicts`, as in 0016.
- **RPCs**: `apply_my_adhkar_group_change_v1` and `apply_my_adhkar_item_change_v1` (with `group_ids`) (contracts/adhkar-qiyam-sync.md).
- Same RLS and grants as 0016. There is no XP write anywhere in 0017.

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
- **My Adhkar group:** absent → live → deleted. Live groups can be renamed any number of times. Deleted is final, and it deletes every entry left with no live group.
- **My Adhkar entry:** absent → live → deleted. Live entries can be edited any number of times, including their group set (never empty). Deleted is final.

## Migration integrity

- Upgrade every real historical local schema (v1…v9) to v10, and v10 to v11 (My Adhkar). Existing Task, Habit, Map, Prayer, Adhkar and Qiyam rows, the XP ledger, the outbox and conflicts are preserved.
- A deliberately failed migration leaves the v9 database readable through the journal and recovery path.
- Test a fresh v10 database, each historical path, a restart after the upgrade, and the failure/recovery case.
