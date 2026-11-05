-- Authenticated Prayer reports, deterministic conflict evidence, and
-- server-owned first-completion XP. Device city and schedules stay local.
begin;

create schema if not exists extensions;
create extension if not exists "uuid-ossp" with schema extensions;

create table public.prayer_reports (
  owner uuid not null references auth.users(id) on delete cascade,
  report_id uuid not null,
  local_date date not null,
  prayer_name text not null check (prayer_name in ('fajr','dhuhr','asr','maghrib','isha')),
  status text not null check (status in ('pending','completed_on_time','completed_late','missed')),
  reported_completion_at timestamptz,
  recorded_zone_id text not null check (pg_catalog.btrim(recorded_zone_id) <> ''),
  recorded_offset_minutes integer not null check (recorded_offset_minutes between -1080 and 1080),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  primary key (owner, local_date, prayer_name),
  unique (owner, report_id),
  check ((status in ('completed_on_time','completed_late')) = (reported_completion_at is not null)),
  check (created_at <= updated_at)
);
create index prayer_reports_owner_version_idx
  on public.prayer_reports(owner,updated_at,report_id);

create table public.prayer_conflicts (
  owner uuid not null references auth.users(id) on delete cascade,
  conflict_id uuid not null,
  report_id uuid not null,
  local_date date not null,
  prayer_name text not null,
  active_report jsonb not null,
  retained_report jsonb not null,
  detected_at timestamptz not null default pg_catalog.now(),
  primary key (owner, conflict_id),
  check (pg_catalog.jsonb_typeof(active_report) = 'object'),
  check (pg_catalog.jsonb_typeof(retained_report) = 'object')
);
create index prayer_conflicts_owner_report_idx
  on public.prayer_conflicts(owner,report_id,conflict_id);

create table public.prayer_operation_receipts (
  owner uuid not null references auth.users(id) on delete cascade,
  operation_id text not null check (pg_catalog.btrim(operation_id) <> ''),
  report_id uuid not null,
  request_fingerprint text not null,
  outcome jsonb not null,
  applied_at timestamptz not null default pg_catalog.now(),
  primary key (owner,operation_id)
);
create index prayer_receipts_report_idx
  on public.prayer_operation_receipts(owner,report_id,applied_at);

alter table public.prayer_reports enable row level security;
alter table public.prayer_conflicts enable row level security;
alter table public.prayer_operation_receipts enable row level security;
revoke all on public.prayer_reports from public,anon,authenticated;
revoke all on public.prayer_conflicts from public,anon,authenticated;
revoke all on public.prayer_operation_receipts from public,anon,authenticated;
grant select on public.prayer_reports,public.prayer_conflicts to authenticated;
create policy prayer_reports_owner_select on public.prayer_reports
  for select to authenticated using (owner = (select auth.uid()));
create policy prayer_conflicts_owner_select on public.prayer_conflicts
  for select to authenticated using (owner = (select auth.uid()));

create function public.prayer_report_id_v1(p_date date,p_name text)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '9d63d7a6-bb43-4b93-b2a1-c1d22c68b008'::uuid,
    pg_catalog.to_char(p_date,'YYYY-MM-DD') || '/' || p_name);
$$;

-- The descriptor is a canonical ASCII semantic version. It is shared with
-- clients and sorted bytewise so equal-timestamp arrivals choose alike.
create function public.prayer_version_descriptor_v1(
  p_updated_at timestamptz,p_status text,p_completion_at timestamptz,
  p_zone text,p_offset integer)
returns text language sql immutable security invoker set search_path = '' as $$
  select (extract(epoch from p_updated_at) * 1000000)::bigint::text
    || ':' || p_status || '|'
    || coalesce((extract(epoch from p_completion_at) * 1000000)::bigint::text,'null')
    || '|' || p_zone || '|' || p_offset::text;
$$;

create function public.prayer_conflict_id_v1(
  p_report_id uuid,p_first text,p_second text)
returns uuid language sql immutable security invoker set search_path = '' as $$
  select extensions.uuid_generate_v5(
    '9d63d7a6-bb43-4b93-b2a1-c1d22c68b008'::uuid,
    'conflict/' || p_report_id::text || '/'
      || least(p_first collate "C",p_second collate "C") || '/'
      || greatest(p_first collate "C",p_second collate "C"));
$$;

create function public.apply_prayer_report_change_v1(
  p_report_id uuid,p_local_date date,p_prayer_name text,p_status text,
  p_reported_completion_at timestamptz,p_recorded_zone_id text,
  p_recorded_offset_minutes integer,p_created_at timestamptz,
  p_updated_at timestamptz,p_base_updated_at timestamptz,p_operation_id text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_receipt public.prayer_operation_receipts%rowtype;
  v_existing public.prayer_reports%rowtype;
  v_active public.prayer_reports%rowtype;
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
  if p_report_id is null or p_local_date is null or p_prayer_name not in
      ('fajr','dhuhr','asr','maghrib','isha') or p_prayer_name is null
      or p_status not in ('pending','completed_on_time','completed_late','missed')
      or p_status is null or p_created_at is null or p_updated_at is null
      or p_created_at > p_updated_at or p_recorded_zone_id is null
      or pg_catalog.btrim(p_recorded_zone_id) = ''
      or p_recorded_offset_minutes is null
      or p_recorded_offset_minutes not between -1080 and 1080
      or p_recorded_zone_id like '%|%'
      or p_operation_id is null or pg_catalog.btrim(p_operation_id) = ''
      or pg_catalog.length(p_operation_id) > 128
      or ((p_status in ('completed_on_time','completed_late'))
          is distinct from (p_reported_completion_at is not null)) then
    raise exception using errcode='22023',message='Invalid Prayer report operation';
  end if;
  -- The completion instant dates the canonical award, so keep it on the
  -- reported prayer day (any zone, late Isha included) and the date itself
  -- out of the future. Delayed offline delivery stays valid: now() is not
  -- compared with the completion instant.
  if p_local_date > (pg_catalog.now() at time zone 'UTC')::date + 2
      or (p_reported_completion_at is not null and (
        p_reported_completion_at < p_local_date::timestamp at time zone 'UTC'
          - interval '1 day'
        or p_reported_completion_at >= p_local_date::timestamp at time zone 'UTC'
          + interval '2 days')) then
    raise exception using errcode='22023',message='Prayer completion outside its day';
  end if;
  if p_report_id is distinct from public.prayer_report_id_v1(p_local_date,p_prayer_name) then
    raise exception using errcode='22023',message='Prayer report identity mismatch';
  end if;
  v_incoming_descriptor := public.prayer_version_descriptor_v1(
    p_updated_at,p_status,p_reported_completion_at,p_recorded_zone_id,
    p_recorded_offset_minutes);
  v_request_fingerprint := pg_catalog.md5(p_report_id::text || ':'
    || pg_catalog.to_char(p_local_date,'YYYY-MM-DD') || ':' || p_prayer_name
    || ':' || v_incoming_descriptor || ':'
    || (extract(epoch from p_created_at) * 1000000)::bigint::text);

  -- Operation and report locks cover absent first insert as well as updates.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':prayer-op:' || p_operation_id,0));
  select * into v_receipt from public.prayer_operation_receipts r
    where r.owner=v_owner and r.operation_id=p_operation_id;
  if found then
    if v_receipt.request_fingerprint <> v_request_fingerprint then
      raise exception using errcode='22023',message='Prayer operation ID reused with different content';
    end if;
    return v_receipt.outcome || '{"replayed":true}'::jsonb;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':prayer-report:' || p_report_id::text,0));
  select * into v_existing from public.prayer_reports r
    where r.owner=v_owner and r.report_id=p_report_id for update;
  if found then
    v_existing_descriptor := public.prayer_version_descriptor_v1(
      v_existing.updated_at,v_existing.status,v_existing.reported_completion_at,
      v_existing.recorded_zone_id,v_existing.recorded_offset_minutes);
    v_divergent := v_existing.status is distinct from p_status
      or v_existing.reported_completion_at is distinct from p_reported_completion_at
      or v_existing.recorded_zone_id is distinct from p_recorded_zone_id
      or v_existing.recorded_offset_minutes is distinct from p_recorded_offset_minutes;
    v_incoming_wins := p_updated_at > v_existing.updated_at
      or (p_updated_at = v_existing.updated_at
        and v_incoming_descriptor collate "C" > v_existing_descriptor collate "C");
    if v_divergent and v_existing.updated_at is distinct from p_base_updated_at then
      v_conflict_id := public.prayer_conflict_id_v1(
        p_report_id,v_existing_descriptor,v_incoming_descriptor);
      if v_incoming_wins then
        v_retained := pg_catalog.to_jsonb(v_existing) - 'owner';
      else
        v_retained := pg_catalog.jsonb_build_object(
          'report_id',p_report_id,'local_date',p_local_date,
          'prayer_name',p_prayer_name,'status',p_status,
          'reported_completion_at',p_reported_completion_at,
          'recorded_zone_id',p_recorded_zone_id,
          'recorded_offset_minutes',p_recorded_offset_minutes,
          'created_at',p_created_at,'updated_at',p_updated_at);
      end if;
    end if;
    if v_incoming_wins then
      update public.prayer_reports r set status=p_status,
        reported_completion_at=p_reported_completion_at,
        recorded_zone_id=p_recorded_zone_id,
        recorded_offset_minutes=p_recorded_offset_minutes,
        updated_at=p_updated_at
        where r.owner=v_owner and r.report_id=p_report_id
        returning * into v_active;
    else
      v_active := v_existing;
    end if;
  else
    if p_base_updated_at is not null then
      raise exception using errcode='22023',message='Unknown Prayer base version';
    end if;
    insert into public.prayer_reports(owner,report_id,local_date,prayer_name,status,
      reported_completion_at,recorded_zone_id,recorded_offset_minutes,created_at,updated_at)
    values(v_owner,p_report_id,p_local_date,p_prayer_name,p_status,
      p_reported_completion_at,p_recorded_zone_id,p_recorded_offset_minutes,
      p_created_at,p_updated_at) returning * into v_active;
  end if;

  v_active_json := pg_catalog.to_jsonb(v_active) - 'owner';
  if v_conflict_id is not null then
    insert into public.prayer_conflicts(owner,conflict_id,report_id,local_date,
      prayer_name,active_report,retained_report)
    values(v_owner,v_conflict_id,p_report_id,p_local_date,p_prayer_name,
      v_active_json,v_retained)
    on conflict(owner,conflict_id) do nothing;
    -- Return the stored (first) detection time so every client agrees.
    select c.detected_at into v_detected_at from public.prayer_conflicts c
      where c.owner=v_owner and c.conflict_id=v_conflict_id;
  end if;
  -- First server-committed eligible completion wins, even when its report
  -- snapshot loses to a later reset. The shared ledger remains Task-compatible.
  if p_status in ('completed_on_time','completed_late') then
    insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
    values(v_owner,'prayer_done',p_report_id,
      case when p_status='completed_on_time' then 10 else 5 end,
      p_reported_completion_at)
    on conflict(owner,source,source_id) do nothing;
  end if;
  select * into v_award from public.xp_awards a
    where a.owner=v_owner and a.source='prayer_done' and a.source_id=p_report_id;
  v_outcome := pg_catalog.jsonb_build_object(
    'owner',v_owner,'operation_id',p_operation_id,'report_id',p_report_id,
    'active_report',v_active_json,'conflict_id',v_conflict_id,
    'retained_report',v_retained,'detected_at',v_detected_at,
    'canonical_award',case when v_award.owner is null then null
      else pg_catalog.jsonb_build_object('source','prayer_done','source_id',p_report_id,
        'amount',v_award.amount,'awarded_at',v_award.awarded_at) end,
    'replayed',false);
  insert into public.prayer_operation_receipts(owner,operation_id,report_id,
    request_fingerprint,outcome)
  values(v_owner,p_operation_id,p_report_id,v_request_fingerprint,v_outcome);
  return v_outcome;
end;
$$;

revoke all on function public.prayer_report_id_v1(date,text) from public,anon;
revoke all on function public.prayer_version_descriptor_v1(
  timestamptz,text,timestamptz,text,integer) from public,anon;
revoke all on function public.prayer_conflict_id_v1(uuid,text,text) from public,anon;
revoke all on function public.apply_prayer_report_change_v1(
  uuid,date,text,text,timestamptz,text,integer,timestamptz,
  timestamptz,timestamptz,text) from public,anon;
grant execute on function public.prayer_report_id_v1(date,text) to authenticated;
grant execute on function public.prayer_version_descriptor_v1(
  timestamptz,text,timestamptz,text,integer) to authenticated;
grant execute on function public.prayer_conflict_id_v1(uuid,text,text) to authenticated;
grant execute on function public.apply_prayer_report_change_v1(
  uuid,date,text,text,timestamptz,text,integer,timestamptz,
  timestamptz,timestamptz,text) to authenticated;

notify pgrst,'reload schema';
commit;
