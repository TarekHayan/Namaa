-- Foundation-only remote probe schema, least-privilege grants, and RLS
-- owner policies (T034).
--
-- Ownership is enforced from the authenticated session (auth.uid()); a
-- caller-supplied account identifier can never establish access rights
-- (contracts/supabase-security.md). This migration defines no
-- product-domain tables.

create table if not exists public.foundation_probe (
  id uuid primary key,
  owner uuid not null references auth.users (id) on delete cascade,
  payload text not null,
  operation_id text unique,
  updated_at timestamptz not null default now()
);

-- Row Level Security: every exposed account-data table enables RLS before
-- the client can access it.
alter table public.foundation_probe enable row level security;

-- Least-privilege grants: anon gets nothing; authenticated gets only the
-- four row operations on this table. Service-role access is server-side
-- only and is not granted here.
revoke all on public.foundation_probe from anon, authenticated, public;
grant select, insert, update, delete on public.foundation_probe to authenticated;

-- Owner policies: the authenticated session's account is the only owner.
-- Inserts are checked against auth.uid(), so a client-supplied owner value
-- for another account is rejected.
create policy "foundation_probe_owner_select"
  on public.foundation_probe
  for select
  to authenticated
  using (owner = (select auth.uid()));

create policy "foundation_probe_owner_insert"
  on public.foundation_probe
  for insert
  to authenticated
  with check (owner = (select auth.uid()));

create policy "foundation_probe_owner_update"
  on public.foundation_probe
  for update
  to authenticated
  using (owner = (select auth.uid()))
  with check (owner = (select auth.uid()));

create policy "foundation_probe_owner_delete"
  on public.foundation_probe
  for delete
  to authenticated
  using (owner = (select auth.uid()));
create or replace function public.apply_foundation_change(
  p_id uuid,
  p_payload text,
  p_operation_id text,
  p_updated_at timestamptz,
  p_kind text
)
returns table (
  id uuid,
  owner uuid,
  payload text,
  operation_id text,
  updated_at timestamptz,
  conflict_detected boolean,
  retained_payload text,
  retained_updated_at timestamptz
)
language plpgsql
security invoker
as $$
declare
  v_owner uuid := auth.uid();
  v_existing public.foundation_probe%rowtype;
  v_retained public.foundation_probe%rowtype;
begin
  if v_owner is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_existing
  from public.foundation_probe
  where public.foundation_probe.id = p_id
  for update;

  if found then
    -- A retry of the exact same operation is idempotent.
    if v_existing.operation_id = p_operation_id then
      return query select v_existing.id, v_existing.owner, v_existing.payload,
        v_existing.operation_id, v_existing.updated_at, false, null::text,
        null::timestamptz;
      return;
    end if;

    -- A newer local version wins. A current or newer remote version is
    -- returned unchanged so the client can resolve and retain the conflict.
    if p_updated_at > v_existing.updated_at then
      v_retained := v_existing;
      if p_kind = 'delete' then
        delete from public.foundation_probe where public.foundation_probe.id = p_id;
        return query select p_id, v_owner, p_payload, p_operation_id,
          p_updated_at, true, v_retained.payload, v_retained.updated_at;
        return;
      end if;

      update public.foundation_probe
      set payload = p_payload,
          operation_id = p_operation_id,
          updated_at = p_updated_at
      where public.foundation_probe.id = p_id
      returning * into v_existing;

      return query select v_existing.id, v_existing.owner, v_existing.payload,
        v_existing.operation_id, v_existing.updated_at, true,
        v_retained.payload, v_retained.updated_at;
      return;
    end if;

    return query select v_existing.id, v_existing.owner, v_existing.payload,
      v_existing.operation_id, v_existing.updated_at, true, null::text,
      null::timestamptz;
    return;
  end if;

  if p_kind = 'delete' then
    return;
  end if;

  insert into public.foundation_probe (id, owner, payload, operation_id, updated_at)
  values (p_id, v_owner, p_payload, p_operation_id, p_updated_at);

  return;
end;
$$;

-- PostgreSQL functions otherwise grant EXECUTE to public by default. The
-- synchronization RPC is available only to authenticated accounts and keeps
-- its security-invoker behavior, so table RLS remains enforced.
revoke all on function public.apply_foundation_change(
  uuid, text, text, timestamptz, text
) from public, anon;
grant execute on function public.apply_foundation_change(
  uuid, text, text, timestamptz, text
) to authenticated;
