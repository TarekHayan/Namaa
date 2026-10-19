begin;
select plan(25);

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values
('00000000-0000-0000-0000-000000000000','71111111-1111-4111-8111-111111111111','authenticated','authenticated','map-a@example.com','x',now(),now()),
('00000000-0000-0000-0000-000000000000','72222222-2222-4222-8222-222222222222','authenticated','authenticated','map-b@example.com','x',now(),now());

insert into public.mind_maps(owner,id,payload,updated_at) values
('71111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','{}',now());
insert into public.mind_map_nodes(owner,map_id,node_id,payload,updated_at) values
('71111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','{}',now());
insert into public.mind_map_parent_slots(owner,map_id,child_node_id,parent_node_id,payload,updated_at) values
('71111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','cccccccc-cccc-4ccc-8ccc-cccccccccccc','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','{}',now());
insert into public.mind_map_side_links(owner,map_id,first_node_id,second_node_id,payload,updated_at) values
('71111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','cccccccc-cccc-4ccc-8ccc-cccccccccccc','{}',now());
insert into public.mind_map_operation_receipts(owner,operation_id,entity_type,entity_id,kind,request_payload,request_updated_at,result_payload,result_updated_at) values
('71111111-1111-4111-8111-111111111111','map-isolation','mind_map','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','create','{}',now(),'{}',now());
insert into public.mind_map_conflicts(owner,conflict_id,map_id,entity_type,entity_id,active_payload,active_updated_at,retained_payload,retained_updated_at,reason) values
('71111111-1111-4111-8111-111111111111','map-conflict','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','mind_map','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','{}',now(),'{}',now(),'version');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"71111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select is((select count(*) from public.mind_maps),1::bigint,'owner reads map');
select is((select count(*) from public.mind_map_nodes),1::bigint,'owner reads node');
select is((select count(*) from public.mind_map_parent_slots),1::bigint,'owner reads parent slot');
select is((select count(*) from public.mind_map_side_links),1::bigint,'owner reads side link');
select is((select count(*) from public.mind_map_conflicts),1::bigint,'owner reads conflict evidence');
select is((select count(*) from public.mind_map_operation_receipts),1::bigint,'owner reads own receipt');
select set_config('request.jwt.claims','{"sub":"72222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
select is((select count(*) from public.mind_maps),0::bigint,'foreign map hidden');
select is((select count(*) from public.mind_map_nodes),0::bigint,'foreign node hidden');
select is((select count(*) from public.mind_map_parent_slots),0::bigint,'foreign parent slot hidden');
select is((select count(*) from public.mind_map_side_links),0::bigint,'foreign side link hidden');
select is((select count(*) from public.mind_map_conflicts),0::bigint,'foreign conflict hidden');
select is((select count(*) from public.mind_map_operation_receipts),0::bigint,'foreign receipt hidden');
reset role;
select ok(not has_table_privilege('authenticated','public.mind_maps','INSERT'),'direct map write denied');
select ok(not has_table_privilege('authenticated','public.mind_map_nodes','UPDATE'),'direct node write denied');
select ok(not has_table_privilege('authenticated','public.mind_map_parent_slots','DELETE'),'direct parent write denied');
select ok(not has_table_privilege('authenticated','public.mind_map_side_links','INSERT'),'direct side write denied');
select ok(not has_table_privilege('authenticated','public.mind_map_conflicts','INSERT'),'direct conflict write denied');
select ok(not has_table_privilege('authenticated','public.mind_map_operation_receipts','UPDATE'),'direct receipt write denied');
select ok(not has_table_privilege('anon','public.mind_maps','SELECT'),'anonymous map read denied');
select ok(not has_table_privilege('anon','public.mind_map_nodes','SELECT'),'anonymous node read denied');
select ok(not has_table_privilege('anon','public.mind_map_parent_slots','SELECT'),'anonymous parent read denied');
select ok(not has_table_privilege('anon','public.mind_map_side_links','SELECT'),'anonymous side read denied');
select ok(not has_table_privilege('anon','public.mind_map_conflicts','SELECT'),'anonymous conflict read denied');
select ok(not has_table_privilege('anon','public.mind_map_operation_receipts','SELECT'),'anonymous receipt read denied');
select ok(not has_function_privilege('anon','public.apply_mind_map_change(text,uuid,text,jsonb,text,timestamptz,text)','EXECUTE'),'anonymous RPC denied');
select * from finish();
rollback;
