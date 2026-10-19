-- Independently versioned, owner-qualified Mind Maps graph records.
begin;

create table public.mind_maps (
  owner uuid not null references auth.users(id) on delete cascade,
  id uuid not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, id)
);
create index mind_maps_owner_updated_idx on public.mind_maps(owner, updated_at, id);
create index mind_maps_owner_deleted_idx on public.mind_maps(owner, deleted_at, id);

create table public.mind_map_nodes (
  owner uuid not null,
  map_id uuid not null,
  node_id uuid not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, map_id, node_id),
  foreign key (owner, map_id) references public.mind_maps(owner, id)
);
create index mind_map_nodes_owner_updated_idx
  on public.mind_map_nodes(owner, map_id, updated_at, node_id);
create index mind_map_nodes_owner_deleted_idx
  on public.mind_map_nodes(owner, map_id, deleted_at, node_id);

create table public.mind_map_parent_slots (
  owner uuid not null,
  map_id uuid not null,
  child_node_id uuid not null,
  parent_node_id uuid not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, map_id, child_node_id),
  foreign key (owner, map_id) references public.mind_maps(owner, id)
);
create index mind_map_parent_slots_parent_idx
  on public.mind_map_parent_slots(owner, map_id, parent_node_id);
create index mind_map_parent_slots_updated_idx
  on public.mind_map_parent_slots(owner, map_id, updated_at, child_node_id);

create table public.mind_map_side_links (
  owner uuid not null,
  map_id uuid not null,
  first_node_id uuid not null,
  second_node_id uuid not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner, map_id, first_node_id, second_node_id),
  foreign key (owner, map_id) references public.mind_maps(owner, id),
  check (first_node_id < second_node_id)
);
create index mind_map_side_links_updated_idx
  on public.mind_map_side_links(owner, map_id, updated_at, first_node_id, second_node_id);

-- A receipt is stable for an operation ID, including a rejected graph race.
create table public.mind_map_operation_receipts (
  owner uuid not null references auth.users(id) on delete cascade,
  operation_id text not null check (btrim(operation_id) <> ''),
  entity_type text not null check (entity_type in
    ('mind_map', 'mind_map_node', 'mind_map_parent_slot', 'mind_map_side_link')),
  entity_id text not null,
  kind text not null check (kind in ('create', 'update', 'delete')),
  request_payload jsonb not null,
  request_updated_at timestamptz not null,
  result_payload jsonb not null,
  result_updated_at timestamptz not null,
  result_deleted_at timestamptz,
  conflict_detected boolean not null default false,
  conflict_unresolved boolean not null default false,
  retained_payload jsonb,
  retained_updated_at timestamptz,
  rejection_reason text,
  applied_at timestamptz not null default now(),
  primary key (owner, operation_id)
);
create index mind_map_receipts_entity_idx
  on public.mind_map_operation_receipts(owner, entity_type, entity_id, applied_at);

create table public.mind_map_conflicts (
  owner uuid not null references auth.users(id) on delete cascade,
  conflict_id text not null,
  map_id uuid not null,
  entity_type text not null,
  entity_id text not null,
  active_payload jsonb not null,
  active_updated_at timestamptz not null,
  retained_payload jsonb not null,
  retained_updated_at timestamptz not null,
  reason text not null,
  detected_at timestamptz not null default now(),
  primary key (owner, conflict_id)
);
create index mind_map_conflicts_owner_map_idx
  on public.mind_map_conflicts(owner, map_id, detected_at desc);

alter table public.mind_maps enable row level security;
alter table public.mind_map_nodes enable row level security;
alter table public.mind_map_parent_slots enable row level security;
alter table public.mind_map_side_links enable row level security;
alter table public.mind_map_operation_receipts enable row level security;
alter table public.mind_map_conflicts enable row level security;

revoke all on public.mind_maps from public, anon, authenticated;
revoke all on public.mind_map_nodes from public, anon, authenticated;
revoke all on public.mind_map_parent_slots from public, anon, authenticated;
revoke all on public.mind_map_side_links from public, anon, authenticated;
revoke all on public.mind_map_operation_receipts from public, anon, authenticated;
revoke all on public.mind_map_conflicts from public, anon, authenticated;

grant select on public.mind_maps, public.mind_map_nodes,
  public.mind_map_parent_slots, public.mind_map_side_links,
  public.mind_map_operation_receipts, public.mind_map_conflicts to authenticated;

create policy mind_maps_owner_read on public.mind_maps for select to authenticated
  using (owner = (select auth.uid()));
create policy mind_map_nodes_owner_read on public.mind_map_nodes for select to authenticated
  using (owner = (select auth.uid()));
create policy mind_map_parent_slots_owner_read on public.mind_map_parent_slots
  for select to authenticated using (owner = (select auth.uid()));
create policy mind_map_side_links_owner_read on public.mind_map_side_links
  for select to authenticated using (owner = (select auth.uid()));
create policy mind_map_receipts_owner_read on public.mind_map_operation_receipts
  for select to authenticated using (owner = (select auth.uid()));
create policy mind_map_conflicts_owner_read on public.mind_map_conflicts
  for select to authenticated using (owner = (select auth.uid()));
commit;
