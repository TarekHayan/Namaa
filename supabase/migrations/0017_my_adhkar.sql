-- 009 My Adhkar (Story 5, reshaped 2026-11-16): the user's personal
-- collection of named groups and two-field entries (text + optional
-- source). Typed RPCs with receipts and conflicts, the server-side group
-- delete cascade, and NO counter, count table or XP write anywhere.
-- Additive on 0016_adhkar_qiyam.sql: the conflict IDs reuse its shared
-- namespace helper adhkar_qiyam_conflict_id_v1 (research.md R6).
--
-- Lengths are counted in code points (char_length on the trimmed text),
-- matching the client's runes.length. All timestamps carry the newest-wins
-- rule with the descriptor tie-break from data-model.md. A delete is final:
-- it wins over a live version whatever the timestamps, and a later edit or
-- rename of a deleted record is kept as a conflict and never applied.
-- A direct client write is denied everywhere.
begin;

-- ---------------------------------------------------------------------------
-- Records
-- ---------------------------------------------------------------------------

create table public.my_adhkar_groups (
  owner uuid not null references auth.users(id) on delete cascade,
  group_id uuid not null,
  name text not null check (pg_catalog.btrim(name) <> ''
    and pg_catalog.char_length(pg_catalog.btrim(name)) <= 60),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner,group_id),
  check (created_at <= updated_at)
);
create index my_adhkar_groups_owner_tab_idx
  on public.my_adhkar_groups(owner,deleted_at,created_at);
create index my_adhkar_groups_owner_version_idx
  on public.my_adhkar_groups(owner,updated_at,group_id);

create table public.my_adhkar_items (
  owner uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null,
  text text not null check (pg_catalog.btrim(text) <> ''
    and pg_catalog.char_length(pg_catalog.btrim(text)) <= 2000),
  source text check (source is null
    or (pg_catalog.btrim(source) <> ''
      and pg_catalog.char_length(pg_catalog.btrim(source)) <= 500)),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner,item_id),
  check (created_at <= updated_at)
);
create index my_adhkar_items_owner_tab_idx
  on public.my_adhkar_items(owner,deleted_at,created_at);
create index my_adhkar_items_owner_version_idx
  on public.my_adhkar_items(owner,updated_at,item_id);

-- The membership join. The entry and the group belong to the same owner;
-- added_at is the entry's order inside that group and is kept when the
-- entry is saved again with the same group. Memberships travel inside the
-- entry change (p_group_ids), never as a separate entity.
create table public.my_adhkar_item_groups (
  owner uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null,
  group_id uuid not null,
  added_at timestamptz not null,
  primary key (owner,item_id,group_id),
  foreign key (owner,item_id) references public.my_adhkar_items(owner,item_id)
    on delete cascade,
  foreign key (owner,group_id) references public.my_adhkar_groups(owner,group_id)
    on delete cascade
);
create index my_adhkar_item_groups_owner_group_idx
  on public.my_adhkar_item_groups(owner,group_id,added_at);

-- ---------------------------------------------------------------------------
-- Receipts and conflicts (internal to the RPCs; owners read conflicts)
-- ---------------------------------------------------------------------------

create table public.my_adhkar_operation_receipts (
  owner uuid not null references auth.users(id) on delete cascade,
  operation_id text not null check (pg_catalog.btrim(operation_id) <> ''),
  record_id uuid not null,
  request_fingerprint text not null,
  outcome jsonb not null,
  applied_at timestamptz not null default pg_catalog.now(),
  primary key (owner,operation_id)
);
create index my_adhkar_receipts_record_idx
  on public.my_adhkar_operation_receipts(owner,record_id,applied_at);

create table public.my_adhkar_conflicts (
  owner uuid not null references auth.users(id) on delete cascade,
  conflict_id uuid not null,
  entity_type text not null check (entity_type in ('group','item')),
  entity_id uuid not null,
  active_record jsonb not null,
  retained_record jsonb not null,
  detected_at timestamptz not null default pg_catalog.now(),
  primary key (owner,conflict_id),
  check (pg_catalog.jsonb_typeof(active_record) = 'object'),
  check (pg_catalog.jsonb_typeof(retained_record) = 'object')
);
create index my_adhkar_conflicts_owner_entity_idx
  on public.my_adhkar_conflicts(owner,entity_type,entity_id,conflict_id);

-- ---------------------------------------------------------------------------
-- RLS and grants
-- ---------------------------------------------------------------------------

alter table public.my_adhkar_groups enable row level security;
alter table public.my_adhkar_items enable row level security;
alter table public.my_adhkar_item_groups enable row level security;
alter table public.my_adhkar_operation_receipts enable row level security;
alter table public.my_adhkar_conflicts enable row level security;

revoke all on public.my_adhkar_groups from public,anon,authenticated;
revoke all on public.my_adhkar_items from public,anon,authenticated;
revoke all on public.my_adhkar_item_groups from public,anon,authenticated;
revoke all on public.my_adhkar_operation_receipts from public,anon,authenticated;
revoke all on public.my_adhkar_conflicts from public,anon,authenticated;

grant select on public.my_adhkar_groups,public.my_adhkar_items,
  public.my_adhkar_item_groups,public.my_adhkar_conflicts to authenticated;
create policy my_adhkar_groups_owner_select on public.my_adhkar_groups
  for select to authenticated using (owner = (select auth.uid()));
create policy my_adhkar_items_owner_select on public.my_adhkar_items
  for select to authenticated using (owner = (select auth.uid()));
create policy my_adhkar_item_groups_owner_select
  on public.my_adhkar_item_groups
  for select to authenticated using (owner = (select auth.uid()));
create policy my_adhkar_conflicts_owner_select on public.my_adhkar_conflicts
  for select to authenticated using (owner = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Version descriptors (canonical ASCII, data-model.md, shared with the
-- conflict-ID helper from 0016). Raw text never enters a descriptor.
-- ---------------------------------------------------------------------------

create function public.my_adhkar_group_descriptor_v1(
  p_updated_at timestamptz,p_deleted boolean,p_name text)
returns text language sql immutable security invoker set search_path = '' as $$
  -- '<updated_at micros>:<deleted>|<name-sha256>'
  select (extract(epoch from p_updated_at) * 1000000)::bigint::text
    || ':' || p_deleted::text
    || '|' || coalesce(pg_catalog.encode(extensions.digest(p_name,'sha256'),'hex'),'null');
$$;

create function public.my_adhkar_item_descriptor_v1(
  p_updated_at timestamptz,p_deleted boolean,p_text text,p_source text,
  p_group_ids uuid[])
returns text language sql immutable security invoker set search_path = '' as $$
  -- '<updated_at micros>:<deleted>|<text-sha256>|<source-sha256>|
  --  <sorted-group-ids-sha256>': the sorted group ids make the membership
  -- set part of the version whatever order was submitted.
  select (extract(epoch from p_updated_at) * 1000000)::bigint::text
    || ':' || p_deleted::text
    || '|' || coalesce(pg_catalog.encode(extensions.digest(p_text,'sha256'),'hex'),'null')
    || '|' || coalesce(pg_catalog.encode(extensions.digest(p_source,'sha256'),'hex'),'null')
    || '|' || coalesce(pg_catalog.encode(extensions.digest(
         (select pg_catalog.string_agg(g::text,',' order by g)
            from unnest(p_group_ids) as g),'sha256'),'hex'),'null');
$$;

-- ---------------------------------------------------------------------------
-- apply_my_adhkar_group_change_v1
-- ---------------------------------------------------------------------------

create function public.apply_my_adhkar_group_change_v1(
  p_group_id uuid,p_name text,p_created_at timestamptz,p_deleted boolean,
  p_updated_at timestamptz,p_base_updated_at timestamptz,p_operation_id text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_name text;
  v_receipt public.my_adhkar_operation_receipts%rowtype;
  v_existing public.my_adhkar_groups%rowtype;
  v_active public.my_adhkar_groups%rowtype;
  v_request_fingerprint text;
  v_incoming_descriptor text;
  v_existing_descriptor text;
  v_conflict_id uuid;
  v_detected_at timestamptz;
  v_retained jsonb;
  v_active_json jsonb;
  v_outcome jsonb;
  v_new_updated timestamptz;
  v_incoming_wins boolean;
  v_cascaded integer := 0;
begin
  if v_owner is null then
    raise exception using errcode='42501',message='Not authenticated';
  end if;
  v_name := pg_catalog.btrim(p_name);
  if p_group_id is null or p_name is null or p_created_at is null
    or p_deleted is null or p_updated_at is null
    or p_operation_id is null or pg_catalog.btrim(p_operation_id) = ''
    or pg_catalog.length(p_operation_id) > 128
    or v_name = '' or pg_catalog.char_length(v_name) > 60
    or p_created_at > p_updated_at then
    raise exception using errcode='22023',
      message='Invalid My Adhkar group operation';
  end if;
  if p_updated_at > pg_catalog.now() + interval '2 days' then
    raise exception using errcode='22023',
      message='My Adhkar timestamp more than two days ahead';
  end if;
  v_incoming_descriptor := public.my_adhkar_group_descriptor_v1(
    p_updated_at,p_deleted,v_name);
  v_request_fingerprint := pg_catalog.md5(p_group_id::text || ':group:'
    || (extract(epoch from p_created_at) * 1000000)::bigint::text || ':'
    || v_incoming_descriptor);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':my-adhkar-op:' || p_operation_id,0));
  select * into v_receipt from public.my_adhkar_operation_receipts r
    where r.owner=v_owner and r.operation_id=p_operation_id;
  if found then
    if v_receipt.request_fingerprint <> v_request_fingerprint then
      raise exception using errcode='22023',
        message='My Adhkar operation ID reused with different content';
    end if;
    return v_receipt.outcome || '{"replayed":true}'::jsonb;
  end if;
  -- One owner-level lock orders every My Adhkar write of the account, so
  -- the limits, the cascade and the entry-to-group checks never race.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':my-adhkar',0));
  select * into v_existing from public.my_adhkar_groups r
    where r.owner=v_owner and r.group_id=p_group_id for update;

  if not found then
    if p_base_updated_at is not null then
      raise exception using errcode='22023',
        message='Unknown My Adhkar group base version';
    end if;
    -- The 100-live-group limit (limit_reached).
    if not p_deleted and (select pg_catalog.count(*)
        from public.my_adhkar_groups g
        where g.owner=v_owner and g.deleted_at is null) >= 100 then
      raise exception using errcode='22023',
        message='My Adhkar group limit reached',hint='limit_reached';
    end if;
    insert into public.my_adhkar_groups(owner,group_id,name,created_at,
      updated_at,deleted_at)
    values(v_owner,p_group_id,v_name,p_created_at,p_updated_at,
      case when p_deleted then p_updated_at end)
    returning * into v_active;
  else
    v_existing_descriptor := public.my_adhkar_group_descriptor_v1(
      v_existing.updated_at,v_existing.deleted_at is not null,v_existing.name);
    if v_existing.deleted_at is not null then
      -- A deleted group stays deleted. A later rename, newer or older, is
      -- not applied and is kept as a conflict; a repeated delete converges.
      v_active := v_existing;
      if not p_deleted then
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
          p_group_id,v_existing_descriptor,v_incoming_descriptor);
        v_retained := pg_catalog.jsonb_build_object(
          'group_id',p_group_id,'name',v_name,
          'created_at',v_existing.created_at,'updated_at',p_updated_at,
          'deleted_at',null);
      end if;
    elsif p_deleted then
      -- The delete wins over the live version whatever the timestamps; the
      -- stored version still moves forward so other devices pull it.
      v_new_updated := greatest(p_updated_at,
        v_existing.updated_at + interval '1 microsecond');
      if v_existing.updated_at is distinct from p_base_updated_at then
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
          p_group_id,v_existing_descriptor,v_incoming_descriptor);
        v_retained := pg_catalog.to_jsonb(v_existing) - 'owner';
      end if;
      update public.my_adhkar_groups r set name=v_name,
        updated_at=v_new_updated,deleted_at=v_new_updated
        where r.owner=v_owner and r.group_id=p_group_id
        returning * into v_active;
      -- The server-side group delete cascade, in this transaction: delete
      -- every live entry left with no live group (each with a new, strictly
      -- greater updated_at so other devices pull it), then drop the group
      -- from every membership. The client queues no operation for the
      -- cascaded entries, and no conflict is recorded for the cascade.
      update public.my_adhkar_items i
        set updated_at=greatest(v_new_updated,
              i.updated_at + interval '1 microsecond'),
            deleted_at=greatest(v_new_updated,
              i.updated_at + interval '1 microsecond')
        where i.owner=v_owner and i.deleted_at is null
          and exists (select 1 from public.my_adhkar_item_groups m
            where m.owner=v_owner and m.item_id=i.item_id
              and m.group_id=p_group_id)
          and not exists (select 1 from public.my_adhkar_item_groups m2
            join public.my_adhkar_groups g2 on g2.owner=m2.owner
              and g2.group_id=m2.group_id and g2.deleted_at is null
            where m2.owner=v_owner and m2.item_id=i.item_id
              and m2.group_id <> p_group_id);
      get diagnostics v_cascaded = row_count;
      delete from public.my_adhkar_item_groups m
        where m.owner=v_owner and m.group_id=p_group_id;
    else
      -- Live against live: newest wins; the equal-timestamp tie goes to the
      -- greater descriptor (byte order); a divergent version against a
      -- different base keeps the losing side as one stable conflict.
      v_incoming_wins := p_updated_at > v_existing.updated_at
        or (p_updated_at = v_existing.updated_at
          and v_incoming_descriptor collate "C" > v_existing_descriptor collate "C");
      if v_existing.name is distinct from v_name
          and v_existing.updated_at is distinct from p_base_updated_at then
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
          p_group_id,v_existing_descriptor,v_incoming_descriptor);
        if v_incoming_wins then
          v_retained := pg_catalog.to_jsonb(v_existing) - 'owner';
        else
          v_retained := pg_catalog.jsonb_build_object(
            'group_id',p_group_id,'name',v_name,
            'created_at',v_existing.created_at,'updated_at',p_updated_at,
            'deleted_at',null);
        end if;
      end if;
      if v_incoming_wins then
        update public.my_adhkar_groups r set name=v_name,updated_at=p_updated_at
          where r.owner=v_owner and r.group_id=p_group_id
          returning * into v_active;
      else
        v_active := v_existing;
      end if;
    end if;
  end if;

  v_active_json := pg_catalog.to_jsonb(v_active) - 'owner';
  if v_conflict_id is not null then
    insert into public.my_adhkar_conflicts(owner,conflict_id,entity_type,
      entity_id,active_record,retained_record)
    values(v_owner,v_conflict_id,'group',p_group_id,v_active_json,v_retained)
    on conflict(owner,conflict_id) do nothing;
    select c.detected_at into v_detected_at from public.my_adhkar_conflicts c
      where c.owner=v_owner and c.conflict_id=v_conflict_id;
  end if;

  v_outcome := pg_catalog.jsonb_build_object(
    'owner',v_owner,'operation_id',p_operation_id,'record_id',p_group_id,
    'entity_type','group',
    'active_record',v_active_json,'active_version',v_active.updated_at,
    'conflict_id',v_conflict_id,'retained_record',v_retained,
    'detected_at',v_detected_at,
    'cascaded_entries',v_cascaded,
    'replayed',false);
  insert into public.my_adhkar_operation_receipts(owner,operation_id,record_id,
    request_fingerprint,outcome)
  values(v_owner,p_operation_id,p_group_id,v_request_fingerprint,v_outcome);
  return v_outcome;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_my_adhkar_item_change_v1
-- ---------------------------------------------------------------------------

create function public.apply_my_adhkar_item_change_v1(
  p_item_id uuid,p_text text,p_source text,p_group_ids uuid[],
  p_created_at timestamptz,p_deleted boolean,p_updated_at timestamptz,
  p_base_updated_at timestamptz,p_operation_id text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_text text;
  v_source text;
  v_receipt public.my_adhkar_operation_receipts%rowtype;
  v_existing public.my_adhkar_items%rowtype;
  v_active public.my_adhkar_items%rowtype;
  v_submitted_groups uuid[];
  v_effective_groups uuid[];
  v_existing_groups uuid[] := array[]::uuid[];
  v_active_groups uuid[] := array[]::uuid[];
  v_group uuid;
  v_request_fingerprint text;
  v_submitted_descriptor text;
  v_incoming_descriptor text;
  v_existing_descriptor text;
  v_conflict_id uuid;
  v_detected_at timestamptz;
  v_retained jsonb;
  v_active_json jsonb;
  v_outcome jsonb;
  v_new_updated timestamptz;
  v_incoming_wins boolean;
  v_group_deleted boolean := false;
begin
  if v_owner is null then
    raise exception using errcode='42501',message='Not authenticated';
  end if;
  v_text := pg_catalog.btrim(p_text);
  v_source := nullif(pg_catalog.btrim(coalesce(p_source,'')),'');
  if p_item_id is null or p_text is null or p_created_at is null
    or p_deleted is null or p_updated_at is null
    or p_operation_id is null or pg_catalog.btrim(p_operation_id) = ''
    or pg_catalog.length(p_operation_id) > 128
    or v_text = '' or pg_catalog.char_length(v_text) > 2000
    or (v_source is not null and pg_catalog.char_length(v_source) > 500)
    or p_created_at > p_updated_at then
    raise exception using errcode='22023',
      message='Invalid My Adhkar item operation';
  end if;
  if p_updated_at > pg_catalog.now() + interval '2 days' then
    raise exception using errcode='22023',
      message='My Adhkar timestamp more than two days ahead';
  end if;
  -- The group set belongs to a live version only: the device removes the
  -- memberships when it deletes an entry, so a delete is accepted with an
  -- empty set and the submitted set is ignored.
  if p_deleted then
    v_submitted_groups := array[]::uuid[];
  else
    if p_group_ids is null or pg_catalog.cardinality(p_group_ids) = 0
      or (select pg_catalog.count(distinct g) from unnest(p_group_ids) as g)
        <> pg_catalog.cardinality(p_group_ids) then
      raise exception using errcode='22023',
        message='Invalid My Adhkar item operation';
    end if;
    v_submitted_groups := array(select g from unnest(p_group_ids) as g
      order by g);
    -- A group the account's server rows do not hold (not yet synced, or not
    -- the caller's) is the retryable group_missing failure: nothing is
    -- written, the change stays pending and a later pass applies it.
    foreach v_group in array v_submitted_groups loop
      if not exists (select 1 from public.my_adhkar_groups r
          where r.owner=v_owner and r.group_id=v_group) then
        raise exception using errcode='22023',
          message='My Adhkar group missing',hint='group_missing';
      end if;
    end loop;
  end if;
  v_submitted_descriptor := public.my_adhkar_item_descriptor_v1(
    p_updated_at,p_deleted,v_text,v_source,v_submitted_groups);
  v_request_fingerprint := pg_catalog.md5(p_item_id::text || ':item:'
    || (extract(epoch from p_created_at) * 1000000)::bigint::text || ':'
    || v_submitted_descriptor);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':my-adhkar-op:' || p_operation_id,0));
  select * into v_receipt from public.my_adhkar_operation_receipts r
    where r.owner=v_owner and r.operation_id=p_operation_id;
  if found then
    if v_receipt.request_fingerprint <> v_request_fingerprint then
      raise exception using errcode='22023',
        message='My Adhkar operation ID reused with different content';
    end if;
    return v_receipt.outcome || '{"replayed":true}'::jsonb;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':my-adhkar',0));

  -- Deleted groups are dropped from the submitted set (read under the
  -- owner lock, so a concurrent group delete is ordered against this call).
  v_effective_groups := array(select g from unnest(v_submitted_groups) as g
    where exists (select 1 from public.my_adhkar_groups r
      where r.owner=v_owner and r.group_id=g and r.deleted_at is null)
    order by g);
  v_incoming_descriptor := public.my_adhkar_item_descriptor_v1(
    p_updated_at,p_deleted,v_text,v_source,v_effective_groups);

  select * into v_existing from public.my_adhkar_items r
    where r.owner=v_owner and r.item_id=p_item_id for update;

  if not found then
    if p_base_updated_at is not null then
      raise exception using errcode='22023',
        message='Unknown My Adhkar item base version';
    end if;
    if p_deleted or pg_catalog.cardinality(v_effective_groups) = 0 then
      -- A tombstone from the start: either the device's own delete, or a
      -- create naming only deleted groups (group_deleted): the entry is
      -- deleted and the submitted version is kept as a conflict.
      insert into public.my_adhkar_items(owner,item_id,text,source,created_at,
        updated_at,deleted_at)
      values(v_owner,p_item_id,v_text,v_source,p_created_at,p_updated_at,
        p_updated_at)
      returning * into v_active;
      if not p_deleted then
        v_group_deleted := true;
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(p_item_id,
          v_submitted_descriptor,
          public.my_adhkar_item_descriptor_v1(p_updated_at,true,v_text,
            v_source,array[]::uuid[]));
        v_retained := pg_catalog.jsonb_build_object(
          'item_id',p_item_id,'text',v_text,'source',v_source,
          'group_ids',v_submitted_groups,'created_at',p_created_at,
          'updated_at',p_updated_at,'deleted_at',null);
      end if;
    else
      -- The 1000-live-entry limit (limit_reached).
      if (select pg_catalog.count(*) from public.my_adhkar_items i
          where i.owner=v_owner and i.deleted_at is null) >= 1000 then
        raise exception using errcode='22023',
          message='My Adhkar entry limit reached',hint='limit_reached';
      end if;
      insert into public.my_adhkar_items(owner,item_id,text,source,created_at,
        updated_at)
      values(v_owner,p_item_id,v_text,v_source,p_created_at,p_updated_at)
      returning * into v_active;
      insert into public.my_adhkar_item_groups(owner,item_id,group_id,added_at)
        select v_owner,p_item_id,g,p_created_at
        from unnest(v_effective_groups) as g;
      v_active_groups := v_effective_groups;
    end if;
  else
    select coalesce(pg_catalog.array_agg(m.group_id order by m.group_id),
        array[]::uuid[])
      into v_existing_groups
      from public.my_adhkar_item_groups m
      where m.owner=v_owner and m.item_id=p_item_id;
    v_existing_descriptor := public.my_adhkar_item_descriptor_v1(
      v_existing.updated_at,v_existing.deleted_at is not null,v_existing.text,
      v_existing.source,v_existing_groups);

    if v_existing.deleted_at is not null then
      -- A deleted entry stays deleted. A later edit, newer or older, is not
      -- applied and is kept as a conflict, whatever its base; a repeated
      -- delete converges.
      v_active := v_existing;
      if not p_deleted then
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
          p_item_id,v_existing_descriptor,v_incoming_descriptor);
        v_retained := pg_catalog.jsonb_build_object(
          'item_id',p_item_id,'text',v_text,'source',v_source,
          'group_ids',v_effective_groups,'created_at',v_existing.created_at,
          'updated_at',p_updated_at,'deleted_at',null);
      end if;
    elsif p_deleted then
      -- The delete wins over the live version whatever the timestamps; the
      -- stored version still moves forward so other devices pull it.
      v_new_updated := greatest(p_updated_at,
        v_existing.updated_at + interval '1 microsecond');
      if v_existing.updated_at is distinct from p_base_updated_at then
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
          p_item_id,v_existing_descriptor,v_incoming_descriptor);
        v_retained := pg_catalog.to_jsonb(v_existing) - 'owner'
          || pg_catalog.jsonb_build_object('group_ids',v_existing_groups);
      end if;
      update public.my_adhkar_items r set text=v_text,source=v_source,
        updated_at=v_new_updated,deleted_at=v_new_updated
        where r.owner=v_owner and r.item_id=p_item_id
        returning * into v_active;
      delete from public.my_adhkar_item_groups m
        where m.owner=v_owner and m.item_id=p_item_id;
    else
      -- Live against live: newest wins; the equal-timestamp tie goes to the
      -- greater descriptor (byte order).
      v_incoming_wins := p_updated_at > v_existing.updated_at
        or (p_updated_at = v_existing.updated_at
          and v_incoming_descriptor collate "C" > v_existing_descriptor collate "C");
      if v_incoming_wins
          and pg_catalog.cardinality(v_effective_groups) = 0 then
        -- group_deleted: every submitted group is deleted, so the entry is
        -- deleted and the submitted version is kept as a conflict, even
        -- against a matching base.
        v_group_deleted := true;
        v_new_updated := greatest(p_updated_at,
          v_existing.updated_at + interval '1 microsecond');
        v_conflict_id := public.adhkar_qiyam_conflict_id_v1(p_item_id,
          v_submitted_descriptor,
          public.my_adhkar_item_descriptor_v1(v_new_updated,true,v_text,
            v_source,array[]::uuid[]));
        v_retained := pg_catalog.jsonb_build_object(
          'item_id',p_item_id,'text',v_text,'source',v_source,
          'group_ids',v_submitted_groups,'created_at',v_existing.created_at,
          'updated_at',p_updated_at,'deleted_at',null);
        update public.my_adhkar_items r set text=v_text,source=v_source,
          updated_at=v_new_updated,deleted_at=v_new_updated
          where r.owner=v_owner and r.item_id=p_item_id
          returning * into v_active;
        delete from public.my_adhkar_item_groups m
          where m.owner=v_owner and m.item_id=p_item_id;
      else
        if (v_existing.text is distinct from v_text
            or v_existing.source is distinct from v_source
            or v_existing_groups is distinct from v_effective_groups)
          and v_existing.updated_at is distinct from p_base_updated_at then
          v_conflict_id := public.adhkar_qiyam_conflict_id_v1(
            p_item_id,v_existing_descriptor,v_incoming_descriptor);
          if v_incoming_wins then
            v_retained := pg_catalog.to_jsonb(v_existing) - 'owner'
              || pg_catalog.jsonb_build_object('group_ids',v_existing_groups);
          else
            v_retained := pg_catalog.jsonb_build_object(
              'item_id',p_item_id,'text',v_text,'source',v_source,
              'group_ids',v_effective_groups,
              'created_at',v_existing.created_at,
              'updated_at',p_updated_at,'deleted_at',null);
          end if;
        end if;
        if v_incoming_wins then
          update public.my_adhkar_items r set text=v_text,source=v_source,
            updated_at=p_updated_at
            where r.owner=v_owner and r.item_id=p_item_id
            returning * into v_active;
          -- Kept groups keep their added_at; removed ones go; new ones get
          -- the edit time (the same rule as the device).
          delete from public.my_adhkar_item_groups m
            where m.owner=v_owner and m.item_id=p_item_id
              and m.group_id <> all(v_effective_groups);
          insert into public.my_adhkar_item_groups(owner,item_id,group_id,
            added_at)
            select v_owner,p_item_id,g,p_updated_at
            from unnest(v_effective_groups) as g
            where not exists (select 1 from public.my_adhkar_item_groups m
              where m.owner=v_owner and m.item_id=p_item_id
                and m.group_id=g);
          v_active_groups := v_effective_groups;
        else
          v_active := v_existing;
          v_active_groups := v_existing_groups;
        end if;
      end if;
    end if;
  end if;

  v_active_json := pg_catalog.to_jsonb(v_active) - 'owner'
    || pg_catalog.jsonb_build_object('group_ids',v_active_groups);
  if v_conflict_id is not null then
    insert into public.my_adhkar_conflicts(owner,conflict_id,entity_type,
      entity_id,active_record,retained_record)
    values(v_owner,v_conflict_id,'item',p_item_id,v_active_json,v_retained)
    on conflict(owner,conflict_id) do nothing;
    select c.detected_at into v_detected_at from public.my_adhkar_conflicts c
      where c.owner=v_owner and c.conflict_id=v_conflict_id;
  end if;

  v_outcome := pg_catalog.jsonb_build_object(
    'owner',v_owner,'operation_id',p_operation_id,'record_id',p_item_id,
    'entity_type','item',
    'active_record',v_active_json,'active_version',v_active.updated_at,
    'conflict_id',v_conflict_id,'retained_record',v_retained,
    'detected_at',v_detected_at,
    'group_deleted',v_group_deleted,
    'replayed',false);
  insert into public.my_adhkar_operation_receipts(owner,operation_id,record_id,
    request_fingerprint,outcome)
  values(v_owner,p_operation_id,p_item_id,v_request_fingerprint,v_outcome);
  return v_outcome;
end;
$$;

-- ---------------------------------------------------------------------------
-- Function grants: authenticated execution only, no anon, no public
-- ---------------------------------------------------------------------------

revoke all on function public.my_adhkar_group_descriptor_v1(
  timestamptz,boolean,text) from public,anon;
revoke all on function public.my_adhkar_item_descriptor_v1(
  timestamptz,boolean,text,text,uuid[]) from public,anon;
revoke all on function public.apply_my_adhkar_group_change_v1(
  uuid,text,timestamptz,boolean,timestamptz,timestamptz,text) from public,anon;
revoke all on function public.apply_my_adhkar_item_change_v1(
  uuid,text,text,uuid[],timestamptz,boolean,timestamptz,timestamptz,text)
  from public,anon;

grant execute on function public.my_adhkar_group_descriptor_v1(
  timestamptz,boolean,text) to authenticated;
grant execute on function public.my_adhkar_item_descriptor_v1(
  timestamptz,boolean,text,text,uuid[]) to authenticated;
grant execute on function public.apply_my_adhkar_group_change_v1(
  uuid,text,timestamptz,boolean,timestamptz,timestamptz,text) to authenticated;
grant execute on function public.apply_my_adhkar_item_change_v1(
  uuid,text,text,uuid[],timestamptz,boolean,timestamptz,timestamptz,text)
  to authenticated;

notify pgrst,'reload schema';
commit;
