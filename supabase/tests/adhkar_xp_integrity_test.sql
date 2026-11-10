-- T017: Adhkar set-completion XP: 15 once per owner/day/list, server
-- derived from the catalog seed; different items from two devices complete
-- the set; resets never revoke; other sources stay untouched.
begin;
select plan(7);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'adhkar-xp@example.com','x',now(),now());

-- The migration ships no catalog seed (T006 gates it behind the owner's
-- content approval); this test seeds its own fixture rows.
insert into public.adhkar_catalog_items(catalog_version,item_id,list,position,target)
values
  (1,'m1','morning',1,1),
  (1,'m2','morning',2,1),
  (1,'m3','morning',3,1),
  (1,'m4','morning',4,3),
  (1,'m5','morning',5,3),
  (1,'m6','morning',6,3),
  (1,'m7','morning',7,7),
  (1,'m8','morning',8,100),
  (1,'m9','morning',9,10),
  (1,'m10','morning',10,100),
  (1,'e1','evening',1,1),
  (1,'e2','evening',2,1),
  (1,'e3','evening',3,1),
  (1,'e4','evening',4,3),
  (1,'e5','evening',5,3),
  (1,'e6','evening',6,3),
  (1,'e7','evening',7,7),
  (1,'e8','evening',8,100),
  (1,'e9','evening',9,10);

insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
values('86666666-6666-4666-8666-666666666666','task_done',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',20,'2026-11-09 05:00+00');

create function pg_temp.submit(p_day date,p_item text,p_count integer,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_adhkar_item_change_v1(p_day,p_item,1,p_count,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- Device A completes the first half of the Morning list; no award yet.
select pg_temp.submit('2026-11-09','m1',1,'2026-11-09 06:00:00+00',null,'a-m1');
select pg_temp.submit('2026-11-09','m2',1,'2026-11-09 06:01:00+00',null,'a-m2');
select pg_temp.submit('2026-11-09','m3',1,'2026-11-09 06:02:00+00',null,'a-m3');
select pg_temp.submit('2026-11-09','m4',3,'2026-11-09 06:03:00+00',null,'a-m4');
select pg_temp.submit('2026-11-09','m5',3,'2026-11-09 06:04:00+00',null,'a-m5');
select is((select count(*) from public.xp_awards
  where source='adhkar_set_done'),0::bigint,
  'a partial set does not award');
-- Device B (same owner) completes the second half: the set completes.
select pg_temp.submit('2026-11-09','m6',3,'2026-11-09 07:00:00+00',null,'b-m6');
select pg_temp.submit('2026-11-09','m7',7,'2026-11-09 07:01:00+00',null,'b-m7');
select pg_temp.submit('2026-11-09','m8',100,'2026-11-09 07:02:00+00',null,'b-m8');
select pg_temp.submit('2026-11-09','m9',10,'2026-11-09 07:03:00+00',null,'b-m9');
select is(pg_temp.submit('2026-11-09','m10',100,'2026-11-09 07:04:00+00',
  null,'b-m10')->'canonical_award'->>'amount','15',
  'completing the last catalog item awards 15 XP');
select is((select count(*) from public.xp_awards
  where source='adhkar_set_done'),1::bigint,'exactly one set award');
select is(pg_temp.submit('2026-11-09','m10',100,'2026-11-09 07:04:00+00',null,
  'b-m10-replay')->'canonical_award'->>'source_id',
  extensions.uuid_generate_v5('70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'adhkar/2026-11-09/morning')::text,
  'the award source id is the shared-namespace set identity');

-- A reset (and re-completion) never revokes or duplicates the award.
select pg_temp.submit('2026-11-09','m10',0,'2026-11-09 08:00:00+00',
  '2026-11-09 07:04:00+00','reset-m10');
select pg_temp.submit('2026-11-09','m10',100,'2026-11-09 09:00:00+00',null,
  'redo-m10');
select is((select count(*) from public.xp_awards
  where source='adhkar_set_done'),1::bigint,
  'reset and re-completion keep a single award');

-- The Evening set is separate, and other sources are untouched.
select is((select count(*) from public.xp_awards
  where source='adhkar_set_done'
  and source_id=extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'adhkar/2026-11-09/evening')),0::bigint,
  'no Evening award exists');
select is((select amount from public.xp_awards where source='task_done'),20,
  'the existing Task reward remains 20 XP');

reset role;
select * from finish();
rollback;
