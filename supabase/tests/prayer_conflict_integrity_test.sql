begin;
select plan(8);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values
('00000000-0000-0000-0000-000000000000','84444444-4444-4444-8444-444444444444','authenticated','authenticated','prayer-conflict-a@example.com','x',now(),now()),
('00000000-0000-0000-0000-000000000000','85555555-5555-4555-8555-555555555555','authenticated','authenticated','prayer-conflict-b@example.com','x',now(),now());

create function pg_temp.submit_prayer(p_op text,p_status text,
  p_version timestamptz,p_base timestamptz,p_completion timestamptz)
returns jsonb language sql as $$
  select public.apply_prayer_report_change_v1(
    public.prayer_report_id_v1('2026-10-29','fajr'),'2026-10-29',
    'fajr',p_status,p_completion,'Africa/Cairo',120,
    '2026-10-29 05:00:00+00',p_version,p_base,p_op);
$$;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"84444444-4444-4444-8444-444444444444","role":"authenticated"}',true);
select pg_temp.submit_prayer('a-initial','pending',
  '2026-10-29 05:00:00+00',null,null);
select is(pg_temp.submit_prayer('a-ordinary','completed_late',
    '2026-10-29 09:00:00+00','2026-10-29 05:00:00+00',
    '2026-10-29 09:00:00+00')->>'conflict_id',null,
  'matching acknowledged base is an ordinary edit');
select is(pg_temp.submit_prayer('a-stale','missed',
    '2026-10-29 09:00:00+00','2026-10-29 05:00:00+00',null)->>'conflict_id',
  'e58910e7-0b1c-55e0-8c8b-36fe5265969b',
  'divergent equal-time change retains a stable conflict ID');
select is((select status from public.prayer_reports), 'missed',
  'equal-time semantic tie chooses the same active state');
select is((select count(*) from public.prayer_conflicts),1::bigint,
  'both semantic versions are retained once');
select is(pg_temp.submit_prayer('a-stale','missed',
    '2026-10-29 09:00:00+00',null,null)->>'conflict_id',
  'e58910e7-0b1c-55e0-8c8b-36fe5265969b',
  'replay preserves the same conflict identity despite a rebased hint');
select is((pg_temp.submit_prayer('a-stale','missed',
    '2026-10-29 09:00:00+00',null,null)->>'detected_at')::timestamptz,
  (select detected_at from public.prayer_conflicts),
  'receipt carries the stored server detection time');
select set_config('request.jwt.claims',
  '{"sub":"85555555-5555-4555-8555-555555555555","role":"authenticated"}',true);
select pg_temp.submit_prayer('b-initial','missed',
  '2026-10-29 09:00:00+00',null,null);
select is(pg_temp.submit_prayer('b-stale','completed_late',
    '2026-10-29 09:00:00+00',null,
    '2026-10-29 09:00:00+00')->>'conflict_id',
  'e58910e7-0b1c-55e0-8c8b-36fe5265969b',
  'reverse arrival uses the same conflict identity');
select is((select status from public.prayer_reports),'missed',
  'reverse arrival chooses the same active state');
reset role;
select * from finish();
rollback;
