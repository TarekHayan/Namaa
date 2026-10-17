begin;
select plan(12);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000',
  '63333333-3333-3333-3333-333333333333','authenticated','authenticated',
  'habit-operations@example.com','x',now(),now());
create schema if not exists tests;
create function tests.habit_payload(p_at timestamptz, p_deleted boolean default false)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'accountId','63333333-3333-3333-3333-333333333333',
    'name','Read','createdAt','2026-10-12T08:00:00Z',
    'updatedAt',p_at::text,
    'deletedAt',case when p_deleted then p_at::text else null end,
    'reminderMinuteOfDay',null,
    'scheduleRevisions',jsonb_build_array(jsonb_build_object(
      'revisionId','revision-1','effectiveAt','2026-10-12T08:00:00Z',
      'effectiveLocalDate','2026-10-12','utcOffsetMinutes',120,
      'weekdays',jsonb_build_array(1)))
  );
$$;
create function tests.day_payload(p_at timestamptz)
returns jsonb language sql as $$
  select jsonb_build_object(
    'accountId','63333333-3333-3333-3333-333333333333',
    'habitId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'localDate','2026-10-12','completedAt',p_at::text,
    'earnedWhileDue',true,'earnedAgainstRevisionId','revision-1',
    'recordedUtcOffsetMinutes',120,'updatedAt',p_at::text);
$$;
grant usage on schema tests to authenticated;
grant execute on function tests.habit_payload(timestamptz,boolean) to authenticated;
grant execute on function tests.day_payload(timestamptz) to authenticated;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"63333333-3333-3333-3333-333333333333","role":"authenticated"}',true);

select is((select replayed from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_payload('2026-10-12T09:00:00Z'),
  'create-habit','2026-10-12T09:00:00Z','create')),
  false, 'first Habit mutation commits');
do $$ begin
  for i in 1..10 loop
    perform * from public.apply_habit_change(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      tests.habit_payload('2026-10-12T09:00:00Z'),
      'create-habit','2026-10-12T09:00:00Z','create');
  end loop;
end $$;
reset role;
select is((select count(*) from public.habit_operation_receipts),1::bigint,
  'ten retries retain one receipt');
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"63333333-3333-3333-3333-333333333333","role":"authenticated"}',true);
select is((select replayed from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_payload('2026-10-12T09:00:00Z'),
  'create-habit','2026-10-12T09:00:00Z','create')),
  true, 'receipt returns replay result');
select is((select replayed from public.apply_habit_day_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-12',
  tests.day_payload('2026-10-12T09:05:00Z'),
  'day-create','2026-10-12T09:05:00Z','create')),
  false, 'day mutation commits under owner parent');
select throws_ok(
  $sql$select public.apply_habit_day_change(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-13',
    tests.day_payload('2026-10-12T09:05:00Z'),
    'wrong-date','2026-10-12T09:05:00Z','create')$sql$,
  '22023', null, 'day payload cannot claim another local date');
select throws_ok(
  $sql$select public.apply_habit_day_change(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-12',
    jsonb_set(tests.day_payload('2026-10-12T09:05:00Z'),
      '{earnedWhileDue}', 'false'::jsonb),
    'invalid-completion','2026-10-12T09:05:00Z','create')$sql$,
  '22023', null, 'completed day must retain due evidence');
select throws_ok(
  $sql$select public.apply_habit_day_change(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','2026-10-12',
    jsonb_set(tests.day_payload('2026-10-12T09:05:00Z'),
      '{habitId}', '"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"'::jsonb),
    'missing-parent','2026-10-12T09:05:00Z','create')$sql$,
  '23503', null, 'day cannot create without an owned parent');
select is((select conflict_detected from public.apply_habit_day_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-12',
  tests.day_payload('2026-10-12T09:06:00Z'),
  'day-update','2026-10-12T09:06:00Z','update')),
  true, 'competing same-date version retains loser');
reset role;
select is((select count(*) from public.habit_days),1::bigint,
  'one owner/Habit/date identity remains');
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"63333333-3333-3333-3333-333333333333","role":"authenticated"}',true);
select is((select deleted_at from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_payload('2026-10-12T10:00:00Z',true),
  'habit-delete','2026-10-12T10:00:00Z','delete')),
  '2026-10-12T10:00:00Z'::timestamptz,
  'delete writes a tombstone');
select is((select replayed from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_payload('2026-10-12T10:00:00Z',true),
  'habit-delete','2026-10-12T10:00:00Z','delete')),
  true, 'tombstone retry returns receipt');
reset role;
select is((select count(*) from public.habit_days),1::bigint,
  'tombstone retains child day evidence');
select * from finish();
rollback;
