begin;
select plan(18);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000','73333333-3333-4333-8333-333333333333','authenticated','authenticated','map-operations@example.com','x',now(),now());
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000','75555555-5555-4555-8555-555555555555','authenticated','authenticated','map-foreign@example.com','x',now(),now());
insert into public.mind_maps(owner,id,payload,updated_at) values
('73333333-3333-4333-8333-333333333333','ffffffff-ffff-4fff-8fff-ffffffffffff','{}','2026-10-12T08:00:00Z'),
('75555555-5555-4555-8555-555555555555','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','{}','2026-10-12T08:00:00Z');
insert into public.mind_map_nodes(owner,map_id,node_id,payload,updated_at) values
('73333333-3333-4333-8333-333333333333','ffffffff-ffff-4fff-8fff-ffffffffffff','11111111-1111-4111-8111-111111111111','{}','2026-10-12T08:00:00Z'),
('75555555-5555-4555-8555-555555555555','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','22222222-2222-4222-8222-222222222222','{}','2026-10-12T08:00:00Z');
insert into public.tasks(owner,id,payload,updated_at) values
('73333333-3333-4333-8333-333333333333','33333333-3333-4333-8333-333333333333','{}','2026-10-12T08:00:00Z');
create schema if not exists tests;
create function tests.map_payload(p_at timestamptz) returns jsonb language sql as $$
  select jsonb_build_object('ownerId','73333333-3333-4333-8333-333333333333',
    'id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','title','Map',
    'centralNodeId','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'settings','{}'::jsonb,'revisionId','map-r1',
    'createdAt','2026-10-12T08:00:00Z','updatedAt',p_at::text,'deletedAt',null);
$$;
create function tests.node_payload(p_id uuid,p_kind text,p_at timestamptz,
  p_task uuid default null) returns jsonb language sql as $$
  select jsonb_build_object('ownerId','73333333-3333-4333-8333-333333333333',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','id',p_id::text,
    'kind',p_kind,'title','Node','description',null,'x',0,'y',0,
    'status','notStarted','priority','medium','appearance','{}'::jsonb,
    'taskId',p_task::text,'revisionId','node-r1',
    'createdAt','2026-10-12T08:00:00Z','updatedAt',p_at::text,'deletedAt',null);
$$;
create function tests.slot_payload(p_child uuid,p_parent uuid,p_at timestamptz)
  returns jsonb language sql as $$
  select jsonb_build_object('ownerId','73333333-3333-4333-8333-333333333333',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'childNodeId',p_child::text,'parentNodeId',p_parent::text,
    'appearance','{}'::jsonb,'revisionId','slot-r1',
    'updatedAt',p_at::text,'deletedAt',null);
$$;
create function tests.side_payload(p_first uuid,p_second uuid,p_at timestamptz)
  returns jsonb language sql as $$
  select jsonb_build_object('ownerId','73333333-3333-4333-8333-333333333333',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'firstNodeId',p_first::text,'secondNodeId',p_second::text,
    'appearance','{}'::jsonb,'revisionId','side-r1',
    'updatedAt',p_at::text,'deletedAt',null);
$$;
grant usage on schema tests to authenticated;
grant execute on function tests.map_payload(timestamptz),
  tests.node_payload(uuid,text,timestamptz,uuid),
  tests.slot_payload(uuid,uuid,timestamptz),
  tests.side_payload(uuid,uuid,timestamptz) to authenticated;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"73333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
select is((select replayed from public.apply_mind_map_change('mind_map',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.map_payload('2026-10-12T09:00:00Z'),'map-create','2026-10-12T09:00:00Z','create')),
  false,'first map mutation commits');
select is((select replayed from public.apply_mind_map_change('mind_map',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.map_payload('2026-10-12T09:00:00Z'),'map-create','2026-10-12T09:00:00Z','create')),
  true,'replay returns stable receipt');
select throws_ok($sql$select public.apply_mind_map_change('mind_map',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  jsonb_set(tests.map_payload('2026-10-12T09:00:00Z'),'{title}','"Other"'),
  'map-create','2026-10-12T09:00:00Z','create')$sql$,
  '22023',null,'same operation ID cannot change payload');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  tests.node_payload('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','central','2026-10-12T09:01:00Z'),
  'center-create','2026-10-12T09:01:00Z','create')),
  false,'central node commits');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_payload('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','2026-10-12T09:02:00Z'),
  'child-create','2026-10-12T09:02:00Z','create')),
  false,'independent child commits');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.node_payload('dddddddd-dddd-4ddd-8ddd-dddddddddddd','branch','2026-10-12T09:03:00Z'),
  'third-create','2026-10-12T09:03:00Z','create')),
  false,'third node commits');
select throws_ok($sql$select public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  tests.node_payload('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','task','2026-10-12T09:04:00Z',
    'ffffffff-ffff-4fff-8fff-ffffffffffff'),
  'foreign-task','2026-10-12T09:04:00Z','create')$sql$,
  '23503',null,'new Task link requires owned live Task');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:44444444-4444-4444-8444-444444444444',
  tests.node_payload('44444444-4444-4444-8444-444444444444','task',
    '2026-10-12T09:04:00Z','33333333-3333-4333-8333-333333333333'),
  'task-link','2026-10-12T09:04:00Z','create')),
  false,'new owned live Task link is allowed');
select throws_ok($sql$select public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  tests.slot_payload('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','2026-10-12T09:05:00Z'),
  'missing-endpoint','2026-10-12T09:05:00Z','create')$sql$,
  '23503',null,'parent endpoint must belong to same map');
select throws_ok($sql$select public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.slot_payload('cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '11111111-1111-4111-8111-111111111111','2026-10-12T09:05:00Z'),
  'cross-map','2026-10-12T09:05:00Z','create')$sql$,
  '23503',null,'other map endpoint is unavailable');
select throws_ok($sql$select public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.slot_payload('cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '22222222-2222-4222-8222-222222222222','2026-10-12T09:05:00Z'),
  'foreign-endpoint','2026-10-12T09:05:00Z','create')$sql$,
  '23503',null,'foreign owner endpoint is unavailable');
select is((select replayed from public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.slot_payload('cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','2026-10-12T09:06:00Z'),
  'slot-create','2026-10-12T09:06:00Z','create')),
  false,'parent slot commits');
select is((select replayed from public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.slot_payload('dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc','2026-10-12T09:07:00Z'),
  'slot-third','2026-10-12T09:07:00Z','create')),
  false,'second parent slot commits');
select is((select rejection_reason from public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.slot_payload('cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd','2026-10-12T09:08:00Z'),
  'cycle-attempt','2026-10-12T09:08:00Z','update')),
  'cycle','cycle is rejected with a durable receipt');
select is((select rejection_reason from public.apply_mind_map_change('mind_map_side_link',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:side:bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.side_payload('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc','2026-10-12T09:06:00Z'),
  'duplicate-pair','2026-10-12T09:06:00Z','create')),
  'duplicate_pair','parent/side pair cannot duplicate');
select is((select result_payload->>'childNodeId' from public.mind_map_operation_receipts
  where operation_id='duplicate-pair'),
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  'rejected side receipt names the active parent version');
reset role;
update public.tasks set deleted_at='2026-10-12T09:09:00Z'
  where id='33333333-3333-4333-8333-333333333333';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"73333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
select ok((select rejection_reason is null from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:44444444-4444-4444-8444-444444444444',
  tests.node_payload('44444444-4444-4444-8444-444444444444','task',
    '2026-10-12T09:10:00Z','33333333-3333-4333-8333-333333333333'),
  'keep-unavailable-task','2026-10-12T09:10:00Z','update')),
  'existing unavailable Task ID remains on unrelated node edit');
reset role;
select is((select count(*) from public.mind_map_operation_receipts),10::bigint,
  'successful and rejected operations have one owner-derived receipt each');
select * from finish();
rollback;
