-- T018: Qiyam operation integrity: receipts, replay, convergence and
-- newest-wins, per contracts/adhkar-qiyam-sync.md.
begin;
select plan(14);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'qiyam-op@example.com','x',now(),now());

create function pg_temp.submit(p_performed boolean,p_rakahs integer,
  p_witr boolean,p_start text,p_end text,p_note text,
  p_version timestamptz,p_base timestamptz,p_op text)
returns jsonb language sql as $$
  select public.apply_qiyam_night_change_v1('2026-11-09',p_performed,
    p_rakahs,p_witr,p_start,p_end,p_note,'Africa/Cairo',120,
    p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);

select is(pg_temp.submit(true,4,true,'03:10','04:00',null,
  '2026-11-10 01:00:00+00',null,'op-1')->>'replayed','false',
  'the first Yes is not a replay');
select is(pg_temp.submit(true,4,true,'03:10','04:00',null,
  '2026-11-10 01:00:00+00',null,'op-1')->>'replayed','true',
  'an exact replay returns the original outcome');
select is((select count(*) from public.qiyam_nights),1::bigint,
  'a replay does not duplicate rows');
select throws_ok(
  'select public.apply_qiyam_night_change_v1(''2026-11-09''::date,true,8,true,
   null,null,null,''Africa/Cairo'',120,''2026-11-10 01:00:00+00''::timestamptz,
   null,''op-1'')',
  '22023','Qiyam operation ID reused with different content',
  'a reused operation ID with different content is rejected');

select is(pg_temp.submit(true,8,true,'03:10','04:00',null,
  '2026-11-10 02:00:00+00','2026-11-10 01:00:00+00','op-2')->>'conflict_id',
  null,'a matching base converges without conflict');
select is(pg_temp.submit(true,8,true,'03:10','04:00',null,
  '2026-11-10 02:00:00+00',null,'op-2-identical')->>'conflict_id',null,
  'identical content is ordinary convergence');

select is((select rakahs from public.qiyam_nights),8,'the newer edit is active');
select ok(pg_temp.submit(true,2,true,'03:00','04:00',null,
  '2026-11-10 00:30:00+00',null,'op-older') ? 'active_record',
  'an older arrival still returns an outcome');
select is((select rakahs from public.qiyam_nights),8,
  'the older arrival does not replace the newer version');

-- A later explicit No wins over an older Yes and clears the details.
select ok(pg_temp.submit(false,null,false,null,null,null,
  '2026-11-10 03:00:00+00','2026-11-10 02:00:00+00','op-no') ? 'active_record',
  'the explicit No lands');
select is((select performed from public.qiyam_nights),false,
  'the night reads as explicitly not performed');
select is((select rakahs from public.qiyam_nights),null::integer,
  'the details are cleared for No');

-- The XP-timestamp window: updated_at must sit inside
-- [night - 1 day, night + 2 days) in UTC (Phase 2 review finding 3).
select throws_ok(
  'select public.apply_qiyam_night_change_v1(''2026-11-09''::date,true,4,true,
   null,null,null,''Africa/Cairo'',120,''2026-11-07 23:30:00+00''::timestamptz,
   null,''op-early'')',
  '22023','Qiyam update outside its night window',
  'an updated_at before the night window is rejected');
select throws_ok(
  'select public.apply_qiyam_night_change_v1(''2026-11-09''::date,true,4,true,
   null,null,null,''Africa/Cairo'',120,''2026-11-11 00:00:00+00''::timestamptz,
   null,''op-late'')',
  '22023','Qiyam update outside its night window',
  'an updated_at at the night+2 boundary is rejected');

reset role;
select * from finish();
rollback;
