# Prayer synchronization and reward contract

References: [model](../data-model.md), [research](../research.md). Planned migration: supabase/migrations/0015_prayer_reports_and_rewards.sql.

## RPC boundary

Native typed function apply_prayer_report_change_v1 accepts:
- p_local_date: SQL date; p_prayer_name: one of five canonical names.
- p_status: one of four canonical states.
- p_reported_completion_at: UTC timestamp for completed states, null otherwise.
- p_recorded_zone_id: validated nonblank IANA identifier; p_recorded_offset_minutes: valid zone-offset range.
- p_updated_at: required UTC version; p_base_updated_at: nullable acknowledged UTC base.
- p_operation_id: nonblank stable opaque ID; same request keeps its ID across every retry.

There is no client owner argument, XP amount, completionXp or metadata-bearing JSON envelope. Derive owner from auth.uid() and recompute report UUID. Strictly validate fields and finite date/timestamp encodings. Stored canonical payload does not include _syncBaseUpdatedAt or mutable reward values.

The caller may upload a previous civil date after offline use; the server must not impose its current UTC date as a reporting-date constraint. UI/application today-only rules remain enforced at original submission.

## Transaction and response

1. Reject unauthenticated callers. Use empty search_path, qualified SQL and least-privilege grants. Deny anon/public execution and direct client INSERT/UPDATE/DELETE.
2. Lock owner+operation key, check receipt. Fingerprint the immutable semantic report fields and submitted version; exclude the transport base argument, which may legitimately rebase without changing the operation. Identical fingerprint returns the original outcome; changed semantic content/version reuse fails without side effects.
3. Lock owner+report identity before reading/inserting, including absent rows. Different prayers/dates remain independent.
4. Matching acknowledged base, identical active content or recognized receipt lineage is ordinary convergence. Divergent base/content creates retained evidence.
5. Newer timestamp wins. Equal-timestamp divergent states use the canonical semantic key defined below; preserve both versions and return a resolved outcome.
6. For submitted on-time/late completion, attempt the one eligible10/5 reward insert even when the submitted version loses to a later reset. Existing canonical award remains unchanged. Never infer eligibility from an editable amount.
7. Commit report, immutable award, conflict and receipt together.

Response contains receiptId/replayed, activeReport and activeVersion, optional retainedReport/version, stable conflictId, and optional canonicalAward(amount,awardedAt,source,sourceId). Response reports are snapshots, not instructions to overwrite later local edits.

First server-committed eligible award is canonical. The server assigns its award instant; offline replicas may reconcile their provisional instant/amount once. Lost-response retry returns the committed receipt rather than awarding again.

## Deterministic version/conflict identities

Report ID uses the fixed UUIDv5 namespace and date/prayer name in data-model.md. Install/check uuid-ossp in extensions and call extensions.uuid_generate_v5 explicitly; no server UUID randomness for the report.

For equal timestamps, compare this semantic ASCII key using byte/C collation, never localized JSON order:
status + '|' + completionUtcMicrosecondsOrNull + '|' + recordedZoneId + '|' + recordedOffsetMinutes.
Allowed zone IDs cannot contain '|'; status is an enum; numeric encoding has one signed-decimal representation. The lexicographically greater key is active. This is deterministic convergence, not a religious-practice judgment.

Conflict identity: UUIDv5(same fixed namespace, 'conflict/' + reportId + '/' + lowerVersionDescriptor + '/' + higherVersionDescriptor). Descriptor = UTC version microseconds + ':' + semantic key; order both descriptors by byte/C comparison. Prefix separates conflicts from report identities. Identical descriptors produce no conflict. SQL/Dart share vectors for field ordering, null/UTC formatting, ties and reversed arrival.

Retained rows are immutable evidence; repeated detection reuses the ID. The selected version and the other version are both downloadable to the owner, including a newly joined device.

## Local finalization and shared coordinator

Register prayer_report in EntityDispatchRouter. Prayer dispatcher maps typed RPC outcomes and uses a repository transaction to:
- insert/update canonical reward;
- set the report's local-only canonical_reward_confirmed_at settlement marker when that canonical award is present; never send this marker in RPC/payload;
- upsert conflict evidence by stable ID;
- apply server active report only when no newer acknowledged/pending local work would be overwritten.

The generic coordinator acknowledges afterward. Do not pre-acknowledge: current DriftLocalStore rejects duplicate ACKs. Crash between local outcome and ACK safely retries the remote receipt/local idempotent finalization. If local finalization fails, return recoverable failure and leave operation pending.

An old replayed response must not overwrite a later acknowledged version or pending descendant. Refresh/rebase pending bases using existing acknowledged-version machinery. Normal server updates with no local contender apply without false conflicts; known queued versions/lost acknowledgements are not new contenders.

New Prayer RPC resolves equal timestamps itself; return DispatchAcknowledged only after durable local outcome handling. Existing domains keep their current generic equal-timestamp behavior. Visible conflict UI reads conflict_records, not a coordinator summary count.

## Reads, pagination and isolation

Separate owner-scoped readers use bounded keyset pages per synchronization pass:
- reports: stable report_id ordering;
- awards: prayer_done only, stable source_id ordering;
- retained conflicts: stable conflict_id ordering.

Begin each pass from the start of that owner's key range; retry a failed page without advancing its in-memory cursor. This deliberately follows the existing snapshot-sync approach rather than introducing an incomplete incremental cursor. A mutable client updated_at is not a safe high-water mark: an equal-timestamp resolved change could otherwise be skipped. An insertion/update behind a page cursor is picked up by the next pass; convergence tests finish concurrent writes before the final repeated pass. No offset pagination, durable cross-owner cursor or scan on countdown ticks. Delta-sync optimization stays in the recorded later sync-hardening work.

RLS filters every exposed row to auth.uid(); readers additionally validate returned owner. No cloud device-preference endpoint. Pending/reset records are retained, so no physical-delete/tombstone protocol is needed for ordinary report changes.

## Required proofs

- Anonymous denial, foreign-owner read/mutation denial, malformed inputs, missing function/schema mismatch is recoverable (no silent legacy fallback).
- Matching base update creates zero conflicts; divergent/equal versions create one visible stable conflict independent of arrival direction.
- Different prayers survive concurrent offline edits; same prayer first insert is serialized.
- Complete→reset before first sync still retains one award; on-time/late concurrent devices settle to one10-or5 canonical award.
- Exact operation replay, changed-operation-ID content rejection, lost ACK, restart, duplicate inbound and stale receipt against a newer descendant.
- Client cannot choose XP/source/owner; existing Task20 awards remain readable and unchanged.
- Retained conflict becomes visible on a third/fresh device. No state leaks after owner change.
