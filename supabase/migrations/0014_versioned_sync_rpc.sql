-- Keep sync metadata out of user payloads. Clients call these versioned RPCs;
-- a server without this migration rejects the call instead of persisting
-- _syncBaseUpdatedAt as an ordinary JSON field.
begin;

create function public.apply_task_change_v2(
  p_id uuid, p_payload jsonb, p_operation_id text,
  p_updated_at timestamptz, p_kind text, p_base_updated_at timestamptz
) returns table (
  id uuid, owner uuid, payload jsonb, operation_id text,
  updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, retained_payload jsonb,
  retained_updated_at timestamptz, retained_deleted_at timestamptz,
  replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public.apply_task_change(
    p_id, p_payload || pg_catalog.jsonb_build_object(
      '_syncBaseUpdatedAt', p_base_updated_at),
    p_operation_id, p_updated_at, p_kind);
$$;

create function public.apply_habit_change_v2(
  p_id uuid, p_payload jsonb, p_operation_id text,
  p_updated_at timestamptz, p_kind text, p_base_updated_at timestamptz
) returns table (
  owner uuid, id uuid, entity_type text, local_date text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  parent_deleted boolean, replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public.apply_habit_change(
    p_id, p_payload || pg_catalog.jsonb_build_object(
      '_syncBaseUpdatedAt', p_base_updated_at),
    p_operation_id, p_updated_at, p_kind);
$$;

create function public.apply_habit_day_change_v2(
  p_habit_id uuid, p_local_date text, p_payload jsonb,
  p_operation_id text, p_updated_at timestamptz, p_kind text,
  p_base_updated_at timestamptz
) returns table (
  owner uuid, id uuid, entity_type text, local_date text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  parent_deleted boolean, replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public.apply_habit_day_change(
    p_habit_id, p_local_date,
    p_payload || pg_catalog.jsonb_build_object(
      '_syncBaseUpdatedAt', p_base_updated_at),
    p_operation_id, p_updated_at, p_kind);
$$;

create function public.apply_mind_map_change_v2(
  p_entity_type text, p_map_id uuid, p_entity_id text, p_payload jsonb,
  p_operation_id text, p_updated_at timestamptz, p_kind text,
  p_base_updated_at timestamptz
) returns table (
  owner uuid, entity_type text, entity_id text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  rejection_reason text, replayed boolean
)
language sql security definer set search_path = '' as $$
  select * from public.apply_mind_map_change(
    p_entity_type, p_map_id, p_entity_id,
    p_payload || pg_catalog.jsonb_build_object(
      '_syncBaseUpdatedAt', p_base_updated_at),
    p_operation_id, p_updated_at, p_kind);
$$;

revoke all on function public.apply_task_change_v2(
  uuid,jsonb,text,timestamptz,text,timestamptz) from public, anon;
revoke all on function public.apply_habit_change_v2(
  uuid,jsonb,text,timestamptz,text,timestamptz) from public, anon;
revoke all on function public.apply_habit_day_change_v2(
  uuid,text,jsonb,text,timestamptz,text,timestamptz) from public, anon;
revoke all on function public.apply_mind_map_change_v2(
  text,uuid,text,jsonb,text,timestamptz,text,timestamptz) from public, anon;
grant execute on function public.apply_task_change_v2(
  uuid,jsonb,text,timestamptz,text,timestamptz) to authenticated;
grant execute on function public.apply_habit_change_v2(
  uuid,jsonb,text,timestamptz,text,timestamptz) to authenticated;
grant execute on function public.apply_habit_day_change_v2(
  uuid,text,jsonb,text,timestamptz,text,timestamptz) to authenticated;
grant execute on function public.apply_mind_map_change_v2(
  text,uuid,text,jsonb,text,timestamptz,text,timestamptz) to authenticated;

notify pgrst, 'reload schema';
commit;
