-- Owner-derived, receipt-backed Habit and HabitDay mutation boundaries.
begin;

create function public._apply_habit_mutation(
  p_entity_type text,
  p_id uuid,
  p_local_date text,
  p_payload jsonb,
  p_operation_id text,
  p_updated_at timestamptz,
  p_kind text
)
returns table (
  owner uuid, id uuid, entity_type text, local_date text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  parent_deleted boolean, replayed boolean
)
language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_receipt public.habit_operation_receipts%rowtype;
  v_habit public.habits%rowtype;
  v_day public.habit_days%rowtype;
  v_active_payload jsonb;
  v_active_at timestamptz;
  v_deleted_at timestamptz;
  v_retained jsonb;
  v_retained_at timestamptz;
  v_conflict boolean := false;
  v_unresolved boolean := false;
  v_parent_deleted boolean := false;
  v_key text;
begin
  if v_owner is null then
    raise exception using errcode = '42501', message = 'Not authenticated';
  end if;
  if p_entity_type not in ('habit', 'habit_day') or p_id is null or
     p_updated_at is null or p_operation_id is null or
     pg_catalog.btrim(p_operation_id) = '' or
     p_kind is null or p_kind not in ('create', 'update', 'delete') or
     p_payload is null or pg_catalog.jsonb_typeof(p_payload) <> 'object' then
    raise exception using errcode = '22023', message = 'Invalid Habit operation';
  end if;
  if p_entity_type = 'habit' then
    if p_local_date is not null or p_payload->>'id' is distinct from p_id::text or
       p_payload->>'accountId' is distinct from v_owner::text or
       pg_catalog.btrim(coalesce(p_payload->>'name', '')) = '' or
       p_payload->>'createdAt' is null or
       pg_catalog.jsonb_typeof(p_payload->'scheduleRevisions') is distinct from 'array' or
       pg_catalog.jsonb_array_length(p_payload->'scheduleRevisions') = 0 or
       (p_payload->>'updatedAt')::timestamptz is distinct from p_updated_at or
       (p_kind = 'delete') is distinct from (p_payload->>'deletedAt' is not null) or
       (p_payload->>'deletedAt' is not null and
        (p_payload->>'deletedAt')::timestamptz is distinct from p_updated_at) or
       (p_payload->>'reminderMinuteOfDay' is not null and
        ((p_payload->>'reminderMinuteOfDay')::integer not between 0 and 1439)) then
      raise exception using errcode = '22023', message = 'Invalid Habit payload';
    end if;
    if exists (
      select 1 from pg_catalog.jsonb_array_elements(p_payload->'scheduleRevisions') as revision(value)
      where pg_catalog.jsonb_typeof(revision.value) <> 'object' or
        revision.value->>'revisionId' is null or
        revision.value->>'effectiveAt' is null or
       revision.value->>'effectiveLocalDate' is null or
        revision.value->>'effectiveLocalDate' !~ '^\d{4}-\d{2}-\d{2}$' or
        (revision.value->>'effectiveLocalDate')::date::text is distinct from
          revision.value->>'effectiveLocalDate' or
        revision.value->>'utcOffsetMinutes' is null or
        (revision.value->>'utcOffsetMinutes')::integer not between -840 and 840 or
        pg_catalog.jsonb_typeof(revision.value->'weekdays') is distinct from 'array' or
        pg_catalog.jsonb_array_length(revision.value->'weekdays') = 0 or
        exists (
          select 1 from pg_catalog.jsonb_array_elements_text(revision.value->'weekdays') as weekday(value)
          where weekday.value !~ '^[1-7]$'
        )
    ) then
      raise exception using errcode = '22023', message = 'Invalid Habit schedule';
    end if;
    if (select count(*) <> count(distinct revision.value->>'revisionId')
        from pg_catalog.jsonb_array_elements(p_payload->'scheduleRevisions') as revision(value)) then
      raise exception using errcode = '22023', message = 'Duplicate Habit revision';
    end if;
    v_key := p_id::text;
  else
    if p_kind = 'delete' or p_local_date is null or
       p_local_date !~ '^\d{4}-\d{2}-\d{2}$' or
       p_local_date::date::text <> p_local_date or
       p_payload->>'habitId' is distinct from p_id::text or
       p_payload->>'accountId' is distinct from v_owner::text or
       p_payload->>'localDate' is distinct from p_local_date or
       (p_payload->>'updatedAt')::timestamptz is distinct from p_updated_at or
       pg_catalog.jsonb_typeof(p_payload->'earnedWhileDue') is distinct from 'boolean' or
       (p_payload->>'completedAt' is not null and
        p_payload->>'earnedWhileDue' <> 'true') or
       (p_payload->>'completedAt' is null and
        p_payload->>'earnedWhileDue' <> 'false') or
       (p_payload->>'completedAt' is not null and
        p_payload->>'earnedAgainstRevisionId' is null) or
       p_payload->>'recordedUtcOffsetMinutes' is null or
       (p_payload->>'recordedUtcOffsetMinutes')::integer not between -840 and 840 then
      raise exception using errcode = '22023', message = 'Invalid HabitDay payload';
    end if;
    v_key := p_id::text || ':' || p_local_date;
  end if;

  -- The receipt lock also serializes two retries that arrive at once.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':' || p_operation_id, 0)
  );
  select * into v_receipt from public.habit_operation_receipts as receipts
    where receipts.owner = v_owner and receipts.operation_id = p_operation_id;
  if found then
    if v_receipt.entity_type <> p_entity_type or v_receipt.entity_id <> v_key or
       v_receipt.kind <> p_kind or v_receipt.request_payload <> p_payload or
       v_receipt.request_updated_at <> p_updated_at then
      raise exception using errcode = '22023', message = 'Operation identity collision';
    end if;
    return query select v_receipt.owner, p_id, p_entity_type, p_local_date,
      v_receipt.result_payload, v_receipt.operation_id,
      v_receipt.result_updated_at, v_receipt.result_deleted_at,
      v_receipt.conflict_detected, v_receipt.conflict_unresolved,
      v_receipt.retained_payload, v_receipt.retained_updated_at,
      v_receipt.parent_deleted, true;
    return;
  end if;

  -- Different operations for the same Habit must arbitrate against one
  -- committed version, including when both arrive before its first insert.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':habit:' || p_id::text, 0)
  );

  if p_entity_type = 'habit' then
    select * into v_habit from public.habits as rows
      where rows.owner = v_owner and rows.id = p_id for update;
    if found then
      if v_habit.payload <> p_payload then
        v_conflict := true;
        if p_updated_at > v_habit.updated_at then
          v_retained := v_habit.payload;
          v_retained_at := v_habit.updated_at;
          update public.habits as rows set payload = p_payload,
            updated_at = p_updated_at,
            deleted_at = case when p_kind = 'delete' then p_updated_at else null end
            where rows.owner = v_owner and rows.id = p_id;
          v_active_payload := p_payload;
          v_active_at := p_updated_at;
          v_deleted_at := case when p_kind = 'delete' then p_updated_at else null end;
        else
          v_active_payload := v_habit.payload;
          v_active_at := v_habit.updated_at;
          v_deleted_at := v_habit.deleted_at;
          v_retained := p_payload;
          v_retained_at := p_updated_at;
          v_unresolved := p_updated_at = v_habit.updated_at;
        end if;
      else
        v_active_payload := v_habit.payload;
        v_active_at := v_habit.updated_at;
        v_deleted_at := v_habit.deleted_at;
      end if;
    else
      insert into public.habits(owner, id, payload, updated_at, deleted_at)
        values (v_owner, p_id, p_payload, p_updated_at,
          case when p_kind = 'delete' then p_updated_at else null end);
      v_active_payload := p_payload;
      v_active_at := p_updated_at;
      v_deleted_at := case when p_kind = 'delete' then p_updated_at else null end;
    end if;
  else
    select * into v_habit from public.habits as rows
      where rows.owner = v_owner and rows.id = p_id for update;
    if not found then
      raise exception using errcode = '23503', message = 'HabitDay parent missing';
    end if;
    select * into v_day from public.habit_days as rows
      where rows.owner = v_owner and rows.habit_id = p_id and
        rows.local_date = p_local_date::date for update;
    if v_habit.deleted_at is not null then
      v_conflict := true;
      v_unresolved := true;
      v_parent_deleted := true;
      v_active_payload := case when v_day.owner is null then p_payload else v_day.payload end;
      v_active_at := case when v_day.owner is null then v_habit.updated_at else v_day.updated_at end;
      v_retained := p_payload;
      v_retained_at := p_updated_at;
    elsif v_day.owner is not null then
      if v_day.payload <> p_payload then
        v_conflict := true;
        if p_updated_at > v_day.updated_at then
          v_retained := v_day.payload;
          v_retained_at := v_day.updated_at;
          update public.habit_days as rows set payload = p_payload,
            updated_at = p_updated_at
            where rows.owner = v_owner and rows.habit_id = p_id and
              rows.local_date = p_local_date::date;
          v_active_payload := p_payload;
          v_active_at := p_updated_at;
        else
          v_active_payload := v_day.payload;
          v_active_at := v_day.updated_at;
          v_retained := p_payload;
          v_retained_at := p_updated_at;
          v_unresolved := p_updated_at = v_day.updated_at;
        end if;
      else
        v_active_payload := v_day.payload;
        v_active_at := v_day.updated_at;
      end if;
    else
      insert into public.habit_days(owner, habit_id, local_date, payload, updated_at)
        values (v_owner, p_id, p_local_date::date, p_payload, p_updated_at);
      v_active_payload := p_payload;
      v_active_at := p_updated_at;
    end if;
  end if;

  insert into public.habit_operation_receipts (
    owner, operation_id, entity_type, entity_id, kind,
    request_payload, request_updated_at, result_payload, result_updated_at,
    result_deleted_at, conflict_detected, conflict_unresolved, parent_deleted,
    retained_payload, retained_updated_at
  ) values (
    v_owner, p_operation_id, p_entity_type, v_key, p_kind,
    p_payload, p_updated_at, v_active_payload, v_active_at,
    v_deleted_at, v_conflict, v_unresolved, v_parent_deleted,
    v_retained, v_retained_at
  );
  return query select v_owner, p_id, p_entity_type, p_local_date,
    v_active_payload, p_operation_id, v_active_at, v_deleted_at,
    v_conflict, v_unresolved, v_retained, v_retained_at,
    v_parent_deleted, false;
end;
$$;

create function public.apply_habit_change(
  p_id uuid, p_payload jsonb, p_operation_id text,
  p_updated_at timestamptz, p_kind text
) returns table (
  owner uuid, id uuid, entity_type text, local_date text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  parent_deleted boolean, replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public._apply_habit_mutation(
    'habit', p_id, null, p_payload, p_operation_id, p_updated_at, p_kind);
$$;

create function public.apply_habit_day_change(
  p_habit_id uuid, p_local_date text, p_payload jsonb,
  p_operation_id text, p_updated_at timestamptz, p_kind text
) returns table (
  owner uuid, id uuid, entity_type text, local_date text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  parent_deleted boolean, replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public._apply_habit_mutation(
    'habit_day', p_habit_id, p_local_date, p_payload,
    p_operation_id, p_updated_at, p_kind);
$$;

revoke all on function public._apply_habit_mutation(
  text, uuid, text, jsonb, text, timestamptz, text) from public, anon, authenticated;
revoke all on function public.apply_habit_change(
  uuid, jsonb, text, timestamptz, text) from public, anon;
revoke all on function public.apply_habit_day_change(
  uuid, text, jsonb, text, timestamptz, text) from public, anon;
grant execute on function public.apply_habit_change(
  uuid, jsonb, text, timestamptz, text) to authenticated;
grant execute on function public.apply_habit_day_change(
  uuid, text, jsonb, text, timestamptz, text) to authenticated;
notify pgrst, 'reload schema';
commit;
