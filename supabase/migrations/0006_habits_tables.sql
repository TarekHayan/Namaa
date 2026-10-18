-- Account-owned Habit metadata and independently versioned local-calendar days.
begin;

create table public.habits (
  owner uuid not null references auth.users (id) on delete cascade,
  id uuid not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, id)
);
create index habits_owner_updated_idx on public.habits (owner, updated_at, id);
create index habits_owner_deleted_idx on public.habits (owner, deleted_at, id);

create table public.habit_days (
  owner uuid not null,
  habit_id uuid not null,
  local_date date not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  primary key (owner, habit_id, local_date),
  foreign key (owner, habit_id) references public.habits (owner, id)
);
create index habit_days_owner_updated_idx on public.habit_days
  (owner, updated_at, habit_id, local_date);

-- Receipts are never exposed to clients. They outlive Habit tombstones and
-- retain nonwinning/equal-time evidence for replay and local conflict display.
create table public.habit_operation_receipts (
  owner uuid not null references auth.users (id) on delete cascade,
  operation_id text not null check (btrim(operation_id) <> ''),
  entity_type text not null check (entity_type in ('habit', 'habit_day')),
  entity_id text not null,
  kind text not null check (kind in ('create', 'update', 'delete')),
  request_payload jsonb not null,
  request_updated_at timestamptz not null,
  result_payload jsonb not null,
  result_updated_at timestamptz not null,
  result_deleted_at timestamptz,
  conflict_detected boolean not null default false,
  conflict_unresolved boolean not null default false,
  parent_deleted boolean not null default false,
  retained_payload jsonb,
  retained_updated_at timestamptz,
  applied_at timestamptz not null default now(),
  primary key (owner, operation_id)
);

alter table public.habits enable row level security;
alter table public.habit_days enable row level security;
alter table public.habit_operation_receipts enable row level security;
revoke all on public.habits from public, anon, authenticated;
revoke all on public.habit_days from public, anon, authenticated;
revoke all on public.habit_operation_receipts from public, anon, authenticated;
grant select on public.habits to authenticated;
grant select on public.habit_days to authenticated;
create policy habits_owner_select on public.habits for select to authenticated
  using (owner = (select auth.uid()));
create policy habit_days_owner_select on public.habit_days for select to authenticated
  using (owner = (select auth.uid()));
commit;
