-- T018: Qiyam access control and validation per contracts/adhkar-qiyam-sync.md.
begin;
select plan(12);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'qiyam-iso@example.com','x',now(),now()),
  ('00000000-0000-0000-0000-000000000000',
  '77777777-7777-4777-8777-777777777777','authenticated','authenticated',
  'qiyam-other@example.com','x',now(),now());

create function pg_temp.submit(p_night date,p_performed boolean,
  p_rakahs integer,p_witr boolean,p_start text,p_end text,p_note text,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language plpgsql as $$
declare r jsonb;
begin
  select public.apply_qiyam_night_change_v1(p_night,p_performed,p_rakahs,
    p_witr,p_start,p_end,p_note,'Africa/Cairo',120,p_version,p_base,p_op)
    into r;
  return r;
exception when others then
  return jsonb_build_object('error',sqlerrm);
end $$;

reset role;
select throws_ok(
  'select public.apply_qiyam_night_change_v1(''2026-11-09''::date,true,4,true,
   null,null,null,''Africa/Cairo'',120,''2026-11-09 20:00+00''::timestamptz,
   null,''anon-q'')',
  '42501','Not authenticated','anonymous callers are rejected');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

select is(pg_temp.submit('2026-11-09',true,4,true,'03:10','04:00',null,
  '2026-11-10 01:00:00+00',null,'q-first')->'active_record'->>'performed',
  'true','owner A records a performed night');

-- Malformed inputs are rejected without side effects.
select is(pg_temp.submit('2026-11-09',true,3,true,null,null,null,
  '2026-11-10 02:00:00+00','2026-11-10 01:00:00+00','rakahs-3')
  ->>'error','Invalid Qiyam night operation',
  'rakahs outside {2,4,8,11} is rejected');
select is(pg_temp.submit('2026-11-09',false,4,true,null,null,null,
  '2026-11-10 02:00:00+00',null,'details-with-no')->>'error',
  'Invalid Qiyam night operation','details sent with No are rejected');
select is(pg_temp.submit('2026-11-09',true,4,true,null,null,
  repeat('x',501),'2026-11-10 02:00:00+00',null,'long-note')->>'error',
  'Invalid Qiyam night operation','a note over 500 characters is rejected');
select is(pg_temp.submit('2026-11-09',true,4,true,'25:00',null,null,
  '2026-11-10 02:00:00+00',null,'bad-time')->>'error',
  'Invalid Qiyam night operation','a bad HH:mm time is rejected');
select is(pg_temp.submit('2026-11-12',true,4,true,null,null,null,
  '2026-11-10 02:00:00+00',null,'too-far')->>'error',
  'Qiyam night more than two days ahead',
  'a night more than two days ahead is rejected');

-- Owner B sees nothing of owner A through RLS.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',true);
select is((select count(*) from public.qiyam_nights),0::bigint,
  'owner B cannot see owner A rows through RLS');
select is(pg_temp.submit('2026-11-09',false,null,false,null,null,null,
  '2026-11-09 21:00:00+00',null,'q-b-no')->'active_record'->>'performed',
  'false','owner B records its own night under the same deterministic ID');
reset role;
select is((select count(*) from public.qiyam_nights
  where owner='86666666-6666-4666-8666-666666666666'),1::bigint,
  'owner A row untouched by owner B activity');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select throws_ok(
  'insert into public.qiyam_nights values (''86666666-6666-4666-8666-666666666666'',
   ''2026-11-10'',null,true,4,true,null,null,null,''Africa/Cairo'',120,
   now(),now(),null)',
  '42501',null);
select throws_ok(
  'delete from public.qiyam_conflicts where owner = auth.uid()',
  '42501',null);
reset role;
select * from finish();
rollback;
