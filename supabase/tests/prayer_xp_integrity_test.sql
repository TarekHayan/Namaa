begin;
select plan(9);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '86666666-6666-4666-8666-666666666666','authenticated','authenticated',
  'prayer-xp@example.com','x',now(),now());
insert into public.xp_awards(owner,source,source_id,amount,awarded_at)
values('86666666-6666-4666-8666-666666666666','task_done',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',20,'2026-10-29 05:00+00');

create function pg_temp.submit_prayer(p_name text,p_op text,p_status text,
  p_version timestamptz,p_base timestamptz,p_completion timestamptz)
returns jsonb language sql as $$
  select public.apply_prayer_report_change_v1(
    public.prayer_report_id_v1('2026-10-29',p_name),'2026-10-29',
    p_name,p_status,p_completion,'Africa/Cairo',120,
    '2026-10-29 05:00:00+00',p_version,p_base,p_op);
$$;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"86666666-6666-4666-8666-666666666666","role":"authenticated"}',true);
select is(pg_temp.submit_prayer('fajr','fajr-first','completed_on_time',
    '2026-10-29 09:00:00+00',null,'2026-10-29 09:00:00+00')
    ->'canonical_award'->>'amount','10','first on-time completion fixes 10 XP');
select is(pg_temp.submit_prayer('fajr','fajr-late','completed_late',
    '2026-10-29 10:00:00+00','2026-10-29 09:00:00+00',
    '2026-10-29 09:00:00+00')->'canonical_award'->>'amount','10',
  'later late correction cannot reduce the first award');
select is(pg_temp.submit_prayer('fajr','fajr-reset','pending',
    '2026-10-29 11:00:00+00','2026-10-29 10:00:00+00',null)
    ->'canonical_award'->>'amount','10','reset retains the first award');
select is((select count(*) from public.xp_awards where source='prayer_done'),
  1::bigint,'correction and reset never insert another award');
select is(pg_temp.submit_prayer('dhuhr','dhuhr-first','completed_late',
    '2026-10-29 09:00:00+00',null,'2026-10-29 09:00:00+00')
    ->'canonical_award'->>'amount','5','first late completion fixes 5 XP');
select is(pg_temp.submit_prayer('dhuhr','dhuhr-on-time','completed_on_time',
    '2026-10-29 10:00:00+00','2026-10-29 09:00:00+00',
    '2026-10-29 09:00:00+00')->'canonical_award'->>'amount','5',
  'later on-time correction cannot increase the first award');
select pg_temp.submit_prayer('asr','asr-newer-reset','pending',
  '2026-10-29 11:00:00+00',null,null);
select is(pg_temp.submit_prayer('asr','asr-older-completion','completed_late',
    '2026-10-29 09:00:00+00',null,'2026-10-29 09:00:00+00')
    ->'canonical_award'->>'amount','5',
  'older losing completion still earns the first award');
select is((select status from public.prayer_reports where prayer_name='asr'),
  'pending','older award-bearing operation does not replace newer report');
select is((select amount from public.xp_awards where source='task_done'),20,
  'existing Task reward remains 20 XP');
reset role;
select * from finish();
rollback;
