begin;
select plan(8);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000',
  '64444444-4444-4444-4444-444444444444','authenticated','authenticated',
  'habit-conflicts@example.com','x',now(),now());
create schema if not exists tests;
create function tests.habit_version(p_name text,p_at timestamptz,p_delete boolean default false)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'accountId','64444444-4444-4444-4444-444444444444',
    'name',p_name,'createdAt','2026-10-12T08:00:00Z',
    'updatedAt',p_at::text,'deletedAt',case when p_delete then p_at::text else null end,
    'reminderMinuteOfDay',null,
    'scheduleRevisions',jsonb_build_array(jsonb_build_object(
      'revisionId','revision-1','effectiveAt','2026-10-12T08:00:00Z',
      'effectiveLocalDate','2026-10-12','utcOffsetMinutes',120,
      'weekdays',jsonb_build_array(1)))
  );
$$;
create function tests.day_version(p_date text,p_at timestamptz,p_done boolean)
returns jsonb language sql as $$
  select jsonb_build_object(
    'accountId','64444444-4444-4444-4444-444444444444',
    'habitId','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'localDate',p_date,
    'completedAt',case when p_done then p_at::text else null end,
    'earnedWhileDue',p_done,
    'earnedAgainstRevisionId',case when p_done then 'revision-1' else null end,
    'recordedUtcOffsetMinutes',120,'updatedAt',p_at::text);
$$;
grant usage on schema tests to authenticated;
grant execute on function tests.habit_version(text,timestamptz,boolean) to authenticated;
grant execute on function tests.day_version(text,timestamptz,boolean) to authenticated;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"64444444-4444-4444-4444-444444444444","role":"authenticated"}',true);

select is((select conflict_detected from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_version('Read','2026-10-12T08:00:00Z'),
  'base','2026-10-12T08:00:00Z','create')),
  false, 'first version has no conflict');
select is((select retained_payload->>'name' from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_version('Newer','2026-10-12T09:00:00Z'),
  'newer','2026-10-12T09:00:00Z','update')),
  'Read','newest version retains older loser');
select is((select payload->>'name' from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_version('Older','2026-10-12T08:30:00Z'),
  'older','2026-10-12T08:30:00Z','update')),
  'Newer','older incoming edit cannot replace winner');
select is((select conflict_unresolved from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_version('Equal','2026-10-12T09:00:00Z'),
  'equal','2026-10-12T09:00:00Z','update')),
  true,'equal-time edit is unresolved and retained');
select is((select retained_payload->>'name' from public.apply_habit_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tests.habit_version('Delete','2026-10-12T10:00:00Z',true),
  'delete','2026-10-12T10:00:00Z','delete')),
  'Newer','edit/delete race retains losing edit');
select is((select parent_deleted from public.apply_habit_day_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-12',
  tests.day_version('2026-10-12','2026-10-12T10:05:00Z',true),
  'day-after-delete','2026-10-12T10:05:00Z','create')),
  true,'day/delete race is recoverable evidence, not resurrection');
select is((select parent_deleted from public.apply_habit_day_change(
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','2026-10-13',
  tests.day_version('2026-10-13','2026-10-12T10:06:00Z',true),
  'other-day-after-delete','2026-10-12T10:06:00Z','create')),
  true,'independent dates retain separate conflict receipts');
reset role;
select is((select count(*) from public.habit_operation_receipts
  where entity_type = 'habit_day' and parent_deleted), 2::bigint,
  'both day/delete races survive as separate durable evidence');
select * from finish();
rollback;
