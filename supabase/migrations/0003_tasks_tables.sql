-- Account-owned Task storage and immutable XP-award ledger (Foundation v3).
-- Clients may read their own rows, but all remote Task mutation is reserved
-- for the authenticated RPC added by 0004_task_sync_api.sql.

begin;

create table public.tasks (
  owner uuid not null references auth.users (id) on delete cascade,
  id uuid not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, id),
  constraint tasks_payload_is_object
    check (jsonb_typeof(payload) = 'object')
);

create index tasks_owner_updated_idx
  on public.tasks (owner, updated_at, id);
create index tasks_owner_deleted_idx
  on public.tasks (owner, deleted_at, id);

create table public.xp_awards (
  owner uuid not null references auth.users (id) on delete cascade,
  source text not null,
  source_id uuid not null,
  amount integer not null check (amount >= 0),
  awarded_at timestamptz not null,
  primary key (owner, source, source_id),
  constraint xp_awards_source_not_blank check (btrim(source) <> '')
);

create index xp_awards_owner_awarded_idx
  on public.xp_awards (owner, awarded_at, source_id);

-- Receipts remain after a Task becomes a tombstone. They are an internal
-- replay ledger and are never exposed as client-readable account data.
create table public.task_operation_receipts (
  owner uuid not null references auth.users (id) on delete cascade,
  operation_id text not null,
  entity_id uuid not null,
  kind text not null check (kind in ('create', 'update', 'delete')),
  result_payload jsonb not null,
  result_updated_at timestamptz not null,
  result_deleted_at timestamptz,
  conflict_detected boolean not null default false,
  retained_payload jsonb,
  retained_updated_at timestamptz,
  retained_deleted_at timestamptz,
  applied_at timestamptz not null default now(),
  primary key (owner, operation_id),
  constraint task_receipts_operation_not_blank
    check (btrim(operation_id) <> '')
);

create index task_receipts_entity_idx
  on public.task_operation_receipts (owner, entity_id, applied_at);

alter table public.tasks enable row level security;
alter table public.xp_awards enable row level security;
alter table public.task_operation_receipts enable row level security;

revoke all on public.tasks from public, anon, authenticated;
revoke all on public.xp_awards from public, anon, authenticated;
revoke all on public.task_operation_receipts from public, anon, authenticated;

grant select on public.tasks to authenticated;
grant select on public.xp_awards to authenticated;

create policy "tasks_owner_select"
  on public.tasks
  for select
  to authenticated
  using (owner = (select auth.uid()));

create policy "xp_awards_owner_select"
  on public.xp_awards
  for select
  to authenticated
  using (owner = (select auth.uid()));

-- No client policies or grants exist for Task writes, award writes, or
-- receipt access. The restricted security-definer RPC is the sole Task
-- mutation boundary and derives its owner from auth.uid().

commit;
