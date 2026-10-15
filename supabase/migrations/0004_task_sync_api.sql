-- Authenticated, replay-safe Task mutation boundary.
-- Ownership is derived only from auth.uid(); no owner argument is accepted.

begin;

create or replace function public.apply_task_change(
  p_id uuid,
  p_payload jsonb,
  p_operation_id text,
  p_updated_at timestamptz,
  p_kind text
)
returns table (
  id uuid,
  owner uuid,
  payload jsonb,
  operation_id text,
  updated_at timestamptz,
  deleted_at timestamptz,
  conflict_detected boolean,
  retained_payload jsonb,
  retained_updated_at timestamptz,
  retained_deleted_at timestamptz,
  replayed boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid := auth.uid();
  v_existing public.tasks%rowtype;
  v_active public.tasks%rowtype;
  v_receipt public.task_operation_receipts%rowtype;
  v_conflict boolean := false;
  v_retained_payload jsonb;
  v_retained_updated_at timestamptz;
  v_retained_deleted_at timestamptz;
begin
  if v_owner is null then
    raise exception using errcode = '42501', message = 'Not authenticated';
  end if;
  if p_id is null or p_updated_at is null then
    raise exception using errcode = '22023',
      message = 'Task id and version timestamp are required';
  end if;
  if p_operation_id is null or pg_catalog.btrim(p_operation_id) = '' then
    raise exception using errcode = '22023',
      message = 'Operation id is required';
  end if;
  if p_kind is null or p_kind not in ('create', 'update', 'delete') then
    raise exception using errcode = '22023',
      message = 'Unsupported Task change kind';
  end if;
  if p_payload is null or pg_catalog.jsonb_typeof(p_payload) <> 'object' then
    raise exception using errcode = '22023',
      message = 'Task payload must be a JSON object';
  end if;

  -- Serialize retries for one account+operation key before reading its
  -- receipt, so concurrent retries still produce exactly one remote effect.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':' || p_operation_id, 0)
  );

  select * into v_receipt
  from public.task_operation_receipts as receipts
  where receipts.owner = v_owner
    and receipts.operation_id = p_operation_id;

  if found then
    return query select
      v_receipt.entity_id,
      v_receipt.owner,
      v_receipt.result_payload,
      v_receipt.operation_id,
      v_receipt.result_updated_at,
      v_receipt.result_deleted_at,
      v_receipt.conflict_detected,
      v_receipt.retained_payload,
      v_receipt.retained_updated_at,
      v_receipt.retained_deleted_at,
      true;
    return;
  end if;

  select * into v_existing
  from public.tasks as task_rows
  where task_rows.owner = v_owner and task_rows.id = p_id
  for update;

  if found then
    v_conflict := true;
    if p_updated_at > v_existing.updated_at then
      v_retained_payload := v_existing.payload;
      v_retained_updated_at := v_existing.updated_at;
      v_retained_deleted_at := v_existing.deleted_at;

      update public.tasks as task_rows
      set payload = case
            when p_kind = 'delete' then v_existing.payload
            else p_payload
          end,
          updated_at = p_updated_at,
          deleted_at = case
            when p_kind = 'delete' then p_updated_at
            else null
          end
      where task_rows.owner = v_owner and task_rows.id = p_id
      returning * into v_active;
    else
      -- The remote version remains active. The attempted local version is
      -- retained in the durable receipt so the client can surface conflict
      -- evidence instead of silently discarding it.
      v_active := v_existing;
      v_retained_payload := p_payload;
      v_retained_updated_at := p_updated_at;
      v_retained_deleted_at := case
        when p_kind = 'delete' then p_updated_at
        else null
      end;
    end if;
  else
    insert into public.tasks (owner, id, payload, updated_at, deleted_at)
    values (
      v_owner,
      p_id,
      p_payload,
      p_updated_at,
      case when p_kind = 'delete' then p_updated_at else null end
    )
    returning * into v_active;
  end if;

  insert into public.task_operation_receipts (
    owner,
    operation_id,
    entity_id,
    kind,
    result_payload,
    result_updated_at,
    result_deleted_at,
    conflict_detected,
    retained_payload,
    retained_updated_at,
    retained_deleted_at
  ) values (
    v_owner,
    p_operation_id,
    p_id,
    p_kind,
    v_active.payload,
    v_active.updated_at,
    v_active.deleted_at,
    v_conflict,
    v_retained_payload,
    v_retained_updated_at,
    v_retained_deleted_at
  )
  returning * into v_receipt;

  return query select
    v_receipt.entity_id,
    v_receipt.owner,
    v_receipt.result_payload,
    v_receipt.operation_id,
    v_receipt.result_updated_at,
    v_receipt.result_deleted_at,
    v_receipt.conflict_detected,
    v_receipt.retained_payload,
    v_receipt.retained_updated_at,
    v_receipt.retained_deleted_at,
    false;
end;
$$;

revoke all on function public.apply_task_change(
  uuid, jsonb, text, timestamptz, text
) from public, anon;
grant execute on function public.apply_task_change(
  uuid, jsonb, text, timestamptz, text
) to authenticated;

notify pgrst, 'reload schema';

commit;
