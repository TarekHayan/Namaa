-- T018: Qiyam XP: 30 once per owner/night on the first performed version,
-- never revoked by No, awarded even when the Yes version loses to a newer
-- No, and racing devices converge to one award.
begin;
select plan(9);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'qiyam-xp@example.com','x',now(),now());
insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
values('86666666-6666-4666-8666-666666666666','task_done',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',20,'2026-11-09 05:00+00');

create function pg_temp.submit(p_performed boolean,p_rakahs integer,
  p_witr boolean,p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_qiyam_night_change_v1('2026-11-09',p_performed,
    p_rakahs,p_witr,null,null,null,'Africa/Cairo',120,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

select is(pg_temp.submit(true,4,true,'2026-11-10 01:00:00+00',null,
  'yes-1')->'canonical_award'->>'amount','30',
  'the first Yes awards 30 XP');
select is(pg_temp.submit(true,4,true,'2026-11-10 01:00:00+00',null,'yes-1')
  ->'canonical_award'->>'source_id',
  public.qiyam_record_id_v1('2026-11-09')::text,
  'the award source id is the night record id');
select is(pg_temp.submit(false,null,false,'2026-11-10 02:00:00+00',
  '2026-11-10 01:00:00+00','no-1')->'canonical_award'->>'amount','30',
  'changing to No keeps the award');
select is(pg_temp.submit(true,8,true,'2026-11-10 03:00:00+00',
  '2026-11-10 02:00:00+00','yes-2')->'canonical_award'->>'amount','30',
  'Yes again does not award a second time');
select is((select count(*) from public.xp_awards
  where source='qiyam_done'),1::bigint,
  'Yes No Yes keeps exactly one award');

-- An older Yes that arrives after a newer No still earns the first award.
select ok(pg_temp.submit(false,null,false,'2026-11-10 05:00:00+00',null,
  'no-later') ? 'active_record','a later No is stored');
select is(pg_temp.submit(true,2,true,'2026-11-10 04:00:00+00',null,
  'yes-older')->'canonical_award'->>'amount','30',
  'a losing Yes still attempts the (already existing) award');
select is((select count(*) from public.xp_awards
  where source='qiyam_done'),1::bigint,'no duplicate award from the loser');

select is((select amount from public.xp_awards where source='task_done'),20,
  'the existing Task reward remains 20 XP');

reset role;
select * from finish();
rollback;
