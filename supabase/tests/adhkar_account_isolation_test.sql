-- T017: Adhkar access control. Anonymous callers and foreign owners are
-- denied; malformed catalog references are rejected; every direct client
-- write is denied. Proofs from contracts/adhkar-qiyam-sync.md.
begin;
select plan(14);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'adhkar-iso@example.com','x',now(),now()),
  ('00000000-0000-0000-0000-000000000000',
  '77777777-7777-4777-8777-777777777777','authenticated','authenticated',
  'adhkar-other@example.com','x',now(),now());

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


create function pg_temp.submit(p_day date,p_item text,p_count integer,
  p_version timestamptz,p_base timestamptz,p_op text,p_version_catalog int)
returns jsonb language plpgsql as $$
declare r jsonb;
begin
  select public.apply_adhkar_item_change_v1(p_day,p_item,p_version_catalog,
    p_count,p_version,p_base,p_op) into r;
  return r;
exception when others then
  return jsonb_build_object('error',sqlerrm);
end $$;

reset role;
select throws_ok(
  'select public.apply_adhkar_item_change_v1(''2026-11-09''::date,''m1'',1,1,
   ''2026-11-09 06:00+00''::timestamptz,null,''anon-op'')',
  '42501','Not authenticated','anonymous callers are rejected');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- No jwt claims at all still means auth.uid() is null.
select set_config('request.jwt.claims','',true);
select throws_ok(
  'select public.apply_adhkar_item_change_v1(''2026-11-09''::date,''m1'',1,1,
   ''2026-11-09 06:00+00''::timestamptz,null,''no-claims-op'')',
  '42501','Not authenticated','missing claims are rejected');

select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select is(pg_temp.submit('2026-11-09','m1',1,'2026-11-09 06:00:00+00',null,
  'owner-a-first',1)->'active_record'->>'count','1','owner A first count lands');

-- Malformed inputs are rejected without side effects.
select is(pg_temp.submit('2026-11-09','zz9',1,'2026-11-09 07:00:00+00',
  '2026-11-09 06:00:00+00','unknown-item',1)->>'error',
  'Unknown Adhkar catalog item','unknown item id is rejected');
select is(pg_temp.submit('2026-11-09','m1',4,'2026-11-09 07:00:00+00',null,
  'above-target',1)->>'error','Count above catalog target',
  'count above target is rejected');
select is(pg_temp.submit('2026-11-09','m1',1,'2026-11-09 07:00:00+00',null,
  'unknown-catalog',99)->>'error','Unknown Adhkar catalog item',
  'unknown catalog version is rejected');
select is(pg_temp.submit((current_date + 3),'m1',1,
  '2026-11-09 07:00:00+00',null,'too-far-ahead',1)->>'error',
  'Adhkar day more than two days ahead',
  'a day more than two days ahead is rejected');

-- Owner B sees nothing of owner A and owns its own rows only.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',true);
select is((select count(*) from public.adhkar_item_counts),0::bigint,
  'owner B cannot see owner A rows through RLS');
select is(pg_temp.submit('2026-11-09','m1',1,'2026-11-09 06:30:00+00',null,
  'owner-b-first',1)->'active_record'->>'count','1',
  'owner B writes its own record under the same deterministic ID');
reset role;
select is((select count(*) from public.adhkar_item_counts
  where owner='86666666-6666-4666-8666-666666666666'),1::bigint,
  'owner A row untouched by owner B activity');

-- Direct client writes are denied everywhere; the catalog is read-only.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select is((select count(*) from public.adhkar_catalog_items
  where catalog_version = 1),19::bigint,
  'the v1 catalog seed is readable to authenticated users');
select throws_ok(
  'insert into public.adhkar_item_counts values (''86666666-6666-4666-8666-666666666666'',
   ''2026-11-09'',''m9'',null,1,''morning'',1,''2026-11-09 06:00+00'',
   ''2026-11-09 06:00+00'',null)',
  '42501',null);
select throws_ok(
  'insert into public.adhkar_catalog_items values (1,''m11'',''morning'',11,1)',
  '42501',null);
select throws_ok(
  'delete from public.adhkar_conflicts where owner = auth.uid()',
  '42501',null);
reset role;
select * from finish();
rollback;
