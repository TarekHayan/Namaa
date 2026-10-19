begin;
select plan(21);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000','74444444-4444-4444-8444-444444444444','authenticated','authenticated','map-conflicts@example.com','x',now(),now());
create schema if not exists tests;
create function tests.map_version(p_at timestamptz,p_deleted boolean default false)
returns jsonb language sql as $$
  select jsonb_build_object('ownerId','74444444-4444-4444-8444-444444444444',
    'id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','title','Map',
    'centralNodeId','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'settings','{}'::jsonb,'revisionId','map-r1',
    'createdAt','2026-10-12T08:00:00Z','updatedAt',p_at::text,
    'deletedAt',case when p_deleted then p_at::text else null end);
$$;
create function tests.node_version(p_id uuid,p_kind text,p_title text,
  p_at timestamptz,p_deleted boolean default false)
returns jsonb language sql as $$
  select jsonb_build_object('ownerId','74444444-4444-4444-8444-444444444444',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','id',p_id::text,
    'kind',p_kind,'title',p_title,'description',null,'x',0,'y',0,
    'status','notStarted','priority','medium','appearance','{}'::jsonb,
    'taskId',null,'revisionId','node-r1',
    'createdAt','2026-10-12T08:00:00Z','updatedAt',p_at::text,
    'deletedAt',case when p_deleted then p_at::text else null end);
$$;
grant usage on schema tests to authenticated;
grant execute on function tests.map_version(timestamptz,boolean),
  tests.node_version(uuid,text,text,timestamptz,boolean) to authenticated;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"74444444-4444-4444-8444-444444444444","role":"authenticated"}',true);
select is((select replayed from public.apply_mind_map_change('mind_map',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.map_version('2026-10-12T09:00:00Z'),'map-create','2026-10-12T09:00:00Z','create')),
  false,'map created');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  tests.node_version('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','central','Center','2026-10-12T09:01:00Z'),
  'center','2026-10-12T09:01:00Z','create')),false,'central node created');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','First','2026-10-12T09:02:00Z'),
  'first','2026-10-12T09:02:00Z','create')),false,'first branch created');
select is((select replayed from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.node_version('dddddddd-dddd-4ddd-8ddd-dddddddddddd','branch','Second','2026-10-12T09:03:00Z'),
  'second','2026-10-12T09:03:00Z','create')),false,'second branch created');
select is((select conflict_detected from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','First updated','2026-10-12T09:05:00Z'),
  'first-update','2026-10-12T09:05:00Z','update')),true,'first node version retains loser');
select is((select conflict_detected from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.node_version('dddddddd-dddd-4ddd-8ddd-dddddddddddd','branch','Second updated','2026-10-12T09:06:00Z'),
  'second-update','2026-10-12T09:06:00Z','update')),true,'independent node also commits');
reset role;
select is((select payload->>'title' from public.mind_map_nodes where node_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  'First updated','first independent edit survives');
select is((select payload->>'title' from public.mind_map_nodes where node_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'Second updated','second independent edit survives');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"74444444-4444-4444-8444-444444444444","role":"authenticated"}',true);
select is((select conflict_detected from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','Old offline','2026-10-12T09:04:00Z'),
  'older','2026-10-12T09:04:00Z','update')),true,'older same-node edit conflicts');
select is((select payload->>'title' from public.mind_map_nodes where node_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  'First updated','older edit cannot overwrite winner');
select is((select conflict_detected from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','New offline','2026-10-12T09:07:00Z'),
  'newer','2026-10-12T09:07:00Z','update')),true,'newer same-node edit wins with loser');
select is((select retained_payload->>'title' from public.mind_map_conflicts where conflict_id='newer'),
  'First updated','previous winner is visible');
select is((select conflict_unresolved from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','Equal offline','2026-10-12T09:07:00Z'),
  'equal','2026-10-12T09:07:00Z','update')),true,'equal-time tie remains unresolved');
select is((select deleted_at from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.node_version('dddddddd-dddd-4ddd-8ddd-dddddddddddd','branch','Second deleted','2026-10-12T09:10:00Z',true),
  'node-delete','2026-10-12T09:10:00Z','delete')),
  '2026-10-12T09:10:00Z'::timestamptz,'newer node delete becomes tombstone');
select is((select conflict_detected from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  tests.node_version('dddddddd-dddd-4ddd-8ddd-dddddddddddd','branch','Old edit','2026-10-12T09:09:00Z'),
  'node-old-edit','2026-10-12T09:09:00Z','update')),true,'edit losing to node delete retained');
select is((select replayed from public.apply_mind_map_change('mind_map_parent_slot',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:parent:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  jsonb_build_object('ownerId','74444444-4444-4444-8444-444444444444',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'childNodeId','cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'parentNodeId','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'appearance','{}'::jsonb,'revisionId','slot-r1',
    'updatedAt','2026-10-12T09:12:00Z','deletedAt',null),
  'parent-before-side','2026-10-12T09:12:00Z','create')),
  false,'parent role commits before structural collision');
select is((select replayed from public.apply_mind_map_change('mind_map_side_link',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:side:bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  jsonb_build_object('ownerId','74444444-4444-4444-8444-444444444444',
    'mapId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'firstNodeId','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'secondNodeId','cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    'appearance','{}'::jsonb,'revisionId','side-r1',
    'updatedAt','2026-10-12T09:13:00Z','deletedAt',null),
  'newer-side','2026-10-12T09:13:00Z','create')),
  false,'newer side role commits under structural lock');
select is((select deleted_at from public.mind_map_parent_slots
  where child_node_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  '2026-10-12T09:13:00Z'::timestamptz,
  'old parent role becomes tombstone and only one pair remains active');
select is((select deleted_at from public.apply_mind_map_change('mind_map',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.map_version('2026-10-12T09:20:00Z',true),'map-delete','2026-10-12T09:20:00Z','delete')),
  '2026-10-12T09:20:00Z'::timestamptz,'map tombstone commits');
select is((select rejection_reason from public.apply_mind_map_change('mind_map_node',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa:cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tests.node_version('cccccccc-cccc-4ccc-8ccc-cccccccccccc','branch','After map delete','2026-10-12T09:21:00Z'),
  'late-child','2026-10-12T09:21:00Z','update')),
  'map_deleted','later child edit cannot resurrect deleted map');
reset role;
select is((select count(*) from public.mind_map_conflicts where owner='74444444-4444-4444-8444-444444444444'),
  10::bigint,'all competing and rejected versions remain owner-scoped');
select * from finish();
rollback;
