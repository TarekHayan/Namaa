-- T017: Adhkar conflict integrity: one stable conflict per divergent pair,
-- arrival-order independent, with the equal-timestamp tie broken by the
-- semantic key (count). Cross-language check: the conflict ID equals the
-- RFC 4122 value computed with the shared NS009 namespace.
begin;
select plan(10);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'adhkar-conflict@example.com','x',now(),now());

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
  (1,'e9','evening',9,10),
  -- A second catalog version for the descriptor tie-break proof.
  (2,'m4','morning',4,3),
  (2,'m5','morning',5,3);


create function pg_temp.submit(p_day date,p_item text,p_count integer,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_adhkar_item_change_v1(p_day,p_item,1,p_count,
    p_version,p_base,p_op);
$$;

create function pg_temp.submit(p_day date,p_item text,p_count integer,
  p_version timestamptz,p_base timestamptz,p_op text,p_catalog integer)
returns jsonb language sql as $$
  select public.apply_adhkar_item_change_v1(p_day,p_item,p_catalog,p_count,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

-- Device A counts twice in order (05:00 then 06:00 with an acknowledged
-- base), so its last acknowledged base is 05:00. Device B, stale at 05:00,
-- diverges to 3 at 07:00: divergent content with an outdated base keeps one
-- conflict.
select pg_temp.submit('2026-11-09','m4',1,'2026-11-09 05:00:00+00',null,'op-a0');
select pg_temp.submit('2026-11-09','m4',1,'2026-11-09 06:00:00+00',
  '2026-11-09 05:00:00+00','op-a1');
select pg_temp.submit('2026-11-09','m4',3,'2026-11-09 07:00:00+00',
  '2026-11-09 05:00:00+00','op-b');
select is((select count from public.adhkar_item_counts where item_id='m4'),3,
  'the newer divergent version is active');
select is((select count(*) from public.adhkar_conflicts
  where item_id='m4'),1::bigint,'exactly one conflict is retained');

-- The conflict ID is the shared-namespace UUIDv5 of the ordered descriptors.
-- 06:00Z epoch = 1794204000s; 07:00Z epoch = 1794207600s (micros below).
select is((select conflict_id from public.adhkar_conflicts where item_id='m4'
    and active_record->>'count' = '3'),
  extensions.uuid_generate_v5(
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3'::uuid,
    'conflict/' || public.adhkar_record_id_v1('2026-11-09','m4')::text
    || '/1794204000000000:1:1/1794207600000000:1:3'),
  'the conflict ID matches the shared NS009 construction');

-- Replaying one side never duplicates the conflict.
select pg_temp.submit('2026-11-09','m4',1,'2026-11-09 05:00:00+00',null,'op-a0');
select is((select count(*) from public.adhkar_conflicts
  where item_id='m4'),1::bigint,'a replay does not duplicate the conflict');

-- Equal timestamps on divergent content: the greater count wins whichever
-- side arrives last, and the conflict stays one stable row. m7 (target 7);
-- the arriving side carries a stale base so the divergence is visible.
select pg_temp.submit('2026-11-09','m7',2,'2026-11-09 10:00:00+00',null,'op-tie-2');
select pg_temp.submit('2026-11-09','m7',4,'2026-11-09 10:00:00+00',
  '2026-11-09 05:00:00+00','op-tie-4');
select is((select count from public.adhkar_item_counts where item_id='m7'),4,
  'the greater count wins the equal-timestamp tie');
select is((select count(*) from public.adhkar_conflicts
  where item_id='m7'),1::bigint,'the tie keeps exactly one conflict');

-- A reset that loses to a newer count stays visible as the retained version.
-- m8 (target 100); the reset arrives with a stale base.
select pg_temp.submit('2026-11-09','m8',6,'2026-11-09 12:00:00+00',null,'op-m8-six');
select pg_temp.submit('2026-11-09','m8',0,'2026-11-09 11:00:00+00',
  '2026-11-09 05:00:00+00','op-m8-zero');
select is((select count from public.adhkar_item_counts where item_id='m8'),6,
  'the newer count beats the older reset');
select is((select retained_record->>'count' from public.adhkar_conflicts
  where item_id='m8'),'0','the losing reset is the retained evidence');


-- Phase 2 review finding 6: the descriptor carries the catalog version, so
-- two versions that differ only by catalog_version converge alike in both
-- arrival orders. The tie at an equal timestamp goes to the greater
-- descriptor (catalog 2 over catalog 1), whatever arrived last.
select pg_temp.submit('2026-11-09','m4',1,'2026-11-09 13:00:00+00',null,'op-ord-a1');
select pg_temp.submit('2026-11-09','m4',1,'2026-11-09 13:00:00+00',
  '2026-11-09 05:00:00+00','op-ord-a2',2);
select is((select catalog_version from public.adhkar_item_counts
  where item_id='m4'),2,
  'order A (catalog 1 first) still converges to catalog 2');
select pg_temp.submit('2026-11-09','m5',1,'2026-11-09 13:00:00+00',null,'op-ord-b1',2);
select pg_temp.submit('2026-11-09','m5',1,'2026-11-09 13:00:00+00',
  '2026-11-09 05:00:00+00','op-ord-b2',1);
select is((select catalog_version from public.adhkar_item_counts
  where item_id='m5'),2,
  'order B (catalog 2 first) converges to catalog 2 as well');

reset role;
select * from finish();
rollback;
