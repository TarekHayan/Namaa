# Adhkar and Qiyam synchronization and reward contract

References: [model](../data-model.md), [research](../research.md). The planned migration is `supabase/migrations/0016_adhkar_qiyam.sql`. Each rule follows [008 prayer-sync](../../008-prayer-experience/contracts/prayer-sync.md) unless it is stated differently here.

## RPCs

### `apply_adhkar_item_change_v1`

| Parameter | Type / rule |
|---|---|
| p_adhkar_day | date; rejected if it is more than 2 days after the server's current UTC date. |
| p_item_id | text; must exist in `adhkar_catalog_items` for `p_catalog_version`. |
| p_catalog_version | integer; must exist. |
| p_count | integer; 0 ≤ count ≤ the catalog target. |
| p_updated_at | UTC; required; must sit inside the record's award window `[day − 1 day, day + 2 days)` in UTC, as 0015 does for the completion instant. |
| p_base_updated_at | UTC or null; the acknowledged base. |
| p_operation_id | non-blank text; stable across retries. |

### `apply_qiyam_night_change_v1`

| Parameter | Type / rule |
|---|---|
| p_night_date | date; the same two-days-ahead limit. |
| p_performed | boolean. |
| p_rakahs | integer or null; in (2, 4, 8, 11) exactly when performed. |
| p_witr | boolean; false when not performed. |
| p_start_time, p_end_time | text or null, `HH:mm`; only when performed. |
| p_note | text or null, ≤ 500 characters; only when performed. |
| p_recorded_zone_id, p_recorded_offset_minutes | Validated as in 0015. |
| p_updated_at, p_base_updated_at, p_operation_id | As above. |

The client never sends an owner, an XP amount, a list (it is derived from the catalog) or a record ID (it is recomputed by the server).

## Transaction (both RPCs)

1. **Reject unauthenticated callers.** Use an empty `search_path`, qualified SQL and least-privilege grants. Deny anon and public execution, and deny every direct client write.
2. **Check the receipt** under a lock on `(owner, operation_id)`. The fingerprint covers the semantic fields plus `p_updated_at`, and excludes the base.
   - The same fingerprint returns the original outcome.
   - A different fingerprint under a reused operation ID is rejected with no side effects.
3. **Lock the record identity** before reading it, including a missing row. Different items and different nights stay independent.
4. **Resolve.**
   - A matching base or identical content is ordinary convergence.
   - A divergent version is resolved newest-wins.
   - Equal timestamps are broken by a byte-ordered semantic version
     descriptor:
     - Adhkar: `<updated_at micros>:<catalog_version>:<count>` — the catalog
       version participates (Phase 2 review finding 6), so two versions that
       differ only by it never tie by arrival order;
     - Qiyam:
       `<updated_at micros>:<performed>|<rakahs>|<witr>|<start>|<end>|<note-sha256>|<zone>|<offset>`.

     The descriptor strings are shared verbatim with the Dart side
     (data-model.md); the greater descriptor wins.

     The greater key wins.
   - The losing version is kept as a conflict under its stable conflict ID.
5. **Award.**
   - **Adhkar.** After writing, check the active rows for `(owner, day, list of item)`. If every catalog item of that list and catalog version has `count = target`, insert `xp_awards(owner, 'adhkar_set_done', setSourceId, 15, now())` with `on conflict do nothing`.
   - **Qiyam.** If the submitted version has `performed = true`, insert `('qiyam_done', recordId, 30)` with `on conflict do nothing`. The award is attempted even when this version loses to a newer "No".
   - Awards are never updated or deleted.
6. **Commit** the record, the award, the conflict and the receipt together.

**Response:** `receiptId`, `replayed`, `activeRecord`, `activeVersion`, an optional `retainedRecord`, an optional `conflictId`, and an optional `canonicalAward` (`source`, `sourceId`, `amount`, `awardedAt`).

## Local finalization

- **Dispatch registration.** Register `adhkar_item` and `qiyam_night` in `EntityDispatchRouter`. In one repository transaction, each dispatcher:
  - applies the canonical award, replacing the provisional replica once;
  - upserts the conflict evidence;
  - applies the server's active record only when no newer local work is pending or acknowledged.

  Only then does it return `DispatchAcknowledged`. If the local step fails, the operation stays pending.
- **Adhkar set awards.** These can come back on the response for any item of the set. The dispatcher settles them by `(source, sourceId)`, never by item.

## Inbound readers

Each reader is owner-scoped, uses bounded keyset pages and restarts its pass from the start of the range, as in 008:
- Adhkar counts, ordered by `record_id`;
- Qiyam nights, ordered by `record_id`;
- awards with `source in ('adhkar_set_done', 'qiyam_done')`, ordered by `source_id`;
- the conflicts of each domain, ordered by `conflict_id`.

The catalog table is read once per catalog version and cached.

## My Adhkar (migration 0017, Story 5)

### `apply_my_adhkar_group_change_v1`

| Parameter | Type / rule |
|---|---|
| p_group_id | uuid; the group's stable ID. |
| p_name | text; 1–60 code points after trimming. |
| p_created_at | UTC; set by the first version, immutable afterwards. |
| p_deleted | boolean; true marks the delete. |
| p_updated_at, p_base_updated_at, p_operation_id | As for items. |

### `apply_my_adhkar_item_change_v1`

| Parameter | Type / rule |
|---|---|
| p_item_id | uuid; the entry's stable ID. |
| p_text | text; 1–2000 code points after trimming. |
| p_source | text or null; ≤ 500 code points after trimming; blank is stored as null. |
| p_group_ids | uuid[]; non-empty, no duplicates, each a group of the caller. |
| p_created_at | UTC; set by the first version, immutable afterwards. |
| p_deleted | boolean; true marks the delete. |
| p_updated_at, p_base_updated_at, p_operation_id | As above, without the day window (an entry has no day). `p_updated_at` is rejected if it is more than 2 days after the server's current UTC time. |

There is no count RPC: My Adhkar has no counter (owner, 2026-11-16).

### Rules that differ from 0016

- **Limits.** An entry create is rejected with `limit_reached` when the caller already has 1000 live entries; a group create, when the caller already has 100 live groups.
- **Lengths** are counted in code points (`char_length` on the trimmed text), matching the client.
- **Group delete cascade.** In the same transaction as a group's delete, the server removes the group from every live item's membership and deletes every live item left with no live group. Each affected item gets a new server `updated_at`, so other devices pull it. A deleted group stays deleted; a later rename, newer or older, is kept as a conflict.
- **Item groups.** On an item change, deleted groups are dropped from `p_group_ids`. If none is left, the item is deleted, the submitted version is kept as a conflict, and the outcome is `group_deleted`. A group the server does not know yet returns the retryable failure `group_missing`; the change stays pending (the client dispatches group operations first, so this only happens after a reorder or a partial pass).
- **Delete is final.** Once an item has `deleted = true`, the server keeps it deleted. A later change to the item, newer or older, is not applied; it is kept as a conflict, and the response's active record is the deleted version.
- **No award.** Neither RPC reads or writes `xp_awards`.
- **Descriptors** for the equal-timestamp tie are in data-model.md.

### Local finalization and inbound

- Register `my_adhkar_group` and `my_adhkar_item` in `EntityDispatchRouter` through composition, groups dispatched first, with the same one-transaction finalization before `DispatchAcknowledged`.
- The inbound reader pages `my_adhkar_groups` by `group_id`, `my_adhkar_items` (with their group sets) by `item_id`, and `my_adhkar_conflicts` by `conflict_id`, owner-scoped, restarting each pass as in 008. It runs in the Adhkar sync service, so a failure stays isolated from the other domains.

## Required proofs (pgTAP and integration)

- **Access control.** Anonymous callers and foreign owners are denied. Malformed inputs are rejected: an unknown item, a count above the target, rakahs outside the set, details sent with "No", a note over 500 characters, bad times, and dates beyond two days.
- **Convergence.** A matching base produces no conflict. Divergent versions produce exactly one stable conflict, whatever the arrival order.
- **Set completion.** Different items from two devices complete the set, and the 15 XP is awarded once.
  - Completing, resetting and completing again within one day gives one award.
  - The award stays after the set is reset.
- **Qiyam award.** Yes, then No, then Yes gives one 30 XP award. Two devices racing on their first Yes give one award.
- **Replay safety.** An exact replay, a changed-content operation-ID collision, a lost ACK, a restart, a duplicate inbound record and a stale receipt against a newer descendant are all handled.
- **Isolation.** Existing Task and Prayer awards stay readable and unchanged. A fresh third device sees the retained conflicts. No state leaks after an owner change.
- **My Adhkar.** Access control and malformed input (blank text, text over 2000, source over 500, blank or over-60 group name, empty or foreign `p_group_ids`); the 1000-entry and 100-group limits; the group delete cascade (an entry only in that group is deleted, an entry also in a live group stays there); `group_deleted` and `group_missing`; a delete that stays final against older and newer edits; newest-wins with one stable conflict for concurrent edits; and zero rows written to `xp_awards`.
