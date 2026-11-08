begin;
select plan(12);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000',
  '83333333-3333-4333-8333-333333333333','authenticated','authenticated',
  'prayer-operation@example.com','x',now(),now());

create function pg_temp.submit_prayer(
  p_op text,p_status text,p_version timestamptz,p_base timestamptz,
  p_completion timestamptz,p_report_id uuid default null)
returns jsonb language sql as $$
  select public.apply_prayer_report_change_v1(
    coalesce(p_report_id,public.prayer_report_id_v1('2026-10-29','fajr')),
    '2026-10-29','fajr',p_status,p_completion,'Africa/Cairo',120,
    '2026-10-29 05:00:00+00',p_version,p_base,p_op);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"83333333-3333-4333-8333-333333333333","role":"authenticated"}',true);
select is(pg_temp.submit_prayer('op-1','pending','2026-10-29 05:00:00+00',null,null)->>'operation_id',
  'op-1','historical offline operation is accepted');
select is(pg_temp.submit_prayer('op-1','pending','2026-10-29 05:00:00+00',null,null)->>'replayed',
  'true','identical replay uses the stored receipt');
set local timezone to 'America/New_York';
select is(pg_temp.submit_prayer('op-1','pending','2026-10-29 05:00:00+00',null,null)->>'replayed',
  'true','replay fingerprint is stable across database session timezones');
set local timezone to 'UTC';
select is((select count(*) from public.prayer_reports),1::bigint,
  'replay has one report effect');
select throws_ok(
  $sql$select pg_temp.submit_prayer('op-1','missed','2026-10-29 05:00:00+00',null,null)$sql$,
  '22023',null,'changed semantic operation ID is rejected');
select throws_ok(
  $sql$select pg_temp.submit_prayer('bad-status','unknown','2026-10-29 05:01:00+00',null,null)$sql$,
  '22023',null,'unknown state is rejected');
select throws_ok(
  $sql$select pg_temp.submit_prayer('missing-completion','completed_on_time','2026-10-29 05:01:00+00',null,null)$sql$,
  '22023',null,'completed state requires completion instant');
select throws_ok(
  $sql$select pg_temp.submit_prayer('extra-completion','missed','2026-10-29 05:01:00+00',null,'2026-10-29 05:01:00+00')$sql$,
  '22023',null,'missed state forbids completion instant');
select throws_ok(
  $sql$select pg_temp.submit_prayer('wrong-id','pending','2026-10-29 05:01:00+00',null,null,
    'ffffffff-ffff-4fff-8fff-ffffffffffff')$sql$,
  '22023',null,'report ID must derive from date and prayer');
select throws_ok(
  $sql$select pg_temp.submit_prayer('future-completion','completed_on_time',
    '2030-01-01 05:00:00+00',null,'2030-01-01 05:00:00+00')$sql$,
  '22023',null,'completion far after the prayer day cannot date an award');
select throws_ok(
  $sql$select pg_temp.submit_prayer('early-completion','completed_on_time',
    '2026-10-29 05:01:00+00',null,'2026-10-20 05:00:00+00')$sql$,
  '22023',null,'completion before the prayer day cannot date an award');
select is(pg_temp.submit_prayer('op-2','completed_late',
    '2026-10-29 06:00:00+00','2026-10-29 05:00:00+00',
    '2026-10-29 06:00:00+00')->'canonical_award'->>'amount',
  '5','server derives the reward without an amount parameter');
reset role;
select * from finish();
rollback;
