-- 009 Adhkar and Qiyam: catalog seed, record tables, typed RPCs with
-- receipts, conflicts, and the server-derived XP awards. Pattern follows
-- 0015_prayer_reports_and_rewards.sql; identities use the shared 009
-- namespace (research.md R6): 70ca78e3-a267-4a2f-883f-1e0dea2df0c3.
--
-- The v1 catalog seed carries IDs, lists, positions and targets only (never
-- text). If the owner's content review changes a target, catalog v2 adds a
-- new seed; recorded days stay valid against the version they were made
-- against. A direct client write is denied everywhere.
begin;

create schema if not exists extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Catalog (reference data, read-only to clients)
-- ---------------------------------------------------------------------------

create table public.adhkar_catalog_items (
  catalog_version integer not null check (catalog_version >= 1),
  item_id text not null check (pg_catalog.btrim(item_id) <> ''),
  list text not null check (list in ('morning','evening')),
  position integer not null check (position >= 1),
  target integer not null check (target >= 1),
  primary key (catalog_version,item_id),
  unique (catalog_version,list,position)
);

insert into public.adhkar_catalog_items(catalog_version,item_id,list,position,target)
values
  (1,'m1','morning',1,1),
  (1,'m2','morning',2,1),
  (1,'m3','morning',3,1),
  (1,'m4','morning',4,3),
  (1,'m5','morning',5,3),
  (1,'m6','morning',6,3),
  (1,'m7','morning',7,7),
  (1,'m8','morning',8,100),
  (1,'m9','morning',9,10),
  (1,'m10','morning',10,100),
  (1,'e1','evening',1,1),
  (1,'e2','evening',2,1),
  (1,'e3','evening',3,1),
  (1,'e4','evening',4,3),
  (1,'e5','evening',5,3),
  (1,'e6','evening',6,3),
  (1,'e7','evening',7,7),
  (1,'e8','evening',8,100),
  (1,'e9','evening',9,10);

-- ---------------------------------------------------------------------------
-- Records
-- ---------------------------------------------------------------------------

create table public.adhkar_item_counts (
  owner uuid not null references auth.users(id) on delete cascade,
  adhkar_day date not null,
  item_id text not null,
  record_id uuid not null,
  catalog_version integer not null,
  list text not null check (list in ('morning','evening')),
  count integer not null check (count >= 0),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  last_acknowledged_updated_at timestamptz,
  primary key (owner,adhkar_day,item_id),
  unique (owner,record_id),
  check (created_at <= updated_at),
  -- The item must exist in the recorded catalog version and the count must
  -- never exceed that version's target. Table checks cannot hold a subquery,
  -- so the pair is enforced by the RPC's validation step (T017 proves it).
  check (count <= 100000)
);
create index adhkar_item_counts_owner_day_list_idx
  on public.adhkar_item_counts(owner,adhkar_day,list);
create index adhkar_item_counts_owner_version_idx
  on public.adhkar_item_counts(owner,updated_at,record_id);

create table public.qiyam_nights (
  owner uuid not null references auth.users(id) on delete cascade,
  night_date date not null,
  record_id uuid not null,
  performed boolean not null,
  rakahs integer,
  witr boolean not null default false,
  start_time text,
  end_time text,
  note text,
  recorded_zone_id text not null check (pg_catalog.btrim(recorded_zone_id) <> ''),
  recorded_offset_minutes integer not null check (recorded_offset_minutes between -1080 and 1080),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  last_acknowledged_updated_at timestamptz,
  primary key (owner,night_date),
  unique (owner,record_id),
  check (created_at <= updated_at),
  check (rakahs is null or rakahs in (2,4,8,11)),
  check (performed or (rakahs is null and witr = false and start_time is null
    and end_time is null and note is null)),
  check (not performed or rakahs is not null),
  check (start_time is null or start_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
  check (end_time is null or end_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
  check (note is null or pg_catalog.length(note) <= 500)
);
create index qiyam_nights_owner_night_idx
  on public.qiyam_nights(owner,night_date desc);
create index qiyam_nights_owner_version_idx
  on public.qiyam_nights(owner,updated_at,record_id);

-- ---------------------------------------------------------------------------
-- Receipts and conflicts (internal to the RPCs; owners read conflicts)
-- ---------------------------------------------------------------------------

create table public.adhkar_operation_receipts (
  owner uuid not null references auth.users(id) on delete cascade,
  operation_id text not null check (pg_catalog.btrim(operation_id) <> ''),
  record_id uuid not null,
  request_fingerprint text not null,
  outcome jsonb not null,
  applied_at timestamptz not null default pg_catalog.now(),
  primary key (owner,operation_id)
);
create index adhkar_receipts_record_idx
  on public.adhkar_operation_receipts(owner,record_id,applied_at);

create table public.qiyam_operation_receipts (
  owner uuid not null references auth.users(id) on delete cascade,
  operation_id text not null check (pg_catalog.btrim(operation_id) <> ''),
  record_id uuid not null,
  request_fingerprint text not null,
  outcome jsonb not null,
  applied_at timestamptz not null default pg_catalog.now(),
  primary key (owner,operation_id)
);
create index qiyam_receipts_record_idx
  on public.qiyam_operation_receipts(owner,record_id,applied_at);

create table public.adhkar_conflicts (
  owner uuid not null references auth.users(id) on delete cascade,
  conflict_id uuid not null,
  record_id uuid not null,
  adhkar_day date not null,
  item_id text not null,
  active_record jsonb not null,
  retained_record jsonb not null,
  detected_at timestamptz not null default pg_catalog.now(),
  primary key (owner,conflict_id),
  check (pg_catalog.jsonb_typeof(active_record) = 'object'),
  check (pg_catalog.jsonb_typeof(retained_record) = 'object')
);
create index adhkar_conflicts_owner_record_idx
  on public.adhkar_conflicts(owner,record_id,conflict_id);

create table public.qiyam_conflicts (
  owner uuid not null references auth.users(id) on delete cascade,
  conflict_id uuid not null,
  record_id uuid not null,
  night_date date not null,
  active_record jsonb not null,
  retained_record jsonb not null,
  detected_at timestamptz not null default pg_catalog.now(),
  primary key (owner,conflict_id),
  check (pg_catalog.jsonb_typeof(active_record) = 'object'),
  check (pg_catalog.jsonb_typeof(retained_record) = 'object')
);
create index qiyam_conflicts_owner_record_idx
  on public.qiyam_conflicts(owner,record_id,conflict_id);

-- ---------------------------------------------------------------------------
-- RLS and grants
-- ---------------------------------------------------------------------------

alter table public.adhkar_catalog_items enable row level security;
alter table public.adhkar_item_counts enable row level security;
alter table public.qiyam_nights enable row level security;
alter table public.adhkar_operation_receipts enable row level security;
alter table public.qiyam_operation_receipts enable row level security;
alter table public.adhkar_conflicts enable row level security;
alter table public.qiyam_conflicts enable row level security;

revoke all on public.adhkar_catalog_items from public,anon,authenticated;
revoke all on public.adhkar_item_counts from public,anon,authenticated;
revoke all on public.qiyam_nights from public,anon,authenticated;
revoke all on public.adhkar_operation_receipts from public,anon,authenticated;
revoke all on public.qiyam_operation_receipts from public,anon,authenticated;
revoke all on public.adhkar_conflicts from public,anon,authenticated;
revoke all on public.qiyam_conflicts from public,anon,authenticated;

grant select on public.adhkar_catalog_items to authenticated;
create policy adhkar_catalog_read on public.adhkar_catalog_items
  for select to authenticated using (true);
grant select on public.adhkar_item_counts,public.qiyam_nights,
  public.adhkar_conflicts,public.qiyam_conflicts to authenticated;
create policy adhkar_counts_owner_select on public.adhkar_item_counts
  for select to authenticated using (owner = (select auth.uid()));
create policy qiyam_nights_owner_select on public.qiyam_nights
  for select to authenticated using (owner = (select auth.uid()));
create policy adhkar_conflicts_owner_select on public.adhkar_conflicts
  for select to authenticated using (owner = (select auth.uid()));
create policy qiyam_conflicts_owner_select on public.qiyam_conflicts
  for select to authenticated using (owner = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Identity helpers (shared with the Dart adapters and the test vectors)
-- ---------------------------------------------------------------------------

create function public.adhkar_record_id_v1(p_day date,p_item text)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'adhkar-item/' || pg_catalog.to_char(p_day,'YYYY-MM-DD') || '/' || p_item);
$$;

create function public.qiyam_record_id_v1(p_night date)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'qiyam/' || pg_catalog.to_char(p_night,'YYYY-MM-DD'));
$$;

create function public.adhkar_set_source_id_v1(p_day date,p_list text)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'adhkar/' || pg_catalog.to_char(p_day,'YYYY-MM-DD') || '/' || p_list);
$$;

-- Version descriptors are canonical ASCII shared with clients and sorted
-- bytewise so equal-timestamp arrivals choose alike. The note component is
-- its sha256 hex digest (pgcrypto), so raw notes never enter the descriptor.
create function public.adhkar_version_descriptor_v1(
  p_updated_at timestamptz,p_count integer)
returns text language sql immutable security invoker set search_path = '' as $$
  select (extract(epoch from p_updated_at) * 1000000)::bigint::text
    || ':' || p_count::text;
$$;

create function public.qiyam_version_descriptor_v1(
  p_updated_at timestamptz,p_performed boolean,p_rakahs integer,p_witr boolean,
  p_start text,p_end text,p_note text,p_zone text,p_offset integer)
returns text language sql immutable security invoker set search_path = '' as $$
  select (extract(epoch from p_updated_at) * 1000000)::bigint::text
    || ':' || p_performed::text
    || '|' || coalesce(p_rakahs::text,'null')
    || '|' || p_witr::text
    || '|' || coalesce(p_start,'null')
    || '|' || coalesce(p_end,'null')
    || '|' || coalesce(pg_catalog.encode(extensions.digest(p_note,'sha256'),'hex'),'null')
    || '|' || p_zone || '|' || p_offset::text;
$$;

create function public.adhkar_conflict_id_v1(
  p_record_id uuid,p_first text,p_second text)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'conflict/' || p_record_id::text || '/'
      || least(p_first collate "C",p_second collate "C") || '/'
      || greatest(p_first collate "C",p_second collate "C"));
$$;

-- ---------------------------------------------------------------------------
-- apply_adhkar_item_change_v1
-- ---------------------------------------------------------------------------

create function public.apply_adhkar_item_change_v1(
  p_adhkar_day date,p_item_id text,p_catalog_version integer,p_count integer,
  p_updated_at timestamptz,p_base_updated_at timestamptz,p_operation_id text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_list text;
  v_target integer;
  v_record_id uuid;
  v_receipt public.adhkar_operation_receipts%rowtype;
  v_existing public.adhkar_item_counts%rowtype;
  v_active public.adhkar_item_counts%rowtype;
  v_request_fingerprint text;
  v_incoming_descriptor text;
  v_existing_descriptor text;
  v_conflict_id uuid;
  v_detected_at timestamptz;
  v_retained jsonb;
  v_active_json jsonb;
  v_award public.xp_awards%rowtype;
  v_set_complete boolean;
  v_outcome jsonb;
  v_divergent boolean;
  v_incoming_wins boolean;
begin
  if v_owner is null then
    raise exception using errcode='42501',message='Not authenticated';
  end if;
  if p_adhkar_day is null or p_item_id is null
    or pg_catalog.btrim(p_item_id) = ''
    or p_catalog_version is null or p_count is null or p_count < 0
    or p_updated_at is null
    or p_operation_id is null or pg_catalog.btrim(p_operation_id) = ''
    or pg_catalog.length(p_operation_id) > 128 then
    raise exception using errcode='22023',message='Invalid Adhkar item operation';
  end if;
  -- Days more than two days ahead are rejected; past days may arrive later
  -- because of offline use.
  if p_adhkar_day > (pg_catalog.now() at time zone 'UTC')::date + 2 then
    raise exception using errcode='22023',
      message='Adhkar day more than two days ahead';
  end if;
  select c.list,c.target into v_list,v_target
    from public.adhkar_catalog_items c
    where c.catalog_version = p_catalog_version and c.item_id = p_item_id;
  if not found then
    raise exception using errcode='22023',message='Unknown Adhkar catalog item';
  end if;
  if p_count > v_target then
    raise exception using errcode='22023',message='Count above catalog target';
  end if;
  v_record_id := public.adhkar_record_id_v1(p_adhkar_day,p_item_id);
  v_incoming_descriptor := public.adhkar_version_descriptor_v1(
    p_updated_at,p_count);
  v_request_fingerprint := pg_catalog.md5(v_record_id::text || ':'
    || pg_catalog.to_char(p_adhkar_day,'YYYY-MM-DD') || ':' || p_item_id || ':'
    || p_catalog_version::text || ':' || v_incoming_descriptor);

  -- Operation and record locks cover absent first inserts as well.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':adhkar-op:' || p_operation_id,0));
  select * into v_receipt from public.adhkar_operation_receipts r
    where r.owner=v_owner and r.operation_id=p_operation_id;
  if found then
    if v_receipt.request_fingerprint <> v_request_fingerprint then
      raise exception using errcode='22023',
        message='Adhkar operation ID reused with different content';
    end if;
    return v_receipt.outcome || '{"replayed":true}'::jsonb;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':adhkar-record:' || v_record_id::text,0));
  select * into v_existing from public.adhkar_item_counts r
    where r.owner=v_owner and r.record_id=v_record_id for update;
  if found then
    v_existing_descriptor := public.adhkar_version_descriptor_v1(
      v_existing.updated_at,v_existing.count);
    v_divergent := v_existing.count is distinct from p_count
      or v_existing.catalog_version is distinct from p_catalog_version;
    v_incoming_wins := p_updated_at > v_existing.updated_at
      or (p_updated_at = v_existing.updated_at
        and v_incoming_descriptor collate "C" > v_existing_descriptor collate "C");
    if v_divergent and v_existing.updated_at is distinct from p_base_updated_at then
      v_conflict_id := public.adhkar_conflict_id_v1(
        v_record_id,v_existing_descriptor,v_incoming_descriptor);
      if v_incoming_wins then
        v_retained := pg_catalog.to_jsonb(v_existing) - 'owner';
      else
        v_retained := pg_catalog.jsonb_build_object(
          'record_id',v_record_id,'adhkar_day',p_adhkar_day,
          'item_id',p_item_id,'catalog_version',p_catalog_version,
          'list',v_list,'count',p_count,
          'created_at',coalesce(p_base_updated_at,p_updated_at),
          'updated_at',p_updated_at);
      end if;
    end if;
    if v_incoming_wins then
      update public.adhkar_item_counts r set count=p_count,
        catalog_version=p_catalog_version,updated_at=p_updated_at
        where r.owner=v_owner and r.record_id=v_record_id
        returning * into v_active;
    else
      v_active := v_existing;
    end if;
  else
    if p_base_updated_at is not null then
      raise exception using errcode='22023',message='Unknown Adhkar base version';
    end if;
    insert into public.adhkar_item_counts(owner,adhkar_day,item_id,record_id,
      catalog_version,list,count,created_at,updated_at)
    values(v_owner,p_adhkar_day,p_item_id,v_record_id,p_catalog_version,
      v_list,p_count,p_updated_at,p_updated_at) returning * into v_active;
  end if;

  v_active_json := pg_catalog.to_jsonb(v_active) - 'owner';
  if v_conflict_id is not null then
    insert into public.adhkar_conflicts(owner,conflict_id,record_id,adhkar_day,
      item_id,active_record,retained_record)
    values(v_owner,v_conflict_id,v_record_id,p_adhkar_day,p_item_id,
      v_active_json,v_retained)
    on conflict(owner,conflict_id) do nothing;
    select c.detected_at into v_detected_at from public.adhkar_conflicts c
      where c.owner=v_owner and c.conflict_id=v_conflict_id;
  end if;

  -- Server-derived set completion: every catalog item of this list and
  -- version for the owner/day sits at its target in the active versions.
  select not exists (
    select 1 from public.adhkar_catalog_items c
    where c.catalog_version = p_catalog_version
      and c.list = v_list
      and c.target > coalesce((select r.count
          from public.adhkar_item_counts r
          where r.owner=v_owner and r.adhkar_day=p_adhkar_day
            and r.catalog_version=p_catalog_version and r.item_id=c.item_id),0)
  ) into v_set_complete;
  if v_set_complete then
    insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
    values(v_owner,'adhkar_set_done',
      public.adhkar_set_source_id_v1(p_adhkar_day,v_list),15,p_updated_at)
    on conflict(owner,source,source_id) do nothing;
  end if;
  select * into v_award from public.xp_awards a
    where a.owner=v_owner and a.source='adhkar_set_done'
      and a.source_id=public.adhkar_set_source_id_v1(p_adhkar_day,v_list);
  v_outcome := pg_catalog.jsonb_build_object(
    'owner',v_owner,'operation_id',p_operation_id,'record_id',v_record_id,
    'adhkar_day',p_adhkar_day,'item_id',p_item_id,
    'active_record',v_active_json,'active_version',v_active.updated_at,
    'conflict_id',v_conflict_id,'retained_record',v_retained,
    'detected_at',v_detected_at,
    'canonical_award',case when v_award.owner is null then null
      else pg_catalog.jsonb_build_object('source','adhkar_set_done',
        'source_id',v_award.source_id,'amount',v_award.amount,
        'awarded_at',v_award.awarded_at) end,
    'replayed',false);
  insert into public.adhkar_operation_receipts(owner,operation_id,record_id,
    request_fingerprint,outcome)
  values(v_owner,p_operation_id,v_record_id,v_request_fingerprint,v_outcome);
  return v_outcome;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_qiyam_night_change_v1
-- ---------------------------------------------------------------------------

create function public.apply_qiyam_night_change_v1(
  p_night_date date,p_performed boolean,p_rakahs integer,p_witr boolean,
  p_start_time text,p_end_time text,p_note text,p_recorded_zone_id text,
  p_recorded_offset_minutes integer,p_updated_at timestamptz,
  p_base_updated_at timestamptz,p_operation_id text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_record_id uuid;
  v_receipt public.qiyam_operation_receipts%rowtype;
  v_existing public.qiyam_nights%rowtype;
  v_active public.qiyam_nights%rowtype;
  v_request_fingerprint text;
  v_incoming_descriptor text;
  v_existing_descriptor text;
  v_conflict_id uuid;
  v_detected_at timestamptz;
  v_retained jsonb;
  v_active_json jsonb;
  v_award public.xp_awards%rowtype;
  v_outcome jsonb;
  v_divergent boolean;
  v_incoming_wins boolean;
begin
  if v_owner is null then
    raise exception using errcode='42501',message='Not authenticated';
  end if;
  if p_night_date is null or p_performed is null or p_witr is null
    or p_updated_at is null
    or p_recorded_zone_id is null
    or pg_catalog.btrim(p_recorded_zone_id) = ''
    or p_recorded_zone_id like '%|%'
    or p_recorded_offset_minutes is null
    or p_recorded_offset_minutes not between -1080 and 1080
    or p_operation_id is null or pg_catalog.btrim(p_operation_id) = ''
    or pg_catalog.length(p_operation_id) > 128
    or (p_rakahs is not null and p_rakahs not in (2,4,8,11))
    or (p_start_time is not null
        and p_start_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
    or (p_end_time is not null
        and p_end_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
    or (p_note is not null and pg_catalog.length(p_note) > 500)
    or (not p_performed
        and (p_rakahs is not null or p_witr
          or p_start_time is not null or p_end_time is not null
          or p_note is not null))
    or (p_performed and p_rakahs is null) then
    raise exception using errcode='22023',message='Invalid Qiyam night operation';
  end if;
  if p_night_date > (pg_catalog.now() at time zone 'UTC')::date + 2 then
    raise exception using errcode='22023',
      message='Qiyam night more than two days ahead';
  end if;
  v_record_id := public.qiyam_record_id_v1(p_night_date);
  v_incoming_descriptor := public.qiyam_version_descriptor_v1(
    p_updated_at,p_performed,p_rakahs,p_witr,p_start_time,p_end_time,p_note,
    p_recorded_zone_id,p_recorded_offset_minutes);
  v_request_fingerprint := pg_catalog.md5(v_record_id::text || ':'
    || pg_catalog.to_char(p_night_date,'YYYY-MM-DD') || ':'
    || v_incoming_descriptor);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':qiyam-op:' || p_operation_id,0));
  select * into v_receipt from public.qiyam_operation_receipts r
    where r.owner=v_owner and r.operation_id=p_operation_id;
  if found then
    if v_receipt.request_fingerprint <> v_request_fingerprint then
      raise exception using errcode='22023',
        message='Qiyam operation ID reused with different content';
    end if;
    return v_receipt.outcome || '{"replayed":true}'::jsonb;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':qiyam-record:' || v_record_id::text,0));
  select * into v_existing from public.qiyam_nights r
    where r.owner=v_owner and r.record_id=v_record_id for update;
  if found then
    v_existing_descriptor := public.qiyam_version_descriptor_v1(
      v_existing.updated_at,v_existing.performed,v_existing.rakahs,
      v_existing.witr,v_existing.start_time,v_existing.end_time,
      v_existing.note,v_existing.recorded_zone_id,
      v_existing.recorded_offset_minutes);
    v_divergent := v_existing.performed is distinct from p_performed
      or v_existing.rakahs is distinct from p_rakahs
      or v_existing.witr is distinct from p_witr
      or v_existing.start_time is distinct from p_start_time
      or v_existing.end_time is distinct from p_end_time
      or v_existing.note is distinct from p_note
      or v_existing.recorded_zone_id is distinct from p_recorded_zone_id
      or v_existing.recorded_offset_minutes is distinct from p_recorded_offset_minutes;
    v_incoming_wins := p_updated_at > v_existing.updated_at
      or (p_updated_at = v_existing.updated_at
        and v_incoming_descriptor collate "C" > v_existing_descriptor collate "C");
    if v_divergent and v_existing.updated_at is distinct from p_base_updated_at then
      v_conflict_id := public.adhkar_conflict_id_v1(
        v_record_id,v_existing_descriptor,v_incoming_descriptor);
      if v_incoming_wins then
        v_retained := pg_catalog.to_jsonb(v_existing) - 'owner';
      else
        v_retained := pg_catalog.jsonb_build_object(
          'record_id',v_record_id,'night_date',p_night_date,
          'performed',p_performed,'rakahs',p_rakahs,'witr',p_witr,
          'start_time',p_start_time,'end_time',p_end_time,'note',p_note,
          'recorded_zone_id',p_recorded_zone_id,
          'recorded_offset_minutes',p_recorded_offset_minutes,
          'created_at',coalesce(p_base_updated_at,p_updated_at),
          'updated_at',p_updated_at);
      end if;
    end if;
    if v_incoming_wins then
      update public.qiyam_nights r set performed=p_performed,rakahs=p_rakahs,
        witr=p_witr,start_time=p_start_time,end_time=p_end_time,note=p_note,
        recorded_zone_id=p_recorded_zone_id,
        recorded_offset_minutes=p_recorded_offset_minutes,
        updated_at=p_updated_at
        where r.owner=v_owner and r.record_id=v_record_id
        returning * into v_active;
    else
      v_active := v_existing;
    end if;
  else
    if p_base_updated_at is not null then
      raise exception using errcode='22023',message='Unknown Qiyam base version';
    end if;
    insert into public.qiyam_nights(owner,night_date,record_id,performed,
      rakahs,witr,start_time,end_time,note,recorded_zone_id,
      recorded_offset_minutes,created_at,updated_at)
    values(v_owner,p_night_date,v_record_id,p_performed,p_rakahs,
      coalesce(p_witr,false),p_start_time,p_end_time,p_note,
      p_recorded_zone_id,p_recorded_offset_minutes,p_updated_at,p_updated_at)
    returning * into v_active;
  end if;

  v_active_json := pg_catalog.to_jsonb(v_active) - 'owner';
  if v_conflict_id is not null then
    insert into public.qiyam_conflicts(owner,conflict_id,record_id,night_date,
      active_record,retained_record)
    values(v_owner,v_conflict_id,v_record_id,p_night_date,v_active_json,
      v_retained)
    on conflict(owner,conflict_id) do nothing;
    select c.detected_at into v_detected_at from public.qiyam_conflicts c
      where c.owner=v_owner and c.conflict_id=v_conflict_id;
  end if;

  -- The first server-committed performed version wins the award, even when
  -- its snapshot loses to a newer "No". Awards are never revoked.
  if p_performed then
    insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
    values(v_owner,'qiyam_done',v_record_id,30,p_updated_at)
    on conflict(owner,source,source_id) do nothing;
  end if;
  select * into v_award from public.xp_awards a
    where a.owner=v_owner and a.source='qiyam_done' and a.source_id=v_record_id;
  v_outcome := pg_catalog.jsonb_build_object(
    'owner',v_owner,'operation_id',p_operation_id,'record_id',v_record_id,
    'night_date',p_night_date,
    'active_record',v_active_json,'active_version',v_active.updated_at,
    'conflict_id',v_conflict_id,'retained_record',v_retained,
    'detected_at',v_detected_at,
    'canonical_award',case when v_award.owner is null then null
      else pg_catalog.jsonb_build_object('source','qiyam_done',
        'source_id',v_award.source_id,'amount',v_award.amount,
        'awarded_at',v_award.awarded_at) end,
    'replayed',false);
  insert into public.qiyam_operation_receipts(owner,operation_id,record_id,
    request_fingerprint,outcome)
  values(v_owner,p_operation_id,v_record_id,v_request_fingerprint,v_outcome);
  return v_outcome;
end;
$$;

-- ---------------------------------------------------------------------------
-- Function grants: authenticated execution only, no anon, no public
-- ---------------------------------------------------------------------------

revoke all on function public.adhkar_record_id_v1(date,text) from public,anon;
revoke all on function public.qiyam_record_id_v1(date) from public,anon;
revoke all on function public.adhkar_set_source_id_v1(date,text) from public,anon;
revoke all on function public.adhkar_version_descriptor_v1(timestamptz,integer) from public,anon;
revoke all on function public.qiyam_version_descriptor_v1(
  timestamptz,boolean,integer,boolean,text,text,text,text,integer) from public,anon;
revoke all on function public.adhkar_conflict_id_v1(uuid,text,text) from public,anon;
revoke all on function public.apply_adhkar_item_change_v1(
  date,text,integer,integer,timestamptz,timestamptz,text) from public,anon;
revoke all on function public.apply_qiyam_night_change_v1(
  date,boolean,integer,boolean,text,text,text,text,integer,
  timestamptz,timestamptz,text) from public,anon;

grant execute on function public.adhkar_record_id_v1(date,text) to authenticated;
grant execute on function public.qiyam_record_id_v1(date) to authenticated;
grant execute on function public.adhkar_set_source_id_v1(date,text) to authenticated;
grant execute on function public.adhkar_version_descriptor_v1(
  timestamptz,integer) to authenticated;
grant execute on function public.qiyam_version_descriptor_v1(
  timestamptz,boolean,integer,boolean,text,text,text,text,integer) to authenticated;
grant execute on function public.adhkar_conflict_id_v1(uuid,text,text) to authenticated;
grant execute on function public.apply_adhkar_item_change_v1(
  date,text,integer,integer,timestamptz,timestamptz,text) to authenticated;
grant execute on function public.apply_qiyam_night_change_v1(
  date,boolean,integer,boolean,text,text,text,text,integer,
  timestamptz,timestamptz,text) to authenticated;

notify pgrst,'reload schema';
commit;
